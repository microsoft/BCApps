namespace Microsoft.Integration.MDM;

using Microsoft.Foundation.Company;
using Microsoft.Integration.SyncEngine;
using Microsoft.Utilities;
using System.Environment;
using System.Telemetry;
using System.Threading;

table 7230 "Master Data Management Setup"
{
    Caption = 'Master Data Management Setup';
    Permissions = tabledata "Master Data Mgt. Coupling" = rd,
                  tabledata "Master Data Mgt. Subscriber" = rid,
                  tabledata "Job Queue Entry" = rm;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(60; "Is Enabled"; Boolean)
        {
            Caption = 'Synchronization Enabled';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
            begin
                if "Is Enabled" then
                    if IsCrossEnvironment() then begin
                        if not IsCrossEnvConnectionConfigured() then
                            Error(BuildConfigureConnectionError());
                    end else
                        if "Company Name" = '' then
                            Error(MustPickSourceCompanyErr);
                MasterDataMgtSetupDefault.UpdateChangeDetectorJob(Rec);
            end;
        }
        field(151; "Company Name"; Text[30])
        {
            Caption = 'Source Company';
            TableRelation = Company;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnLookup()
            var
                Company: Record Company;
            begin
                if not LookupCompanies(Company) then
                    exit;

                Rec.Validate("Company Name", Company.Name);
            end;

            trigger OnValidate()
            var
                MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
                MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
                MasterDataManagement: Codeunit "Master Data Management";
                CurrentCompanyName: Text[30];
            begin
                if Rec."Is Enabled" then
                    if Rec."Company Name" <> xRec."Company Name" then
                        Error('');

                if Rec."Company Name" = CompanyName() then
                    Error(MustNotPickCurrentCompanyErr);

                if (xRec."Company Name" <> '') and (xRec."Company Name" <> Rec."Company Name") then
                    if not MasterDataMgtCoupling.IsEmpty() then
                        if not Confirm(CouplingsWillBeDeletedQst, false, xRec."Company Name") then
                            Error('');

                CurrentCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataMgtSubscriber."Company Name"));
                MasterDataManagement.RemoveSubsidiarySubscriptionFromMasterCompany(xRec."Company Name", CurrentCompanyName);
                MasterDataManagement.AddSubsidiarySubscriptionToMasterCompany(Rec."Company Name", CurrentCompanyName);
                MasterDataMgtCoupling.DeleteAll();
            end;
        }
        field(152; "Delay Job Scheduling"; Boolean)
        {
            Caption = 'Delay Synchronization Job Scheduling';
            DataClassification = SystemMetadata;
        }
        field(155; "Source Environment Name"; Text[100])
        {
            Caption = 'Source Environment';
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
            begin
                // Re-pointing an enabled setup would leave stale couplings/cursors against the old source; force a disable/rebuild.
                if "Is Enabled" and ("Source Environment Name" <> xRec."Source Environment Name") then
                    Error(CannotChangeSourceWhileEnabledErr);
                MasterDataMgtSetupDefault.UpdateChangeDetectorJob(Rec);
            end;
        }
        field(156; "Source Environment URL"; Text[250])
        {
            Caption = 'Source Environment URL';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(157; "Source Company Name"; Text[100])
        {
            Caption = 'Source Company';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(158; "Source OAuth Client Id"; Text[100])
        {
            Caption = 'Source Client ID';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(159; "Source Client Secret Key"; Guid)
        {
            Caption = 'Source Client Secret Key';
            ExtendedDatatype = Masked;
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

        if "Is Enabled" then
            EnableConnection()
        else
            DisableConnection();
    end;

    trigger OnModify()
    var
        IsEnabledChanged: Boolean;
    begin
        if IsTemporary() then
            exit;

        if "Is Enabled" then
            EnableConnection()
        else
            DisableConnection();

        GetConfigurationUpdates(IsEnabledChanged);
    end;

    trigger OnDelete()
    begin
        if IsTemporary() then
            exit;

        DisableConnection();
    end;

    procedure LookupCompanies(var Company: Record Company): Boolean
    var
        Companies: Page Companies;
        Result: Boolean;
    begin
        Company.SetFilter(Name, '<>%1', CompanyName());
        Companies.SetTableView(Company);
        Companies.SetRecord(Company);
        Companies.LookupMode := true;
        Result := Companies.RunModal() = ACTION::LookupOK;
        if Result then
            Companies.GetRecord(Company)
        else
            Clear(Company);

        exit(Result);
    end;

    internal procedure IsCrossEnvConnectionConfigured(): Boolean
    begin
        exit(("Source Environment URL" <> '') and ("Source Company Name" <> '') and ("Source OAuth Client Id" <> '') and (not IsNullGuid("Source Client Secret Key")));
    end;

    internal procedure IsCrossEnvironment(): Boolean
    begin
        exit("Source Environment Name" <> '');
    end;

    // Reverting to same-environment: drop the source connection details and the stored secret.
    internal procedure ClearCrossEnvConnection()
    begin
        "Source Environment URL" := '';
        "Source Company Name" := '';
        "Source OAuth Client Id" := '';
        if not IsNullGuid("Source Client Secret Key") then
            if not IsolatedStorage.Delete("Source Client Secret Key", DataScope::Company) then;
        Clear("Source Client Secret Key");
    end;

    [NonDebuggable]
    internal procedure SetSourceClientSecret(ClientSecret: SecretText)
    begin
        "Source Client Secret Key" := SetSecret("Source Client Secret Key", ClientSecret);
    end;

    internal procedure GetSourceClientSecret(): SecretText
    begin
        exit(GetSecret("Source Client Secret Key"));
    end;

    // Mirrors the Intercompany connection pattern: secrets live in module-scoped Isolated Storage, keyed by a Guid.
    [NonDebuggable]
    local procedure SetSecret(SecretKey: Guid; SecretValue: SecretText): Guid
    var
        EnvironmentInformation: Codeunit "Environment Information";
        NewSecretKey: Guid;
    begin
        if not IsNullGuid(SecretKey) then
            if not IsolatedStorage.Delete(SecretKey, DataScope::Company) then;

        NewSecretKey := CreateGuid();
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(NewSecretKey, SecretValue, DataScope::Company)
        else begin
            // On SaaS (the only runtime for cross-env) encryption is always available, so refuse to store the
            // secret unencrypted there; off-SaaS dev/test/on-prem may lack encryption, so fall back as Intercompany does.
            if EnvironmentInformation.IsSaaSInfrastructure() then
                Error(EncryptionRequiredErr);
            IsolatedStorage.Set(NewSecretKey, SecretValue, DataScope::Company);
        end;

        exit(NewSecretKey);
    end;

    local procedure GetSecret(SecretKey: Guid) SecretValue: SecretText
    begin
        if IsNullGuid(SecretKey) then
            exit;
        if not IsolatedStorage.Get(SecretKey, DataScope::Company, SecretValue) then;
    end;

    local procedure EnableConnection()
    var
        MasterDataMgtSubscriber: Record "Master Data Mgt. Subscriber";
        IntegrationTableMapping: Record "Integration Table Mapping";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        MasterDataManagement: Codeunit "Master Data Management";
        CurrentCompanyName: Text[30];
        ResetConfig: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000JIL', MasterDataManagement.GetFeatureName(), Enum::"Feature Uptake Status"::"Set up");
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        if IntegrationTableMapping.IsEmpty() then
            ResetConfig := true
        else
            ResetConfig := Confirm(ResetConfigQst);
        if ResetConfig then
            MasterDataMgtSetupDefault.ResetConfiguration(Rec);

        if IsCrossEnvironment() then begin
            // Cross-environment: the source is a different environment; never write to its subscriber table.
            // Drop any stale local-company subscription left from a prior local-source setup.
            if "Company Name" <> '' then begin
                CurrentCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataMgtSubscriber."Company Name"));
                MasterDataManagement.RemoveSubsidiarySubscriptionFromMasterCompany("Company Name", CurrentCompanyName);
            end;
            Message(SynchronizationEnabledMsg, "Source Company Name");
            LogCrossEnvironmentEnabled(MasterDataManagement.GetTelemetryCategory());
            exit;
        end;

        CurrentCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataMgtSubscriber."Company Name"));
        MasterDataManagement.AddSubsidiarySubscriptionToMasterCompany(Rec."Company Name", CurrentCompanyName);
        Message(SynchronizationEnabledMsg, Rec."Company Name");
        Session.LogMessage('0000JIM', Rec."Company Name", Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
        Session.LogMessage('0000JIN', CurrentCompanyName, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
    end;

    // Env name is organization-identifiable: keep it out of the free-text message and in a structured dimension.
    local procedure LogCrossEnvironmentEnabled(TelemetryCategory: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory);
        Dimensions.Add('sourceEnvironment', "Source Environment Name");
        Session.LogMessage('0000VAX', CrossEnvEnabledTelemetryTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure GetConfigurationUpdates(var IsEnabledChanged: Boolean)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        IsEnabledChanged := "Is Enabled" <> xRec."Is Enabled";
        if not IsEnabledChanged then
            if MasterDataManagementSetup.Get() then
                IsEnabledChanged := "Is Enabled" <> MasterDataManagementSetup."Is Enabled";
    end;

    local procedure DisableConnection()
    var
        MasterDataMgtCoupling: Record "Master Data Mgt. Coupling";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        MasterDataManagement: Codeunit "Master Data Management";
        CurrentCompanyName: Text[30];
    begin
        CurrentCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(Rec."Company Name"));

        // Cross-environment: the source is a different environment; never touch its subscriber table.
        if not IsCrossEnvironment() then
            MasterDataManagement.RemoveSubsidiarySubscriptionFromMasterCompany(Rec."Company Name", CurrentCompanyName);
        UpdateDataSynchJobQueueEntriesStatus();

        if not MasterDataMgtCoupling.IsEmpty() then
            if Confirm(KeepTheCouplingsQst, false, Rec."Company Name") then
                exit
            else begin
                IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
                if IntegrationTableMapping.FindSet() then
                    repeat
                        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
                        IntegrationFieldMapping.DeleteAll();
                    until IntegrationTableMapping.Next() = 0;
                IntegrationTableMapping.DeleteAll();
                MasterDataMgtCoupling.DeleteAll();
            end;
    end;

    internal procedure SynchronizeNow(DoFullSynch: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        MasterDataManagementSetupDefaults: Codeunit "Master Data Mgt. Setup Default";
    begin
        MasterDataManagementSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);

        TempNameValueBuffer.Ascending(true);
        if not TempNameValueBuffer.FindSet() then
            exit;

        repeat
            if IntegrationTableMapping.Get(TempNameValueBuffer.Value) then
                IntegrationTableMapping.SynchronizeNow(DoFullSynch);
        until TempNameValueBuffer.Next() = 0;
    end;

    local procedure UpdateDataSynchJobQueueEntriesStatus()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        NewStatus: Option;
    begin
        if "Is Enabled" then
            NewStatus := JobQueueEntry.Status::Ready
        else
            NewStatus := JobQueueEntry.Status::"On Hold";
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"Integration Master Data Synch.");
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

    internal procedure GetDataSource(): Interface "IMDM Data Source"
    begin
        if "Source Environment Name" <> '' then
            exit(Enum::"MDM Data Source Type"::CrossEnvironment);
        exit(Enum::"MDM Data Source Type"::LocalCompany);
    end;

    local procedure BuildConfigureConnectionError(): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MustConfigureConnectionErr;
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        ErrInfo.RecordId := Rec.RecordId();
        ErrInfo.PageNo := Page::"Master Data Management Setup";
        ErrInfo.AddNavigationAction(OpenSetupNavigationTxt);
        exit(ErrInfo);
    end;

    var
        SynchronizationEnabledMsg: label 'The synchronization of data from company %1 is enabled. \\To review the tables and fields that will be synchronized, choose action Synchronization Tables. \\To perform the initial synchronization of data from %1, choose Start Initial Synchronization. \\After the initial synchronization is done, job queue entries will continue to synchronize modifications.', Comment = '%1 - a company name';
        CouplingsWillBeDeletedQst: label 'All the couplings with records from previous source company %1 will be deleted. Do you want to continue?', Comment = '%1 - a company name';
        KeepTheCouplingsQst: label 'Data synchronization with company %1 is disabled. \\We recommend to keep the table setup and coupling information, especially if you intend to reenable the synchronization with the same company. \\Do you want to keep the table setup and coupling information?', Comment = '%1 - a company name';
        MustNotPickCurrentCompanyErr: label 'You are currently signed into this company. \\Choose a different company to synchronize data with.';
        MustPickSourceCompanyErr: label 'You must choose a source company to synchronize data from.';
        MustConfigureConnectionErr: label 'Enter the cross-environment connection details before you enable synchronization.';
        OpenSetupNavigationTxt: label 'Open Master Data Management Setup';
        CannotChangeSourceWhileEnabledErr: label 'You cannot change the source environment while synchronization is enabled. Disable synchronization first, then change the source.';
        EncryptionRequiredErr: label 'Enable data encryption before saving the source connection secret. Cross-environment credentials are never stored unencrypted.';
        CrossEnvEnabledTelemetryTxt: label 'Cross-environment master data synchronization was enabled.', Locked = true;
        ResetConfigQst: label 'There are existing synchronization table definitions in this company. Do you want to reset them to the default configuration?';
}
