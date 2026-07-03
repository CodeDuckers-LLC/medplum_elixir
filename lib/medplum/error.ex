defmodule Medplum.Error do
  @moduledoc """
  Stable error shape returned by Medplum requests.
  """

  defexception [:message, :type, :status, :body, :reason]

  @typedoc "Error categories returned by configuration, auth, transport, and API failures."
  @type type ::
          :config_error
          | :auth_failed
          | :request_failed
          | :api_error
          | :invalid_response

  @typedoc "Structured error returned by Medplum operations."
  @type t :: %__MODULE__{
          message: String.t(),
          type: type(),
          status: non_neg_integer() | nil,
          body: term() | nil,
          reason: term() | nil
        }

  @doc """
  Builds a new error struct with a generated message.
  """
  @spec new(type(), keyword()) :: t()
  def new(type, attrs \\ []) do
    attrs = Keyword.put_new(attrs, :message, default_message(type, attrs))
    struct!(__MODULE__, [{:type, type} | attrs])
  end

  defp default_message(:config_error, attrs) do
    "invalid Medplum client config: #{Keyword.fetch!(attrs, :reason)}"
  end

  defp default_message(:auth_failed, attrs) do
    "Medplum auth failed with status #{Keyword.fetch!(attrs, :status)}"
  end

  defp default_message(:request_failed, attrs) do
    "Medplum request failed: #{inspect(Keyword.fetch!(attrs, :reason))}"
  end

  defp default_message(:api_error, attrs) do
    "Medplum API returned status #{Keyword.fetch!(attrs, :status)}"
  end

  defp default_message(:invalid_response, _attrs) do
    "Medplum returned an invalid response"
  end
end
