# Medplum Elixir

Elixir client for Medplum's FHIR API.

Built for apps that want:

- direct CRUD on FHIR resources
- first-class OAuth authorization-code helpers
- resource-specific helpers under `Medplum.Resources.*`
- workflow helpers under `Medplum.Workflows.*`
- token reuse across requests
- user-bearer-token authenticated requests
- stable `{:error, %Medplum.Error{}}` returns
- lower-level escape hatches for operations, batch, transaction, binary, upsert, GraphQL, FHIR requests, and non-FHIR Medplum requests

## Installation

Add package to `mix.exs`:

```elixir
def deps do
  [
    {:medplum_elixir, "~> 0.2.0"}
  ]
end
```

Then fetch deps:

```bash
mix deps.get
```

## Quick start

### Service app / backend

For backend and server-to-server use, Medplum uses OAuth client credentials. Set env vars first:

```bash
export MEDPLUM_BASE_URL="https://api.medplum.com"
export MEDPLUM_CLIENT_ID="..."
export MEDPLUM_CLIENT_SECRET="..."
```

Create reusable client:

```elixir
client =
  Medplum.new(
    base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
  )
```

Read resource:

```elixir
{:ok, patient} = Medplum.read(client, "Patient", "123")
```

Search resource:

```elixir
{:ok, bundle} = Medplum.search(client, "Patient", %{"family" => "Smith"})
```

Patch resource:

```elixir
ops = [%{"op" => "replace", "path" => "/active", "value" => true}]
{:ok, patient} = Medplum.patch(client, "Patient", "123", ops)
```

Stream paged search results:

```elixir
entries =
  client
  |> Medplum.stream_search("Patient", %{"family" => "Smith"})
  |> Enum.to_list()
```

### User session / OAuth callback

Build an authorization URL for the frontend login flow:

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

Exchange the callback code, then create a client that uses the returned user token directly:

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

user_client =
  Medplum.new_with_access_token(
    [base_url: System.fetch_env!("MEDPLUM_BASE_URL")],
    token_response["access_token"]
  )

{:ok, profile} = Medplum.userinfo(user_client)
{:ok, patient} = Medplum.read(user_client, "Patient", "123")
```

## Client options

`Medplum.new/1` accepts:

- `base_url` - Medplum server URL, trailing slash removed automatically
- `client_id` - OAuth client id, required for `:client_credentials`
- `client_secret` - OAuth client secret, required for `:client_credentials`
- `auth_mode` - `:client_credentials` or `:access_token`, defaults based on config
- `access_token` - existing bearer token for user-authenticated requests
- `fhir_version` - defaults to `"R4"`
- `default_headers` - merged into every request
- `req_options` - forwarded to `Req`
- `auth_req_options` - forwarded only to token requests
- `retry` - `false`, `:safe_transient`, or `:transient`
- `max_retries` - defaults to `2`
- `token_refresh_skew` - defaults to `60`
- `cache_tokens` - defaults to `true`

Example with request tuning:

```elixir
client =
  Medplum.new(
    base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
    client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
    client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET"),
    default_headers: [{"x-app-name", "my_app"}],
    req_options: [receive_timeout: 15_000],
    max_retries: 2,
    token_refresh_skew: 60
  )
```

Use `Medplum.new_with_access_token/2` to build an access-token client directly:

```elixir
user_client =
  Medplum.new_with_access_token(
    [base_url: System.fetch_env!("MEDPLUM_BASE_URL")],
    user_access_token
  )
```

## Core API

Main module covers generic FHIR and Medplum operations:

- `authorize_url/2`
- `exchange_authorization_code/3`
- `userinfo/2`
- `new_with_access_token/2`
- `read/3`
- `search/3`
- `create/3`
- `update/4`
- `delete/3`
- `patch/4`
- `request/4`
- `api_request/4`
- `operation/5`
- `poll_async/3`
- `batch/2`
- `transaction/2`
- `create_binary/3`
- `get_binary/2`
- `upsert/3`
- `graphql/3`
- `stream_search/3`

Example:

```elixir
{:ok, bundle} =
  Medplum.batch(client, [
    %{"request" => %{"method" => "GET", "url" => "Patient/123"}}
  ])

