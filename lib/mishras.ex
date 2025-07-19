defmodule Mishras do
  defmacro __using__(_) do
    base_module =
      case Module.split(__CALLER__.module) do
        ["Mishras", "Factory" | rest] ->
          Module.concat(rest)

        _ ->
          raise "use Mishras may only be called from an implementation of Mishras.Factory"
      end

    quote do
      defdelegate changeset(schema, attrs), to: unquote(base_module)
    end
  end
end
