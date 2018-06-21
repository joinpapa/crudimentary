defmodule CRUDimentary.Absinthe.Generator.ResultType do
  defmacro generic_result_types(name) do
    quote do
      unquote(__MODULE__).result_types(unquote(name), unquote(name))
    end
  end

  defmacro result_types(name, type) do
    quote do
      object(unquote(__MODULE__.result_name(name, :list))) do
        field(:data, list_of(unquote(type)))
        field(:pagination, :pagination)
      end

      object(unquote(__MODULE__.result_name(name, :single))) do
        field(:data, unquote(type))
        field(:pagination, :pagination)
      end
    end
  end

  def result_name(name, count) do
    String.to_atom("#{name}_#{count}_result")
  end
end
