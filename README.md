# Medplum

A lightweight Elixir client for Medplum's FHIR API.

Features:

- CRUD helpers for common FHIR resource operations
- Generic FHIR operation, batch, transaction, binary, upsert, and GraphQL support
- Resource helper modules for common Medplum/FHIR records
- Workflow helper modules for scheduling, tasks, intake, orders, and charting
- Token reuse across requests
- Stable `Medplum.Error` responses
- Low-level authenticated `request/4`
- JSON Patch support with `patch/4`
- Paged search streaming with `stream_search/3` 

## Installation

Add `medplum_elixir` to your dependencies.

From Hex:

```elixir
def deps do
  [
    {:medplum_elixir, "~> 0.1.0"}
  ]
end
```

From GitHub:

```elixir
def deps do
  [
    {:medplum_elixir, git: "https://github.com/CodeDuckers-LLC/medplum_elixir.git"}
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

## Resource Helpers

Thin wrappers live under `Medplum.Resources.*`.

Available modules include:

- `Patient`
- `Appointment`
- `Encounter`
- `CareTeam`
- `CarePlan`
- `RelatedPerson`
- `Goal`
- `ClinicalImpression`
- `Practitioner`
- `Organization`
- `Coverage`
- `Claim`
- `ClaimResponse`
- `ChargeItem`
- `Account`
- `CoverageEligibilityRequest`
- `CoverageEligibilityResponse`
- `ChargeItemDefinition`
- `Invoice`
- `Bot`
- `Subscription`
- `AuditEvent`
- `Provenance`
- `Task`
- `Communication`
- `QuestionnaireResponse`
- `Observation`
- `Condition`
- `AllergyIntolerance`
- `Medication`
- `MedicationRequest`
- `MedicationStatement`
- `Immunization`
- `DocumentReference`
- `ServiceRequest`
- `DiagnosticReport`
- `Schedule`
- `Slot`
- `HealthcareService`
- `Location`
- `PractitionerRole`

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

Several identifier-driven resources also include resource-specific upsert conventions.
For example:

```elixir
{:ok, patient} =
  Patient.upsert(client, %{
    "identifier" => [%{"system" => "http://hospital.example/mrn", "value" => "123"}],
    "name" => [%{"family" => "Smith"}]
  })
```

Current identifier-based upsert helpers are available on:

- `Patient`
- `Appointment`
- `Encounter`
- `Practitioner`
- `PractitionerRole`
- `Organization`
- `Coverage`
- `HealthcareService`
- `Location`
- `Account`
- `Communication`
- `QuestionnaireResponse`
- `Observation`
- `Condition`
- `DocumentReference`
- `ServiceRequest`
- `DiagnosticReport`
- `Schedule`
- `Slot`
- `AllergyIntolerance`
- `Medication`
- `MedicationRequest`
- `MedicationStatement`
- `CareTeam`
- `CarePlan`
- `Goal`
- `Immunization`
- `RelatedPerson`
- `Claim`
- `ClaimResponse`
- `ChargeItem`
- `ChargeItemDefinition`
- `CoverageEligibilityRequest`
- `CoverageEligibilityResponse`
- `Invoice`
- `ClinicalImpression`
- `Task`

## Workflow Helpers

Higher-level workflow modules live under `Medplum.Workflows.*`.

Available modules:

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
alias Medplum.Workflows.Charting
alias Medplum.Workflows.Billing
alias Medplum.Workflows.CarePlanning
alias Medplum.Workflows.CareCoordination
alias Medplum.Workflows.Intake
alias Medplum.Workflows.Medications
alias Medplum.Workflows.Orders
alias Medplum.Workflows.Scheduling
alias Medplum.Workflows.Tasks
alias Medplum.Workflows.Automation

{:ok, open_tasks} =
  Tasks.list_for_owner(client, "Practitioner/dr-1", %{"status" => "requested"})

{:ok, _completed} = Tasks.complete_task(client, "task-123")

{:ok, appointments} =
  Scheduling.find_appointments(client, %{
    "resourceType" => "Parameters",
    "parameter" => [%{"name" => "start", "valueDateTime" => "2026-07-04T09:00:00Z"}]
  })

{:ok, responses} =
  Intake.questionnaire_responses_for_subject(client, "Patient/123")

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

{:ok, family_contacts} =
  CareCoordination.family_for_patient(client, "Patient/123")

{:ok, care_goals} =
  CarePlanning.active_goals_for_subject(client, "Patient/123")

{:ok, observations} =
  Charting.observations_for_patient(client, "Patient/123", %{"category" => "vital-signs"})
```

