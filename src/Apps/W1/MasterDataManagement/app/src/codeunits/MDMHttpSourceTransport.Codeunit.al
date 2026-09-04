namespace Microsoft.Integration.MDM;

using System.Azure.Identity;
using System.Environment;
using System.Reflection;
using System.Security.Authentication;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Production transport: calls the source environment's ODataV4 web service with an app-only (client
/// credentials) token. Same-tenant by construction — the OAuth authority (tenant + ring) is derived from THIS
/// environment, so there is no tenant-id setting to point the connection at another tenant; production and the
/// TIE/PPE ring use different Entra authorities and Business Central resource audiences. Tests never hit
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
        OpenSetupActionTxt: Label 'Open Master Data Management Setup';
        NonSaaSErr: Label 'Cross-environment synchronization is only available in online environments.';
        NoTokenErr: Label 'Could not acquire an access token for the source environment. Check the client ID and secret.';
        SendFailedErr: Label 'The request to the source environment could not be sent. Check the source environment URL.';
        InvalidSourceUrlErr: Label 'The source environment URL is not a valid Business Central endpoint.';
        InvalidSourceUrlAuditTxt: Label 'Blocked a cross-environment request: the configured source environment URL host ''%1'' is not a valid Business Central endpoint.', Comment = '%1 = the rejected host';
        HttpErr: Label 'The source environment returned HTTP %1.', Comment = '%1 = HTTP status code';
        ServiceNameTok: Label 'MDMCrossEnvSource', Locked = true;
        ScopeTok: Label 'https://api.businesscentral.dynamics.com/.default', Locked = true;
        ScopePPETok: Label 'https://api.businesscentral.dynamics-tie.com/.default', Locked = true;
        TokenEndpointTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true, Comment = '%1 = Entra tenant id';
        TokenEndpointPPETok: Label 'https://login.windows-ppe.net/%1/oauth2/v2.0/token', Locked = true, Comment = '%1 = Entra tenant id';
        SourceHostProdTok: Label 'api.businesscentral.dynamics.com', Locked = true;
        SourceHostPPETok: Label 'api.businesscentral.dynamics-tie.com', Locked = true;
        ActionUrlTok: Label '%1/ODataV4/%2_%3?company=%4', Locked = true, Comment = '%1 = base url, %2 = service, %3 = action, %4 = company';
        BaseUrlTok: Label 'https://%1/v2.0/%2/%3', Locked = true, Comment = '%1 = api host, %2 = Entra tenant id, %3 = source environment name';
        TelemetryCategoryTok: Label 'MDM Cross-Environment', Locked = true;
        TokenAcquiredAuditTxt: Label 'Acquired an application access token to read master data from source environment %1.', Comment = '%1 = source environment name';
        TokenFailedAuditTxt: Label 'Failed to acquire an application access token for source environment %1.', Comment = '%1 = source environment name';
        AccessDeniedAuditTxt: Label 'Source environment %1 denied the master data request (HTTP %2).', Comment = '%1 = source environment name, %2 = HTTP status code';
        RequestFailedTelemetryTxt: Label 'Cross-environment %1 request failed with HTTP %2.', Locked = true, Comment = '%1 = action name, %2 = HTTP status code';
        TransportFailedTelemetryTxt: Label 'Cross-environment %1 request could not be sent to the source environment.', Locked = true, Comment = '%1 = action name';

    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer; Filter: Text): Text
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        Body.Add('tableId', TableId);
        Body.Add('fieldIds', FieldIds);
        Body.Add('selector', Selector);
        Body.Add('pageSize', PageSize);
        Body.Add('filter', Filter);
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
        PrivacyNotice: Codeunit "MDM Privacy Notice";
        ResponseMessage: HttpResponseMessage;
        ResponseBodyText: Text;
        RetryAfter: Duration;
        Attempt: Integer;
    begin
        GetConfiguredSetup(MasterDataManagementSetup);
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            Error(NonSaaSErr);
        PrivacyNotice.CheckApproved();

        for Attempt := 0 to MaxRetries() do
            if TrySend(MasterDataManagementSetup, ActionName, RequestBody, ResponseMessage) then begin
                ResponseMessage.Content().ReadAs(ResponseBodyText);
                if ResponseMessage.IsSuccessStatusCode() then
                    exit(UnwrapODataValue(ResponseBodyText));
                if not ShouldRetry(ResponseMessage, Attempt, RetryAfter) then begin
                    LogRequestFailure(MasterDataManagementSetup, ActionName, ResponseMessage);
                    Error(SetupNavigationError(StrSubstNo(HttpErr, ResponseMessage.HttpStatusCode())));
                end;
                Sleep(RetryAfter);
            end else begin
                // Transport-level failure (dropped connection, timeout): these reads are idempotent, so retry while
                // attempts remain instead of aborting the sync run on a transient network blip.
                if Attempt >= MaxRetries() then begin
                    LogTransportFailure(ActionName);
                    Error(SetupNavigationError(SendFailedErr));
                end;
                Sleep(TransportRetryBackoff());
            end;
    end;

    local procedure LogRequestFailure(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text; var ResponseMessage: HttpResponseMessage)
    var
        AuditLog: Codeunit "Audit Log";
        Dimensions: Dictionary of [Text, Text];
    begin
        // The response body can echo source-environment record content, so it is never emitted to telemetry; only
        // the action and HTTP status (non-content diagnostics) are logged.
        Dimensions.Add('Category', TelemetryCategoryTok);
        Dimensions.Add('action', ActionName);
        Dimensions.Add('httpStatusCode', Format(ResponseMessage.HttpStatusCode()));
        Session.LogMessage('0000VAT', StrSubstNo(RequestFailedTelemetryTxt, ActionName, ResponseMessage.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        // Security audit: an authorization failure crossing the environment boundary.
        if ResponseMessage.HttpStatusCode() in [401, 403] then
            AuditLog.LogAuditMessage(StrSubstNo(AccessDeniedAuditTxt, MasterDataManagementSetup."Source Environment Name", ResponseMessage.HttpStatusCode()), SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
    end;

    local procedure LogTransportFailure(ActionName: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        // GetLastErrorText() can contain record keys or file names, so the raw error is never emitted to telemetry;
        // only the action is logged.
        Dimensions.Add('Category', TelemetryCategoryTok);
        Dimensions.Add('action', ActionName);
        Session.LogMessage('0000VAU', StrSubstNo(TransportFailedTelemetryTxt, ActionName), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    local procedure TrySend(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text; RequestBody: Text; var ResponseMessage: HttpResponseMessage): Boolean
    var
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        HttpClient.Timeout := 100000; // explicit 100s cap so a stalled connection can't hang a background sync run
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

        // A transport-level failure returns false so the caller can retry the read-only call.
        exit(HttpClient.Send(RequestMessage, ResponseMessage));
    end;

    local procedure BuildActionUrl(var MasterDataManagementSetup: Record "Master Data Management Setup"; ActionName: Text): Text
    var
        BaseUrl: Text;
    begin
        BaseUrl := DelChr(MasterDataManagementSetup."Source Environment URL", '>', '/');
        ValidateSourceHost(BaseUrl);
        exit(StrSubstNo(ActionUrlTok, BaseUrl, ServiceNameTok, ActionName, UriEncodeCompany(MasterDataManagementSetup."Source Company Name")));
    end;

    // The source must be a Business Central SaaS endpoint over HTTPS. Validating the configured URL before the
    // bearer token is attached stops the setup field from redirecting the authenticated call to an arbitrary host (SSRF).
    local procedure ValidateSourceHost(BaseUrl: Text)
    var
        AuditLog: Codeunit "Audit Log";
        Uri: Codeunit Uri;
        Host: Text;
    begin
        // Only the standard Business Central API hosts are allowed - production and the TIE ring. Embed/ISV
        // deployments must be on a normal cluster that serves api.businesscentral.dynamics.com. Matching the host
        // EXACTLY (not a dynamics.com suffix) blocks SSRF via look-alike hosts; a malformed URL surfaces the
        // actionable setup error instead of the URI parser's raw exception.
        if TryInitUri(Uri, BaseUrl) then begin
            Host := LowerCase(Uri.GetHost());
            if (Uri.GetScheme() = 'https') and ((Host = SourceHostProdTok) or (Host = SourceHostPPETok)) then
                exit;
        end;
        AuditLog.LogAuditMessage(StrSubstNo(InvalidSourceUrlAuditTxt, Host), SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0);
        Error(SetupNavigationError(InvalidSourceUrlErr));
    end;

    [TryFunction]
    local procedure TryInitUri(var Uri: Codeunit Uri; BaseUrl: Text)
    begin
        Uri.Init(BaseUrl);
    end;

    // Test seam: exercise the source-host allow-list without a live environment or the SaaS gate.
    internal procedure ValidateSourceHostUrl(BaseUrl: Text)
    begin
        ValidateSourceHost(BaseUrl);
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

    // Test seam: exercise OData envelope unwrapping without a live transport.
    internal procedure UnwrapODataValueForTest(ResponseBody: Text): Text
    begin
        exit(UnwrapODataValue(ResponseBody));
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
        Scopes.Add(GetBcResourceScope());
        TokenEndpoint := StrSubstNo(GetTokenEndpointTemplate(), AzureADTenant.GetAadTenantId());
        // Prefer a cached/refreshed token (no round-trip when a valid one exists); fall back to a fresh
        // client-credentials grant if the cache misses, errors, or returns an empty token.
        if not TryAcquireTokenFromCache(MasterDataManagementSetup, TokenEndpoint, Scopes, Token) then
            Clear(Token);
        if Token.IsEmpty() then
            if not OAuth2.AcquireTokenWithClientCredentials(
                MasterDataManagementSetup."Source OAuth Client Id",
                MasterDataManagementSetup.GetSourceClientSecret(),
                TokenEndpoint, '', Scopes, Token) or Token.IsEmpty()
            then begin
                AuditLog.LogAuditMessage(StrSubstNo(TokenFailedAuditTxt, MasterDataManagementSetup."Source Environment Name"), SecurityOperationResult::Failure, AuditCategory::Authentication, 4, 0);
                Error(SetupNavigationError(NoTokenErr));
            end;
        AuditLog.LogAuditMessage(StrSubstNo(TokenAcquiredAuditTxt, MasterDataManagementSetup."Source Environment Name"), SecurityOperationResult::Success, AuditCategory::Authentication, 4, 0);
    end;

    // Reuses a token from the platform (MSAL) cache when one is valid; a cache miss or error is treated as "no token"
    // so the caller falls back to a fresh client-credentials grant.
    [TryFunction]
    [NonDebuggable]
    local procedure TryAcquireTokenFromCache(MasterDataManagementSetup: Record "Master Data Management Setup"; TokenEndpoint: Text; Scopes: List of [Text]; var Token: SecretText)
    var
        OAuth2: Codeunit OAuth2;
    begin
        if not OAuth2.AcquireAuthorizationCodeTokenFromCache(MasterDataManagementSetup."Source OAuth Client Id", MasterDataManagementSetup.GetSourceClientSecret(), '', TokenEndpoint, Scopes, Token) then
            Clear(Token);
    end;

    // Production and the TIE/PPE ring use different Entra authorities and BC resource audiences. Cross-env is same
    // tenant and same ring, so detect the ring from this environment's web URL and mint the token for the right one.
    local procedure IsPPE(): Boolean
    begin
        exit(StrPos(LowerCase(GetUrl(ClientType::Web)), 'businesscentral.dynamics-tie.com') <> 0);
    end;

    local procedure GetBcResourceScope(): Text
    begin
        if IsPPE() then
            exit(ScopePPETok);
        exit(ScopeTok);
    end;

    local procedure GetTokenEndpointTemplate(): Text
    begin
        if IsPPE() then
            exit(TokenEndpointPPETok);
        exit(TokenEndpointTok);
    end;

    // Same-tenant, same-ring: the source web-service base URL is fully derivable from the source environment name,
    // this environment's tenant, and the ring host, so the wizard constructs it instead of asking for a free-text URL.
    internal procedure BuildSourceApiBaseUrl(EnvironmentName: Text): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(StrSubstNo(BaseUrlTok, GetSourceApiHost(), AzureADTenant.GetAadTenantId(), EnvironmentName));
    end;

    local procedure GetSourceApiHost(): Text
    begin
        if IsPPE() then
            exit(SourceHostPPETok);
        exit(SourceHostProdTok);
    end;

    local procedure GetConfiguredSetup(var MasterDataManagementSetup: Record "Master Data Management Setup")
    begin
        if not MasterDataManagementSetup.Get() then
            Error(SetupNavigationError(NotConfiguredErr));
        if not MasterDataManagementSetup.IsCrossEnvConnectionConfigured() then
            Error(SetupNavigationError(NotConfiguredErr));
    end;

    local procedure SetupNavigationError(MessageText: Text): ErrorInfo
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MessageText;
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        // The remedy is always the setup page, even before the record exists; only RecordId needs an existing record.
        ErrInfo.PageNo := Page::"Master Data Management Setup";
        ErrInfo.AddNavigationAction(OpenSetupActionTxt);
        if MasterDataManagementSetup.Get() then
            ErrInfo.RecordId := MasterDataManagementSetup.RecordId();
        exit(ErrInfo);
    end;

    local procedure ShouldRetry(var ResponseMessage: HttpResponseMessage; Attempt: Integer; var RetryAfter: Duration): Boolean
    begin
        if Attempt >= MaxRetries() then
            exit(false);
        if not (ResponseMessage.HttpStatusCode() in [408, 429, 502, 503, 504]) then
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

    local procedure TransportRetryBackoff(): Duration
    begin
        exit(5000); // fixed backoff for transport failures, where no Retry-After header is available
    end;
}
