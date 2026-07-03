defmodule Medplum.Resources.Bot do
  @moduledoc """
  Convenience helpers for Medplum `Bot` resource.

  ## Examples

      alias Medplum.Resources.Bot

      {:ok, bots} = Bot.search_by_name(client, "sync-bot")

      {:ok, result} =
        Bot.execute(client, "bot-123", %{
          "resourceType" => "Patient",
          "id" => "patient-123"
        })
  """

  alias Medplum.Client

  @resource_type "Bot"

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

  @spec search_by_name(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_name(%Client{} = client, name, params \\ %{}) do
    search(client, Map.merge(params, %{"name" => name}))
  end

  @spec search_by_status(Client.t(), String.t(), map()) :: Medplum.result()
  def search_by_status(%Client{} = client, status, params \\ %{}) do
    search(client, Map.merge(params, %{"status" => status}))
  end

  @spec execute(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def execute(%Client{} = client, id, input, opts \\ []) when is_map(input) do
    Medplum.operation(
      client,
      {@resource_type, id},
      "execute",
      input,
      Keyword.put_new(opts, :method, :post)
    )
  end

  @spec deploy(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def deploy(%Client{} = client, id, params \\ %{}, opts \\ []) when is_map(params) do
    Medplum.operation(
      client,
      {@resource_type, id},
      "deploy",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end
end
