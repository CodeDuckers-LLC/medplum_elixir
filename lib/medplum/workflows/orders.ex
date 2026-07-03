defmodule Medplum.Workflows.Orders do
  @moduledoc """
  Order and results workflow helpers built on `ServiceRequest` and `DiagnosticReport`.
  """

  alias Medplum.Client
  alias Medplum.Resources.DiagnosticReport
  alias Medplum.Resources.ServiceRequest

  @spec create_service_request(Client.t(), map()) :: Medplum.result()
  def create_service_request(%Client{} = client, attrs) do
    ServiceRequest.create(client, attrs)
  end

  @spec service_requests_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def service_requests_for_subject(%Client{} = client, subject, params \\ %{}) do
    ServiceRequest.search_by_subject(client, subject, params)
  end

  @spec service_requests_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def service_requests_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    ServiceRequest.search_by_encounter(client, encounter, params)
  end

  @spec service_requests_for_requester(Client.t(), String.t(), map()) :: Medplum.result()
  def service_requests_for_requester(%Client{} = client, requester, params \\ %{}) do
    ServiceRequest.search_by_requester(client, requester, params)
  end

  @spec diagnostic_reports_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def diagnostic_reports_for_subject(%Client{} = client, subject, params \\ %{}) do
    DiagnosticReport.search_by_patient(client, subject, params)
  end

  @spec diagnostic_reports_for_based_on(Client.t(), String.t(), map()) :: Medplum.result()
  def diagnostic_reports_for_based_on(%Client{} = client, based_on, params \\ %{}) do
    DiagnosticReport.search_by_based_on(client, based_on, params)
  end
end
