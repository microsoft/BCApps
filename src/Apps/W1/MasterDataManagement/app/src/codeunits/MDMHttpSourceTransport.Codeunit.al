namespace Microsoft.Integration.MDM;

/// <summary>
/// Production transport: calls the source environment's ODataV4 web service with an app-only (client
/// credentials) token. The OAuth2 + HttpClient body is implemented in a follow-up; until then it fails loudly
/// so a misconfigured environment is obvious. Tests never hit this — they inject an in-process transport.
/// </summary>
codeunit 7247 "MDM Http Source Transport" implements "IMDM Source Transport"
{
    Access = Internal;

    var
        NotConfiguredErr: Label 'The cross-environment connection to the source is not configured yet.';

    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer): Text
    begin
        // TODO(cross-env): OAuth2 client-credentials token (creds from Isolated Storage) + HttpClient POST to
        // {sourceUrl}/ODataV4/{service}_GetRecords?company={company}; return the response body.
        Error(NotConfiguredErr);
    end;

    procedure LastModifiedAtPerTable(TableIds: Text): Text
    begin
        Error(NotConfiguredErr);
    end;

    procedure GetCapabilities(): Text
    begin
        Error(NotConfiguredErr);
    end;
}
