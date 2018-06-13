defmodule CRUDimentary.Absinthe.Resolvers.Generic.Update do
  import CRUDimentary.Absinthe.Resolvers.Generic

  def call(schema, current_account, parent, args, resolution, options) do
    with repo <- options[:repo],
         {:resource, %schema{} = resource} <- {:resource, Repo.get(schema, args[:id])},
         policy <- options[:policy],
         params <-
           apply_mapping(args[:input], options[:mapping])
           |> permitted_params(policy),
         changeset <-
           apply(
             schema,
             options[:changeset_function] || :changeset,
             [resource, params]
           ),
         {:ok, updated_resource} <- repo.update(changeset) do
      {
        :ok,
        %{
          data: updated_resource
        }
      }
    else
      {:resource, _} -> Errors.no_resource()
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
