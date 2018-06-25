defmodule CRUDimentary.Absinthe.Generator.Enum do
  @moduledoc false

  defmacro filter_enum_input(enum) do
    quote do
      input_object unquote(String.to_atom("filter_#{enum}_input")) do
        field(:eq, unquote(enum))
        field(:ne, unquote(enum))
        field(:in, list_of(unquote(enum)))
        field(:not_in, list_of(unquote(enum)))
      end
    end
  end
end
