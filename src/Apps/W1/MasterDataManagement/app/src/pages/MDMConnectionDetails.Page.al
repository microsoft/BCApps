namespace Microsoft.Integration.MDM;

using System.Telemetry;
using System.Text;

/// <summary>
/// Guided setup for reading master data from another Business Central ENVIRONMENT (same tenant). Mirrors the
/// Intercompany cross-environment partner wizard: consent, then the source environment/company and the
/// Microsoft Entra client-credentials application, then an optional connection test. The application authenticates
/// with either a client secret or a certificate (.pfx/.p12 with its private key). Credentials are write-only and stored
/// in module-scoped Isolated Storage; they are never read back to the page.
/// </summary>
page 7232 "MDM Connection Details"
{
    Caption = 'Cross-Environment Connection Setup';
    PageType = NavigatePage;
    ApplicationArea = Suite;
    UsageCategory = None;
    Permissions = tabledata "Master Data Management Setup" = rimd;

    layout
    {
        area(Content)
        {
            group(WelcomeTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Welcome;
                group(Introduction)
                {
                    Caption = 'Welcome';
                    InstructionalText = 'This guide helps you connect to a company in a different Business Central environment so you can synchronize master data from it. Before you continue, make sure the source environment has this extension installed and exposes its data, and that you have a Microsoft Entra application with a read-only permission set on the source. When you choose Next, you are asked to review and accept the privacy terms for sharing data between environments.';
                }
            }
            group(ConnectionTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Connection;
                group(SourceConnectionDetails)
                {
                    Caption = 'Source environment connection details';

                    field(SourceEnvironmentName; SourceEnvironmentName)
                    {
                        Caption = 'Source Environment';
                        ApplicationArea = Suite;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the name of the source Business Central environment.';

                        trigger OnValidate()
                        begin
                            SetControls();
                        end;
                    }
                    field(SourceCompanyName; SourceCompanyName)
                    {
                        Caption = 'Source Company';
                        ApplicationArea = Suite;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the name of the company in the source environment that data is read from.';

                        trigger OnValidate()
                        begin
                            SetControls();
                        end;
                    }
                }
                group(OAuth2ConnectionDetails)
                {
                    Caption = 'Authentication details';
                    InstructionalText = 'Provide the Microsoft Entra application that this environment uses to sign in to the source environment with a client secret or a certificate. Register it as a single-tenant application in the same tenant.';

                    field(OAuth2ClientId; OAuth2ClientId)
                    {
                        Caption = 'Client ID';
                        ApplicationArea = Suite;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the application (client) ID of the Microsoft Entra authentication application.';

                        trigger OnValidate()
                        begin
                            SetControls();
                        end;
                    }
                    field(AuthenticationType; AuthenticationType)
                    {
                        Caption = 'Authentication Type';
                        ApplicationArea = Suite;
                        OptionCaption = 'Client Secret,Certificate';
                        ToolTip = 'Specifies whether the Microsoft Entra authentication application authenticates with a client secret or with a certificate.';

                        trigger OnValidate()
                        begin
                            SetControls();
                        end;
                    }
                    // Field visibility is only applied when the page opens; group visibility follows the authentication type.
                    group(ClientSecretDetails)
                    {
                        ShowCaption = false;
                        Visible = AuthenticationType = AuthenticationType::"Client Secret";

                        field(OAuth2ClientSecret; OAuth2ClientSecret)
                        {
                            Caption = 'Client Secret';
                            ApplicationArea = Suite;
                            ExtendedDatatype = Masked;
                            ShowMandatory = not SecretAlreadyStored;
                            ToolTip = 'Specifies the client secret of the Microsoft Entra authentication application. The secret is stored securely and is not shown again after you enter it.';

                            trigger OnValidate()
                            begin
                                SetControls();
                            end;
                        }
                    }
                    group(CertificateDetails)
                    {
                        ShowCaption = false;
                        Visible = AuthenticationType = AuthenticationType::Certificate;

                        field(ClientCertificate; CertificateFileName)
                        {
                            Caption = 'Certificate';
                            ApplicationArea = Suite;
                            Editable = false;
                            ShowMandatory = not CertificateAlreadyStored;
                            ToolTip = 'Specifies the certificate of the Microsoft Entra authentication application. Choose the AssistEdit button to upload the .pfx or .p12 file that includes the private key. The certificate is stored securely and cannot be downloaded again.';

                            trigger OnAssistEdit()
                            begin
                                UploadCertificate();
                                SetControls();
                            end;
                        }
                        field(CertificatePassword; CertificatePassword)
                        {
                            Caption = 'Certificate Password';
                            ApplicationArea = Suite;
                            ExtendedDatatype = Masked;
                            ShowMandatory = CertificatePasswordRequired;
                            ToolTip = 'Specifies the password that protects the certificate file. Leave it blank if the file is not password protected. The password is stored securely and is not shown again after you enter it.';

                            trigger OnValidate()
                            begin
                                VerifyUploadedCertificate(true);
                                SetControls();
                            end;
                        }
                        // Shown only once a certificate is read, so the step needs no scrolling while uploading.
                        group(CertificateInformation)
                        {
                            ShowCaption = false;
                            Visible = CertificateThumbprint <> '';

                            field(CertificateThumbprint; CertificateThumbprint)
                            {
                                Caption = 'Certificate Thumbprint';
                                ApplicationArea = Suite;
                                Editable = false;
                                ToolTip = 'Specifies the thumbprint of the certificate. It must match the thumbprint of a certificate registered for the Microsoft Entra application.';
                            }
                            field(CertificateExpirationDate; CertificateExpirationDate)
                            {
                                Caption = 'Certificate Expiration Date';
                                ApplicationArea = Suite;
                                Editable = false;
                                ToolTip = 'Specifies when the certificate expires. Upload a new certificate before this date to keep synchronization running.';
                            }
                        }
                    }
                }
            }
            group(TestConnectionTab)
            {
                ShowCaption = false;
                Visible = Step = Step::TestConnection;
                group(VerifyConnection)
                {
                    Caption = 'Verify connection';
                    InstructionalText = 'Optionally test that the source environment can be reached with the details you entered. Choose Test Connection, or choose Next to continue.';
                }
            }
            group(FinishTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Finish;
                group(AllDone)
                {
                    Caption = 'All done';
                    InstructionalText = 'You''re all set. Choose Finish to save your connection settings. You can enable data synchronization right away.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = Suite;
                Caption = 'Test connection';
                ToolTip = 'Test that the source environment can be reached with the current URL and credentials.';
                Visible = TestConnectionEnabled;
                Image = InteractionTemplateSetup;
                InFooterBar = true;

                trigger OnAction()
                begin
                    TestConnectionToSource();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Suite;
                Caption = 'Back';
                ToolTip = 'Go to the previous step.';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PreviousStep();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                ToolTip = 'Go to the next step.';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Suite;
                Caption = 'Finish';
                ToolTip = 'Save the connection settings.';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    MasterDataManagement: Codeunit "Master Data Management";
                begin
                    SaveConfiguration();
                    // Catch a mistyped environment or company, or a missing app registration, now - not as failing sync jobs.
                    if not VerifyConnectionOnFinish() then
                        exit;
                    // Completing the wizard saves a full cross-environment connection, which is a genuine setup of the
                    // feature; register Set up here so it is captured even when the user declines to enable right away.
                    FeatureTelemetry.LogUptake('0000VVS', MasterDataManagement.GetFeatureName(), Enum::"Feature Uptake Status"::"Set up");
                    EnableSynchronizationOnFinish();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MasterDataManagement: Codeunit "Master Data Management";
    begin
        // Opening the cross-environment setup wizard is a genuine discovery of the feature, so register Discovered here
        // too (the main setup page may never be opened in a wizard-only cross-environment setup).
        FeatureTelemetry.LogUptake('0000VVT', MasterDataManagement.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        LoadConfiguration();
        Step := Step::Welcome;
        SetControls();
    end;

    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
        Step: Option Welcome,Connection,TestConnection,Finish;
        AuthenticationType: Option "Client Secret",Certificate;
        NextEnabled, BackEnabled, FinishEnabled, TestConnectionEnabled : Boolean;
        SecretAlreadyStored: Boolean;
        CertificateAlreadyStored: Boolean;
        CertificateVerified: Boolean;
        CertificatePasswordRequired: Boolean;
        SourceEnvironmentName: Text[100];
        SourceCompanyName: Text[100];
        OAuth2ClientId: Text[100];
        [NonDebuggable]
        OAuth2ClientSecret: Text;
        [NonDebuggable]
        CertificateBase64: Text;
        [NonDebuggable]
        CertificatePassword: Text;
        CertificateFileName: Text;
        CertificateThumbprint: Text;
        CertificateExpirationDate: DateTime;
        ConnectionOkMsg: Label 'Successfully connected to the source environment (contract version %1).', Comment = '%1 = wire contract version';
        ConnectionFailedErr: Label 'Could not connect to the source environment. Check the source environment, company, and credentials, then try again.';
        ConnectionNotVerifiedQst: Label 'The connection to the source environment could not be verified:\\%1\\Do you want to finish anyway? Choose No to go back and correct the connection details.', Comment = '%1 = the reason the connection failed';
        EnableNowQst: Label 'Your cross-environment connection is saved. Do you want to enable data synchronization now?';
        SelectCertificateTxt: Label 'Select the certificate file';
        CertificateFileFilterTxt: Label 'Certificate Files (*.pfx, *.p12)|*.pfx;*.p12', Locked = true;
        StoredCertificateTxt: Label 'Stored certificate';
        UploadCertificateFirstErr: Label 'Upload the certificate file before you enter its password.';

    local procedure LoadConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        if not MasterDataManagementSetup.Get() then
            exit;
        SourceEnvironmentName := MasterDataManagementSetup."Source Environment Name";
        SourceCompanyName := MasterDataManagementSetup."Source Company Name";
        OAuth2ClientId := MasterDataManagementSetup."Source OAuth Client Id";
        SecretAlreadyStored := not IsNullGuid(MasterDataManagementSetup."Source Client Secret Key");
        CertificateAlreadyStored := MasterDataManagementSetup.UsesSourceClientCertificate();
        if CertificateAlreadyStored then begin
            AuthenticationType := AuthenticationType::Certificate;
            CertificateFileName := StoredCertificateTxt;
            CertificateThumbprint := MasterDataManagementSetup."Source Cert. Thumbprint";
            CertificateExpirationDate := MasterDataManagementSetup."Source Cert. Expiration Date";
        end;
    end;

    [NonDebuggable]
    local procedure SaveConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        HttpSourceTransport: Codeunit "MDM Http Source Transport";
    begin
        if not MasterDataManagementSetup.Get() then begin
            MasterDataManagementSetup.Init();
            MasterDataManagementSetup.Insert();
        end;
        MasterDataManagementSetup.Validate("Source Environment Name", SourceEnvironmentName);
        // Same-tenant, same-ring: derive the source web-service URL from the environment name instead of asking for it.
        MasterDataManagementSetup."Source Environment URL" := CopyStr(HttpSourceTransport.BuildSourceApiBaseUrl(SourceEnvironmentName), 1, MaxStrLen(MasterDataManagementSetup."Source Environment URL"));
        MasterDataManagementSetup."Source Company Name" := SourceCompanyName;
        MasterDataManagementSetup."Source OAuth Client Id" := OAuth2ClientId;
        // Storing one credential type removes the other, so the connection never holds both a secret and a certificate.
        case AuthenticationType of
            AuthenticationType::"Client Secret":
                if OAuth2ClientSecret <> '' then begin
                    MasterDataManagementSetup.SetSourceClientSecret(OAuth2ClientSecret);
                    // Minimize the plain-text window: the secret is now encrypted at rest, so drop the wizard copy.
                    Clear(OAuth2ClientSecret);
                    SecretAlreadyStored := true;
                    // Storing the secret deleted any stored certificate, so the certificate fields no longer describe a credential.
                    ClearCertificateState();
                end;
            AuthenticationType::Certificate:
                if CertificateBase64 <> '' then begin
                    MasterDataManagementSetup.SetSourceClientCertificate(CertificateBase64, CertificatePassword);
                    // The certificate and its password are now in Isolated Storage, so drop the wizard copies.
                    Clear(CertificateBase64);
                    Clear(CertificatePassword);
                    // Readiness now comes from the stored certificate, not from the upload that was just saved.
                    CertificateVerified := false;
                    CertificateAlreadyStored := true;
                    SecretAlreadyStored := false;
                end;
        end;
        MasterDataManagementSetup.Modify(true);
    end;

    [NonDebuggable]
    local procedure ClearCertificateState()
    begin
        Clear(CertificateBase64);
        Clear(CertificatePassword);
        CertificateAlreadyStored := false;
        CertificateVerified := false;
        CertificateFileName := '';
        CertificateThumbprint := '';
        CertificateExpirationDate := 0DT;
    end;

    [NonDebuggable]
    local procedure UploadCertificate()
    var
        Base64Convert: Codeunit "Base64 Convert";
        CertificateInStream: InStream;
        UploadedFileName: Text;
    begin
        if not UploadIntoStream(SelectCertificateTxt, '', CertificateFileFilterTxt, UploadedFileName, CertificateInStream) then
            exit;
        CertificateBase64 := Base64Convert.ToBase64(CertificateInStream);
        CertificateFileName := UploadedFileName;
        VerifyUploadedCertificate(false);
    end;

    // After an upload the file is kept even when it cannot be read yet. Without a password that is the expected state for a
    // password-protected certificate, so no message is shown and the password is marked as required; the certificate stays
    // unverified, so Next stays disabled. Entering the password re-checks the file and raises an error if it still cannot be
    // read. A file that cannot be read with a password already entered is reported right away.
    [NonDebuggable]
    local procedure VerifyUploadedCertificate(FailOnError: Boolean)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        Thumbprint: Text;
        ExpirationDate: DateTime;
    begin
        if CertificateBase64 = '' then begin
            if FailOnError and (CertificatePassword <> '') then
                Error(UploadCertificateFirstErr);
            exit;
        end;

        if FailOnError then
            MasterDataManagementSetup.CheckSourceClientCertificate(CertificateBase64, CertificatePassword, Thumbprint, ExpirationDate)
        else
            if not TryCheckUploadedCertificate(Thumbprint, ExpirationDate) then begin
                CertificateVerified := false;
                CertificateThumbprint := '';
                CertificateExpirationDate := 0DT;
                if CertificatePassword <> '' then
                    Message(GetLastErrorText());
                exit;
            end;

        CertificateVerified := true;
        CertificateThumbprint := Thumbprint;
        CertificateExpirationDate := ExpirationDate;
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryCheckUploadedCertificate(var Thumbprint: Text; var ExpirationDate: DateTime)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.CheckSourceClientCertificate(CertificateBase64, CertificatePassword, Thumbprint, ExpirationDate);
    end;

    // Enabling here starts synchronization straight from Finish so the admin doesn't have to flip the setup toggle afterward.
    local procedure EnableSynchronizationOnFinish()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        if not MasterDataManagementSetup.Get() then
            exit;
        if MasterDataManagementSetup."Is Enabled" then
            exit;
        if not Confirm(EnableNowQst) then
            exit;
        MasterDataManagementSetup.Validate("Is Enabled", true);
        MasterDataManagementSetup.Modify(true);
    end;

    [NonDebuggable]
    local procedure TestConnectionToSource()
    begin
        // Persist first so the transport reads the details entered in the wizard.
        SaveConfiguration();
        Commit();
        Message(ConnectionOkMsg, CheckSourceConnection());
    end;

    // The details are already saved; on failure the user either keeps them or stays in the wizard to correct them.
    // The wizard is only offered online, where the transport can reach a source, so the check always runs.
    local procedure VerifyConnectionOnFinish(): Boolean
    var
        VersionText: Text;
    begin
        Commit(); // the transport reads the saved details
        if TryCheckSourceConnection(VersionText) then
            exit(true);
        exit(Confirm(StrSubstNo(ConnectionNotVerifiedQst, GetLastErrorText()), false));
    end;

    [TryFunction]
    local procedure TryCheckSourceConnection(var VersionText: Text)
    begin
        VersionText := CheckSourceConnection();
    end;

    // Returns the source's contract version; errors (with the transport's specific reason) if it can't be reached.
    local procedure CheckSourceConnection() VersionText: Text
    var
        SourceConnection: Codeunit "MDM Source Connection";
        SourceResponse: Codeunit "MDM Source Response";
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
        Transport: Interface "IMDM Source Transport";
        Capabilities: JsonObject;
        VersionToken: JsonToken;
        VersionValue: Integer;
    begin
        Transport := SourceConnection.GetTransport();
        if not Capabilities.ReadFrom(Transport.GetCapabilities()) then
            Error(ConnectionFailedErr);
        // Reachable, but the source hasn't approved sharing: report it now, with the same message the sync would show.
        if SourceResponse.ConsentRequired(Capabilities) then
            Error(CrossEnvDataSource.SourceConsentError());
        if Capabilities.Get('version', VersionToken) then begin
            if not (VersionToken.IsValue() and Evaluate(VersionValue, VersionToken.AsValue().AsText())) then // malformed version is a broken capabilities contract, not user-actionable
                Error(ConnectionFailedErr);
            VersionText := Format(VersionValue);
        end;
    end;

    local procedure NextStep()
    begin
        // Leaving the Welcome step requires the durable platform privacy-notice approval; show it once if needed.
        if (Step = Step::Welcome) and not (MDMPrivacyNotice.IsApproved() or MDMPrivacyNotice.ConfirmApproval()) then
            exit;
        Step += 1;
        SetControls();
    end;

    local procedure PreviousStep()
    begin
        Step -= 1;
        SetControls();
    end;

    local procedure SetControls()
    begin
        BackEnabled := Step > Step::Welcome;
        TestConnectionEnabled := Step = Step::TestConnection;
        FinishEnabled := Step = Step::Finish;
        NextEnabled := (Step < Step::Finish) and StepIsComplete();
        CertificatePasswordRequired := (CertificateBase64 <> '') and not CertificateVerified;
    end;

    local procedure StepIsComplete(): Boolean
    begin
        case Step of
            Step::Connection:
                exit((SourceEnvironmentName <> '') and (SourceCompanyName <> '') and
                     (OAuth2ClientId <> '') and CredentialIsComplete());
            else
                exit(true);
        end;
    end;

    local procedure CredentialIsComplete(): Boolean
    begin
        case AuthenticationType of
            AuthenticationType::"Client Secret":
                exit((OAuth2ClientSecret <> '') or SecretAlreadyStored);
            AuthenticationType::Certificate:
                begin
                    // A pending upload must be readable; without one, a certificate must already be stored.
                    if CertificateBase64 <> '' then
                        exit(CertificateVerified);
                    exit(CertificateAlreadyStored);
                end;
        end;
    end;
}
