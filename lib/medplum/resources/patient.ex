defmodule Medplum.Resources.Patient do
  @moduledoc """
  Convenience helpers for the FHIR `Patient` resource.

  ## Examples

      alias Medplum.Resources.Patient

      {:ok, patient} = Patient.get(client, "patient-123")
      {:ok, matches} = Patient.search_by_identifier(client, "http://hospital.example/mrn", "123")
      {:ok, everything} = Patient.everything(client, "patient-123")
  """

  alias Medplum.Client
  alias Medplum.ResourceUpsert

  @resource_type "Patient"

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

  @spec search_by_identifier(Client.t(), String.t(), String.t(), map()) :: Medplum.result()
  def search_by_identifier(%Client{} = client, system, value, params \\ %{}) do
    search(client, Map.merge(params, %{"identifier" => "#{system}|#{value}"}))
  end

  @spec search_by_name(Client.t(), String.t(), String.t() | nil, map()) :: Medplum.result()
  def search_by_name(%Client{} = client, family, given \\ nil, params \\ %{}) do
    params =
      params
      |> Map.put("family", family)
      |> maybe_put_param("given", given)

    search(client, params)
  end

  @spec everything(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def everything(%Client{} = client, id, params \\ %{}, opts \\ []) do
    Medplum.operation(client, {@resource_type, id}, "everything", params, opts)
  end

  defp maybe_put_param(params, _key, nil), do: params
  defp maybe_put_param(params, key, value), do: Map.put(params, key, value)
end
