defmodule CRUDimentary.Absinthe.Cache.InMemory do
  use Agent

  def start_link(map \\ %{}) do
    Agent.start_link(fn -> map end)
  end

  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  def set(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  def delete(bucket, key) do
    Agent.update(bucket, &Map.drop(&1, [key]))
  end
end
