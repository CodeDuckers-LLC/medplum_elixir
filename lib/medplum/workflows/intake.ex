defmodule Medplum.Workflows.Intake do
  @moduledoc """
  Intake and assessment workflow helpers built on `QuestionnaireResponse`.
  """

  alias Medplum.Client
  alias Medplum.Resources.QuestionnaireResponse

  @spec submit_questionnaire_response(Client.t(), map()) :: Medplum.result()
  def submit_questionnaire_response(%Client{} = client, attrs) do
    QuestionnaireResponse.create(client, attrs)
  end

  @spec questionnaire_responses_for_subject(Client.t(), String.t(), map()) :: Medplum.result()
  def questionnaire_responses_for_subject(%Client{} = client, subject, params \\ %{}) do
    QuestionnaireResponse.search_by_subject(client, subject, params)
  end

  @spec questionnaire_responses_for_encounter(Client.t(), String.t(), map()) :: Medplum.result()
  def questionnaire_responses_for_encounter(%Client{} = client, encounter, params \\ %{}) do
    QuestionnaireResponse.search_by_encounter(client, encounter, params)
  end

  @spec questionnaire_responses_for_questionnaire(Client.t(), String.t(), map()) ::
          Medplum.result()
  def questionnaire_responses_for_questionnaire(%Client{} = client, questionnaire, params \\ %{}) do
    QuestionnaireResponse.search_by_questionnaire(client, questionnaire, params)
  end
end
