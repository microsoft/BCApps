namespace Microsoft.Integration.MDM;

using System.Azure.Identity;
using System.Environment;
using System.Security.Authentication;
using System.Reflection;
using System.Telemetry;

/// <summary>
/// Production transport: calls the source environment's ODataV4 web service with an app-only (client
/// credentials) token. Same-tenant by construction — the OAuth authority is derived from THIS environment's
/// Entra tenant, so there is no tenant-id setting to point the connection at another tenant. Tests never hit
/// this: they inject an in-process transport that calls the source API directly.
/// </summary>
codeunit 7247 "MDM Http Source Transport" implements "IMDM Source Transport"
{
    Access = Internal;

    var
        CachedToken: SecretText;
        TokenExpiresAt: DateTime;
        MaxRetriesValue: Integer;
        NotConfiguredErr: Label 'The cross-environment connection to the source is not configured yet.';
        NonSaaSErr: Label 'Cross-environment synchronization is only available in online environments.';
        NoTokenErr: Label 'Could not acquire an access token for the source environment. Check the client ID and secret.';
        SendFailedErr: Label 'The request to the source environment could not be sent. Check the source environment URL.';
        HttpErr: Label 'The source environment returned HTTP %1. %2', Comment = '%1 = HTTP status code, %2 = response detail';
        ServiceNameTok: Label 'MDMCrossEnvSource', Locked = true;
        ScopeTok: Label 'https://api.businesscentral.dynamics.com/.default', Locked = true;
        TokenEndpointTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true, Comment = '%1 = Entra tenant id';
        ActionUrlTok: Label '%1/ODataV4/%2_%3?company=%4', Locked = true, Comment = '%1 = base url, %2 = service, %3 = action, %4 = company';
        TelemetryCategoryTok: Label 'MDM Cross-Environment', Locked = true;
        TokenAcquiredAuditTxt: Label 'Acquired an application access token to read master data from source environment %1.', Comment = '%1 = source environment name';
        TokenFailedAuditTxt: Label 'Failed to acquire an application access token for source environment %1.', Comment = '%1 = source environment name';
        AccessDeniedAuditTxt: Label 'Source environment %1 denied the master data request (HTTP %2).', Comment = '%1 = source environment name, %2 = HTTP status code';
        RequestFailedTelemetryTxt: Label 'Cross-environment %1 request failed with HTTP %2.', Locked = true;

    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer): Text
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        Body.Add('tableId', TableId);
        Body.Add('fieldIds', FieldIds);
        Body.Add('selector', Selector);
        Body.Add('pageSize', PageSize);
        Body.WriteTo(BodyText);
        exit(InvokeAction('GetRecords', BodyText));
    end;

    procedure LastModifiedAtPerTable(TableIds: Text): Text
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        Body.Add('tableIds', TableIds);
        Body.WriteTo(BodyText);
        exit(InvokeAction('LastModifiedAtPerTable', BodyText));
    end;

    procedure GetCapabilities(): Text
    begin
        exit(InvokeAction('GetCapabilities', '{}'));
    end;

    local procedure InvokeAction(ActionName: Text; RequestBody: Text): Text
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        ResponseMessage: HttpResponseMessage;
        ResponseBodyText: Text;
        RetryAfter: Duration;
        Attempt: Integer;
    begin
        GetConfiguredSetup(MasterDataManagementSetup);
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            Error(NonSaaSErr);

        for Attempt := 0 to MaxRetries() do begin
            Send(MasterDataManagementSetup, ActionName, RequestBody, ResponseMessage);
            ResponseMessage.Content().ReadAs(ResponseBodyText);
            if ResponseMessage.IsSuccessStatusCode() then
                exit(UnwrapODataValue(ResponseBodyText));
            if not ShouldRetry(ResponseMessage, Attempt, RetryAfter) then begin
                LogRequestFailure(MasterDataManagementSetup, ActionName, ResponseMessage);
                Error(HttpErr, ResponseMessage.HttpStatusCode(), ResponseBodyText);
            end;
            Sleep(RetryAfter);
        end;
    end;

    local procedure LogRequestFailure(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text; var ResponseMessage: HttpResponseMessage)
    var
        AuditLog: Codeunit "Audit Log";
    begin
        // Operational telemetry: action + status only, never record data or credentials.
        Session.LogMessage('', StrSubstNo(RequestFailedTelemetryTxt, ActionName, ResponseMessage.HttpStatusCode()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        // Security audit: an authorization failure crossing the environment boundary.
        if ResponseMessage.HttpStatusCode() in [401, 403] then
            AuditLog.LogAuditMessage(StrSubstNo(AccessDeniedAuditTxt, MasterDataManagementSetup."Source Environment Name", ResponseMessage.HttpStatusCode()), SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
    end;

    local procedure Send(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text; RequestBody: Text; var ResponseMessage: HttpResponseMessage)
    var
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        RequestMessage.Method('POST');
        RequestMessage.SetRequestUri(BuildActionUrl(MasterDataManagementSetup, ActionName));
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/json');
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', GetBearerToken(MasterDataManagementSetup)));

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        RequestMessage.Content(HttpContent);

        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            Error(SendFailedErr);
    end;

    local procedure BuildActionUrl(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text): Text
    var
        BaseUrl: Text;
    begin
        BaseUrl := DelChr(MasterDataManagementSetup."Source Environment URL", '>', '/');
        exit(StrSubstNo(ActionUrlTok, BaseUrl, ServiceNameTok, ActionName, UriEncodeCompany(MasterDataManagementSetup."Source Company Name")));
    end;

    // The ODataV4 envelope for an action returning Text is { "@odata.context": "...", "value": "<inner json>" };
    // the source API's own JSON is that inner value. Fall back to the raw body if the shape is unexpected.
    local procedure UnwrapODataValue(ResponseBody: Text): Text
    var
        Envelope: JsonObject;
        ValueToken: JsonToken;
    begin
        if Envelope.ReadFrom(ResponseBody) then
            if Envelope.Get('value', ValueToken) then
                if ValueToken.IsValue() then
                    exit(ValueToken.AsValue().AsText());
        exit(ResponseBody);
    end;

    local procedure GetBearerToken(var MasterDataManagementSetup: Record "Master Data Management Setup"): SecretText
    begin
        // Cached in-instance for the lifetime of a single sync run (the paging loop reuses this transport).
        if (TokenExpiresAt <> 0DT) and (TokenExpiresAt > CurrentDateTime()) then
            exit(CachedToken);
        CachedToken := AcquireToken(MasterDataManagementSetup);
        TokenExpiresAt := CurrentDateTime() + (3500 * 1000); // refresh a little before the ~1h token lifetime
        exit(CachedToken);
    end;

    [NonDebuggable]
    local procedure AcquireToken(var MasterDataManagementSetup: Record "Master Data Management Setup") Token: SecretText
    var
        OAuth2: Codeunit OAuth2;
        AzureADTenant: Codeunit "Azure AD Tenant";
        AuditLog: Codeunit "Audit Log";
        Scopes: List of [Text];
        TokenEndpoint: Text;
    begin
        Scopes.Add(ScopeTok);
        TokenEndpoint := StrSubstNo(TokenEndpointTok, AzureADTenant.GetAadTenantId());
        OAuth2.AcquireTokenWithClientCredentials(
            MasterDataManagementSetup."Source OAuth Client Id",
            MasterDataManagementSetup.GetSourceClientSecret(),
            TokenEndpoint, '', Scopes, Token);
        if Token.IsEmpty() then begin
            AuditLog.LogAuditMessage(StrSubstNo(TokenFailedAuditTxt, MasterDataManagementSetup."Source Environment Name"), SecurityOperationResult::Failure, AuditCategory::Authentication, 4, 0);
            Error(NoTokenErr);
        end;
        AuditLog.LogAuditMessage(StrSubstNo(TokenAcquiredAuditTxt, MasterDataManagementSetup."Source Environment Name"), SecurityOperationResult::Success, AuditCategory::Authentication, 4, 0);
    end;

    local procedure GetConfiguredSetup(var MasterDataManagementSetup: Record "Master Data Management Setup")
    begin
        if not MasterDataManagementSetup.Get() then
            Error(NotConfiguredErr);
        if not MasterDataManagementSetup.IsCrossEnvConnectionConfigured() then
            Error(NotConfiguredErr);
    end;

    local procedure ShouldRetry(var ResponseMessage: HttpResponseMessage; Attempt: Integer; var RetryAfter: Duration): Boolean
    begin
        if Attempt >= MaxRetries() then
            exit(false);
        if not (ResponseMessage.HttpStatusCode() in [429, 503]) then
            exit(false);
        RetryAfter := RetryAfterDuration(ResponseMessage);
        exit(true);
    end;

    local procedure RetryAfterDuration(var ResponseMessage: HttpResponseMessage) RetryAfter: Duration
    var
        ResponseHeaders: HttpHeaders;
        Values: array[10] of Text;
        Seconds: Integer;
    begin
        RetryAfter := 5000; // default backoff when the source gives no Retry-After
        ResponseHeaders := ResponseMessage.Headers();
        if ResponseHeaders.GetValues('Retry-After', Values) then
            if Evaluate(Seconds, Values[1]) then
                if Seconds > 0 then
                    RetryAfter := Seconds * 1000;
        if RetryAfter > 60000 then
            RetryAfter := 60000; // never wait more than a minute inside a job
    end;

    local procedure UriEncodeCompany(CompanyNameText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.UrlEncode(CompanyNameText));
    end;

    local procedure MaxRetries(): Integer
    begin
        if MaxRetriesValue = 0 then
            MaxRetriesValue := 2;
        exit(MaxRetriesValue);
    end;
}
