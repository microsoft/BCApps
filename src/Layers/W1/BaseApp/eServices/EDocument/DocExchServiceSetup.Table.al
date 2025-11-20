// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Integration;
using System.Privacy;
using System.Security.Encryption;
using System.Telemetry;
using System.Threading;

table 1275 "Doc. Exch. Service Setup"
{
    Caption = 'Doc. Exch. Service Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(4; "Sign-up URL"; Text[250])
        {
            Caption = 'Sign-up URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Sign-up URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Sign-up URL");
            end;
        }
        field(5; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Service URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Service URL");
            end;
        }
        field(6; "Sign-in URL"; Text[250])
        {
            Caption = 'Sign-in URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Sign-in URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Sign-in URL");
            end;
        }
#if not CLEANSCHEMA26
        field(7; "Consumer Key"; Guid)
        {
            Caption = 'Consumer Key';
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
        field(8; "Consumer Secret"; Guid)
        {
            Caption = 'Consumer Secret';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
        field(9; Token; Guid)
        {
            Caption = 'Token';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
        field(10; "Token Secret"; Guid)
        {
            Caption = 'Token Secret';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
        field(11; "Doc. Exch. Tenant ID"; Guid)
        {
            Caption = 'Doc. Exch. Tenant ID';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(12; "User Agent"; Text[30])
        {
            Caption = 'User Agent';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(13; "Client Id"; Text[250])
        {
            Caption = 'Client Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(15; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Redirect URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Redirect URL");
            end;
        }
        field(16; "Auth URL"; Text[250])
        {
            Caption = 'Authentication URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Auth URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Auth URL");
            end;
        }
        field(17; "Token URL"; Text[250])
        {
            Caption = 'Token URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Token URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Token URL");
            end;
        }
        field(18; "Access Token Key"; Guid)
        {
            Caption = 'Access Token Key';
            DataClassification = CustomerContent;
        }
        field(19; "Refresh Token Key"; Guid)
        {
            Caption = 'Refresh Token Key';
            DataClassification = CustomerContent;
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                AuditLog: Codeunit "Audit Log";
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                DocExchServiceSetupConsentProvidedLbl: Label 'Document Exchange Service Setup - consent has been provided by UserSecurityId %1.', Locked = true;
            begin
                if Enabled then begin
                    if not CustomerConsentMgt.ConfirmUserConsent() then
                        Enabled := false;
                    if Enabled then
                        AuditLog.LogAuditMessage(StrSubstNo(DocExchServiceSetupConsentProvidedLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                    DocExchServiceMgt.VerifyPrerequisites(true);
                end;
            end;
        }
        field(21; "Log Web Requests"; Boolean)
        {
            Caption = 'Log Web Requests';
        }
        field(24; "Token Subject"; Text[250])
        {
            Caption = 'Token Subject';
            DataClassification = AccountData;
        }
        field(25; "Token Issued At"; DateTime)
        {
            Caption = 'Token Issued At';
            DataClassification = AccountData;
        }
        field(27; "Id Token"; Text[1024])
        {
            Caption = 'Id Token';
            DataClassification = AccountData;
        }
        field(28; "Token Expired"; Boolean)
        {
            Caption = 'Id Token';
            DataClassification = AccountData;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempClientSecret: SecretText;
        TempAccessToken: SecretText;
        TempRefreshToken: SecretText;

    trigger OnDelete()
    begin
        DeleteClientSecret();
        DeleteAccessToken();
        DeleteRefreshToken();
    end;

    trigger OnModify()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000IM7', DocExchServiceMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        if IsEnabledChanged() then
            if Enabled then
                EnableConnection()
            else
                DisableConnection();
    end;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        LogTelemetryWhenServiceCreated();
        if Enabled then
            EnableConnection()
        else
            DisableConnection();
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        JobQEntriesCreatedQst: Label 'A job queue entry for exchanging documents has been created.\\Do you want to open the Job Queue Entries page?';
        DocExchServiceCreatedTxt: Label 'The user started setting up document exchange service.', Locked = true;
        DocExchServiceEnabledTxt: Label 'The user enabled document exchange service.', Locked = true;
        DocExchServiceDisabledTxt: Label 'The user disabled document exchange service.', Locked = true;
        TelemetryCategoryTok: Label 'AL Document Exchange Service', Locked = true;

    [Scope('OnPrem')]
    procedure SetClientSecret(ClientSecretText: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempClientSecret := ClientSecretText;
            exit;
        end;

        if IsNullGuid("Client Secret Key") then begin
            "Client Secret Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        IsolatedStorageManagement.Set(Format("Client Secret Key"), ClientSecretText, DATASCOPE::Company);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [Obsolete('Replaced by GetClientSecretAsSecretText', '25.0')]
    [NonDebuggable]
    procedure GetClientSecret(): Text
    begin
        exit(GetClientSecretAsSecretText().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetClientSecretAsSecretText(): SecretText
    var
        Value: SecretText;
    begin
        if IsTemporary() then
            exit(TempClientSecret);

        if not IsNullGuid("Client Secret Key") then
            if IsolatedStorageManagement.Get(Format("Client Secret Key"), DATASCOPE::Company, Value) then
                exit(Value);

        Clear(Value);
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure DeleteClientSecret()
    begin
        if IsTemporary() then begin
            Clear(TempClientSecret);
            exit;
        end;

        if IsNullGuid("Client Secret Key") then
            exit;

        IsolatedStorageManagement.Delete(Format("Client Secret Key"), DATASCOPE::Company);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [Obsolete('Replaced by SetAccessToken(AccessToken: SecretText)', '25.0')]
    procedure SetAccessToken(AccessToken: Text)
    var
        AccessTokenAsSecretText: SecretText;
    begin
        AccessTokenAsSecretText := AccessToken;
        SetAccessToken(AccessTokenAsSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetAccessToken(AccessToken: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempAccessToken := AccessToken;
            exit;
        end;

        if IsNullGuid("Access Token Key") then begin
            "Access Token Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        SetToken("Access Token Key", AccessToken);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetAccessTokenAsSecretText', '25.0')]
    procedure GetAccessToken(): Text
    begin
        exit(GetAccessTokenAsSecretText().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetAccessTokenAsSecretText(): SecretText
    var
        Value: SecretText;
    begin
        if IsTemporary() then
            exit(TempAccessToken);

        if IsNullGuid("Access Token Key") then
            exit(Value);

        Value := GetTokenAsSecretText("Access Token Key");
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure DeleteAccessToken()
    begin
        if IsTemporary() then begin
            Clear(TempAccessToken);
            exit;
        end;

        if IsNullGuid("Access Token Key") then
            exit;

        DeleteToken("Access Token Key");
    end;
#if not CLEAN25

    [Obsolete('Replaced by SetRefreshToken(RefreshToken: SecretText)', '25.0')]
    [Scope('OnPrem')]
    procedure SetRefreshToken(RefreshToken: Text)
    var
        RefreshTokenAsSecretText: SecretText;
    begin
        RefreshTokenAsSecretText := RefreshToken;
        SetRefreshToken(RefreshTokenAsSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetRefreshToken(RefreshToken: SecretText)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempRefreshToken := RefreshToken;
            exit;
        end;

        if IsNullGuid("Refresh Token Key") then begin
            "Refresh Token Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        SetToken("Refresh Token Key", RefreshToken);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetRefreshTokenAsSecretText', '25.0')]
    procedure GetRefreshToken(): Text
    begin
        exit(GetRefreshTokenAsSecretText().Unwrap())
    end;
#endif

    [Scope('OnPrem')]
    procedure GetRefreshTokenAsSecretText(): SecretText
    var
        Value: SecretText;
    begin
        if IsTemporary() then
            exit(TempRefreshToken);

        if IsNullGuid("Refresh Token Key") then
            exit(Value);

        Value := GetTokenAsSecretText("Refresh Token Key");
        exit(Value);
    end;

    [Scope('OnPrem')]
    procedure DeleteRefreshToken()
    begin
        if IsTemporary() then begin
            Clear(TempRefreshToken);
            exit;
        end;

        if IsNullGuid("Refresh Token Key") then
            exit;

        DeleteToken("Refresh Token Key");
    end;

    local procedure DeleteToken(TokenKey: Guid)
    var
        I: Integer;
        N: Integer;
        PartKey: Text;
    begin
        N := GetMaxTokenPartCount();
        for I := 1 to N do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            if not IsolatedStorageManagement.Delete(PartKey, DataScope::Company) then
                break;
        end;
    end;

    [NonDebuggable]
    local procedure GetTokenAsSecretText(TokenKey: Guid): SecretText
    var
        I: Integer;
        N: Integer;
        PartKey: Text;
        TokenPart: SecretText;
        TokenValue: Text;
    begin
        N := GetMaxTokenPartCount();
        for I := 1 to N do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            if IsolatedStorageManagement.Get(PartKey, DataScope::Company, TokenPart) then
                TokenValue += TokenPart.Unwrap()
            else
                break;
        end;
        exit(TokenValue);
    end;

    [NonDebuggable]
    local procedure SetToken(TokenKey: Guid; TokenValueAsSecretText: SecretText): Boolean
    var
        TokenLen: Integer;
        PartLen: Integer;
        PartCount: Integer;
        PartKey: Text;
        TokenPart: Text;
        TokenValue: Text;
        TokenPartAsSecretText: SecretText;
        I: Integer;
    begin
        DeleteToken(TokenKey);

        TokenValue := TokenValueAsSecretText.Unwrap();
        TokenLen := StrLen(TokenValue);
        PartLen := GetMaxTokenPartLength();
        PartCount := TokenLen div PartLen;
        if TokenLen > (PartCount * PartLen) then
            PartCount += 1;

        if PartCount > GetMaxTokenPartCount() then begin
            PartKey := GetTokenPartKey(TokenKey, 1);
            exit(IsolatedStorageManagement.Set(PartKey, TokenValueAsSecretText, DataScope::Company));
        end;

        for I := 1 to PartCount do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            TokenPart := CopyStr(TokenValue, (PartLen * (I - 1)) + 1, PartLen);
            TokenPartAsSecretText := TokenPart;
            if not TokenPartAsSecretText.IsEmpty() then
                if not IsolatedStorageManagement.Set(PartKey, TokenPartAsSecretText, DataScope::Company) then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure GetTokenPartKey(TokenKey: Guid; PartNumber: Integer): Text
    begin
        exit(Format(TokenKey) + '#' + Format(PartNumber))
    end;

    local procedure GetMaxTokenPartLength(): Integer
    begin
        exit(100);
    end;

    local procedure GetMaxTokenPartCount(): Integer
    begin
        exit(21);
    end;

    [Scope('OnPrem')]
    procedure SetDefaultRedirectUrl()
    begin
        DocExchServiceMgt.SetDefaultRedirectUrl(Rec);
    end;

    procedure SetURLsToDefault()
    var
        Sandbox: Boolean;
    begin
        Sandbox := DocExchServiceMgt.IsSandbox(Rec);
        SetURLsToDefault(Sandbox);
    end;

    [Scope('OnPrem')]
    procedure SetURLsToDefault(Sandbox: Boolean)
    begin
        DocExchServiceMgt.SetURLsToDefault(Rec, Sandbox);
    end;

    [Scope('OnPrem')]
    procedure CheckConnection()
    begin
        DocExchServiceMgt.CheckConnection();
    end;

    internal procedure IsEnabledChanged(): Boolean
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if Enabled <> xRec.Enabled then
            exit(true);
        if DocExchServiceSetup.Get() then
            exit(Enabled <> DocExchServiceSetup.Enabled);
        exit(false);
    end;

    local procedure EnableConnection()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnableConnection(Rec, IsHandled);
        if IsHandled then
            exit;

        Enabled := false;
        Modify();
        DocExchServiceMgt.AcquireAccessTokenByAuthorizationCode(false);
        Get();
        Enabled := true;
        Modify();
        DocExchServiceMgt.CheckConnection();
        ScheduleJobQueueEntries();
        LogTelemetryWhenServiceEnabled();

        if not GuiAllowed() then
            exit;

        DocExchServiceMgt.RecallActivateAppNotification();

        if Confirm(JobQEntriesCreatedQst) then
            ShowJobQueueEntry();
    end;

    local procedure DisableConnection()
    begin
        Enabled := false;
        CancelJobQueueEntries();
        LogTelemetryWhenServiceDisabled();
    end;

    procedure ScheduleJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordID;
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status", DummyRecId);
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.", DummyRecId);
    end;

    procedure CancelJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status");
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");
    end;

    local procedure CancelJobQueueEntry(ObjType: Option; ObjID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.FindJobQueueEntry(ObjType, ObjID) then
            JobQueueEntry.Cancel();
    end;

    procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2',
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status",
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");
        if JobQueueEntry.FindFirst() then
            PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure LogTelemetryWhenServiceEnabled()
    begin
        Session.LogMessage('00008A9', DocExchServiceEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008AA', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceDisabled()
    begin
        Session.LogMessage('00008AB', DocExchServiceDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008AC', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceCreated()
    begin
        Session.LogMessage('00008AD', DocExchServiceCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnableConnection(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"; var IsHandled: Boolean)
    begin
    end;
}

