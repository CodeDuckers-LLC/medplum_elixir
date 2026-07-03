defmodule Medplum.ResourceUpsert do
  @moduledoc false

  alias Medplum.Client

  @spec upsert_by_identifier(Client.t(), String.t(), String.t(), String.t(), map()) ::
          Medplum.result()
  def upsert_by_identifier(%Client{} = client, resource_type, system, value, attrs)
      when is_map(attrs) do
    Medplum.upsert(
      client,
      resource_type,
      Map.put(attrs, "_search", %{"identifier" => "#{system}|#{value}"})
    )
  end

  @spec upsert_from_first_identifier(Client.t(), String.t(), map()) :: Medplum.result()
  def upsert_from_first_identifier(%Client{} = client, resource_type, attrs) when is_map(attrs) do
    {system, value} = extract_first_identifier!(attrs)
    upsert_by_identifier(client, resource_type, system, value, attrs)
  end

  defp extract_first_identifier!(%{
         "identifier" => [%{"system" => system, "value" => value} | _rest]
       })
       when is_binary(system) and is_binary(value) do
    {system, value}
  end

  defp extract_first_identifier!(%{identifier: [%{system: system, value: value} | _rest]})
       when is_binary(system) and is_binary(value) do
    {system, value}
  end

  defp extract_first_identifier!(_attrs) do
    raise ArgumentError,
          "upsert/2 requires attrs to include identifier with system and value in first entry"
  end
end
