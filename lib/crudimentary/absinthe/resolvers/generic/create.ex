defmodule CRUDimentary.Absinthe.Resolvers.Generic.Create do
  import CRUDimentary.Absinthe.Resolvers.Generic

  def call(schema, current_account, _parent, args, _resolution, options) do
    with repo <- options[:repo],
         policy <- options[:policy],
         {:authorized, true} <- {:authorized, authorized?(policy, current_account, :create)},
         params <-
           apply_mapping(args[:input], options[:mapping])
           |> permitted_params(policy),
         changeset <-
           apply(
             schema,
             options[:changeset_function] || :changeset,
             [struct(schema, []), params]
           ),
         {:ok, resource} <- repo.insert(changeset) do
      {
        :ok,
        %{
          data: resource
        }
      }
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end
end
