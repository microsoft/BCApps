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
        CannedCapabilities: Text;
        Active: Boolean;
        UseCanned: Boolean;
        UseCannedCapabilities: Boolean;

    /// <summary>Activates the in-process transport so it is injected in place of the HTTP transport.</summary>
    procedure Activate()
    begin
        Active := true;
    end;

    /// <summary>Deactivates the transport and clears all canned state and negotiated capabilities.</summary>
    procedure Deactivate()
    var
        SourceCapabilities: Codeunit "MDM Source Capabilities";
    begin
        Active := false;
        UseCanned := false;
        UseCannedCapabilities := false;
        Clear(CannedResponse);
        Clear(CannedCapabilities);
        SourceCapabilities.Reset(); // clear negotiated capabilities between tests
    end;

    /// <summary>Sets a canned records/last-modified response returned instead of calling the real source API.</summary>
    /// <param name="Response">The raw JSON response to return.</param>
    procedure SetCannedResponse(Response: Text)
    begin
        CannedResponse := Response;
        UseCanned := true;
    end;

    /// <summary>Sets a canned capabilities response returned instead of calling the real source API.</summary>
    /// <param name="Response">The raw JSON capabilities response to return.</param>
    procedure SetCannedCapabilities(Response: Text)
    begin
        CannedCapabilities := Response;
        UseCannedCapabilities := true;
    end;

    /// <summary>Returns records for a table, using the canned response if one is set, otherwise the real source API.</summary>
    /// <param name="TableId">The source table ID to read.</param>
    /// <param name="FieldIds">The projected field IDs.</param>
    /// <param name="Selector">The cursor/systemId selector.</param>
    /// <param name="PageSize">The page size.</param>
    /// <param name="Filter">The optional source row filter (view).</param>
    /// <returns>The raw JSON records response.</returns>
    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer; Filter: Text): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        if UseCanned then
            exit(CannedResponse);
        exit(SourceApi.GetRecords(TableId, FieldIds, Selector, PageSize, Filter));
    end;

    /// <summary>Returns the last-modified-per-table probe, using the canned response if set, otherwise the real source API.</summary>
    /// <param name="TableIds">The JSON array of table IDs to probe.</param>
    /// <returns>The raw JSON last-modified response.</returns>
    procedure LastModifiedAtPerTable(TableIds: Text): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        if UseCanned then
            exit(CannedResponse);
        exit(SourceApi.LastModifiedAtPerTable(TableIds));
    end;

    /// <summary>Returns the source capabilities, using the canned capabilities if set, otherwise the real source API.</summary>
    /// <returns>The raw JSON capabilities response.</returns>
    procedure GetCapabilities(): Text
    var
        SourceApi: Codeunit "MDM Cross-Env Source API";
    begin
        if UseCannedCapabilities then
            exit(CannedCapabilities);
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
