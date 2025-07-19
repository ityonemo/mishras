defmodule Mishras do
  @moduledoc """
  A utility module for factory implementations.

  This module provides a `__using__` macro that automatically delegates
  `changeset/2` calls to the base schema module when implementing the
  `Mishras.Factory` protocol.

  ## Usage

  When implementing the `Mishras.Factory` protocol for a schema, you can
  use this module to automatically delegate changeset calls:

      defimpl Mishras.Factory, for: MyApp.User do
        use Mishras
        
        def build_map(_mode, _attrs) do
          %{name: "John Doe", email: "john@example.com"}
        end
      end

  This will automatically create a `changeset/2` function that delegates
  to `MyApp.User.changeset/2`.
  """

  @doc """
  Provides automatic changeset delegation for factory implementations.

  When used in a factory implementation module, this macro automatically
  creates a `changeset/2` function that delegates to the corresponding
  schema module's `changeset/2` function.

  The schema module is determined by removing the `Mishras.Factory` prefix
  from the current module name.

  ## Examples

      defmodule Mishras.Factory.MyApp.User do
        use Mishras  # Delegates to MyApp.User.changeset/2
      end

  ## Raises

  Raises a compile-time error if used outside of a `Mishras.Factory.*` module.
  """
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
