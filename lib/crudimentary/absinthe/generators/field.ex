defmodule CRUDimentary.Absinthe.Generator.Field do
  @moduledoc false

  defmacro has_many(name, type \\ nil) do
    type = if type, do: type, else: Inflex.singularize(name)

    quote do
      field unquote(name), unquote(String.to_atom("#{type}_list_result")) do
        arg(:filter, list_of(unquote(String.to_atom("#{type}_filter"))))
        arg(:sorting, unquote(String.to_atom("#{type}_sorting")))
        arg(:pagination, :pagination_input)
      end
    end
  end
end
