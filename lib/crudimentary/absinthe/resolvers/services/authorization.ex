defmodule CRUDimentary.Absinthe.Resolvers.Services.Authorization do
  def permitted_params(params, schema, account, policy) do
    permitted_fields = policy.permitted_params(schema, account)
    Map.drop(params, permitted_fields)
  end

  def authorized?(policy, account, action) do
    authorized?(policy, nil, account, action)
  end

  def authorized?(policy, record, account, action) do
    policy.authorized?(action, record, account)
  end
end
