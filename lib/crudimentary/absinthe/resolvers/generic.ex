defmodule CRUDimentary.Absinthe.Resolvers.Generic do
  import Ecto.Query

  defmacro __using__(params) do
    quote do
      use CRUDimentary.Absinthe.Resolvers.Base

      def call(current_account, parent, args, resolution) do
        alias CRUDimentary.Absinthe.Resolvers.Generic

        module =
          case unquote(params[:action]) do
            :index ->
              Generic.Index

            :show ->
              Generic.Show

            :create ->
              Generic.Create

            :update ->
              Generic.Update

            :destroy ->
              Generic.Destroy

            _ ->
              raise("Unknown action")
          end

        module.call(
          unquote(params[:schema]),
          current_account,
          parent,
          args,
          resolution,
          unquote(params[:options])
        )
      end
    end
  end

  ##
  ## IMPLEMENTATION
  ##

  def scope_module(_schema, policy) do
    if function_exported?(policy, :scope, 2) do
      policy
    else
      nil
    end
  end

  def scope(schema, current_account, policy) do
    scope_module = scope_module(schema, policy)

    if scope_module do
      scope_module.scope(schema, current_account)
    else
      schema
    end
  end

  def filter(queriable, filters, mapping \\ %{}, custom_filters \\ %{}) do
    CRUDimentary.Ecto.Filter.call(
      queriable,
      filters,
      mapping,
      custom_filters
    )
  end

  def sort(queriable, sortings) do
    sorting = sort_list(sortings)
    order_by(queriable, ^sorting)
  end

  def sort_list(sortings) do
    Enum.map(sortings || [], fn {key, direction} ->
      {
        String.to_atom("#{direction}"),
        String.to_atom("#{key}")
      }
    end) ++ [desc: :inserted_at]
  end

  def paginate(queriable, sortings, pagination, repo) do
    {direction, _} = sort_list(sortings) |> List.first()

    options =
      [
        include_total_count: true,
        cursor_fields: cursor_fields_from_sortings(sortings),
        limit: cap_pagination_limit(pagination[:limit]),
        after: pagination[:after_cursor],
        before: pagination[:before_cursor],
        sort_direction: direction
      ]
      |> Keyword.delete(:after, nil)
      |> Keyword.delete(:before, nil)

    repo.paginate(queriable, options)
  end

  def cursor_fields_from_sortings(sortings) do
    Enum.map(sortings || [], fn {key, _} ->
      String.to_atom("#{key}")
    end) ++ [:inserted_at]
  end

  def cap_pagination_limit(limit) when is_integer(limit) do
    cond do
      limit < 1 -> 1
      limit > 50 -> 50
      true -> limit
    end
  end

  def cap_pagination_limit(_), do: 30

  def result_from_pagination(pagination, mapping \\ nil) do
    result(pagination.entries, mapping, pagination.metadata)
  end

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

  def data_load(data) when is_list(data) do
    Enum.map(data, &data_load/1)
  end

  def data_load(data) do
    data
  end

  def format_pagination(%Paginator.Page.Metadata{} = pagination) do
    %{
      after_cursor: pagination.after,
      before_cursor: pagination.before,
      limit: pagination.limit,
      total_count: pagination.total_count
    }
  end

  def format_pagination(_), do: nil
end
