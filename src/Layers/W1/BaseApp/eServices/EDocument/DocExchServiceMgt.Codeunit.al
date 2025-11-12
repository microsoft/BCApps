// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System;
using System.Azure.KeyVault;
using System.Environment;
using System.IO;
using System.Utilities;
using System.Xml;
using System.Integration;
using System.Security.Authentication;
using System.Telemetry;

codeunit 1410 "Doc. Exch. Service Mgt."
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;

    trigger OnRun()
    begin
    end;

    var
        TempBlobResponse: Codeunit "Temp Blob";
        TempBlobTrace: Codeunit "Temp Blob";
        Trace: Codeunit Trace;
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        DocExchLinks: Codeunit "Doc. Exch. Links";
        XMLDOMMgt: Codeunit "XML DOM Management";
        EnvironmentInfo: Codeunit "Environment Information";
        GLBResponseInStream: InStream;
        GLBHttpStatusCode: DotNet HttpStatusCode;
        GLBResponseHeaders: DotNet NameValueCollection;
        GLBLastUsedGUID: Text;
        GLBTraceLogEnabled: Boolean;
        NotConfiguredQst: Label 'The connection to the document exchange service is not configured. Do you want to open the %1 page to set it up?', Comment = '%1 - page caption';
        NotConfiguredErr: Label 'You must configure the connection to the document exchange service on the %1 page.', Comment = '%1 - page caption';
        ConnectionSuccessMsg: Label 'The connection test was successful. The settings are valid.';
        DocSendSuccessMsg: Label 'The document was successfully sent to the document exchange service for processing.', Comment = '%1 is the actual document no.';
        DocUploadSuccessMsg: Label 'The document was successfully uploaded to the document exchange service for processing.', Comment = '%1 is the actual document no.';
        DocDispatchSuccessMsg: Label 'The document was successfully sent for dispatching.', Comment = '%1 is the actual document no.';
        DocDispatchFailedMsg: Label 'The document was not successfully dispatched. ', Comment = '%1 is the actual document no.';
        DocStatusOKMsg: Label 'The current status of the electronic document is %1.', Comment = '%1 is the returned value.';
        NotSetUpTxt: Label 'The document exchange service is not set up.';
        NotEnabledTxt: Label 'The document exchange service is not enabled.';
        RenewTokenTxt: Label 'Renew token';
        CheckConnectionTxt: Label 'Check connection.';
        SendDocTxt: Label 'Send document.';
        DispatchDocTxt: Label 'Dispatch document.';
        GetDocStatusTxt: Label 'Check document status.';
        GetDocsTxt: Label 'Get received documents.';
        LoggingConstTxt: Label 'Document exchange service.';
        GetDocErrorTxt: Label 'Check document dispatch errors.';
        MarkBusinessProcessedTxt: Label 'Mark as Business Processed.';
        DocIdImportedTxt: Label 'The document ID %1 is imported into incoming documents.', Comment = '%1 is the actual doc id.';
        FileInvalidTxt: Label 'The document ID %1 is not a valid XML format. ', Comment = '%1 is the actual doc id';
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        InvalidHeaderResponseMsg: Label 'The document exchange service did not return a document identifier.';
        CannotResendErr: Label 'You cannot send this electronic document because it is already delivered or in progress.';
        MalformedGuidErr: Label 'The document exchange service did not return a valid document identifier.';
        DocExchServiceDocumentSuccessfullySentTxt: Label 'The user successfully sent a document via the exchange service.', Locked = true;
        DocExchServiceDocumentSuccessfullyReceivedTxt: Label 'The user successfully received a document via the exchange service.', Locked = true;
        TelemetryCategoryTok: Label 'AL Document Exchange Service', Locked = true;
        MethodGetTxt: Label 'GET', Locked = true;
        MethodPostTxt: Label 'POST', Locked = true;
        MethodPutTxt: Label 'PUT', Locked = true;
        TextXmlTxt: Label 'text/xml', Locked = true;
        ApplicationJsonTxt: Label 'application/json', Locked = true;
        ApplicationFormTxt: Label 'application/x-www-form-urlencoded', Locked = true;
        EncodingUtf8Txt: Label 'utf-8', Locked = true;
        AcceptEncodingHeaderNameTxt: Label 'Accept-Encoding', Locked = true;
        AuthorizationHeaderNameTxt: Label 'Authorization', Locked = true;
        AuthorizationHeaderValueTxt: Label 'Bearer %1', Locked = true;
        AuthorizationCodeRequestUrlTxt: Label '%1?client_id=%2&redirect_uri=%3&response_type=code&scope=%4&state=%5', Locked = true;
        AuthorizationCodeRequestBodyTxt: label 'grant_type=authorization_code&client_id=%1&client_secret=%2&code=%3&redirect_uri=%4', Locked = true;
        RefreshTokenRequestBodyTxt: Label 'grant_type=refresh_token&client_id=%1&client_secret=%2&refresh_token=%3&scope=%4', Locked = true;
        ClientIdAKVSecretNameProdTxt: Label 'DocExchClientIdProd', Locked = true;
        ClientSecretAKVSecretNameProdTxt: Label 'DocExchClientSecretProd', Locked = true;
        ClientIdAKVSecretNameSandboxTxt: Label 'DocExchClientIdTest', Locked = true;
        ClientSecretAKVSecretNameSandboxTxt: Label 'DocExchClientSecretTest', Locked = true;
        AuthCodeScopeTxt: Label 'openid offline', Locked = true;
        AccessTokenParamNameTxt: Label 'access_token', Locked = true;
        RefreshTokenParamNameTxt: Label 'refresh_token', Locked = true;
        IdTokenParamNameTxt: Label 'id_token', Locked = true;
        TokenTypeParamNameTxt: Label 'token_type', Locked = true;
        ExpiresInParamNameTxt: Label 'expires_in', Locked = true;
        ClientIdParamNameTxt: Label 'client_id', Locked = true;
        AudienceParamNameTxt: Label 'aud', Locked = true;
        IssuerParamNameTxt: Label 'iss', Locked = true;
        TokenTypeBearerTxt: Label 'Bearer', Locked = true;
        AppStorePathTxt: Label '#/apps/Tradeshift.AppStore/apps/', Locked = true;
        DefaultSignUpUrlProdTxt: Label 'https://go.tradeshift.com/register', Locked = true;
        DefaultSignInUrlProdTxt: Label 'https://go.tradeshift.com/login', Locked = true;
        DefaultServiceUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/rest/external', Locked = true;
        DefaultAuthUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/auth/login', Locked = true;
        DefaultTokenUrlProdTxt: Label 'https://api.tradeshift.com/tradeshift/auth/token', Locked = true;
        DefaultSignUpUrlSandboxTxt: Label 'https://sandbox.tradeshift.com/register', Locked = true;
        DefaultSignInUrlSandboxTxt: Label 'https://sandbox.tradeshift.com/login', Locked = true;
        DefaultServiceUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/rest/external', Locked = true;
        DefaultAuthUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/auth/login', Locked = true;
        DefaultTokenUrlSandboxTxt: Label 'https://api-sandbox.tradeshift.com/tradeshift/auth/token', Locked = true;
        SandboxTxt: Label 'sandbox', Locked = true;
        DefaultVersionTxt: Label '/v1.0', Locked = true;
        TokenExpiredTxt: Label 'The token has expired.';
        RenewTokenActionTxt: Label 'Renew Token';
        RenewTokenNotificationTxt: Label 'The token for connecting to the document exchange service has expired.';
        RenewTokenNotificationIdTxt: Label '3788e60d-366b-4b69-8827-591237ffe8b1', Locked = true;
        ActivateAppActionTxt: Label 'Activate App';
        ActivateAppNotificationTxt: Label 'To connect to the document exchange service, your administrator must activate the integration app.';
        ActivateAppNotificationIdTxt: Label '7031414b-bc7a-4660-b175-fccf773ddd26', Locked = true;
        MissingClientIdTxt: Label 'The client ID has not been initialized. Sandbox: %1.', Locked = true;
        MissingClientSecretTxt: Label 'The client secret has not been initialized. Sandbox: %1.', Locked = true;
        MissingClientIdOrSecretInSaasTxt: Label 'The client ID or client secret have not been initialized.';
        MissingClientIdOrSecretOnPremTxt: Label 'You must register an app that will be used to connect to the document exchange service and specify the client ID, client secret and redirect URL in the Document Exchange Service Setup page.';
        GuiNotAllowedTxt: Label 'The GUI is not allowed, so acquiring the authorization code through the interactive experience is not possible.';
        AcquireAuthorizationCodeTxt: Label 'Attempting to acquire an authorization code.', Locked = true;
        AcquireAccessTokenByAuthorizationCodeTxt: Label 'Attempting to acquire an access token by authorization code.', Locked = true;
        AcquireAccessTokenByRefreshTokenTxt: Label 'Attempting to acquire an access token by refresh token.', Locked = true;
        CannotGetResponseTxt: Label 'Cannot get a response. Status: %1. Message: %2', Comment = '%1 - response status code, %2 - error message';
        CannotGetResponseWithDetailsTxt: Label 'Cannot get a response. Status: %1. Message: %2. Details: %3', Comment = '%1 - response status code, %2 - error message, %3 - error details';
        CannotParseResponseTxt: Label 'Cannot parse a response.';
        CannotParseIdTokenTxt: Label 'Cannot parse the ID token. %1', Comment = '%1 - error details';
        IdTokenParsedTxt: Label 'Succeed to parse the ID token.', Locked = true;
        CannotGetParamValueTxt: Label 'Cannot get the parameter value from the response. Parameter name: %1.', Comment = '%1 - parameter name';
        NotMatchingParamValueTxt: Label 'The parameter value does not match. Parameter name: %1.', Comment = '%1 - parameter name';
        SucceedRenewTokenTxt: Label 'The token was successfully renewed.';
        SucceedRetrieveAccessTokenTxt: Label 'The access token was successfully retrieved. The token lifetime is %1.', Locked = true;
        FailedAcquireAuthorizationCodeTxt: Label 'Failed to acquire an authorization code. %1', Comment = '%1 - error details';
        SucceedAcquireAuthorizationCodeTxt: Label 'The authorization code was successfully acquired.', Locked = true;
        FailedAcquireAccessTokenByAuthorizationCodeTxt: Label 'Failed to acquire an access token by authorization code. %1', Comment = '%1 - error details';
        SucceedAcquireAccessTokenByAuthorizationCodeTxt: Label 'Acquiring an access token by the authorization code was successful.', Locked = true;
        FailedAcquireAccessTokenByRefreshTokenTxt: Label 'Failed to acquire an access token by refresh token. %1', Comment = '%1 - error details';
        SucceedAcquireAccessTokenByRefreshTokenTxt: Label 'Acquiring an access token by the refresh token was successful.', Locked = true;
        FieldNotSpecifiedTxt: Label 'The field value is not specified. Field: %1', Comment = '%1 - field caption';
        EmptyAccessTokenTxt: Label 'The access token is empty.';
        EmptyRefreshTokenTxt: Label 'The refresh token is empty.';
        EmptyIdTokenTxt: Label 'The ID token is empty.';


    procedure IsSandbox(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"): Boolean
    begin
        exit(DocExchServiceSetup."Service URL".Contains(SandboxTxt));
    end;

    procedure SetURLsToDefault(var DocExchServiceSetup: Record "Doc. Exch. Service Setup")
    begin
        SetURLsToDefault(DocExchServiceSetup, false);
    end;

    [Scope('OnPrem')]
    procedure SetURLsToDefault(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"; Sandbox: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetURLsToDefault(DocExchServiceSetup, Sandbox, IsHandled);
        if IsHandled then
            exit;

        if not Sandbox then begin
            DocExchServiceSetup."Sign-up URL" := DefaultSignUpUrlProdTxt;
            DocExchServiceSetup."Sign-in URL" := DefaultSignInUrlProdTxt;
            DocExchServiceSetup."Service URL" := DefaultServiceUrlProdTxt;
            DocExchServiceSetup."Auth URL" := DefaultAuthUrlProdTxt;
            DocExchServiceSetup."Token URL" := DefaultTokenUrlProdTxt;
        end else begin
            DocExchServiceSetup."Sign-up URL" := DefaultSignUpUrlSandboxTxt;
            DocExchServiceSetup."Sign-in URL" := DefaultSignInUrlSandboxTxt;
            DocExchServiceSetup."Service URL" := DefaultServiceUrlSandboxTxt;
            DocExchServiceSetup."Auth URL" := DefaultAuthUrlSandboxTxt;
            DocExchServiceSetup."Token URL" := DefaultTokenUrlSandboxTxt;
        end;
        DocExchServiceSetup.SetDefaultRedirectUrl();
        DocExchServiceSetup."User Agent" := CopyStr(CompanyName() + DefaultVersionTxt, 1, MaxStrLen(DocExchServiceSetup."User Agent"));
    end;

    [Scope('OnPrem')]
    procedure GetAppUrl(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"): Text
    var
        ClientId: Text;
        SignInUrl: Text;
        AppUrl: Text;
        Sandbox: Boolean;
    begin
        SignInUrl := DocExchServiceSetup."Sign-in URL".TrimEnd('/');
        if SignInUrl = '' then
            exit('');
        Sandbox := IsSandbox(DocExchServiceSetup);
        ClientId := GetClientId(Sandbox);
        if ClientId = '' then
            exit('');
        AppUrl := SignInUrl.Substring(1, SignInUrl.LastIndexOf('/')) + AppStorePathTxt + ClientId;
        exit(AppUrl);
    end;


    [Scope('OnPrem')]
    procedure GetDefaultRedirectUrl(): Text
    var
        OAuth2: Codeunit "OAuth2";
        RedirectUrl: Text;
    begin
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        exit(RedirectUrl);
    end;

    [Scope('OnPrem')]
    procedure SetDefaultRedirectUrl(var DocExchServiceSetup: Record "Doc. Exch. Service Setup")
    var
        RedirectUrl: Text;
    begin
        RedirectUrl := GetDefaultRedirectUrl();
        DocExchServiceSetup."Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen(DocExchServiceSetup."Redirect URL"));
    end;

    local procedure SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl: Text; State: Text; var AuthCode: SecretText; var ErrorMessage: Text)
    var
        DocExchServiceAuth: Page "Doc. Exch. Service Auth.";
    begin
        if AuthRequestUrl = '' then begin
            Clear(AuthCode);
            exit;
        end;

        DocExchServiceAuth.SetOAuth2Properties(AuthRequestUrl, State);
        Commit();
        DocExchServiceAuth.RunModal();

        AuthCode := DocExchServiceAuth.GetAuthCodeAsSecretText();
        ErrorMessage := DocExchServiceAuth.GetAuthError();
    end;

    local procedure AcquireAccessTokenByAuthorizationCode(ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text; AuthUrl: Text; TokenUrl: Text; var AccessToken: SecretText; var RefreshToken: SecretText; var IdToken: SecretText)
    var
        AuthRequestUrl: Text;
        AuthorizationCode: SecretText;
        State: Text;
        RequestBody: SecretText;
        ErrorMessage: Text;
    begin
        Session.LogMessage('0000EXU', AcquireAuthorizationCodeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        State := GetGUID();
        AuthRequestUrl := StrSubstNo(AuthorizationCodeRequestUrlTxt, AuthUrl, UrlEncode(ClientId), UrlEncode(RedirectUrl), UrlEncode(AuthCodeScopeTxt), UrlEncode(State));
        SetPropertiesBasedOnAuthRequestUrlAndRunOAuth2ControlAddIn(AuthRequestUrl, State, AuthorizationCode, ErrorMessage);
        if AuthorizationCode.IsEmpty() then begin
            Session.LogMessage('0000EXW', StrSubstNo(FailedAcquireAuthorizationCodeTxt, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAuthorizationCodeTxt, ErrorMessage);
        end;
        Session.LogMessage('0000EXX', SucceedAcquireAuthorizationCodeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        Session.LogMessage('0000EXY', AcquireAccessTokenByAuthorizationCodeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        if RedirectUrl = '' then
            RedirectUrl := GetDefaultRedirectUrl();
        RequestBody := SecretStrSubstNo(AuthorizationCodeRequestBodyTxt, UrlEncode(ClientId), UrlEncode(ClientSecret), UrlEncode(AuthorizationCode), UrlEncode(RedirectUrl));
        if not TryAcquireAccessToken(TokenUrl, ClientId, ClientSecret, RequestBody, AccessToken, RefreshToken, IdToken, ErrorMessage, true) then begin
            if ErrorMessage = '' then
                ErrorMessage := GetLastErrorText();
            Session.LogMessage('0000EXZ', StrSubstNo(FailedAcquireAccessTokenByAuthorizationCodeTxt, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAccessTokenByAuthorizationCodeTxt, ErrorMessage);
        end;
        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000EY0', StrSubstNo(FailedAcquireAccessTokenByAuthorizationCodeTxt, ''), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAccessTokenByAuthorizationCodeTxt, '');
        end;
        if RefreshToken.IsEmpty() then
            Session.LogMessage('0000EYQ', EmptyRefreshTokenTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        if IdToken.IsEmpty() then
            Session.LogMessage('0000EZ6', EmptyIdTokenTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('0000EY1', SucceedAcquireAccessTokenByAuthorizationCodeTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok)
    end;

    local procedure AcquireAccessTokenByRefreshToken(ClientId: Text; ClientSecret: SecretText; TokenUrl: Text; var AccessToken: SecretText; var RefreshToken: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        OldRefreshToken: SecretText;
        RequestBody: SecretText;
        ErrorMessage: Text;
        IdToken: SecretText;
    begin
        Session.LogMessage('0000EY2', AcquireAccessTokenByRefreshTokenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        GetServiceSetUp(DocExchServiceSetup);
        OldRefreshToken := DocExchServiceSetup.GetRefreshTokenAsSecretText();
        if OldRefreshToken.IsEmpty() then begin
            ErrorMessage := EmptyRefreshTokenTxt;
            Session.LogMessage('0000EY3', StrSubstNo(FailedAcquireAccessTokenByRefreshTokenTxt, EmptyRefreshTokenTxt), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAccessTokenByRefreshTokenTxt, ErrorMessage);
        end;
        RequestBody := SecretStrSubstNo(RefreshTokenRequestBodyTxt, UrlEncode(ClientId), UrlEncode(ClientSecret), UrlEncode(OldRefreshToken), UrlEncode(ClientId));
        if not TryAcquireAccessToken(TokenUrl, ClientId, ClientSecret, RequestBody, AccessToken, RefreshToken, IdToken, ErrorMessage, false) then begin
            if ErrorMessage = '' then
                ErrorMessage := GetLastErrorText();
            Session.LogMessage('0000EY4', StrSubstNo(FailedAcquireAccessTokenByRefreshTokenTxt, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAccessTokenByRefreshTokenTxt, ErrorMessage);
        end;
        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000EY5', StrSubstNo(FailedAcquireAccessTokenByRefreshTokenTxt, ''), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FailedAcquireAccessTokenByRefreshTokenTxt, '');
        end;
        if RefreshToken.IsEmpty() then begin
            Session.LogMessage('0000EZ7', EmptyRefreshTokenTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(EmptyRefreshTokenTxt);
        end;
        Session.LogMessage('0000EY6', SucceedAcquireAccessTokenByRefreshTokenTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryAcquireAccessToken(TokenUrl: Text; ClientId: Text; ClientSecret: SecretText; RequestBody: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText; var IdToken: SecretText; var ErrorMessage: Text; ParseIdToken: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseBody: Text;
        ErrorDetails: Text;
        TokenType: Text;
        ResponseClientId: Text;
        ExpiresIn: Integer;
        HttpStatusCodeNumber: Integer;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(RequestBody.Unwrap());

        HttpWebRequestMgt.Initialize(TokenUrl);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetMethod(MethodPostTxt);
        HttpWebRequestMgt.SetContentType(ApplicationFormTxt);
        HttpWebRequestMgt.SetContentLength(TempBlob.Length());
        HttpWebRequestMgt.SetUserAgent(GetUserAgent());
        HttpWebRequestMgt.SetReturnType(ApplicationJsonTxt);
        HttpWebRequestMgt.AddHeader(AcceptEncodingHeaderNameTxt, EncodingUtf8Txt);
        HttpWebRequestMgt.AddBasicAuthentication(ClientId, ClientSecret);
        HttpWebRequestMgt.AddBodyBlob(TempBlob);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            if not IsNull(HttpStatusCode) then
                HttpStatusCodeNumber := HttpStatusCode;
            Session.LogMessage('0000EY7', StrSubstNo(CannotGetResponseWithDetailsTxt, HttpStatusCodeNumber, ErrorMessage, ErrorDetails), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotGetResponseWithDetailsTxt, HttpStatusCodeNumber, ErrorMessage, ErrorDetails);
        end;

        ParseTokenResponse(ResponseBody, AccessToken, RefreshToken, IdToken, TokenType, ResponseClientId, ExpiresIn, ParseIdToken);

        if TokenType <> TokenTypeBearerTxt then begin
            Session.LogMessage('0000EY8', StrSubstNo(NotMatchingParamValueTxt, TokenTypeParamNameTxt), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotMatchingParamValueTxt, TokenTypeParamNameTxt);
        end;

        if ResponseClientId <> ClientId then begin
            Session.LogMessage('0000EY9', StrSubstNo(NotMatchingParamValueTxt, ClientIdParamNameTxt), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotMatchingParamValueTxt, ClientIdParamNameTxt);
        end;

        Session.LogMessage('0000EYA', StrSubstNo(SucceedRetrieveAccessTokenTxt, ExpiresIn), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryGetSecurityToken(Token: SecretText; var JwtSecurityToken: DotNet JwtSecurityToken)
    var
        JwtSecurityTokenHandler: DotNet JwtSecurityTokenHandler;
    begin
        JwtSecurityTokenHandler := JwtSecurityTokenHandler.JwtSecurityTokenHandler();
        JwtSecurityToken := JwtSecurityTokenHandler.ReadToken(Token.Unwrap());
        Session.LogMessage('0000EYB', IdTokenParsedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [NonDebuggable]
    local procedure ParseTokenResponse(ResponseBody: Text; var AccessToken: SecretText; var RefreshToken: SecretText; var IdToken: SecretText; var TokenType: Text; var ClientId: Text; var ExpiresIn: Integer; ParseIdToken: Boolean)
    var
        JsonObject: JsonObject;
        AccessTokenAsText, RefreshTokenAsText, IdTokenAsText : Text;
    begin
        if not JsonObject.ReadFrom(ResponseBody) then begin
            Session.LogMessage('0000EYC', CannotParseResponseTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotParseResponseTxt);
        end;
        if not GetJsonKeyValue(JsonObject, AccessTokenParamNameTxt, AccessTokenAsText) then begin
            Session.LogMessage('0000EYD', StrSubstNo(CannotGetParamValueTxt, AccessTokenParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotGetParamValueTxt, AccessTokenParamNameTxt);
        end;
        AccessToken := AccessTokenAsText;
        if not GetJsonKeyValue(JsonObject, RefreshTokenParamNameTxt, RefreshTokenAsText) then begin
            Session.LogMessage('0000EYE', StrSubstNo(CannotGetParamValueTxt, RefreshTokenParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotGetParamValueTxt, RefreshTokenParamNameTxt);
        end;
        RefreshToken := RefreshTokenAsText;
        if not GetJsonKeyValue(JsonObject, TokenTypeParamNameTxt, TokenType) then begin
            Session.LogMessage('0000EYF', StrSubstNo(CannotGetParamValueTxt, TokenTypeParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotGetParamValueTxt, TokenTypeParamNameTxt);
        end;
        if ParseIdToken then
            if not GetJsonKeyValue(JsonObject, IdTokenParamNameTxt, IdTokenAsText) then begin
                Session.LogMessage('0000EYG', StrSubstNo(CannotGetParamValueTxt, IdTokenParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                Error(CannotGetParamValueTxt, IdTokenParamNameTxt);
            end;
        IdToken := IdTokenAsText;
        if not GetJsonKeyValue(JsonObject, ExpiresInParamNameTxt, ExpiresIn) then
            Session.LogMessage('0000EYH', StrSubstNo(CannotGetParamValueTxt, ExpiresInParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        if not GetJsonKeyValue(JsonObject, ClientIdParamNameTxt, ClientId) then begin
            Session.LogMessage('0000EYI', StrSubstNo(CannotGetParamValueTxt, ClientIdParamNameTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotGetParamValueTxt, ClientIdParamNameTxt);
        end;
    end;

    [NonDebuggable]
    local procedure GetJsonKeyValue(var JsonObject: JsonObject; KeyName: Text; var KeyValue: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(KeyName, JsonToken) then
            exit(false);

        KeyValue := JsonToken.AsValue().AsText();
        exit(true);
    end;

    [NonDebuggable]
    local procedure GetJsonKeyValue(var JsonObject: JsonObject; KeyName: Text; var KeyValue: Integer): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(KeyName, JsonToken) then
            exit(false);

        KeyValue := JsonToken.AsValue().AsInteger();
        exit(true);
    end;

    local procedure MarkTokenAsExpired()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        DocExchServiceSetup."Token Expired" := true;
        DocExchServiceSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SendRenewTokenNotification()
    var
        RenewTokenNotification: Notification;
    begin
        if not GuiAllowed() then
            exit;
        RenewTokenNotification.Id := GetRenewTokenNotificationId();
        RenewTokenNotification.Message := RenewTokenNotificationTxt;
        RenewTokenNotification.Scope := NotificationScope::LocalScope;
        RenewTokenNotification.AddAction(RenewTokenActionTxt, Codeunit::"Doc. Exch. Service Mgt.", 'RenewToken');
        RenewTokenNotification.Send();
    end;

    procedure RecallActivateAppNotification()
    var
        ActivateAppNotification: Notification;
    begin
        ActivateAppNotification.Id := GetActivateAppNotificationId();
        if not ActivateAppNotification.Recall() then;
    end;

    [Scope('OnPrem')]
    procedure SendActivateAppNotification()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ActivateAppNotification: Notification;
        ClientId: Text;
        Sandbox: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendActivateAppNotification(IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed() then
            exit;

        if not DocExchServiceSetup.Get() then
            exit;

        Sandbox := IsSandbox(DocExchServiceSetup);
        ClientId := GetClientId(Sandbox);
        if ClientId = '' then
            exit;

        ActivateAppNotification.Id := GetActivateAppNotificationId();
        ActivateAppNotification.Recall();
        ActivateAppNotification.Message := ActivateAppNotificationTxt;
        ActivateAppNotification.Scope := NotificationScope::LocalScope;
        if GetAppUrl(DocExchServiceSetup) <> '' then
            ActivateAppNotification.AddAction(ActivateAppActionTxt, Codeunit::"Doc. Exch. Service Mgt.", 'ActivateApp');
        ActivateAppNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure ActivateApp(var ActivateAppNotification: Notification)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        SendActivateAppNotification();
        GetServiceSetUp(DocExchServiceSetup);
        Hyperlink(GetAppUrl(DocExchServiceSetup));
    end;

    [Scope('OnPrem')]
    procedure RenewToken(var RenewTokenNotification: Notification)
    begin
        RenewToken(true);
    end;

    [Scope('OnPrem')]
    procedure RenewToken(TryRefreshToken: Boolean)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        AccessToken: SecretText;
        RefreshToken: SecretText;
        Renewed: Boolean;
    begin
        if TryRefreshToken then
            if TryAcquireAccessTokenByRefreshToken(AccessToken, RefreshToken) then begin
                SaveTokens(AccessToken, RefreshToken);
                Renewed := TryCheckConnection();
            end;

        if not Renewed then begin
            AcquireAccessTokenByAuthorizationCode(true);
            Renewed := TryCheckConnection();
        end;

        GetServiceSetUp(DocExchServiceSetup);
        if Renewed then begin
            LogActivitySucceeded(DocExchServiceSetup.RecordId(), RenewTokenTxt, SucceedRenewTokenTxt);
            if GuiAllowed() then
                Message(SucceedRenewTokenTxt);
            exit;
        end;
        LogActivityFailedAndError(DocExchServiceSetup.RecordId(), RenewTokenTxt, GetLastErrorText());
    end;

    local procedure GetRenewTokenNotificationId(): Guid
    begin
        exit(TextToGuid(RenewTokenNotificationIdTxt));
    end;

    local procedure GetActivateAppNotificationId(): Guid
    begin
        exit(TextToGuid(ActivateAppNotificationIdTxt));
    end;

    local procedure TextToGuid(TextVar: Text): Guid
    var
        GuidVar: Guid;
    begin
        if not Evaluate(GuidVar, TextVar) then;
        exit(GuidVar);
    end;

    internal procedure GetFeatureTelemetryName(): Text
    var
        DocumentExchangeTelemetryNameTxt: Label 'Document Exchange', Locked = true;
    begin
        exit(DocumentExchangeTelemetryNameTxt);
    end;

    [TryFunction]
    local procedure TryCheckConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        VerifyPrerequisites(true);

        GetServiceSetUp(DocExchServiceSetup);
        ExecuteWebServiceGetRequest(GetCheckConnectionURL());
    end;

    [Scope('OnPrem')]
    procedure CheckConnection()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        VerifyPrerequisites(true);

        GetServiceSetUp(DocExchServiceSetup);
        if not ExecuteWebServiceGetRequest(GetCheckConnectionURL()) then
            LogActivityFailedAndError(DocExchServiceSetup.RecordId(), CheckConnectionTxt, GetLastErrorText());

        LogActivitySucceeded(DocExchServiceSetup.RecordId(), CheckConnectionTxt, ConnectionSuccessMsg);

        if GuiAllowed() then
            Message(ConnectionSuccessMsg);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'checkstatus', TempBlobTrace);
    end;

    [Scope('OnPrem')]
    procedure SendUBLDocument(DocVariant: Variant; var TempBlob: Codeunit "Temp Blob"): Text
    var
        DocRecRef: RecordRef;
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        CheckServiceEnabled();
        FeatureTelemetry.LogUptake('0000IM9', TelemetryCategoryTok, Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IMP', TelemetryCategoryTok, 'Document send');

        DocRecRef.GetTable(DocVariant);

        CheckDocumentStatus(DocRecRef);

        if not ExecuteWebServicePostRequest(GetPostSalesURL(DocRecRef), TempBlob) then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        LogActivitySucceeded(DocRecRef.RecordId, SendDocTxt, DocSendSuccessMsg);

        DocExchLinks.UpdateDocumentRecord(DocRecRef, GLBLastUsedGUID, '');

        LogTelemetryDocumentSent();

        if GuiAllowed then
            Message(DocSendSuccessMsg);

        exit(GLBLastUsedGUID);
    end;

    [Scope('OnPrem')]
    procedure SendDocument(DocVariant: Variant; var TempBlob: Codeunit "Temp Blob"): Text
    var
        DocRecRef: RecordRef;
        DocIdentifier: Text;
    begin
        CheckServiceEnabled();

        DocIdentifier := GetGUID();
        DocRecRef.GetTable(DocVariant);

        CheckDocumentStatus(DocRecRef);

        PutDocument(TempBlob, DocIdentifier, DocRecRef);
        DispatchDocument(DocIdentifier, DocRecRef);

        LogTelemetryDocumentSent();

        if GuiAllowed() then
            Message(DocSendSuccessMsg);

        exit(DocIdentifier);
    end;

    [Scope('OnPrem')]
    procedure HasPredefinedOAuth2Params(): Boolean
    begin
        if GetPredefinedClientId(false) = '' then
            exit(false);
        if GetPredefinedClientSecret(false).IsEmpty() then
            exit(false);
        if GetPredefinedClientId(true) = '' then
            exit(false);
        if GetPredefinedClientSecret(true).IsEmpty() then
            exit(false);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetClientId(Sandbox: Boolean): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ClientId: Text;
    begin
        ClientId := GetPredefinedClientId(Sandbox);
        if ClientId = '' then
            if DocExchServiceSetup.Get() then
                ClientId := DocExchServiceSetup."Client Id";
        exit(ClientId);
    end;

    local procedure GetPredefinedClientId(Sandbox: Boolean): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretName: Text;
        ClientId: Text;
    begin
        if not Sandbox then
            SecretName := ClientIdAKVSecretNameProdTxt
        else
            SecretName := ClientIdAKVSecretNameSandboxTxt;
        if EnvironmentInfo.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, ClientId) then
                Session.LogMessage('0000EYJ', StrSubstNo(MissingClientIdTxt, Sandbox), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok)
            else
                exit(ClientId);

        if ClientId = '' then
            OnGetClientId(ClientId);

        exit(ClientId);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [Obsolete('Replaced by GetClientSecretAsSecretText', '25.0')]
    [NonDebuggable]
    procedure GetClientSecret(Sandbox: Boolean): Text
    begin
        exit(GetClientSecretAsSecretText(Sandbox).Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetClientSecretAsSecretText(Sandbox: Boolean): SecretText
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ClientSecret: SecretText;
    begin
        ClientSecret := GetPredefinedClientSecret(Sandbox);
        if ClientSecret.IsEmpty() then
            if DocExchServiceSetup.Get() then
                ClientSecret := DocExchServiceSetup.GetClientSecretAsSecretText();
        exit(ClientSecret);
    end;

    local procedure GetPredefinedClientSecret(Sandbox: Boolean): SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        ClientSecret: SecretText;
        [NonDebuggable]
        ClientSecretFromEvent: Text;
        SecretName: Text;
    begin
        if not Sandbox then
            SecretName := ClientSecretAKVSecretNameProdTxt
        else
            SecretName := ClientSecretAKVSecretNameSandboxTxt;

        if EnvironmentInfo.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, ClientSecret) then
                Session.LogMessage('0000EYK', StrSubstNo(MissingClientSecretTxt, Sandbox), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok)
            else
                exit(ClientSecret);

        if ClientSecret.IsEmpty() then begin
            OnGetClientSecret(ClientSecretFromEvent);
            ClientSecret := ClientSecretFromEvent;
        end;

        exit(ClientSecret);
    end;

    [NonDebuggable]
    local procedure VerifyIdToken(IdToken: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        JwtSecurityToken: DotNet JwtSecurityToken;
        ErrorMessage: Text;
        ClientId: Text;
        AuthUrl: Text;
        ExpectedIss: Text;
        Aud: Text;
        Iss: Text;
        Sandbox: Boolean;
    begin
        if not TryGetSecurityToken(IdToken, JwtSecurityToken) then begin
            ErrorMessage := GetLastErrorText();
            Session.LogMessage('0000EYL', StrSubstNo(CannotParseIdTokenTxt, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(CannotParseIdTokenTxt, ErrorMessage);
        end;

        GetServiceSetUp(DocExchServiceSetup);
        AuthUrl := DocExchServiceSetup."Auth URL".ToLower();
        Sandbox := IsSandbox(DocExchServiceSetup);
        ClientId := GetClientId(Sandbox);

        Aud := JwtSecurityToken.Payload().Aud().Item(0);
        if Aud <> ClientId then begin
            Session.LogMessage('0000EYM', StrSubstNo(NotMatchingParamValueTxt, AudienceParamNameTxt), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotMatchingParamValueTxt, AudienceParamNameTxt);
        end;

        Iss := JwtSecurityToken.Payload().Iss().ToLower();
        ExpectedIss := AuthUrl.Substring(1, StrLen(Iss)).ToLower();
        if Iss <> ExpectedIss then begin
            Session.LogMessage('0000EYN', StrSubstNo(NotMatchingParamValueTxt, IssuerParamNameTxt), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotMatchingParamValueTxt, IssuerParamNameTxt);
        end;
    end;

    local procedure ParseIdToken(IdToken: SecretText; var Json: Text; var Subject: Text; var IssuedAt: DateTime)
    begin
        if IdToken.IsEmpty() then begin
            Session.LogMessage('0000EZ8', EmptyIdTokenTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;
        if not TryParseIdToken(IdToken, Json, Subject, IssuedAt) then begin
            Session.LogMessage('0000EZ9', StrSubstNo(CannotParseIdTokenTxt, GetLastErrorText()), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;
    end;

    [TryFunction]
    local procedure TryParseIdToken(IdToken: SecretText; var Json: Text; var Subject: Text; var IssuedAt: DateTime)
    var
        JwtSecurityToken: DotNet JwtSecurityToken;
        DotNetDateTime: DotNet DateTime;
        DotNetTimeSpan: DotNet TimeSpan;
        DotNetDateTimeKind: DotNet DateTimeKind;
        Iat: Integer;
    begin
        if not TryGetSecurityToken(IdToken, JwtSecurityToken) then begin
            Session.LogMessage('0000EYO', StrSubstNo(CannotParseIdTokenTxt, GetLastErrorText()), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;

        Json := JwtSecurityToken.Payload().SerializeToJson();
        Subject := JwtSecurityToken.Payload().Sub();
        Iat := JwtSecurityToken.Payload().Iat;

        if Iat > 0 then begin
            DotNetDateTime := DotNetDateTime.DateTime(1970, 1, 1, 0, 0, 0, DotNetDateTimeKind.Utc);
            DotNetTimeSpan := DotNetTimeSpan.FromSeconds(Iat);
            IssuedAt := DotNetDateTime.Add(DotNetTimeSpan).ToLocalTime();
        end;
    end;

    local procedure SaveTokens(AccessToken: SecretText; RefreshToken: SecretText)
    var
        IdToken: Text;
    begin
        SaveTokens(AccessToken, RefreshToken, IdToken);
    end;

    local procedure SaveTokens(AccessToken: SecretText; RefreshToken: SecretText; IdToken: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        Json: Text;
        Subject: Text;
        IssuedAt: DateTime;
    begin
        GetServiceSetUp(DocExchServiceSetup);
        DocExchServiceSetup.SetAccessToken(AccessToken);
        DocExchServiceSetup.SetRefreshToken(RefreshToken);
        if not IdToken.IsEmpty() then begin
            ParseIdToken(IdToken, Json, Subject, IssuedAt);
            if Json <> '' then begin
                DocExchServiceSetup."Id Token" := CopyStr(Json, 1, MaxStrLen(DocExchServiceSetup."Id Token"));
                DocExchServiceSetup."Token Subject" := CopyStr(Subject, 1, MaxStrLen(DocExchServiceSetup."Token Subject"));
            end;
        end else
            if not AccessToken.IsEmpty() then
                IssuedAt := CurrentDateTime();
        DocExchServiceSetup."Token Issued At" := IssuedAt;
        DocExchServiceSetup."Token Expired" := false;
        DocExchServiceSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure AcquireAccessTokenByAuthorizationCode(EnabledOnly: Boolean)
    var
        AccessToken: SecretText;
        RefreshToken: SecretText;
        IdToken: SecretText;
    begin
        AcquireAccessTokenByAuthorizationCode(EnabledOnly, AccessToken, RefreshToken, IdToken);
        VerifyIdToken(IdToken);
        SaveTokens(AccessToken, RefreshToken, IdToken);
    end;

    local procedure AcquireAccessTokenByAuthorizationCode(EnabledOnly: Boolean; var AccessToken: SecretText; var RefreshToken: SecretText; var IdToken: SecretText)
    var
        ClientId: Text;
        ClientSecret: SecretText;
        RedirectUrl: Text;
        AuthUrl: text;
        TokenUrl: Text;
    begin
        if not GuiAllowed() then begin
            Session.LogMessage('0000EYP', GuiNotAllowedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(GuiNotAllowedTxt);
        end;

        GetOAuth2Params(EnabledOnly, ClientId, ClientSecret, RedirectUrl, AuthUrl, TokenUrl);
        AcquireAccessTokenByAuthorizationCode(ClientId, ClientSecret, RedirectUrl, AuthUrl, TokenUrl, AccessToken, RefreshToken, IdToken);
    end;

    [Scope('OnPrem')]
    procedure AcquireAccessTokenByRefreshToken()
    var
        AccessToken: SecretText;
        RefreshToken: SecretText;
    begin
        AcquireAccessTokenByRefreshToken(AccessToken, RefreshToken);
        SaveTokens(AccessToken, RefreshToken);
    end;

    [TryFunction]
    local procedure TryAcquireAccessTokenByRefreshToken(var AccessToken: SecretText; var RefreshToken: SecretText)
    begin
        AcquireAccessTokenByRefreshToken(AccessToken, RefreshToken);
    end;

    local procedure AcquireAccessTokenByRefreshToken(var AccessToken: SecretText; var RefreshToken: SecretText)
    var
        ClientId: Text;
        ClientSecret: SecretText;
        RedirectUrl: Text;
        AuthUrl: Text;
        TokenUrl: Text;
    begin
        GetOAuth2Params(true, ClientId, ClientSecret, RedirectUrl, AuthUrl, TokenUrl);
        AcquireAccessTokenByRefreshToken(ClientId, ClientSecret, TokenUrl, AccessToken, RefreshToken);
    end;

    local procedure GetOAuth2Params(EnabledOnly: Boolean; var ClientId: Text; var ClientSecret: SecretText; var RedirectUrl: Text; var AuthUrl: Text; var TokenUrl: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        Sandbox: Boolean;
    begin
        GetServiceSetUp(DocExchServiceSetup);
        if EnabledOnly then
            CheckServiceEnabled(DocExchServiceSetup);
        RedirectUrl := DocExchServiceSetup."Redirect URL";
        if RedirectUrl = '' then begin
            Session.LogMessage('0000EYS', StrSubstNo(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Redirect URL")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Redirect URL"));
        end;

        AuthUrl := DocExchServiceSetup."Auth URL";
        if AuthUrl = '' then begin
            Session.LogMessage('0000EYT', StrSubstNo(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Auth URL")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Auth URL"));
        end;

        TokenUrl := DocExchServiceSetup."Token URL";
        if TokenUrl = '' then begin
            Session.LogMessage('0000EYU', StrSubstNo(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Token URL")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Token URL"));
        end;

        Sandbox := IsSandbox(DocExchServiceSetup);

        ClientId := GetClientId(Sandbox);
        if ClientId = '' then begin
            Session.LogMessage('0000EYV', StrSubstNo(MissingClientIdTxt, Sandbox), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(GetMissingClientIdOrSecretErr());
        end;

        ClientSecret := GetClientSecretAsSecretText(Sandbox);
        if ClientSecret.IsEmpty() then begin
            Session.LogMessage('0000EYW', StrSubstNo(MissingClientSecretTxt, Sandbox), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(GetMissingClientIdOrSecretErr());
        end;
    end;

    local procedure GetMissingClientIdOrSecretErr(): Text
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit(MissingClientIdOrSecretInSaasTxt);

        exit(MissingClientIdOrSecretOnPremTxt);
    end;

    local procedure PutDocument(var TempBlob: Codeunit "Temp Blob"; DocIdentifier: Text; DocRecRef: RecordRef)
    var
        Succeed: Boolean;
    begin
        if not ExecuteWebServicePutRequest(GetPUTDocURL(DocIdentifier), TempBlob) then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        if not IsNull(GLBHttpStatusCode) then
            Succeed := GLBHttpStatusCode.Equals(GLBHttpStatusCode.NoContent);
        if not Succeed then
            LogActivityFailedAndError(DocRecRef.RecordId, SendDocTxt, '');

        LogActivitySucceeded(DocRecRef.RecordId, SendDocTxt, DocUploadSuccessMsg);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'put', TempBlobTrace);
    end;

    local procedure DispatchDocument(DocOrigIdentifier: Text; DocRecRef: RecordRef)
    var
        TempBlob: Codeunit "Temp Blob";
        DocIdentifier: Text;
        PlaceholderGuid: Guid;
        Succeed: Boolean;
    begin
        if not ExecuteWebServicePostRequest(GetDispatchDocURL(DocOrigIdentifier), TempBlob) then
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, '');

        if not IsNull(GLBHttpStatusCode) then
            Succeed := GLBHttpStatusCode.Equals(GLBHttpStatusCode.Created);
        if not Succeed then begin
            DocExchLinks.UpdateDocumentRecord(DocRecRef, '', DocOrigIdentifier);
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, DocDispatchFailedMsg);
        end;

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'dispatch', TempBlobTrace);

        DocIdentifier := GLBResponseHeaders.Get(GetDocumentIDKey());
        if not Evaluate(PlaceholderGuid, DocIdentifier) then
            LogActivityFailedAndError(DocRecRef.RecordId, DispatchDocTxt, InvalidHeaderResponseMsg);
        DocExchLinks.UpdateDocumentRecord(DocRecRef, DocIdentifier, DocOrigIdentifier);

        LogActivitySucceeded(DocRecRef.RecordId, DispatchDocTxt, DocDispatchSuccessMsg);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentStatus(DocRecordID: RecordID; DocIdentifier: Text[50]; DocOrigIdentifier: Text[50]): Text
    var
        Errors: Text;
    begin
        CheckServiceEnabled();

        // Check for dispatch errors first
        if DocOrigIdentifier <> '' then
            if GetDocDispatchErrors(DocRecordID, DocOrigIdentifier, Errors) then
                if Errors <> '' then
                    exit('FAILED');

        // Check metadata
        if not GetDocumentMetadata(DocRecordID, DocIdentifier, Errors) then
            exit('PENDING');

        // If metadata exist it means doc has been dispatched
        exit(Errors);
    end;

    local procedure GetDocDispatchErrors(DocRecordID: RecordID; DocIdentifier: Text; var Errors: Text): Boolean
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled();

        if not ExecuteWebServiceGetRequest(GetDispatchErrorsURL(DocIdentifier)) then begin
            LogActivityFailed(DocRecordID, GetDocErrorTxt, '');
            exit(false);
        end;

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then begin
            LogActivityFailed(DocRecordID, GetDocErrorTxt, '');
            exit(false);
        end;

        Errors := XMLDOMMgt.FindNodeTextWithNamespace(XmlDoc.DocumentElement, GetErrorXPath(),
            GetPrefix(), GetApiNamespace());

        LogActivitySucceeded(DocRecordID, GetDocErrorTxt, Errors);

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'dispatcherrors', TempBlobTrace);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentMetadata(DocRecordID: RecordID; DocIdentifier: Text[50]; var NewStatus: Text): Boolean
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled();
        NewStatus := '';

        if not ExecuteWebServiceGetRequest(GetDocStatusURL(DocIdentifier)) then begin
            LogActivityFailed(DocRecordID, GetDocStatusTxt, '');
            exit(false);
        end;

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then begin
            LogActivityFailed(DocRecordID, GetDocStatusTxt, '');
            exit(false);
        end;

        if GLBTraceLogEnabled then
            Trace.LogStreamToTempFile(GLBResponseInStream, 'checkstatus', TempBlobTrace);

        NewStatus := XMLDOMMgt.FindNodeTextWithNamespace(XmlDoc.DocumentElement(), GetStatusXPath(), GetPrefix(), GetPublicNamespace());
        LogActivitySucceeded(DocRecordID, GetDocStatusTxt, StrSubstNo(DocStatusOKMsg, NewStatus));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ReceiveDocuments(ContextRecordID: RecordID)
    var
        XmlDoc: DotNet XmlDocument;
    begin
        CheckServiceEnabled();

        if not ExecuteWebServiceGetRequest(GetRetrieveDocsURL()) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');

        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');

        ProcessReceivedDocs(ContextRecordID, XmlDoc);
    end;

    local procedure ProcessReceivedDocs(ContextRecordID: RecordID; XmlDocs: DotNet XmlDocument)
    var
        IncomingDocument: Record "Incoming Document";
        XMLRootNode: DotNet XmlNode;
        Node: DotNet XmlNode;
        DummyGuid: Guid;
        DocIdentifier: Text;
        Description: Text;
    begin
        XMLRootNode := XmlDocs.DocumentElement;

        foreach Node in XMLRootNode.ChildNodes do begin
            DocIdentifier := XMLDOMMgt.FindNodeTextWithNamespace(Node, GetDocumentIDXPath(),
                GetPrefix(), GetPublicNamespace());

            if not Evaluate(DummyGuid, DocIdentifier) then
                LogActivityFailedAndError(ContextRecordID, GetDocsTxt, MalformedGuidErr);
            if TryGetDocumentDescription(Node, Description) then;
            if DelChr(Description, '<>', ' ') = '' then
                Description := DocIdentifier;
            GetOriginalDocument(ContextRecordID, DocIdentifier);
            CreateIncomingDocEntry(IncomingDocument, ContextRecordID, DocIdentifier, Description);

            if not MarkDocBusinessProcessed(DocIdentifier) then begin
                IncomingDocument.Delete();
                LogActivityFailed(ContextRecordID, MarkBusinessProcessedTxt, '');
            end else
                LogActivitySucceeded(ContextRecordID, MarkBusinessProcessedTxt, StrSubstNo(DocIdImportedTxt, DocIdentifier));
            Commit();

            IncomingDocument.Find();
            LogTelemetryDocumentReceived();
            OnAfterIncomingDocReceivedFromDocExch(IncomingDocument);
        end;
    end;

    local procedure GetOriginalDocument(ContextRecordID: RecordID; DocIdentifier: Text)
    begin
        CheckServiceEnabled();

        // If can't get the original, it means it was not a 2-step. Get the actual TS-UBL
        if not ExecuteWebServiceGetRequest(GetRetrieveOriginalDocIDURL(DocIdentifier)) then
            GetDocument(ContextRecordID, DocIdentifier);
    end;

    local procedure GetDocument(ContextRecordID: RecordID; DocIdentifier: Text)
    begin
        CheckServiceEnabled();

        if not ExecuteWebServiceGetRequest(GetRetrieveDocIDURL(DocIdentifier)) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, '');
    end;

    [TryFunction]
    local procedure MarkDocBusinessProcessed(DocIdentifier: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        CheckServiceEnabled();
        ExecuteWebServicePutRequest(GetSetTagURL(DocIdentifier), TempBlob);
    end;

    local procedure CreateIncomingDocEntry(var IncomingDocument: Record "Incoming Document"; ContextRecordID: RecordID; DocIdentifier: Text; Description: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        XmlDoc: DotNet XmlDocument;
    begin
        // Assert response is XML
        if not HttpWebRequestMgt.TryLoadXMLResponse(GLBResponseInStream, XmlDoc) then
            LogActivityFailedAndError(ContextRecordID, GetDocsTxt, StrSubstNo(FileInvalidTxt, DocIdentifier));

        IncomingDocument.CreateIncomingDocument(
          CopyStr(Description, 1, MaxStrLen(IncomingDocument.Description)), GetExternalDocURL(DocIdentifier));

        // set received XML as main attachment and extract additional ones as secondary attachments
        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, DocIdentifier, 'xml', GLBResponseInStream);
        ProcessAttachments(IncomingDocument, XmlDoc);
    end;

    local procedure ProcessAttachments(var IncomingDocument: Record "Incoming Document"; XmlDoc: DotNet XmlDocument)
    var
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
    begin
        XMLDOMMgt.FindNodesWithNamespace(XmlDoc.DocumentElement, GetEmbeddedDocXPath(), GetPrefix(), GetCBCNamespace(),
          NodeList);
        foreach Node in NodeList do
            ExtractAdditionalAttachment(IncomingDocument, Node);
    end;

    local procedure ExtractAdditionalAttachment(var IncomingDocument: Record "Incoming Document"; Node: DotNet XmlNode)
    var
        FileMgt: Codeunit "File Management";
        Convert: DotNet Convert;
        TempFile: DotNet File;
        FilePath: Text;
        FileName: Text;
    begin
        FileName := XMLDOMMgt.GetAttributeValue(Node, 'filename');
        FilePath := FileMgt.ServerTempFileName(FileMgt.GetExtension(FileName));
        FileMgt.IsAllowedPath(FilePath, false);
        TempFile.WriteAllBytes(FilePath, Convert.FromBase64String(Node.InnerText));
        IncomingDocument.AddAttachmentFromServerFile(FileName, FilePath);
    end;

    local procedure Initialize(URL: Text; Method: Text[6]; var TempBlob: Codeunit "Temp Blob")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        AccessToken: SecretText;
    begin
        CheckCredentials();
        GetServiceSetUp(DocExchServiceSetup);
        AccessToken := DocExchServiceSetup.GetAccessTokenAsSecretText();
        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000EYR', EmptyAccessTokenTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(EmptyAccessTokenTxt);
        end;

        Clear(HttpWebRequestMgt);
        HttpWebRequestMgt.Initialize(URL);
        HttpWebRequestMgt.SetMethod(Method);
        HttpWebRequestMgt.AddHeader(AuthorizationHeaderNameTxt, SecretStrSubstNo(AuthorizationHeaderValueTxt, AccessToken));

        SetDefaults(TempBlob);
    end;

    local procedure SetDefaults(var TempBlob: Codeunit "Temp Blob")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        HttpWebRequestMgt.SetContentType(TextXmlTxt);
        HttpWebRequestMgt.SetReturnType(TextXmlTxt);
        HttpWebRequestMgt.SetUserAgent(GetUserAgent());
        HttpWebRequestMgt.AddHeader(AcceptEncodingHeaderNameTxt, EncodingUtf8Txt);
        HttpWebRequestMgt.AddBodyBlob(TempBlob);

        // Set tracing
        GetServiceSetUp(DocExchServiceSetup);
        GLBTraceLogEnabled := DocExchServiceSetup."Log Web Requests";
        HttpWebRequestMgt.SetTraceLogEnabled(DocExchServiceSetup."Log Web Requests");
    end;

    procedure CheckCredentials()
    var
        DocExchServiceSetup: Page "Doc. Exch. Service Setup";
    begin
        if not VerifyPrerequisites(false) then
            if GuiAllowed() and Confirm(StrSubstNo(NotConfiguredQst, DocExchServiceSetup.Caption()), true) then begin
                Commit();
                DocExchServiceSetup.RunModal();
                if not VerifyPrerequisites(false) then
                    Error(NotConfiguredErr, DocExchServiceSetup.Caption());
            end else
                Error(NotConfiguredErr, DocExchServiceSetup.Caption());
    end;

    local procedure ExecuteWebServiceGetRequest(URL: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        exit(ExecuteWebServiceRequest(URL, MethodGetTxt, TempBlob));
    end;

    local procedure ExecuteWebServicePostRequest(URL: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(ExecuteWebServiceRequest(URL, MethodPostTxt, TempBlob));
    end;

    local procedure ExecuteWebServicePutRequest(URL: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(ExecuteWebServiceRequest(URL, MethodPutTxt, TempBlob));
    end;

    local procedure ExecuteWebServiceRequest(URL: Text; Method: Text[6]; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ErrorMessage: Text;
    begin
        Initialize(URL, Method, TempBlob);
        if ExecuteWebServiceRequest() then
            exit(true);
        if IsNull(GLBHttpStatusCode) then
            exit(false);
        if not GLBHttpStatusCode.Equals(GLBHttpStatusCode.Unauthorized) then
            exit(false);
        AcquireAccessTokenByRefreshToken();
        Initialize(URL, Method, TempBlob);
        if ExecuteWebServiceRequest() then
            exit(true);
        if IsNull(GLBHttpStatusCode) then
            exit(false);
        if not GLBHttpStatusCode.Equals(GLBHttpStatusCode.Unauthorized) then
            exit(false);
        ErrorMessage := GetLastErrorText();
        GetServiceSetUp(DocExchServiceSetup);
        LogActivityFailed(DocExchServiceSetup.RecordId(), TokenExpiredTxt, ErrorMessage);
        MarkTokenAsExpired();
        SendRenewTokenNotification();
        exit(false);
    end;

    [TryFunction]
    local procedure ExecuteWebServiceRequest()
    var
        ErrorMessage: Text;
        HttpStatusCodeNumber: Integer;
    begin
        Clear(GLBHttpStatusCode);
        Clear(GLBResponseHeaders);
        Clear(TempBlobResponse);
        TempBlobResponse.CreateInStream(GLBResponseInStream);

        if not GuiAllowed() then
            HttpWebRequestMgt.DisableUI();

        if not HttpWebRequestMgt.GetResponse(GLBResponseInStream, GLBHttpStatusCode, GLBResponseHeaders) then begin
            if not HttpWebRequestMgt.ProcessFaultXMLResponse('', GetErrorXPath(), GetPrefix(), GetApiNamespace(), GLBHttpStatusCode, GLBResponseHeaders) then
                ; // catch
            ErrorMessage := GetLastErrorText();
            if not IsNull(GLBHttpStatusCode) then
                HttpStatusCodeNumber := GLBHttpStatusCode;
            Session.LogMessage('0000EYX', StrSubstNo(CannotGetResponseTxt, HttpStatusCodeNumber, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(ErrorMessage); // rethrow
        end;
    end;

    procedure CheckServiceEnabled()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        CheckServiceEnabled(DocExchServiceSetup);
    end;

    procedure GetServiceSetUp(var DocExchServiceSetup: Record "Doc. Exch. Service Setup")
    begin
        if not DocExchServiceSetup.Get() then begin
            Session.LogMessage('0000EYY', NotSetUpTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotSetUpTxt);
        end;
    end;

    local procedure CheckServiceEnabled(var DocExchServiceSetup: Record "Doc. Exch. Service Setup")
    begin
        if not DocExchServiceSetup.Enabled then begin
            Session.LogMessage('0000EYZ', NotEnabledTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotEnabledTxt);
        end;
    end;

    local procedure CheckDocumentStatus(DocRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentStatus(DocRecRef, IsHandled);
        if IsHandled then
            exit;

        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocRecRef.SetTable(SalesInvoiceHeader);
                    if SalesInvoiceHeader."Document Exchange Status" in
                       [SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
                        SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocRecRef.SetTable(SalesCrMemoHeader);
                    if SalesCrMemoHeader."Document Exchange Status" in
                       [SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        SalesCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
                        SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                end;
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    local procedure GetUserAgent(): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        if DocExchServiceSetup."User Agent" = '' then begin
            Session.LogMessage('0000EZ0', StrSubstNo(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("User Agent")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("User Agent"));
        end;
        exit(DocExchServiceSetup."User Agent");
    end;

    local procedure GetFullURL(PartialURL: Text): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        if DocExchServiceSetup."Service URL" = '' then begin
            Session.LogMessage('0000EZ1', StrSubstNo(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Service URL")), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(FieldNotSpecifiedTxt, DocExchServiceSetup.FieldCaption("Service URL"));
        end;
        exit(DocExchServiceSetup."Service URL" + PartialURL);
    end;

    local procedure GetCheckConnectionURL(): Text
    begin
        exit(GetFullURL('/account/info'));
    end;

    local procedure GetPostSalesURL(DocRecRef: RecordRef) URL: Text
    begin
        OnBeforeGetPostSalesURL(DocRecRef, URL);
        if URL <> '' then
            exit(URL);

        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                exit(GetPostSalesInvURL());
            DATABASE::"Sales Cr.Memo Header":
                exit(GetPostSalesCrMemoURL());
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    procedure GetPostSalesInvURL(): Text
    begin
        exit(
            GetFullURL(StrSubstNo('/documents/dispatcher?documentId=%1&documentProfileId=tradeshift.invoice.ubl.1.0', GetGUID())));
    end;

    procedure GetPostSalesCrMemoURL(): Text
    begin
        exit(
            GetFullURL(StrSubstNo('/documents/dispatcher?documentId=%1&documentProfileId=tradeshift.creditnote.ubl.1.0', GetGUID())));
    end;

    local procedure GetDocStatusURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/metadata', DocIdentifier)));
    end;

    local procedure GetPUTDocURL(FileName: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/file?directory=outbox', FileName)));
    end;

    local procedure GetDispatchDocURL(FileName: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/dispatcher?directory=outbox', FileName)));
    end;

    local procedure GetDispatchErrorsURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documentfiles/%1/errors', DocIdentifier)));
    end;

    local procedure GetRetrieveDocsURL(): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents?stag=inbox&withouttag=BusinessDelivered&limit=%1', GetChunckSize())));
    end;

    local procedure GetRetrieveDocIDURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1', DocIdentifier)));
    end;

    local procedure GetRetrieveOriginalDocIDURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/original', DocIdentifier)));
    end;

    local procedure GetSetTagURL(DocIdentifier: Text): Text
    begin
        exit(GetFullURL(StrSubstNo('/documents/%1/tags/BusinessDelivered', DocIdentifier)));
    end;

    local procedure GetGUID(): Text
    begin
        GLBLastUsedGUID := DelChr(DelChr(Format(CreateGuid()), '=', '{'), '=', '}');

        exit(GLBLastUsedGUID);
    end;

    local procedure UrlEncode(UrlComponent: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.UrlEncode(UrlComponent));
    end;

    [NonDebuggable]
    local procedure UrlEncode(UrlComponent: SecretText): SecretText
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.UrlEncode(UrlComponent.Unwrap()));
    end;

    local procedure GetChunckSize(): Integer
    begin
        exit(100);
    end;

    local procedure GetApiNamespace(): Text
    begin
        exit('http://tradeshift.com/api/1.0');
    end;

    local procedure GetPublicNamespace(): Text
    begin
        exit('http://tradeshift.com/api/public/1.0');
    end;

    local procedure GetCBCNamespace(): Text
    begin
        exit('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure GetErrorXPath(): Text
    begin
        exit(StrSubstNo('//%1:Message', GetPrefix()));
    end;

    local procedure GetStatusXPath(): Text
    begin
        exit(StrSubstNo('//%1:DeliveryState', GetPrefix()));
    end;

    local procedure GetDocumentIDXPath(): Text
    begin
        exit(StrSubstNo('.//%1:DocumentId', GetPrefix()));
    end;

    local procedure GetDocumentTypeXPath(): Text
    begin
        exit(StrSubstNo('.//%1:DocumentType', GetPrefix()));
    end;

    local procedure GetDocumentIDForDescriptionXPath(): Text
    begin
        exit(StrSubstNo('.//%1:ID', GetPrefix()));
    end;

    local procedure GetEmbeddedDocXPath(): Text
    begin
        exit(StrSubstNo('//%1:EmbeddedDocumentBinaryObject', GetPrefix()));
    end;

    local procedure GetPrefix(): Text
    begin
        exit('newnamespace');
    end;

    local procedure GetDocumentIDKey(): Text
    begin
        exit('X-Tradeshift-DocumentId');
    end;

    [TryFunction]
    local procedure TryGetDocumentDescription(Node: DotNet XmlNode;

    var
        Description: Text)
    var
        SrchNode: DotNet XmlNode;
    begin
        Description := '';
        XMLDOMMgt.FindNodeWithNamespace(Node, GetDocumentTypeXPath(), GetPrefix(),
          GetPublicNamespace(), SrchNode);
        Description := MapDocumentType(XMLDOMMgt.GetAttributeValue(SrchNode, 'type'));
        Description += ' ' + XMLDOMMgt.FindNodeTextWithNamespace(Node, GetDocumentIDForDescriptionXPath(),
            GetPrefix(), GetPublicNamespace());
    end;

    local procedure MapDocumentType(DocType: Text): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case DocType of
            'invoice':
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
            'creditnote':
                PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
            else
                exit('');
        end;
        exit(Format(PurchaseHeader."Document Type"));
    end;

    procedure LogActivitySucceeded(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Success, LoggingConstTxt,
          ActivityDescription, ActivityMessage);
    end;

    procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityMessageVar: Text;
    begin
        ActivityMessageVar := ActivityMessage;
        LogActivityFailedCommon(RelatedRecordID, ActivityDescription, ActivityMessageVar);
    end;

    procedure LogActivityFailedAndError(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    begin
        LogActivityFailedCommon(RelatedRecordID, ActivityDescription, ActivityMessage);
        if DelChr(ActivityMessage, '<>', ' ') <> '' then
            Error(ActivityMessage);
    end;

    local procedure LogActivityFailedCommon(RelatedRecordID: RecordID; ActivityDescription: Text; var ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityMessage := GetLastErrorText + ' ' + ActivityMessage;
        ClearLastError();

        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Failed, LoggingConstTxt,
          ActivityDescription, ActivityMessage);

        if ActivityMessage = '' then
            ActivityLog.SetDetailedInfoFromStream(GLBResponseInStream);

        Commit();
    end;

    procedure EnableTraceLog(NewTraceLogEnabled: Boolean)
    begin
        GLBTraceLogEnabled := NewTraceLogEnabled;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleVANRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        RecRef: RecordRef;
    begin
        if not DocExchServiceSetup.Get() then begin
            DocExchServiceSetup.Init();
            DocExchServiceSetup.Insert();
        end;

        RecRef.GetTable(DocExchServiceSetup);

        if DocExchServiceSetup.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId(), DocExchServiceSetup.TableCaption(), DocExchServiceSetup."Service URL", PAGE::"Doc. Exch. Service Setup");
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnAfterIncomingDocReceivedFromDocExch(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetClientId(var ClientId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetClientSecret(var ClientSecret: Text)
    begin
    end;

    procedure GetExternalDocURL(DocID: Text): Text
    var
        URLPart: Text;
    begin
        URLPart := 'www';
        if StrPos(GetFullURL(''), SandboxTxt) > 0 then
            URLPart := SandboxTxt;

        exit(StrSubstNo('https://%1.tradeshift.com/app/Tradeshift.Migration#::conversation/view/%2::', URLPart, DocID));
    end;

    procedure VerifyPrerequisites(ShowFailure: Boolean): Boolean
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        PageDocExchServiceSetup: Page "Doc. Exch. Service Setup";
        Success: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyPrerequisites(ShowFailure, Success, IsHandled);
        if IsHandled then
            exit(Success);

        if DocExchServiceSetup.Get() then
            if DocExchServiceSetup."Service URL" <> '' then
                if DocExchServiceSetup."Auth URL" <> '' then
                    if DocExchServiceSetup."Token URL" <> '' then
                        Success := true;
        if not Success then
            if ShowFailure then
                Error(NotConfiguredErr, PageDocExchServiceSetup.Caption());
        exit(Success);
    end;

    local procedure LogTelemetryDocumentSent()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        Session.LogMessage('000089R', DocExchServiceDocumentSuccessfullySentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('000089S', DocExchServiceSetup."Service URL", Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryDocumentReceived()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        GetServiceSetUp(DocExchServiceSetup);
        Session.LogMessage('000089T', DocExchServiceDocumentSuccessfullyReceivedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('000089U', DocExchServiceSetup."Service URL", Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendActivateAppNotification(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetURLsToDefault(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"; Sandbox: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyPrerequisites(ShowFailure: Boolean; var Success: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentStatus(DocRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetPostSalesURL(DocRecRef: RecordRef; var URL: Text)
    begin
    end;
}

