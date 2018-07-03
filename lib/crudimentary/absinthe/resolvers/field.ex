defmodule CRUDimentary.Absinthe.Resolvers.Field do
  defmacro __using__(params) do
    quote do
      use CRUDimentary.Absinthe.Resolvers.Base

      def call(
            current_account,
            parent,
            args,
            %{definition: %{schema_node: %{identifier: field}}} = resolution
          ) do
        if field in unquote(params[:policy]).accessible_attributes(parent, current_account) do
          try do
            call(field, current_account, parent, args, resolution)
          rescue
            FunctionClauseError -> {:ok, Map.get(parent, field)}
          end
        else
          {:ok, nil}
        end
      end
    end
  end
end
