namespace Microsoft.FabricExport;

using System.RestClient;

codeunit 140010 "Fabric Platform Test Sub" implements "Http Client Handler"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        EnableCalled: Boolean;
        StartCalled: Boolean;
        StopCalled: Boolean;
        DisableCalled: Boolean;
        TestConnectionCalled: Boolean;
        MockStatusCode: Integer;
        MockResponseBody: Text;
        MockResponseConfigured: Boolean;

    procedure Reset()
    begin
        EnableCalled := false;
        StartCalled := false;
        StopCalled := false;
        DisableCalled := false;
        TestConnectionCalled := false;
        MockStatusCode := 0;
        MockResponseBody := '';
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
        MockStatusCode := StatusCode;
        MockResponseBody := ResponseBody;
        MockResponseConfigured := true;
    end;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        MockContent: Codeunit "Http Content";
    begin
        HttpResponseMessage.SetHttpStatusCode(MockStatusCode);
        HttpResponseMessage.SetIsSuccessStatusCode((MockStatusCode >= 200) and (MockStatusCode < 300));
        if MockResponseBody <> '' then begin
            MockContent := MockContent.Create(MockResponseBody, 'application/json');
            HttpResponseMessage.SetContent(MockContent);
        end;
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

