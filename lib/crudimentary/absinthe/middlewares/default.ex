defmodule CRUDimentary.Absinthe.Middlewares.Default do
  def call(%{source: source} = resolution, %{field: field, object: object}) do
    value =
      with \
        %_{} <- source,
        false <- String.ends_with?(object.name, "Result"),
        object_resolver when not is_nil(object_resolver) <- extract_object_resolver(object),
        {:ok, value} <- object_resolver.(source, field.args, resolution)
      do
        value
      else
        _ -> Map.get(source, field.identifier)
      end

    %{resolution | state: :resolved, value: value}
  end

  defp extract_object_resolver(object) do
    object_module = object.__reference__.module

    if Keyword.has_key?(object_module.__info__(:functions), :object_resolver) do
      &object.__reference__.module.object_resolver.call/3
    else
      nil
    end
  end
end
