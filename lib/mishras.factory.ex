use Protoss

defprotocol Mishras.Factory do
  @moduledoc """
  A protocol for creating test data factories for Ecto schemas.

  This protocol provides a powerful and flexible way to create test data with
  automatic handling of associations, embeds, and primary key generation.

  ## Overview

  The Mishras.Factory protocol allows you to define factories for your Ecto schemas
  that can automatically:
  - Generate primary keys (both integer and binary_id)
  - Handle associations (belongs_to, has_one, has_many, many_to_many)
  - Process embedded schemas (embeds_one, embeds_many)
  - Support different modes for building vs inserting data

  ## Implementation

  To implement a factory for a schema, you need to define the `build_map/2` callback:

      defimpl Mishras.Factory, for: MyApp.User do
        use Mishras
        
        def build_map(_mode, _attrs) do
          %{
            name: "John Doe",
            email: "john@example.com"
          }
        end
      end

  ### Modes

  The factory supports two modes, which are passed into the `build_map` callback:
  - `:build` - Creates structs without database insertion
  - `:insert` - Creates and inserts records into the database

  ### Dependent data

  When building maps, it may be necessary to have some fields depend on other fields.
  In this case, the fields are passed as the second `attrs` argument.

  ## Configuration

  In order to properly integrate with Ecto, configure your repo in your application config:

      config :mishras, repo: MyApp.Repo
  """

  @doc false
  def changeset(object, attrs)
after
  alias Ecto.Changeset

  @type mode :: :build | :insert
  @callback build_map(mode, attrs :: map) :: map
  @callback autogenerate_id(attrs :: map) :: map
  @optional_callbacks autogenerate_id: 1

  @doc """
  Builds a struct from the given schema with the provided attributes.

  This function creates a struct without inserting it into the database.
  It automatically generates primary keys and handles associations/embeds.

  ## Parameters

  - `schema` - The Ecto schema module
  - `attrs` - A map or keyword list of attributes to override defaults

  ## Examples

      user = Mishras.Factory.build(MyApp.User, %{name: "Jane"})
      # Returns a %MyApp.User{} struct

  ## Returns

  A struct of the given schema type with all fields populated.
  """
  def build(schema, attrs \\ []) do
    schema
    |> struct()
    |> changeset(build_map(schema, :build, attrs))
    |> Changeset.apply_action!(:build)
  end

  defp add_primary_key(attrs, mode, schema, impl) do
    # if the schema impl has an autogenerate_id function, we should call it.
    cond do
      function_exported?(impl, :autogenerate_id, 1) ->
        impl.autogenerate_id(attrs)

      mode == :build ->
        case schema.__schema__(:autogenerate_id) do
          {name, _, :id} -> Map.put(attrs, name, Enum.random(1..32767))
          {name, _, :binary_id} -> Map.put(attrs, name, Ecto.UUID.generate())
          nil -> attrs
        end

      :else ->
        attrs
    end
  end

  @repo Application.compile_env!(:mishras, :repo)

  @doc """
  Inserts a record into the database using the given schema and attributes.

  This function creates a struct and immediately inserts it into the configured
  repository. It automatically generates primary keys and handles associations/embeds.

  ## Parameters

  - `schema` - The Ecto schema module
  - `attrs` - A map or keyword list of attributes to override defaults

  ## Examples

      user = Mishras.Factory.insert(MyApp.User, %{email: "jane@example.com"})
      # Returns a persisted %MyApp.User{} struct with database ID

  ## Returns

  A struct of the given schema type that has been persisted to the database.

  ## Raises

  Raises if the insertion fails due to validation errors or database constraints.
  """
  def insert(schema, attrs \\ []) do
    schema
    |> struct()
    |> changeset(build_map(schema, :insert, attrs))
    |> then(&apply(@repo, :insert!, [&1, []]))
  end

  defp build_map(schema, mode, attrs) do
    impl = Module.concat(Mishras.Factory, schema)

    attrs
    |> Map.new()
    |> add_primary_key(mode, schema, impl)
    |> then(&Map.merge(impl.build_map(mode, &1), &1))
    |> expand_associations(mode, schema)
    |> expand_embeds(schema)
  end

  defp expand_associations(attrs, mode, schema) do
    :associations
    |> schema.__schema__()
    |> Enum.reduce(attrs, &expand_association(&2, &1, mode, schema))
  end

  defp expand_association(attrs, assoc, mode, schema) do
    case {attrs, schema.__schema__(:association, assoc)} do
      {attrs,
       %{cardinality: :one, owner_key: key, relationship: :parent, queryable: assoc_schema}}
      when is_map_key(attrs, key) ->
        if mode == :insert do
          found = apply(@repo, :get!, [assoc_schema, attrs[key], []])

          attrs
          |> Map.delete(key)
          |> Map.put(assoc, found)
        else
          # ablate the attrs key
          Map.delete(attrs, assoc)
        end

      {%{^assoc => %assoc_schema{} = object}, %{cardinality: :one, queryable: assoc_schema}} ->
        Map.replace!(attrs, assoc, assoc_schema.changeset(object, %{}))

      {%{^assoc => assoc_map}, %{cardinality: :one, queryable: assoc_schema}} ->
        Map.replace!(attrs, assoc, build_map(assoc_schema, mode, assoc_map))

      {%{^assoc => object_list}, %{cardinality: :many, queryable: assoc_schema}}
      when is_list(object_list) ->
        object_list
        |> Enum.map(fn
          object when is_struct(object, assoc_schema) ->
            assoc_schema.changeset(object, %{})

          object when is_map(object) ->
            build(assoc_schema, object)
        end)
        |> then(&Map.replace!(attrs, assoc, &1))

      # if the association is not present, we just return the attrs unchanged.
      {attrs, _} ->
        attrs
    end
  end

  defp expand_embeds(attrs, schema) do
    :embeds
    |> schema.__schema__()
    |> Enum.reduce(attrs, &expand_embed(&2, &1, schema))
  end

  defp expand_embed(attrs, embed, schema) do
    case {attrs, schema.__schema__(:embed, embed)} do
      {%{^embed => %embed_mod{} = object}, %{cardinality: :one, related: embed_mod}} ->
        Map.replace!(attrs, embed, embed_mod.changeset(object, %{}))

      {%{^embed => embed_map}, %{cardinality: :one, related: embed_mod}} ->
        Map.replace!(attrs, embed, build(embed_mod, embed_map))

      {%{^embed => object_list}, %{cardinality: :many, related: embed_mod}}
      when is_list(object_list) ->
        object_list
        |> Enum.map(fn
          object when is_struct(object, embed_mod) ->
            embed_mod.changeset(object, %{})

          object when is_map(object) ->
            build(embed_mod, object)
        end)
        |> then(&Map.replace!(attrs, embed, &1))

      {attrs, _} ->
        attrs
    end
  end
end
