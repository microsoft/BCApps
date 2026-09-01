namespace Microsoft.Integration.MDM;

/// <summary>
/// Guided setup for reading master data from another Business Central ENVIRONMENT (same tenant). Mirrors the
/// Intercompany cross-environment partner wizard: consent, then the source environment/company and the
/// Microsoft Entra client-credentials application, then an optional connection test. The client secret is
/// write-only and stored in module-scoped Isolated Storage; it is never read back to the page.
/// </summary>
page 7232 "MDM Connection Details"
{
    Caption = 'Cross-Environment Connection Setup';
    PageType = NavigatePage;
    ApplicationArea = Suite;
    UsageCategory = None;
    Permissions = tabledata "Master Data Management Setup" = imd;

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
                    InstructionalText = 'This guide helps you connect to a company in a different Business Central environment so you can synchronize master data from it. Before you continue, make sure the source environment has this extension installed and exposes its data, and that you have a Microsoft Entra application with a read-only permission set on the source.';
                }
                group(TermsAndConditions)
                {
                    Caption = 'Review the terms and conditions';
                    InstructionalText = 'By enabling this, you consent that this environment will read data from the source environment that you configure. Your privacy is important to us. To learn more, follow the link below.';

                    field(Consent; ConsentState)
                    {
                        ApplicationArea = All;
                        Caption = 'I accept';
                        ToolTip = 'Accept the terms and conditions.';

                        trigger OnValidate()
                        begin
                            // Ticking "I accept" records the durable platform privacy-notice approval.
                            if ConsentState then
                                ConsentState := MDMPrivacyNotice.ConfirmApproval();
                            SetControls();
                        end;
                    }
                    field(LearnMore; LearnMoreTok)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'View information about privacy.';

                        trigger OnDrillDown()
                        begin
                            Hyperlink(PrivacyLinkTxt);
                        end;
                    }
                }
            }
            group(ConnectionTab)
            {
                ShowCaption = false;
                Visible = Step = Step::Connection;
                group(SourceConnectionDetails)
                {
                    Caption = 'Source environment connection details';
                    InstructionalText = 'Provide the environment and company you want to read master data from.';

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
                    field(SourceEnvironmentUrl; SourceEnvironmentUrl)
                    {
                        Caption = 'Source Environment URL';
                        ApplicationArea = Suite;
                        ExtendedDatatype = URL;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the base URL of the source environment''s web services, up to but not including /ODataV4.';

                        trigger OnValidate()
                        begin
                            SetControls();
                        end;
                    }
                    field(SourceCompanyName; SourceCompanyName)
                    {
                        Caption = 'Source Company Name';
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
                    InstructionalText = 'Provide the Microsoft Entra application that this environment uses to authenticate to the source environment. Register it as a single-tenant application, because synchronization only connects to environments in the same Microsoft Entra tenant.';

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
                    InstructionalText = 'You''re all set. Choose Finish to save your connection settings.';
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
                Caption = 'Test Connection';
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
                begin
                    SaveConfiguration();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadConfiguration();
        Step := Step::Welcome;
        SetControls();
    end;

    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
        Step: Option Welcome,Connection,TestConnection,Finish;
        NextEnabled, BackEnabled, FinishEnabled, TestConnectionEnabled : Boolean;
        ConsentState, SecretAlreadyStored : Boolean;
        SourceEnvironmentName: Text[100];
        SourceEnvironmentUrl: Text[250];
        SourceCompanyName: Text[100];
        OAuth2ClientId: Text[100];
        [NonDebuggable]
        OAuth2ClientSecret: Text;
        LearnMoreTok: Label 'Privacy and Cookies';
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839', Locked = true;
        ConnectionOkMsg: Label 'Successfully connected to the source environment (contract version %1).', Comment = '%1 = wire contract version';
        ConnectionFailedErr: Label 'Could not connect to the source environment. Check the URL, company, and credentials, then try again.';

    local procedure LoadConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        if not MasterDataManagementSetup.Get() then
            exit;
        SourceEnvironmentName := MasterDataManagementSetup."Source Environment Name";
        SourceEnvironmentUrl := MasterDataManagementSetup."Source Environment URL";
        SourceCompanyName := MasterDataManagementSetup."Source Company Name";
        OAuth2ClientId := MasterDataManagementSetup."Source OAuth Client Id";
        SecretAlreadyStored := not IsNullGuid(MasterDataManagementSetup."Source Client Secret Key");
    end;

    [NonDebuggable]
    local procedure SaveConfiguration()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        if not MasterDataManagementSetup.Get() then begin
            MasterDataManagementSetup.Init();
            MasterDataManagementSetup.Insert();
        end;
        MasterDataManagementSetup.Validate("Source Environment Name", SourceEnvironmentName);
        MasterDataManagementSetup."Source Environment URL" := SourceEnvironmentUrl;
        MasterDataManagementSetup."Source Company Name" := SourceCompanyName;
        MasterDataManagementSetup."Source OAuth Client Id" := OAuth2ClientId;
        if OAuth2ClientSecret <> '' then begin
            MasterDataManagementSetup.SetSourceClientSecret(OAuth2ClientSecret);
            // Minimize the plain-text window: the secret is now encrypted at rest, so drop the wizard copy.
            Clear(OAuth2ClientSecret);
            SecretAlreadyStored := true;
        end;
        MasterDataManagementSetup.Modify(true);
    end;

    [NonDebuggable]
    local procedure TestConnectionToSource()
    var
        SourceConnection: Codeunit "MDM Source Connection";
        Transport: Interface "IMDM Source Transport";
        Capabilities: JsonObject;
        VersionToken: JsonToken;
        VersionText: Text;
    begin
        // Persist first so the transport reads the details entered in the wizard.
        SaveConfiguration();
        Commit();
        Transport := SourceConnection.GetTransport();
        if not Capabilities.ReadFrom(Transport.GetCapabilities()) then
            Error(ConnectionFailedErr);
        if Capabilities.Get('version', VersionToken) then
            VersionText := Format(VersionToken.AsValue().AsInteger());
        Message(ConnectionOkMsg, VersionText);
    end;

    local procedure NextStep()
    begin
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
    end;

    local procedure StepIsComplete(): Boolean
    begin
        case Step of
            Step::Welcome:
                exit(ConsentState);
            Step::Connection:
                exit((SourceEnvironmentName <> '') and (SourceEnvironmentUrl <> '') and (SourceCompanyName <> '') and
                     (OAuth2ClientId <> '') and ((OAuth2ClientSecret <> '') or SecretAlreadyStored));
            else
                exit(true);
        end;
    end;
}
