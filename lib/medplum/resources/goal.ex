defmodule Medplum.Resources.Goal do
  @moduledoc """
  Convenience helpers for FHIR `Goal` resource.

  ## Examples

      alias Medplum.Resources.Goal

      {:ok, goals} = Goal.search_by_subject(client, "Patient/patient-123")
      {:ok, active} = Goal.search_by_lifecycle_status(client, "active")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Goal"

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

  @spec search_by_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_subject(%Client{} = client, subject, params \\ %{}) do
    search(client, Map.merge(params, %{"subject" => subject}))
  end

  @spec search_by_lifecycle_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_lifecycle_status(%Client{} = client, lifecycle_status, params \\ %{}) do
    search(client, Map.merge(params, %{"lifecycle-status" => lifecycle_status}))
  end

  @spec search_by_target_date(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_target_date(%Client{} = client, target_date, params \\ %{}) do
    search(client, Map.merge(params, %{"target-date" => target_date}))
  end
end
