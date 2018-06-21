defmodule CRUDimentary.Absinthe.Resolvers.Services.Authorization do
  def permitted_params(params, account, policy) do
    permitted_params = policy.permitted_params(account)
    filter_map(params, permitted_params)
  end

  def authorized?(policy, account, action) do
    authorized?(policy, nil, account, action)
  end

  def authorized?(policy, record, account, action) do
    policy.authorized?(action, record, account)
  end

  defp filter_map(map, permitted_keys) do
    Enum.reduce(map, %{}, &filter_map(&1, &2, permitted_keys))
  end
  defp filter_map({key, value}, map, permitted_params) when is_map(value) do
    if permitted_params[key] do
      Map.put(map, key, filter_map(value, permitted_params[key]))
    else
      map
    end
  end
  defp filter_map({key, value}, map, permitted_params) do
    if Enum.member?(permitted_params, key), do: Map.put(map, key, value), else: map
  end
end
