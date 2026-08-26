namespace Microsoft.Integration.MDM;

/// <summary>
/// Source-side generic API, published as an ODataV4 web service. The cross-environment implementation of
/// "IMDM Data Source" (running in a subsidiary) calls these unbound actions to read source master data.
/// Runs under the CALLER's permission set with NO permission elevation, so a read-only, table-scoped
/// permission set assigned to the caller's Entra app is the effective access boundary.
/// </summary>
codeunit 7241 "MDM Cross-Env Source API"
{
    Access = Public;

    var
        NotYetImplementedErr: Label 'This master data management source action is not yet available.';

    /// <summary>
    /// Wire-version negotiation: returns the API contract version and the action/feature names this source
    /// supports, so a newer subsidiary only calls actions an older source actually implements.
    /// </summary>
    [ServiceEnabled]
    procedure GetCapabilities(): Text
    var
        Capabilities: JsonObject;
        Features: JsonArray;
        ResultText: Text;
    begin
        Capabilities.Add('version', ApiVersion());
        Features.Add('records');
        Features.Add('lastModifiedPerTable');
        Capabilities.Add('features', Features);
        Capabilities.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Returns a page of changed source records for the given table. Selector is either a change-feed
    /// cursor { modifiedAt, systemId, pageSize } or a targeted { systemIds } list. Response carries the
    /// records, nextCursor and hasMore. Only tables/fields in a configured mapping are served.
    /// </summary>
    [ServiceEnabled]
    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer): Text
    begin
        // TODO(cross-env): authorize (calling app + mapping scope), project FieldIds, page by the composite
        // cursor (SystemModifiedAt, SystemId), serialize field types, and report unavailable table/fields.
        Error(NotYetImplementedErr);
    end;

    /// <summary>
    /// Change detection: for each requested table id, returns its latest source modification timestamp so
    /// the subsidiary detector can decide which per-table sync jobs to reschedule.
    /// </summary>
    [ServiceEnabled]
    procedure LastModifiedAtPerTable(TableIds: Text): Text
    begin
        // TODO(cross-env): read the trigger-maintained (TableId, LastModifiedAt) summary table (not yet built)
        // rather than scanning; return [{ tableId, lastModifiedAt }].
        Error(NotYetImplementedErr);
    end;

    local procedure ApiVersion(): Integer
    begin
        exit(1);
    end;
}

