defmodule Medplum.Resources.AuditEvent do
  @moduledoc """
  Convenience helpers for FHIR `AuditEvent` resource.

  ## Examples

      alias Medplum.Resources.AuditEvent

      {:ok, events} = AuditEvent.search_by_entity(client, "Patient/patient-123")
      {:ok, recent} = AuditEvent.search_by_date(client, "ge2026-07-01T00:00:00Z")
  """

  alias Medplum.Client

  @resource_type "AuditEvent"

  @spec get(Client.t(), String.t()) :: Medplum.result()
  def get(%Client{} = client, id), do: Medplum.read(client, @resource_type, id)

  @spec create(Client.t(), map()) :: Medplum.result()
  def create(%Client{} = client, attrs), do: Medplum.create(client, @resource_type, attrs)

  @spec update(Client.t(), String.t(), map()) :: Medplum.result()
  def update(%Client{} = client, id, attrs), do: Medplum.update(client, @resource_type, id, attrs)

  @spec delete(Client.t(), String.t()) :: Medplum.result()
  def delete(%Client{} = client, id), do: Medplum.delete(client, @resource_type, id)

  @spec search(Client.t(), map()) :: Medplum.result()
  def search(%Client{} = client, params \\ %{}),
    do: Medplum.search(client, @resource_type, params)

  @spec search_by_entity(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_entity(%Client{} = client, entity, params \\ %{}) do
    search(client, Map.merge(params, %{"entity" => entity}))
  end

  @spec search_by_agent(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_agent(%Client{} = client, agent, params \\ %{}) do
    search(client, Map.merge(params, %{"agent" => agent}))
  end

  @spec search_by_date(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_date(%Client{} = client, date, params \\ %{}) do
    search(client, Map.merge(params, %{"date" => date}))
  end

  @spec search_by_type(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_type(%Client{} = client, type, params \\ %{}) do
    search(client, Map.merge(params, %{"type" => type}))
  end
end
