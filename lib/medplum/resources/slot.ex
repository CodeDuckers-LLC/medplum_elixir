defmodule Medplum.Resources.Slot do
  @moduledoc """
  Convenience helpers for FHIR `Slot` resource.

  ## Examples

      alias Medplum.Resources.Slot

      {:ok, slots} = Slot.search_by_schedule(client, "Schedule/schedule-123")
      {:ok, free} = Slot.search_by_status(client, "free")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Slot"

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

  @spec search_by_schedule(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_schedule(%Client{} = client, schedule, params \\ %{}) do
    search(client, Map.merge(params, %{"schedule" => schedule}))
  end

  @spec search_by_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_status(%Client{} = client, status, params \\ %{}) do
    search(client, Map.merge(params, %{"status" => status}))
  end

  @spec search_by_start(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_start(%Client{} = client, start, params \\ %{}) do
    search(client, Map.merge(params, %{"start" => start}))
  end
end
