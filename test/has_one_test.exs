defmodule Mishras.HasOneTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule ChildSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    schema "child" do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field])
      |> Changeset.validate_required([:field])
    end
  end

  defmodule HasOneSchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "has_one" do
      has_one(:child, ChildSchema)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id])
      |> Changeset.put_assoc(:child, attrs[:child])
    end
  end

  defimpl Mishras.Factory, for: ChildSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  defimpl Mishras.Factory, for: HasOneSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{child: %{}}
    end
  end

  describe "has one schema changeset" do
    test "is provided with sane defaults" do
      assert %HasOneSchema{child: %ChildSchema{field: "foobar"}} =
               Factory.build(HasOneSchema, %{})
    end

    test "can be overridden internally" do
      assert %HasOneSchema{child: %ChildSchema{field: "baz"}} =
               Factory.build(HasOneSchema, child: %{field: "baz"})
    end 

    test "can be inserted with an existing struct" do
      child = Factory.build(ChildSchema, %{})

      assert %HasOneSchema{child: ^child} =
               Factory.build(HasOneSchema, %{child: child})
    end
  end

  describe "has one schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %HasOneSchema{child: %ChildSchema{field: "foobar"}} =
               Factory.insert(HasOneSchema, %{})
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      child = Factory.insert(ChildSchema, %{})

      assert %HasOneSchema{child: ^child} =
               Factory.insert(HasOneSchema, %{child: child})
    end
  end
end
