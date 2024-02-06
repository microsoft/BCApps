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
        ClientSecret: SecretText;
        [NonDebuggable]
        AuthCodeErr: Text;
        [NonDebuggable]
        EntraTenantId: Text;
        [NonDebuggable]
        Scopes: List of [Text];
        AuthorityTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', Comment = '%1 = Microsoft Entra tenant ID', Locked = true;
        BearerTxt: Label 'Bearer %1', Comment = '%1 - Token', Locked = true;

    procedure SetParameters(NewEntraTenantId: Text; NewClientId: Text; NewClientSecret: SecretText; NewScopes: List of [Text])
    begin
        EntraTenantId := NewEntraTenantId;
        ClientId := NewClientId;
        ClientSecret := NewClientSecret;
        Scopes := NewScopes;
    end;

    procedure Authorize(var HttpRequestMessage: HttpRequestMessage);
    var
        Headers: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo(BearerTxt, GetToken()));
    end;

    local procedure GetToken(): SecretText
    var
        ErrorText: Text;
        AccessToken: SecretText;
    begin
        if not AcquireToken(AccessToken, ErrorText) then
            Error(ErrorText);
        exit(AccessToken);
    end;

    local procedure AcquireToken(var AccessToken: SecretText; var ErrorText: Text): Boolean
    var
        OAuth2: Codeunit OAuth2;
        IsHandled, IsSuccess : Boolean;
        EventAccessToken: Text;
    begin
        OnBeforeGetSecretToken(IsHandled, IsSuccess, ErrorText, AccessToken);
#if not CLEAN24
        if not IsHandled then begin
#pragma warning disable AL0432
            OnBeforeGetToken(IsHandled, IsSuccess, ErrorText, EventAccessToken);
#pragma warning restore AL0432
            if IsHandled then
                AccessToken := EventAccessToken;
        end;
#endif

        if not IsHandled then begin
            if (not OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, '', StrSubstNo(AuthorityTxt, EntraTenantId), Scopes, AccessToken)) or (AccessToken.IsEmpty()) then
                OAuth2.AcquireTokenByAuthorizationCode(ClientId, ClientSecret, StrSubstNo(AuthorityTxt, EntraTenantId), '', Scopes, "Prompt Interaction"::None, AccessToken, AuthCodeErr);

            IsSuccess := not AccessToken.IsEmpty();

            if AuthCodeErr <> '' then
                ErrorText := AuthCodeErr
            else
                ErrorText := GetLastErrorText();
        end;

        exit(IsSuccess);
    end;

#if not CLEAN24
    [InternalEvent(false, true)]
    [Obsolete('Replaced by OnBeforeGetSecretToken with SecretText data type for AccessToken parameter.', '24.0')]
    local procedure OnBeforeGetToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: Text)
    begin
    end;
#endif

    [InternalEvent(false, true)]
    local procedure OnBeforeGetSecretToken(var IsHandled: Boolean; var IsSuccess: Boolean; var ErrorText: Text; var AccessToken: SecretText)
    begin
    end;
}