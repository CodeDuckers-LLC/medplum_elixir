defmodule Medplum.Workflows.Billing do
  @moduledoc """
  Billing and claim workflow helpers.
  """

  alias Medplum.Client
  alias Medplum.Resources.Account
  alias Medplum.Resources.ChargeItem
  alias Medplum.Resources.ChargeItemDefinition
  alias Medplum.Resources.Claim
  alias Medplum.Resources.ClaimResponse
  alias Medplum.Resources.CoverageEligibilityRequest
  alias Medplum.Resources.CoverageEligibilityResponse

  @spec claims_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def claims_for_patient(%Client{} = client, patient, params \\ %{}) do
    Claim.search_by_patient(client, patient, params)
  end

  @spec claims_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def claims_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    Claim.search_by_encounter(client, encounter, params)
  end

  @spec claims_for_status(Client.t(), String.t(), map()) :: Medplum.result()
  def claims_for_status(%Client{} = client, status, params \\ %{}) do
    Claim.search_by_status(client, status, params)
  end

  @spec claim_responses_for_claim(Client.t(), String.t(), map()) :: Medplum.result()
  def claim_responses_for_claim(%Client{} = client, claim, params \\ %{}) do
    ClaimResponse.search_by_claim(client, claim, params)
  end

  @spec charge_items_for_account(Client.t(), String.t(), map()) :: Medplum.result()
  def charge_items_for_account(%Client{} = client, account, params \\ %{}) do
    ChargeItem.search_by_account(client, account, params)
  end

  @spec charge_items_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def charge_items_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    ChargeItem.search_by_encounter(client, encounter, params)
  end

  @spec accounts_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def accounts_for_patient(%Client{} = client, patient, params \\ %{}) do
    Account.search_by_patient(client, patient, params)
  end

  @spec eligibility_requests_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def eligibility_requests_for_patient(%Client{} = client, patient, params \\ %{}) do
    CoverageEligibilityRequest.search_by_patient(client, patient, params)
  end

  @spec eligibility_responses_for_patient(Client.t(), String.t(), map()) :: Medplum.result()
  def eligibility_responses_for_patient(%Client{} = client, patient, params \\ %{}) do
    CoverageEligibilityResponse.search_by_patient(client, patient, params)
  end

  @spec export_claim(Client.t(), String.t()) :: Medplum.result() | {:ok, Medplum.async_result()}
  def export_claim(%Client{} = client, claim_id) when is_binary(claim_id) do
    Medplum.operation(client, {"Claim", claim_id}, "export", %{}, method: :get)
  end

  @spec export_claim(Client.t(), map(), keyword()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def export_claim(%Client{} = client, params, opts) when is_map(params) and is_list(opts) do
    Medplum.operation(client, "Claim", "export", params, Keyword.put_new(opts, :method, :post))
  end

  @spec submit_claim_to_stedi(Client.t(), String.t(), map()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def submit_claim_to_stedi(%Client{} = client, claim_id, params \\ %{})
      when is_binary(claim_id) and is_map(params) do
    Medplum.operation(client, {"Claim", claim_id}, "stedi-submit-claim", params, method: :post)
  end

  @spec submit_claim_to_candid(Client.t(), String.t(), map()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def submit_claim_to_candid(%Client{} = client, claim_id, params \\ %{})
      when is_binary(claim_id) and is_map(params) do
    Medplum.operation(client, {"Claim", claim_id}, "candid-submit-claim", params, method: :post)
  end

  @spec apply_charge_item_definition(Client.t(), String.t(), map()) ::
          Medplum.result() | {:ok, Medplum.async_result()}
  def apply_charge_item_definition(%Client{} = client, definition_id, params)
      when is_binary(definition_id) and is_map(params) do
    ChargeItemDefinition.apply_definition(client, definition_id, params)
  end
end
