namespace System.Security.Authentication;

using Microsoft.Foundation.Enums;
using System.Integration;
using System.Security.AccessControl;

table 1140 "OAuth 2.0 Setup"
{
    Caption = 'OAuth 2.0 Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Service URL"; Text[250])
        {
            Caption = 'Service URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Service URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Service URL");
            end;
        }
        field(4; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
        }
        field(5; "Client ID"; Guid)
        {
            Caption = 'Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Client Secret"; Guid)
        {
            Caption = 'Client Secret';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Access Token"; Guid)
        {
            Caption = 'Access Token';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Refresh Token"; Guid)
        {
            Caption = 'Refresh Token';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Authorization URL Path"; Text[250])
        {
            Caption = 'Authorization URL Path';

            trigger OnValidate()
            begin
                CheckAndAppendURLPath("Authorization URL Path");
            end;
        }
        field(10; "Access Token URL Path"; Text[250])
        {
            Caption = 'Access Token URL Path';

            trigger OnValidate()
            begin
                CheckAndAppendURLPath("Access Token URL Path");
            end;
        }
        field(11; "Refresh Token URL Path"; Text[250])
        {
            Caption = 'Refresh Token URL Path';

            trigger OnValidate()
            begin
                CheckAndAppendURLPath("Refresh Token URL Path");
            end;
        }
        field(12; Scope; Text[250])
        {
            Caption = 'Scope';
        }
        field(13; "Authorization Response Type"; Text[250])
        {
            Caption = 'Authorization Response Type';
        }
        field(14; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Enabled,Disabled,Connected,Error';
            OptionMembers = " ",Enabled,Disabled,Connected,Error;
        }
        field(15; "Token DataScope"; Option)
        {
            Caption = 'Token DataScope';
            OptionCaption = 'Module,User,Company,UserAndCompany';
            OptionMembers = Module,User,Company,UserAndCompany;
        }
        field(16; "Activity Log ID"; Integer)
        {
            Caption = 'Activity Log ID';
        }
        field(17; "Daily Limit"; Integer)
        {
            Caption = 'Daily Limit';
            Editable = false;
        }
        field(18; "Daily Count"; Integer)
        {
            Caption = 'Daily Count';
            Editable = false;
        }
        field(19; "Latest Datetime"; DateTime)
        {
            Caption = 'Latest Datetime';
            Editable = false;
        }
        field(20; "Access Token Due DateTime"; DateTime)
        {
            Caption = 'Access Token Due DateTime';
            Editable = false;
        }
        field(21; "Feature GUID"; Guid)
        {
            Caption = 'Feature GUID';
            Editable = false;
        }
        field(22; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(50; "Code Challenge Method"; Enum "OAuth 2.0 Code Challenge")
        {
        }
        field(51; "Code Verifier"; Guid)
        {

        }
        field(52; "Use Nonce"; Boolean)
        {

        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteToken("Client ID");
        DeleteToken("Client Secret");
        DeleteToken("Access Token");
        DeleteToken("Refresh Token");
    end;

    var
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";

    local procedure CheckAndAppendURLPath(var value: Text)
    begin
        if value <> '' then
            if value[1] <> '/' then
                value := '/' + value;
    end;

    [NonDebuggable]
    internal procedure SetToken(var TokenKey: Guid; TokenValue: SecretText)
    begin
        if IsNullGuid(TokenKey) then
            TokenKey := CreateGuid();

        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(TokenKey, TokenValue, GetTokenDataScope())
        else
            IsolatedStorage.Set(TokenKey, TokenValue, GetTokenDataScope());
    end;

    [NonDebuggable]
    internal procedure GetTokenAsSecretText(TokenKey: Guid) TokenValue: SecretText
    begin
        if not HasToken(TokenKey) then
            exit(TokenValue);

        IsolatedStorage.Get(TokenKey, GetTokenDataScope(), TokenValue);
    end;

    [NonDebuggable]
    internal procedure DeleteToken(TokenKey: Guid)
    begin
        if not HasToken(TokenKey) then
            exit;

        IsolatedStorage.Delete(TokenKey, GetTokenDataScope());
    end;

    [NonDebuggable]
    internal procedure HasToken(TokenKey: Guid): Boolean
    begin
        exit(not IsNullGuid(TokenKey) and IsolatedStorage.Contains(TokenKey, GetTokenDataScope()));
    end;

    procedure GetTokenDataScope(): DataScope
    begin
        case "Token DataScope" of
            "Token DataScope"::Company:
                exit(DataScope::Company);
            "Token DataScope"::UserAndCompany:
                exit(DataScope::CompanyAndUser);
            "Token DataScope"::User:
                exit(DataScope::User);
            "Token DataScope"::Module:
                exit(DataScope::Module);
        end;
    end;

    [NonDebuggable]
    internal procedure RequestAuthorizationCode()
    var
        Processed: Boolean;
    begin
        OAuth20Mgt.CheckEncryption();

        OnBeforeRequestAuthoizationCode(Rec, Processed);
        if Processed then
            exit;

        OAuth20Mgt.RequestAuthorizationCode(Rec);
    end;

    [NonDebuggable]
    internal procedure RequestAccessToken(var MessageText: Text; AuthorizationCode: Text) Result: Boolean
    var
        Processed: Boolean;
    begin
        OnBeforeRequestAccessToken(Rec, AuthorizationCode, Result, MessageText, Processed);
        if not Processed then
            Result := OAuth20Mgt.RequestAndSaveAccessToken(Rec, MessageText, AuthorizationCode);

        OnAfterRequestAccessToken(Rec, Result, MessageText);
    end;

    [NonDebuggable]
    internal procedure RefreshAccessToken(var MessageText: Text) Result: Boolean
    var
        Processed: Boolean;
    begin
        OnBeforeRefreshAccessToken(Rec, Result, MessageText, Processed);
        if not Processed then
            Result := OAuth20Mgt.RefreshAndSaveAccessToken(Rec, MessageText);
    end;

    [NonDebuggable]
    internal procedure InvokeRequest(RequestJSON: Text; var ResponseJSON: Text; var HttpError: Text; RetryOnCredentialsFailure: Boolean) Result: Boolean
    var
        Processed: Boolean;
    begin
        OnBeforeInvokeRequest(Rec, RequestJSON, ResponseJSON, HttpError, Result, Processed, RetryOnCredentialsFailure);
        if not Processed then
            Result := OAuth20Mgt.InvokeRequestBasic(Rec, RequestJSON, ResponseJSON, HttpError, RetryOnCredentialsFailure);
    end;

    procedure FindSetOAuth20SetupByFeature(FeatureGUID: Guid): Boolean
    begin
        SetRange("Feature GUID", FeatureGUID);
        exit(FindSet());
    end;

    procedure FindFirstOAuth20SetupByFeatureAndCurrUser(FeatureGUID: Guid): Boolean
    begin
        SetRange("Feature GUID", FeatureGUID);
        SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen("User Id")));
        exit(FindFirst());
    end;

    procedure FindFirstOAuth20SetupByFeatureAndUser(FeatureGUID: Guid; OAuthUserID: Code[50]): Boolean
    begin
        SetRange("Feature GUID", FeatureGUID);
        SetRange("User ID", OAuthUserID);
        exit(FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRequestAccessToken(OAuth20Setup: Record "OAuth 2.0 Setup"; Result: Boolean; var MessageText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRequestAuthoizationCode(OAuth20Setup: Record "OAuth 2.0 Setup"; var Processed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefreshAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; var Result: Boolean; var MessageText: Text; var Processed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRequestAccessToken(var OAuth20Setup: Record "OAuth 2.0 Setup"; AuthorizationCode: Text; var Result: Boolean; var MessageText: Text; var Processed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvokeRequest(var OAuth20Setup: Record "OAuth 2.0 Setup"; RequestJSON: Text; var ResponseJSON: Text; var HttpError: Text; var Result: Boolean; var Processed: Boolean; RetryOnCredentialsFailure: Boolean)
    begin
    end;
}
