defmodule CRUDimentary.Absinthe.Generator.Endpoint do
  import CRUDimentary.Absinthe.Generator.ResultType

  @query_types    [:index, :show]
  @mutation_types [:create, :update, :destroy]

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

  defmacro generic_schema_field(
    action_type,
    name,
    input_type,
    filter_type,
    sort_type,
    base_module,
    options) do
    quote do
      field(
      unquote(action_name(name, action_type, options)),
      unquote(
        if action_type == :index do
          result_name(name, :list)
        else
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

      resolve(&Module.concat(unquote(base_module), unquote(capitalize_atom(action_type))).call/3)

      unquote(
        if options[:error_handler] do
          quote do
            middleware(unquote(options[:error_handler]))
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

  def included?(action, options) do
    !excluded?(action, options)
  end

  def excluded?(action, options) do
    exclusions = options[:exclude] || []
    Enum.any?(exclusions, &(&1 == action))
  end

  def extract_middleware(action, position, options) do
    (options[action][:middleware][position] || []) ++ (options[:middleware][position] || [])
  end

  def filter_name(name) do
    String.to_atom("#{name}_filter")
  end

  def index_name(name) do
    "#{name}"
    |> Inflex.pluralize()
    |> String.to_atom()
  end

  def action_name(name, :show, options) do
    extract_action_name(:show, options) || name
  end
  def action_name(name, :index, options) do
    extract_action_name(:index, options) || index_name(name)
  end
  def action_name(name, action, options) do
    extract_action_name(action, options) || String.to_atom("#{action}_#{name}")
  end

  def extract_action_name(action, options) do
    options[:name][action]
  end

  def capitalize_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.capitalize()
    |> String.to_atom()
  end
end
