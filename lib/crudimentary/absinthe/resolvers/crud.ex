defmodule CRUDimentary.Absinthe.Resolvers.CRUD do
  import CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    ResultFormatter,
    Querying,
    Pagination
  }

  @repo Application.get_env(CRUDimentary.MixProject.project()[:app], :repo)

  defmacro __using__(params) do
    quote do
      use CRUDimentary.Absinthe.Resolvers.Base

      @actions [:index, :show, :create, :update, :destroy]

      def call(current_account, parent, args, resolution) do
        action = unquote(params[:action])

        if action in @actions do
          params = [
            unquote(params[:schema]),
            current_account,
            parent,
            args,
            resolution,
            unquote(params[:options])
          ]

          apply(unquote(__MODULE__), action, params)
        else
          raise(ArgumentError, message: "unknown action #{action}")
        end
      end
    end
  end

  @doc """
  Returns paginated list of resources based uppon resolvers policy for currently logged user.
  Also it applies filtering, sorting and pagination functions.
  In opposite it raises authorization error.
  """
  @spec index(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map, pagination: ResultFormatter.pagination_result()}} | {:error, any}
  def index(schema, current_account, parent, args, _resolution, options \\ []) do
    with repo <- options[:repo] || @repo,
         policy <- options[:policy] || policy_module(schema),
         {:authorized, true} <- {:authorized, authorized?(policy, current_account, :index)} do
      schema
      |> scope(current_account, parent, policy)
      |> filter(args[:filter], options[:mapping], options[:filters])
      |> sort(args[:sorting])
      |> paginate(args[:sorting], args[:pagination], repo)
      |> result(options[:mapping])
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @doc """
  Shows and existing resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization error.
  """
  @spec show(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map, pagination: ResultFormatter.pagination_result()}} | {:error, any}
  def show(schema, current_account, _parent, args, _resolution, options \\ []) do
    with repo <- options[:repo] || @repo,
         policy <- options[:policy] || policy_module(schema),
         resource <- repo.get_by(schema, id: args[:id]),
         {:authorized, true} <- {:authorized, authorized?(policy, resource, current_account, :show)} do
      {:ok, resource}
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @doc """
  Creates and returns new resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization, changeset or insertion error.
  """
  @spec create(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map}} | {:error, any}
  def create(schema, current_account, _parent, args, _resolution, options \\ []) do
    with repo <- options[:repo] || @repo,
         policy <- options[:policy] || policy_module(schema),
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

  @doc """
  Updates and returns existing resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization, changeset or update error.
  """
  @spec update(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map, pagination: ResultFormatter.pagination_result()}} | {:error, any}
  def update(schema, current_account, _parent, args, _resolution, options \\ []) do
    with repo <- options[:repo] || @repo,
         {:resource, %schema{} = resource} <- {:resource, repo.get(schema, args[:id])},
         policy <- options[:policy] || policy_module(schema),
         {:authorized, true} <-
           {:authorized, authorized?(policy, resource, current_account, :update)},
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
      result(updated_resource)
    else
      {:authorized, _} -> {:error, :unauthorized}
      {:resource, _} -> {:error, :no_resource}
      {:error, _, changeset, _} -> {:error, changeset}
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  @doc """
  Deletes and returns last instance of resource based uppon resolvers policy for currently logged user.
  In opposite it raises authorization, changeset or deletion error.
  """
  @spec destroy(
          schema :: Ecto.Schema.t(),
          current_account :: Ecto.Schema.t(),
          parent :: Ecto.Schema.t(),
          args :: map,
          resolution :: map,
          options :: keyword
        ) :: {:ok, %{data: map}} | {:error, any}
  def destroy(schema, current_account, _parent, args, _resolution, options \\ []) do
    with repo <- options[:repo] || @repo,
         policy <- options[:policy] || policy_module(schema),
         resource <- repo.get_by(schema, id: args[:id]),
         {:resource, false} <- {:resource, is_nil(resource)},
         {:authorized, true} <-
           {:authorized, authorized?(policy, resource, current_account, :destroy)},
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
