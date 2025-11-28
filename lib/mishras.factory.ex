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

  ## Optional Callbacks

  ### `autogenerate_id/1`

  Override the default primary key generation behavior:

      def autogenerate_id(attrs) do
        Map.put(attrs, :id, MyApp.IdGenerator.generate())
      end

  ### `insert/2`

  Override the default insert behavior for custom persistence logic:

      def insert(schema, attrs) do
        schema
        |> struct()
        |> changeset(attrs)
        |> MyApp.Repo.insert!(returning: true)
      end

  This is useful when you need custom insert options, want to use a different
  repo, or need to perform additional operations during insertion.

  ### `relation_type/1`

  Control how associations and embeds are handled. Returns either `:cast` (default)
  or `:put`:

      def relation_type(_relation), do: :put

  Or handle different relations differently:

      def relation_type(:comments), do: :put
      def relation_type(_), do: :cast

  The difference between `:cast` and `:put`:

  - `:cast` - Relations are passed as maps to `cast_assoc`/`cast_embed`. The
    changeset function of the related schema validates and transforms the data.
    This is the default and works with most changesets that use `cast_assoc`
    or `cast_embed`.

  - `:put` - Relations are built as structs/changesets and passed to `put_assoc`/
    `put_embed`. Use this when your changeset uses `put_assoc` or `put_embed`
    instead of the cast variants.
  """

  @doc false
  def changeset(object, attrs)
after
  alias Ecto.Changeset

  @typedoc """
  The mode in which the factory is operating.

  - `:build` - Creating structs without database insertion
  - `:insert` - Creating and inserting records into the database
  """
  @type mode :: :build | :insert

  @typedoc """
  The strategy for handling relations (associations and embeds).

  - `:cast` - Pass data as maps for `cast_assoc`/`cast_embed` (default)
  - `:put` - Pass data as structs/changesets for `put_assoc`/`put_embed`
  """
  @type relation_type :: :cast | :put

  @doc """
  Returns a map of default attributes for building a schema.

  This is the primary callback that must be implemented. It should return
  a map containing default values for the schema's fields.

  ## Parameters

  - `mode` - Either `:build` or `:insert`, indicating how the data will be used
  - `attrs` - The attributes passed by the caller, useful for dependent fields

  ## Examples

      # Using attrs for dependent fields
      def build_map(_mode, attrs) do
        %{
          first_name: "John",
          last_name: "Doe",
          full_name: "\#{attrs[:first_name] || "John"} \#{attrs[:last_name] || "Doe"}"
        }
      end
  """
  @callback build_map(mode, attrs :: map) :: map

  @doc """
  Customizes primary key generation for the schema.

  By default, Mishras generates random integer IDs or UUIDs based on the
  schema's autogenerate configuration. Override this callback to provide
  custom ID generation logic.

  ## Parameters

  - `attrs` - The current attributes map

  ## Returns

  The attributes map with the primary key added.

  ## Examples

      def autogenerate_id(attrs) do
        Map.put(attrs, :id, MyApp.Snowflake.generate())
      end
  """
  @callback autogenerate_id(attrs :: map) :: map

  @doc """
  Customizes the insert behavior for the schema.

  Override this callback when you need custom persistence logic, such as
  using different insert options, a different repo, or performing additional
  operations during insertion.

  ## Parameters

  - `schema` - The schema module being inserted
  - `attrs` - The attributes map produced by `build_map/2` merged with caller overrides

  ## Returns

  The inserted struct.

  ## Examples

      def insert(schema, attrs) do
        schema
        |> struct()
        |> changeset(attrs)
        |> MyApp.Repo.insert!(returning: true, on_conflict: :replace_all)
      end
  """
  @callback insert(schema :: module, attrs :: map) :: struct

  @doc """
  Specifies how a relation should be handled when building data.

  This callback controls whether relations (associations and embeds) are
  processed for `cast_assoc`/`cast_embed` or `put_assoc`/`put_embed`.

  ## Parameters

  - `relation` - The name of the association or embed as an atom

  ## Returns

  - `:cast` - Data will be passed as maps (for `cast_assoc`/`cast_embed`)
  - `:put` - Data will be passed as structs/changesets (for `put_assoc`/`put_embed`)

  ## Examples

      # Use :put for all relations
      def relation_type(_relation), do: :put

      # Different handling per relation
      def relation_type(:comments), do: :put
      def relation_type(:profile), do: :cast
      def relation_type(_), do: :cast
  """
  @callback relation_type(relation :: atom) :: relation_type

  @optional_callbacks autogenerate_id: 1, insert: 2, relation_type: 1

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
    impl = Module.concat(Mishras.Factory, schema)

    if function_exported?(impl, :insert, 2) do
      impl.insert(schema, Map.new(attrs))
    else
      schema
      |> struct()
      |> changeset(build_map(schema, :insert, attrs))
      |> then(&apply(@repo, :insert!, [&1, []]))
    end
  end

  defp build_map(schema, mode, attrs) do
    impl = Module.concat(Mishras.Factory, schema)

    attrs
    |> Map.new()
    |> add_primary_key(mode, schema, impl)
    |> then(&Map.merge(impl.build_map(mode, &1), &1))
    |> expand_associations(mode, schema, impl)
    |> expand_embeds(schema, impl)
  end

  defp expand_associations(attrs, mode, schema, impl) do
    :associations
    |> schema.__schema__()
    |> Enum.reduce(attrs, &expand_association(&2, &1, mode, schema, impl))
  end

  defp get_relation_type(impl, relation) do
    if function_exported?(impl, :relation_type, 1) do
      impl.relation_type(relation)
    else
      :cast
    end
  end

  defp relation_from_struct(:cast, _schema, object), do: Map.from_struct(object)
  defp relation_from_struct(:put, schema, object), do: schema.changeset(object, %{})

  defp relation_from_map(:cast, schema, map) do
    impl = Module.concat(Mishras.Factory, schema)
    Map.merge(impl.build_map(:build, map), map)
  end

  defp relation_from_map(:put, schema, map), do: build(schema, map)

  defp expand_association(attrs, assoc, mode, schema, impl) do
    next_mode = assoc_mode(mode)
    relation_type = get_relation_type(impl, assoc)

    case {attrs, schema.__schema__(:association, assoc)} do
      {attrs,
       %{cardinality: :one, owner_key: key, relationship: :parent, queryable: assoc_schema}}
      when is_map_key(attrs, key) ->
        if mode == :insert do
          found = apply(@repo, :get!, [assoc_schema, attrs[key], []])

          attrs
          |> Map.delete(key)
          |> Map.put(assoc, relation_from_struct(relation_type, assoc_schema, found))
        else
          # ablate the attrs key
          Map.delete(attrs, assoc)
        end

      {%{^assoc => %assoc_schema{} = object}, %{cardinality: :one, queryable: assoc_schema}} ->
        Map.replace!(attrs, assoc, relation_from_struct(relation_type, assoc_schema, object))

      {%{^assoc => assoc_map}, %{cardinality: :one, queryable: assoc_schema}} ->
        Map.replace!(attrs, assoc, build_map(assoc_schema, next_mode, assoc_map))

      {%{^assoc => object_list}, %{cardinality: :many, queryable: assoc_schema}}
      when is_list(object_list) ->
        object_list
        |> Enum.map(fn
          object when is_struct(object, assoc_schema) ->
            relation_from_struct(relation_type, assoc_schema, object)

          object when is_map(object) ->
            build_map(assoc_schema, next_mode, object)
        end)
        |> then(&Map.replace!(attrs, assoc, &1))

      # if the association is not present, we just return the attrs unchanged.
      {attrs, _} ->
        attrs
    end
  end

  defp assoc_mode(:build), do: :build
  defp assoc_mode(:insert), do: :map
  defp assoc_mode(:map), do: :map

  defp expand_embeds(attrs, schema, impl) do
    :embeds
    |> schema.__schema__()
    |> Enum.reduce(attrs, &expand_embed(&2, &1, schema, impl))
  end

  defp expand_embed(attrs, embed, schema, impl) do
    relation_type = get_relation_type(impl, embed)

    case {attrs, schema.__schema__(:embed, embed)} do
      {%{^embed => %embed_mod{} = object}, %{cardinality: :one, related: embed_mod}} ->
        Map.replace!(attrs, embed, relation_from_struct(relation_type, embed_mod, object))

      {%{^embed => embed_map}, %{cardinality: :one, related: embed_mod}} ->
        Map.replace!(attrs, embed, relation_from_map(relation_type, embed_mod, embed_map))

      {%{^embed => object_list}, %{cardinality: :many, related: embed_mod}}
      when is_list(object_list) ->
        object_list
        |> Enum.map(fn
          object when is_struct(object, embed_mod) ->
            relation_from_struct(relation_type, embed_mod, object)

          object when is_map(object) ->
            relation_from_map(relation_type, embed_mod, object)
        end)
        |> then(&Map.replace!(attrs, embed, &1))

      {attrs, _} ->
        attrs
    end
  end
end