## Billing Helpers

Billing-side helpers cover charge capture, claims, eligibility, and export/submission flows.

Resource modules include:

- `Claim`
- `ClaimResponse`
- `ChargeItem`
- `Account`
- `CoverageEligibilityRequest`
- `CoverageEligibilityResponse`
- `ChargeItemDefinition`
- `Invoice`

Workflow module:

- `Medplum.Workflows.Billing`

Example:

```elixir
alias Medplum.Resources.Claim
alias Medplum.Workflows.Billing

{:ok, claims} =
  Claim.search_by_patient(client, "Patient/123")

{:ok, pdf_media} =
  Billing.export_claim(client, "claim-123")

{:ok, stedi_response} =
  Billing.submit_claim_to_stedi(client, "claim-123")
```

## Automation Helpers

Automation helpers cover bot execution, bot-triggering subscriptions, and event tracing.

Resource modules include:

- `Bot`
- `Subscription`
- `AuditEvent`
- `Provenance`

Workflow module:

- `Medplum.Workflows.Automation`

Example:

```elixir
alias Medplum.Workflows.Automation

{:ok, result} =
  Automation.execute_bot(client, "bot-123", %{
    "resourceType" => "Patient",
    "id" => "123"
  })

{:ok, subscription} =
  Automation.subscribe_bot_to_resource(client, "Patient", "bot-123")
```

## Medication And Allergy Helpers

Medication-side helpers cover allergies, medication definitions, prescribing, and patient medication history.

Resource modules include:

- `AllergyIntolerance`
- `Medication`
- `MedicationRequest`
- `MedicationStatement`

Workflow module:

- `Medplum.Workflows.Medications`

Example:

```elixir
alias Medplum.Workflows.Medications

{:ok, allergies} =
  Medications.active_allergies_for_patient(client, "Patient/123")

{:ok, med_requests} =
  Medications.active_medication_requests_for_subject(client, "Patient/123")

{:ok, med_history} =
  Medications.medication_history_for_subject(client, "Patient/123")
```

## Care Coordination And Family Helpers

Care coordination helpers cover care teams, family/caregiver records, and clinical assessment summaries.

Resource modules include:

- `CareTeam`
- `RelatedPerson`
- `ClinicalImpression`

Workflow module:

- `Medplum.Workflows.CareCoordination`

Example:

```elixir
alias Medplum.Workflows.CareCoordination

{:ok, teams} =
  CareCoordination.active_care_teams_for_subject(client, "Patient/123")

{:ok, family} =
  CareCoordination.active_family_for_patient(client, "Patient/123")

{:ok, impressions} =
  CareCoordination.clinical_impressions_for_patient(client, "Patient/123")
```

## Care Planning And Immunization Helpers

Care planning helpers cover longitudinal care plans, goals, and vaccine history.

Resource modules include:

- `CarePlan`
- `Goal`
- `Immunization`

Workflow module:

- `Medplum.Workflows.CarePlanning`

Example:

```elixir
alias Medplum.Workflows.CarePlanning

{:ok, plans} =
  CarePlanning.active_care_plans_for_subject(client, "Patient/123")

{:ok, goals} =
  CarePlanning.active_goals_for_subject(client, "Patient/123")

{:ok, immunizations} =
  CarePlanning.immunizations_for_patient(client, "Patient/123")
```

## Generic Medplum Features

Lower-level helpers still available on `Medplum`:

- `operation/5`
- `poll_async/3`
- `batch/2`
- `transaction/2`
- `create_binary/3`
- `get_binary/2`
- `upsert/3`
- `graphql/3`

Example:

```elixir
{:ok, bundle} =
  Medplum.batch(client, [
    %{"request" => %{"method" => "GET", "url" => "Patient/123"}}
  ])

{:ok, graphql_result} =
  Medplum.graphql(client, "query Demo { PatientList { id } }")
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
