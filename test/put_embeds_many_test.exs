defmodule Mishras.PutEmbedsManyTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule EmbeddedSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    embedded_schema do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:field])
      |> Changeset.validate_required([:field])
    end
  end

  defmodule EmbedsManySchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "has_embed" do
      embeds_many(:embed, EmbeddedSchema)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id])
      |> maybe_put_embed(:embed, attrs)
    end

    defp maybe_put_embed(changeset, key, attrs) do
      case Map.get(attrs, key) do
        nil -> changeset
        value -> Changeset.put_embed(changeset, key, value)
      end
    end
  end

  defimpl Mishras.Factory, for: EmbeddedSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  defimpl Mishras.Factory, for: EmbedsManySchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{embed: [%{}]}
    end

    def relation_type(_relation), do: :put
  end

  describe "put embeds many schema build" do
    test "is provided with sane defaults" do
      assert %EmbedsManySchema{embed: [%EmbeddedSchema{field: "foobar"}]} =
               Factory.build(EmbedsManySchema, %{})
    end

    test "can be overridden" do
      assert %EmbedsManySchema{embed: [%EmbeddedSchema{field: "baz"}]} =
               Factory.build(EmbedsManySchema, embed: [%{field: "baz"}])
    end

    test "can have zero" do
      assert %EmbedsManySchema{embed: []} =
               Factory.build(EmbedsManySchema, embed: [])
    end

    test "can be built with an existing struct" do
      child = Factory.build(EmbeddedSchema, %{})

      assert %EmbedsManySchema{embed: [^child]} =
               Factory.build(EmbedsManySchema, %{embed: [child]})
    end
  end

  describe "put embeds many schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsManySchema{embed: [%EmbeddedSchema{field: "foobar"}]} =
               Factory.insert(EmbedsManySchema, %{})
    end

    test "can be overridden with a map" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsManySchema{embed: [%EmbeddedSchema{field: "baz"}]} =
               Factory.insert(EmbedsManySchema, embed: [%{field: "baz"}])
    end

    test "can have zero" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsManySchema{embed: []} =
               Factory.insert(EmbedsManySchema, embed: [])
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      child = Factory.insert(EmbeddedSchema, %{})

      assert %EmbedsManySchema{embed: [^child]} =
               Factory.insert(EmbedsManySchema, %{embed: [child]})
    end
  end
end
