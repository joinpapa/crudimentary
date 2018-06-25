defmodule CRUDimentary.Absinthe.Resolvers.Generic.Create do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter
  }

  @doc """
  Creates and returns new resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization, changeset or insertion error.
  """
  @spec call(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map}} | {:error, any}
  def call(schema, current_account, _parent, args, _resolution, options) do
    with repo <- options[:repo],
         policy <- options[:policy],
         {:authorized, true} <- {:authorized, authorized?(policy, current_account, :create)},
         params <-
           apply_mapping(args[:input], options[:mapping])
           |> permitted_params(current_account, policy),
         changeset <-
           apply(
             schema,
             options[:changeset_function] || :changeset,
             [struct(schema, []), params]
           ),
         {:ok, resource} <- repo.insert(changeset) do
      result(resource)
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
