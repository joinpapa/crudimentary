defmodule CRUDimentary.Policy do
  @moduledoc """
  This module generates and defines set of overridable functions which regulate scope of access
  and action authorization based on the current account properties.
  """

  defmacro __using__(_) do
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

      def permitted_params(current_account), do: permitted_params(nil, current_account)
      def permitted_params(_record, _current_account), do: []

      def accessible_attributes(current_account), do: accessible_attributes(nil, current_account)
      def accessible_attributes(_record, _current_account), do: []

      defoverridable scope: 2,
                     index: 2,
                     show: 2,
                     create: 2,
                     update: 2,
                     destroy: 2,
                     permitted_params: 2,
                     accessible_attributes: 2
    end
  end
end
