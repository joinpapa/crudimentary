defmodule CRUDimentary.Absinthe.Generator.Endpoint do
  @moduledoc """
  This module defines generators for Absinthe GraphQL CRUD fields.
  By calling one of macros you can generate multiple queries or mutations with generic resolver callbacks, middleware and error handlers.
  """
  import CRUDimentary.Absinthe.Generator.ResultType

  @query_types [:index, :show]
  @mutation_types [:create, :update, :destroy]
  @error_handler  Confex.get_env(CRUDimentary.MixProject.project()[:app], :error_handler)

  @doc """
  Generates Absinthe schema query CRUD (index and show) fields based uppon options.

  ```
  query do

    CRUDimentary.Absinthe.EndpointGenerator.generic_query(
      :account,
      Project.API.Resolvers.Account,
      [
        error_handler: ErrorHandler,
        index: [
          middleware:
            [
              before: [Middleware, Middleware],
              after: [Middleware]
            ]
        ]
      ])

  end
  ```

  This results in generated fields:

  ```
  RootQueryType{
    account(id: ID!): AccountSingleResult

    accounts(
      filter: [AccountFilter]
      pagination: PaginationInput
      sorting: AccountSorting): AccountListResult
  }
  ```
  """
  defmacro generic_query(name, base_module, options \\ %{}) do
    for query_type <- @query_types do
      if included?(query_type, options) do
        quote do
          unquote(__MODULE__).generic_schema_field(
            unquote(query_type),
            unquote(name),
            nil,
            String.to_atom("#{unquote(name)}_filter"),
            String.to_atom("#{unquote(name)}_sorting"),
            unquote(base_module),
            unquote(options)
          )
        end
      end
    end
  end

  @doc """
  Generates Absinthe schema mutation CRUD (create, update, destory) fields based uppon options.

  ```
  mutation do

    CRUDimentary.Absinthe.EndpointGenerator.generic_mutation(
      :account,
      Project.API.Resolvers.Account,
      [
        exclude: [:update]
      ])

  end
  ```

  This results in generated fields:

  ```
  RootMutationType{
    createAccount(input: AccountInput!): AccountSingleResult

    destroyAccount(id: ID!): AccountSingleResult
  }
  ```

  """
  defmacro generic_mutation(name, base_module, options \\ %{}) do
    for mutation_type <- @mutation_types do
      if included?(mutation_type, options) do
        quote do
          unquote(__MODULE__).generic_schema_field(
            unquote(mutation_type),
            unquote(name),
            String.to_atom("#{unquote(name)}_input"),
            nil,
            nil,
            unquote(base_module),
            unquote(options)
          )
        end
      end
    end
  end

  @doc false
  defmacro generic_schema_field(
             action_type,
             name,
             input_type,
             filter_type,
             sort_type,
             base_module,
             options
           ) do
    error_handler = options[:error_handler] || @error_handler

    quote do
      @desc unquote(generate_description(name, action_type))
      field(
        unquote(action_name(name, action_type, options)),
        unquote(
          case action_type do
            :index ->
              result_name(name, :list)

            _ ->
              result_name(name, :single)
          end
        )
      ) do
        unquote(
          case action_type do
            :index ->
              quote do
                arg(:filter, list_of(unquote(filter_type)))
                arg(:sorting, unquote(sort_type))
                arg(:pagination, :pagination_input)
              end

            :create ->
              quote do
                arg(:input, non_null(unquote(input_type)))
              end

            :update ->
              quote do
                arg(:id, non_null(:id))
                arg(:input, non_null(unquote(input_type)))
              end

            _ ->
              quote do
                arg(:id, non_null(:id))
              end
          end
        )

        unquote(
          for mw <- extract_middleware(action_type, :before, options) do
            quote do
              middleware(unquote(mw))
            end
          end
        )

        resolve(
          &Module.concat(unquote(base_module), unquote(capitalize_atom(action_type))).call/3
        )

        unquote(
          if error_handler do
            quote do
              middleware(unquote(error_handler))
            end
          end
        )

        unquote(
          for mw <- extract_middleware(action_type, :after, options) do
            quote do
              middleware(unquote(mw))
            end
          end
        )
      end
    end
  end

  @doc false
  def generate_description(name, :index),
    do: "Fetches filtered and sorted list of #{name} resources"

  def generate_description(name, :show), do: "Fetches single #{name} resource by id"
  def generate_description(name, :create), do: "Creates new #{name} resource"
  def generate_description(name, :update), do: "Updates existing #{name} resource by id"
  def generate_description(name, :destroy), do: "Deletes #{name} resource by id"

  @doc false
  def included?(action, options) do
    !excluded?(action, options)
  end

  @doc false
  def excluded?(action, options) do
    exclusions = options[:except] || options[:exclude] || []
    included = options[:only] || []

    Enum.member?(exclusions, action) || (Enum.any?(included) && !Enum.member?(included, action))
  end

  @doc false
  def extract_middleware(action, position, options) do
    (options[action][:middleware][position] || []) ++ (options[:middleware][position] || [])
  end

  @doc false
  def filter_name(name) do
    String.to_atom("#{name}_filter")
  end

  @doc false
  def index_name(name) do
    "#{name}"
    |> Inflex.pluralize()
    |> String.to_atom()
  end

  @doc false
  def action_name(name, :show, options) do
    extract_action_name(:show, options) || name
  end

  def action_name(name, :index, options) do
    extract_action_name(:index, options) || index_name(name)
  end

  def action_name(name, action, options) do
    extract_action_name(action, options) || String.to_atom("#{action}_#{name}")
  end

  @doc false
  def extract_action_name(action, options) do
    options[:name][action]
  end

  @doc false
  def capitalize_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.capitalize()
    |> String.to_atom()
  end
end
