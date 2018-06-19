defmodule CRUDimentary.Absinthe.Resolvers.Generic.Show do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter
  }

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
