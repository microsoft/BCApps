namespace Microsoft.FabricExport;

using System.RestClient;

codeunit 140010 "Fabric Platform Test Sub" implements "Http Client Handler"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Assert";
        EnableCalled: Boolean;
        StartCalled: Boolean;
        StopCalled: Boolean;
        DisableCalled: Boolean;
        TestConnectionCalled: Boolean;
        MockStatusCodes: List of [Integer];
        MockResponseBodies: List of [Text];
        ExpectedHttpMethods: List of [Text];
        ExpectedRequestUris: List of [Text];
        MockResponseConfigured: Boolean;
        UnexpectedHttpRequestErr: Label 'Unexpected HTTP request: %1 %2.', Comment = '%1 = HTTP method, %2 = request URI';

    procedure Reset()
    begin
        EnableCalled := false;
        StartCalled := false;
        StopCalled := false;
        DisableCalled := false;
        TestConnectionCalled := false;
        Clear(MockStatusCodes);
        Clear(MockResponseBodies);
        Clear(ExpectedHttpMethods);
        Clear(ExpectedRequestUris);
        MockResponseConfigured := false;
    end;

    procedure WasEnableCalled(): Boolean
    begin
        exit(EnableCalled);
    end;

    procedure WasStartCalled(): Boolean
    begin
        exit(StartCalled);
    end;

    procedure WasStopCalled(): Boolean
    begin
        exit(StopCalled);
    end;

    procedure WasDisableCalled(): Boolean
    begin
        exit(DisableCalled);
    end;

    procedure WasTestConnectionCalled(): Boolean
    begin
        exit(TestConnectionCalled);
    end;

    /// <summary>Configures the mocked HTTP response returned to the next Fabric Platform Http Client caller.</summary>
    procedure SetMockHttpResponse(StatusCode: Integer; ResponseBody: Text)
    begin
        Clear(MockStatusCodes);
        Clear(MockResponseBodies);
        Clear(ExpectedHttpMethods);
        Clear(ExpectedRequestUris);
        AddMockHttpResponse(StatusCode, ResponseBody, '', '');
    end;

    procedure AddMockHttpResponse(StatusCode: Integer; ResponseBody: Text; ExpectedHttpMethod: Text; ExpectedRequestUri: Text)
    begin
        MockStatusCodes.Add(StatusCode);
        MockResponseBodies.Add(ResponseBody);
        ExpectedHttpMethods.Add(ExpectedHttpMethod);
        ExpectedRequestUris.Add(ExpectedRequestUri);
        MockResponseConfigured := true;
    end;

    procedure AssertHttpRequestsComplete()
    begin
        Assert.AreEqual(0, MockStatusCodes.Count(), 'Expected all mocked HTTP requests to be sent.');
    end;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        MockContent: Codeunit "Http Content";
        MockStatusCode: Integer;
        MockResponseBody: Text;
    begin
        if MockStatusCodes.Count() = 0 then
            Error(UnexpectedHttpRequestErr, HttpRequestMessage.GetHttpMethod(), HttpRequestMessage.GetRequestUri());
        if ExpectedHttpMethods.Get(1) <> '' then
            Assert.AreEqual(ExpectedHttpMethods.Get(1), HttpRequestMessage.GetHttpMethod(), 'Unexpected HTTP method.');
        if ExpectedRequestUris.Get(1) <> '' then
            Assert.AreEqual(ExpectedRequestUris.Get(1), HttpRequestMessage.GetRequestUri(), 'Unexpected HTTP request URI.');

        MockStatusCode := MockStatusCodes.Get(1);
        MockResponseBody := MockResponseBodies.Get(1);
        MockStatusCodes.RemoveAt(1);
        MockResponseBodies.RemoveAt(1);
        ExpectedHttpMethods.RemoveAt(1);
        ExpectedRequestUris.RemoveAt(1);

        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode((MockStatusCode >= 200) and (MockStatusCode < 300));
        MockContent := MockContent.Create(MockResponseBody, 'application/json');
        HttpResponseMessage.SetContent(MockContent);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Http Client", OnBeforeGetHttpClientHandler, '', false, false)]
    local procedure OnBeforeGetHttpClientHandler(var HttpClientHandler: Interface "Http Client Handler"; var IsHandled: Boolean)
    begin
        if not MockResponseConfigured then
            exit;
        HttpClientHandler := this;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeEnableExport, '', false, false)]
    local procedure OnBeforeEnable(var IsHandled: Boolean)
    begin
        EnableCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeStartExport, '', false, false)]
    local procedure OnBeforeStart(var IsHandled: Boolean)
    begin
        StartCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeStopExport, '', false, false)]
    local procedure OnBeforeStop(var IsHandled: Boolean)
    begin
        StopCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeDisableExport, '', false, false)]
    local procedure OnBeforeDisable(var IsHandled: Boolean)
    begin
        DisableCalled := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fabric Platform Mgt", OnBeforeTestConnection, '', false, false)]
    local procedure OnBeforeTestConnectionSub(var IsHandled: Boolean; var IsSuccess: Boolean)
    begin
        TestConnectionCalled := true;
        IsHandled := true;
        IsSuccess := true;
    end;
}
