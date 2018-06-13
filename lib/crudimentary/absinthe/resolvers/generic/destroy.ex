defmodule CRUDimentary.Absinthe.Resolvers.Generic.Destroy do
  import CRUDimentary.Absinthe.Resolvers.Generic

  def call(_schema, current_account, _parent, args, _resolution, options) do
    with repo <- options[:repo],
         policy <- options[:policy],
         resource <- repo.get_by(id: args[:id]),
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
