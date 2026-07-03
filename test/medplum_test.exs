defmodule MedplumTest do
  use ExUnit.Case, async: true

  alias Medplum.Error

  test "read/3 reuses cached token until expiry" do
    parent = self()
    client_id = unique_client_id()

    adapter = fn request ->
      send(parent, {:request, URI.to_string(request.url)})

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient/123" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Patient", "id" => "123"})
        end

      {request, response}
    end

    client = client(adapter: adapter, client_id: client_id)

    assert {:ok, %{"id" => "123"}} = Medplum.read(client, "Patient", "123")
    assert {:ok, %{"id" => "123"}} = Medplum.read(client, "Patient", "123")

    urls = drain_urls([])
    assert Enum.count(urls, &(&1 == "https://api.medplum.com/oauth2/token")) == 1
    assert Enum.count(urls, &(&1 == "https://api.medplum.com/fhir/R4/Patient/123")) == 2
  end

  test "read/3 refreshes expired tokens" do
    parent = self()
    client_id = unique_client_id()

    adapter = fn request ->
      send(parent, {:request, URI.to_string(request.url)})

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-now", "expires_in" => 0}
            )

          "/fhir/R4/Patient/123" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Patient", "id" => "123"})
        end

      {request, response}
    end

    client = client(adapter: adapter, client_id: client_id)

    assert {:ok, %{"id" => "123"}} = Medplum.read(client, "Patient", "123")
    assert {:ok, %{"id" => "123"}} = Medplum.read(client, "Patient", "123")

    urls = drain_urls([])
    assert Enum.count(urls, &(&1 == "https://api.medplum.com/oauth2/token")) == 2
  end

  test "request errors return stable Medplum.Error shape" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient" ->
            Req.Response.new(status: 422, body: %{"issue" => [%{"code" => "invalid"}]})
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:error, %Error{} = error} = Medplum.search(client, "Patient", %{"family" => "Smith"})
    assert error.type == :api_error
    assert error.status == 422
    assert error.body == %{"issue" => [%{"code" => "invalid"}]}
  end

  test "patch/4 sends json patch request" do
    parent = self()

    adapter = fn request ->
      send(parent, {:patch_request, request})

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient/123" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Patient", "id" => "123"})
        end

      {request, response}
    end

    client = client(adapter: adapter)
    operations = [%{"op" => "replace", "path" => "/active", "value" => true}]

    assert {:ok, %{"id" => "123"}} = Medplum.patch(client, "Patient", "123", operations)

    assert_received {:patch_request, %Req.Request{method: :patch} = request}
    assert request.method == :patch
    assert request.body == Jason.encode!(operations)
    assert Req.Request.get_header(request, "content-type") == ["application/json-patch+json"]
  end

  test "request/4 accepts absolute URLs" do
    parent = self()

    adapter = fn request ->
      send(parent, {:absolute_request, URI.to_string(request.url)})

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "searchset"}
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)
    url = "https://api.medplum.com/fhir/R4/Patient?_count=1"

    assert {:ok, %{"type" => "searchset"}} = Medplum.request(client, :get, url)
    assert_received {:absolute_request, ^url}
  end

  test "operation/5 builds system operation path and defaults to POST with Parameters body" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:operation_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/$graphql" ->
            Req.Response.new(status: 200, body: %{"ok" => true})

          "/fhir/R4/$export" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Parameters"})
        end

      {request, response}
    end

    client = client(adapter: adapter)

    params = %{
      "resourceType" => "Parameters",
      "parameter" => [%{"name" => "_since", "valueDate" => "2026-01-01"}]
    }

    assert {:ok, %{"resourceType" => "Parameters"}} =
             Medplum.operation(client, :system, "export", params)

    assert_received {:operation_request, %Req.Request{} = request}
    assert request.method == :post
    assert request.url.path == "/fhir/R4/$export"
    assert IO.iodata_to_binary(request.body) == Jason.encode!(params)
  end

  test "operation/5 builds type and instance paths and defaults to GET without body" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:operation_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/ValueSet/$validate-code" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Parameters"})

          "/fhir/R4/Patient/123/$everything" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Bundle"})
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{"resourceType" => "Parameters"}} =
             Medplum.operation(client, "ValueSet", "validate-code", %{},
               params: %{"url" => "abc"}
             )

    assert_received {:operation_request, %Req.Request{} = type_request}
    assert type_request.method == :get
    assert type_request.url.path == "/fhir/R4/ValueSet/$validate-code"
    assert type_request.url.query == "url=abc"

    assert {:ok, %{"resourceType" => "Bundle"}} =
             Medplum.operation(client, {"Patient", "123"}, "everything")

    assert_received {:operation_request, %Req.Request{} = instance_request}
    assert instance_request.method == :get
    assert instance_request.url.path == "/fhir/R4/Patient/123/$everything"
  end

  test "operation/5 returns async metadata for 202 accepted responses" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/$export" ->
            Req.Response.new(
              status: 202,
              headers: [{"content-location", "https://api.medplum.com/fhir/R4/AsyncJob/123"}],
              body: ""
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok,
            %{"status" => 202, "statusUrl" => "https://api.medplum.com/fhir/R4/AsyncJob/123"}} =
             Medplum.operation(client, :system, "export", %{}, async: true)
  end

  test "poll_async/3 follows async status until final body" do
    parent = self()
    Process.put(:poll_count, 0)

    adapter = fn request ->
      send(parent, {:poll_request, URI.to_string(request.url)})

      response =
        case URI.to_string(request.url) do
          "https://api.medplum.com/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "https://api.medplum.com/fhir/R4/AsyncJob/123" ->
            count = Process.get(:poll_count, 0)
            Process.put(:poll_count, count + 1)

            if count == 0 do
              Req.Response.new(
                status: 200,
                body: %{"resourceType" => "AsyncJob", "status" => "running"}
              )
            else
              Req.Response.new(
                status: 200,
                body: %{"resourceType" => "Bundle", "type" => "batch-response"}
              )
            end
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{"resourceType" => "Bundle", "type" => "batch-response"}} =
             Medplum.poll_async(client, "https://api.medplum.com/fhir/R4/AsyncJob/123",
               interval: 0,
               max_attempts: 3
             )

    urls = drain_poll_urls([])
    assert "https://api.medplum.com/fhir/R4/AsyncJob/123" in urls
  end

  test "batch/2 and transaction/2 build bundle requests" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:bundle_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Bundle", "type" => "batch-response"}
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)
    entries = [%{"request" => %{"method" => "GET", "url" => "Patient/123"}}]

    assert {:ok, %{"type" => "batch-response"}} = Medplum.batch(client, entries)
    assert_received {:bundle_request, %Req.Request{} = batch_request}
    assert batch_request.method == :post
    assert batch_request.url.path == "/fhir/R4/"

    assert IO.iodata_to_binary(batch_request.body) ==
             Jason.encode!(%{"resourceType" => "Bundle", "type" => "batch", "entry" => entries})

    prebuilt = %{"resourceType" => "Bundle", "type" => "transaction", "entry" => entries}
    assert {:ok, %{"type" => "batch-response"}} = Medplum.transaction(client, prebuilt)
    assert_received {:bundle_request, %Req.Request{} = transaction_request}
    assert IO.iodata_to_binary(transaction_request.body) == Jason.encode!(prebuilt)
  end

  test "create_binary/3 uploads raw bytes with caller content type and security context" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:binary_upload_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Binary" ->
            Req.Response.new(status: 200, body: %{"resourceType" => "Binary", "id" => "bin-1"})
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{"id" => "bin-1"}} =
             Medplum.create_binary(client, "PDFDATA",
               content_type: "application/pdf",
               security_context: "Patient/123",
               filename: "report.pdf"
             )

    assert_received {:binary_upload_request, %Req.Request{} = request}
    assert request.body == "PDFDATA"
    assert Req.Request.get_header(request, "content-type") == ["application/pdf"]
    assert Req.Request.get_header(request, "x-security-context") == ["Patient/123"]

    assert Req.Request.get_header(request, "content-disposition") == [
             "attachment; filename=\"report.pdf\""
           ]
  end

  test "get_binary/2 returns raw body metadata" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Binary/bin-1" ->
            Req.Response.new(
              status: 200,
              headers: [{"content-type", "application/pdf"}],
              body: "RAWPDF"
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{body: "RAWPDF", content_type: "application/pdf", headers: headers}} =
             Medplum.get_binary(client, "bin-1")

    assert {"content-type", "application/pdf"} in headers
  end

  test "upsert/3 sends conditional put using embedded search query" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:upsert_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient" ->
            Req.Response.new(
              status: 200,
              body: %{"resourceType" => "Patient", "id" => "upserted"}
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)

    attrs = %{
      "_search" => %{"identifier" => "http://hospital.example/mrn|123"},
      "resourceType" => "Patient",
      "identifier" => [%{"system" => "http://hospital.example/mrn", "value" => "123"}]
    }

    assert {:ok, %{"id" => "upserted"}} = Medplum.upsert(client, "Patient", attrs)

    assert_received {:upsert_request, %Req.Request{} = request}
    assert request.method == :put
    assert request.url.path == "/fhir/R4/Patient"
    assert request.url.query == "identifier=http%3A%2F%2Fhospital.example%2Fmrn%7C123"
    refute String.contains?(IO.iodata_to_binary(request.body), "\"_search\"")
  end

  test "graphql/3 posts JSON payload and preserves HTTP 200 GraphQL errors as success" do
    parent = self()

    adapter = fn request ->
      if request.url.path != "/oauth2/token" do
        send(parent, {:graphql_request, request})
      end

      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/$graphql" ->
            Req.Response.new(
              status: 200,
              body: %{"data" => nil, "errors" => [%{"message" => "bad field"}]}
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{"errors" => [%{"message" => "bad field"}]}} =
             Medplum.graphql(client, "query Demo { PatientList { id } }",
               variables: %{"limit" => 1},
               operation_name: "Demo"
             )

    assert_received {:graphql_request, %Req.Request{} = request}
    assert request.method == :post

    assert IO.iodata_to_binary(request.body) ==
             Jason.encode!(%{
               "query" => "query Demo { PatientList { id } }",
               "variables" => %{"limit" => 1},
               "operationName" => "Demo"
             })

    assert Req.Request.get_header(request, "content-type") == ["application/json"]
    assert Req.Request.get_header(request, "accept") == ["application/json"]
  end

  test "stream_search/3 follows next links and yields entries" do
    adapter = fn request ->
      response =
        case URI.to_string(request.url) do
          "https://api.medplum.com/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "https://api.medplum.com/fhir/R4/Patient?family=Smith" ->
            Req.Response.new(
              status: 200,
              body: %{
                "resourceType" => "Bundle",
                "entry" => [%{"resource" => %{"id" => "1"}}],
                "link" => [
                  %{
                    "relation" => "next",
                    "url" => "https://api.medplum.com/fhir/R4/Patient?page=2"
                  }
                ]
              }
            )

          "https://api.medplum.com/fhir/R4/Patient?page=2" ->
            Req.Response.new(
              status: 200,
              body: %{
                "resourceType" => "Bundle",
                "entry" => [%{"resource" => %{"id" => "2"}}]
              }
            )
        end

      {request, response}
    end

    client = client(adapter: adapter)

    entries =
      client
      |> Medplum.stream_search("Patient", %{"family" => "Smith"})
      |> Enum.to_list()

    assert entries == [%{"resource" => %{"id" => "1"}}, %{"resource" => %{"id" => "2"}}]
  end

  test "delete/3 treats 204 empty response as success" do
    adapter = fn request ->
      response =
        case request.url.path do
          "/oauth2/token" ->
            Req.Response.new(
              status: 200,
              body: %{"access_token" => "token-1", "expires_in" => 300}
            )

          "/fhir/R4/Patient/123" ->
            Req.Response.new(status: 204, body: "")
        end

      {request, response}
    end

    client = client(adapter: adapter)

    assert {:ok, %{}} = Medplum.delete(client, "Patient", "123")
  end

  defp client(opts) do
    adapter = Keyword.fetch!(opts, :adapter)

    Medplum.new(
      base_url: "https://api.medplum.com/",
      client_id: Keyword.get(opts, :client_id, unique_client_id()),
      client_secret: "client-secret",
      req_options: [adapter: adapter]
    )
  end

  defp unique_client_id do
    "client-#{System.unique_integer([:positive])}"
  end

  defp drain_urls(acc) do
    receive do
      {:request, url} -> drain_urls([url | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp drain_poll_urls(acc) do
    receive do
      {:poll_request, url} -> drain_poll_urls([url | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
