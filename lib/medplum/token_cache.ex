defmodule Medplum.TokenCache do
  @moduledoc """
  Internal ETS-backed cache for OAuth tokens shared by Medplum clients.
  """

  alias Medplum.Client

  @table :medplum_token_cache

  @spec get(Client.t()) :: {:ok, String.t()} | :miss
  def get(%Client{cache_tokens: false}), do: :miss

  def get(%Client{} = client) do
    ensure_table()

    case :ets.lookup(@table, cache_key(client)) do
      [{_, token, expires_at}] ->
        if fresh?(expires_at, client.token_refresh_skew), do: {:ok, token}, else: :miss

      [] ->
        :miss
    end
  end

  @spec put(Client.t(), String.t(), integer() | nil) :: :ok
  def put(%Client{cache_tokens: false}, _token, _expires_at), do: :ok

  def put(%Client{} = client, token, expires_at) do
    ensure_table()
    true = :ets.insert(@table, {cache_key(client), token, expires_at})
    :ok
  end

  defp cache_key(%Client{} = client) do
    {client.base_url, client.client_id, :erlang.phash2(client.client_secret), client.fhir_version}
  end

  defp fresh?(nil, _skew), do: true

  defp fresh?(expires_at, skew) do
    System.system_time(:second) + skew < expires_at
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
        rescue
          ArgumentError -> :ok
        end

      _table ->
        :ok
    end

    :ok
  end
end
