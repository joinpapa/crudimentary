defmodule CRUDimentary.Absinthe.Resolvers.Services.Authorization do
  def permitted_params(params, _policy) do
    # TODO: Implement
    params
  end

  def authorized?(policy, account, action) do
    authorized?(policy, nil, account, action)
  end

  def authorized?(policy, record, account, action) do
    policy.authorized?(action, record, account)
  end
end
