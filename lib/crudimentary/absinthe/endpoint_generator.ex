defmodule CRUDimentary.Absinthe.EndpointGenerator do
  #############
  ## QUERIES ##
  #############

  defmacro generic_query(name, base_module, options \\ %{}) do
    quote do
      unquote(__MODULE__).query(
        unquote(name),
        String.to_atom("#{unquote(name)}_filter"),
        String.to_atom("#{unquote(name)}_sorting"),
        unquote(base_module),
        unquote(options)
      )
    end
  end

  defmacro query(name, filter_type, sort_type, base_module, options \\ %{}) do
    quote do
      if unquote(__MODULE__).included?(:index, options) do
        unquote(__MODULE__).index(
          name,
          filter_type,
          sort_type,
          base_module,
          options
        )
      end

      if unquote(__MODULE__).included?(:show, options) do
        unquote(__MODULE__).show(
          name,
          filter_type,
          sort_type,
          base_module,
          options
        )
      end
    end
  end

  defmacro index(name, filter_type, sort_type, base_module, options \\ %{}) do
    field(
      unquote(__MODULE__.action_name(name, :index, options)),
      unquote(__MODULE__.result_name(name, :list))
    ) do
      arg(:filter, list_of(unquote(filter_type)))
      arg(:sorting, unquote(sort_type))
      arg(:pagination, :pagination_input)

      unquote(
        for mw <- __MODULE__.extract_middleware(:index, :before, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )

      resolve(&Module.concat(unquote(base_module), Index).call/3)
      middleware(PapaPal.Web.API.Middleware.HandleErrors)

      unquote(
        for mw <- __MODULE__.extract_middleware(:index, :after, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )
    end
  end

  defmacro show(name, filter_type, sort_type, base_module, options \\ %{}) do
    field(
      unquote(__MODULE__.action_name(name, :show, options)),
      unquote(__MODULE__.result_name(name, :single))
    ) do
      arg(:id, non_null(:id))

      unquote(
        for mw <- __MODULE__.extract_middleware(:show, :before, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )

      resolve(&Module.concat(unquote(base_module), Show).call/3)
      middleware(PapaPal.Web.API.Middleware.HandleErrors)

      unquote(
        for mw <- __MODULE__.extract_middleware(:show, :after, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )
    end
  end

  ###############
  ## MUTATIONS ##
  ###############

  defmacro generic_mutation(name, base_module, options \\ %{}) do
    quote do
      unquote(__MODULE__).mutation(
        unquote(name),
        String.to_atom("#{unquote(name)}_input"),
        unquote(base_module),
        unquote(options)
      )
    end
  end

  defmacro mutation(name, input_type, base_module, options \\ %{}) do
    quote do
      if unquote(__MODULE__).included?(:create, options) do
        unquote(__MODULE__).create(name, input_type, base_module, options)
      end

      if unquote(__MODULE__).included?(:update, options) do
        unquote(__MODULE__).update(name, input_type, base_module, options)
      end

      if unquote(__MODULE__).included?(:destroy, options) do
        unquote(__MODULE__).destroy(name, input_type, base_module, options)
      end
    end
  end

  defmacro create(name, input_type, base_module, options \\ %{}) do
    field(
      unquote(__MODULE__.action_name(name, :create, options)),
      unquote(__MODULE__.result_name(name, :single))
    ) do
      arg(:input, non_null(unquote(input_type)))

      unquote(
        for mw <- __MODULE__.extract_middleware(:create, :before, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )

      resolve(&Module.concat(unquote(base_module), Create).call/3)
      middleware(PapaPal.Web.API.Middleware.HandleErrors)

      unquote(
        for mw <- __MODULE__.extract_middleware(:create, :after, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )
    end
  end

  defmacro update(name, input_type, base_module, options \\ %{}) do
    field(
      unquote(__MODULE__.action_name(name, :update, options)),
      unquote(__MODULE__.result_name(name, :single))
    ) do
      arg(:id, non_null(:id))
      arg(:input, non_null(unquote(input_type)))

      unquote(
        for mw <- __MODULE__.extract_middleware(:update, :before, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )

      resolve(&Module.concat(unquote(base_module), Update).call/3)
      middleware(PapaPal.Web.API.Middleware.HandleErrors)

      unquote(
        for mw <- __MODULE__.extract_middleware(:update, :after, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )
    end
  end

  defmacro destroy(name, input_type, base_module, options \\ %{}) do
    field(
      unquote(__MODULE__.action_name(name, :destroy, options)),
      unquote(__MODULE__.result_name(name, :single))
    ) do
      arg(:id, non_null(:id))

      unquote(
        for mw <- __MODULE__.extract_middleware(:destroy, :before, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )

      resolve(&Module.concat(unquote(base_module), Destroy).call/3)
      middleware(PapaPal.Web.API.Middleware.HandleErrors)

      unquote(
        for mw <- __MODULE__.extract_middleware(:destroy, :after, options) do
          quote do
            middleware(unquote(mw))
          end
        end
      )
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
    (options[action][:middleware][position] || []) ++
      (options[:middleware][position] || [])
  end

  def result_name(name, count) do
    "#{name}_#{count}_result"
    |> String.to_atom()
  end

  def filter_name(name) do
    "#{name}_filter"
    |> String.to_atom()
  end

  def index_name(name) do
    # Hack to convert anything to a string
    Inflex.pluralize("#{name}")
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
end
