defmodule CRUDimentary.Absinthe.Middlewares.Default do
  def call(%{source: source} = resolution, %{field: field, object: object}) do
    with %_{} <- source,
         false <- String.ends_with?(object.name, "Result"),
         object_resolver when not is_nil(object_resolver) <- extract_object_resolver(object) do
      case object_resolver.(source, resolution.definition.argument_data, resolution) do
        {:ok, value} ->
          add_resolution_value(resolution, value)

        {:middleware, module, opts} ->
          add_resolution_middlware(resolution, {module, opts})
      end
    else
      _ ->
        add_resolution_value(resolution, Map.get(source, field.identifier))
    end
  end

  defp extract_object_resolver(object) do
    object_module = object.__reference__.module

    if Keyword.has_key?(object_module.__info__(:functions), :object_resolver) do
      &object.__reference__.module.object_resolver.call/3
    else
      nil
    end
  end

  defp add_resolution_value(resolution, value) do
    %{resolution | state: :resolved, value: value}
  end

  defp add_resolution_middlware(resolution, middleware) do
    %{resolution | state: :unresolved, middleware: [middleware | resolution.middleware]}
  end
end
