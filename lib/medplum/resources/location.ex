defmodule Medplum.Resources.Location do
  @moduledoc """
  Convenience helpers for FHIR `Location` resource.

  ## Examples

      alias Medplum.Resources.Location

      {:ok, locations} = Location.search_by_name(client, "Main Clinic")
      {:ok, by_org} = Location.search_by_organization(client, "Organization/org-123")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Location"

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

  @spec search_by_organization(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_organization(%Client{} = client, organization, params \\ %{}) do
    search(client, Map.merge(params, %{"organization" => organization}))
  end
end
