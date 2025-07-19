defmodule Mishras.BinaryIdSchemaTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule BinaryIdSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}

    schema "basic_binary_id" do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field])
      |> Changeset.validate_required([:field])
    end
  end

  defimpl Mishras.Factory, for: BinaryIdSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  test "binary id schema build" do
    assert %BinaryIdSchema{id: id, field: "foobar"} = Factory.build(BinaryIdSchema, %{})
    assert is_binary(id)
  end

  test "binary id schema insert" do
    # note, we don't auto-add id on insert.
    Mox.expect(Repo, :insert!, fn changeset, _ ->
      refute Changeset.get_field(changeset, :id)
      Changeset.apply_action!(changeset, :insert)
    end)

    assert %BinaryIdSchema{id: nil, field: "foobar"} = Factory.insert(BinaryIdSchema, %{})
  end
end
