defmodule CRUDimentary.Absinthe.EndpointGenerator do
  #########################
  ## QUERIES / MUTATIONS ##
  #########################

  @query_types [:index, :show]
  @mutation_types [:create, :update, :destroy]

  defmacro generic_query(name, base_module, options \\ %{}) do
    for query_type <- @query_types do
      if included?(query_type, options) do
        quote do
          unquote(__MODULE__).generic_field(
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
          unquote(__MODULE__).generic_field(
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

  defmacro generic_field(
             request_type,
             name,
             input_type,
             filter_type,
             sort_type,
             base_module,
             options
           ) do
    quote do
      field(
        unquote(action_name(name, request_type, options)),
        unquote(
          if request_type == :index do
            result_name(name, :list)
          else
            result_name(name, :single)
          end
        )
      ) do
        unquote(
          case request_type do
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
          for mw <- extract_middleware(request_type, :before, options) do
            quote do
              middleware(unquote(mw))
            end
          end
        )

        resolve(
          &Module.concat(unquote(base_module), unquote(capitalize_atom(request_type))).call/3
        )

        middleware(CRUDimentary.Absinthe.Middleware.HandleErrors)

        unquote(
          for mw <- extract_middleware(request_type, :after, options) do
            quote do
              middleware(unquote(mw))
            end
          end
        )
      end
    end
  end

  ###########
  ## TYPES ##
  ###########

  defmacro generic_result_types(name) do
    quote do
      unquote(__MODULE__).result_types(unquote(name), unquote(name))
    end
  end

  defmacro result_types(name, type) do
    quote do
      object(unquote(__MODULE__.result_name(name, :list))) do
        field(:data, list_of(unquote(type)))
        field(:pagination, :pagination)
      end

      object(unquote(__MODULE__.result_name(name, :single))) do
        field(:data, unquote(type))
        field(:pagination, :pagination)
      end
    end
  end

  defmacro filter_enum_input(enum) do
    quote do
      input_object unquote(String.to_atom("filter_#{enum}_input")) do
        field(:eq, unquote(enum))
        field(:ne, unquote(enum))
        field(:in, list_of(unquote(enum)))
        field(:not_in, list_of(unquote(enum)))
      end
    end
  end

  #############
  ## HELPERS ##
  #############

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

  def result_name(name, count) do
    String.to_atom("#{name}_#{count}_result")
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
