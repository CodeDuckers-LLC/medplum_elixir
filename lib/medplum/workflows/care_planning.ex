defmodule Medplum.Workflows.CarePlanning do
  @moduledoc """
  Care planning and preventive care workflow helpers.
  """

  alias Medplum.Client
  alias Medplum.Resources.CarePlan
  alias Medplum.Resources.Goal
  alias Medplum.Resources.Immunization

  @spec care_plans_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def care_plans_for_subject(%Client{} = client, subject, params \\ %{}) do
    CarePlan.search_by_subject(client, subject, params)
  end

  @spec active_care_plans_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def active_care_plans_for_subject(%Client{} = client, subject, params \\ %{}) do
    params = Map.merge(params, %{"status" => "active"})
    CarePlan.search_by_subject(client, subject, params)
  end

  @spec goals_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def goals_for_subject(%Client{} = client, subject, params \\ %{}) do
    Goal.search_by_subject(client, subject, params)
  end

  @spec active_goals_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def active_goals_for_subject(%Client{} = client, subject, params \\ %{}) do
    params = Map.merge(params, %{"lifecycle-status" => "active"})
    Goal.search_by_subject(client, subject, params)
  end

  @spec immunizations_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def immunizations_for_patient(%Client{} = client, patient, params \\ %{}) do
    Immunization.search_by_patient(client, patient, params)
  end

  @spec immunizations_by_vaccine_code(Client.t(), String.t(), String.t(), map()) ::
          Medplum.result()
  def immunizations_by_vaccine_code(%Client{} = client, system, code, params \\ %{}) do
    Immunization.search_by_vaccine_code(client, system, code, params)
  end

  @spec create_care_plan(Client.t(), map()) :: Medplum.result()
  def create_care_plan(%Client{} = client, attrs) do
    CarePlan.create(client, attrs)
  end

  @spec create_goal(Client.t(), map()) :: Medplum.result()
  def create_goal(%Client{} = client, attrs) do
    Goal.create(client, attrs)
  end

  @spec record_immunization(Client.t(), map()) :: Medplum.result()
  def record_immunization(%Client{} = client, attrs) do
    Immunization.create(client, attrs)
  end
end
