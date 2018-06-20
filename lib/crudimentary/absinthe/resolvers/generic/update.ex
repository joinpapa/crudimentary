defmodule CRUDimentary.Absinthe.Resolvers.Generic.Update do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter
  }

  def call(schema, current_account, _parent, args, _resolution, options) do
    with repo <- options[:repo],
         {:resource, %schema{} = resource} <- {:resource, repo.get(schema, args[:id])},
         policy <- options[:policy],
         params <-
           apply_mapping(args[:input], options[:mapping])
           |> permitted_params(current_account, policy),
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
      {:resource, _} -> {:error, :no_resource}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
