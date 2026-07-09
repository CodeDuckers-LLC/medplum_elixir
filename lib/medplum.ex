defmodule Medplum do
  @moduledoc """
  Concise client for Medplum's FHIR API and OAuth flows.

  Build a `Medplum.Client`, then pass it to the resource helpers in this module for
  authenticated FHIR requests. Public operations return `{:ok, map()}` for decoded
  response bodies or `{:error, %Medplum.Error{}}` for transport, auth, or API failures.

  Clients can either reuse cached client-credentials tokens or use an existing bearer
  token directly. The module exposes resource helpers, OAuth helpers, and lower-level
  request functions for unsupported endpoints.

  ## Example

      client =
        Medplum.new(
          base_url: "https://api.medplum.com",
          client_id: System.fetch_env!("MEDPLUM_CLIENT_ID"),
          client_secret: System.fetch_env!("MEDPLUM_CLIENT_SECRET")
        )

      {:ok, patient} = Medplum.read(client, "Patient", "123")

      {:ok, patients} = Medplum.search(client, "Patient", %{"family" => "Smith"})
  """

  alias Medplum.Client
  alias Medplum.Error
  alias Medplum.OAuth
  alias Medplum.Request

  @type client :: Client.t()
  @type result :: {:ok, map()} | {:error, Error.t()}
  @type async_result :: %{
          required(String.t()) => term(),
          optional(String.t()) => term()
        }
  @type binary_result :: %{
          body: binary(),
          content_type: String.t() | nil,
          headers: [{String.t(), String.t()}]
        }

  @doc """
  Builds a reusable Medplum client from base URL and client credentials.
  """
  @spec new(keyword() | map()) :: Client.t()
  def new(opts), do: Client.new(opts)

  @doc """
  Builds a reusable Medplum client and raises on invalid configuration.
  """
  @spec new!(keyword() | map()) :: Client.t()
  def new!(opts), do: Client.new!(opts)

  @doc """
  Builds a reusable Medplum client that authenticates with an existing bearer token.
  """
  @spec new_with_access_token(keyword() | map(), String.t()) :: Client.t()
  def new_with_access_token(opts, access_token),
    do: Client.new_with_access_token(opts, access_token)

  @doc """
  Builds a Medplum OAuth authorize URL for authorization-code flows.
  """
  @spec authorize_url(Client.t() | keyword() | map(), keyword() | map()) :: String.t()
  def authorize_url(client_or_opts, params), do: OAuth.authorize_url(client_or_opts, params)

  @doc """
  Exchanges an authorization code for a Medplum OAuth token response.
  """
  @spec exchange_authorization_code(Client.t() | keyword() | map(), String.t(), keyword() | map()) ::
          result()
  def exchange_authorization_code(client_or_opts, code, opts \\ []),
    do: OAuth.exchange_authorization_code(client_or_opts, code, opts)

  @doc """
  Fetches OpenID Connect userinfo from `/oauth2/userinfo`.
  """
  @spec userinfo(Client.t(), keyword()) :: result()
  def userinfo(%Client{} = client, opts \\ []), do: OAuth.userinfo(client, opts)

  @doc """
  Fetches one FHIR resource by resource type and id.
  """
  @spec read(Client.t(), String.t(), String.t()) :: result()
  def read(%Client{} = client, resource_type, id) do
    Request.request(client, :get, "/#{resource_type}/#{id}")
  end

  @doc """
  Searches a FHIR resource type with query parameters encoded from the given map.
  """
  @spec search(Client.t(), String.t(), map()) :: result()
  def search(%Client{} = client, resource_type, params \\ %{}) do
    Request.request(client, :get, "/#{resource_type}", params: params)
  end

  @doc """
  Creates a FHIR resource and fills in `"resourceType"` when it is omitted.
  """
  @spec create(Client.t(), String.t(), map()) :: result()
  def create(%Client{} = client, resource_type, attrs) when is_map(attrs) do
    body = Map.put_new(attrs, "resourceType", resource_type)

    Request.request(client, :post, "/#{resource_type}", json: body)
  end

  @doc """
  Replaces a FHIR resource by type and id, forcing the outgoing body to match both.
  """
  @spec update(Client.t(), String.t(), String.t(), map()) :: result()
  def update(%Client{} = client, resource_type, id, attrs) when is_map(attrs) do
    body =
      attrs
      |> Map.put("id", id)
      |> Map.put_new("resourceType", resource_type)

    Request.request(client, :put, "/#{resource_type}/#{id}", json: body)
  end

  @doc """
  Deletes a FHIR resource by resource type and id.
  """
  @spec delete(Client.t(), String.t(), String.t()) :: result()
  def delete(%Client{} = client, resource_type, id) do
    Request.request(client, :delete, "/#{resource_type}/#{id}")
  end

  @doc """
  Sends an authenticated request to any FHIR-relative path or absolute Medplum URL.
  """
  @spec request(Client.t(), atom(), String.t(), keyword()) :: result()
  def request(%Client{} = client, method, path, opts \\ []) do
    Request.request(client, method, path, opts)
  end

  @doc """
  Sends an authenticated request to a non-FHIR Medplum path relative to `base_url`.
  """
  @spec api_request(Client.t(), atom(), String.t(), keyword()) :: result()
  def api_request(%Client{} = client, method, path, opts \\ []) do
    Request.api_request(client, method, path, opts)
  end

  @doc """
  Applies a JSON Patch document to a resource by type and id.
  """
  @spec patch(Client.t(), String.t(), String.t(), list(map())) :: result()
  def patch(%Client{} = client, resource_type, id, operations) when is_list(operations) do
    Request.request(
      client,
      :patch,
      "/#{resource_type}/#{id}",
      body: Jason.encode!(operations),
      headers: [{"content-type", "application/json-patch+json"}]
    )
  end

  @doc """
  Invokes a FHIR operation on the system, type, or instance level.
  """
  @spec operation(
          Client.t(),
          :system | String.t() | {String.t(), String.t()},
          String.t(),
          map(),
          keyword()
        ) ::
          result() | {:ok, async_result()}
  def operation(%Client{} = client, target, operation_name, params \\ %{}, opts \\ [])
      when is_map(params) do
    {method, request_opts} = operation_request_opts(params, opts)
    path = operation_path(target, operation_name)

    Request.request(client, method, path, request_opts)
  end

  @doc """
  Polls an async status URL until a final response is available.
  """
  @spec poll_async(Client.t(), String.t(), keyword()) :: result() | {:ok, async_result()}
  def poll_async(%Client{} = client, status_url_or_path, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1_000)
    max_attempts = Keyword.get(opts, :max_attempts, 30)

    do_poll_async(client, status_url_or_path, interval, max_attempts)
  end

  @doc """
  Executes a FHIR batch bundle against the base endpoint.
  """
  @spec batch(Client.t(), list(map()) | map()) :: result() | {:ok, async_result()}
  def batch(%Client{} = client, entries_or_bundle) do
    bundle = build_bundle(entries_or_bundle, "batch")
    Request.request(client, :post, "/", json: bundle)
  end

  @doc """
  Executes a FHIR transaction bundle against the base endpoint.
  """
  @spec transaction(Client.t(), list(map()) | map()) :: result() | {:ok, async_result()}
  def transaction(%Client{} = client, entries_or_bundle) do
    bundle = build_bundle(entries_or_bundle, "transaction")
    Request.request(client, :post, "/", json: bundle)
  end

  @doc """
  Uploads raw bytes to the Binary endpoint.
  """
  @spec create_binary(Client.t(), binary(), keyword()) :: result()
  def create_binary(%Client{} = client, data, opts) when is_binary(data) and is_list(opts) do
    content_type = Keyword.fetch!(opts, :content_type)
    extra_headers = Keyword.get(opts, :headers, [])

    headers =
      [{"content-type", content_type}]
      |> maybe_put_security_context(Keyword.get(opts, :security_context))
      |> maybe_put_filename(Keyword.get(opts, :filename))
      |> Kernel.++(extra_headers)

    Request.request(client, :post, "/Binary", body: data, headers: headers)
  end

  @doc """
  Downloads raw bytes from a Binary resource.
  """
  @spec get_binary(Client.t(), String.t()) :: {:ok, binary_result()} | {:error, Error.t()}
  def get_binary(%Client{} = client, id_or_url) when is_binary(id_or_url) do
    path = if absolute_url?(id_or_url), do: id_or_url, else: "/Binary/#{id_or_url}"

    Request.request(client, :get, path,
      headers: [{"accept", "*/*"}],
      response_mode: :raw,
      decode_body: false
    )
  end

  @doc """
  Performs an official Medplum conditional upsert using a query embedded in attrs.
  """
  @spec upsert(Client.t(), String.t(), map()) :: result()
  def upsert(%Client{} = client, resource_type, attrs) when is_map(attrs) do
    body = attrs |> Map.put_new("resourceType", resource_type)
    ensure_resource_type!(body, resource_type)

    {query, body} = extract_upsert_query!(body)
    Request.request(client, :put, "/#{resource_type}?#{query}", json: body)
  end

  @doc """
  Sends a GraphQL request to the FHIR GraphQL endpoint.
  """
  @spec graphql(Client.t(), String.t(), keyword()) :: result()
  def graphql(%Client{} = client, query, opts \\ []) when is_binary(query) do
    payload =
      %{"query" => query}
      |> maybe_put_graphql_field("variables", Keyword.get(opts, :variables))
      |> maybe_put_graphql_field("operationName", Keyword.get(opts, :operation_name))

    Request.request(
      client,
      :post,
      "/$graphql",
      json: payload,
      headers: [{"accept", "application/json"}, {"content-type", "application/json"}]
    )
  end

  @doc """
  Streams Bundle entries across paginated search results.

  The stream yields each Bundle `entry` map and raises `Medplum.Error` if a later page fails.
  """
  @spec stream_search(Client.t(), String.t(), map()) :: Enumerable.t()
  def stream_search(%Client{} = client, resource_type, params \\ %{}) do
    Stream.resource(
      fn -> {:path, "/#{resource_type}", params} end,
      fn
        nil ->
          {:halt, nil}

        {:path, path, params} ->
          case Request.request(client, :get, path, params: params) do
            {:ok, bundle} ->
              {bundle_entries(bundle), next_state(bundle)}

            {:error, error} ->
              raise error
          end

        {:url, url} ->
          case Request.request(client, :get, url) do
            {:ok, bundle} ->
              {bundle_entries(bundle), next_state(bundle)}

            {:error, error} ->
              raise error
          end
      end,
      fn _state -> :ok end
    )
  end

  defp bundle_entries(%{"entry" => entries}) when is_list(entries), do: entries
  defp bundle_entries(_bundle), do: []

  defp next_state(%{"link" => links}) when is_list(links) do
    case Enum.find(links, &match?(%{"relation" => "next"}, &1)) do
      %{"url" => url} when is_binary(url) -> {:url, url}
      _other -> nil
    end
  end

  defp next_state(_bundle), do: nil

  defp operation_request_opts(params, opts) do
    method =
      Keyword.get_lazy(opts, :method, fn ->
        if map_size(params) == 0, do: :get, else: :post
      end)

    request_opts =
      opts
      |> Keyword.delete(:method)
      |> Keyword.update(:headers, [], fn headers -> headers end)
      |> maybe_add_async_preference()
      |> maybe_put_operation_body(method, params)

    {method, request_opts}
  end

  defp operation_path(:system, operation_name), do: "/#{normalize_operation_name(operation_name)}"

  defp operation_path(resource_type, operation_name) when is_binary(resource_type),
    do: "/#{resource_type}/#{normalize_operation_name(operation_name)}"

  defp operation_path({resource_type, id}, operation_name)
       when is_binary(resource_type) and is_binary(id) do
    "/#{resource_type}/#{id}/#{normalize_operation_name(operation_name)}"
  end

  defp normalize_operation_name("$" <> _rest = operation_name), do: operation_name
  defp normalize_operation_name(operation_name), do: "$" <> operation_name

  defp do_poll_async(_client, _status_url_or_path, _interval, 0) do
    {:error, Error.new(:request_failed, reason: :max_attempts_exceeded)}
  end

  defp do_poll_async(client, status_url_or_path, interval, attempts_left) do
    case Request.request(client, :get, status_url_or_path) do
      {:ok, %{"statusUrl" => next_url}} ->
        Process.sleep(interval)
        do_poll_async(client, next_url, interval, attempts_left - 1)

      {:ok, %{"resourceType" => "AsyncJob", "status" => status} = job}
      when status in ["accepted", "queued", "running", "in-progress"] ->
        Process.sleep(interval)
        job_url = Map.get(job, "url", status_url_or_path)
        do_poll_async(client, job_url, interval, attempts_left - 1)

      other ->
        other
    end
  end

  defp build_bundle(entries, type) when is_list(entries) do
    %{"resourceType" => "Bundle", "type" => type, "entry" => entries}
  end

  defp build_bundle(%{"resourceType" => "Bundle"} = bundle, _type), do: bundle

  defp build_bundle(bundle, _type) when is_map(bundle) do
    bundle
  end

  defp maybe_put_security_context(headers, nil), do: headers

  defp maybe_put_security_context(headers, security_context),
    do: headers ++ [{"x-security-context", security_context}]

  defp maybe_put_filename(headers, nil), do: headers

  defp maybe_put_filename(headers, filename) do
    headers ++ [{"content-disposition", ~s(attachment; filename="#{filename}")}]
  end

  defp absolute_url?(url) do
    String.starts_with?(url, "http://") or String.starts_with?(url, "https://")
  end

  defp ensure_resource_type!(%{"resourceType" => actual}, resource_type)
       when actual == resource_type,
       do: :ok

  defp ensure_resource_type!(%{"resourceType" => actual}, resource_type) do
    raise ArgumentError,
          ~s(attrs["resourceType"] must match #{inspect(resource_type)}, got #{inspect(actual)})
  end

  defp extract_upsert_query!(attrs) do
    cond do
      is_binary(attrs["_search"]) ->
        {attrs["_search"], Map.delete(attrs, "_search")}

      is_map(attrs["_search"]) ->
        {URI.encode_query(attrs["_search"]), Map.delete(attrs, "_search")}

      true ->
        raise ArgumentError,
              ~s(upsert/3 requires attrs["_search"] as a query string or map for Medplum conditional PUT)
    end
  end

  defp maybe_put_graphql_field(payload, _key, nil), do: payload
  defp maybe_put_graphql_field(payload, key, value), do: Map.put(payload, key, value)

  defp maybe_add_async_preference(opts) do
    if Keyword.get(opts, :async, false) do
      headers = Keyword.get(opts, :headers, [])
      Keyword.put(opts, :headers, headers ++ [{"prefer", "respond-async"}])
    else
      opts
    end
  end

  defp maybe_put_operation_body(opts, :get, _params), do: opts

  defp maybe_put_operation_body(opts, _method, params) do
    if Keyword.has_key?(opts, :json) or Keyword.has_key?(opts, :body) do
      opts
    else
      Keyword.put(opts, :json, params)
    end
  end
end
