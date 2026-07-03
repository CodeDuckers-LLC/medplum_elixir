defmodule Medplum.Client do
  @moduledoc """
  Client configuration shared by Medplum API requests.
  """

  @enforce_keys [:base_url, :client_id, :client_secret]
  @allowed_keys [
    :auth_req_options,
    :base_url,
    :cache_tokens,
    :client_id,
    :client_secret,
    :default_headers,
    :fhir_version,
    :max_retries,
    :req_options,
    :retry,
    :token_refresh_skew
  ]

  defstruct [
    :base_url,
    :client_id,
    :client_secret,
    fhir_version: "R4",
    default_headers: [],
    req_options: [],
    auth_req_options: [],
    retry: :transient,
    max_retries: 2,
    token_refresh_skew: 60,
    cache_tokens: true
  ]

  @typedoc "Client state used to authenticate requests and build FHIR URLs."
  @type t :: %__MODULE__{
          base_url: base_url(),
          client_id: client_id(),
          client_secret: client_secret(),
          fhir_version: fhir_version(),
          default_headers: headers(),
          req_options: req_options(),
          auth_req_options: req_options(),
          retry: retry(),
          max_retries: non_neg_integer(),
          token_refresh_skew: non_neg_integer(),
          cache_tokens: boolean()
        }

  @typedoc "Base Medplum URL without a trailing slash."
  @type base_url :: String.t()

  @typedoc "OAuth client id used for the client credentials grant."
  @type client_id :: String.t()

  @typedoc "OAuth client secret paired with the client id."
  @type client_secret :: String.t()

  @typedoc "FHIR version segment used in request paths. Defaults to `\"R4\"`."
  @type fhir_version :: String.t()

  @typedoc "Default headers merged into every FHIR request."
  @type headers :: [{String.t(), String.t()}]

  @typedoc "Extra `Req` options forwarded to outgoing requests."
  @type req_options :: keyword()

  @typedoc "Retry strategy passed through to `Req`."
  @type retry :: false | :safe_transient | :transient

  @doc """
  Builds a Medplum client.

  The `base_url` value is normalized by trimming a trailing slash, and
  `fhir_version` defaults to `"R4"` when it is not provided.
  """
  @spec new(keyword() | map()) :: t()
  def new(opts), do: build(opts)

  @doc """
  Builds a Medplum client and raises on invalid configuration.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(opts), do: build(opts)

  defp build(opts) when is_map(opts), do: opts |> Enum.into([]) |> build()

  defp build(opts) when is_list(opts) do
    validate_keys!(opts)

    base_url =
      opts
      |> fetch_string!(:base_url)
      |> String.trim_trailing("/")

    %__MODULE__{
      base_url: base_url,
      client_id: fetch_string!(opts, :client_id),
      client_secret: fetch_string!(opts, :client_secret),
      fhir_version: fetch_string(opts, :fhir_version, "R4"),
      default_headers: fetch_headers(opts),
      req_options: fetch_keyword(opts, :req_options),
      auth_req_options: fetch_keyword(opts, :auth_req_options),
      retry: fetch_retry(opts),
      max_retries: fetch_non_neg_integer(opts, :max_retries, 2),
      token_refresh_skew: fetch_non_neg_integer(opts, :token_refresh_skew, 60),
      cache_tokens: fetch_boolean(opts, :cache_tokens, true)
    }
  end

  defp build(_opts) do
    raise ArgumentError, "Medplum client config must be keyword list or map"
  end

  defp validate_keys!(opts) do
    invalid_keys = Keyword.keys(opts) -- @allowed_keys

    if invalid_keys != [] do
      raise ArgumentError,
            "unsupported Medplum client options: #{Enum.map_join(invalid_keys, ", ", &inspect/1)}"
    end
  end

  defp fetch_string!(opts, key) do
    opts
    |> Keyword.fetch!(key)
    |> ensure_string!(key)
  end

  defp fetch_string(opts, key, default) do
    opts
    |> Keyword.get(key, default)
    |> ensure_string!(key)
  end

  defp fetch_headers(opts) do
    opts
    |> Keyword.get(:default_headers, [])
    |> ensure_headers!()
  end

  defp fetch_keyword(opts, key) do
    value = Keyword.get(opts, key, [])

    if Keyword.keyword?(value) do
      value
    else
      raise ArgumentError, "#{inspect(key)} must be a keyword list"
    end
  end

  defp fetch_retry(opts) do
    retry = Keyword.get(opts, :retry, :transient)

    if retry in [false, :safe_transient, :transient] do
      retry
    else
      raise ArgumentError, ":retry must be false, :safe_transient, or :transient"
    end
  end

  defp fetch_non_neg_integer(opts, key, default) do
    value = Keyword.get(opts, key, default)

    if is_integer(value) and value >= 0 do
      value
    else
      raise ArgumentError, "#{inspect(key)} must be a non-negative integer"
    end
  end

  defp fetch_boolean(opts, key, default) do
    value = Keyword.get(opts, key, default)

    if is_boolean(value) do
      value
    else
      raise ArgumentError, "#{inspect(key)} must be a boolean"
    end
  end

  defp ensure_string!(value, _key) when is_binary(value), do: value

  defp ensure_string!(_value, key) do
    raise ArgumentError, "#{inspect(key)} must be a string"
  end

  defp ensure_headers!(headers) when is_list(headers) do
    Enum.map(headers, fn
      {name, value} when is_binary(name) and is_binary(value) -> {name, value}
      _other -> raise ArgumentError, ":default_headers must be a list of {binary, binary}"
    end)
  end

  defp ensure_headers!(_headers) do
    raise ArgumentError, ":default_headers must be a list of {binary, binary}"
  end
end
