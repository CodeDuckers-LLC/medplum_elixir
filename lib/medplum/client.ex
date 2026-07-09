defmodule Medplum.Client do
  @moduledoc """
  Client configuration shared by Medplum API requests.
  """

  @enforce_keys [:base_url]
  @allowed_keys [
    :access_token,
    :auth_req_options,
    :auth_mode,
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
    :access_token,
    fhir_version: "R4",
    default_headers: [],
    req_options: [],
    auth_req_options: [],
    auth_mode: :client_credentials,
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
          access_token: access_token(),
          fhir_version: fhir_version(),
          default_headers: headers(),
          req_options: req_options(),
          auth_req_options: req_options(),
          auth_mode: auth_mode(),
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

  @typedoc "Bearer token used directly for authenticated requests."
  @type access_token :: String.t() | nil

  @typedoc "FHIR version segment used in request paths. Defaults to `\"R4\"`."
  @type fhir_version :: String.t()

  @typedoc "Default headers merged into every FHIR request."
  @type headers :: [{String.t(), String.t()}]

  @typedoc "Extra `Req` options forwarded to outgoing requests."
  @type req_options :: keyword()

  @typedoc "Retry strategy passed through to `Req`."
  @type retry :: false | :safe_transient | :transient

  @typedoc "Authentication strategy used to authorize requests."
  @type auth_mode :: :client_credentials | :access_token

  @doc """
  Builds a Medplum client.

  The `base_url` value is normalized by trimming a trailing slash, and
  `fhir_version` defaults to `"R4"` when it is not provided.

  By default the client uses the OAuth client credentials grant. When
  `access_token` is provided, the client switches to direct bearer-token mode
  unless `auth_mode` is set explicitly.
  """
  @spec new(keyword() | map()) :: t()
  def new(opts), do: build(opts)

  @doc """
  Builds a Medplum client and raises on invalid configuration.
  """
  @spec new!(keyword() | map()) :: t()
  def new!(opts), do: build(opts)

  @doc """
  Builds a Medplum client that uses an existing bearer token directly.
  """
  @spec new_with_access_token(keyword() | map(), String.t()) :: t()
  def new_with_access_token(opts, access_token) when is_binary(access_token) do
    opts
    |> normalize_opts()
    |> Keyword.put(:access_token, access_token)
    |> Keyword.put(:auth_mode, :access_token)
    |> build()
  end

  defp build(opts) when is_map(opts), do: opts |> normalize_opts() |> build()

  defp build(opts) when is_list(opts) do
    validate_keys!(opts)

    base_url =
      opts
      |> fetch_string!(:base_url)
      |> String.trim_trailing("/")

    auth_mode = fetch_auth_mode(opts)

    %__MODULE__{
      base_url: base_url,
      client_id: fetch_optional_string(opts, :client_id, ""),
      client_secret: fetch_optional_string(opts, :client_secret, ""),
      access_token: fetch_optional_string(opts, :access_token, nil),
      fhir_version: fetch_string(opts, :fhir_version, "R4"),
      default_headers: fetch_headers(opts),
      req_options: fetch_keyword(opts, :req_options),
      auth_req_options: fetch_keyword(opts, :auth_req_options),
      auth_mode: auth_mode,
      retry: fetch_retry(opts),
      max_retries: fetch_non_neg_integer(opts, :max_retries, 2),
      token_refresh_skew: fetch_non_neg_integer(opts, :token_refresh_skew, 60),
      cache_tokens: fetch_boolean(opts, :cache_tokens, true)
    }
    |> validate_auth_config!()
  end

  defp build(_opts) do
    raise ArgumentError, "Medplum client config must be keyword list or map"
  end

  defp normalize_opts(opts) when is_map(opts), do: Enum.into(opts, [])
  defp normalize_opts(opts) when is_list(opts), do: opts

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

  defp fetch_optional_string(opts, key, default) do
    case Keyword.get(opts, key, default) do
      nil -> nil
      value -> ensure_string!(value, key)
    end
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

  defp fetch_auth_mode(opts) do
    auth_mode =
      case Keyword.fetch(opts, :auth_mode) do
        {:ok, value} ->
          value

        :error ->
          if Keyword.has_key?(opts, :access_token), do: :access_token, else: :client_credentials
      end

    if auth_mode in [:client_credentials, :access_token] do
      auth_mode
    else
      raise ArgumentError, ":auth_mode must be :client_credentials or :access_token"
    end
  end

  defp validate_auth_config!(%__MODULE__{auth_mode: :client_credentials} = client) do
    if client.client_id == "" do
      raise ArgumentError, ":client_id must be a string"
    end

    if client.client_secret == "" do
      raise ArgumentError, ":client_secret must be a string"
    end

    client
  end

  defp validate_auth_config!(
         %__MODULE__{auth_mode: :access_token, access_token: access_token} = client
       )
       when is_binary(access_token) and access_token != "" do
    client
  end

  defp validate_auth_config!(%__MODULE__{auth_mode: :access_token}) do
    raise ArgumentError,
          ":access_token must be a non-empty string when auth_mode is :access_token"
  end
end
