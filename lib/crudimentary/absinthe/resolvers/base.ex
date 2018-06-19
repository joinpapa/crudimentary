defmodule CRUDimentary.Absinthe.Resolvers.Base do
  defmacro __using__(_) do
    quote do
      @current_account_cache_key :current_account
      import CRUDimentary.Absinthe.Resolvers.Services.{
        Cache,
        Pagination,
        ResultFormatter,
        Querying,
        Authorization
      }

      def call(parent, args, resolution) do
        resolve_current_account(resolution)
        |> call(parent, args, resolution)
      end

      defp resolve_current_account(resolution) do
        cache_get(resolution, @current_account_cache_key) ||
          store_current_user_from_session(resolution)
      end

      defp store_current_user_from_session(resolution) do
        store_result =
          cache_set(
            resolution,
            @current_account_cache_key,
            get_in(resolution.context, [@current_account_cache_key])
          )

        if :ok == store_result do
          cache_get(resolution, @current_account_cache_key)
        else
          nil
        end
      end
    end
  end
end
