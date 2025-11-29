defmodule Mishras.InsertOverrideTest do
  use ExUnit.Case, async: true

  alias Mishras.Factory

  defmodule InsertOverrideSchema do
    use Ecto.Schema
    alias Ecto.Changeset

    schema "insert_override" do
      field(:field, :string)
      field(:custom_inserted, :boolean, virtual: true)
    end

    def changeset(struct \\ %__MODULE__{}, attrs) do
      struct
      |> Changeset.cast(attrs, [:id, :field, :custom_inserted])
      |> Changeset.validate_required([:field])
    end
  end

  defimpl Mishras.Factory, for: InsertOverrideSchema do
    use Mishras

    def build_map(_mode, _attrs) do
      %{field: "foobar"}
    end

    def insert(attrs) do
      %InsertOverrideSchema{
        field: attrs[:field] || "custom",
        custom_inserted: true
      }
    end
  end

  describe "insert override" do
    test "uses custom insert function when defined" do
      result = Factory.insert(InsertOverrideSchema, %{})
      assert result.custom_inserted == true
    end

    test "passes attrs to custom insert function" do
      result = Factory.insert(InsertOverrideSchema, %{field: "custom_value"})
      assert result.field == "custom_value"
      assert result.custom_inserted == true
    end
  end
end
