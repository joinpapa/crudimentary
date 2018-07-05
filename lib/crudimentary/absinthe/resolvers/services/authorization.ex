defmodule CRUDimentary.Absinthe.Resolvers.Services.Authorization do
  @moduledoc false

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

  def policy_module(%Ecto.Query{} = queriable) do
    {_, schema} = Ecto.Queryable.to_query(queriable).from
    policy_module(schema)
  end

  def policy_module(schema) do
    case Module.split(schema) do
      [project_module, context_module, schema_module] ->
        Module.concat([project_module, context_module, Policies, schema_module])
      [project_module, schema_module] ->
        Module.concat([project_module, Policies, schema_module])
    end
  end

  defp filter_map(map, permission_list) do
    Enum.reduce(map, %{}, &filter_map(&1, &2, permission_list))
  end

  defp filter_map({key, %_{} = value}, map, permitted_params) do
    add_if_member(map, key, value, permitted_params)
  end

  defp filter_map({key, %{} = value}, map, permitted_params) when is_map(value) do
    if permitted_params[key] do
      Map.put(map, key, filter_map(value, permitted_params[key]))
    else
      map
    end
  end

  defp filter_map({key, value}, map, permitted_params) do
    add_if_member(map, key, value, permitted_params)
  end

  defp add_if_member(map, key, value, list) do
    if Enum.member?(list, key) do
      Map.put(map, key, value)
    else
      map
    end
  end
end
