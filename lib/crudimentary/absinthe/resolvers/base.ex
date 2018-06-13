defmodule CRUDimentary.Absinthe.Respolvers.Base do
  defmacro __using__(_) do
    quote do
      @current_account_cache_key :current_account
      alias CRUDimentary.Cache.InMemory, as: Cache

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

      defp cache_get(resolution, key) do
        agent = get_agent(resolution)
        if agent do
          Cache.get(agent, key)
        else
          nil
        end
      end

      defp cache_set(resolution, key, value) do
        agent = get_agent(resolution)
        if agent do
          Cache.set(agent, key, value)
        else
          nil
        end
      end

      defp cache_delete(resolution, key) do
        agent = get_agent(resolution)
        if agent do
          Cache.delete(agent, key)
        else
          nil
        end
      end

      defp get_agent(resolution) do
        get_in(resolution.context, [:cache])
      end

      defp wrap_result(result) do
        case result do
          {:ok, result} -> {:ok, %{data: result}}
          {:error, _, error, _} -> {:error, error}
          error -> {:error, error}
        end
      end
    end
  end
end
