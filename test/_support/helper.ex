defmodule Mishras.Helper do
  alias Ecto.Changeset

  def required_assoc_or_id(changeset = %{data: %schema{}}, assoc, attrs) do
    assoc_id = schema.__schema__(:association, assoc).owner_key

    case {Map.get(attrs, assoc), Changeset.get_field(changeset, assoc_id)} do
      {nil, nil} ->
        Changeset.validate_required(changeset, [assoc_id])

      {_assoc_data, nil} ->
        Changeset.cast_assoc(changeset, assoc)

      {nil, _} ->
        changeset

      _ ->
        raise ArgumentError, "Both #{assoc} and #{assoc_id} cannot be provided"
    end
  end
end
