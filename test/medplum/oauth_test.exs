defmodule Medplum.OAuthTest do
  use ExUnit.Case, async: true

  alias Medplum.Error

  test "authorize_url/2 builds an authorization-code URL with extras" do
    url =
      Medplum.authorize_url(
        [
          base_url: "https://api.medplum.com",
          client_id: "phoenix-client",
          client_secret: "ignored-for-url"
        ],
        redirect_uri: "https://example.com/auth/medplum/callback",
        scope: "openid profile offline_access",
        state: "csrf-state",
        audience: "https://api.medplum.com"
      )

    uri = URI.parse(url)
    query = URI.decode_query(uri.query)

    assert uri.scheme == "https"
    assert uri.host == "api.medplum.com"
    assert uri.path == "/oauth2/authorize"
    assert query["client_id"] == "phoenix-client"
    assert query["redirect_uri"] == "https://example.com/auth/medplum/callback"
    assert query["response_type"] == "code"
    assert query["scope"] == "openid profile offline_access"
    assert query["state"] == "csrf-state"
    assert query["audience"] == "https://api.medplum.com"
  end

  test "exchange_authorization_code/3 posts grant details and returns token response" do
    parent = self()

    adapter = fn request ->
      send(parent, {:exchange_request, request})

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{
                "access_token" => "user-token",
                "refresh_token" => "refresh-token",
                "token_type" => "Bearer"
              }
            )
        end

      {request, response}
    end

    client =
      Medplum.new(
        base_url: "https://api.medplum.com",
        client_id: "phoenix-client",
        client_secret: "phoenix-secret",
        req_options: [adapter: adapter]
      )

    assert {:ok, %{"access_token" => "user-token", "refresh_token" => "refresh-token"}} =
             Medplum.exchange_authorization_code(client, "auth-code-123",
               redirect_uri: "https://example.com/auth/medplum/callback",
               code_verifier: "pkce-verifier"
             )

    assert_received {:exchange_request, %Req.Request{} = request}
    assert request.url.path == "/oauth2/token"
    assert Req.Request.get_header(request, "authorization") == []

    form =
      request.body
      |> IO.iodata_to_binary()
      |> URI.decode_query()

    assert form["grant_type"] == "authorization_code"
    assert form["code"] == "auth-code-123"
    assert form["redirect_uri"] == "https://example.com/auth/medplum/callback"
    assert form["client_id"] == "phoenix-client"
    assert form["client_secret"] == "phoenix-secret"
    assert form["code_verifier"] == "pkce-verifier"
  end

  test "exchange_authorization_code/3 returns Medplum.Error on oauth failure" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(status: 400, body: %{"error" => "invalid_grant"})
        end

      {request, response}
    end

    client =
      Medplum.new(
        base_url: "https://api.medplum.com",
        client_id: "phoenix-client",
        client_secret: "phoenix-secret",
        req_options: [adapter: adapter]
      )

    assert {:error, %Error{} = error} =
             Medplum.exchange_authorization_code(client, "bad-code",
               redirect_uri: "https://example.com/auth/medplum/callback"
             )

    assert error.type == :auth_failed
    assert error.status == 400
    assert error.body == %{"error" => "invalid_grant"}
  end

  test "userinfo/2 uses the provided access token" do
    parent = self()

    adapter = fn request ->
      send(parent, {:userinfo_request, request})

      response =
        case request.url.path do
          "/oauth2/userinfo" ->
            Req.Response.new(
              status: 200,
              body: %{"sub" => "user-1", "email" => "user@example.com"}
            )
        end

      {request, response}
    end

    client =
      Medplum.new_with_access_token(
        [base_url: "https://api.medplum.com", req_options: [adapter: adapter]],
        "user-access-token"
      )

    assert {:ok, %{"sub" => "user-1", "email" => "user@example.com"}} = Medplum.userinfo(client)

    assert_received {:userinfo_request, %Req.Request{} = request}
    assert request.url.path == "/oauth2/userinfo"
    assert Req.Request.get_header(request, "authorization") == ["Bearer user-access-token"]
  end

  test "userinfo/2 returns Medplum.Error on oauth failure" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/userinfo" ->
            Req.Response.new(status: 401, body: %{"error" => "invalid_token"})
        end

      {request, response}
    end

    client =
      Medplum.new_with_access_token(
        [base_url: "https://api.medplum.com", req_options: [adapter: adapter]],
        "expired-token"
      )

    assert {:error, %Error{} = error} = Medplum.userinfo(client)
    assert error.type == :auth_failed
    assert error.status == 401
    assert error.body == %{"error" => "invalid_token"}
  end
end
