namespace Microsoft.Integration.MDM;

using Microsoft.Foundation.Company;
using Microsoft.Integration.SyncEngine;
using Microsoft.Utilities;
using System.Environment;
using System.Security.Encryption;
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
        field(160; "Source Client Certificate Key"; Guid)
        {
            Caption = 'Source Client Certificate Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(161; "Source Cert. Password Key"; Guid)
        {
            Caption = 'Source Certificate Password Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(162; "Source Cert. Thumbprint"; Text[50])
        {
            Caption = 'Source Certificate Thumbprint';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(163; "Source Cert. Expiration Date"; DateTime)
        {
            Caption = 'Source Certificate Expiration Date';
            Editable = false;
            DataClassification = CustomerContent;
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
        // Without the setup record nothing references the stored credentials, so remove them from Isolated Storage.
        ClearSourceCredentials();
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
        exit(("Source Environment URL" <> '') and ("Source Company Name" <> '') and ("Source OAuth Client Id" <> '') and HasSourceCredential());
    end;

    internal procedure IsCrossEnvironment(): Boolean
    begin
        exit("Source Environment Name" <> '');
    end;

    // The source connection authenticates with either a client secret or a certificate, never both.
    internal procedure UsesSourceClientCertificate(): Boolean
    begin
        exit(not IsNullGuid("Source Client Certificate Key"));
    end;

    local procedure HasSourceCredential(): Boolean
    begin
        exit((not IsNullGuid("Source Client Secret Key")) or UsesSourceClientCertificate());
    end;

    // Reverting to same-environment: drop the source connection details and the stored credentials.
    internal procedure ClearCrossEnvConnection()
    begin
        "Source Environment URL" := '';
        "Source Company Name" := '';
        "Source OAuth Client Id" := '';
        ClearSourceCredentials();
    end;

    // Write-only by design: the secret is read back only by a local procedure of "MDM Http Source Transport", so no
    // internal or public member hands the secret out.
    [NonDebuggable]
    internal procedure SetSourceClientSecret(ClientSecret: SecretText)
    begin
        "Source Client Secret Key" := SetSecret("Source Client Secret Key", ClientSecret);
        ClearSourceClientCertificate();
    end;

    // Write-only by design, like the client secret: the certificate and its password are read back only by local
    // procedures of "MDM Http Source Transport". Only the non-secret thumbprint and expiration date are kept on the record.
    [NonDebuggable]
    internal procedure SetSourceClientCertificate(CertificateBase64: Text; CertificatePassword: SecretText)
    var
        Thumbprint: Text;
        ExpirationDate: DateTime;
    begin
        CheckSourceClientCertificate(CertificateBase64, CertificatePassword, Thumbprint, ExpirationDate);
        "Source Client Certificate Key" := SetCertificate("Source Client Certificate Key", CertificateBase64);
        if CertificatePassword.IsEmpty() then
            DeleteSecret("Source Cert. Password Key")
        else
            "Source Cert. Password Key" := SetSecret("Source Cert. Password Key", CertificatePassword);
        "Source Cert. Thumbprint" := CopyStr(Thumbprint, 1, MaxStrLen("Source Cert. Thumbprint"));
        "Source Cert. Expiration Date" := ExpirationDate;
        DeleteSecret("Source Client Secret Key");
    end;

    // Errors unless the certificate can be read with the password, carries the private key needed to sign the token
    // request, and has not expired.
    [NonDebuggable]
    internal procedure CheckSourceClientCertificate(CertificateBase64: Text; CertificatePassword: SecretText; var Thumbprint: Text; var ExpirationDate: DateTime)
    var
        HasPrivateKey: Boolean;
    begin
        if not TryReadCertificate(CertificateBase64, CertificatePassword, Thumbprint, ExpirationDate, HasPrivateKey) then
            Error(CertificateNotReadableErr);
        if not HasPrivateKey then
            Error(CertificateWithoutPrivateKeyErr);
        if ExpirationDate < CurrentDateTime() then
            Error(CertificateExpiredErr, ExpirationDate);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryReadCertificate(CertificateBase64: Text; CertificatePassword: SecretText; var Thumbprint: Text; var ExpirationDate: DateTime; var HasPrivateKey: Boolean)
    var
        X509Certificate2: Codeunit X509Certificate2;
    begin
        HasPrivateKey := X509Certificate2.HasPrivateKey(CertificateBase64, CertificatePassword);
        X509Certificate2.GetCertificateThumbprint(CertificateBase64, CertificatePassword, Thumbprint);
        X509Certificate2.GetCertificateExpiration(CertificateBase64, CertificatePassword, ExpirationDate);
    end;

    // An environment copy (e.g. production to sandbox) must not carry the source credentials along: in a sandbox a DEV
    // extension can be published under this app's id and read its Isolated Storage. The rest of the connection is
    // kept, so an admin only re-enters the secret or re-uploads the certificate to resume synchronization in the copy.
    internal procedure ClearSourceCredentialsOnEnvironmentCopy()
    var
        MasterDataMgtSetupDefault: Codeunit "Master Data Mgt. Setup Default";
        DisableSynchronization: Boolean;
    begin
        DisableSynchronization := "Is Enabled" and IsCrossEnvironment();
        if not HasSourceCredential() and not DisableSynchronization then
            exit;

        ClearSourceCredentials();

        if DisableSynchronization then begin
            "Is Enabled" := false;
            UpdateDataSynchJobQueueEntriesStatus();
            MasterDataMgtSetupDefault.UpdateChangeDetectorJob(Rec);
        end;
        Modify(false);
    end;

    local procedure ClearSourceCredentials()
    begin
        DeleteSecret("Source Client Secret Key");
        ClearSourceClientCertificate();
    end;

    // Test seam: reports only whether a credential entry exists in Isolated Storage, never its value.
    internal procedure IsSourceCredentialStored(CredentialKey: Guid): Boolean
    begin
        if IsNullGuid(CredentialKey) then
            exit(false);
        exit(IsolatedStorage.Contains(CredentialKey, DataScope::Company));
    end;

    local procedure ClearSourceClientCertificate()
    begin
        DeleteSecret("Source Client Certificate Key");
        DeleteSecret("Source Cert. Password Key");
        "Source Cert. Thumbprint" := '';
        "Source Cert. Expiration Date" := 0DT;
    end;

    local procedure DeleteSecret(var SecretKey: Guid)
    begin
        if IsNullGuid(SecretKey) then
            exit;
        if IsolatedStorage.Contains(SecretKey, DataScope::Company) then
            IsolatedStorage.Delete(SecretKey, DataScope::Company);
        Clear(SecretKey);
    end;

    // Mirrors the Intercompany connection pattern: secrets live in module-scoped Isolated Storage, keyed by a Guid.
    [NonDebuggable]
    local procedure SetSecret(SecretKey: Guid; SecretValue: SecretText): Guid
    var
        EnvironmentInformation: Codeunit "Environment Information";
        NewSecretKey: Guid;
    begin
        DeleteSecret(SecretKey);

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

    // IsolatedStorage.SetEncrypted is limited to 215 characters, far below a Base64-encoded .pfx file, so the
    // certificate is stored with IsolatedStorage.Set, as the platform Certificate Management does. Isolated Storage is
    // module-scoped and encrypted at rest; the certificate password is still stored with SetEncrypted.
    [NonDebuggable]
    local procedure SetCertificate(CertificateKey: Guid; CertificateBase64: SecretText): Guid
    var
        NewCertificateKey: Guid;
    begin
        DeleteSecret(CertificateKey);

        NewCertificateKey := CreateGuid();
        if not IsolatedStorage.Set(NewCertificateKey, CertificateBase64, DataScope::Company) then
            Error(CertificateNotSavedErr);

        exit(NewCertificateKey);
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
        // Company names are tenant data: keep them out of the free-text telemetry message.
        Session.LogMessage('0000JIM', SynchronizationEnabledSourceTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
        Session.LogMessage('0000JIN', SynchronizationEnabledSubscriberTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
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
        CertificateNotReadableErr: label 'The certificate could not be read. Make sure that the file is a .pfx or .p12 certificate and that the password is correct.';
        CertificateWithoutPrivateKeyErr: label 'The certificate does not contain a private key. Upload a .pfx or .p12 file that includes the private key of the certificate registered for the Microsoft Entra application.';
        CertificateExpiredErr: label 'The certificate expired on %1. Upload a valid certificate.', Comment = '%1 = expiration date and time of the certificate';
        CertificateNotSavedErr: label 'The certificate could not be saved.';
        CrossEnvEnabledTelemetryTxt: label 'Cross-environment master data synchronization was enabled.', Locked = true;
        SynchronizationEnabledSourceTelemetryTxt: label 'Master data synchronization was enabled for the source company.', Locked = true;
        SynchronizationEnabledSubscriberTelemetryTxt: label 'Master data synchronization was enabled for the subscriber company.', Locked = true;
        ResetConfigQst: label 'There are existing synchronization table definitions in this company. Do you want to reset them to the default configuration?';
}
