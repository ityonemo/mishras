defmodule Mishras.Helper do
  alias Ecto.Changeset

  def required_assoc_or_id(changeset = %{data: %schema{}}, assoc, attrs) do
    assoc_id = schema.__schema__(:association, assoc).owner_key

    case {Map.get(attrs, assoc), Changeset.get_field(changeset, assoc_id)} do
      {nil, nil} ->
        Changeset.validate_required(changeset, [assoc_id])

      {assoc_data, nil} ->
        Changeset.put_assoc(changeset, assoc, assoc_data)

      {nil, _} ->
        changeset

      _ ->
        raise ArgumentError, "Both #{assoc} and #{assoc_id} cannot be provided"
    end
  end

  def maybe_put_assoc(changeset, field, attrs) do
    exists? = !!Changeset.get_field(changeset, :id)

    missing? =
      exists? and match?(%Ecto.Association.NotLoaded{}, Map.fetch!(changeset.data, field))

    value = Map.get(attrs, field)

    if not missing? and value do
      Changeset.put_assoc(changeset, field, value)
    else
      changeset
    end
  end
end