{:ok, graphql_result} =
  Medplum.graphql(client, "query Demo { PatientList { id } }")

{:ok, userinfo} =
  Medplum.userinfo(user_client)
```

## Resource helpers

Thin wrappers live under `Medplum.Resources.*`.

Common modules:

- `Patient`
- `Appointment`
- `Encounter`
- `Task`
- `Observation`
- `Condition`
- `DocumentReference`
- `ServiceRequest`
- `DiagnosticReport`
- `Claim`
- `Coverage`
- `Organization`
- `Practitioner`
- `PractitionerRole`
- `Schedule`
- `Slot`
- `Location`
- `Bot`
- `Subscription`

Example:

```elixir
alias Medplum.Resources.Patient
alias Medplum.Resources.Task

{:ok, patient} = Patient.get(client, "123")

{:ok, matches} =
  Patient.search_by_identifier(client, "http://hospital.example/mrn", "123")

{:ok, tasks} =
  Task.search_by_owner(client, "Practitioner/dr-1", %{"status" => "requested"})
```

Many resource modules also expose identifier-based upsert helpers:

```elixir
{:ok, patient} =
  Patient.upsert(client, %{
    "identifier" => [%{"system" => "http://hospital.example/mrn", "value" => "123"}],
    "name" => [%{"family" => "Smith"}]
  })
```

## Workflow helpers

Higher-level modules live under `Medplum.Workflows.*`.

Available workflows:

- `Scheduling`
- `Billing`
- `Automation`
- `Medications`
- `CareCoordination`
- `CarePlanning`
- `Tasks`
- `Intake`
- `Orders`
- `Charting`

Example:

```elixir
alias Medplum.Workflows.Automation
alias Medplum.Workflows.Billing
alias Medplum.Workflows.CarePlanning
alias Medplum.Workflows.CareCoordination
alias Medplum.Workflows.Charting
alias Medplum.Workflows.Intake
alias Medplum.Workflows.Medications
alias Medplum.Workflows.Orders
alias Medplum.Workflows.Scheduling
alias Medplum.Workflows.Tasks

{:ok, open_tasks} =
  Tasks.list_for_owner(client, "Practitioner/dr-1", %{"status" => "requested"})

{:ok, appointments} =
  Scheduling.find_appointments(client, %{
    "resourceType" => "Parameters",
    "parameter" => [%{"name" => "start", "valueDateTime" => "2026-07-04T09:00:00Z"}]
  })

{:ok, service_requests} =
  Orders.service_requests_for_subject(client, "Patient/123")

{:ok, claim_pdf} =
  Billing.export_claim(client, "claim-123")

{:ok, bot_result} =
  Automation.execute_bot(client, "bot-123", %{
    "resourceType" => "Patient",
    "id" => "123"
  })

{:ok, active_meds} =
  Medications.active_medication_requests_for_subject(client, "Patient/123")

{:ok, care_goals} =
  CarePlanning.active_goals_for_subject(client, "Patient/123")

{:ok, family_contacts} =
  CareCoordination.active_family_for_patient(client, "Patient/123")

{:ok, observations} =
  Charting.observations_for_patient(client, "Patient/123", %{"category" => "vital-signs"})

{:ok, responses} =
  Intake.questionnaire_responses_for_subject(client, "Patient/123")
```

## Error handling

All public functions return either success tuple or `%Medplum.Error{}`:

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

Error types:

- `:config_error`
- `:auth_failed`
- `:request_failed`
- `:api_error`
- `:invalid_response`

## Phoenix config

```elixir
# config/runtime.exs
config :my_app, :medplum,
  base_url: System.fetch_env!("MEDPLUM_BASE_URL"),
  client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
  client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
```

```elixir
service_client =
  :my_app
  |> Application.fetch_env!(:medplum)
  |> Medplum.new()
```

## Docs

- API docs generated with `mix docs`
- ExDoc extras:
  - `README.md`
  - `guides/getting-started.md`
  - `guides/resource-and-workflow-helpers.md`

## Development

Run tests:

```bash
mix test
```

Build docs:

```bash
mix docs
```
