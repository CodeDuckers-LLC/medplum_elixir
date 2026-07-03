defmodule Medplum.Resources.ChargeItemDefinition do
  @moduledoc """
  Convenience helpers for FHIR `ChargeItemDefinition` resource.

  ## Examples

      alias Medplum.Resources.ChargeItemDefinition

      {:ok, defs} =
        ChargeItemDefinition.search_by_url(
          client,
          "https://example.org/charge-definitions/office-visit"
        )

      {:ok, priced_charge} =
        ChargeItemDefinition.apply_definition(client, "charge-item-definition-123", %{
          "resourceType" => "Parameters",
          "parameter" => [
            %{"name" => "chargeItem", "valueReference" => %{"reference" => "ChargeItem/charge-123"}}
          ]
        })
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "ChargeItemDefinition"

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

  @spec search_by_url(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_url(%Client{} = client, url, params \\ %{}) do
    search(client, Map.merge(params, %{"url" => url}))
  end

  @spec search_by_identifier(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_identifier(%Client{} = client, system, value, params \\ %{}) do
    search(client, Map.merge(params, %{"identifier" => "#{system}|#{value}"}))
  end

  @spec apply_definition(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def apply_definition(%Client{} = client, id, params, opts \\ []) when is_map(params) do
    Medplum.operation(
      client,
      {@resource_type, id},
      "apply",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end
end
