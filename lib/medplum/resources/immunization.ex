defmodule Medplum.Resources.Immunization do
  @moduledoc """
  Convenience helpers for FHIR `Immunization` resource.

  ## Examples

      alias Medplum.Resources.Immunization

      {:ok, shots} = Immunization.search_by_patient(client, "Patient/patient-123")
      {:ok, covid} = Immunization.search_by_vaccine_code(client, "http://hl7.org/fhir/sid/cvx", "207")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Immunization"

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

  @spec search_by_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_status(%Client{} = client, status, params \\ %{}) do
    search(client, Map.merge(params, %{"status" => status}))
  end

  @spec search_by_date(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_date(%Client{} = client, date, params \\ %{}) do
    search(client, Map.merge(params, %{"date" => date}))
  end

  @spec search_by_vaccine_code(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_vaccine_code(%Client{} = client, system, code, params \\ %{}) do
    search(client, Map.merge(params, %{"vaccine-code" => "#{system}|#{code}"}))
  end
end
