defmodule CRUDimentary.Absinthe.Resolvers.Services.Pagination do
  @moduledoc false

  import CRUDimentary.Absinthe.Resolvers.Services.Querying, only: [sort_list: 1]

  def paginate(queryable, sortings, pagination, repo, options \\ []) do
    opts = create_opts(sortings, pagination, options)
    repo.paginate(queryable, opts)
  end

  def create_opts(sortings, pagination, options) do
    {direction, _} = sort_list(sorting_opts) |> List.first()

    [
      include_total_count: true,
      cursor_fields: cursor_fields_from_sortings(sorting_opts),
      limit: cap_pagination_limit(pagination_opts[:limit], []),
      after: pagination_opts[:after_cursor],
      before: pagination_opts[:before_cursor],
      sort_direction: direction
    ]
    |> Keyword.delete(:after, nil)
    |> Keyword.delete(:before, nil)
  end

  def cursor_fields_from_sortings(sortings) do
    Enum.map(sortings || [], fn {key, _} ->
      String.to_atom("#{key}")
    end) ++ [:inserted_at]
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
