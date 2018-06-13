defmodule CRUDimentary.Absinthe.Services.Map.StringifyKeys do
  def call(map) do
    stringify_keys(map)
  end

  defp is_struct?(struct) do
    Map.has_key?(struct, :__struct__)
  end

  defp stringify_keys(nil), do: nil
  defp stringify_keys(map) when is_map(map) do
    if is_struct?(map) do
      map
    else
      stringify_map_keys(map)
    end
  end
  defp stringify_keys(other), do: other

  defp stringify_map_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end
end
