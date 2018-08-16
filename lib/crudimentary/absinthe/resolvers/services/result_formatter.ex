defmodule CRUDimentary.Absinthe.Resolvers.Services.ResultFormatter do
  @moduledoc false

  alias Paginator.Page.Metadata

  @type pagination_result :: %{
          after_cursor: Metadata.opaque_cursor(),
          before_cursor: Metadata.opaque_cursor(),
          limit: integer,
          total_count: integer
        }

  def result(queriable, mapping \\ nil)
  def result({:error, _, error, _}, _) do
    {:error, error}
  end
  def result({:error, error}, _) do
    {:error, error}
  end
  def result({:ok, queriable}, mapping) do
    result(queriable, mapping)
  end
  def result(%{entries: queriable, metadata: metadata}, mapping) do
    {
      :ok,
      %{
        data: queriable |> apply_mapping(mapping) |> data_load(),
        pagination: format_pagination(metadata)
      }
    }
  end
  def result(queriable, mapping) do
    {:ok, %{data: queriable |> apply_mapping(mapping)}}
  end

  def format_pagination(%Metadata{} = pagination) do
    %{
      after_cursor: pagination.after,
      before_cursor: pagination.before,
      limit: pagination.limit,
      total_count: pagination.total_count
    }
  end
  def format_pagination(_), do: nil

  def apply_mapping(data, nil), do: data
  def apply_mapping(data, mapping) when is_map(mapping) do
    string_data = CRUDimentary.Absinthe.Services.Map.StringifyKeys.call(data)
    Enum.reduce(mapping, string_data, fn {map_from, map_to}, object ->
      case JSONPointer.get(string_data, map_from) do
        {:ok, value} ->
          {:ok, object, _} = JSONPointer.remove(object, map_from)
          JSONPointer.set!(object, map_to, value)
        {:error, _} ->
          object
      end
    end)
  end
  def apply_mapping(data, _), do: data

  def data_load(data) when is_list(data), do: Enum.map(data, &data_load/1)
  def data_load(data), do: data
end
