defmodule Medplum.Resources.Account do
  @moduledoc """
  Convenience helpers for FHIR `Account` resource.

  ## Examples

      alias Medplum.Resources.Account

      {:ok, accounts} = Account.search_by_patient(client, "Patient/patient-123")
      {:ok, by_identifier} = Account.search_by_identifier(client, "http://hospital.example/account", "A-123")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Account"

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

  @spec search_by_identifier(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_identifier(%Client{} = client, system, value, params \\ %{}) do
    search(client, Map.merge(params, %{"identifier" => "#{system}|#{value}"}))
  end

  @spec search_by_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_subject(%Client{} = client, subject, params \\ %{}) do
    search(client, Map.merge(params, %{"subject" => subject}))
  end
end
