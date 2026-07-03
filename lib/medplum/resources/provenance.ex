defmodule Medplum.Resources.Provenance do
  @moduledoc """
  Convenience helpers for FHIR `Provenance` resource.

  ## Examples

      alias Medplum.Resources.Provenance

      {:ok, audit_trail} = Provenance.search_by_target(client, "Patient/patient-123")
      {:ok, by_agent} = Provenance.search_by_agent(client, "Practitioner/practitioner-123")
  """

  alias Medplum.Client

  @resource_type "Provenance"

  @spec get(Client.t(), String.t()) :: Medplum.result()
  def get(%Client{} = client, id), do: Medplum.read(client, @resource_type, id)

  @spec create(Client.t(), map()) :: Medplum.result()
  def create(%Client{} = client, attrs), do: Medplum.create(client, @resource_type, attrs)

  @spec update(Client.t(), String.t(), map()) :: Medplum.result()
  def update(%Client{} = client, id, attrs), do: Medplum.update(client, @resource_type, id, attrs)

  @spec delete(Client.t(), String.t()) :: Medplum.result()
  def delete(%Client{} = client, id), do: Medplum.delete(client, @resource_type, id)

  @spec search(Client.t(), map()) :: Medplum.result()
  def search(%Client{} = client, params \\ %{}),
    do: Medplum.search(client, @resource_type, params)

  @spec search_by_target(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_target(%Client{} = client, target, params \\ %{}) do
    search(client, Map.merge(params, %{"target" => target}))
  end

  @spec search_by_agent(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_agent(%Client{} = client, agent, params \\ %{}) do
    search(client, Map.merge(params, %{"agent" => agent}))
  end

  @spec search_by_date(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_date(%Client{} = client, date, params \\ %{}) do
    search(client, Map.merge(params, %{"date" => date}))
  end
end
