defmodule CRUDimentary.Absinthe.Resolvers.Services.Pagination do
  @moduledoc false

  import CRUDimentary.Absinthe.Resolvers.Services.Querying, only: [sort_list: 1]

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
end
