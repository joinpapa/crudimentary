defmodule CRUDimentary.Absinthe.Resolvers.Generic.Show do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter
  }

  @doc """
  Shows and existing resource based uppon resolvers policy for currently logged user.
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
         {:authorized, true} <- {:authorized, authorized?(policy, current_account, :show)},
         record <- repo.get_by(schema, id: args[:id]) do
      result(record)
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
