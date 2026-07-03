defmodule Medplum.Workflows.Charting do
  @moduledoc """
  Charting-oriented workflow helpers for patient and encounter context.
  """

  alias Medplum.Client
  alias Medplum.Resources.Condition
  alias Medplum.Resources.DocumentReference
  alias Medplum.Resources.Observation

  @spec observations_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def observations_for_patient(%Client{} = client, patient, params \\ %{}) do
    Observation.search_by_patient(client, patient, params)
  end

  @spec observations_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def observations_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    Observation.search_by_encounter(client, encounter, params)
  end

  @spec conditions_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def conditions_for_patient(%Client{} = client, patient, params \\ %{}) do
    Condition.search_by_patient(client, patient, params)
  end

  @spec documents_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def documents_for_patient(%Client{} = client, patient, params \\ %{}) do
    DocumentReference.search_by_patient(client, patient, params)
  end

  @spec documents_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def documents_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    DocumentReference.search_by_encounter(client, encounter, params)
  end
end
