defmodule CRUDimentary.Cache.InMemory do
  use Agent

  @doc """
  Creates new agent (GenServer) link for managing cache values.

  ## Examples

      iex> CRUDimentary.Absinthe.Cache.InMemory.start_link()
      {:ok, pid}
  """
  @spec start_link(map :: map) :: {:ok, pid}
  def start_link(map \\ %{}) do
    Agent.start_link(fn -> map end)
  end

  @doc """
  Fetches specific value from the session cache bucket map.

  ## Examples

      iex> CRUDimentary.Absinthe.Cache.InMemory.get(pid, :key)
      :value
  """
  @spec get(bucket :: pid, key :: atom) :: any
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Saves key-value pair to the session cache bucket map.

  ## Examples

      iex> CRUDimentary.Absinthe.Cache.InMemory.set(pid, :key, :value)
      :ok
  """
  @spec set(bucket :: pid, key :: atom, value :: any) :: atom
  def set(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Deletes key from the session cache bucket map.

  ## Examples

      iex> CRUDimentary.Absinthe.Cache.InMemory.delete(pid, :key)
      :ok
  """
  @spec delete(bucket :: pid, key :: atom) :: atom
  def delete(bucket, key) do
    Agent.update(bucket, &Map.drop(&1, [key]))
  end
end
