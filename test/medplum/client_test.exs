defmodule Medplum.ClientTest do
  use ExUnit.Case, async: true

  alias Medplum.Client

  test "new/1 builds a client, trims trailing slash, and applies defaults" do
    client =
      Client.new(
        base_url: "https://api.medplum.com/",
        client_id: "client-id",
        client_secret: "client-secret"
      )

    assert client.base_url == "https://api.medplum.com"
    assert client.client_id == "client-id"
    assert client.client_secret == "client-secret"
    assert client.fhir_version == "R4"
    assert client.default_headers == []
    assert client.req_options == []
    assert client.auth_req_options == []
    assert client.auth_mode == :client_credentials
    assert client.access_token == nil
    assert client.retry == :transient
    assert client.max_retries == 2
    assert client.token_refresh_skew == 60
    assert client.cache_tokens == true
  end

  test "new/1 accepts map config and custom request options" do
    client =
      Client.new(%{
        base_url: "https://api.medplum.com/",
        client_id: "client-id",
        client_secret: "client-secret",
        fhir_version: "R5",
        default_headers: [{"x-app", "demo"}],
        req_options: [receive_timeout: 5_000],
        auth_req_options: [connect_options: [timeout: 100]],
        auth_mode: :client_credentials,
        retry: false,
        max_retries: 0,
        token_refresh_skew: 5,
        cache_tokens: false
      })

    assert client.base_url == "https://api.medplum.com"
    assert client.fhir_version == "R5"
    assert client.default_headers == [{"x-app", "demo"}]
    assert client.req_options == [receive_timeout: 5_000]
    assert client.auth_req_options == [connect_options: [timeout: 100]]
    assert client.auth_mode == :client_credentials
    assert client.retry == false
    assert client.max_retries == 0
    assert client.token_refresh_skew == 5
    assert client.cache_tokens == false
  end

  test "new_with_access_token/2 builds an access-token client" do
    client =
      Client.new_with_access_token(
        [base_url: "https://api.medplum.com/", default_headers: [{"x-app", "demo"}]],
        "user-token"
      )

    assert client.base_url == "https://api.medplum.com"
    assert client.auth_mode == :access_token
    assert client.access_token == "user-token"
    assert client.client_id == ""
    assert client.client_secret == ""
    assert client.default_headers == [{"x-app", "demo"}]
  end

  test "new!/1 raises for unsupported options" do
    assert_raise ArgumentError, ~r/unsupported Medplum client options/, fn ->
      Client.new!(
        base_url: "https://api.medplum.com",
        client_id: "id",
        client_secret: "secret",
        nope: true
      )
    end
  end

  test "new/1 raises for invalid typed options" do
    assert_raise ArgumentError, ~r/:max_retries must be a non-negative integer/, fn ->
      Client.new(
        base_url: "https://api.medplum.com",
        client_id: "id",
        client_secret: "secret",
        max_retries: -1
      )
    end
  end

  test "new/1 raises when access-token mode is missing the token" do
    assert_raise ArgumentError, ~r/:access_token must be a non-empty string/, fn ->
      Client.new(
        base_url: "https://api.medplum.com",
        auth_mode: :access_token
      )
    end
  end
end
