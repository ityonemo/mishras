defmodule Mishras.CastEmbedsOneTest do
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

  defmodule EmbedsOneSchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "has_embed" do
      embeds_one(:embed, EmbeddedSchema)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id])
      |> Changeset.cast_embed(:embed)
    end
  end

  defimpl Mishras.Factory, for: EmbeddedSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  defimpl Mishras.Factory, for: EmbedsOneSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{embed: %{}}
    end
  end

  describe "cast embeds one schema build" do
    test "is provided with sane defaults" do
      assert %EmbedsOneSchema{embed: %EmbeddedSchema{field: "foobar"}} =
               Factory.build(EmbedsOneSchema, %{})
    end

    test "can be overridden" do
      assert %EmbedsOneSchema{embed: %EmbeddedSchema{field: "baz"}} =
               Factory.build(EmbedsOneSchema, embed: %{field: "baz"})
    end

    test "can be built with an existing struct" do
      child = Factory.build(EmbeddedSchema, %{})

      assert %EmbedsOneSchema{embed: ^child} =
               Factory.build(EmbedsOneSchema, %{embed: child})
    end
  end

  describe "cast embeds one schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsOneSchema{embed: %EmbeddedSchema{field: "foobar"}} =
               Factory.insert(EmbedsOneSchema, %{})
    end

    test "can be overridden with a map" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %EmbedsOneSchema{embed: %EmbeddedSchema{field: "baz"}} =
               Factory.insert(EmbedsOneSchema, embed: %{field: "baz"})
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      child = Factory.insert(EmbeddedSchema, %{})

      assert %EmbedsOneSchema{embed: ^child} =
               Factory.insert(EmbedsOneSchema, %{embed: child})
    end
  end
end
