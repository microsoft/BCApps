// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.Authentication;
using System.Telemetry;

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
    local procedure TryGetJsonBoolean(JsonValue: JsonValue; var Value: Boolean)
    begin
        Value := JsonValue.AsBoolean();
    end;

    local procedure GetExpenseAgentBaseUrl(var BaseUrl: SecretText): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretName: Text;
    begin
        SecretName := ProdBaseUrlSecretNameTok;
        if ExpenseAgentSetup.Get() then
            if ExpenseAgentSetup."Use Canary Endpoint" then
                SecretName := CanaryBaseUrlSecretNameTok;
        exit(AzureKeyVault.GetAzureKeyVaultSecret(SecretName, BaseUrl));
    end;

    local procedure GetProductionBaseUrl(var BaseUrl: SecretText): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        exit(AzureKeyVault.GetAzureKeyVaultSecret(ProdBaseUrlSecretNameTok, BaseUrl));
    end;

    [NonDebuggable]
    procedure RegisterErpConfiguration(): Boolean
    begin
        exit(SendErpConfigRequest('POST', ErpRegistrationFailedErr));
    end;

    [NonDebuggable]
    procedure UnregisterErpConfiguration(): Boolean
    begin
        exit(SendErpConfigRequest('DELETE', ErpUnregistrationFailedErr));
    end;

    [NonDebuggable]
    local procedure SendErpConfigRequest(HttpMethod: Text; FailureError: Text): Boolean
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
        if not GetExpenseAgentBaseUrl(BaseUrl) then begin
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
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
        OAuthScope: Text;
        OAuthScopePatternLbl: Label 'api://%1/', Locked = true;
    begin
        OAuthScope := StrSubstNo(OAuthScopePatternLbl, ExpenseAgentAPIValidation.GetAadAppId());
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
