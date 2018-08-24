defmodule CRUDimentary.Absinthe.Middlewares.Default do
  def call(%{source: source} = resolution, %{field: field, object: object}) do
    value =
      unless String.ends_with?(object.name, "Result") do
        {:ok, value} =
          object.__reference__.module.object_resolver.call(source, field.args, resolution)
        value
      else
         Map.get(source, field.identifier)
      end
    %{resolution | state: :resolved, value: value}
  end
end
