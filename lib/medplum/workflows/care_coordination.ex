defmodule Medplum.Workflows.CareCoordination do
  @moduledoc """
  Care coordination and family workflow helpers.
  """

  alias Medplum.Client
  alias Medplum.Resources.CareTeam
  alias Medplum.Resources.ClinicalImpression
  alias Medplum.Resources.RelatedPerson

  @spec care_teams_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def care_teams_for_subject(%Client{} = client, subject, params \\ %{}) do
    CareTeam.search_by_subject(client, subject, params)
  end

  @spec active_care_teams_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def active_care_teams_for_subject(%Client{} = client, subject, params \\ %{}) do
    params = Map.merge(params, %{"status" => "active"})
    CareTeam.search_by_subject(client, subject, params)
  end

  @spec care_teams_for_participant(Client.t(), String.t(), map()) :: Medplum.result()
  def care_teams_for_participant(%Client{} = client, participant, params \\ %{}) do
    CareTeam.search_by_participant(client, participant, params)
  end

  @spec family_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def family_for_patient(%Client{} = client, patient, params \\ %{}) do
    RelatedPerson.search_by_patient(client, patient, params)
  end

  @spec active_family_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def active_family_for_patient(%Client{} = client, patient, params \\ %{}) do
    params = Map.merge(params, %{"active" => "true"})
    RelatedPerson.search_by_patient(client, patient, params)
  end

  @spec clinical_impressions_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def clinical_impressions_for_patient(%Client{} = client, patient, params \\ %{}) do
    ClinicalImpression.search_by_patient(client, patient, params)
  end

  @spec clinical_impressions_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def clinical_impressions_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    ClinicalImpression.search_by_encounter(client, encounter, params)
  end

  @spec create_care_team(Client.t(), map()) :: Medplum.result()
  def create_care_team(%Client{} = client, attrs) do
    CareTeam.create(client, attrs)
  end

  @spec add_related_person(Client.t(), map()) :: Medplum.result()
  def add_related_person(%Client{} = client, attrs) do
    RelatedPerson.create(client, attrs)
  end
end
