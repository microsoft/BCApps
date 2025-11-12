// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Security.Authentication;

page 1276 "Doc. Exch. Service Auth."
{
    Extensible = false;
    Caption = 'Waiting for a response - do not close this page';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            usercontrol(OAuthIntegration; OAuthControlAddIn)
            {
                ApplicationArea = All;
                trigger AuthorizationCodeRetrieved(code: Text)
                var
                    StateOut: Text;
                begin
                    GetOAuthProperties(code, AuthCode, StateOut);

                    if State = '' then begin
                        Session.LogMessage('0000EXP', MissingStateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                        AuthError := AuthError + NoStateErr;
                    end else
                        if StateOut <> State then begin
                            Session.LogMessage('0000EXQ', MismatchingStateErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                            AuthError := AuthError + NotMatchingStateErr;
                        end;

                    CurrPage.Close();
                end;

                trigger AuthorizationErrorOccurred(error: Text; desc: Text);
                begin
                    Session.LogMessage('0000EXR', StrSubstNo(OauthFailErrMsg, error, desc), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                    AuthError := StrSubstNo(AuthCodeErrorLbl, error, desc);
                    CurrPage.Close();
                end;

                trigger ControlAddInReady();
                begin
                    Session.LogMessage('0000EXS', OAuthCodeStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                    CurrPage.OAuthIntegration.StartAuthorization(OAuthRequestUrl);
                end;
            }
        }
    }

    [Scope('OnPrem')]
    procedure SetOAuth2Properties(AuthRequestUrl: Text; AuthInitialState: Text)
    begin
        OAuthRequestUrl := AuthRequestUrl;
        State := AuthInitialState;
    end;
#if not CLEAN25

    [Obsolete('Replaced by GetAuthCodeAsSecretText', '25.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetAuthCode(): Text
    begin
        exit(GetAuthCodeAsSecretText().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetAuthCodeAsSecretText(): SecretText
    begin
        exit(AuthCode);
    end;

    [Scope('OnPrem')]
    procedure GetAuthError(): Text
    begin
        exit(AuthError);
    end;

#if not CLEAN25
    [Scope('OnPrem')]
    [Obsolete('Replaced by GetOAuthProperties(AuthorizationCode: Text; var CodeOut: SecretText; var StateOut: Text)', '25.0')]
    [NonDebuggable]
    procedure GetOAuthProperties(AuthorizationCode: Text; var CodeOut: Text; var StateOut: Text)
    var
        CodeOutAsSecretText: SecretText;
    begin
        CodeOutAsSecretText := CodeOut;
        GetOAuthProperties(AuthorizationCode, CodeOutAsSecretText, StateOut);
        CodeOut := CodeOutAsSecretText.Unwrap();
    end;
#endif

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetOAuthProperties(AuthorizationCode: Text; var CodeOut: SecretText; var StateOut: Text)
    begin
        if AuthorizationCode = '' then begin
            Session.LogMessage('0000EXT', AuthorizationCodeErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit;
        end;

        if AuthorizationCode.EndsWith('#') then
            AuthorizationCode := CopyStr(AuthorizationCode, 1, StrLen(AuthorizationCode) - 1);

        CodeOut := GetPropertyFromCode(AuthorizationCode, 'code');
        StateOut := GetPropertyFromCode(AuthorizationCode, 'state');
    end;

    [NonDebuggable]
    local procedure GetPropertyFromCode(CodeTxt: Text; Property: Text): Text
    var
        PosProperty: Integer;
        PosValue: Integer;
        PosEnd: Integer;
    begin
        PosProperty := StrPos(CodeTxt, Property);
        if PosProperty = 0 then
            exit('');
        PosValue := PosProperty + StrPos(CopyStr(Codetxt, PosProperty), '=');
        PosEnd := PosValue + StrPos(CopyStr(CodeTxt, PosValue), '&');

        if PosEnd = PosValue then
            exit(CopyStr(CodeTxt, PosValue, StrLen(CodeTxt) - 1));
        exit(CopyStr(CodeTxt, PosValue, PosEnd - PosValue - 1));
    end;

    var
        [NonDebuggable]
        OAuthRequestUrl: Text;
        [NonDebuggable]
        State: Text;
        AuthCode: SecretText;
        [NonDebuggable]
        AuthError: Text;
        CategoryTxt: Label 'AL Document Exchange Service', Locked = true;
        MissingStateErr: Label 'The returned authorization code is missing information about the returned state.', Locked = true;
        MismatchingStateErr: Label 'The authroization code returned state is missmatching the expected state value.', Locked = true;
        OauthFailErrMsg: Label 'Error: %1 ; Description: %2.', Comment = '%1 = OAuth error message ; %2 = description of OAuth failure error message', Locked = true;
        OAuthCodeStartMsg: Label 'The authorization code flow grant process has started.', Locked = true;
        NoStateErr: Label 'No state has been returned.';
        NotMatchingStateErr: Label 'The state parameter value does not match.';
        AuthCodeErrorLbl: Label 'Error: %1, description: %2', Comment = '%1 = The authorization error message, %2 = The authorization error description';
        AuthorizationCodeErr: Label 'The OAuth2 authentication code retrieved is empty.', Locked = true;
}
