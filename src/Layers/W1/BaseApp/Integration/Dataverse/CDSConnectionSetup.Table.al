// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Utilities;
using System.Environment;
using System.Privacy;
using System.Security.Encryption;
using System.Threading;
using System.Telemetry;

table 7200 "CDS Connection Setup"
{
    Caption = 'Dataverse Connection Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Server Address"; Text[250])
        {
            Caption = 'Environment URL';
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                EnvironmentInfo: Codeunit "Environment Information";
            begin
                CDSIntegrationImpl.CheckModifyConnectionURL("Server Address");

                if "Server Address" <> '' then
                    if EnvironmentInfo.IsSaaS() or (StrPos("Server Address", '.dynamics.com') > 0) then
                        "Authentication Type" := "Authentication Type"::Office365
                    else
                        "Authentication Type" := "Authentication Type"::AD;
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(3; "User Name"; Text[250])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                "User Name" := DelChr("User Name", '<>');
                CDSIntegrationImpl.CheckUserName(Rec);
                CDSIntegrationImpl.UpdateDomainName(Rec);
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(4; "User Password Key"; Guid)
        {
            Caption = 'User Password Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(60; "Is Enabled"; Boolean)
        {
            Caption = 'Synchronization Enabled';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMConnectionSetup: Record "CRM Connection Setup";
                AuditLog: Codeunit "Audit Log";
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                CDSConnectionConsentLbl: Label 'CDS Connection Setup - consent has been provided by UserSecurityId %1.', Locked = true;
            begin
                if not "Is Enabled" then begin
                    if CRMConnectionSetup.Get() then
                        if CRMConnectionSetup."Is Enabled" then
                            Error(CannotDisableCDSErr);
                    Session.LogMessage('0000CDG', CDSConnDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    exit;
                end;

                Session.LogMessage('0000CDS', CDSConnEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                AuditLog.LogAuditMessage(StrSubstNo(CDSConnectionConsentLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);

                if IsTemporary() then begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    CDSIntegrationImpl.CheckConnectionRequiredFieldsMatch(Rec, false);
                    exit;
                end;

                CDSIntegrationImpl.CheckConnectionRequiredFieldsMatch(Rec, false);

                if not CDSIntegrationImpl.TryCheckCredentials(Rec) then
                    Error(GetLastErrorText());
                if Rec."Is Enabled" and (CurrFieldNo <> 0) then
                    if Rec."Business Events Enabled" then
                        Rec."Is Enabled" := true
                    else
                        Rec."Is Enabled" := CustomerConsentMgt.ConfirmUserConsentToMicrosoftService();
            end;
        }
        field(61; "Business Events Enabled"; Boolean)
        {
            Caption = 'Business Events Enabled';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
            begin
                if not Rec."Business Events Enabled" then begin
                    Session.LogMessage('0000CDG', BusinessEventsDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    exit;
                end;

                Session.LogMessage('0000GBC', BusinessEventsEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

                if IsTemporary() then begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    exit;
                end;

                if not CDSIntegrationImpl.TryCheckCredentials(Rec) then
                    Error(GetLastErrorText());
                if not Rec."Business Events Enabled" then
                    Clear(Rec."Virtual Tables Config Id")
                else
                    if CurrFieldNo <> 0 then
                        if Rec."Is Enabled" then
                            Rec."Business Events Enabled" := true
                        else
                            Rec."Business Events Enabled" := CustomerConsentMgt.ConfirmUserConsentToMicrosoftService();
            end;
        }
        field(76; "Proxy Version"; Integer)
        {
            Caption = 'Proxy Version';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(118; CurrencyDecimalPrecision; Integer)
        {
            Caption = 'Currency Decimal Precision';
            Description = 'Number of decimal places that can be used for currency.';
            DataClassification = SystemMetadata;
        }
        field(124; BaseCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the base currency of the organization.';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
            DataClassification = SystemMetadata;
        }
        field(133; BaseCurrencyPrecision; Integer)
        {
            Caption = 'Base Currency Precision';
            Description = 'Number of decimal places that can be used for the base currency.';
            DataClassification = SystemMetadata;
            MaxValue = 4;
            MinValue = 0;
        }
        field(134; BaseCurrencySymbol; Text[5])
        {
            Caption = 'Base Currency Symbol';
            Description = 'Symbol used for the base currency.';
            DataClassification = SystemMetadata;
        }
        field(135; "Authentication Type"; Option)
        {
            Caption = 'Authentication Type';
            OptionCaption = 'OAuth 2.0,AD,IFD,OAuth';
            OptionMembers = Office365,AD,IFD,OAuth;
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                case "Authentication Type" of
                    "Authentication Type"::Office365:
                        Domain := '';
                    "Authentication Type"::AD:
                        CDSIntegrationImpl.UpdateDomainName(Rec);
                end;
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(136; "Connection String"; Text[2048])
        {
            Caption = 'Connection String';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(137; Domain; Text[250])
        {
            Caption = 'Domain';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }
        field(139; "Disable Reason"; Text[250])
        {
            Caption = 'Disable Reason';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(140; "Ownership Model"; Option)
        {
            Caption = 'Ownership Model';
            OptionMembers = ,Person,Team;
            OptionCaption = ',Person,Team';
            DataClassification = SystemMetadata;
        }
        field(150; "Business Unit Id"; Guid)
        {
            Caption = 'Business Unit ID';
            DataClassification = SystemMetadata;
        }
        field(151; "Business Unit Name"; Text[160])
        {
            Caption = 'Business Unit Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(153; "Client Id"; Text[250])
        {
            Caption = 'Client Id';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(154; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(155; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(156; "Virtual Tables Config Id"; Guid)
        {
            Caption = 'Virtual Tables Config ID';
            DataClassification = SystemMetadata;
        }
        field(241; BaseCurrencyCode; Text[5])
        {
            Caption = 'Base Currency Code';
            Description = 'ISO currency code for the base currency.';
            TableRelation = "CRM Transactioncurrency".ISOCurrencyCode;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if IsTemporary() then
            exit;

        CDSIntegrationImpl.InsertBusinessUnitCoupling(Rec);

        if "Is Enabled" then
            EnableConnection()
        else
            DisableConnection();
    end;

    trigger OnModify()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        PasswordChanged: Boolean;
        ClientSecretChanged: Boolean;
        BusinessUnitChanged: Boolean;
        IsEnabledChanged: Boolean;
    begin
        if IsTemporary() then
            exit;

        GetConfigurationUpdates(PasswordChanged, BusinessUnitChanged, IsEnabledChanged, ClientSecretChanged);

        if PasswordChanged then
            CDSConnectionSetup.DeletePassword();

        if ClientSecretChanged then
            CDSConnectionSetup.DeleteClientSecret();

        GetConfigurationUpdates(PasswordChanged, BusinessUnitChanged, IsEnabledChanged, ClientSecretChanged);

        if PasswordChanged then
            CDSConnectionSetup.DeletePassword();

        if ClientSecretChanged then
            CDSConnectionSetup.DeleteClientSecret();

        if BusinessUnitChanged then
            CDSIntegrationImpl.ModifyBusinessUnitCoupling(Rec);

        if IsEnabledChanged then
            if "Is Enabled" then
                EnableConnection()
            else
                DisableConnection();
    end;

    trigger OnDelete()
    begin
        if IsTemporary() then
            exit;

        DeletePassword();
        DeleteClientSecret();
        CDSIntegrationImpl.DeleteBusinessUnitCoupling(Rec);
        DisableConnection();
    end;

    local procedure EnableConnection()
    begin
        if CDSIntegrationImpl.ImportAndConfigureIntegrationSolution(Rec, false) then
            CDSIntegrationImpl.CheckIntegrationRequirements(Rec, false);
        CDSIntegrationImpl.RegisterConnection(Rec, false);
        CDSIntegrationImpl.ClearConnectionDisableReason(Rec);
        EnableIntegrationTables();

        CDSIntegrationMgt.OnEnableIntegration();
    end;

    local procedure GetConfigurationUpdates(var PasswordChanged: Boolean; var BusinessUnitChanged: Boolean; var IsEnabledChanged: Boolean; var ClientSecretChanged: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        PasswordChanged := "User Password Key" <> xRec."User Password Key";
        ClientSecretChanged := "Client Secret Key" <> xRec."Client Secret Key";
        BusinessUnitChanged := "Business Unit Id" <> xRec."Business Unit Id";
        IsEnabledChanged := "Is Enabled" <> xRec."Is Enabled";
        if not (PasswordChanged or BusinessUnitChanged or IsEnabledChanged) then
            if CDSConnectionSetup.Get() then begin
                PasswordChanged := "User Password Key" <> CDSConnectionSetup."User Password Key";
                ClientSecretChanged := "Client Secret Key" <> xRec."Client Secret Key";
                BusinessUnitChanged := "Business Unit Id" <> CDSConnectionSetup."Business Unit Id";
                IsEnabledChanged := "Is Enabled" <> CDSConnectionSetup."Is Enabled";
            end;
    end;

    local procedure DisableConnection()
    begin
        UpdateCDSJobQueueEntriesStatus();
        CDSIntegrationImpl.UnregisterConnection();
        CDSIntegrationMgt.OnDisableIntegration();
    end;

    [Scope('OnPrem')]
    procedure HasPassword(): Boolean
    begin
        exit(not GetSecretPassword().IsEmpty());
    end;

#if not CLEAN25
    [Obsolete('Use GetSecretPassword instead.', '25.0')]
    [NonDebuggable]
    procedure GetPassword(): Text
    begin
        exit(GetSecretPassword().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetSecretPassword(): SecretText
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Value: SecretText;
    begin
        if IsTemporary() then
            exit(TempUserPassword);

        if not IsNullGuid("User Password Key") then
            if IsolatedStorageManagement.Get("User Password Key", DATASCOPE::Company, Value) then
                exit(Value);

    end;

#if not CLEAN25
    [Obsolete('Use SetPassword with SecretText parameter instead.', '25.0')]
    [NonDebuggable]
    procedure SetPassword(PasswordText: Text)
    var
        SecretPasswordText: SecretText;
    begin
        SecretPasswordText := PasswordText;
        SetPassword(SecretPasswordText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetPassword(PasswordText: SecretText)
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            TempUserPassword := PasswordText;
            exit;
        end;

        if IsNullGuid("User Password Key") then
            "User Password Key" := CreateGuid();

        IsolatedStorageManagement.Set(Format("User Password Key"), PasswordText, DATASCOPE::Company);
    end;

#if not CLEAN25
    [Obsolete('Use GetSecretAccessToken instead.', '25.0')]
    [NonDebuggable]
    procedure GetAccessToken(): Text
    begin
        exit(GetSecretAccessToken().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetSecretAccessToken(): SecretText
    begin
        if IsTemporary() then
            exit(TempAccessToken);
    end;

#if not CLEAN25
    [NonDebuggable]
    [Obsolete('Use SetAccessToken with SecretText parameter instead.', '25.0')]
    procedure SetAccessToken(AccessToken: Text)
    var
        SecretAccessToken: SecretText;
    begin
        SecretAccessToken := AccessToken;
        SetAccessToken(SecretAccessToken);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetAccessToken(AccessToken: SecretText)
    begin
        if IsTemporary() then begin
            TempAccessToken := AccessToken;
            exit;
        end;

        Clear(TempAccessToken);
    end;


    [Scope('OnPrem')]
    procedure DeletePassword()
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            Clear(TempUserPassword);
            exit;
        end;

        if IsNullGuid("User Password Key") then
            exit;

        IsolatedStorageManagement.Delete(Format("User Password Key"), DATASCOPE::Company);
    end;

#if not CLEAN25
    [Obsolete('Use SetClientSecret with SecretText parameter instead.', '25.0')]
    [NonDebuggable]
    procedure SetClientSecret(ClientSecretText: Text)
    var
        SecretClientSecretText: SecretText;
    begin
        SecretClientSecretText := ClientSecretText;
        SetClientSecret(SecretClientSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetClientSecret(ClientSecretText: SecretText)
    var
        DummyCDSConnectionSetup: Record "CDS Connection Setup";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            TempClientSecret := ClientSecretText;
            exit;
        end;

        if IsNullGuid("Client Secret Key") then begin
            "Client Secret Key" := CreateGuid();
            if DummyCDSConnectionSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        IsolatedStorageManagement.Set(Format("Client Secret Key"), ClientSecretText, DATASCOPE::Company);
    end;

#if not CLEAN25
    [Obsolete('Use GetSecretClientSecret instead', '25.0')]
    [NonDebuggable]
    procedure GetClientSecret(): Text
    begin
        exit(GetSecretClientSecret().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetSecretClientSecret(): SecretText
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Value: SecretText;
    begin
        if IsTemporary() then
            exit(TempClientSecret);

        if not IsNullGuid("Client Secret Key") then
            if IsolatedStorageManagement.Get("Client Secret Key", DATASCOPE::Company, Value) then
                exit(Value);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure DeleteClientSecret()
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            Clear(TempClientSecret);
            exit;
        end;

        if IsNullGuid("Client Secret Key") then
            exit;

        IsolatedStorageManagement.Delete(Format("Client Secret Key"), DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure SynchronizeNow(DoFullSynch: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        CDSSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);

        TempNameValueBuffer.Ascending(true);
        if not TempNameValueBuffer.FindSet() then
            exit;

        repeat
            if IntegrationTableMapping.Get(TempNameValueBuffer.Value) then
                IntegrationTableMapping.SynchronizeNow(DoFullSynch);
        until TempNameValueBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure EnableIntegrationTables()
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        Modify(); // Job Queue to read "Is Enabled"
        Commit();
        CDSSetupDefaults.ResetConfiguration(Rec);
    end;

    procedure SetBaseCurrencyData()
    var
        CRMOrganization: Record "CRM Organization";
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
    begin
        CDSIntegrationMgt.RegisterConnection();
        CDSIntegrationMgt.ActivateConnection();
        if CRMOrganization.FindFirst() then
            if CRMTransactioncurrency.Get(CRMOrganization.BaseCurrencyId) then begin
                CurrencyDecimalPrecision := CRMOrganization.CurrencyDecimalPrecision;
                BaseCurrencyId := CRMOrganization.BaseCurrencyId;
                BaseCurrencyPrecision := CRMOrganization.BaseCurrencyPrecision;
                BaseCurrencySymbol := CRMOrganization.BaseCurrencySymbol;
                BaseCurrencyCode := CRMTransactionCurrency.ISOCurrencyCode;
                Modify();
            end;
    end;

    [Scope('OnPrem')]
    procedure LoadConnectionStringElementsFromCRMConnectionSetup();
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        Exists: Boolean;
    begin
        if Get() then
            if "Is Enabled" then
                exit;

        if "Server Address" <> '' then
            exit;

        if "User Name" <> '' then
            exit;

        if not IsNullGuid("User Password Key") then
            exit;

        EnsureCRMConnectionSetupIsDisabled();

        if CRMConnectionSetup.Get() then
            if not CRMConnectionSetup."Is Enabled" then begin
                Session.LogMessage('0000D3Q', TransferringConnectionValuesFromCRMConnectionsetupTxt, Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Exists := Get();
                "Server Address" := CRMConnectionSetup."Server Address";
                "User Name" := CRMConnectionSetup."User Name";
                "User Password Key" := CRMConnectionSetup."User Password Key";
                "Authentication Type" := CRMConnectionSetup."Authentication Type";
                if Exists then
                    Modify()
                else
                    Insert();
                exit;
            end;

    end;

    procedure EnsureCRMConnectionSetupIsDisabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ErrorInfo: ErrorInfo;
    begin
        OnEnsureConnectionSetupIsDisabled();

        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup.IsEnabled() then
                if CRMConnectionSetup."Server Address" <> TestServerAddressTok then begin
                    Session.LogMessage('0000D3R', CRMConnEnabledTelemetryErr, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    ErrorInfo.Message := CRMConnEnabledErr;
                    ErrorInfo.AddAction(LearnMoreLbl, Codeunit::"CDS Integration Impl.", 'LearnMoreDisablingCRMConnection', LearnMoreDescriptionLbl);
                    ErrorInfo.AddNavigationAction(ShowCRMConnectionSetupLbl, ShowCRMConnectionSetupDescLbl);
                    ErrorInfo.PageNo(Page::"CRM Connection Setup");
                    Error(ErrorInfo);
                end;
    end;

    local procedure UpdateCDSJobQueueEntriesStatus()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        NewStatus: Option;
    begin
        if "Is Enabled" then
            NewStatus := JobQueueEntry.Status::Ready
        else
            NewStatus := JobQueueEntry.Status::"On Hold";
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                if JobQueueEntry.FindSet() then
                    repeat
                        JobQueueEntry.SetStatus(NewStatus);
                    until JobQueueEntry.Next() = 0;
            until IntegrationTableMapping.Next() = 0;
    end;

    internal procedure GetProxyVersion(): Integer
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if "Proxy Version" >= 100 then
            exit("Proxy Version");

        if not EnvironmentInformation.IsSaaS() then
            exit("Proxy Version");

        Session.LogMessage('0000K7Q', DefaultingToDataverseServiceClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        exit(100);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnsureConnectionSetupIsDisabled()
    begin
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        TempUserPassword: SecretText;
        TempClientSecret: SecretText;
        TempAccessToken: SecretText;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CDSConnDisabledTxt: Label 'Dataverse connection has been disabled.', Locked = true;
        CDSConnEnabledTxt: Label 'Dataverse connection has been enabled.', Locked = true;
        BusinessEventsDisabledTxt: Label 'Business events have been disabled.', Locked = true;
        BusinessEventsEnabledTxt: Label 'Business events have been enabled.', Locked = true;
        CRMConnEnabledErr: Label 'To set up the connection with Dataverse, you must first disable the existing connection with Dynamics 365 Sales.';
        CRMConnEnabledTelemetryErr: Label 'User is trying to set up the connection with Dataverse, while the existing connection with Dynamics 365 Sales is enabled.', Locked = true;
        CannotDisableCDSErr: Label 'To disable the connection with Dataverse, you must first disable the existing connection with Dynamics 365 Sales.';
        TransferringConnectionValuesFromCRMConnectionsetupTxt: Label 'Transferring connection string values from Dynamics 365 sales connection setup to Dataverse connection setup', Locked = true;
        TestServerAddressTok: Label '@@test@@', Locked = true;
        DefaultingToDataverseServiceClientTxt: Label 'Defaulting to DataverseServiceClient', Locked = true;
        LearnMoreLbl: Label 'Learn more';
        LearnMoreDescriptionLbl: Label 'Read more about disabling connection.';
        ShowCRMConnectionSetupLbl: Label 'Sales Integration Setup';
        ShowCRMConnectionSetupDescLbl: Label 'Shows Dynamics 365 Sales Integration Setup page where you can disable the connection.';
}
