namespace Microsoft.EServices;

using System.Telemetry;
using System.Utilities;

codeunit 13608 "Nemhandel Status Page Bckgrnd"
{
    Access = Internal;

    var
        NemhandelMgt: Codeunit "Nemhandel Status Mgt.";
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - host, e.g. microsoft.com', Locked = true;
        ConnectionErr: Label 'Could not connect to the remote service %1.', Comment = '%1 - host, e.g. microsoft.com', Locked = true;
        CompanyStatusCheckedTxt: Label 'Nemhandel company registration status was checked.', Locked = true;
        ResponseRejectedTxt: Label 'The Nemhandelsregisteret response was rejected by response validation (size or schema).', Locked = true;
        ServiceCallFailedTxt: Label 'The Nemhandelsregisteret company registration status lookup failed.', Locked = true;
        NemhandelsregisteretCategoryTxt: Label 'Nemhandelsregisteret', Locked = true;
        NemhandelCompanyStatusKeyLbl: Label 'NemhandelCompanyStatus', Locked = true;
        CVRNumberKeyLbl: Label 'CVRNumber', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The Nemhandelsregisteret service returned a response that exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseSchemaTxt: Label 'The Nemhandelsregisteret service returned a response that did not contain the expected data.', Locked = true;

    trigger OnRun()
    var
        InputParams: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CompanyStatus: Enum "Nemhandel Company Status";
        CVRNumber: Text;
    begin
        InputParams := Page.GetBackgroundParameters();
        if InputParams.Get(GetCVRNumberKey(), CVRNumber) then;

        // Send request to Nemhandel to determine if the company is registered
        CompanyStatus := GetCompanyStatus(CVRNumber);

        Results.Add(GetStatusKey(), Format(CompanyStatus));
        Page.SetBackgroundTaskResult(Results);
    end;

    procedure GetCompanyStatus(CVRNumber: Text) CompanyStatus: Enum "Nemhandel Company Status"
    var
        Telemetry: Codeunit Telemetry;
        HttpClientNemhandel: Interface "Http Client Nemhandel Status";
        HttpResponseMsgNemhandel: Interface "Http Response Msg Nemhandel";
        HttpRequestMessage: HttpRequestMessage;
        HttpRequestURI: Text;
        ResponseCVRNumber: Text;
        ErrorMessage: Text;
        ContentString: Text;
        HttpStatusCode: Integer;
        HttpStatusReason: Text;
        ResponseBodyValid: Boolean;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if CVRNumber = '' then
            exit("Nemhandel Company Status"::NotRegistered);

        CustomDimensions.Add('Category', NemhandelsregisteretCategoryTxt);

        HttpClientNemhandel := NemhandelMgt.GetHttpClient();
        HttpRequestURI := HttpClientNemhandel.GetRequestURI(CVRNumber);
        if not HttpClientNemhandel.SendGetRequest(HttpRequestURI, HttpRequestMessage, HttpResponseMsgNemhandel) then
            if HttpResponseMsgNemhandel.IsBlockedByEnvironment() then
                ErrorMessage := StrSubstNo(EnvironmentBlocksErr, GetHostFromUri(HttpRequestURI))
            else
                ErrorMessage := StrSubstNo(ConnectionErr, GetHostFromUri(HttpRequestURI));
        if ErrorMessage <> '' then begin
            Telemetry.LogMessage(
                '0000L9W', ErrorMessage, Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, CustomDimensions);
            CompanyStatus := "Nemhandel Company Status"::Unknown;
            exit;
        end;

        HttpStatusCode := 0;
        HttpStatusReason := '';
        ProcessHttpResponseMessage(HttpResponseMsgNemhandel, ResponseCVRNumber, ContentString, HttpStatusCode, HttpStatusReason, ResponseBodyValid);
        CustomDimensions.Add('HttpStatusCode', Format(HttpStatusCode));
        CustomDimensions.Add('HttpStatusReason', HttpStatusReason);

        case HttpStatusCode of
            200:
                if not ResponseBodyValid then begin
                    // Oversized or schema-invalid response: an explicit rejection introduced by response validation.
                    // Logged as a warning (and to environment telemetry) so it is distinguishable from a successful lookup.
                    CompanyStatus := "Nemhandel Company Status"::Unknown;
                    Telemetry.LogMessage(
                        '0000VEV', ResponseRejectedTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                        TelemetryScope::All, CustomDimensions);
                end else begin
                    if UpperCase(ResponseCVRNumber.Trim()) = UpperCase(CVRNumber.Trim()) then
                        CompanyStatus := "Nemhandel Company Status"::Registered
                    else
                        CompanyStatus := "Nemhandel Company Status"::NotRegistered;
                    Telemetry.LogMessage(
                        '0000L9X', CompanyStatusCheckedTxt, Verbosity::Normal, DataClassification::SystemMetadata,
                        TelemetryScope::ExtensionPublisher, CustomDimensions);
                end;
            404:
                begin
                    CompanyStatus := "Nemhandel Company Status"::NotRegistered;
                    Telemetry.LogMessage(
                        '0000L9Y', CompanyStatusCheckedTxt, Verbosity::Normal, DataClassification::SystemMetadata,
                        TelemetryScope::ExtensionPublisher, CustomDimensions);
                end;
            else begin
                CompanyStatus := "Nemhandel Company Status"::Unknown;
                Telemetry.LogMessage(
                    '0000L9Z', ServiceCallFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata,
                    TelemetryScope::All, CustomDimensions);
            end;
        end;
    end;

    procedure GetStatusKey(): Text
    begin
        exit(NemhandelCompanyStatusKeyLbl);
    end;

    procedure GetCVRNumberKey(): Text
    begin
        exit(CVRNumberKeyLbl);
    end;

    procedure SetHttpClient(HttpClientNemhandel: Interface "Http Client Nemhandel Status")
    begin
        NemhandelMgt.SetHttpClient(HttpClientNemhandel);
    end;

    local procedure ProcessHttpResponseMessage(HttpResponseMsgNemhandel: Interface "Http Response Msg Nemhandel"; var ResponseCVRNumber: Text; var ContentString: Text; var HttpStatusCode: Integer; var HttpStatusReason: Text; var ResponseBodyValid: Boolean)
    var
        AuditLog: Codeunit "Audit Log";
    begin
        ResponseBodyValid := false;
        HttpStatusCode := HttpResponseMsgNemhandel.HttpStatusCode();
        HttpStatusReason := HttpResponseMsgNemhandel.ReasonPhrase();

        if not HttpResponseMsgNemhandel.IsSuccessStatusCode() then
            exit;

        ContentString := HttpResponseMsgNemhandel.GetResponseBodyAsText();

        // Size limit: reject abnormally large responses from the unauthenticated Nemhandelsregisteret service before parsing.
        if StrLen(ContentString) > GetMaxResponseSize() then begin
            // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
            AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
            exit;
        end;

        // Schema / source expectation: the response must be a JSON object that exposes the 'cvrNummer' field.
        if not TryExtractCVRNumber(ContentString, ResponseCVRNumber) then begin
            AuditLog.LogAuditMessage(SecurityAuditResponseSchemaTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
            exit;
        end;

        ResponseBodyValid := true;
    end;

    local procedure TryExtractCVRNumber(ContentString: Text; var ResponseCVRNumber: Text): Boolean
    var
        ContentJson: JsonObject;
        CVRNumberToken: JsonToken;
    begin
        if not ContentJson.ReadFrom(ContentString) then
            exit(false);
        if not ContentJson.Get('cvrNummer', CVRNumberToken) then
            exit(false);
        // Require a scalar value (reject nested objects/arrays) so a tampered payload cannot smuggle the CVR number.
        if not CVRNumberToken.IsValue() then
            exit(false);
        ResponseCVRNumber := CVRNumberToken.AsValue().AsText();
        exit(true);
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        // A lookup returns a single company record (typically < 1 KB). 64 KB leaves ample headroom
        // while still rejecting abnormally large payloads from the unauthenticated service.
        exit(65536);
    end;

    local procedure GetHostFromUri(RequestUri: Text): Text
    var
        Uri: Codeunit Uri;
    begin
        // Return only the host so the CVR-number-bearing request URI is not emitted verbatim to telemetry.
        if not TryInitUri(Uri, RequestUri) then
            exit('');
        exit(Uri.GetHost());
    end;

    [TryFunction]
    local procedure TryInitUri(var Uri: Codeunit Uri; RequestUri: Text)
    begin
        Uri.Init(RequestUri);
    end;
}
