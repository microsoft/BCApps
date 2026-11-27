// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System;
using System.Apps;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.AccessControl;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Telemetry;
using System.Utilities;

codeunit 6941 "EA Http Client"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SubmitExpenseEndpointLbl: Label '/api/v1.0/expenses/process', Locked = true;
        RegisterErpConfigEndpointLbl: Label '/api/v1.0/erp/config', Locked = true;
        ContentTypeLbl: Label 'multipart/form-data; boundary=%1', Locked = true;
        ErpRegistrationFailedErr: Label 'Failed to register environment with Expense Agent service. Please try again or contact support.';
        ErpUnregistrationFailedErr: Label 'Failed to unregister environment from Expense Agent service. Please try again or contact support.';
        CouldNotGetAccessTokenErr: Label 'Could not acquire access token for Expense Agent service.';
        AttachmentDispositionLbl: Label 'Content-Disposition: form-data; name="attachments"; filename="%1"', Locked = true;
        AttachmentContentTypeLbl: Label 'Content-Type: %1', Locked = true;
        FormFieldDispositionLbl: Label 'Content-Disposition: form-data; name="%1"', Locked = true;
        TextPlainUtf8Lbl: Label 'text/plain; charset=utf-8', Locked = true;
        SubmitExpenseSuccessTxt: Label 'Successfully submitted expense with attachments.', Locked = true;
        SubmitExpenseFailedTxt: Label 'Failed to submit expense with attachments.', Locked = true;
        OpenReportReminderEndpointLbl: Label '/api/v1.0/notifications/open-reports-reminder', Locked = true;
        OpenReportReminderSuccessTxt: Label 'Successfully sent open report reminder notification.', Locked = true;
        OpenReportReminderFailedTxt: Label 'Failed to send open report reminder notification.', Locked = true;
        ReimbursementEndpointLbl: Label '/api/v1.0/notifications/reimbursement', Locked = true;
        ReimbursementSuccessTxt: Label 'Successfully sent reimbursement notification.', Locked = true;
        ReimbursementFailedTxt: Label 'Failed to send reimbursement notification.', Locked = true;
        WelcomeEndpointLbl: Label '/api/v1.0/notifications/welcome', Locked = true;
        WelcomeSuccessTxt: Label 'Successfully sent welcome notification.', Locked = true;
        WelcomeFailedTxt: Label 'Failed to send welcome notification.', Locked = true;
        CorrelationIdHeaderLbl: Label 'X-Correlation-Id', Locked = true;
        CorrelationIdDimensionLbl: Label 'CorrelationId', Locked = true;
        ErpConfigRegisteredTxt: Label 'Successfully registered ERP configuration.', Locked = true;
        ErpConfigUnregisteredTxt: Label 'Successfully unregistered ERP configuration.', Locked = true;
        ErpConfigRequestFailedTxt: Label 'ERP configuration request failed. Method: %1', Locked = true;
        AccessTokenAcquiredTxt: Label 'Successfully acquired access token.', Locked = true;
        AccessTokenFailedTxt: Label 'Failed to acquire access token.', Locked = true;
        CanaryAllowlistEndpointTok: Label '/api/v1.0/canary/allowlist', Locked = true;
        ProdBaseUrlSecretNameTok: Label 'EABaseUrl', Locked = true;
        CanaryBaseUrlSecretNameTok: Label 'EABaseUrlCanary', Locked = true;
        ExpenseAgentSetupMissingTxt: Label 'Expense Agent setup is missing. The service request was not sent.', Locked = true;
        ExpenseAppBaseUrlOnPremTxt: Label 'http://localhost:5173/', Locked = true;
        ExpenseAppBaseUrlProdTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2365219', Locked = true;
        ExpenseAppBaseUrlTieTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2365220', Locked = true;
        ErpScopeHeaderTok: Label 'X-ERP-Scope', Locked = true;
        ErpScopeNamespaceHexTok: Label '7d8f2d5b0e565f2d9b396ce7f2f54844', Locked = true;
        ErpScopeErpCodeTok: Label 'business-central', Locked = true;
        ErpScopeTenantIdTok: Label 'tenant_id', Locked = true;
        ErpScopeEnvironmentNameTok: Label 'environment_name', Locked = true;
        ErpScopeCompanyIdTok: Label 'company_id', Locked = true;
        ErpScopeIdentityMissingErr: Label 'The request to the Expense Agent service was blocked because the company scope could not be calculated: the %1 value is missing. Make sure the environment is connected to Microsoft Entra ID and that you are working in an existing company, and then try again.', Comment = '%1 = name of the missing identity value, for example tenant_id, environment_name or company_id';
        ErpScopeInvalidTextErr: Label 'The request to the Expense Agent service was blocked because the company scope could not be calculated: an identity value contains invalid characters.';

    internal procedure GetExpenseAppBaseUrl(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
        URLHelper: Codeunit "URL Helper";
    begin
        if EnvironmentInfo.IsOnPrem() then
            exit(ExpenseAppBaseUrlOnPremTxt);
        if not EnvironmentInfo.IsSaaSInfrastructure() then
            exit('');
        if URLHelper.IsTIE() or URLHelper.IsPPE() then
            exit(ExpenseAppBaseUrlTieTxt);

        exit(ExpenseAppBaseUrlProdTxt);
    end;

    [NonDebuggable]
    procedure SubmitExpenseWithAttachments(ConversationId: Text; Context: Text; OnBehalfUser: Text; var TempAttachment: Record "EA Email Attachment" temporary): Boolean
    var
        TempContentBuffer: Record "EA Email Attachment" temporary;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        BodyOutStream: OutStream;
        BodyInStream: InStream;
        TelemetryDimensions: Dictionary of [Text, Text];
        Url: Text;
        Boundary: Text;
        BaseUrl: SecretText;
        IsSuccess: Boolean;
    begin
        if not GetExpenseAgentBaseUrl(BaseUrl) then
            exit(false);
        Url := BaseUrl.Unwrap() + SubmitExpenseEndpointLbl;

        // Generate a unique boundary for this request
        Boundary := GenerateBoundary();

        // Build multipart/form-data body with attachments into a temporary blob
        TempContentBuffer."Entry No." := 1;
        TempContentBuffer.Insert();

        // Write the multipart body to the blob.
        // IMPORTANT: pass TextEncoding::UTF8 explicitly. The BLOB stream default is
        // TextEncoding::MSDos (OEM code page), which silently best-fit-encodes
        // characters like €, •, ° and Danish ø/å/æ to nonsense bytes.
        TempContentBuffer.Content.CreateOutStream(BodyOutStream, TextEncoding::UTF8);
        BuildMultipartFormDataWithAttachments(ConversationId, Context, TempAttachment, Boundary, BodyOutStream);
        TempContentBuffer.Modify(true);

        // Create input stream from the blob and set HTTP content.
        // UTF-8 here too for symmetry; HttpContent.WriteFrom reads raw bytes,
        // but keeping the encoding consistent avoids surprises if the read path changes.
        TempContentBuffer.CalcFields(Content);
        TempContentBuffer.Content.CreateInStream(BodyInStream, TextEncoding::UTF8);
        Content.WriteFrom(BodyInStream);

        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', StrSubstNo(ContentTypeLbl, Boundary));

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;

        // Add Accept header
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('On-Behalf-Of', OnBehalfUser);
        AddErpScopeHeader(Headers);
        AddAuthHeaders(Headers);

        IsSuccess := Client.Send(RequestMessage, ResponseMessage);

        if not IsSuccess then begin
            // Transport-level failure: no HTTP response was received. A last-error call
            // stack is meaningful here, but HTTP status/reason are not available.
            TelemetryDimensions.Add('Endpoint', SubmitExpenseEndpointLbl);
            TelemetryDimensions.Add('SendFailure', 'true');
            TelemetryDimensions.Add('AttachmentCount', Format(TempAttachment.Count()));
            FeatureTelemetry.LogError('0000RIB', ExpenseAgentSetup.GetFeatureName(), SubmitExpenseFailedTxt, SubmitExpenseFailedTxt, GetLastErrorCallStack(), TelemetryDimensions);
            exit(false);
        end;

        if ResponseMessage.IsSuccessStatusCode() then begin
            FeatureTelemetry.LogUsage('0000RIF', ExpenseAgentSetup.GetFeatureName(), SubmitExpenseSuccessTxt);
            exit(true);
        end;

        // HTTP error response: no AL error was raised, so omit the (unrelated) call
        // stack and capture the HTTP status/reason instead.
        TelemetryDimensions.Add('Endpoint', SubmitExpenseEndpointLbl);
        TelemetryDimensions.Add('SendFailure', 'false');
        TelemetryDimensions.Add('HttpStatusCode', Format(ResponseMessage.HttpStatusCode()));
        TelemetryDimensions.Add('ReasonPhrase', ResponseMessage.ReasonPhrase());
        TelemetryDimensions.Add('AttachmentCount', Format(TempAttachment.Count()));
        FeatureTelemetry.LogError('0000RIB', ExpenseAgentSetup.GetFeatureName(), SubmitExpenseFailedTxt, SubmitExpenseFailedTxt, '', TelemetryDimensions);
        exit(false);
    end;

    [NonDebuggable]
    procedure SendOpenReportReminderNotification(OnBehalfUser: Text): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        TelemetryDimensions: Dictionary of [Text, Text];
        CorrelationId: Guid;
        Url: Text;
        BaseUrl: SecretText;
        IsSuccess: Boolean;
    begin
        if not GetExpenseAgentBaseUrl(BaseUrl) then
            exit(false);
        Url := BaseUrl.Unwrap() + OpenReportReminderEndpointLbl;

        CorrelationId := CreateGuid();

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Url);

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('On-Behalf-Of', OnBehalfUser);
        AddErpScopeHeader(Headers);
        AddCorrelationHeader(Headers, CorrelationId);
        AddAuthHeaders(Headers);

        IsSuccess := Client.Send(RequestMessage, ResponseMessage);

        if IsSuccess then
            IsSuccess := ResponseMessage.IsSuccessStatusCode();

        TelemetryDimensions.Add(CorrelationIdDimensionLbl, LowercaseGuid(CorrelationId));
        if IsSuccess then
            FeatureTelemetry.LogUsage('0000SJK', ExpenseAgentSetup.GetFeatureName(), OpenReportReminderSuccessTxt, TelemetryDimensions)
        else
            FeatureTelemetry.LogError('0000SJJ', ExpenseAgentSetup.GetFeatureName(), OpenReportReminderFailedTxt, OpenReportReminderFailedTxt, '', TelemetryDimensions);

        exit(IsSuccess);
    end;

    [NonDebuggable]
    procedure SendReimbursementNotification(OnBehalfUser: Text; PostedExpenseReportSystemId: Guid): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        TelemetryDimensions: Dictionary of [Text, Text];
        CorrelationId: Guid;
        JsonBody: Text;
        Url: Text;
        BaseUrl: SecretText;
        IsSuccess: Boolean;
    begin
        if not GetExpenseAgentBaseUrl(BaseUrl) then
            exit(false);

        Url := BaseUrl.Unwrap() + ReimbursementEndpointLbl;

        CorrelationId := CreateGuid();
        JsonBody := BuildReimbursementJson(PostedExpenseReportSystemId);

        Content.WriteFrom(JsonBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('On-Behalf-Of', OnBehalfUser);
        AddErpScopeHeader(Headers);
        AddCorrelationHeader(Headers, CorrelationId);
        AddAuthHeaders(Headers);

        IsSuccess := Client.Send(RequestMessage, ResponseMessage);

        if IsSuccess then
            IsSuccess := ResponseMessage.IsSuccessStatusCode();

        TelemetryDimensions.Add(CorrelationIdDimensionLbl, LowercaseGuid(CorrelationId));
        if IsSuccess then
            FeatureTelemetry.LogUsage('0000TIL', ExpenseAgentSetup.GetFeatureName(), ReimbursementSuccessTxt, TelemetryDimensions)
        else
            FeatureTelemetry.LogError('0000TIJ', ExpenseAgentSetup.GetFeatureName(), ReimbursementFailedTxt, ReimbursementFailedTxt, '', TelemetryDimensions);

        exit(IsSuccess);
    end;

    [NonDebuggable]
    procedure SendWelcomeEmailNotification(OnBehalfUser: Text; CorrelationId: Guid): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        TelemetryDimensions: Dictionary of [Text, Text];
        Url: Text;
        BaseUrl: SecretText;
        IsSuccess: Boolean;
    begin
        if not GetExpenseAgentBaseUrl(BaseUrl) then
            exit(false);

        Url := BaseUrl.Unwrap() + WelcomeEndpointLbl;

        Content.WriteFrom('');
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('On-Behalf-Of', OnBehalfUser);
        AddErpScopeHeader(Headers);
        AddCorrelationHeader(Headers, CorrelationId);
        AddAuthHeaders(Headers);

        IsSuccess := Client.Send(RequestMessage, ResponseMessage);

        if IsSuccess then
            IsSuccess := ResponseMessage.IsSuccessStatusCode();

        TelemetryDimensions.Add(CorrelationIdDimensionLbl, LowercaseGuid(CorrelationId));
        if IsSuccess then
            FeatureTelemetry.LogUsage('0000TIM', ExpenseAgentSetup.GetFeatureName(), WelcomeSuccessTxt, TelemetryDimensions)
        else
            FeatureTelemetry.LogError('0000TIK', ExpenseAgentSetup.GetFeatureName(), WelcomeFailedTxt, WelcomeFailedTxt, '', TelemetryDimensions);

        exit(IsSuccess);
    end;

    local procedure BuildReimbursementJson(PostedExpenseReportSystemId: Guid): Text
    var
        JsonObj: JsonObject;
        JsonText: Text;
    begin
        JsonObj.Add('posted_expense_report_id', LowercaseGuid(PostedExpenseReportSystemId));
        JsonObj.WriteTo(JsonText);

        exit(JsonText);
    end;

    local procedure LowercaseGuid(SystemId: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(SystemId), '=', '{}')));
    end;

    local procedure GenerateBoundary(): Text
    var
        BoundaryGuid: Guid;
    begin
        // Generate a unique boundary using a GUID (remove braces and dashes for cleaner format)
        BoundaryGuid := CreateGuid();
        exit('----Boundary' + DelChr(Format(BoundaryGuid), '=', '{}'));
    end;

    local procedure BuildMultipartFormDataWithAttachments(ConversationId: Text; Context: Text; var TempAttachment: Record "EA Email Attachment" temporary; Boundary: Text; var ContentOutStream: OutStream)
    var
        AttachmentInStream: InStream;
    begin
        // Add conversation_id field
        WriteFormField(ContentOutStream, Boundary, 'conversation_id', ConversationId);

        // Add context field. Tag it as UTF-8 so the receiver does not guess
        // a single-byte code page (default for form-data text parts is ambiguous).
        WriteFormField(ContentOutStream, Boundary, 'context', Context, TextPlainUtf8Lbl);

        // Add attachments with actual binary content
        if TempAttachment.FindSet() then
            repeat
                TempAttachment.CalcFields(Content);
                WriteTextToStream(ContentOutStream, StrSubstNo('--%1', Boundary));
                WriteTextToStream(ContentOutStream, GetCRLF());
                WriteTextToStream(ContentOutStream, StrSubstNo(AttachmentDispositionLbl, TempAttachment.FileName));
                WriteTextToStream(ContentOutStream, GetCRLF());
                WriteTextToStream(ContentOutStream, StrSubstNo(AttachmentContentTypeLbl, TempAttachment.ContentType));
                WriteTextToStream(ContentOutStream, GetCRLF());
                WriteTextToStream(ContentOutStream, GetCRLF());

                // Write actual binary content from attachment
                TempAttachment.Content.CreateInStream(AttachmentInStream);
                CopyStream(ContentOutStream, AttachmentInStream);

                WriteTextToStream(ContentOutStream, GetCRLF());
            until TempAttachment.Next() = 0;

        // Add closing boundary
        WriteTextToStream(ContentOutStream, StrSubstNo('--%1--', Boundary));
        WriteTextToStream(ContentOutStream, GetCRLF());
    end;

    local procedure WriteFormField(var ContentOutStream: OutStream; Boundary: Text; FieldName: Text; FieldValue: Text)
    begin
        WriteFormField(ContentOutStream, Boundary, FieldName, FieldValue, '');
    end;

    local procedure WriteFormField(var ContentOutStream: OutStream; Boundary: Text; FieldName: Text; FieldValue: Text; ContentType: Text)
    begin
        WriteTextToStream(ContentOutStream, StrSubstNo('--%1', Boundary));
        WriteTextToStream(ContentOutStream, GetCRLF());
        WriteTextToStream(ContentOutStream, StrSubstNo(FormFieldDispositionLbl, FieldName));
        WriteTextToStream(ContentOutStream, GetCRLF());
        if ContentType <> '' then begin
            WriteTextToStream(ContentOutStream, StrSubstNo(AttachmentContentTypeLbl, ContentType));
            WriteTextToStream(ContentOutStream, GetCRLF());
        end;
        WriteTextToStream(ContentOutStream, GetCRLF());
        WriteTextToStream(ContentOutStream, FieldValue);
        WriteTextToStream(ContentOutStream, GetCRLF());
    end;

    local procedure WriteTextToStream(var OutStream: OutStream; TextToWrite: Text)
    begin
        OutStream.WriteText(TextToWrite);
    end;

    local procedure GetCRLF(): Text
    var
        CRLF: Text;
    begin
        CRLF[1] := 13;  // CR (Carriage Return)
        CRLF[2] := 10;  // LF (Line Feed)
        exit(CRLF);
    end;

    internal procedure IsTenantOnCanaryAllowlist(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseJson: JsonObject;
        AllowedToken: JsonToken;
        ResponseText: Text;
        BaseUrl: SecretText;
        Allowed: Boolean;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(false);

        if not GetProductionBaseUrl(BaseUrl) then
            exit(false);

        Client.Timeout := 5000;

        RequestMessage.Method := 'GET';
        RequestMessage.SetSecretRequestUri(SecretStrSubstNo('%1' + CanaryAllowlistEndpointTok, BaseUrl));
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');

        // Use the non-throwing auth path to avoid block the wizard from opening.
        if not TryAddAuthHeaders(Headers) then
            exit(false);

        if not Client.Send(RequestMessage, ResponseMessage) then
            exit(false);
        if not ResponseMessage.IsSuccessStatusCode() then
            exit(false);
        ResponseMessage.Content.ReadAs(ResponseText);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if not ResponseJson.Get('allowed', AllowedToken) then
            exit(false);
        if not AllowedToken.IsValue() then
            exit(false);
        if not TryGetJsonBoolean(AllowedToken.AsValue(), Allowed) then
            exit(false);
        exit(Allowed);
    end;

    [TryFunction]
    internal procedure TryEnableHttpRequestForExpenseAgentApp()
    var
        ExtensionManagement: Codeunit "Extension Management";
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CallerModuleInfo);
        ExtensionManagement.ConfigureExtensionHttpClientRequestsAllowance(CallerModuleInfo.PackageId(), true);
    end;

    [TryFunction]
    local procedure TryGetJsonBoolean(JsonValue: JsonValue; var Value: Boolean)
    begin
        Value := JsonValue.AsBoolean();
    end;

    local procedure GetExpenseAgentBaseUrl(var BaseUrl: SecretText): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        Clear(BaseUrl);
        if not ExpenseAgentSetup.Get() then begin
            FeatureTelemetry.LogError('0000VGO', ExpenseAgentSetup.GetFeatureName(), 'Resolve service endpoint', ExpenseAgentSetupMissingTxt);
            exit(false);
        end;

        exit(GetExpenseAgentBaseUrl(ExpenseAgentSetup."Use Canary Endpoint", BaseUrl));
    end;

    local procedure GetExpenseAgentBaseUrl(UseCanaryEndpoint: Boolean; var BaseUrl: SecretText): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if UseCanaryEndpoint then
            exit(AzureKeyVault.GetAzureKeyVaultSecret(CanaryBaseUrlSecretNameTok, BaseUrl));

        exit(GetProductionBaseUrl(BaseUrl));
    end;

    local procedure GetProductionBaseUrl(var BaseUrl: SecretText): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        exit(AzureKeyVault.GetAzureKeyVaultSecret(ProdBaseUrlSecretNameTok, BaseUrl));
    end;

    [NonDebuggable]
    procedure RegisterErpConfiguration(UseCanaryEndpoint: Boolean): Boolean
    begin
        exit(SendErpConfigRequest('POST', ErpRegistrationFailedErr, UseCanaryEndpoint));
    end;

    [NonDebuggable]
    procedure UnregisterErpConfiguration(UseCanaryEndpoint: Boolean): Boolean
    begin
        exit(SendErpConfigRequest('DELETE', ErpUnregistrationFailedErr, UseCanaryEndpoint));
    end;

    [NonDebuggable]
    local procedure SendErpConfigRequest(HttpMethod: Text; FailureError: Text; UseCanaryEndpoint: Boolean): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        JsonBody: Text;
        Url: Text;
        BaseUrl: SecretText;
    begin
        if not GetExpenseAgentBaseUrl(UseCanaryEndpoint, BaseUrl) then begin
            Message(FailureError);
            exit(false);
        end;

        Url := BaseUrl.Unwrap() + RegisterErpConfigEndpointLbl;

        // Build JSON body
        JsonBody := BuildErpConfigJson();

        // Set content
        Content.WriteFrom(JsonBody);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        // Configure request
        RequestMessage.Method := HttpMethod;
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;

        // Add headers
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        AddAuthHeaders(Headers);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            FeatureTelemetry.LogError('0000RIC', ExpenseAgentSetup.GetFeatureName(), StrSubstNo(ErpConfigRequestFailedTxt, HttpMethod), StrSubstNo(ErpConfigRequestFailedTxt, HttpMethod));
            Message(FailureError);
            exit(false);
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            FeatureTelemetry.LogError('0000RID', ExpenseAgentSetup.GetFeatureName(), StrSubstNo(ErpConfigRequestFailedTxt, HttpMethod), StrSubstNo(ErpConfigRequestFailedTxt, HttpMethod));
            Message(FailureError);
            exit(false);
        end;

        if HttpMethod = 'POST' then
            FeatureTelemetry.LogUsage('0000RIG', ExpenseAgentSetup.GetFeatureName(), ErpConfigRegisteredTxt)
        else
            FeatureTelemetry.LogUsage('0000RIH', ExpenseAgentSetup.GetFeatureName(), ErpConfigUnregisteredTxt);

        exit(true);
    end;

    local procedure BuildErpConfigJson(): Text
    var
        Company: Record Company;
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        RootJsonObj: JsonObject;
        ConfigDataJsonObj: JsonObject;
        JsonText: Text;
        IsEUDB: Boolean;
    begin
        // Get current company
        Company.Get(CompanyName());

        // Only the platform helper knows EUDB membership for SaaS environments;
        // on-prem/local dev defaults to false (mirrors FormatAzureRegion's SaaS gate).
        if EnvironmentInformation.IsSaaS() then
            IsEUDB := NavTenantSettingsHelper.GetAppServiceInEUDB();

        // Build configData object
        ConfigDataJsonObj.Add('tenant_id', AzureADTenant.GetAadTenantId());
        ConfigDataJsonObj.Add('environment_name', EnvironmentInformation.GetEnvironmentName());
        ConfigDataJsonObj.Add('company_id', Format(Company.Id, 0, 4));  // Format as lowercase without braces
        ConfigDataJsonObj.Add('location', FormatAzureRegion());
        ConfigDataJsonObj.Add('is_eudb', IsEUDB);

        // Build root object
        RootJsonObj.Add('erpCode', 'business-central');
        RootJsonObj.Add('configData', ConfigDataJsonObj);

        RootJsonObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure AddCorrelationHeader(var Headers: HttpHeaders; CorrelationId: Guid)
    begin
        if IsNullGuid(CorrelationId) then
            exit;
        Headers.Add(CorrelationIdHeaderLbl, LowercaseGuid(CorrelationId));
    end;

    local procedure AddErpScopeHeader(var Headers: HttpHeaders)
    var
        ScopeId: Text;
    begin
        // Calculated before the header is touched so that a missing identity blocks the request.
        ScopeId := GetCurrentCompanyScopeId();
        if Headers.Contains(ErpScopeHeaderTok) then
            Headers.Remove(ErpScopeHeaderTok);
        Headers.Add(ErpScopeHeaderTok, ScopeId);
    end;

    /// <summary>
    /// Calculates the Expense Agent scope of the current tenant, environment and company on the fly.
    /// Uses the same identity values that are sent when the environment is registered with the service.
    /// </summary>
    internal procedure GetCurrentCompanyScopeId(): Text
    var
        Company: Record Company;
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        CompanyId: Text;
    begin
        if Company.Get(CompanyName()) then
            if not IsNullGuid(Company.Id) then
                CompanyId := Format(Company.Id, 0, 4);

        exit(CalculateCompanyScopeId(AzureADTenant.GetAadTenantId(), EnvironmentInformation.GetEnvironmentName(), CompanyId));
    end;

    /// <summary>
    /// Calculates the scope as a name-based (version 5) UUID over the normalized, length-prefixed identity values.
    /// </summary>
    internal procedure CalculateCompanyScopeId(TenantId: Text; EnvironmentName: Text; CompanyId: Text): Text
    var
        ScopeName: Text;
    begin
        ScopeName := ErpScopeErpCodeTok +
            '|' + EncodeScopeComponent(NormalizeScopeComponent(TenantId, ErpScopeTenantIdTok)) +
            '|' + EncodeScopeComponent(NormalizeScopeComponent(EnvironmentName, ErpScopeEnvironmentNameTok)) +
            '|' + EncodeScopeComponent(CanonicalizeScopeCompanyId(NormalizeScopeComponent(CompanyId, ErpScopeCompanyIdTok)));

        exit(GenerateNameBasedUuid(ErpScopeNamespaceHexTok, ScopeName));
    end;

    local procedure NormalizeScopeComponent(Value: Text; ComponentName: Text): Text
    var
        Result: Text;
        WhitespaceCharacters: Text;
        WhitespaceCharacter: Char;
    begin
        WhitespaceCharacter := 9;
        WhitespaceCharacters := ' ' + Format(WhitespaceCharacter);
        WhitespaceCharacter := 10;
        WhitespaceCharacters += Format(WhitespaceCharacter);
        WhitespaceCharacter := 13;
        WhitespaceCharacters += Format(WhitespaceCharacter);
        Result := DelChr(Value, '<>', WhitespaceCharacters);
        if Result = '' then
            Error(ErpScopeIdentityMissingErr, ComponentName);
        exit(ConvertStr(Result, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'));
    end;

    local procedure CanonicalizeScopeCompanyId(NormalizedCompanyId: Text): Text
    var
        Remainder: Text;
        HexDigits: Text;
    begin
        Remainder := NormalizedCompanyId;
        while Remainder.StartsWith('urn:') or Remainder.StartsWith('uuid:') do
            if Remainder.StartsWith('urn:') then
                Remainder := CopyStr(Remainder, 5)
            else
                Remainder := CopyStr(Remainder, 6);

        Remainder := DelChr(Remainder, '<>', '{}');
        HexDigits := DelChr(Remainder, '=', '-');
        if (StrLen(HexDigits) <> 32) or (DelChr(HexDigits, '=', '0123456789abcdef') <> '') then
            exit(NormalizedCompanyId);

        exit(FormatHyphenatedUuid(HexDigits));
    end;

    local procedure EncodeScopeComponent(Value: Text): Text
    var
        Utf8Bytes: List of [Integer];
    begin
        AppendUtf8Bytes(Value, Utf8Bytes);
        exit(Format(Utf8Bytes.Count(), 0, 9) + ':' + Value);
    end;

    local procedure GenerateNameBasedUuid(NamespaceHex: Text; Name: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        NameBytes: List of [Integer];
        ByteValue: Byte;
        ByteCode: Integer;
        HashOutStream: OutStream;
        HashInStream: InStream;
        Hash: Text;
        Index: Integer;
    begin
        // RFC 4122 version 5: SHA-1 over the namespace bytes (network order) followed by the UTF-8 name.
        for Index := 1 to StrLen(NamespaceHex) div 2 do
            NameBytes.Add(HexToInteger(CopyStr(NamespaceHex, Index * 2 - 1, 2)));
        AppendUtf8Bytes(Name, NameBytes);

        TempBlob.CreateOutStream(HashOutStream);
        foreach ByteCode in NameBytes do begin
            ByteValue := ByteCode;
            HashOutStream.Write(ByteValue);
        end;
        TempBlob.CreateInStream(HashInStream);

        Hash := CopyStr(LowerCase(CryptographyManagement.GenerateHash(HashInStream, HashAlgorithmType::SHA1)), 1, 32);
        if StrLen(Hash) <> 32 then
            Error(ErpScopeInvalidTextErr);

        // Set the version (5) and the RFC 4122 variant bits.
        Hash := CopyStr(Hash, 1, 12) +
            IntegerToHex((HexToInteger(CopyStr(Hash, 13, 2)) mod 16) + 80) +
            CopyStr(Hash, 15, 2) +
            IntegerToHex((HexToInteger(CopyStr(Hash, 17, 2)) mod 64) + 128) +
            CopyStr(Hash, 19);

        exit(FormatHyphenatedUuid(Hash));
    end;

    local procedure AppendUtf8Bytes(Value: Text; var Utf8Bytes: List of [Integer])
    var
        CodePoint: Integer;
        LowSurrogate: Integer;
        Index: Integer;
    begin
        Index := 1;
        while Index <= StrLen(Value) do begin
            CodePoint := Value[Index];
            if (CodePoint >= 55296) and (CodePoint <= 56319) then begin
                if Index = StrLen(Value) then
                    Error(ErpScopeInvalidTextErr);
                LowSurrogate := Value[Index + 1];
                if (LowSurrogate < 56320) or (LowSurrogate > 57343) then
                    Error(ErpScopeInvalidTextErr);
                CodePoint := 65536 + (CodePoint - 55296) * 1024 + (LowSurrogate - 56320);
                Index += 1;
            end else
                if (CodePoint >= 56320) and (CodePoint <= 57343) then
                    Error(ErpScopeInvalidTextErr);

            AppendUtf8CodePoint(CodePoint, Utf8Bytes);
            Index += 1;
        end;
    end;

    local procedure AppendUtf8CodePoint(CodePoint: Integer; var Utf8Bytes: List of [Integer])
    begin
        case true of
            CodePoint < 128:
                AddByte(Utf8Bytes, CodePoint);
            CodePoint < 2048:
                begin
                    AddByte(Utf8Bytes, 192 + CodePoint div 64);
                    AddByte(Utf8Bytes, 128 + CodePoint mod 64);
                end;
            CodePoint < 65536:
                begin
                    AddByte(Utf8Bytes, 224 + CodePoint div 4096);
                    AddByte(Utf8Bytes, 128 + (CodePoint div 64) mod 64);
                    AddByte(Utf8Bytes, 128 + CodePoint mod 64);
                end;
            else begin
                AddByte(Utf8Bytes, 240 + CodePoint div 262144);
                AddByte(Utf8Bytes, 128 + (CodePoint div 4096) mod 64);
                AddByte(Utf8Bytes, 128 + (CodePoint div 64) mod 64);
                AddByte(Utf8Bytes, 128 + CodePoint mod 64);
            end;
        end;
    end;

    local procedure AddByte(var Bytes: List of [Integer]; Value: Integer)
    begin
        Bytes.Add(Value);
    end;

    local procedure HexToInteger(HexText: Text): Integer
    var
        Result: Integer;
        Index: Integer;
    begin
        for Index := 1 to StrLen(HexText) do
            Result := Result * 16 + StrPos('0123456789abcdef', LowerCase(CopyStr(HexText, Index, 1))) - 1;
        exit(Result);
    end;

    local procedure IntegerToHex(Value: Integer): Text
    var
        HexDigitsTok: Label '0123456789abcdef', Locked = true;
    begin
        exit(CopyStr(HexDigitsTok, Value div 16 + 1, 1) + CopyStr(HexDigitsTok, Value mod 16 + 1, 1));
    end;

    local procedure FormatHyphenatedUuid(HexDigits: Text): Text
    begin
        exit(CopyStr(HexDigits, 1, 8) + '-' + CopyStr(HexDigits, 9, 4) + '-' + CopyStr(HexDigits, 13, 4) + '-' + CopyStr(HexDigits, 17, 4) + '-' + CopyStr(HexDigits, 21, 12));
    end;

    [NonDebuggable]
    local procedure AddAuthHeaders(var Headers: HttpHeaders)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AccessToken: SecretText;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        if not TryGetAccessToken(AccessToken) then
            Error(CouldNotGetAccessTokenErr);
        if AccessToken.IsEmpty() then
            Error(CouldNotGetAccessTokenErr);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));
    end;

    [NonDebuggable]
    internal procedure IsCurrentUserGuestUser(): Boolean
    var
        User: Record User;
        EnvironmentInformation: Codeunit "Environment Information";
        TenantInformation: Codeunit "Tenant Information";
        OAuth2: Codeunit OAuth2;
        ObjectClaims: JsonObject;
        SingleClaim: JsonToken;
        AccessToken: SecretText;
        CurrentTenant: Guid;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit(false);

        // External users are stored in M365 with an authentication email that
        // looks like username_hometenant.onmicrosoft.com#EXT#@guesttenant.onmicrosoft.com;
        // the official recommendation is to check whether whe user is marked as usertype = Guest
        // instead, but to avoid a call to Graph, we limit the check to the email here.
        if User.ReadPermission() then
            if User.Get(UserSecurityId()) then
                if User."Authentication Email".Split('#EXT#@').Count > 1 then
                    exit(true);

        // We can also fall back to checking whether the current tenant is the
        // identity provider for the user tokens
        if Evaluate(CurrentTenant, TenantInformation.GetTenantId()) and not IsNullGuid(CurrentTenant) then
            if TryGetAccessToken(AccessToken) and not AccessToken.IsEmpty() then begin
                ObjectClaims := OAuth2.GetClaims(AccessToken);
                if ObjectClaims.Get('idp', SingleClaim) and SingleClaim.IsValue() then
                    if not SingleClaim.AsValue().IsNull() and not SingleClaim.AsValue().IsUndefined() then
                        if not LowerCase(SingleClaim.AsValue().AsText()).Contains(LowerCase(Format(CurrentTenant, 4))) then
                            // There is a idp claim and it does not match the current tenant,
                            // which is also indication of an external user
                            exit(true);
            end;

        exit(false);
    end;

    [TryFunction]
    local procedure TryAddAuthHeaders(var Headers: HttpHeaders)
    begin
        AddAuthHeaders(Headers);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryGetAccessToken(var AccessToken: SecretText)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
        OAuthScope: Text;
        OAuthScopePatternLbl: Label 'api://%1/', Locked = true;
    begin
        OAuthScope := StrSubstNo(OAuthScopePatternLbl, ExpenseAgentEntraApp.GetAadAppId());
        Scopes.Add(OAuthScope + 'Expenses.ReadWrite.All');
        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(OAuthScope, '', false);
        if AccessToken.IsEmpty() then begin
            if OAuth2.AcquireOnBehalfOfToken('', Scopes, AccessToken) then;
            if not AccessToken.IsEmpty() then
                FeatureTelemetry.LogUsage('0000UTW', ExpenseAgentSetup.GetFeatureName(), AccessTokenAcquiredTxt);
        end;
        if AccessToken.IsEmpty() then begin
            FeatureTelemetry.LogError('0000RIE', ExpenseAgentSetup.GetFeatureName(), AccessTokenFailedTxt, AccessTokenFailedTxt);
            Error(CouldNotGetAccessTokenErr);
        end;
    end;

    local procedure FormatAzureRegion(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        Location: Text;
    begin
        // Only get location from NavTenantSettingsHelper in SaaS environments
        if not EnvironmentInformation.IsSaaS() then
            exit('eastus');

        // Get location from NavTenantSettingsHelper (e.g., "Canada Central")
        Location := NavTenantSettingsHelper.GetAppServiceLocation();

        // Convert to lowercase and remove spaces (e.g., "canadacentral")
        Location := LowerCase(Location);
        Location := DelChr(Location, '=', ' ');

        exit(Location);
    end;
}
