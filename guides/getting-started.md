# Getting Started

This guide covers first client setup, OAuth flows, and common request patterns.

## Installation

Add package to `mix.exs`:

```elixir
def deps do
  [
    {:medplum_elixir, "~> 0.2.0"}
  ]
end
```

Fetch deps:

```bash
mix deps.get
```

## Credentials

Typical Medplum env vars:

```bash
export MEDPLUM_BASE_URL="https://api.medplum.com"
export MEDPLUM_CLIENT_ID="..."
export MEDPLUM_CLIENT_SECRET="..."
```

## Build service client

```elixir
client =
  Medplum.new(
    base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
  )
```

Client struct is reusable across requests. Token caching is enabled by default.

## Build authorize URL

Use `authorize_url/2` when a browser session should log in through Medplum with the authorization-code flow:

```elixir
authorize_url =
  Medplum.authorize_url(
    [
      base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
      client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
      client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
    ],
    redirect_uri: "https://myapp.example/auth/medplum/callback",
    scope: "openid profile offline_access",
    state: "csrf-token"
  )
```

## Exchange callback code

In your callback handler, exchange the Medplum authorization code for a token response:

```elixir
oauth_client =
  Medplum.new(
    base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
  )

{:ok, token_response} =
  Medplum.exchange_authorization_code(oauth_client, params["code"],
    redirect_uri: "https://myapp.example/auth/medplum/callback"
  )
```

## Build user-token client

Use the returned access token directly for user-authenticated requests:

```elixir
user_client =
  Medplum.new_with_access_token(
    [base_url: System.fetch_env!("MEDPLUM_BASE_URL")],
    token_response["access_token"]
  )

{:ok, userinfo} = Medplum.userinfo(user_client)
{:ok, patient} = Medplum.read(user_client, "Patient", "123")
```

## CRUD example

```elixir
{:ok, created} =
  Medplum.create(client, "Patient", %{
    "name" => [%{"family" => "Smith", "given" => ["Ada"]}]
  })

{:ok, fetched} = Medplum.read(client, "Patient", created["id"])

{:ok, updated} =
  Medplum.update(client, "Patient", created["id"], %{
    "active" => true
  })

:ok =
  case Medplum.delete(client, "Patient", created["id"]) do
    {:ok, _resource} -> :ok
    {:error, error} -> raise error
  end
```

## Search example

```elixir
{:ok, bundle} =
  Medplum.search(client, "Patient", %{
    "family" => "Smith",
    "_count" => "10"
  })
```

Use `stream_search/3` when result set may span many pages:

```elixir
entries =
  client
  |> Medplum.stream_search("Observation", %{"subject" => "Patient/123"})
  |> Enum.to_list()
```

## JSON Patch example

```elixir
ops = [
  %{"op" => "replace", "path" => "/active", "value" => true}
]

{:ok, patient} = Medplum.patch(client, "Patient", "123", ops)
```

## Lower-level requests

Use `request/4` for unsupported FHIR endpoints or custom headers:

```elixir
{:ok, result} =
  Medplum.request(client, :get, "/Patient/123/$everything", params: %{"_count" => "20"})
```

Use `api_request/4` for non-FHIR Medplum paths relative to `base_url`:

```elixir
{:ok, profile} =
  Medplum.api_request(user_client, :get, "/oauth2/userinfo")
```

Use `operation/5` for FHIR operations:

```elixir
{:ok, export_result} =
  Medplum.operation(client, {"Claim", "claim-123"}, "export", %{}, method: :get)
```

## GraphQL and batch

```elixir
{:ok, graphql_result} =
  Medplum.graphql(client, "query Demo { PatientList { id } }")

{:ok, batch_result} =
  Medplum.batch(client, [
    %{"request" => %{"method" => "GET", "url" => "Patient/123"}},
    %{"request" => %{"method" => "GET", "url" => "Observation?subject=Patient/123"}}
  ])
```

## Error handling

Public functions return `{:error, %Medplum.Error{}}` on failure:

```elixir
case Medplum.read(client, "Patient", "missing-id") do
  {:ok, patient} ->
    patient

  {:error, %Medplum.Error{type: :api_error, status: 404}} ->
    nil

  {:error, %Medplum.Error{} = error} ->
    raise error
end
```

## Phoenix config

```elixir
# config/runtime.exs
config :my_app, :medplum,
  base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
  client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
  client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
```

```elixir
client =
  :my_app
  |> Application.fetch_env!(:medplum)
  |> Medplum.new()
```
