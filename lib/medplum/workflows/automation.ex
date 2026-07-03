defmodule Medplum.Workflows.Automation do
  @moduledoc """
  Bot and subscription workflow helpers for automation-heavy applications.
  """

  alias Medplum.Client
  alias Medplum.Resources.AuditEvent
  alias Medplum.Resources.Bot
  alias Medplum.Resources.Provenance
  alias Medplum.Resources.Subscription

  @spec execute_bot(Client.t(), String.t(), map()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def execute_bot(%Client{} = client, bot_id, input) when is_map(input) do
    Bot.execute(client, bot_id, input)
  end

  @spec deploy_bot(Client.t(), String.t(), map()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def deploy_bot(%Client{} = client, bot_id, params \\ %{}) when is_map(params) do
    Bot.deploy(client, bot_id, params)
  end

  @spec subscriptions_for_criteria(Client.t(), String.t(), map()) :: Medplum.result()
  def subscriptions_for_criteria(%Client{} = client, criteria, params \\ %{}) do
    Subscription.search_by_criteria(client, criteria, params)
  end

  @spec activate_subscription(Client.t(), String.t()) :: Medplum.result()
  def activate_subscription(%Client{} = client, subscription_id) do
    Medplum.patch(client, "Subscription", subscription_id, [
      %{"op" => "replace", "path" => "/status", "value" => "active"}
    ])
  end

  @spec pause_subscription(Client.t(), String.t()) :: Medplum.result()
  def pause_subscription(%Client{} = client, subscription_id) do
    Medplum.patch(client, "Subscription", subscription_id, [
      %{"op" => "replace", "path" => "/status", "value" => "off"}
    ])
  end

  @spec bot_audit_events(Client.t(), String.t(), map()) :: Medplum.result()
  def bot_audit_events(%Client{} = client, bot_ref, params \\ %{}) do
    AuditEvent.search_by_entity(client, bot_ref, params)
  end

  @spec provenance_for_target(Client.t(), String.t(), map()) :: Medplum.result()
  def provenance_for_target(%Client{} = client, target, params \\ %{}) do
    Provenance.search_by_target(client, target, params)
  end

  @spec subscribe_bot_to_resource(Client.t(), String.t(), String.t(), keyword()) ::
          Medplum.result()
  def subscribe_bot_to_resource(%Client{} = client, criteria, bot_id, opts \\ []) do
    status = Keyword.get(opts, :status, "active")
    payload = Keyword.get(opts, :payload, "application/fhir+json")
    reason = Keyword.get(opts, :reason, "Execute Bot/#{bot_id} for #{criteria}")

    headers =
      opts
      |> Keyword.get(:headers, [])
      |> Enum.map(fn {name, value} -> %{"name" => name, "value" => value} end)

    subscription = %{
      "resourceType" => "Subscription",
      "status" => status,
      "reason" => reason,
      "criteria" => criteria,
      "channel" => %{
        "type" => "rest-hook",
        "endpoint" => "Bot/#{bot_id}",
        "payload" => payload,
        "header" => headers
      }
    }

    Subscription.create(client, subscription)
  end
end
