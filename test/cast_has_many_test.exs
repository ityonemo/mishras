defmodule Mishras.CastHasManyTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule ChildSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    schema "children" do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field])
      |> Changeset.validate_required([:field])
    end
  end

  defmodule HasManySchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "has_many" do
      has_many(:children, ChildSchema)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id])
      |> Changeset.cast_assoc(:children)
    end
  end

  defimpl Mishras.Factory, for: ChildSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  defimpl Mishras.Factory, for: HasManySchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{children: [%{}]}
    end
  end

  describe "cast has many schema build" do
    test "is provided with sane defaults" do
      assert %HasManySchema{children: [%ChildSchema{field: "foobar"}]} =
               Factory.build(HasManySchema, %{})
    end

    test "can be overridden" do
      assert %HasManySchema{children: [%ChildSchema{field: "baz"}]} =
               Factory.build(HasManySchema, children: [%{field: "baz"}])
    end

    test "can have zero" do
      assert %HasManySchema{children: []} =
               Factory.build(HasManySchema, children: [])
    end

    test "can be built with an existing struct" do
      child = Factory.build(ChildSchema, %{})

      assert %HasManySchema{children: [^child]} =
               Factory.build(HasManySchema, %{children: [child]})
    end
  end

  describe "cast has many schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %HasManySchema{children: [%ChildSchema{field: "foobar"}]} =
               Factory.insert(HasManySchema, %{})
    end

    test "can be overridden with a map" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %HasManySchema{children: [%ChildSchema{field: "baz"}]} =
               Factory.insert(HasManySchema, children: [%{field: "baz"}])
    end

    test "can have zero" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %HasManySchema{children: []} =
               Factory.insert(HasManySchema, children: [])
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      child = Factory.insert(ChildSchema, %{})

      assert %HasManySchema{children: [^child]} =
               Factory.insert(HasManySchema, %{children: [child]})
    end
  end
end
