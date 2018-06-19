defmodule CRUDimentary.Absinthe.Resolvers.Generic do
  defmacro __using__(params) do
    quote do
      use CRUDimentary.Absinthe.Resolvers.Base

      @actions [:index, :show, :create, :update, :destroy]

      def call(current_account, parent, args, resolution) do
        action = unquote(params[:action])

        module =
          if action in @actions do
            submodule =
              action
              |> Atom.to_string()
              |> String.capitalize()

            Module.concat(unquote(__MODULE__), submodule)
          else
            raise("Unknown action")
          end

        module.call(
          unquote(params[:schema]),
          current_account,
          parent,
          args,
          resolution,
          unquote(params[:options])
        )
      end
    end
  end
end
