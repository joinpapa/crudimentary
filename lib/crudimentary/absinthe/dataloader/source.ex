defmodule CertifyEdWeb.API.Graphql.Dataloader.Source do
  import Ecto.Query

  @repo Confex.get_env(CRUDimentary.MixProject.project()[:app], :repo)

  def data(), do: Dataloader.Ecto.new(@repo, query: &query/2)

  defp query(queryable, _params) do
    from(q in queryable, select: %{data: q})
  end
end
