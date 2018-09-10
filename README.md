# CRUDimentary
-------------------------

##### TODO: HEX DOCS
-------------------------

Absinthe helper for queryable CRUD resource endpoints (queries and mutations).

This package contains set of field generators for Absinthe including generic resolvers for sorting, filtering and pagination of output data which removes much of repeatative boilerplate code. Also includes policy and caching mechanism.

## Implementation

### Endpoint generation

Every generation starts in Absinthe schema, inside query or mutation macro. Inside of generator you define field name which will be used for normalized naming of field, input and result types. Second argument refers to resource resolver module. As a third argument you can pass set of options:
  * _exclude_ - excludes CRUD components from creating
  * _error_handler_ - middleware for error handling
  * _middleware_ - defines list of middlewares for CRUD field
    * _before_ - execution before error handling
    * _after_ - execution after error handling

```
query do

  CRUDimentary.Absinthe.EndpointGenerator.generic_query(
    :account,
    Project.API.Resolvers.Account,
    [
      error_handler: ErrorHandler,
      index: [
        middleware:
          [
            before: [Middleware, Middleware],
            after: [Middleware]
          ]
      ]
    ])

end
```

```
mutation do

  CRUDimentary.Absinthe.EndpointGenerator.generic_mutation(
    :account,
    Project.API.Resolvers.Account,
    [
      exclude: [:update]
    ])

end
```

Watching from REST prospective, every `generic_query`macro creates `SHOW`and `INDEX` actions (eg. `Account` and `Accounts`). While `generic_mutation` generates `CREATE`, `UPDATE`, and `DESTORY`actions (eg. `CreateAccount`, `UpdateAccount` and `DestroyAccount`).

```
RootQueryType{
  account(id: ID!): AccountSingleResult

  accounts(
    filter: [AccountFilter]
    pagination: PaginationInput
    sorting: AccountSorting): AccountListResult
}

RootMutationType{
  createAccount(input: AccountInput!): AccountSingleResult

  destroyAccount(id: ID!): AccountSingleResult
}
```


### CRUD resolver(s) definition

All of the generated fields will reference to the one of CRUD resolvers. All that you need to do is to define the module with right module name sufix (Show, Index, Create, Update, Destroy) within resource resolver module specified in generator. Then you `use CRUDimentary.Absinthe.Resolvers.Generic`with arguments:
  * action - which generic action to generate
  * schema - resource schema
  * options
    * policy - policy module for the resource
    * repo - used repo
    * changeset_function - function for update or create
    * filters - nested list of resolvers for custom filters
```
defmodule ProjectWeb.API.Resolvers.Account.Create do
  use CRUDimentary.Absinthe.Resolvers.Generic,
      action: :create,
      schema: Project.Account,
      options: [
        policy: ProjectWeb.API.Resolvers.Account.Policy,
        repo:   Project.Repo,
        changeset_function: :registration_changeset
      ]
end

defmodule ProjectWeb.API.Resolvers.Account.Index do
  alias ProjectWeb.API.Types.Account
  use CRUDimentary.Absinthe.Resolvers.Generic,
      action: :index,
      schema: ArkamixApi.Accounts.Account,
      options: [
        policy: ArkamixApiWeb.API.Resolvers.Account.Policy,
        repo:   ArkamixApi.Repo,
        filters: Account.filters()
      ]
end
```

### Authorization and Policy definition

Policy is defined set of functions which regulate scope of access and action execution authorization based on the current account properties. Function `scope` defines base scope for db querying while action functions define authorization handlers for specific resources.
```
defmodule ProjectWeb.API.Resolvers.Account.Policy do
  use CRUDimentary.Policy

  def scope(queryable, _current_account) do
    if Code.ensure_compiled?(Ecto.Query) do
      import Ecto.Query
      from(r in queryable)
    else
      queryable
    end
  end

  def index(current_account), do: index(nil, current_account)
  def index(record, current_account), do: show(record, current_account)

  def show(current_account), do: show(nil, current_account)
  def show(_record, _current_account), do: true

  def create(current_account), do: create(nil, current_account)
  def create(_record, _current_account), do: true

  def update(current_account), do: update(nil, current_account)
  def update(_record, _current_account), do: true

  def destroy(current_account), do: destroy(nil, current_account)
  def destroy(_record, _current_account), do: true
end
```

### Resolver services

If you're defining custom (regular) mutation out of CRUD scope you can use and combine any of stock resolver services. Or you can `use CRUDimentary.Absinthe.Resolvers.Base` which automatically resolves and stores current user into caches and imports all of the services (in that case you define &call/4 function).

List of possible services:
  * Authorization
  * Cache
  * Pagination
  * Querying
  * Result formatter

```
defmodule ProjectWeb.API.Resolvers.Account.CustomMutation do
  use CRUDimentary.Absinthe.Resolvers.Base

   def call(current_account, parent, args, resolution) do
    {:ok, true}
  end
end
```
#### Using cached values in requests

In some cases we need to preserve state during complex request. For example while registering user for the first time we need to do additional resource creations which depends upon current user, because user is not authenticated thorough any kind of authentication system we need to storing somewhere. We can easily store those kind of values thanks to Erlangs OTP and in this context is implemented through `CRUDimentary.Absinthe.Resolvers.Services.Cache` module. All caches are destroyed before sending a response to the client.
