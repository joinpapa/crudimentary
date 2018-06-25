defmodule CRUDimentary.Absinthe.Plugs.RequestCache do
  @moduledoc """
  Plug for issuing cache during response creation.
  This plug creates temporary cache storage uppon incoming request, cache (GenServer) pid is stored in Absinthe Resolution Context.
  Also it creates hook which destorys created and populated cache before sending a response.
  """
  @behaviour Plug

  import Plug.Conn

  @spec init(opts :: keyword) :: keyword
  def init(opts), do: opts

  @doc """
  Creates Cache Agent and stores PID in Absinthe Resolution Context.
  Before sending the response, Agent dies.
  """
  @spec call(conn :: Conn.t(), params :: keyword) :: Conn.t()
  def call(conn, _) do
    cache =
      case CRUDimentary.Cache.InMemory.start_link() do
        {:ok, pid} -> pid
        _ -> nil
      end

    conn =
      put_private(
        conn,
        :absinthe,
        %{
          context: %{
            cache: cache
          }
        }
      )

    Plug.Conn.register_before_send(
      conn,
      fn conn ->
        if cache = conn.private[:absinthe][:context][:cache] do
          Agent.stop(cache)
        end

        conn
      end
    )
  end
end
