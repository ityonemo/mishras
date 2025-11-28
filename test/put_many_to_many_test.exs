defmodule Mishras.PutManyToManyTest do
  use ExUnit.Case, async: true

  setup {Mox, :verify_on_exit!}

  alias Ecto.Changeset
  alias Mishras.Factory
  alias MishrasTest.Repo

  defmodule OtherSchema do
    use Ecto.Schema

    alias Ecto.Changeset

    schema "others" do
      field(:field, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field])
      |> Changeset.validate_required([:field])
    end
  end

  defmodule ManyToManySchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "many_to_many" do
      many_to_many(:others, OtherSchema, join_through: "many_to_many_others")
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id])
      |> maybe_put_assoc(:others, attrs)
    end

    defp maybe_put_assoc(changeset, key, attrs) do
      case Map.get(attrs, key) do
        nil -> changeset
        value -> Changeset.put_assoc(changeset, key, value)
      end
    end
  end

  defimpl Mishras.Factory, for: OtherSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end
  end

  defimpl Mishras.Factory, for: ManyToManySchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{others: [%{}]}
    end

    def relation_type(_relation), do: :put
  end

  describe "put many to many schema build" do
    test "is provided with sane defaults" do
      assert %ManyToManySchema{others: [%OtherSchema{field: "foobar"}]} =
               Factory.build(ManyToManySchema, %{})
    end

    test "can be overridden internally" do
      assert %ManyToManySchema{others: [%OtherSchema{field: "baz"}]} =
               Factory.build(ManyToManySchema, others: [%{field: "baz"}])
    end

    test "can have zero" do
      assert %ManyToManySchema{others: []} = Factory.build(ManyToManySchema, others: [])
    end

    test "can be built with an existing struct" do
      other = Factory.build(OtherSchema, %{})

      assert %ManyToManySchema{others: [^other]} =
               Factory.build(ManyToManySchema, %{others: [other]})
    end
  end

  describe "put many to many schema insert" do
    test "is provided with sane defaults" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %ManyToManySchema{others: [%OtherSchema{field: "foobar"}]} =
               Factory.insert(ManyToManySchema, %{})
    end

    test "can be overridden with a map" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %ManyToManySchema{others: [%OtherSchema{field: "baz"}]} =
               Factory.insert(ManyToManySchema, others: [%{field: "baz"}])
    end

    test "can have zero" do
      Mox.expect(Repo, :insert!, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      assert %ManyToManySchema{others: []} =
               Factory.insert(ManyToManySchema, others: [])
    end

    test "can be inserted with an existing struct" do
      Mox.expect(Repo, :insert!, 2, fn changeset, _ ->
        refute Changeset.get_field(changeset, :id)
        Changeset.apply_action!(changeset, :insert)
      end)

      other = Factory.insert(OtherSchema, %{})

      assert %ManyToManySchema{others: [^other]} =
               Factory.insert(ManyToManySchema, %{others: [other]})
    end
  end
end
