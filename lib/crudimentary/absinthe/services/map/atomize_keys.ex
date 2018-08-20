defmodule CRUDimentary.Absinthe.Services.Map.AtomizeKeys do
  def call(map), do: atomize_keys(map)

  defp atomize_keys(nil), do: nil
  defp atomize_keys(%_{} = struct), do: struct
  defp atomize_keys(map) when is_map(map), do: atomize_map_keys(map)
  defp atomize_keys(other), do: other

  defp atomize_map_keys(map) do
    for {k, v} <- map, into: %{}, do: {String.to_atom(k), v}
  end
end
