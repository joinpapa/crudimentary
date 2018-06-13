defmodule CRUDimentary.Absinthe.Plugs.RequestCache do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    cache =
      case CRUDimentary.Absinthe.Cache.InMemory.start_link() do
        {:ok, pid} -> pid
        _ -> nil
      end

    conn = put_private(
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
