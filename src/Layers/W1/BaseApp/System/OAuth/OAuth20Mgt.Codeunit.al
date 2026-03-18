namespace System.Security.Authentication;

using Microsoft.Foundation.Enums;
using Microsoft.Utilities;
using System;
using System.Environment;
using System.Security.Encryption;
using System.Text;

codeunit 1140 "OAuth 2.0 Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        AuthRequiredNotificationMsg: Label 'Choose the Request Authorization Code action to complete the authorization process.';
        RequestAuthCodeTxt: Label 'Request authorization code.', Locked = true;
        RequestAccessTokenTxt: Label 'Request access token.', Locked = true;
        RefreshAccessTokenTxt: Label 'Refresh access token.', Locked = true;
        InvokeRequestTxt: Label 'Invoke %1 request.', Comment = '%1 - request type, e.g. GET, POST', Locked = true;
        RefreshSuccessfulTxt: Label 'Refresh token successful.';
        RefreshFailedTxt: Label 'Refresh token failed.';
        AuthorizationSuccessfulTxt: Label 'Authorization successful.';
        AuthorizationFailedTxt: Label 'Authorization failed.';
        ReasonTxt: Label 'Reason: ';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        ActivityLogContextTxt: Label 'OAuth 2.0', Locked = true;
        AuthorizeTxt: Label 'Authorize';
        LimitExceededTxt: Label 'Http daily request limit is exceeded.', Locked = true;
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.', Comment = '%1 - url, e.g. https://microsoft.com';
        BaseAuthorizationUrlTxt: Label '%1%2?response_type=%3&client_id=%4&scope=%5&redirect_uri=%6', Locked = true;
        AuthCodeUrlTxt: Label 'grant_type=authorization_code&client_secret=%1&client_id=%2&redirect_uri=%3&code=%4', Locked = true;
        PlaceholderTok: Label 'Placeholder', Locked = true;

    [EventSubscriber(ObjectType::Page, Page::"OAuth 2.0 Setup", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordPageEvent(var Rec: Record "OAuth 2.0 Setup")
    var
        SetupNotification: Notification;
    begin
        SetupNotification.Id := GetRequestAuthNotificationGUID();
        SetupNotification.Recall();

        if not (Rec.Status in [Rec.Status::Disabled, Rec.Status::Error]) then
            exit;

        SetupNotification.Message := AuthRequiredNotificationMsg;
        SetupNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        SetupNotification.SetData(Rec.FieldName(Code), Rec.Code);
        SetupNotification.AddAction(AuthorizeTxt, CODEUNIT::"OAuth 2.0 Mgt.", 'RequestAuthFromNotification');
        SetupNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure RequestAuthFromNotification(AuthNotification: Notification)
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        if not AuthNotification.HasData(OAuth20Setup.FieldName(Code)) then
            exit;

        if not OAuth20Setup.Get(AuthNotification.GetData(OAuth20Setup.FieldName(Code))) then
            exit;

        OAuth20Setup.RequestAuthorizationCode();
    end;

    local procedure GetRequestAuthNotificationGUID(): Guid
    begin
        exit('7CC74E1E-641D-4FCC-A074-1F64CEE53AEA');
    end;

    procedure GetAuthorizationURLAsSecretText(OAuth20Setup: Record "OAuth 2.0 Setup"; ClientID: Text) AuthorizationUrl: SecretText
    var
        ServiceUrl: Text;
        RequestJson: Text;
    begin
        OAuth20Setup.TestField("Service URL");
        OAuth20Setup.TestField("Authorization URL Path");
        OAuth20Setup.TestField("Authorization Response Type");
        OAuth20Setup.TestField("Access Token URL Path");
        OAuth20Setup.TestField("Client ID");
        OAuth20Setup.TestField(Scope);
        OAuth20Setup.TestField("Redirect URL");

        RequestJson := '';
        LogActivity(OAuth20Setup, true, RequestAuthCodeTxt, '', RequestJson, '', true);
        ServiceUrl := OAuth20Setup."Service URL";
        OnBeforeGetServiceUrlForAuthorizationURL(ServiceUrl, OAuth20Setup);
        AuthorizationUrl :=
          SecretStrSubstNo(
            BaseAuthorizationUrlTxt,
            ServiceUrl, OAuth20Setup."Authorization URL Path", OAuth20Setup."Authorization Response Type", ClientID, OAuth20Setup.Scope, OAuth20Setup."Redirect URL");
        ExtendAuthorizationURLWithCodeChallenge(AuthorizationUrl, OAuth20Setup);
        ExtendWithNonce(AuthorizationUrl, OAuth20Setup);
        exit(AuthorizationUrl);
    end;


    /// <summary>
    /// Request access token using application/json ContentType.
    /// </summary>
    procedure RequestAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; AuthorizationCode: SecretText; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText): Boolean
    begin
        exit(
            RequestAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;


    /// <summary>
    /// Request access token using given request json and application/json ContentType.
    /// </summary>
    procedure RequestAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: SecretText; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText) Result: Boolean
    begin
        exit(RequestAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken, false));
    end;


    /// <summary>
    /// Request access token using application/x-www-form-urlencoded ContentType if UseUrlEncodedContentType is set to true or application/json ContentType otherwise.
    /// </summary>
    procedure RequestAccessTokenWithContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: SecretText; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText; UseUrlEncodedContentType: Boolean) Result: Boolean
    begin
        exit(RequestAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, AuthorizationCode, ClientID, ClientSecret, AccessToken, RefreshToken, UseUrlEncodedContentType));
    end;

    local procedure RequestAccessTokenWithGivenRequestJsonAndContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; AuthorizationCode: SecretText; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText; UseUrlEncodedContentType: Boolean) Result: Boolean
    var
        RequestJsonContent: SecretText;
        ContentJson: SecretText;
        ResponseJson: Text;
        HttpError: Text;
        ExpireInSec: BigInteger;
    begin
        OAuth20Setup.Status := OAuth20Setup.Status::Disabled;
        OAuth20Setup.TestField("Service URL");
        OAuth20Setup.TestField("Access Token URL Path");
        OAuth20Setup.TestField("Client ID");
        OAuth20Setup.TestField("Client Secret");
        OAuth20Setup.TestField("Redirect URL");

        if UseUrlEncodedContentType then begin
            CreateContentRequestForAccessToken(ContentJson, ClientSecret, ClientID, OAuth20Setup."Redirect URL", AuthorizationCode, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Code Verifier"));
            CreateRequestJSONForAccessRefreshTokenURLEncoded(RequestJson, OAuth20Setup."Service URL", OAuth20Setup."Access Token URL Path", ContentJson, RequestJsonContent);
        end else begin
            CreateContentRequestJSONForAccessToken(ContentJson, ClientSecret, ClientID, OAuth20Setup."Redirect URL", AuthorizationCode, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Code Verifier"));
            CreateRequestJSONForAccessRefreshToken(RequestJson, OAuth20Setup."Service URL", OAuth20Setup."Access Token URL Path", ContentJson, RequestJsonContent);
        end;

        Result := RequestAccessAndRefreshTokens(RequestJsonContent, ResponseJson, AccessToken, RefreshToken, ExpireInSec, HttpError);
        SaveResultForRequestAccessAndRefreshTokens(
          OAuth20Setup, MessageText, Result, RequestAccessTokenTxt, AuthorizationSuccessfulTxt,
          AuthorizationFailedTxt, HttpError, RequestJsonContent, ResponseJson, ExpireInSec);
    end;


    /// <summary>
    /// Refreshes access token using application/json ContentType.
    /// </summary>
    [NonDebuggable]
    procedure RefreshAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText): Boolean
    begin
        exit(
            RefreshAccessTokenWithGivenRequestJson(
                OAuth20Setup, '', MessageText, ClientID, ClientSecret, AccessToken, RefreshToken));
    end;


    /// <summary>
    /// Refreshes access token with given request json using application/json ContentType.
    /// </summary>
    procedure RefreshAccessTokenWithGivenRequestJson(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText) Result: Boolean
    begin
        exit(RefreshAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, ClientID, ClientSecret, AccessToken, RefreshToken, false));
    end;


    /// <summary>
    /// Refreshes access token using application/x-www-form-urlencoded ContentType if UseUrlEncodedContentType is set to true or application/json ContentType otherwise.
    /// </summary>
    procedure RefreshAccessTokenWithContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText; UseUrlEncodedContentType: Boolean): Boolean
    begin
        exit(RefreshAccessTokenWithGivenRequestJsonAndContentType(OAuth20Setup, RequestJson, MessageText, ClientID, ClientSecret, AccessToken, RefreshToken, UseUrlEncodedContentType));
    end;

    local procedure RefreshAccessTokenWithGivenRequestJsonAndContentType(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var MessageText: Text; ClientID: Text; ClientSecret: SecretText; var AccessToken: SecretText; var RefreshToken: SecretText; UseUrlEncodedContentType: Boolean) Result: Boolean
    var
        RequestJsonContent: SecretText;
        ContentJson: SecretText;
        ResponseJson: Text;
        HttpError: Text;
        ExpireInSec: BigInteger;
    begin
        OAuth20Setup.Status := OAuth20Setup.Status::Disabled;
        OAuth20Setup.TestField("Service URL");
        OAuth20Setup.TestField("Refresh Token URL Path");
        OAuth20Setup.TestField("Client ID");
        OAuth20Setup.TestField("Client Secret");
        OAuth20Setup.TestField("Refresh Token");

        if UseUrlEncodedContentType then begin
            CreateContentRequestForRefreshAccessToken(ContentJson, ClientSecret, ClientID, RefreshToken);
            CreateRequestJSONForAccessRefreshTokenURLEncoded(RequestJson, OAuth20Setup."Service URL", OAuth20Setup."Refresh Token URL Path", ContentJson, RequestJsonContent);
        end else begin
            CreateContentRequestJSONForRefreshAccessToken(ContentJson, ClientSecret, ClientID, RefreshToken);
            CreateRequestJSONForAccessRefreshToken(RequestJson, OAuth20Setup."Service URL", OAuth20Setup."Refresh Token URL Path", ContentJson, RequestJsonContent);
        end;

        Result := RequestAccessAndRefreshTokens(RequestJsonContent, ResponseJson, AccessToken, RefreshToken, ExpireInSec, HttpError);
        SaveResultForRequestAccessAndRefreshTokens(
          OAuth20Setup, MessageText, Result, RefreshAccessTokenTxt, RefreshSuccessfulTxt,
          RefreshFailedTxt, HttpError, RequestJsonContent, ResponseJson, ExpireInSec);
    end;

    local procedure SaveResultForRequestAccessAndRefreshTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; Result: Boolean; Context: Text; SuccessMsg: Text; ErrorMsg: Text; HttpError: Text; RequestJson: SecretText; ResponseJson: Text; ExpireInSec: BigInteger)
    begin
        if Result then begin
            MessageText := SuccessMsg;
            OAuth20Setup.Status := OAuth20Setup.Status::Enabled;
            if ExpireInSec > 0 then
                OAuth20Setup."Access Token Due DateTime" := CurrentDateTime() + ExpireInSec * 1000;
        end else begin
            MessageText := ErrorMsg;
            if HttpError <> '' then
                MessageText += '\' + ReasonTxt + HttpError;
            OAuth20Setup.Status := OAuth20Setup.Status::Error;
        end;
        LogActivity(OAuth20Setup, Result, Context, MessageText, RequestJson, ResponseJson, true);
    end;

    procedure InvokeRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: SecretText; RetryOnCredentialsFailure: Boolean) Result: Boolean
    var
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
    begin
        if RetryOnCredentialsFailure and (OAuth20Setup."Access Token Due DateTime" <> 0DT) then
            if OAuth20Setup."Access Token Due DateTime" < CurrentDateTime() then begin
                if OAuth20Setup.RefreshAccessToken(HttpError) then
                    exit(OAuth20Setup.InvokeRequest(RequestJson, ResponseJson, HttpError, false));
                exit(false);
            end;

        Result := InvokeSingleRequest(OAuth20Setup, RequestJson, ResponseJson, HttpError, AccessToken);
        if not Result and RetryOnCredentialsFailure then
            if GetHttpStatusFromJsonResponse(ResponseJson, StatusCode, StatusReason, StatusDetails) then
                if StatusCode = 401 then // Unauthorized
                    if OAuth20Setup.RefreshAccessToken(HttpError) then
                        exit(OAuth20Setup.InvokeRequest(RequestJson, ResponseJson, HttpError, false));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RequestAuthorizationCode(OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        HyperLink(GetAuthorizationURLAsSecretText(OAuth20Setup, OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap()).Unwrap());
    end;


    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RequestAndSaveAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; AuthorizationCode: SecretText) Result: Boolean
    var
        AccessToken: SecretText;
        RefreshToken: SecretText;
    begin
        Result :=
          RequestAccessToken(
            OAuth20Setup, MessageText, AuthorizationCode,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap(), OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client Secret"),
            AccessToken, RefreshToken);

        if Result then
            SaveTokens(OAuth20Setup, AccessToken, RefreshToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RefreshAndSaveAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text) Result: Boolean
    var
        AccessToken: SecretText;
        RefreshToken: SecretText;
    begin
        RefreshToken := OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Refresh Token");
        Result :=
          RefreshAccessToken(
            OAuth20Setup, MessageText,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap(), OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client Secret"),
            AccessToken, RefreshToken);

        if Result then
            SaveTokens(OAuth20Setup, AccessToken, RefreshToken);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure InvokeRequestBasic(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJSON: Text; var ResponseJSON: Text; var HttpError: Text; RetryOnCredentialsFailure: Boolean): Boolean
    begin
        exit(
          InvokeRequest(
            OAuth20Setup, RequestJSON, ResponseJSON, HttpError,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Access Token"), RetryOnCredentialsFailure));
    end;

    [Scope('OnPrem')]
    procedure CheckEncryption()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        IsHandled: Boolean;
    begin
        OnBeforeCheckEncryption(IsHandled);
        if IsHandled then
            exit;
        if not EnvironmentInfo.IsSaaS() and not EncryptionEnabled() and GuiAllowed() then
            if Confirm(EncryptionIsNotActivatedQst) then
                Page.RunModal(Page::"Data Encryption Management");
    end;

    local procedure InvokeSingleRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJson: Text; var ResponseJson: Text; var HttpError: Text; AccessToken: SecretText) Result: Boolean
    var
        RequestJObject: JsonObject;
        HeaderJObject: JsonObject;
        JToken: JsonToken;
        RequestJsonSecret: SecretText;
    begin
        OAuth20Setup.TestField("Service URL");
        OAuth20Setup.TestField("Access Token");

        if RequestJObject.ReadFrom(RequestJson) then;
        RequestJObject.Add('ServiceURL', OAuth20Setup."Service URL");
        HeaderJObject.Add('Authorization', PlaceholderTok);
        if RequestJObject.SelectToken('Header', JToken) then
            JToken.AsObject().Add('Authorization', PlaceholderTok)
        else
            RequestJObject.Add('Header', HeaderJObject);

        RequestJObject.WriteWithSecretsTo('$.Header.Authorization', SecretStrSubstNo('Bearer %1', AccessToken), RequestJsonSecret);

        if OAuth20Setup."Latest Datetime" = 0DT then
            OAuth20Setup."Daily Count" := 0
        else
            if OAuth20Setup."Latest Datetime" < CreateDateTime(Today(), 0T) then
                OAuth20Setup."Daily Count" := 0;
        if (OAuth20Setup."Daily Limit" <= 0) or (OAuth20Setup."Daily Count" < OAuth20Setup."Daily Limit") or (OAuth20Setup."Latest Datetime" = 0DT) then begin
            Result := InvokeHttpJSONRequest(RequestJsonSecret, ResponseJson, HttpError);
            OAuth20Setup."Latest Datetime" := CurrentDateTime();
            OAuth20Setup."Daily Count" += 1;
        end else begin
            Result := false;
            HttpError := LimitExceededTxt;
            Session.LogMessage('00009YL', LimitExceededTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ActivityLogContextTxt);
        end;
        RequestJObject.Get('Method', JToken);
        LogActivity(
            OAuth20Setup, Result, StrSubstNo(InvokeRequestTxt, JToken.AsValue().AsText()),
            HttpError, RequestJsonSecret, ResponseJson, false);
    end;

    [NonDebuggable]
    local procedure SaveTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; AccessToken: SecretText; RefreshToken: SecretText)
    begin
        OAuth20Setup.SetToken(OAuth20Setup."Access Token", AccessToken);
        OAuth20Setup.SetToken(OAuth20Setup."Refresh Token", RefreshToken);
        OAuth20Setup.Modify();
        Commit(); // need to prevent rollback to save new keys
    end;

    local procedure RequestAccessAndRefreshTokens(RequestJson: SecretText; var ResponseJson: Text; var AccessToken: SecretText; var RefreshToken: SecretText; var ExpireInSec: BigInteger; var HttpError: Text): Boolean
    var
        AccessTokenText: Text;
        RefreshTokenText: Text;
        ResponseJsonText: Text;
    begin
        AccessTokenText := '';
        RefreshTokenText := '';
        ResponseJsonText := '';

        AccessToken := AccessTokenText;
        RefreshToken := RefreshTokenText;
        ResponseJson := ResponseJsonText;

        if InvokeHttpJSONRequest(RequestJson, ResponseJson, HttpError) then
            exit(ParseAccessAndRefreshTokens(ResponseJson, AccessToken, RefreshToken, ExpireInSec));
    end;

    local procedure ParseAccessAndRefreshTokens(ResponseJson: Text; var AccessToken: SecretText; var RefreshToken: SecretText; var ExpireInSec: BigInteger): Boolean
    var
        JToken: JsonToken;
        NewAccessToken: Text;
        NewRefreshToken: Text;
    begin
        NewAccessToken := '';
        NewRefreshToken := '';

        AccessToken := NewAccessToken;
        RefreshToken := NewRefreshToken;

        ExpireInSec := 0;

        if JToken.ReadFrom(ResponseJson) then
            if JToken.SelectToken('Content', JToken) then
                foreach JToken in JToken.AsObject().Values() do
                    case JToken.Path() of
                        'Content.access_token':
                            NewAccessToken := JToken.AsValue().AsText();
                        'Content.refresh_token':
                            NewRefreshToken := JToken.AsValue().AsText();
                        'Content.expires_in':
                            ExpireInSec := JToken.AsValue().AsBigInteger();
                    end;
        if (NewAccessToken = '') or (NewRefreshToken = '') then
            exit(false);

        AccessToken := NewAccessToken;
        RefreshToken := NewRefreshToken;
        exit(true);
    end;

    local procedure CreateRequestJSONForAccessRefreshTokenUrlEncoded(JsonString: Text; ServiceURL: Text; URLRequestPath: Text; ContentJson: SecretText; var RequestJsonContent: SecretText)
    var
        JObject: JsonObject;
    begin
        if JObject.ReadFrom(JsonString) then;
        JObject.Add('ServiceURL', ServiceURL);
        JObject.Add('Method', 'POST');
        JObject.Add('URLRequestPath', URLRequestPath);
        JObject.Add('Content-Type', 'application/x-www-form-urlencoded');
        JObject.Add('Content', PlaceholderTok);

        JObject.WriteWithSecretsTo('$.Content', ContentJson, RequestJsonContent);
    end;

    local procedure CreateRequestJSONForAccessRefreshToken(JsonString: Text; ServiceURL: Text; URLRequestPath: Text; ContentJson: SecretText; var RequestJsonContent: SecretText)
    var
        JObject: JsonObject;
    begin
        if JObject.ReadFrom(JsonString) then;
        JObject.Add('ServiceURL', ServiceURL);
        JObject.Add('Method', 'POST');
        JObject.Add('URLRequestPath', URLRequestPath);
        JObject.Add('Content-Type', 'application/json');
        JObject.Add('Content', PlaceholderTok);

        JObject.WriteWithSecretsTo('$.Content', ContentJson, RequestJsonContent);
    end;

    [NonDebuggable]
    local procedure CreateContentRequestForAccessToken(var UrlStringSecret: SecretText; ClientSecret: SecretText; ClientID: SecretText; RedirectURI: Text; AuthorizationCode: SecretText; CodeVerifier: SecretText)
    var
        HttpUtility: DotNet HttpUtility;
        UrlString: Text;
    begin
        UrlString := StrSubstNo(AuthCodeUrlTxt,
             HttpUtility.UrlEncode(ClientSecret.Unwrap()), HttpUtility.UrlEncode(ClientID.Unwrap()), HttpUtility.UrlEncode(RedirectURI), HttpUtility.UrlEncode(AuthorizationCode.Unwrap()));
        if CodeVerifier.Unwrap() <> '' then
            UrlString += StrSubstNo('&code_verifier=%1', CodeVerifier.Unwrap());

        UrlStringSecret := UrlString;
    end;

    local procedure CreateContentRequestJSONForAccessToken(var RequestJsonContent: SecretText; ClientSecret: SecretText; ClientID: SecretText; RedirectURI: Text; AuthorizationCode: SecretText; CodeVerifier: SecretText)
    var
        Secrets: Dictionary of [Text, SecretText];
        JObject: JsonObject;
    begin
        JObject.Add('grant_type', 'authorization_code');
        JObject.Add('client_secret', PlaceholderTok);
        JObject.Add('client_id', PlaceholderTok);
        JObject.Add('redirect_uri', RedirectURI);
        JObject.Add('code', PlaceholderTok);

        Secrets.Add('$.client_secret', ClientSecret);
        Secrets.Add('$.client_id', ClientID);
        Secrets.Add('$.code', AuthorizationCode);

        if not CodeVerifier.IsEmpty() then begin
            JObject.Add('code_verifier', PlaceholderTok);
            Secrets.Add('$.code_verifier', CodeVerifier);
        end;

        JObject.WriteWithSecretsTo(Secrets, RequestJsonContent);
    end;

    [NonDebuggable]
    local procedure CreateContentRequestForRefreshAccessToken(var UrlStringSecret: SecretText; ClientSecret: SecretText; ClientID: SecretText; RefreshToken: SecretText)
    var
        HttpUtility: DotNet HttpUtility;
        UrlString: Text;
    begin
        UrlString := StrSubstNo('grant_type=refresh_token&client_secret=%1&client_id=%2&refresh_token=%3',
            HttpUtility.UrlEncode(ClientSecret.Unwrap()), HttpUtility.UrlEncode(ClientID.Unwrap()), HttpUtility.UrlEncode(RefreshToken.Unwrap()));

        UrlStringSecret := UrlString;
    end;

    local procedure CreateContentRequestJSONForRefreshAccessToken(var RequestJsonContent: SecretText; ClientSecret: SecretText; ClientID: SecretText; RefreshToken: SecretText)
    var
        JObject: JsonObject;
        Secrets: Dictionary of [Text, SecretText];
    begin
        JObject.Add('grant_type', 'refresh_token');
        JObject.Add('client_secret', PlaceholderTok);
        JObject.Add('client_id', PlaceholderTok);
        JObject.Add('refresh_token', PlaceholderTok);

        Secrets.Add('$.client_secret', ClientSecret);
        Secrets.Add('$.client_id', ClientID);
        Secrets.Add('$.refresh_token', RefreshToken);

        JObject.WriteWithSecretsTo(Secrets, RequestJsonContent);
    end;

    [NonDebuggable]
    local procedure LogActivity(var OAuth20Setup: Record "OAuth 2.0 Setup"; Result: Boolean; ActivityDescription: Text; ActivityMessage: Text; RequestJson: SecretText; ResponseJson: Text; MaskContent: Boolean)
    var
        ActivityLog: Record "Activity Log";
        JObject: JsonObject;
        JToken: JsonToken;
        RequestJObject: JsonObject;
        ResponseJObject: JsonObject;
        Context: Text[30];
        Status: Option;
        JsonString: Text;
        Body: Text;
        DetailedInfoExists: Boolean;
    begin
        Body := RequestJson.Unwrap();
        Context := CopyStr(StrSubstNo('%1 %2', ActivityLogContextTxt, OAuth20Setup.Code), 1, MaxStrLen(Context));
        if Result then
            Status := ActivityLog.Status::Success
        else
            Status := ActivityLog.Status::Failed;

        ActivityLog.LogActivity(OAuth20Setup.RecordId(), Status, Context, ActivityDescription, ActivityMessage);
        if RequestJObject.ReadFrom(MaskHeaders(Body)) then begin
            if MaskContent then
                if RequestJObject.SelectToken('Content', JToken) then
                    RequestJObject.Replace('Content', '***');
            JObject.Add('Request', RequestJObject);
            DetailedInfoExists := true;
        end;
        if ResponseJObject.ReadFrom(ResponseJson) then begin
            if MaskContent then
                if ResponseJObject.SelectToken('Content', JToken) then
                    ResponseJObject.Replace('Content', '***');
            JObject.Add('Response', ResponseJObject);
            DetailedInfoExists := true;
        end;
        if DetailedInfoExists then
            if JObject.WriteTo(JsonString) then
                if JsonString <> '' then
                    ActivityLog.SetDetailedInfoFromText(JsonString);
        OAuth20Setup."Activity Log ID" := ActivityLog.ID;
        OAuth20Setup.Modify();

        Commit(); // need to prevent rollback to save the log
    end;

    [NonDebuggable]
    local procedure MaskHeaders(RequestJson: Text) Result: Text;
    var
        JObject: JsonObject;
        JToken: JsonToken;
        KeyValue: Text;
    begin
        Result := RequestJson;
        if JObject.ReadFrom(RequestJson) then
            if JObject.SelectToken('Header', JToken) then begin
                foreach KeyValue in JToken.AsObject().Keys() do
                    JToken.AsObject().Replace(KeyValue, '***');
                JObject.WriteTo(Result);
            end;
    end;

    [NonDebuggable]
    local procedure SetHttpStatus(var JObject: JsonObject; StatusCode: Integer; StatusReason: Text; StatusDetails: Text)
    var
        JObject2: JsonObject;
    begin
        JObject2.Add('code', StatusCode);
        JObject2.Add('reason', StatusReason);
        if StatusDetails <> '' then
            JObject2.Add('details', StatusDetails);
        JObject.Add('Status', JObject2);
    end;

    [NonDebuggable]
    procedure GetHttpStatusFromJsonResponse(JsonString: Text; var StatusCode: Integer; var StatusReason: Text; var StatusDetails: Text): Boolean
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        if JObject.ReadFrom(JsonString) then
            if JObject.SelectToken('Status', JToken) then begin
                foreach JToken in JToken.AsObject().Values() do
                    case JToken.Path() of
                        'Status.code':
                            StatusCode := JToken.AsValue().AsInteger();
                        'Status.reason':
                            StatusReason := JToken.AsValue().AsText();
                        'Status.details':
                            StatusDetails := JToken.AsValue().AsText();
                    end;
                exit(true);
            end;
    end;

    [NonDebuggable]
    local procedure InvokeHttpJSONRequest(RequestJsonSecret: SecretText; var ResponseJson: Text; var HttpError: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ErrorMessage: Text;
        RequestJson: Text;
    begin
        RequestJson := RequestJsonSecret.Unwrap();
        ResponseJson := '';
        HttpError := '';

        Client.Clear();
        Client.Timeout(60000);
        InitHttpRequestContent(RequestMessage, RequestJson);
        InitHttpRequestMessage(RequestMessage, RequestJson);

        if not Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsBlockedByEnvironment() then
                ErrorMessage := StrSubstNo(EnvironmentBlocksErr, RequestMessage.GetRequestUri())
            else
                ErrorMessage := StrSubstNo(ConnectionErr, RequestMessage.GetRequestUri());

        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit(ProcessHttpResponseMessage(ResponseMessage, ResponseJson, HttpError));
    end;

    [NonDebuggable]
    local procedure InitHttpRequestContent(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        ContentHeaders: HttpHeaders;
        RequestContent: HttpContent;
        JToken: JsonToken;
        JValue: JsonValue;
        ContentJToken: JsonToken;
        ContentTypeJToken: JsonToken;
        ContentDispositionJToken: JsonToken;
        ContentJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then
            if JToken.SelectToken('Content', ContentJToken) then begin
                if ContentJToken.IsObject() then
                    ContentJToken.WriteTo(ContentJson)
                else begin
                    JValue := ContentJToken.AsValue();
                    ContentJson := JValue.AsText();
                end;
                if ContentJson = '' then
                    exit;
                RequestMessage.Content().Clear();
                RequestContent.WriteFrom(ContentJson);
                RequestMessage.Content := RequestContent;
                if JToken.SelectToken('Content-Type', ContentTypeJToken) then begin
                    RequestMessage.Content().GetHeaders(ContentHeaders);
                    ContentHeaders.Clear();
                    ContentHeaders.Add('Content-Type', ContentTypeJToken.AsValue().AsText());
                    if JToken.SelectToken('Content-Disposition', ContentDispositionJToken) then
                        ContentHeaders.Add('Content-Disposition', ContentDispositionJToken.AsValue().AsText());
                end;
            end;
    end;

    [NonDebuggable]
    local procedure InitHttpRequestMessage(var RequestMessage: HttpRequestMessage; RequestJson: Text)
    var
        RequestHeaders: HttpHeaders;
        JToken: JsonToken;
        JToken2: JsonToken;
        ServiceURL: Text;
        HeadersJson: Text;
    begin
        if JToken.ReadFrom(RequestJson) then begin
            RequestMessage.GetHeaders(RequestHeaders);
            RequestHeaders.Clear();
            if JToken.SelectToken('Accept', JToken2) then
                RequestHeaders.Add('Accept', JToken2.AsValue().AsText());
            if JToken.AsObject().Get('Header', JToken2) then begin
                JToken2.WriteTo(HeadersJson);
                if JToken2.ReadFrom(HeadersJson) then
                    foreach JToken2 in JToken2.AsObject().Values() do
                        RequestHeaders.Add(JToken2.Path(), JToken2.AsValue().AsText());
            end;

            if JToken.SelectToken('Method', JToken2) then
                RequestMessage.Method(JToken2.AsValue().AsText());

            if JToken.SelectToken('ServiceURL', JToken2) then begin
                ServiceURL := JToken2.AsValue().AsText();
                if JToken.SelectToken('URLRequestPath', JToken2) then
                    ServiceURL += JToken2.AsValue().AsText();
                RequestMessage.SetRequestUri(ServiceURL);
            end;
        end;
    end;

    [NonDebuggable]
    local procedure ProcessHttpResponseMessage(var ResponseMessage: HttpResponseMessage; var ResponseJson: Text; var HttpError: Text) Result: Boolean
    var
        ResponseJObject: JsonObject;
        ContentJObject: JsonObject;
        JToken: JsonToken;
        ResponseText: Text;
        JsonResponse: Boolean;
        StatusCode: Integer;
        StatusReason: Text;
        StatusDetails: Text;
    begin
        Result := ResponseMessage.IsSuccessStatusCode();
        StatusCode := ResponseMessage.HttpStatusCode();
        StatusReason := ResponseMessage.ReasonPhrase();

        if ResponseMessage.Content().ReadAs(ResponseText) then
            JsonResponse := ContentJObject.ReadFrom(ResponseText);
        if JsonResponse then
            ResponseJObject.Add('Content', ContentJObject)
        else
            ResponseJObject.Add('ContentText', ResponseText);

        if not Result then begin
            HttpError := StrSubstNo('HTTP error %1 (%2)', StatusCode, StatusReason);
            if JsonResponse then
                if ContentJObject.SelectToken('error_description', JToken) then begin
                    StatusDetails := JToken.AsValue().AsText();
                    HttpError += StrSubstNo('\%1', StatusDetails);
                end;
        end;

        SetHttpStatus(ResponseJObject, StatusCode, StatusReason, StatusDetails);
        ResponseJObject.WriteTo(ResponseJson);
    end;

    [NonDebuggable]
    local procedure ExtendAuthorizationURLWithCodeChallenge(var AuthorizationUrl: SecretText; OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        CodeVerifier: SecretText;
    begin
        if OAuth20Setup."Code Challenge Method" = OAuth20Setup."Code Challenge Method"::" " then
            exit;
        CodeVerifier := GenerateRandomCodeVerifier();
        OAuth20Setup.SetToken(OAuth20Setup."Code Verifier", CodeVerifier);
        OAuth20Setup.Modify(true);
        AuthorizationUrl := SecretStrSubstNo('%1&code_challenge=%2&code_challenge_method=%3', AuthorizationUrl, GenerateCodeChallenge(OAuth20Setup."Code Challenge Method", CodeVerifier), Format(OAuth20Setup."Code Challenge Method"));
    end;

    [NonDebuggable]
    local procedure ExtendWithNonce(var AuthorizationUrl: SecretText; OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        if OAuth20Setup."Use Nonce" then
            AuthorizationUrl := SecretStrSubstNo('%1&nonce=%2', AuthorizationUrl, GenerateRandomCodeVerifier());
    end;


    [NonDebuggable]
    local procedure GenerateRandomCodeVerifier(): SecretText
    var
        Convert: Codeunit "Base64 Convert";
    begin
        exit(Encode(Convert.ToBase64(CreateGuid())));
    end;

    [NonDebuggable]
    local procedure GenerateCodeChallenge(CodeChallengeMethod: Enum "OAuth 2.0 Code Challenge"; CodeVerifier: SecretText): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        if CodeChallengeMethod <> CodeChallengeMethod::S256 then
            exit;
        exit(Encode(CryptographyManagement.GenerateHashAsBase64String(CodeVerifier.UnWrap(), Enum::"Hash Algorithm"::SHA256.AsInteger())));
    end;

    [NonDebuggable]
    local procedure Encode(Input: Text) Encoded: Text
    begin
        Encoded := Input.TrimEnd('=');
        Encoded := Encoded.Replace('+', '-');
        Encoded := Encoded.Replace('/', '_');
        exit(Encoded);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEncryption(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServiceUrlForAuthorizationURL(var ServiceUrl: Text; OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
    end;
}