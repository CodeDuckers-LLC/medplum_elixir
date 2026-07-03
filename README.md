# Medplum

A lightweight Elixir client for Medplum's FHIR API.

Features:

- CRUD helpers for common FHIR resource operations
- Token reuse across requests
- Stable `Medplum.Error` responses
- Low-level authenticated `request/4`
- JSON Patch support with `patch/4`
- Paged search streaming with `stream_search/3`

## Installation

Add `medplum_elixir` to your dependencies:

```elixir
def deps do
  [
    {:medplum_elixir, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
client =
  Medplum.new(
    base_url: "https://api.medplum.com",
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
  )

{:ok, patient} = Medplum.read(client, "Patient", "123")

{:ok, patients} =
  Medplum.search(client, "Patient", %{
    "family" => "Smith"
  })

ops = [%{"op" => "replace", "path" => "/active", "value" => true}]
{:ok, patient} = Medplum.patch(client, "Patient", "123", ops)

entries =
  client
  |> Medplum.stream_search("Patient", %{"family" => "Smith"})
  |> Enum.to_list()
```

## Request tuning

```elixir
client =
  Medplum.new(
    base_url: "https://api.medplum.com",
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET"),
    default_headers: [{"x-app-name", "my_app"}],
    req_options: [receive_timeout: 15_000],
    max_retries: 2,
    token_refresh_skew: 60
  )
```

## Error handling

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

## Phoenix configuration example

```elixir
# config/runtime.exs
config :my_app, :medplum,
  base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
  client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
  client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
```

```elixir
config = Application.fetch_env!(:my_app, :medplum)
client = Medplum.new(config)
```
