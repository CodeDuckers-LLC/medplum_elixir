defmodule Medplum.Request do
  @moduledoc """
  Internal request layer that builds FHIR URLs, adds authentication, applies
  default headers, and normalizes HTTP responses.
  """

  alias Medplum.Auth
  alias Medplum.Client
  alias Medplum.Error

  @doc """
  Performs one authenticated request against the configured FHIR endpoint.
  """
  @spec request(Client.t(), atom(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def request(%Client{} = client, method, path, opts \\ []) do
    perform_request(client, method, path, opts, :fhir)
  end

  @doc """
  Performs one request against a non-FHIR Medplum endpoint relative to `base_url`.
  """
  @spec api_request(Client.t(), atom(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def api_request(%Client{} = client, method, path, opts \\ []) do
    perform_request(client, method, path, opts, :api)
  end

  defp perform_request(%Client{} = client, method, path, opts, endpoint_type) do
    with {:ok, auth} <- resolve_auth(client, Keyword.get(opts, :auth, :auto)) do
      url = build_url(client, path, endpoint_type)

      request_opts =
        client.req_options
        |> Keyword.merge(opts)
        |> Keyword.drop([:async, :auth, :response_mode, :error_type])
        |> Keyword.put(:method, method)
        |> Keyword.put(:url, url)
        |> maybe_put_auth(auth)
        |> Keyword.put(
          :headers,
          merge_headers(client, Keyword.get(opts, :headers, []), endpoint_type)
        )
        |> Keyword.put_new(:retry, client.retry)
        |> Keyword.put_new(:max_retries, client.max_retries)

      Req.request(request_opts)
      |> normalize_response(opts)
    end
  end

  defp build_url(%Client{} = client, path, :fhir) do
    cond do
      String.starts_with?(path, "http://") ->
        path

      String.starts_with?(path, "https://") ->
        path

      true ->
        path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

        # Assemble the canonical FHIR endpoint from the base URL, version, and path.
        "#{client.base_url}/fhir/#{client.fhir_version}#{path}"
    end
  end

  defp build_url(%Client{} = client, path, :api) do
    cond do
      String.starts_with?(path, "http://") ->
        path

      String.starts_with?(path, "https://") ->
        path

      true ->
        path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"
        "#{client.base_url}#{path}"
    end
  end

  defp normalize_response({:ok, %Req.Response{} = response}, request_opts) do
    cond do
      async_response?(response) ->
        {:ok,
         %{
           "status" => response.status,
           "statusUrl" => response_header(response, "content-location"),
           "headers" => response_headers(response)
         }}

      response.status in 200..299 ->
        normalize_success_body(response, Keyword.get(request_opts, :response_mode, :json))

      true ->
        {:error,
         Error.new(Keyword.get(request_opts, :error_type, :api_error),
           status: response.status,
           body: response.body
         )}
    end
  end

  defp normalize_response({:ok, %{status: status, body: body}}, request_opts) do
    if status in 200..299 do
      cond do
        is_map(body) -> {:ok, body}
        body in [nil, ""] -> {:ok, %{}}
        true -> {:error, Error.new(:invalid_response, body: body)}
      end
    else
      {:error,
       Error.new(Keyword.get(request_opts, :error_type, :api_error), status: status, body: body)}
    end
  end

  defp normalize_response({:error, reason}, _request_opts) do
    {:error, Error.new(:request_failed, reason: reason)}
  end

  defp normalize_success_body(%Req.Response{body: body}, :json) do
    cond do
      is_map(body) -> {:ok, body}
      body in [nil, ""] -> {:ok, %{}}
      true -> {:error, Error.new(:invalid_response, body: body)}
    end
  end

  defp normalize_success_body(%Req.Response{} = response, :raw) do
    {:ok,
     %{
       body: response.body,
       content_type: response_header(response, "content-type"),
       headers: response_headers(response)
     }}
  end

  defp async_response?(%Req.Response{status: 202} = response) do
    is_binary(response_header(response, "content-location"))
  end

  defp async_response?(_response), do: false

  defp response_header(%Req.Response{} = response, name) do
    case Req.Response.get_header(response, name) do
      [value | _rest] -> value
      [] -> nil
    end
  end

  defp response_headers(%Req.Response{} = response) do
    response
    |> Req.Response.to_map()
    |> Map.fetch!(:headers)
  end

  defp resolve_auth(%Client{} = client, :auto) do
    with {:ok, token} <- Auth.token(client) do
      {:ok, {:bearer, token}}
    end
  end

  defp resolve_auth(_client, :none), do: {:ok, nil}
  defp resolve_auth(_client, {:bearer, token}) when is_binary(token), do: {:ok, {:bearer, token}}

  defp maybe_put_auth(request_opts, nil), do: request_opts
  defp maybe_put_auth(request_opts, auth), do: Keyword.put(request_opts, :auth, auth)

  defp merge_headers(%Client{} = client, request_headers, :fhir) do
    [{"accept", "application/fhir+json"}, {"content-type", "application/fhir+json"}]
    |> Kernel.++(Keyword.get(client.req_options, :headers, []))
    |> Kernel.++(client.default_headers)
    |> Kernel.++(request_headers)
    |> Enum.reduce(%{}, fn {name, value}, headers ->
      Map.put(headers, String.downcase(name), value)
    end)
    |> Enum.to_list()
  end

  defp merge_headers(%Client{} = client, request_headers, :api) do
    []
    |> Kernel.++(Keyword.get(client.req_options, :headers, []))
    |> Kernel.++(client.default_headers)
    |> Kernel.++(request_headers)
    |> Enum.reduce(%{}, fn {name, value}, headers ->
      Map.put(headers, String.downcase(name), value)
    end)
    |> Enum.to_list()
  end
end
