defmodule Mishras.BasicSchemaTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule BasicSchema do
    use Ecto.Schema
    alias Ecto.Changeset

    # note there is an implicit integer id here, Mishra
    # should be able to put an implicit id.

    schema "basic" do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field])
      |> Changeset.validate_required([:field])
    end
  end

  defimpl Mishras.Factory, for: BasicSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  describe "basic schema build" do
    test "provides basics" do
      assert %BasicSchema{id: id, field: "foobar"} = Factory.build(BasicSchema, %{})
      assert is_integer(id)
    end

    test "can be overridden" do
      assert %BasicSchema{id: id, field: "baz"} = Factory.build(BasicSchema, %{field: "baz"})
      assert is_integer(id)
    end
  end

  describe "basic schema insert" do
    setup do
      # note, we don't auto-add id on insert.
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)
      :ok
    end

    test "provides basics" do
      assert %BasicSchema{id: nil, field: "foobar"} = Factory.insert(BasicSchema, %{})
    end

    test "can be overridden" do
      assert %BasicSchema{id: nil, field: "baz"} = Factory.insert(BasicSchema, %{field: "baz"})
    end
  end
end
