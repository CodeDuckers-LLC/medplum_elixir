defmodule Medplum.Resources.Schedule do
  @moduledoc """
  Convenience helpers for FHIR `Schedule` resource.

  ## Examples

      alias Medplum.Resources.Schedule

      {:ok, schedules} = Schedule.search_by_actor(client, "Practitioner/practitioner-123")
      {:ok, by_service} = Schedule.search_by_service_type(client, "office-visit")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Schedule"

  @spec get(Client.t(), String.t()) :: Medplum.result()
  def get(%Client{} = client, id), do: Medplum.read(client, @resource_type, id)

  @spec create(Client.t(), map()) :: Medplum.result()
  def create(%Client{} = client, attrs), do: Medplum.create(client, @resource_type, attrs)

  @spec upsert(Client.t(), map()) :: Medplum.result()
  def upsert(%Client{} = client, attrs),
    do: ResourceUpsert.upsert_from_first_identifier(client, @resource_type, attrs)

  @spec upsert_by_identifier(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def upsert_by_identifier(%Client{} = client, system, value, attrs) do
    ResourceUpsert.upsert_by_identifier(client, @resource_type, system, value, attrs)
  end

  @spec update(Client.t(), String.t(), map()) :: Medplum.result()
  def update(%Client{} = client, id, attrs), do: Medplum.update(client, @resource_type, id, attrs)

  @spec delete(Client.t(), String.t()) :: Medplum.result()
  def delete(%Client{} = client, id), do: Medplum.delete(client, @resource_type, id)

  @spec search(Client.t(), map()) :: Medplum.result()
  def search(%Client{} = client, params \\ %{}),
    do: Medplum.search(client, @resource_type, params)

  @spec search_by_actor(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_actor(%Client{} = client, actor, params \\ %{}) do
    search(client, Map.merge(params, %{"actor" => actor}))
  end

  @spec search_by_service_type(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_service_type(%Client{} = client, service_type, params \\ %{}) do
    search(client, Map.merge(params, %{"service-type" => service_type}))
  end
end
