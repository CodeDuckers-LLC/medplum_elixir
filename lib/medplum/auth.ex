defmodule Medplum.Auth do
  @moduledoc """
  Internal helper that exchanges Medplum client credentials for an access token.
  """

  alias Medplum.Client
  alias Medplum.Error
  alias Medplum.TokenCache

  @doc """
  Requests a bearer token for the given client using the client credentials grant.
  """
  @spec token(Client.t()) :: {:ok, String.t()} | {:error, Error.t()}
  def token(%Client{} = client) do
    case TokenCache.get(client) do
      {:ok, token} ->
        {:ok, token}

      :miss ->
        request_opts = Keyword.merge(client.req_options, client.auth_req_options)

        client
        |> token_url()
        |> Req.post(
          Keyword.merge(
            request_opts,
            form: %{
              "grant_type" => "client_credentials",
              "client_id" => client.client_id,
              "client_secret" => client.client_secret
            }
          )
        )
        |> handle_response(client)
    end
  end

  defp token_url(%Client{} = client), do: "#{client.base_url}/oauth2/token"

  defp handle_response(
         {:ok, %{status: 200, body: %{"access_token" => access_token} = body}},
         %Client{} = client
       ) do
    expires_at =
      case Map.get(body, "expires_in") do
        expires_in when is_integer(expires_in) and expires_in >= 0 ->
          System.system_time(:second) + expires_in

        _other ->
          nil
      end

    :ok = TokenCache.put(client, access_token, expires_at)
    {:ok, access_token}
  end

  defp handle_response({:ok, %{status: status, body: body}}, _client) do
    {:error, Error.new(:auth_failed, status: status, body: body)}
  end

  defp handle_response({:error, reason}, _client) do
    {:error, Error.new(:request_failed, reason: reason)}
  end
end
