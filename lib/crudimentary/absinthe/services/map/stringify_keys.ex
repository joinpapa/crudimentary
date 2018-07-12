defmodule CRUDimentary.Absinthe.Services.Map.StringifyKeys do
  def call(map), do: stringify_keys(map)

  defp stringify_keys(nil), do: nil
  defp stringify_keys(%_{} = struct), do: struct
  defp stringify_keys(map) when is_map(map), do: stringify_map_keys(map)
  defp stringify_keys(other), do: other

  defp stringify_map_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end
end
