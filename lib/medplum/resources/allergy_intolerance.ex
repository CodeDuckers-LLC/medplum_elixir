defmodule Medplum.Resources.AllergyIntolerance do
  @moduledoc """
  Convenience helpers for FHIR `AllergyIntolerance` resource.

  ## Examples

      alias Medplum.Resources.AllergyIntolerance

      {:ok, allergies} = AllergyIntolerance.search_by_patient(client, "Patient/patient-123")
      {:ok, active} = AllergyIntolerance.search_by_clinical_status(client, "active")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "AllergyIntolerance"

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

  @spec search_by_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_patient(%Client{} = client, patient, params \\ %{}) do
    search(client, Map.merge(params, %{"patient" => patient}))
  end

  @spec search_by_clinical_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_clinical_status(%Client{} = client, clinical_status, params \\ %{}) do
    search(client, Map.merge(params, %{"clinical-status" => clinical_status}))
  end

  @spec search_by_category(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_category(%Client{} = client, category, params \\ %{}) do
    search(client, Map.merge(params, %{"category" => category}))
  end

  @spec search_by_code(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_code(%Client{} = client, system, code, params \\ %{}) do
    search(client, Map.merge(params, %{"code" => "#{system}|#{code}"}))
  end
end
