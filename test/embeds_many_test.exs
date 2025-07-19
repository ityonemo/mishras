defmodule Mishras.EmbedsManyTest do
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
      |> Changeset.put_embed(:embed, attrs[:embed])
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
  end

  describe "embeds many schema build" do
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

    test "can be inserted with an existing struct" do
      child = Factory.build(EmbeddedSchema, %{})

      assert %EmbedsManySchema{embed: [^child]} =
               Factory.build(EmbedsManySchema, %{embed: [child]})
    end
  end

  describe "has many schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsManySchema{embed: [%EmbeddedSchema{field: "foobar"}]} =
               Factory.insert(EmbedsManySchema, %{})
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
