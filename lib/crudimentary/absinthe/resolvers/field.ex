defmodule CRUDimentary.Absinthe.Resolvers.Field do
  defmacro __using__(params) do
    quote do
      use CRUDimentary.Absinthe.Resolvers.Base

      def call(nil, _, _, _, _), do: raise(ArgumentError, message: "field can not be nil")

      def call(
            current_account,
            parent,
            args,
            %{definition: %{schema_node: %{identifier: field}}} = resolution
          ) do
        with policy when not is_nil(policy) <-
               unquote(params[:policy]) || policy_module(parent.__struct__),
             true <- field in policy.accessible_attributes(parent, current_account),
             external_resolver <- get_external_resolver(field),
             {:external, true} <- {:external, Code.ensure_compiled?(external_resolver)} do
          external_resolver.call(current_account, parent, args, resolution)
        else
          {:external, false} ->
            try do
              call(field, current_account, parent, args, resolution)
            rescue
              FunctionClauseError ->
                unquote(__MODULE__).return_field(parent, field)
            end

          _ ->
            {:ok, nil}
        end
      end
    end
  end

  def field_resolver_module(atom) do
    submodule =
      atom
      |> Atom.to_string()
      |> Macro.camelize()

    Module.concat([__MODULE__, submodule])
  end

  def return_field(struct, field) do
    {:ok,
     case struct do
       %_{} -> Map.from_struct(struct)[field]
       _ -> struct[field]
     end}
  end
end
