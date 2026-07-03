defmodule Medplum.ResourceHelpersTest do
  use ExUnit.Case, async: true

  alias Medplum.Resources.Appointment
  alias Medplum.Resources.Account
  alias Medplum.Resources.AuditEvent
  alias Medplum.Resources.Bot
  alias Medplum.Resources.ChargeItem
  alias Medplum.Resources.ChargeItemDefinition
  alias Medplum.Resources.Claim
  alias Medplum.Resources.ClaimResponse
  alias Medplum.Resources.ClinicalImpression
  alias Medplum.Resources.Communication
  alias Medplum.Resources.Condition
  alias Medplum.Resources.Coverage
  alias Medplum.Resources.CoverageEligibilityRequest
  alias Medplum.Resources.CoverageEligibilityResponse
  alias Medplum.Resources.DiagnosticReport
  alias Medplum.Resources.DocumentReference
  alias Medplum.Resources.Encounter
  alias Medplum.Resources.Goal
  alias Medplum.Resources.HealthcareService
  alias Medplum.Resources.Immunization
  alias Medplum.Resources.Invoice
  alias Medplum.Resources.Location
  alias Medplum.Resources.Medication
  alias Medplum.Resources.MedicationRequest
  alias Medplum.Resources.MedicationStatement
  alias Medplum.Resources.Observation
  alias Medplum.Resources.Organization
  alias Medplum.Resources.Patient
  alias Medplum.Resources.Practitioner
  alias Medplum.Resources.PractitionerRole
  alias Medplum.Resources.Provenance
  alias Medplum.Resources.QuestionnaireResponse
  alias Medplum.Resources.CarePlan
  alias Medplum.Resources.CareTeam
  alias Medplum.Resources.RelatedPerson
  alias Medplum.Resources.Schedule
  alias Medplum.Resources.ServiceRequest
  alias Medplum.Resources.Slot
  alias Medplum.Resources.Subscription
  alias Medplum.Resources.Task
  alias Medplum.Resources.AllergyIntolerance
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

  test "patient helper wraps CRUD and search operations" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:patient_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient/p1" ->
            case request.method do
              :get ->
                Req.Response.new(status: 200, body: %{"resourceType" => "Patient", "id" => "p1"})

              :put ->
                Req.Response.new(status: 200, body: %{"resourceType" => "Patient", "id" => "p1"})

              :delete ->
                Req.Response.new(status: 204, body: "")
            end

          "/fhir/R4/Patient" ->
            case request.method do
              :post ->
                Req.Response.new(
                  status: 200,
                  body: %{"resourceType" => "Patient", "id" => "created"}
                )

              :get ->
                Req.Response.new(
                  status: 200,
                  body: %{"resourceType" => "Bundle", "type" => "searchset"}
                )
            end
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"id" => "p1"}} = Patient.get(client, "p1")
    assert_received {:patient_request, %Req.Request{} = get_request}
    assert get_request.method == :get
    assert get_request.url.path == "/fhir/R4/Patient/p1"

    assert {:ok, %{"id" => "created"}} = Patient.create(client, %{"active" => true})
    assert_received {:patient_request, %Req.Request{} = create_request}
    assert create_request.method == :post
    assert create_request.url.path == "/fhir/R4/Patient"

    assert {:ok, %{"id" => "p1"}} = Patient.update(client, "p1", %{"active" => false})
    assert_received {:patient_request, %Req.Request{} = update_request}
    assert update_request.method == :put
    assert update_request.url.path == "/fhir/R4/Patient/p1"

    assert {:ok, %{}} = Patient.delete(client, "p1")
    assert_received {:patient_request, %Req.Request{} = delete_request}
    assert delete_request.method == :delete
    assert delete_request.url.path == "/fhir/R4/Patient/p1"

    assert {:ok, %{"type" => "searchset"}} = Patient.search(client, %{"family" => "Smith"})
    assert_received {:patient_request, %Req.Request{} = search_request}
    assert search_request.method == :get
    assert search_request.url.path == "/fhir/R4/Patient"
    assert search_request.url.query == "family=Smith"
  end

  test "patient helper provides identifier, name, and everything convenience functions" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:patient_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Patient/p1/$everything" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             Patient.search_by_identifier(client, "http://hospital.example/mrn", "123")

    assert_received {:patient_request, %Req.Request{} = identifier_request}
    assert identifier_request.url.query == "identifier=http%3A%2F%2Fhospital.example%2Fmrn%7C123"

    assert {:ok, %{"type" => "searchset"}} =
             Patient.search_by_name(client, "Smith", "Jane", %{"birthdate" => "1990-01-01"})

    assert_received {:patient_request, %Req.Request{} = name_request}

    assert URI.decode_query(name_request.url.query) == %{
             "birthdate" => "1990-01-01",
             "family" => "Smith",
             "given" => "Jane"
           }

    assert {:ok, %{"type" => "searchset"}} = Patient.everything(client, "p1")
    assert_received {:patient_request, %Req.Request{} = everything_request}
    assert everything_request.method == :get
    assert everything_request.url.path == "/fhir/R4/Patient/p1/$everything"
  end

  test "resource specific upsert conventions build conditional put from identifiers" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:upsert_convention_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Patient", "id" => "patient-1"}
            )

          "/fhir/R4/Organization" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Organization", "id" => "org-1"}
            )

          "/fhir/R4/MedicationRequest" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "MedicationRequest", "id" => "mr-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    patient_attrs = %{
      "identifier" => [%{"system" => "http://hospital.example/mrn", "value" => "123"}],
      "name" => [%{"family" => "Smith"}]
    }

    assert {:ok, %{"id" => "patient-1"}} = Patient.upsert(client, patient_attrs)
    assert_received {:upsert_convention_request, %Req.Request{} = patient_upsert}
    assert patient_upsert.method == :put
    assert patient_upsert.url.path == "/fhir/R4/Patient"
    assert patient_upsert.url.query == "identifier=http%3A%2F%2Fhospital.example%2Fmrn%7C123"
    refute String.contains?(IO.iodata_to_binary(patient_upsert.body), "\"_search\"")

    organization_attrs = %{
      "identifier" => [%{"system" => "http://example.org/org", "value" => "acme"}],
      "name" => "Acme Clinic"
    }

    assert {:ok, %{"id" => "org-1"}} =
             Organization.upsert_by_identifier(
               client,
               "http://example.org/org",
               "acme",
               organization_attrs
             )

    assert_received {:upsert_convention_request, %Req.Request{} = organization_upsert}
    assert organization_upsert.method == :put
    assert organization_upsert.url.path == "/fhir/R4/Organization"
    assert organization_upsert.url.query == "identifier=http%3A%2F%2Fexample.org%2Forg%7Cacme"

    medication_request_attrs = %{
      "identifier" => [%{"system" => "http://example.org/prescriptions", "value" => "rx-1"}],
      "status" => "active",
      "intent" => "order",
      "subject" => %{"reference" => "Patient/p1"}
    }

    assert {:ok, %{"id" => "mr-1"}} =
             MedicationRequest.upsert_by_identifier(
               client,
               "http://example.org/prescriptions",
               "rx-1",
               medication_request_attrs
             )

    assert_received {:upsert_convention_request, %Req.Request{} = medication_request_upsert}
    assert medication_request_upsert.method == :put
    assert medication_request_upsert.url.path == "/fhir/R4/MedicationRequest"

    assert medication_request_upsert.url.query ==
             "identifier=http%3A%2F%2Fexample.org%2Fprescriptions%7Crx-1"
  end

  test "appointment, encounter, practitioner, organization, and coverage helpers target the correct resources" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:resource_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Appointment/a1" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Appointment", "id" => "a1"})

          "/fhir/R4/Appointment" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Encounter" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Practitioner" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Practitioner", "id" => "dr-1"}
            )

          "/fhir/R4/Organization" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Coverage" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"id" => "a1"}} = Appointment.get(client, "a1")
    assert_received {:resource_request, %Req.Request{} = appointment_get}
    assert appointment_get.url.path == "/fhir/R4/Appointment/a1"

    assert {:ok, %{"type" => "searchset"}} = Appointment.search_by_patient(client, "Patient/p1")
    assert_received {:resource_request, %Req.Request{} = appointment_by_patient}
    assert appointment_by_patient.url.path == "/fhir/R4/Appointment"
    assert appointment_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = Appointment.search_by_date(client, "ge2026-07-01")
    assert_received {:resource_request, %Req.Request{} = appointment_by_date}
    assert appointment_by_date.url.query == "date=ge2026-07-01"

    assert {:ok, %{"type" => "searchset"}} = Encounter.search_by_patient(client, "Patient/p1")
    assert_received {:resource_request, %Req.Request{} = encounter_by_patient}
    assert encounter_by_patient.url.path == "/fhir/R4/Encounter"
    assert encounter_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Encounter.search_by_appointment(client, "Appointment/a1")

    assert_received {:resource_request, %Req.Request{} = encounter_by_appointment}
    assert encounter_by_appointment.url.query == "appointment=Appointment%2Fa1"

    assert {:ok, %{"id" => "dr-1"}} = Practitioner.create(client, %{"active" => true})
    assert_received {:resource_request, %Req.Request{} = practitioner_create}
    assert practitioner_create.method == :post
    assert practitioner_create.url.path == "/fhir/R4/Practitioner"

    assert {:ok, %{"type" => "searchset"}} =
             Organization.search(client, %{"name" => "Acme Clinic"})

    assert_received {:resource_request, %Req.Request{} = organization_search}
    assert organization_search.url.path == "/fhir/R4/Organization"
    assert organization_search.url.query == "name=Acme+Clinic"

    assert {:ok, %{"type" => "searchset"}} =
             Coverage.search_by_beneficiary(client, "Patient/p1")

    assert_received {:resource_request, %Req.Request{} = coverage_by_beneficiary}
    assert coverage_by_beneficiary.url.path == "/fhir/R4/Coverage"
    assert coverage_by_beneficiary.url.query == "beneficiary=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Coverage.search_by_identifier(client, "http://payer.example/policy", "ABC-123")

    assert_received {:resource_request, %Req.Request{} = coverage_by_identifier}

    assert coverage_by_identifier.url.query ==
             "identifier=http%3A%2F%2Fpayer.example%2Fpolicy%7CABC-123"
  end

  test "scheduling workflow helpers use the documented appointment operation endpoints" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:scheduling_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Appointment/$find" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Appointment/$hold" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "transaction-response"}
            )

          "/fhir/R4/Appointment/$book" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "transaction-response"}
            )

          "/fhir/R4/Appointment/appt-1/$confirm" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "transaction-response"}
            )

          "/fhir/R4/Appointment/appt-1/$cancel" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Appointment", "status" => "cancelled"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    params = %{
      "resourceType" => "Parameters",
      "parameter" => [%{"name" => "start", "valueDateTime" => "2026-07-04T09:00:00Z"}]
    }

    assert {:ok, %{"type" => "searchset"}} = Scheduling.find_appointments(client, params)
    assert_received {:scheduling_request, %Req.Request{} = find_request}
    assert find_request.method == :post
    assert find_request.url.path == "/fhir/R4/Appointment/$find"
    assert IO.iodata_to_binary(find_request.body) == Jason.encode!(params)

    assert {:ok, %{"type" => "transaction-response"}} =
             Scheduling.hold_appointment(client, params)

    assert_received {:scheduling_request, %Req.Request{} = hold_request}
    assert hold_request.method == :post
    assert hold_request.url.path == "/fhir/R4/Appointment/$hold"

    assert {:ok, %{"type" => "transaction-response"}} =
             Scheduling.book_appointment(client, params)

    assert_received {:scheduling_request, %Req.Request{} = book_request}
    assert book_request.method == :post
    assert book_request.url.path == "/fhir/R4/Appointment/$book"

    assert {:ok, %{"type" => "transaction-response"}} =
             Scheduling.confirm_appointment(client, "appt-1")

    assert_received {:scheduling_request, %Req.Request{} = confirm_request}
    assert confirm_request.method == :post
    assert confirm_request.url.path == "/fhir/R4/Appointment/appt-1/$confirm"

    assert {:ok, %{"status" => "cancelled"}} = Scheduling.cancel_appointment(client, "appt-1")
    assert_received {:scheduling_request, %Req.Request{} = cancel_request}
    assert cancel_request.method == :post
    assert cancel_request.url.path == "/fhir/R4/Appointment/appt-1/$cancel"
  end

  test "next resource helpers target correct paths and useful search params" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:next_resource_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Task/t1" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Task", "id" => "t1"})

          "/fhir/R4/Task" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Communication" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/QuestionnaireResponse" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Observation" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Condition" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/DocumentReference" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/ServiceRequest" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/DiagnosticReport" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Schedule" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Slot" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/HealthcareService" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/Location" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          "/fhir/R4/PractitionerRole" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"id" => "t1"}} = Task.get(client, "t1")
    assert_received {:next_resource_request, %Req.Request{} = task_get}
    assert task_get.url.path == "/fhir/R4/Task/t1"

    assert {:ok, %{"type" => "searchset"}} = Task.search_by_owner(client, "Practitioner/dr-1")
    assert_received {:next_resource_request, %Req.Request{} = task_by_owner}
    assert task_by_owner.url.query == "owner=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} = Task.search_by_status(client, "requested")
    assert_received {:next_resource_request, %Req.Request{} = task_by_status}
    assert task_by_status.url.query == "status=requested"

    assert {:ok, %{"type" => "searchset"}} =
             Communication.search_by_sender(client, "Practitioner/dr-1")

    assert_received {:next_resource_request, %Req.Request{} = communication_by_sender}
    assert communication_by_sender.url.path == "/fhir/R4/Communication"
    assert communication_by_sender.url.query == "sender=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} =
             QuestionnaireResponse.search_by_questionnaire(client, "Questionnaire/intake")

    assert_received {:next_resource_request, %Req.Request{} = questionnaire_by_questionnaire}

    assert questionnaire_by_questionnaire.url.path == "/fhir/R4/QuestionnaireResponse"
    assert questionnaire_by_questionnaire.url.query == "questionnaire=Questionnaire%2Fintake"

    assert {:ok, %{"type" => "searchset"}} =
             QuestionnaireResponse.search_by_subject(client, "Patient/p1")

    assert_received {:next_resource_request, %Req.Request{} = questionnaire_by_subject}
    assert questionnaire_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Observation.search_by_code(client, "http://loinc.org", "85354-9")

    assert_received {:next_resource_request, %Req.Request{} = observation_by_code}

    assert observation_by_code.url.path == "/fhir/R4/Observation"
    assert observation_by_code.url.query == "code=http%3A%2F%2Floinc.org%7C85354-9"

    assert {:ok, %{"type" => "searchset"}} =
             Observation.search_by_category(client, "vital-signs")

    assert_received {:next_resource_request, %Req.Request{} = observation_by_category}
    assert observation_by_category.url.query == "category=vital-signs"

    assert {:ok, %{"type" => "searchset"}} =
             Condition.search_by_clinical_status(client, "active")

    assert_received {:next_resource_request, %Req.Request{} = condition_by_status}
    assert condition_by_status.url.path == "/fhir/R4/Condition"
    assert condition_by_status.url.query == "clinical-status=active"

    assert {:ok, %{"type" => "searchset"}} =
             DocumentReference.search_by_encounter(client, "Encounter/e1")

    assert_received {:next_resource_request, %Req.Request{} = document_reference_by_encounter}

    assert document_reference_by_encounter.url.path == "/fhir/R4/DocumentReference"
    assert document_reference_by_encounter.url.query == "encounter=Encounter%2Fe1"

    assert {:ok, %{"type" => "searchset"}} =
             ServiceRequest.search_by_requester(client, "Practitioner/dr-1")

    assert_received {:next_resource_request, %Req.Request{} = service_request_by_requester}
    assert service_request_by_requester.url.path == "/fhir/R4/ServiceRequest"
    assert service_request_by_requester.url.query == "requester=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} =
             ServiceRequest.search_by_code(client, "http://loinc.org", "24323-8")

    assert_received {:next_resource_request, %Req.Request{} = service_request_by_code}
    assert service_request_by_code.url.query == "code=http%3A%2F%2Floinc.org%7C24323-8"

    assert {:ok, %{"type" => "searchset"}} =
             DiagnosticReport.search_by_based_on(client, "ServiceRequest/sr-1")

    assert_received {:next_resource_request, %Req.Request{} = diagnostic_report_by_based_on}
    assert diagnostic_report_by_based_on.url.path == "/fhir/R4/DiagnosticReport"
    assert diagnostic_report_by_based_on.url.query == "based-on=ServiceRequest%2Fsr-1"

    assert {:ok, %{"type" => "searchset"}} = Schedule.search_by_actor(client, "Practitioner/dr-1")
    assert_received {:next_resource_request, %Req.Request{} = schedule_by_actor}
    assert schedule_by_actor.url.path == "/fhir/R4/Schedule"
    assert schedule_by_actor.url.query == "actor=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} = Slot.search_by_schedule(client, "Schedule/s-1")
    assert_received {:next_resource_request, %Req.Request{} = slot_by_schedule}
    assert slot_by_schedule.url.path == "/fhir/R4/Slot"
    assert slot_by_schedule.url.query == "schedule=Schedule%2Fs-1"

    assert {:ok, %{"type" => "searchset"}} =
             HealthcareService.search_by_identifier(client, "http://svc.example", "office-visit")

    assert_received {:next_resource_request, %Req.Request{} = healthcare_service_by_identifier}

    assert healthcare_service_by_identifier.url.path == "/fhir/R4/HealthcareService"

    assert healthcare_service_by_identifier.url.query ==
             "identifier=http%3A%2F%2Fsvc.example%7Coffice-visit"

    assert {:ok, %{"type" => "searchset"}} =
             Location.search_by_organization(client, "Organization/org-1")

    assert_received {:next_resource_request, %Req.Request{} = location_by_organization}
    assert location_by_organization.url.path == "/fhir/R4/Location"
    assert location_by_organization.url.query == "organization=Organization%2Forg-1"

    assert {:ok, %{"type" => "searchset"}} =
             PractitionerRole.search_by_practitioner(client, "Practitioner/dr-1")

    assert_received {:next_resource_request, %Req.Request{} = practitioner_role_by_practitioner}

    assert practitioner_role_by_practitioner.url.path == "/fhir/R4/PractitionerRole"
    assert practitioner_role_by_practitioner.url.query == "practitioner=Practitioner%2Fdr-1"
  end

  test "workflow modules compose resource helpers for common middleman flows" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/Task"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:patch, "/fhir/R4/Task/task-1"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Task", "status" => "completed"}
            )

          {:patch, "/fhir/R4/Task/task-2"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Task", "status" => "cancelled"}
            )

          {:post, "/fhir/R4/ServiceRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "ServiceRequest", "id" => "sr-1"}
            )

          {:get, "/fhir/R4/ServiceRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/DiagnosticReport"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/QuestionnaireResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "QuestionnaireResponse", "id" => "qr-1"}
            )

          {:get, "/fhir/R4/QuestionnaireResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Observation"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Condition"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/DocumentReference"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             Tasks.list_for_owner(client, "Practitioner/dr-1", %{"status" => "requested"})

    assert_received {:workflow_request, %Req.Request{} = tasks_for_owner}
    assert tasks_for_owner.url.path == "/fhir/R4/Task"

    assert URI.decode_query(tasks_for_owner.url.query) == %{
             "owner" => "Practitioner/dr-1",
             "status" => "requested"
           }

    assert {:ok, %{"status" => "completed"}} = Tasks.complete_task(client, "task-1")
    assert_received {:workflow_request, %Req.Request{} = complete_task}
    assert complete_task.method == :patch
    assert complete_task.url.path == "/fhir/R4/Task/task-1"

    assert complete_task.body ==
             Jason.encode!([%{"op" => "replace", "path" => "/status", "value" => "completed"}])

    assert {:ok, %{"status" => "cancelled"}} = Tasks.cancel_task(client, "task-2")
    assert_received {:workflow_request, %Req.Request{} = cancel_task}
    assert cancel_task.method == :patch
    assert cancel_task.url.path == "/fhir/R4/Task/task-2"

    assert {:ok, %{"id" => "sr-1"}} =
             Orders.create_service_request(client, %{"status" => "active"})

    assert_received {:workflow_request, %Req.Request{} = create_service_request}
    assert create_service_request.method == :post
    assert create_service_request.url.path == "/fhir/R4/ServiceRequest"

    assert {:ok, %{"type" => "searchset"}} =
             Orders.service_requests_for_subject(client, "Patient/p1")

    assert_received {:workflow_request, %Req.Request{} = service_requests_for_subject}
    assert service_requests_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Orders.diagnostic_reports_for_based_on(client, "ServiceRequest/sr-1")

    assert_received {:workflow_request, %Req.Request{} = diagnostic_reports_for_based_on}
    assert diagnostic_reports_for_based_on.url.path == "/fhir/R4/DiagnosticReport"
    assert diagnostic_reports_for_based_on.url.query == "based-on=ServiceRequest%2Fsr-1"

    assert {:ok, %{"id" => "qr-1"}} =
             Intake.submit_questionnaire_response(client, %{"status" => "completed"})

    assert_received {:workflow_request, %Req.Request{} = submit_questionnaire_response}
    assert submit_questionnaire_response.method == :post
    assert submit_questionnaire_response.url.path == "/fhir/R4/QuestionnaireResponse"

    assert {:ok, %{"type" => "searchset"}} =
             Intake.questionnaire_responses_for_encounter(client, "Encounter/e1")

    assert_received {:workflow_request, %Req.Request{} = questionnaire_responses_for_encounter}
    assert questionnaire_responses_for_encounter.url.query == "encounter=Encounter%2Fe1"

    assert {:ok, %{"type" => "searchset"}} =
             Charting.observations_for_patient(client, "Patient/p1", %{
               "category" => "vital-signs"
             })

    assert_received {:workflow_request, %Req.Request{} = observations_for_patient}

    assert URI.decode_query(observations_for_patient.url.query) == %{
             "category" => "vital-signs",
             "patient" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} = Charting.conditions_for_patient(client, "Patient/p1")
    assert_received {:workflow_request, %Req.Request{} = conditions_for_patient}
    assert conditions_for_patient.url.path == "/fhir/R4/Condition"
    assert conditions_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Charting.documents_for_encounter(client, "Encounter/e1")

    assert_received {:workflow_request, %Req.Request{} = documents_for_encounter}
    assert documents_for_encounter.url.path == "/fhir/R4/DocumentReference"
    assert documents_for_encounter.url.query == "encounter=Encounter%2Fe1"
  end

  test "billing resource helpers target claim-side resources and operations" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:billing_resource_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/Claim"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ClaimResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ChargeItem"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Account"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/CoverageEligibilityRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/CoverageEligibilityResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Invoice"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ChargeItemDefinition"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/ChargeItemDefinition/cid-1/$apply"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "ChargeItem", "id" => "charge-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} = Claim.search_by_patient(client, "Patient/p1")
    assert_received {:billing_resource_request, %Req.Request{} = claim_by_patient}
    assert claim_by_patient.url.path == "/fhir/R4/Claim"
    assert claim_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = Claim.search_by_provider(client, "Practitioner/dr-1")
    assert_received {:billing_resource_request, %Req.Request{} = claim_by_provider}
    assert claim_by_provider.url.query == "provider=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} = ClaimResponse.search_by_claim(client, "Claim/c1")
    assert_received {:billing_resource_request, %Req.Request{} = claim_response_by_claim}
    assert claim_response_by_claim.url.path == "/fhir/R4/ClaimResponse"
    assert claim_response_by_claim.url.query == "claim=Claim%2Fc1"

    assert {:ok, %{"type" => "searchset"}} = ChargeItem.search_by_account(client, "Account/a1")
    assert_received {:billing_resource_request, %Req.Request{} = charge_item_by_account}
    assert charge_item_by_account.url.path == "/fhir/R4/ChargeItem"
    assert charge_item_by_account.url.query == "account=Account%2Fa1"

    assert {:ok, %{"type" => "searchset"}} =
             ChargeItem.search_by_encounter(client, "Encounter/e1")

    assert_received {:billing_resource_request, %Req.Request{} = charge_item_by_encounter}
    assert charge_item_by_encounter.url.query == "context=Encounter%2Fe1"

    assert {:ok, %{"type" => "searchset"}} = Account.search_by_subject(client, "Patient/p1")
    assert_received {:billing_resource_request, %Req.Request{} = account_by_subject}
    assert account_by_subject.url.path == "/fhir/R4/Account"
    assert account_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CoverageEligibilityRequest.search_by_provider(client, "Organization/org-1")

    assert_received {:billing_resource_request, %Req.Request{} = cer_by_provider}
    assert cer_by_provider.url.path == "/fhir/R4/CoverageEligibilityRequest"
    assert cer_by_provider.url.query == "provider=Organization%2Forg-1"

    assert {:ok, %{"type" => "searchset"}} =
             CoverageEligibilityResponse.search_by_request(
               client,
               "CoverageEligibilityRequest/req-1"
             )

    assert_received {:billing_resource_request, %Req.Request{} = ceresp_by_request}
    assert ceresp_by_request.url.path == "/fhir/R4/CoverageEligibilityResponse"
    assert ceresp_by_request.url.query == "request=CoverageEligibilityRequest%2Freq-1"

    assert {:ok, %{"type" => "searchset"}} = Invoice.search_by_account(client, "Account/a1")
    assert_received {:billing_resource_request, %Req.Request{} = invoice_by_account}
    assert invoice_by_account.url.path == "/fhir/R4/Invoice"
    assert invoice_by_account.url.query == "account=Account%2Fa1"

    params = %{
      "resourceType" => "Parameters",
      "parameter" => [
        %{"name" => "chargeItem", "valueReference" => %{"reference" => "ChargeItem/charge-1"}}
      ]
    }

    assert {:ok, %{"id" => "charge-1"}} =
             ChargeItemDefinition.apply_definition(client, "cid-1", params)

    assert_received {:billing_resource_request, %Req.Request{} = apply_definition}
    assert apply_definition.method == :post
    assert apply_definition.url.path == "/fhir/R4/ChargeItemDefinition/cid-1/$apply"
    assert IO.iodata_to_binary(apply_definition.body) == Jason.encode!(params)
  end

  test "billing workflow module composes claim, export, submit, and eligibility flows" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:billing_workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/Claim"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ClaimResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ChargeItem"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Account"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/CoverageEligibilityRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/CoverageEligibilityResponse"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Claim/c1/$export"} ->
            Req.Response.new(
              status: 200,
              body: %{
                "resourceType" => "Media",
                "content" => %{"contentType" => "application/pdf"}
              }
            )

          {:post, "/fhir/R4/Claim/$export"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Media", "content" => %{"title" => "cms-1500.pdf"}}
            )

          {:post, "/fhir/R4/Claim/c1/$stedi-submit-claim"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "ClaimResponse", "id" => "stedi-response"}
            )

          {:post, "/fhir/R4/Claim/c1/$candid-submit-claim"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "ClaimResponse", "id" => "candid-response"}
            )

          {:post, "/fhir/R4/ChargeItemDefinition/cid-1/$apply"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "ChargeItem", "id" => "charge-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} = Billing.claims_for_patient(client, "Patient/p1")
    assert_received {:billing_workflow_request, %Req.Request{} = claims_for_patient}
    assert claims_for_patient.url.path == "/fhir/R4/Claim"
    assert claims_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = Billing.claim_responses_for_claim(client, "Claim/c1")
    assert_received {:billing_workflow_request, %Req.Request{} = claim_responses_for_claim}
    assert claim_responses_for_claim.url.path == "/fhir/R4/ClaimResponse"
    assert claim_responses_for_claim.url.query == "claim=Claim%2Fc1"

    assert {:ok, %{"type" => "searchset"}} =
             Billing.charge_items_for_account(client, "Account/a1")

    assert_received {:billing_workflow_request, %Req.Request{} = charge_items_for_account}
    assert charge_items_for_account.url.path == "/fhir/R4/ChargeItem"
    assert charge_items_for_account.url.query == "account=Account%2Fa1"

    assert {:ok, %{"type" => "searchset"}} = Billing.accounts_for_patient(client, "Patient/p1")
    assert_received {:billing_workflow_request, %Req.Request{} = accounts_for_patient}
    assert accounts_for_patient.url.path == "/fhir/R4/Account"
    assert accounts_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Billing.eligibility_requests_for_patient(client, "Patient/p1")

    assert_received {:billing_workflow_request, %Req.Request{} = eligibility_requests_for_patient}
    assert eligibility_requests_for_patient.url.path == "/fhir/R4/CoverageEligibilityRequest"
    assert eligibility_requests_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Billing.eligibility_responses_for_patient(client, "Patient/p1")

    assert_received {:billing_workflow_request,
                     %Req.Request{} = eligibility_responses_for_patient}

    assert eligibility_responses_for_patient.url.path == "/fhir/R4/CoverageEligibilityResponse"
    assert eligibility_responses_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"resourceType" => "Media"}} = Billing.export_claim(client, "c1")
    assert_received {:billing_workflow_request, %Req.Request{} = export_claim_instance}
    assert export_claim_instance.method == :get
    assert export_claim_instance.url.path == "/fhir/R4/Claim/c1/$export"

    export_params = %{
      "resourceType" => "Parameters",
      "parameter" => [
        %{"name" => "resource", "resource" => %{"resourceType" => "Claim", "id" => "c1"}}
      ]
    }

    assert {:ok, %{"resourceType" => "Media"}} = Billing.export_claim(client, export_params, [])
    assert_received {:billing_workflow_request, %Req.Request{} = export_claim_type}
    assert export_claim_type.method == :post
    assert export_claim_type.url.path == "/fhir/R4/Claim/$export"
    assert IO.iodata_to_binary(export_claim_type.body) == Jason.encode!(export_params)

    assert {:ok, %{"id" => "stedi-response"}} = Billing.submit_claim_to_stedi(client, "c1")
    assert_received {:billing_workflow_request, %Req.Request{} = submit_claim_to_stedi}
    assert submit_claim_to_stedi.method == :post
    assert submit_claim_to_stedi.url.path == "/fhir/R4/Claim/c1/$stedi-submit-claim"

    assert {:ok, %{"id" => "candid-response"}} = Billing.submit_claim_to_candid(client, "c1")
    assert_received {:billing_workflow_request, %Req.Request{} = submit_claim_to_candid}
    assert submit_claim_to_candid.method == :post
    assert submit_claim_to_candid.url.path == "/fhir/R4/Claim/c1/$candid-submit-claim"

    apply_params = %{
      "resourceType" => "Parameters",
      "parameter" => [
        %{"name" => "chargeItem", "valueReference" => %{"reference" => "ChargeItem/charge-1"}}
      ]
    }

    assert {:ok, %{"id" => "charge-1"}} =
             Billing.apply_charge_item_definition(client, "cid-1", apply_params)

    assert_received {:billing_workflow_request, %Req.Request{} = apply_charge_item_definition}
    assert apply_charge_item_definition.method == :post
    assert apply_charge_item_definition.url.path == "/fhir/R4/ChargeItemDefinition/cid-1/$apply"
    assert IO.iodata_to_binary(apply_charge_item_definition.body) == Jason.encode!(apply_params)
  end

  test "automation resources support bot execution, subscription search, and audit tracing" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:automation_resource_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/Bot"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/Bot/bot-1/$execute"} ->
            Req.Response.new(status: 200, body: %{"ok" => true})

          {:post, "/fhir/R4/Bot/bot-1/$deploy"} ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Bot", "id" => "bot-1"})

          {:get, "/fhir/R4/Subscription"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/AuditEvent"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Provenance"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} = Bot.search_by_name(client, "sync-bot")
    assert_received {:automation_resource_request, %Req.Request{} = bot_by_name}
    assert bot_by_name.url.path == "/fhir/R4/Bot"
    assert bot_by_name.url.query == "name=sync-bot"

    bot_input = %{"resourceType" => "Patient", "id" => "patient-1"}
    assert {:ok, %{"ok" => true}} = Bot.execute(client, "bot-1", bot_input)
    assert_received {:automation_resource_request, %Req.Request{} = execute_bot}
    assert execute_bot.method == :post
    assert execute_bot.url.path == "/fhir/R4/Bot/bot-1/$execute"
    assert IO.iodata_to_binary(execute_bot.body) == Jason.encode!(bot_input)

    assert {:ok, %{"id" => "bot-1"}} =
             Bot.deploy(client, "bot-1", %{"code" => "console.log('hi')"})

    assert_received {:automation_resource_request, %Req.Request{} = deploy_bot}
    assert deploy_bot.method == :post
    assert deploy_bot.url.path == "/fhir/R4/Bot/bot-1/$deploy"

    assert {:ok, %{"type" => "searchset"}} = Subscription.search_by_criteria(client, "Patient")
    assert_received {:automation_resource_request, %Req.Request{} = subscription_by_criteria}
    assert subscription_by_criteria.url.path == "/fhir/R4/Subscription"
    assert subscription_by_criteria.url.query == "criteria=Patient"

    assert {:ok, %{"type" => "searchset"}} =
             Subscription.search_by_channel_type(client, "rest-hook")

    assert_received {:automation_resource_request, %Req.Request{} = subscription_by_channel_type}
    assert subscription_by_channel_type.url.query == "channel-type=rest-hook"

    assert {:ok, %{"type" => "searchset"}} = AuditEvent.search_by_entity(client, "Bot/bot-1")
    assert_received {:automation_resource_request, %Req.Request{} = audit_event_by_entity}
    assert audit_event_by_entity.url.path == "/fhir/R4/AuditEvent"
    assert audit_event_by_entity.url.query == "entity=Bot%2Fbot-1"

    assert {:ok, %{"type" => "searchset"}} =
             Provenance.search_by_target(client, "Patient/patient-1")

    assert_received {:automation_resource_request, %Req.Request{} = provenance_by_target}
    assert provenance_by_target.url.path == "/fhir/R4/Provenance"
    assert provenance_by_target.url.query == "target=Patient%2Fpatient-1"
  end

  test "automation workflow module composes execute, deploy, patch, and subscribe flows" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:automation_workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:post, "/fhir/R4/Bot/bot-1/$execute"} ->
            Req.Response.new(status: 200, body: %{"executed" => true})

          {:post, "/fhir/R4/Bot/bot-1/$deploy"} ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Bot", "id" => "bot-1"})

          {:get, "/fhir/R4/Subscription"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:patch, "/fhir/R4/Subscription/sub-1"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Subscription", "status" => "active"}
            )

          {:patch, "/fhir/R4/Subscription/sub-2"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Subscription", "status" => "off"}
            )

          {:get, "/fhir/R4/AuditEvent"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Provenance"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/Subscription"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Subscription", "id" => "sub-3"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"executed" => true}} =
             Automation.execute_bot(client, "bot-1", %{
               "resourceType" => "Patient",
               "id" => "patient-1"
             })

    assert_received {:automation_workflow_request, %Req.Request{} = execute_bot}
    assert execute_bot.method == :post
    assert execute_bot.url.path == "/fhir/R4/Bot/bot-1/$execute"

    assert {:ok, %{"id" => "bot-1"}} =
             Automation.deploy_bot(client, "bot-1", %{"code" => "console.log('hi')"})

    assert_received {:automation_workflow_request, %Req.Request{} = deploy_bot}
    assert deploy_bot.method == :post
    assert deploy_bot.url.path == "/fhir/R4/Bot/bot-1/$deploy"

    assert {:ok, %{"type" => "searchset"}} =
             Automation.subscriptions_for_criteria(client, "Observation?category=vital-signs")

    assert_received {:automation_workflow_request, %Req.Request{} = subscriptions_for_criteria}
    assert subscriptions_for_criteria.url.path == "/fhir/R4/Subscription"
    assert subscriptions_for_criteria.url.query == "criteria=Observation%3Fcategory%3Dvital-signs"

    assert {:ok, %{"status" => "active"}} = Automation.activate_subscription(client, "sub-1")
    assert_received {:automation_workflow_request, %Req.Request{} = activate_subscription}
    assert activate_subscription.method == :patch
    assert activate_subscription.url.path == "/fhir/R4/Subscription/sub-1"

    assert activate_subscription.body ==
             Jason.encode!([%{"op" => "replace", "path" => "/status", "value" => "active"}])

    assert {:ok, %{"status" => "off"}} = Automation.pause_subscription(client, "sub-2")
    assert_received {:automation_workflow_request, %Req.Request{} = pause_subscription}
    assert pause_subscription.method == :patch
    assert pause_subscription.url.path == "/fhir/R4/Subscription/sub-2"

    assert {:ok, %{"type" => "searchset"}} = Automation.bot_audit_events(client, "Bot/bot-1")
    assert_received {:automation_workflow_request, %Req.Request{} = bot_audit_events}
    assert bot_audit_events.url.path == "/fhir/R4/AuditEvent"
    assert bot_audit_events.url.query == "entity=Bot%2Fbot-1"

    assert {:ok, %{"type" => "searchset"}} =
             Automation.provenance_for_target(client, "Patient/patient-1")

    assert_received {:automation_workflow_request, %Req.Request{} = provenance_for_target}
    assert provenance_for_target.url.path == "/fhir/R4/Provenance"
    assert provenance_for_target.url.query == "target=Patient%2Fpatient-1"

    assert {:ok, %{"id" => "sub-3"}} =
             Automation.subscribe_bot_to_resource(client, "Patient", "bot-1",
               reason: "Run bot on patient changes",
               headers: [{"x-test", "1"}]
             )

    assert_received {:automation_workflow_request, %Req.Request{} = subscribe_bot_to_resource}
    assert subscribe_bot_to_resource.method == :post
    assert subscribe_bot_to_resource.url.path == "/fhir/R4/Subscription"

    assert IO.iodata_to_binary(subscribe_bot_to_resource.body) ==
             Jason.encode!(%{
               "resourceType" => "Subscription",
               "status" => "active",
               "reason" => "Run bot on patient changes",
               "criteria" => "Patient",
               "channel" => %{
                 "type" => "rest-hook",
                 "endpoint" => "Bot/bot-1",
                 "payload" => "application/fhir+json",
                 "header" => [%{"name" => "x-test", "value" => "1"}]
               }
             })
  end

  test "medication and allergy resources target correct paths and search params" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:medication_resource_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/AllergyIntolerance"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/MedicationRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/MedicationStatement"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Medication"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/MedicationRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "MedicationRequest", "id" => "mr-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             AllergyIntolerance.search_by_patient(client, "Patient/p1")

    assert_received {:medication_resource_request, %Req.Request{} = allergy_by_patient}
    assert allergy_by_patient.url.path == "/fhir/R4/AllergyIntolerance"
    assert allergy_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             AllergyIntolerance.search_by_clinical_status(client, "active")

    assert_received {:medication_resource_request, %Req.Request{} = allergy_by_status}
    assert allergy_by_status.url.query == "clinical-status=active"

    assert {:ok, %{"type" => "searchset"}} =
             MedicationRequest.search_by_subject(client, "Patient/p1")

    assert_received {:medication_resource_request, %Req.Request{} = medication_request_by_subject}
    assert medication_request_by_subject.url.path == "/fhir/R4/MedicationRequest"
    assert medication_request_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             MedicationRequest.search_by_requester(client, "Practitioner/dr-1")

    assert_received {:medication_resource_request,
                     %Req.Request{} = medication_request_by_requester}

    assert medication_request_by_requester.url.query == "requester=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} =
             MedicationStatement.search_by_subject(client, "Patient/p1")

    assert_received {:medication_resource_request,
                     %Req.Request{} = medication_statement_by_subject}

    assert medication_statement_by_subject.url.path == "/fhir/R4/MedicationStatement"
    assert medication_statement_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Medication.search_by_code(
               client,
               "http://www.nlm.nih.gov/research/umls/rxnorm",
               "860975"
             )

    assert_received {:medication_resource_request, %Req.Request{} = medication_by_code}
    assert medication_by_code.url.path == "/fhir/R4/Medication"

    assert medication_by_code.url.query ==
             "code=http%3A%2F%2Fwww.nlm.nih.gov%2Fresearch%2Fumls%2Frxnorm%7C860975"

    assert {:ok, %{"id" => "mr-1"}} =
             Medications.prescribe(client, %{"status" => "active"})

    assert_received {:medication_resource_request, %Req.Request{} = prescribe}
    assert prescribe.method == :post
    assert prescribe.url.path == "/fhir/R4/MedicationRequest"
  end

  test "medication workflow module composes common allergy and medication queries" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:medication_workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/AllergyIntolerance"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/MedicationRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/MedicationStatement"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/MedicationRequest"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "MedicationRequest", "id" => "mr-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             Medications.allergies_for_patient(client, "Patient/p1")

    assert_received {:medication_workflow_request, %Req.Request{} = allergies_for_patient}
    assert allergies_for_patient.url.path == "/fhir/R4/AllergyIntolerance"
    assert allergies_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Medications.active_allergies_for_patient(client, "Patient/p1")

    assert_received {:medication_workflow_request, %Req.Request{} = active_allergies_for_patient}

    assert URI.decode_query(active_allergies_for_patient.url.query) == %{
             "clinical-status" => "active",
             "patient" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             Medications.medication_requests_for_subject(client, "Patient/p1")

    assert_received {:medication_workflow_request,
                     %Req.Request{} = medication_requests_for_subject}

    assert medication_requests_for_subject.url.path == "/fhir/R4/MedicationRequest"
    assert medication_requests_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Medications.active_medication_requests_for_subject(client, "Patient/p1")

    assert_received {:medication_workflow_request,
                     %Req.Request{} = active_medication_requests_for_subject}

    assert URI.decode_query(active_medication_requests_for_subject.url.query) == %{
             "status" => "active",
             "subject" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             Medications.medication_history_for_subject(client, "Patient/p1")

    assert_received {:medication_workflow_request,
                     %Req.Request{} = medication_history_for_subject}

    assert medication_history_for_subject.url.path == "/fhir/R4/MedicationStatement"
    assert medication_history_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Medications.active_medication_history_for_subject(client, "Patient/p1")

    assert_received {:medication_workflow_request,
                     %Req.Request{} = active_medication_history_for_subject}

    assert URI.decode_query(active_medication_history_for_subject.url.query) == %{
             "status" => "active",
             "subject" => "Patient/p1"
           }
  end

  test "care coordination and family resources target correct paths and queries" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:care_resource_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/CareTeam"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/RelatedPerson"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ClinicalImpression"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/CareTeam"} ->
            Req.Response.new(status: 200, body: %{"resourceType" => "CareTeam", "id" => "ct-1"})

          {:post, "/fhir/R4/RelatedPerson"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "RelatedPerson", "id" => "rp-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} = CareTeam.search_by_subject(client, "Patient/p1")
    assert_received {:care_resource_request, %Req.Request{} = care_team_by_subject}
    assert care_team_by_subject.url.path == "/fhir/R4/CareTeam"
    assert care_team_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CareTeam.search_by_participant(client, "Practitioner/dr-1")

    assert_received {:care_resource_request, %Req.Request{} = care_team_by_participant}
    assert care_team_by_participant.url.query == "participant=Practitioner%2Fdr-1"

    assert {:ok, %{"type" => "searchset"}} =
             RelatedPerson.search_by_patient(client, "Patient/p1")

    assert_received {:care_resource_request, %Req.Request{} = related_person_by_patient}
    assert related_person_by_patient.url.path == "/fhir/R4/RelatedPerson"
    assert related_person_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = RelatedPerson.search_by_active(client, true)
    assert_received {:care_resource_request, %Req.Request{} = related_person_by_active}
    assert related_person_by_active.url.query == "active=true"

    assert {:ok, %{"type" => "searchset"}} =
             ClinicalImpression.search_by_encounter(client, "Encounter/e1")

    assert_received {:care_resource_request, %Req.Request{} = clinical_impression_by_encounter}
    assert clinical_impression_by_encounter.url.path == "/fhir/R4/ClinicalImpression"
    assert clinical_impression_by_encounter.url.query == "encounter=Encounter%2Fe1"

    assert {:ok, %{"id" => "ct-1"}} =
             CareCoordination.create_care_team(client, %{"status" => "active"})

    assert_received {:care_resource_request, %Req.Request{} = create_care_team}
    assert create_care_team.method == :post
    assert create_care_team.url.path == "/fhir/R4/CareTeam"

    assert {:ok, %{"id" => "rp-1"}} =
             CareCoordination.add_related_person(client, %{"active" => true})

    assert_received {:care_resource_request, %Req.Request{} = add_related_person}
    assert add_related_person.method == :post
    assert add_related_person.url.path == "/fhir/R4/RelatedPerson"
  end

  test "care coordination workflow composes team, family, and assessment lookups" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:care_workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/CareTeam"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/RelatedPerson"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/ClinicalImpression"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             CareCoordination.care_teams_for_subject(client, "Patient/p1")

    assert_received {:care_workflow_request, %Req.Request{} = care_teams_for_subject}
    assert care_teams_for_subject.url.path == "/fhir/R4/CareTeam"
    assert care_teams_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CareCoordination.active_care_teams_for_subject(client, "Patient/p1")

    assert_received {:care_workflow_request, %Req.Request{} = active_care_teams_for_subject}

    assert URI.decode_query(active_care_teams_for_subject.url.query) == %{
             "status" => "active",
             "subject" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             CareCoordination.family_for_patient(client, "Patient/p1")

    assert_received {:care_workflow_request, %Req.Request{} = family_for_patient}
    assert family_for_patient.url.path == "/fhir/R4/RelatedPerson"
    assert family_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CareCoordination.active_family_for_patient(client, "Patient/p1")

    assert_received {:care_workflow_request, %Req.Request{} = active_family_for_patient}

    assert URI.decode_query(active_family_for_patient.url.query) == %{
             "active" => "true",
             "patient" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             CareCoordination.clinical_impressions_for_patient(client, "Patient/p1")

    assert_received {:care_workflow_request, %Req.Request{} = clinical_impressions_for_patient}
    assert clinical_impressions_for_patient.url.path == "/fhir/R4/ClinicalImpression"
    assert clinical_impressions_for_patient.url.query == "patient=Patient%2Fp1"
  end

  test "care plan, goal, and immunization resources target correct paths and queries" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:care_planning_resource_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/CarePlan"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Goal"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Immunization"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:post, "/fhir/R4/CarePlan"} ->
            Req.Response.new(status: 200, body: %{"resourceType" => "CarePlan", "id" => "cp-1"})

          {:post, "/fhir/R4/Goal"} ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Goal", "id" => "goal-1"})

          {:post, "/fhir/R4/Immunization"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Immunization", "id" => "imm-1"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} = CarePlan.search_by_subject(client, "Patient/p1")
    assert_received {:care_planning_resource_request, %Req.Request{} = care_plan_by_subject}
    assert care_plan_by_subject.url.path == "/fhir/R4/CarePlan"
    assert care_plan_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = CarePlan.search_by_care_team(client, "CareTeam/ct-1")
    assert_received {:care_planning_resource_request, %Req.Request{} = care_plan_by_care_team}
    assert care_plan_by_care_team.url.query == "care-team=CareTeam%2Fct-1"

    assert {:ok, %{"type" => "searchset"}} = Goal.search_by_subject(client, "Patient/p1")
    assert_received {:care_planning_resource_request, %Req.Request{} = goal_by_subject}
    assert goal_by_subject.url.path == "/fhir/R4/Goal"
    assert goal_by_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} = Goal.search_by_lifecycle_status(client, "active")
    assert_received {:care_planning_resource_request, %Req.Request{} = goal_by_lifecycle_status}
    assert goal_by_lifecycle_status.url.query == "lifecycle-status=active"

    assert {:ok, %{"type" => "searchset"}} = Immunization.search_by_patient(client, "Patient/p1")
    assert_received {:care_planning_resource_request, %Req.Request{} = immunization_by_patient}
    assert immunization_by_patient.url.path == "/fhir/R4/Immunization"
    assert immunization_by_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             Immunization.search_by_vaccine_code(client, "http://hl7.org/fhir/sid/cvx", "207")

    assert_received {:care_planning_resource_request,
                     %Req.Request{} = immunization_by_vaccine_code}

    assert immunization_by_vaccine_code.url.query ==
             "vaccine-code=http%3A%2F%2Fhl7.org%2Ffhir%2Fsid%2Fcvx%7C207"

    assert {:ok, %{"id" => "cp-1"}} =
             CarePlanning.create_care_plan(client, %{"status" => "active"})

    assert_received {:care_planning_resource_request, %Req.Request{} = create_care_plan}
    assert create_care_plan.method == :post
    assert create_care_plan.url.path == "/fhir/R4/CarePlan"

    assert {:ok, %{"id" => "goal-1"}} =
             CarePlanning.create_goal(client, %{"lifecycleStatus" => "active"})

    assert_received {:care_planning_resource_request, %Req.Request{} = create_goal}
    assert create_goal.method == :post
    assert create_goal.url.path == "/fhir/R4/Goal"

    assert {:ok, %{"id" => "imm-1"}} =
             CarePlanning.record_immunization(client, %{"status" => "completed"})

    assert_received {:care_planning_resource_request, %Req.Request{} = record_immunization}
    assert record_immunization.method == :post
    assert record_immunization.url.path == "/fhir/R4/Immunization"
  end

  test "care planning workflow composes plans, goals, and immunization lookups" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:care_planning_workflow_request, request})
      end

      response =
        case {request.method, request.url.path} do
          {_, "/oauth2/token"} ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          {:get, "/fhir/R4/CarePlan"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Goal"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )

          {:get, "/fhir/R4/Immunization"} ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter)

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.care_plans_for_subject(client, "Patient/p1")

    assert_received {:care_planning_workflow_request, %Req.Request{} = care_plans_for_subject}
    assert care_plans_for_subject.url.path == "/fhir/R4/CarePlan"
    assert care_plans_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.active_care_plans_for_subject(client, "Patient/p1")

    assert_received {:care_planning_workflow_request,
                     %Req.Request{} = active_care_plans_for_subject}

    assert URI.decode_query(active_care_plans_for_subject.url.query) == %{
             "status" => "active",
             "subject" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.goals_for_subject(client, "Patient/p1")

    assert_received {:care_planning_workflow_request, %Req.Request{} = goals_for_subject}
    assert goals_for_subject.url.path == "/fhir/R4/Goal"
    assert goals_for_subject.url.query == "subject=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.active_goals_for_subject(client, "Patient/p1")

    assert_received {:care_planning_workflow_request, %Req.Request{} = active_goals_for_subject}

    assert URI.decode_query(active_goals_for_subject.url.query) == %{
             "lifecycle-status" => "active",
             "subject" => "Patient/p1"
           }

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.immunizations_for_patient(client, "Patient/p1")

    assert_received {:care_planning_workflow_request, %Req.Request{} = immunizations_for_patient}
    assert immunizations_for_patient.url.path == "/fhir/R4/Immunization"
    assert immunizations_for_patient.url.query == "patient=Patient%2Fp1"

    assert {:ok, %{"type" => "searchset"}} =
             CarePlanning.immunizations_by_vaccine_code(
               client,
               "http://hl7.org/fhir/sid/cvx",
               "207"
             )

    assert_received {:care_planning_workflow_request,
                     %Req.Request{} = immunizations_by_vaccine_code}

    assert immunizations_by_vaccine_code.url.query ==
             "vaccine-code=http%3A%2F%2Fhl7.org%2Ffhir%2Fsid%2Fcvx%7C207"
  end

  defp client(adapter) do
    Medplum.new(
      base_url: "https://api.medplum.com/",
      client_id: "client-#{System.unique_integer([:positive])}",
      client_secret: "client-secret",
      req_options: [adapter: adapter]
    )
  end
end
