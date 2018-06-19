defmodule CRUDimentary.Absinthe.Resolvers.Services.Cache do
  alias CRUDimentary.Cache.InMemory, as: Cache

  def cache_get(resolution, key) do
    agent = get_agent(resolution)

    if agent do
      Cache.get(agent, key)
    else
      nil
    end
  end

  def cache_set(resolution, key, value) do
    agent = get_agent(resolution)

    if agent do
      Cache.set(agent, key, value)
    else
      nil
    end
  end

  def cache_delete(resolution, key) do
    agent = get_agent(resolution)

    if agent do
      Cache.delete(agent, key)
    else
      nil
    end
  end

  def get_agent(resolution) do
    get_in(resolution.context, [:cache])
  end
end
