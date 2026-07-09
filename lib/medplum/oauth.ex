defmodule Medplum.OAuth do
  @moduledoc """
  OAuth helpers for Medplum authorization-code and OpenID Connect flows.
  """

  alias Medplum.Client
  alias Medplum.Request

  @doc """
  Builds a Medplum OAuth authorize URL.
  """
  @spec authorize_url(Client.t() | keyword() | map(), keyword() | map()) :: String.t()
  def authorize_url(client_or_opts, params) do
    client = ensure_client(client_or_opts)
    params = normalize_params(params)

    query =
      %{
        "client_id" => client.client_id,
        "redirect_uri" => fetch_required_param!(params, "redirect_uri"),
        "response_type" => "code",
        "scope" => fetch_required_param!(params, "scope"),
        "state" => fetch_required_param!(params, "state")
      }
      |> Map.merge(Map.drop(params, ["redirect_uri", "scope", "state", "response_type"]))
      |> URI.encode_query()

    "#{client.base_url}/oauth2/authorize?#{query}"
  end

  @doc """
  Exchanges an authorization code for a Medplum token response.
  """
  @spec exchange_authorization_code(Client.t() | keyword() | map(), String.t(), keyword() | map()) ::
          {:ok, map()} | {:error, Medplum.Error.t()}
  def exchange_authorization_code(client_or_opts, code, opts \\ []) when is_binary(code) do
    client = ensure_client(client_or_opts)
    opts = normalize_params(opts)

    form =
      %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => fetch_required_param!(opts, "redirect_uri"),
        "client_id" => client.client_id,
        "client_secret" => client.client_secret
      }
      |> Map.merge(Map.drop(opts, ["redirect_uri"]))

    Request.api_request(client, :post, "/oauth2/token",
      auth: :none,
      error_type: :auth_failed,
      form: form
    )
  end

  @doc """
  Fetches OpenID Connect userinfo from `/oauth2/userinfo`.
  """
  @spec userinfo(Client.t(), keyword()) :: {:ok, map()} | {:error, Medplum.Error.t()}
  def userinfo(%Client{} = client, opts \\ []) do
    Request.api_request(client, :get, "/oauth2/userinfo",
      error_type: :auth_failed,
      headers: [{"accept", "application/json"}] ++ Keyword.get(opts, :headers, [])
    )
  end

  defp ensure_client(%Client{} = client), do: client
  defp ensure_client(opts), do: Client.new(opts)

  defp normalize_params(params) when is_map(params),
    do: Map.new(params, fn {k, v} -> {to_string(k), v} end)

  defp normalize_params(params) when is_list(params),
    do: params |> Enum.into(%{}) |> normalize_params()

  defp fetch_required_param!(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} when is_binary(value) and value != "" -> value
      _other -> raise ArgumentError, "#{inspect(key)} must be a non-empty string"
    end
  end
end
