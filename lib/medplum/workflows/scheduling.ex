defmodule Medplum.Workflows.Scheduling do
  @moduledoc """
  Medplum scheduling workflow helpers built on Appointment FHIR operations.
  """

  alias Medplum.Client

  @resource_type "Appointment"

  @spec find_appointments(Client.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def find_appointments(%Client{} = client, params, opts \\ []) when is_map(params) do
    Medplum.operation(
      client,
      @resource_type,
      "find",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end

  @spec hold_appointment(Client.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def hold_appointment(%Client{} = client, params, opts \\ []) when is_map(params) do
    Medplum.operation(
      client,
      @resource_type,
      "hold",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end

  @spec book_appointment(Client.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def book_appointment(%Client{} = client, params, opts \\ []) when is_map(params) do
    Medplum.operation(
      client,
      @resource_type,
      "book",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end

  @spec confirm_appointment(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def confirm_appointment(%Client{} = client, appointment_id, params \\ %{}, opts \\ [])
      when is_binary(appointment_id) and is_map(params) do
    Medplum.operation(
      client,
      {@resource_type, appointment_id},
      "confirm",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end

  @spec cancel_appointment(Client.t(), String.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def cancel_appointment(%Client{} = client, appointment_id, params \\ %{}, opts \\ [])
      when is_binary(appointment_id) and is_map(params) do
    Medplum.operation(
      client,
      {@resource_type, appointment_id},
      "cancel",
      params,
      Keyword.put_new(opts, :method, :post)
    )
  end
end
