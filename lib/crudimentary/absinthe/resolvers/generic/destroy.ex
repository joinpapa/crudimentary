defmodule CRUDimentary.Absinthe.Respolvers.Generic.Destroy do
  import CRUDimentary.Absinthe.Respolvers.Generic

  def call(schema, _current_account, _parent, args, _resolution, options) do
    when \
      repo <- options[:repo],
      policy <- options[:policy],
      resource <- repo.get_by(id: args[:id]),
      {:authorized, true} <-
        {:authorized, authorized?(policy, resource, current_account, :destroy)},
      {:resource, false} <- {:resource, is_nil(resource)},
      {:destroy, {:ok, result}} <- {:destroy, repo.delete(resource)}
    do
      result(resource)
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:resource, _} -> {:error, :non_existant_resource},
      {:destroy, _} -> {:error, :unable_to_destroy_resource}
      error -> {:error, error}
    end
  end
end
