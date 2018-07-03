defmodule CRUDimentary.Absinthe.Resolvers.Services.ResultFormatter do
  @moduledoc false

  alias Paginator.Page.Metadata

  @type pagination_result :: %{
          after_cursor: Metadata.opaque_cursor(),
          before_cursor: Metadata.opaque_cursor(),
          limit: integer,
          total_count: integer
        }

  def wrap_result(result) do
    case result do
      {:ok, result} -> {:ok, %{data: result}}
      {:error, _, error, _} -> {:error, error}
      error -> {:error, error}
    end
  end

  def result(queriable, mapping \\ nil, pagination \\ nil)

  def result({:error, _, error, _}, _, _) do
    {:error, error}
  end

  def result({:error, error}, _, _) do
    {:error, error}
  end

  def result({:ok, queriable}, mapping, pagination) do
    result(queriable, mapping, pagination)
  end

  def result(queriable, mapping, pagination) do
    {
      :ok,
      %{
        data: queriable |> apply_mapping(mapping) |> data_load(),
        pagination: format_pagination(pagination)
      }
    }
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

  def result_from_pagination(pagination, mapping \\ nil) do
    result(pagination.entries, mapping, pagination.metadata)
  end

  def apply_mapping(data, nil), do: data

  def apply_mapping(data, mapping) when is_list(mapping) do
    Enum.map(data, &apply_mapping(&1, mapping))
  end

  def apply_mapping(data, mapping) do
    string_data = CRUDimentary.Absinthe.Services.Map.StringifyKeys.call(data)

    Enum.reduce(mapping, data, fn {attribute, json_pointer}, object ->
      case JSONPointer.get(string_data, json_pointer) do
        {:ok, value} ->
          Map.put(object, attribute, value)

        {:error, _} ->
          object
      end
    end)
  end

  def data_load(nil), do: nil
  def data_load(data) when is_list(data), do: Enum.map(data, &data_load/1)
  def data_load(data), do: data
end
