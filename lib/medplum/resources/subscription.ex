defmodule Medplum.Resources.Subscription do
  @moduledoc """
  Convenience helpers for FHIR `Subscription` resource.

  ## Examples

      alias Medplum.Resources.Subscription

      {:ok, subs} = Subscription.search_by_criteria(client, "Patient")
      {:ok, active} = Subscription.search_by_status(client, "active")
  """

  alias Medplum.Client

  @resource_type "Subscription"

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

  @spec search_by_criteria(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_criteria(%Client{} = client, criteria, params \\ %{}) do
    search(client, Map.merge(params, %{"criteria" => criteria}))
  end

  @spec search_by_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_status(%Client{} = client, status, params \\ %{}) do
    search(client, Map.merge(params, %{"status" => status}))
  end

  @spec search_by_channel_type(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_channel_type(%Client{} = client, channel_type, params \\ %{}) do
    search(client, Map.merge(params, %{"channel-type" => channel_type}))
  end
end
