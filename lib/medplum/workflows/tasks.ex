defmodule Medplum.Workflows.Tasks do
  @moduledoc """
  Task-oriented workflow helpers for operational and clinical coordination.
  """

  alias Medplum.Client
  alias Medplum.Resources.Task

  @spec list_for_owner(Client.t(), String.t(), map()) :: Medplum.result()
  def list_for_owner(%Client{} = client, owner, params \\ %{}) do
    Task.search_by_owner(client, owner, params)
  end

  @spec list_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def list_for_patient(%Client{} = client, patient, params \\ %{}) do
    Task.search_by_patient(client, patient, params)
  end

  @spec list_for_focus(Client.t(), String.t(), map()) :: Medplum.result()
  def list_for_focus(%Client{} = client, focus, params \\ %{}) do
    Task.search_by_focus(client, focus, params)
  end

  @spec complete_task(Client.t(), String.t()) :: Medplum.result()
  def complete_task(%Client{} = client, id) do
    Medplum.patch(client, "Task", id, [
      %{"op" => "replace", "path" => "/status", "value" => "completed"}
    ])
  end

  @spec cancel_task(Client.t(), String.t()) :: Medplum.result()
  def cancel_task(%Client{} = client, id) do
    Medplum.patch(client, "Task", id, [
      %{"op" => "replace", "path" => "/status", "value" => "cancelled"}
    ])
  end
end
