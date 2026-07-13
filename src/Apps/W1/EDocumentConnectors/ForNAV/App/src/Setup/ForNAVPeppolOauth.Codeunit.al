// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument.Integration.Send;
using System.Azure.Identity;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

codeunit 6422 "ForNAV Peppol Oauth"
{
    Access = Internal;

    var
        SetupKeyLbl: Label 'setupKey', Locked = true;
        BaseUrlLbl: Label 'https://fornavpeppol.azure-api.net/', Locked = true;
        RequestConfigLbl: Label 'RequestConfig', Locked = true;
        RotateSecretLbl: Label 'RotateSecret', Locked = true;
        ClientIdKeyLbl: Label 'ClientIdKey', Locked = true;
        TenantIdKeyLbl: Label 'TenantIdKey', Locked = true;
        ClientSecretKeyLbl: Label 'SecretKey', Locked = true;
        ScopeEndpointLbl: Label 'ScopeEndpoint', Locked = true;
        ScopeConfigLbl: Label 'ScopeConfig', Locked = true;
        SecretValidFromKeyLbl: Label 'SecretValidFromKey', Locked = true;
        SecretValidToKeyLbl: Label 'SecretValidToKey', Locked = true;
        InvalidCLientIdErr: Label 'Invalid client id. Contact your ForNAV partner.';

    local procedure SetSecretStorage("Key": Text; keyValue: SecretText)
    var
        Setup: Codeunit "ForNAV Peppol Setup";
    begin
        if keyValue.IsEmpty() then
            DeleteIsolatedStorage("Key")
        else
            IsolatedStorage.Set("Key", keyValue, DataScope::Module);

        Setup.ClearAccessToken();
    end;

    internal procedure GetSecretStorage("Key": Text) keyValue: SecretText
    begin
        if IsolatedStorage.Contains("Key", DataScope::Module) then
            IsolatedStorage.Get("Key", DataScope::Module, keyValue);
    end;

    local procedure SetIsolatedStorage("Key": Text; keyValue: Text)
    var
        Setup: Codeunit "ForNAV Peppol Setup";
    begin
        if keyValue = '' then
            DeleteIsolatedStorage("Key")
        else
            IsolatedStorage.Set("Key", keyValue, DataScope::Module);

        Setup.ClearAccessToken();
    end;

    local procedure GetIsolatedStorage("Key": Text) keyValue: Text
    begin
        if IsolatedStorage.Contains("Key", DataScope::Module) then
            IsolatedStorage.Get("Key", DataScope::Module, keyValue);
    end;

    local procedure DeleteIsolatedStorage("Key": Text)
    begin
        if IsolatedStorage.Contains("Key", DataScope::Module) then
            IsolatedStorage.Delete("Key", DataScope::Module);
    end;

    internal procedure ValidateClientID(ClientId: Text)
    begin
        SetIsolatedStorage(ClientIdKeyLbl, ClientId);
    end;

    internal procedure GetClientID(): Text
    begin
        exit(GetIsolatedStorage(ClientIdKeyLbl));
    end;

    internal procedure ValidateForNAVTenantID(TenantId: Text)
    begin
        SetIsolatedStorage(TenantIdKeyLbl, TenantId);
    end;

    internal procedure GetForNAVTenantID(): Text
    begin
        exit(GetIsolatedStorage(TenantIdKeyLbl));
    end;

    internal procedure ValidateSecret(Secret: SecretText)
    begin
        SetSecretStorage(ClientSecretKeyLbl, Secret);
    end;

    internal procedure GetClientSecret(): SecretText
    begin
        exit(GetSecretStorage(ClientSecretKeyLbl));
    end;

    [NonDebuggable]
    internal procedure ValidateScope(Scope: Text)
    var
        ScopePart: Text;
        EndpointLbl: Label 'endpoint', Locked = true;
        ConfigLbl: Label 'config', Locked = true;
    begin
        DeleteIsolatedStorage(ScopeEndpointLbl);
        DeleteIsolatedStorage(ScopeConfigLbl);

        if Scope = '' then
            exit;

        foreach ScopePart in Scope.Split(';') do begin
            if ScopePart.StartsWith(EndpointLbl) then
                SetSecretStorage(ScopeEndpointLbl, ScopePart.Split(',').Get(2));
            if ScopePart.StartsWith(ConfigLbl) then
                SetSecretStorage(ScopeConfigLbl, ScopePart.Split(',').Get(2));
        end;
    end;

    internal procedure GetEndpointScope() Scopes: List of [SecretText];
    begin
        Scopes.Add(GetSecretStorage(ScopeEndpointLbl));
    end;

    internal procedure GetConfigScope() Scopes: List of [SecretText];
    begin
        Scopes.Add(GetSecretStorage(ScopeConfigLbl));
    end;

    internal procedure GetScopes() Scopes: List of [SecretText];
    begin
        Scopes.Add(GetSecretStorage(ScopeConfigLbl));
        Scopes.Add(GetSecretStorage(ScopeEndpointLbl));
    end;

    internal procedure GetEndpoint() Result: Text
    var
        Setup: Record "ForNAV Peppol Setup";
        RegEx: Codeunit Regex;
        InvalidEndpointErr: Label 'Endpoint contains invalid characters. Only lowercase letters and numbers are allowed.';
    begin
        case true of
            not Setup.FindFirst(),
            Setup.Endpoint = '':
                exit(GetDefaultEndpoint());
        end;

        if not RegEx.IsMatch(Setup.Endpoint, '^[a-z0-9]+$') then
            Error(InvalidEndpointErr);

        exit(Setup.Endpoint);
    end;

    internal procedure GetDefaultEndpoint(): Text[20]
    var
        DefaultEndpointLbl: Label 'v2', Locked = true;
    begin
        exit(DefaultEndpointLbl);
    end;

    local procedure ValidateSecretValidFrom(SecretValidFrom: DateTime)
    begin
        if SecretValidFrom.Date = 0D then
            DeleteIsolatedStorage(SecretValidFromKeyLbl)
        else
            SetIsolatedStorage(SecretValidFromKeyLbl, Format(SecretValidFrom, 0, 9));
    end;

    internal procedure GetSecretValidFrom() Result: DateTime
    var
        SecretValidFrom: Text;
    begin
        SecretValidFrom := GetIsolatedStorage(SecretValidFromKeyLbl);
        if SecretValidFrom = '' then
            exit(CreateDateTime(0D, 0T));

        Evaluate(Result, SecretValidFrom);
        Result := ToLocalTime(Result);
    end;

    internal procedure ValidateSecretValidTo(SecretValidTo: DateTime)
    begin
        if SecretValidTo.Date = 0D then begin
            ValidateSecretValidFrom(CreateDateTime(0D, 0T));
            DeleteIsolatedStorage(SecretValidToKeyLbl);
            exit;
        end;

        ValidateSecretValidFrom(CreateDateTime(Today, Time));
        SetIsolatedStorage(SecretValidToKeyLbl, Format(SecretValidTo, 0, 9));
    end;

    internal procedure GetSecretValidTo() Result: DateTime
    var
        SecretValidTo: Text;
    begin
        SecretValidTo := GetIsolatedStorage(SecretValidToKeyLbl);
        if SecretValidTo = '' then
            exit(CreateDateTime(0D, 0T));

        Evaluate(Result, SecretValidTo);
        Result := ToLocalTime(Result);
    end;

    local procedure ToLocalTime(UtcDateTime: DateTime) Result: DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        TimeZoneOffset: Duration;
    begin
        if not TypeHelper.GetUserTimezoneOffset(TimeZoneOffset) then
            exit;

        Result := UtcDateTime + TimeZoneOffset;
    end;

    [NonDebuggable]
    internal procedure SetSetupKey()
    var
        PasswordHandler: Codeunit "Password Handler";
    begin
        SetSecretStorage(SetupKeyLbl, PasswordHandler.GenerateSecretPassword(20));
    end;

    internal procedure GetSetupKey(): SecretText
    begin
        exit(GetSecretStorage(SetupKeyLbl));
    end;

    internal procedure ResetSetupKey()
    begin
        DeleteIsolatedStorage(SetupKeyLbl);
    end;

    internal procedure GetInstallationId() Result: Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            exit(AzureADTenant.GetAadTenantId());

        exit(Database.SerialNumber());
    end;

    internal procedure ResetForSetup()
    begin
        ValidateClientId('');
        ValidateForNAVTenantID('');
        ValidateSecret(SecretStrSubstNo(''));
        ValidateScope('');
        ValidateSecretValidTo(CreateDateTime(0D, 0T));
        ResetSetupKey();
    end;

    internal procedure GetPeppolEndpointURL() Url: Text
    var
        PeppolAPEndpointLbl: Label 'bc/apendpoint', Locked = true;
    begin
        Url := BaseUrlLbl + PeppolAPEndpointLbl + '/' + GetEndpoint();
        if Url.EndsWith('/') then
            exit(Url)
        else
            exit(Url + '/');
    end;

    local procedure GetPeppolSetupURL(Endpoint: Text) Url: Text
    var
        ForNAVPeppolConfigLbl: Label 'bc/config', Locked = true;
    begin
        if Endpoint = '' then
            Endpoint := GetDefaultEndpoint();

        Url := BaseUrlLbl + ForNAVPeppolConfigLbl + '/' + Endpoint;
        if Url.EndsWith('/') then
            exit(Url)
        else
            exit(Url + '/');
    end;

    internal procedure GetOAuthAuthorityUrl(): Text
    var
        OAuthAuthorityUrlTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
    begin
        exit(StrSubstNo(OAuthAuthorityUrlTxt, GetForNAVTenantID()));
    end;

    [TryFunction]
    internal procedure TryTestOAuth()
    var
        Response: Text;
    begin
        TestOAuth(Response);
    end;

    internal procedure TestOAuth(var Response: Text)
    var
        SendContext: Codeunit SendContext;
        Setup: Codeunit "ForNAV Peppol Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseCode: Integer;
        EndpointLbl: Label '%1Test', Locked = true;
        HttpErr: Label 'Http error: %1\Reason: %2', Comment = '%1= statuscode %2= reasonphrase';
    begin
        Setup.ClearAccessToken();
        if GetClientID() = '' then
            Error(InvalidCLientIdErr);

        HttpRequestMessage := SendContext.Http().GetHttpRequestMessage();
        HttpRequestMessage.SetRequestUri(StrSubstNo(EndpointLbl, GetPeppolEndpointURL()));
        HttpRequestMessage.Method('GET');

        ResponseCode := Setup.Send(HttpClient, SendContext.Http());
        SendContext.Http().GetHttpResponseMessage().Content.ReadAs(Response);
        if ResponseCode = 200 then
            exit;

        HttpResponseMessage := SendContext.Http().GetHttpResponseMessage();
        if ResponseCode = 407 then
            Error(HttpErr, ResponseCode, GetLastErrorText())
        else
            Error(HttpErr, ResponseCode, Response);
    end;

    [Obsolete('Roles are no longer stored; role-based access is not used.', '1.0.0.0')]
    internal procedure StoreRoles(Roles: List of [Text])
    var
#Pragma warning disable AL0432
        PeppolRole: Record "ForNAV Peppol Role";
#Pragma warning restore AL0432
        i: Integer;
    begin
        PeppolRole.DeleteAll();
        for i := 1 to Roles.Count do begin
            PeppolRole.Init();
            PeppolRole.Role := CopyStr(Roles.Get(i), 1, MaxStrLen(PeppolRole.Role));
            PeppolRole.Insert();
        end;
    end;

    [NonDebuggable]
    internal procedure SendSetupRequest(IsSaas: Boolean; NewEndpoint: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
    begin
        if IsSaas then
            HttpRequestMessage.SetRequestUri(GetPeppolSetupURL(NewEndpoint) + RequestConfigLbl)
        else
            exit;

        HttpRequestMessage.GetHeaders(HttpHeaders);
        AddSetupHeaders(HttpHeaders);
        HttpRequestMessage.Method('POST');
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        exit(HttpResponseMessage.HttpStatusCode = 204);
    end;

    [NonDebuggable]
    internal procedure GetNewSecurityKey(): Boolean
    var
        OAuthToken: Codeunit "ForNAV Peppol Oauth Token";
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        AccessToken: SecretText;
        AccessTokenExpires: DateTime;
        Response: Text;
        ResponseObject: JsonObject;
        Token: JsonToken;
        CannotRotateKeyErr: Label 'Cannot rotate key. Contact your ForNAV partner.\%1', Comment = '%1 = reason';
        DialogLbl: Label 'Request new client secret from the FORNAV Peppol Network. Please wait...';
        Dlg: Dialog;
    begin
        Dlg.Open(DialogLbl);
        HttpRequestMessage.SetRequestUri(GetPeppolSetupURL(GetEndpoint()) + RotateSecretLbl);

        HttpRequestMessage.GetHeaders(HttpHeaders);
        AddSetupHeaders(HttpHeaders);

        OAuthToken.AcquireTokenWithClientCredentials(GetClientID(), GetClientSecret(), GetOAuthAuthorityUrl(), '', GetConfigScope());
        OAuthToken.GetAccessToken(AccessToken, AccessTokenExpires);

        HttpHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));

        HttpRequestMessage.Method('POST');
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        HttpResponseMessage.Content.ReadAs(Response);
        if not ResponseObject.ReadFrom(Response) then
            Error(CannotRotateKeyErr, HttpResponseMessage.ReasonPhrase);

        if HttpResponseMessage.HttpStatusCode <> 200 then
            Error(CannotRotateKeyErr, HttpResponseMessage.ReasonPhrase);

        ResponseObject.Get('clientId', Token);
        if GetClientID() <> Token.AsValue().AsText() then
            Error(InvalidCLientIdErr);

        ResponseObject.Get('clientSecret', Token);
        ValidateSecret(Token.AsValue().AsText());
        ResponseObject.Get('expires', Token);
        ValidateSecretValidTo(Token.AsValue().AsDateTime());
        Dlg.Close();
        exit(true);
    end;

    local procedure AddSetupHeaders(var HttpHeaders: HttpHeaders)
    var
        Company: Record Company;
        PeppolSetup: Record "ForNAV Peppol Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        TenantInformation: Codeunit "Tenant Information";
        AppInfo: ModuleInfo;
    begin
        PeppolSetup.InitSetup();
        HttpHeaders.Add(SetupKeyLbl, GetSetupKey());
        HttpHeaders.Add('tenantId', GetInstallationId());
        HttpHeaders.Add('bcTenantId', TenantInformation.GetTenantId());
        HttpHeaders.Add('environmentName', EnvironmentInformation.GetEnvironmentName());
        Company.Get(CompanyName);
        HttpHeaders.Add('companyId', Format(Company.SystemId).TrimStart('{').TrimEnd('}'));
        HttpHeaders.Add('companyName', HtmlEncode(PeppolSetup.Name));
        HttpHeaders.Add('idCode', HtmlEncode(PeppolSetup."Identification Code"));
        HttpHeaders.Add('idValue', HtmlEncode(PeppolSetup."Identification Value"));
        HttpHeaders.Add('serialNumber', Database.SerialNumber());
        HttpHeaders.Add('contactName', HtmlEncode(PeppolSetup."Contact Person"));
        HttpHeaders.Add('contactEmail', PeppolSetup."E-Mail");
        NavApp.GetCurrentModuleInfo(AppInfo);
        HttpHeaders.Add('appVersion', HtmlEncode(Format(AppInfo.AppVersion)));
        HttpHeaders.Add('appPublisher', HtmlEncode(Format(AppInfo.Publisher)));
    end;

    local procedure HTMLEncode(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.HtmlEncode(Input));
    end;
}