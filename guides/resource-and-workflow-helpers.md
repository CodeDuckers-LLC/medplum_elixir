# Resource And Workflow Helpers

This package exposes two layers:

- `Medplum.Resources.*` for resource-specific helpers
- `Medplum.Workflows.*` for multi-resource workflows

Use resource modules when you know exact FHIR record type. Use workflow modules when task maps to Medplum feature area.

## Resource helpers

Examples:

- `Medplum.Resources.Patient`
- `Medplum.Resources.Appointment`
- `Medplum.Resources.Encounter`
- `Medplum.Resources.Task`
- `Medplum.Resources.Observation`
- `Medplum.Resources.DocumentReference`
- `Medplum.Resources.Claim`
- `Medplum.Resources.Organization`
- `Medplum.Resources.Bot`

Typical shape:

```elixir
alias Medplum.Resources.Patient

{:ok, patient} = Patient.get(client, "patient-123")

{:ok, bundle} = Patient.search(client, %{"family" => "Smith"})

{:ok, matches} =
  Patient.search_by_identifier(client, "http://hospital.example/mrn", "123")

{:ok, everything} = Patient.everything(client, "patient-123")
```

Many resource modules also support identifier-based upsert:

```elixir
{:ok, patient} =
  Patient.upsert(client, %{
    "identifier" => [%{"system" => "http://hospital.example/mrn", "value" => "123"}],
    "name" => [%{"family" => "Smith", "given" => ["Ada"]}]
  })
```

## Workflow helpers

Examples:

- `Medplum.Workflows.Scheduling`
- `Medplum.Workflows.Billing`
- `Medplum.Workflows.Automation`
- `Medplum.Workflows.Medications`
- `Medplum.Workflows.CareCoordination`
- `Medplum.Workflows.CarePlanning`
- `Medplum.Workflows.Tasks`
- `Medplum.Workflows.Intake`
- `Medplum.Workflows.Orders`
- `Medplum.Workflows.Charting`

### Tasks

```elixir
alias Medplum.Workflows.Tasks

{:ok, open_tasks} =
  Tasks.list_for_owner(client, "Practitioner/dr-1", %{"status" => "requested"})

{:ok, completed_task} = Tasks.complete_task(client, "task-123")
```

### Scheduling

```elixir
alias Medplum.Workflows.Scheduling

{:ok, appointments} =
  Scheduling.find_appointments(client, %{
    "resourceType" => "Parameters",
    "parameter" => [%{"name" => "start", "valueDateTime" => "2026-07-04T09:00:00Z"}]
  })
```

### Billing

```elixir
alias Medplum.Workflows.Billing

{:ok, claims} =
  Billing.claims_for_patient(client, "Patient/123", %{"status" => "active"})

{:ok, export_result} =
  Billing.export_claim(client, "claim-123")

{:ok, stedi_result} =
  Billing.submit_claim_to_stedi(client, "claim-123")
```

### Automation

```elixir
alias Medplum.Workflows.Automation

{:ok, result} =
  Automation.execute_bot(client, "bot-123", %{
    "resourceType" => "Patient",
    "id" => "123"
  })
```

### Charting and orders

```elixir
alias Medplum.Workflows.Charting
alias Medplum.Workflows.Orders

{:ok, observations} =
  Charting.observations_for_patient(client, "Patient/123", %{"category" => "vital-signs"})

{:ok, service_requests} =
  Orders.service_requests_for_subject(client, "Patient/123")
```

## When to use base `Medplum` module

Stay on top-level `Medplum` API when:

- helper module does not exist yet
- you need generic FHIR CRUD
- you need custom `request/4`
- you need `batch/2`, `transaction/2`, `graphql/3`, or binary helpers
- you want direct `operation/5` access

## Doc navigation

For module-level details, open ExDoc pages for:

- `Medplum`
- `Medplum.Client`
- `Medplum.Error`
- specific `Medplum.Resources.*` module you use
- specific `Medplum.Workflows.*` module you use
