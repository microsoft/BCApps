// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

using System.Security.Authentication;

codeunit 9144 "SharePoint Authorization Code" implements "SharePoint Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        ClientId: Text;
        [NonDebuggable]
        ClientSecret: SecretText;
        [NonDebuggable]
        AuthCodeErr: Text;
        [NonDebuggable]
        EntraTenantId: Text;
        [NonDebuggable]
        Scopes: List of [Text];
        AuthorityTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', Comment = '%1 = Microsoft Entra tenant ID', Locked = true;
        BearerTxt: Label 'Bearer %1', Comment = '%1 - Token', Locked = true;

    [NonDebuggable]
    procedure SetParameters(NewEntraTenantId: Text; NewClientId: Text; NewClientSecret: SecretText; NewScopes: List of [Text])
    begin
        EntraTenantId := NewEntraTenantId;
        ClientId := NewClientId;
        ClientSecret := NewClientSecret;
        Scopes := NewScopes;
    end;

    [NonDebuggable]
    procedure Authorize(var HttpRequestMessage: HttpRequestMessage);
    var
        Headers: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo(BearerTxt, GetToken()));
    end;

    [NonDebuggable]
    local procedure GetToken(): SecretText
    var
        ErrorText: Text;
        [NonDebuggable]
        AccessToken: SecretText;
    begin
        if not AcquireToken(AccessToken, ErrorText) then
            Error(ErrorText);
        exit(AccessToken);
    end;

    [NonDebuggable]
    local procedure AcquireToken(var AccessToken: SecretText; var ErrorText: Text): Boolean
    var
        OAuth2: Codeunit OAuth2;
        IsHandled, IsSuccess : Boolean;
        EventAccessToken: Text;
    begin
#if not CLEAN24
        OnBeforeGetToken(IsHandled, IsSuccess, ErrorText, EventAccessToken);
#endif
        OnBeforeGetSecretToken(IsHandled, IsSuccess, ErrorText, AccessToken);

        if not IsHandled then begin
            if (not OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, '', StrSubstNo(AuthorityTxt, EntraTenantId), Scopes, AccessToken)) or (AccessToken.IsEmpty()) then
                OAuth2.AcquireTokenByAuthorizationCode(ClientId, ClientSecret, StrSubstNo(AuthorityTxt, EntraTenantId), '', Scopes, "Prompt Interaction"::None, AccessToken, AuthCodeErr);

            IsSuccess := not AccessToken.IsEmpty();

            if AuthCodeErr <> '' then
                ErrorText := AuthCodeErr
            else
                ErrorText := GetLastErrorText();
        end
        else
            AccessToken := EventAccessToken;

        exit(IsSuccess);
    end;

#if not CLEAN24
    [InternalEvent(false, true)]
    [Obsolete('Use OnBeforeGetSecretToken with SecretText data type for AccessToken instead.', '24.0')]
    local procedure OnBeforeGetToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: Text)
    begin
    end;
#endif

    [InternalEvent(false, true)]
    local procedure OnBeforeGetSecretToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: SecretText)
    begin
    end;
}