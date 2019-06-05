defmodule CRUDimentary.Absinthe.Dataloader.Sources.Index do
  import Ecto.Query

  alias CRUDimentary.Absinthe.Resolvers.Services.Querying

  @repo Confex.get_env(CRUDimentary.MixProject.project()[:app], :repo)
  
  def data(), do: Dataloader.Ecto.new(@repo, query: &query/2)

  def query(queryable, args) do
    queryable
    |> Querying.scope(args[:account], args[:parent], args.policy)
    |> Querying.filter(args[:filter], args[:mapping], args[:options][:filters])
    |> Querying.sort(args[:sorting])
  end
end
  