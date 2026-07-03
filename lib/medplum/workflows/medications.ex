defmodule Medplum.Workflows.Medications do
  @moduledoc """
  Medication and allergy workflow helpers.
  """

  alias Medplum.Client
  alias Medplum.Resources.AllergyIntolerance
  alias Medplum.Resources.MedicationRequest
  alias Medplum.Resources.MedicationStatement

  @spec allergies_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def allergies_for_patient(%Client{} = client, patient, params \\ %{}) do
    AllergyIntolerance.search_by_patient(client, patient, params)
  end

  @spec active_allergies_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def active_allergies_for_patient(%Client{} = client, patient, params \\ %{}) do
    params = Map.merge(params, %{"clinical-status" => "active"})
    AllergyIntolerance.search_by_patient(client, patient, params)
  end

  @spec medication_requests_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def medication_requests_for_subject(%Client{} = client, subject, params \\ %{}) do
    MedicationRequest.search_by_subject(client, subject, params)
  end

  @spec active_medication_requests_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def active_medication_requests_for_subject(%Client{} = client, subject, params \\ %{}) do
    params = Map.merge(params, %{"status" => "active"})
    MedicationRequest.search_by_subject(client, subject, params)
  end

  @spec medication_history_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def medication_history_for_subject(%Client{} = client, subject, params \\ %{}) do
    MedicationStatement.search_by_subject(client, subject, params)
  end

  @spec active_medication_history_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def active_medication_history_for_subject(%Client{} = client, subject, params \\ %{}) do
    params = Map.merge(params, %{"status" => "active"})
    MedicationStatement.search_by_subject(client, subject, params)
  end

  @spec prescribe(Client.t(), map()) :: Medplum.result()
  def prescribe(%Client{} = client, attrs) do
    MedicationRequest.create(client, attrs)
  end
end
