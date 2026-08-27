#pragma warning disable AA0247
codeunit 139929 "MDM In-Process Transport" implements "IMDM Source Transport"
{
    // Test transport: injected into the cross-env data source via OnResolveSourceTransport so the subsidiary and
    // source run in ONE environment. Pass-through calls the real source API (codeunit 7241) for round-trip tests;
    // a canned response lets tests exercise the subsidiary's error handling. SingleInstance so the injected
    // instance shares the state the test sets.
    SingleInstance = true;
    Access = Public;

    var
        CannedResponse: Text;
        Active: Boolean;
        UseCanned: Boolean;

    procedure Activate()
    begin
        Active := true;
    end;

    procedure Deactivate()
    begin
        Active := false;
        UseCanned := false;
        Clear(CannedResponse);
    end;

    procedure SetCannedResponse(Response: Text)
    begin
        CannedResponse := Response;
        UseCanned := true;
    end;

    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        if UseCanned then
            exit(CannedResponse);
        exit(SourceApi.GetRecords(TableId, FieldIds, Selector, PageSize));
    end;

    procedure LastModifiedAtPerTable(TableIds: Text): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        if UseCanned then
            exit(CannedResponse);
        exit(SourceApi.LastModifiedAtPerTable(TableIds));
    end;

    procedure GetCapabilities(): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        exit(SourceApi.GetCapabilities());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MDM Source Connection", 'OnResolveSourceTransport', '', false, false)]
    local procedure InjectTransport(var Transport: Interface "IMDM Source Transport")
    var
        InProcessTransport: Codeunit "MDM In-Process Transport";
    begin
        if not Active then
            exit;
        Transport := InProcessTransport; // SingleInstance: same stateful instance the test configured
    end;
}
