defmodule Medplum.Resources.HealthcareService do
  @moduledoc """
  Convenience helpers for FHIR `HealthcareService` resource.

  ## Examples

      alias Medplum.Resources.HealthcareService

      {:ok, services} = HealthcareService.search_by_name(client, "Office Visit")
      {:ok, by_identifier} = HealthcareService.search_by_identifier(client, "http://svc.example", "office-visit")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "HealthcareService"

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

  @spec search_by_name(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_name(%Client{} = client, name, params \\ %{}) do
    search(client, Map.merge(params, %{"name" => name}))
  end

  @spec search_by_identifier(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_identifier(%Client{} = client, system, value, params \\ %{}) do
    search(client, Map.merge(params, %{"identifier" => "#{system}|#{value}"}))
  end
end
