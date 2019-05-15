defmodule CRUDimentary.Absinthe.Resolvers.Services.Pagination do
  @moduledoc false

  import CRUDimentary.Absinthe.Resolvers.Services.Querying, only: [sort_list: 1]

  def paginate(queryable, sortings, pagination, repo, options \\ []) do
    {direction, _} = sort_list(sortings) |> List.first()

    opts =
      [
        include_total_count: true,
        cursor_fields: cursor_fields_from_sortings(sortings),
        limit: cap_pagination_limit(pagination[:limit], options),
        after: pagination[:after_cursor],
        before: pagination[:before_cursor],
        sort_direction: direction
      ]
      |> Keyword.delete(:after, nil)
      |> Keyword.delete(:before, nil)

    repo.paginate(queryable, opts)
  end

  def cursor_fields_from_sortings(sortings) do
    Enum.map(sortings || [], fn {key, _} ->
      String.to_atom("#{key}")
    end) ++ [:id, :inserted_at]
  end

  def cap_pagination_limit(limit, options \\ [])

  def cap_pagination_limit(limit, options) when is_integer(limit) do
    max = options[:max_page_size] || 50

    cond do
      limit < 1 -> 1
      limit > max -> max
      true -> limit
    end
  end

  def cap_pagination_limit(_, options) do
    options[:default_page_size] || 30
  end
end
