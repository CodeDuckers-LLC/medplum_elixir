defmodule Medplum.Resources.Medication do
  @moduledoc """
  Convenience helpers for FHIR `Medication` resource.

  ## Examples

      alias Medplum.Resources.Medication

      {:ok, meds} = Medication.search_by_code(client, "http://www.nlm.nih.gov/research/umls/rxnorm", "860975")
      {:ok, by_status} = Medication.search_by_status(client, "active")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Medication"

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

  @spec search_by_code(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_code(%Client{} = client, system, code, params \\ %{}) do
    search(client, Map.merge(params, %{"code" => "#{system}|#{code}"}))
  end

  @spec search_by_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_status(%Client{} = client, status, params \\ %{}) do
    search(client, Map.merge(params, %{"status" => status}))
  end
end
