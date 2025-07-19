defmodule Mishras.BelongsToTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule ParentSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    schema "parents" do
      field(:field, :string)
      field(:other_field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field, :other_field])
      |> Changeset.validate_required([:field])
    end
  end

  defmodule BelongsToSchema do
    use Ecto.Schema
    alias Ecto.Changeset
    alias Mishras.Helper

    schema "belongs_to" do
      belongs_to(:parent, ParentSchema)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :parent_id])
      |> Helper.required_assoc_or_id(:parent, attrs)
    end
  end

  defimpl Mishras.Factory, for: ParentSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{
        field: "foobar",
        other_field: "barbaz"
      }
    end
  end

  defimpl Mishras.Factory, for: BelongsToSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{parent: %{}}
    end
  end

  describe "belongs to schema build" do
    test "is provided with sane defaults" do
      assert %BelongsToSchema{parent: %ParentSchema{field: "foobar"}} =
               Factory.build(BelongsToSchema, %{})
    end

    test "parent can be overridden internally" do
      # note that "other field" is untouched.
      assert %BelongsToSchema{parent: %ParentSchema{field: "baz", other_field: "barbaz"}} =
               Factory.build(BelongsToSchema, parent: %{field: "baz"})
    end


    test "can be inserted with an existing struct" do
      parent = Factory.build(ParentSchema, %{other_field: "boop"})

      assert %BelongsToSchema{parent: ^parent} =
               Factory.build(BelongsToSchema, %{parent: parent})
    end

    test "is ok if you put an id on the parent" do
      parent_id = Enum.random(1..32767)

      assert %BelongsToSchema{parent_id: ^parent_id} =
               Factory.build(BelongsToSchema, %{parent_id: parent_id})
    end
  end

  describe "belongs to schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %BelongsToSchema{parent: %ParentSchema{field: "foobar"}} =
               Factory.insert(BelongsToSchema, %{})
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      parent = Factory.insert(ParentSchema, %{})

      assert %BelongsToSchema{parent: ^parent} =
               Factory.insert(BelongsToSchema, %{parent: parent})
    end

    test "is ok if you put an id on the parent" do
      parent_id = Enum.random(1..32767)

      Repo
      |> Mox.expect(:get!, fn ParentSchema, ^parent_id, _ ->
        Factory.build(ParentSchema, %{id: parent_id})
      end)
      |> Mox.expect(:insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)

        # adding the parent_id to the changeset is 100% on the database adapter to
        # do correctly.

        changeset
        |> Changeset.put_change(:parent_id, parent_id)
        |> Changeset.apply_action!(:insert)
      end)

      assert %BelongsToSchema{parent_id: ^parent_id} =
               Factory.insert(BelongsToSchema, %{parent_id: parent_id})
    end
  end
end
