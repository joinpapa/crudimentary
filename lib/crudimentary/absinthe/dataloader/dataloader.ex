defmodule Crudimentary.Absinthe.Dataloader do
  import Absinthe.Resolution.Helpers, only: [dataloader: 3]

  alias CRUDimentary.Absinthe.Resolvers.Services.{
    Authorization,
    Pagination,
    ResultFormatter
  }

  alias __MODULE__.Source.{Show, Index}

  def batch(type, assoc, account, parent, args, resolution) do
    with \
      {:type_valid, true} <- {:type_valid, type in [:show, :index]},
      {:policy_valid, true} <- {:policy_valid, (type == :index and args[:policy] != nil) or type == :show},
      {:args, args} <- {:args, build_args(args, account, assoc, type, parent, args[:policy])}
    do
      if type == :index do
        if Authorization.authorized?(args.policy, args.account, :index) do
          dataloader(IndexSource, assoc, callback: &callback/3).(parent, args, resolution)
        else
          ResultFormatter.result(nil)
        end
      else
        dataloader(ShowSource, assoc, callback: &callback/3).(parent, args, resolution)
      end
    else
      {:type_valid, false} ->
        raise ArgumentError, message: "batch type can be only :show or :index value"

      {:policy_valid, false} ->
        raise ArgumentError, message: "args parameter need to contain policy module for :index batch type"
    end
  end

  defp callback(result, parent, args) when is_list(result) do
    if args[:pagination] do
      Pagination.paginate(result, args.pagination)
    else
      result
    end
    |> ResultFormatter.result(args[:mapping])
  end

  defp callback(%_{} = result, _parent, args) do
    policy = args[:policy] || Authorization.policy_module(result.__struct__)

    result =
      if Authorization.authorized?(policy, result, args.account, :show) do
        result
      else
        nil
      end

    ResultFormatter.result(result)
  end

  defp callback(result, _parent, _args), do: ResultFormatter.result(result)

  defp build_args(args, account, assoc, type, parent, policy) do
    args
    |> Map.put(:account, account)
    |> Map.put(:assoc, assoc)
    |> Map.put(:type, type)
    |> Map.put(:policy, policy)
    |> Map.put(:pagination, Pagination.create_pagination_config(args[:sorting], args[:pagination], args[:options][:pagination]))
  end
end
