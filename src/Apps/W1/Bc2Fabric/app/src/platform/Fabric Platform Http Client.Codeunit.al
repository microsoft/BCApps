namespace Microsoft.FabricExport;

using System.RestClient;

#if not PTE
codeunit 150006 "Fabric Platform Http Client"
#else
codeunit 50106 "Fabric Platform Http Client"
#endif
{
    Access = Internal;

    internal procedure CreateClientWithBearer(AccessToken: SecretText) RestClientResult: Codeunit "Rest Client"
    begin
        RestClientResult := CreateClient();
        RestClientResult.SetAuthorizationHeader(SecretStrSubstNo('Bearer %1', AccessToken));
    end;

    internal procedure BuildJsonRequest(Method: Text; Url: Text; JsonBody: Text) HttpRequestMessage: Codeunit "Http Request Message"
    var
        HttpContent: Codeunit "Http Content";
    begin
        HttpRequestMessage.SetHttpMethod(Method);
        HttpRequestMessage.SetRequestUri(Url);
        if JsonBody <> '' then begin
            HttpContent := HttpContent.Create(JsonBody, 'application/json');
            HttpRequestMessage.SetContent(HttpContent);
        end;
    end;

    [TryFunction]
    internal procedure TrySend(var RestClientParam: Codeunit "Rest Client"; var HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message")
    begin
        HttpResponseMessage := RestClientParam.Send(HttpRequestMessage);
    end;

    /// <summary>Raised before the HTTP client handler is created. Bind a subscriber to inject a mock handler in tests.</summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetHttpClientHandler(var HttpClientHandler: Interface "Http Client Handler"; var IsHandled: Boolean)
    begin
    end;

    local procedure CreateClient() RestClientResult: Codeunit "Rest Client"
    var
        HttpClientHandler: Interface "Http Client Handler";
        IsHandled: Boolean;
    begin
        OnBeforeGetHttpClientHandler(HttpClientHandler, IsHandled);
        if IsHandled then
            RestClientResult.Initialize(HttpClientHandler)
        else
            RestClientResult.Initialize();
    end;
}
