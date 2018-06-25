defmodule CRUDimentary.Absinthe.Resolvers.Generic.Destroy do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter
  }

  @doc """
  Deletes and returns last instance of resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization, changeset or deletion error.
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
         resource <- repo.get_by(schema, id: args[:id]),
         {:authorized, true} <-
           {:authorized, authorized?(policy, resource, current_account, :destroy)},
         {:resource, false} <- {:resource, is_nil(resource)},
         {:destroy, {:ok, _}} <- {:destroy, repo.delete(resource)} do
      result(resource)
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:resource, _} -> {:error, :non_existant_resource}
      {:destroy, _} -> {:error, :unable_to_destroy_resource}
      error -> {:error, error}
    end
  end
end
