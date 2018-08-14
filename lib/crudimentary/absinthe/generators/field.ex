defmodule CRUDimentary.Absinthe.Generator.Field do
  @moduledoc false

  defmacro has_many(name) do
    singularized_name = Inflex.singularize(name)
    quote do
      field unquote(name), unquote(String.to_atom("#{singularized_name}_list_result")) do
        arg :filter, list_of(unquote(String.to_atom("#{singularized_name}_filter")))
        arg :sorting, unquote(String.to_atom("#{singularized_name}_sorting"))
        arg :pagination, :pagination_input
      end
    end
  end
end
