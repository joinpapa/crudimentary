defmodule CRUDimentary.Absinthe.Respolvers.Generic.Index do
  import CRUDimentary.Absinthe.Respolvers.Generic

  def call(schema, current_account, parent, args, resolution, options) do
    with \
      repo <- options[:repo],
      policy <- options[:policy],
      {:authorized, true} <-
        {:authorized, authorized?(policy, current_account, :index)},
    do
      schema
      |> scope(current_account, policy)
      |> filter(args[:filter], options[:mapping], options[:filters])
      |> sort(args[:sorting])
      |> paginate(args[:sorting], args[:pagination])
      |> result_from_pagination(options[:mapping])
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
