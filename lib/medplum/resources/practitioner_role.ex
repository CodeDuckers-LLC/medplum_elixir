defmodule Medplum.Resources.PractitionerRole do
  @moduledoc """
  Convenience helpers for FHIR `PractitionerRole` resource.

  ## Examples

      alias Medplum.Resources.PractitionerRole

      {:ok, roles} = PractitionerRole.search_by_practitioner(client, "Practitioner/practitioner-123")
      {:ok, by_org} = PractitionerRole.search_by_organization(client, "Organization/org-123")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "PractitionerRole"

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

  @spec search_by_practitioner(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_practitioner(%Client{} = client, practitioner, params \\ %{}) do
    search(client, Map.merge(params, %{"practitioner" => practitioner}))
  end

  @spec search_by_organization(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_organization(%Client{} = client, organization, params \\ %{}) do
    search(client, Map.merge(params, %{"organization" => organization}))
  end

  @spec search_by_location(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_location(%Client{} = client, location, params \\ %{}) do
    search(client, Map.merge(params, %{"location" => location}))
  end
end
