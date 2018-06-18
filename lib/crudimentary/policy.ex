defmodule CRUDimentary.Policy do
  defmacro __using__ do
    quote do
      def scope(queriable, _current_account) do
        if Code.ensure_compiled?(Ecto.Query) do
          import Ecto.Query
          from(r in queriable, where: 1 == 0)
        else
          queriable
        end
      end

      def authorized?(action, current_account) do
        authorized?(action, nil, current_account)
      end

      def authorized?(action, record, current_account) do
        apply(__MODULE__, action, [record, current_account])
      end

      def index(current_account), do: index(nil, current_account)
      def index(record, current_account), do: show(record, current_account)

      def show(current_account), do: show(nil, current_account)
      def show(_record, _current_account), do: false

      def create(current_account), do: create(nil, current_account)
      def create(_record, _current_account), do: false

      def update(current_account), do: update(nil, current_account)
      def update(_record, _current_account), do: false

      def destroy(current_account), do: destroy(nil, current_account)
      def destroy(_record, _current_account), do: false

      def permitted_attributes(current_account) do
        permitted_attributes(nil, current_account)
      end

      def permitted_attributes(_record, _current_account) do
        []
      end

      defoverridable scope: 2,
                     index: 2,
                     show: 2,
                     create: 2,
                     update: 2,
                     destroy: 2,
                     permitted_attributes: 2
    end
  end
end
