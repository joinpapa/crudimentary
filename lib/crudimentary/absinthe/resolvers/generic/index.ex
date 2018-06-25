defmodule CRUDimentary.Absinthe.Resolvers.Generic.Index do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter,
    Querying,
    Pagination
  }

  @doc """
  Returns paginated list of resources based uppon resolvers policy for currently logged user.
  Also it applies filtering, sorting and pagination functions.
  In opposite it raises authorization error.
  """
  @spec call(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map, pagination: ResultFormatter.pagination_result()}} | {:error, any}
  def call(schema, current_account, _parent, args, _resolution, options) do
    with repo <- options[:repo],
         policy <- options[:policy],
         {:authorized, true} <- {:authorized, authorized?(policy, current_account, :index)} do
      schema
      |> scope(current_account, policy)
      |> filter(args[:filter], options[:mapping], options[:filters])
      |> sort(args[:sorting])
      |> paginate(args[:sorting], args[:pagination], repo)
      |> result_from_pagination(options[:mapping])
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
