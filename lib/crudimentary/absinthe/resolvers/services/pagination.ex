defmodule CRUDimentary.Absinthe.Resolvers.Services.Pagination do
  @moduledoc false

  import CRUDimentary.Absinthe.Resolvers.Services.Querying, only: [sort_list: 1]
  import Ecto.Query

  def create_pagination_config(sorting, pagination, opts) do
    sorting
    |> create_opts(pagination, opts)
    |> Paginator.Config.new()
  end

  def paginate(queryable, sortings, pagination, repo, options \\ []) do
    opts = create_opts(sortings, pagination, options)
    repo.paginate(queryable, opts)
  end

  def enum_paginate(queryable, repo, sorted_entries, config) do
    paginated_entries = Paginator.paginate_entries(sorted_entries, config)

    %Paginator.Page{
      entries: paginated_entries,
      metadata: %Paginator.Page.Metadata{
        before: nil,
        after: Paginator.after_cursor(paginated_entries, sorted_entries, config),
        limit: config.limit,
        total_count: total_count(repo, queryable)
      }
    }
  end

  def create_opts(sortings, pagination, _options) do
    {direction, _} = sort_list(sortings) |> List.first()

    [
      include_total_count: true,
      cursor_fields: cursor_fields_from_sortings(sortings),
      limit: cap_pagination_limit(pagination[:limit], []),
      after: pagination[:after_cursor],
      before: pagination[:before_cursor],
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

  defp total_count(repo, queryable) do
    queryable
    |> select(count("*"))
    |> repo.one()
  end
end
