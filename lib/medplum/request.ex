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
    with {:ok, token} <- Auth.token(client) do
      # Fetch a fresh token before building the authenticated FHIR request.
      url = build_url(client, path)

      request_opts =
        client.req_options
        |> Keyword.merge(opts)
        |> Keyword.drop([:async, :response_mode])
        |> Keyword.put(:method, method)
        |> Keyword.put(:url, url)
        |> Keyword.put(:auth, {:bearer, token})
        |> Keyword.put(:headers, merge_headers(client, Keyword.get(opts, :headers, [])))
        |> Keyword.put_new(:retry, client.retry)
        |> Keyword.put_new(:max_retries, client.max_retries)

      Req.request(request_opts)
      |> normalize_response(opts)
    end
  end

  defp build_url(%Client{} = client, path) do
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
        {:error, Error.new(:api_error, status: response.status, body: response.body)}
    end
  end

  defp normalize_response({:ok, %{status: status, body: body}}, _request_opts) do
    if status in 200..299 do
      cond do
        is_map(body) -> {:ok, body}
        body in [nil, ""] -> {:ok, %{}}
        true -> {:error, Error.new(:invalid_response, body: body)}
      end
    else
      {:error, Error.new(:api_error, status: status, body: body)}
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

  defp merge_headers(%Client{} = client, request_headers) do
    [{"accept", "application/fhir+json"}, {"content-type", "application/fhir+json"}]
    |> Kernel.++(Keyword.get(client.req_options, :headers, []))
    |> Kernel.++(client.default_headers)
    |> Kernel.++(request_headers)
    |> Enum.reduce(%{}, fn {name, value}, headers ->
      Map.put(headers, String.downcase(name), value)
    end)
    |> Enum.to_list()
  end
end
