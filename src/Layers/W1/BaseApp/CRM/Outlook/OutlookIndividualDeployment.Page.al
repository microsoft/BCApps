// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Environment;
using System.Integration;
using System.Privacy;
using System.Security.AccessControl;
using System.Utilities;

page 1832 "Outlook Individual Deployment"
{
    Caption = 'Get the Outlook Add-in';
    PageType = NavigatePage;
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'Outlook, Office, O365, AddIn, M365, Microsoft 365, Addon, Business Inbox, Install Outlook, Set up Outlook';

    layout
    {
        area(content)
        {
            // Top Banners
            group(TopBannerStandardGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and IntroStepVisible;
                field(MediaResourcesOutlook; MediaResourcesOutlook."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Step0)
            {
                Caption = '';
                Visible = PrivacyNoticeStepVisible;

                group(PrivacyNoticeGroup)
                {
                    Caption = 'Your privacy is important to us';

                    group(PrivacyNoticeInner)
                    {
                        ShowCaption = false;
                        label(PrivacyNoticeLabel)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'This feature utilizes Microsoft Exchange. By continuing you are affirming that you understand that the data handling and compliance standards of Microsoft Exchange may not be the same as those provided by Microsoft Dynamics 365 Business Central. Please consult the documentation for Exchange to learn more.';
                        }
                        field(PrivacyNoticeStatement; PrivacyStatementTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=831305');
                            end;
                        }
                    }
                }
            }

            // Introduction Step
            group(Step1)
            {
                Caption = '';
                Visible = IntroStepVisible;
                group("Para1.1")
                {
                    Caption = '';
                    InstructionalText = 'Set up Outlook with Business Central to make faster decisions and respond to inquiries from customers, vendors, or prospects. Look up Business Central contacts, create and attach documents, and more without leaving Outlook.';
                }
                group("Para1.2")
                {
                    Caption = '';
                    field(WatchVideo; WatchVideoLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '';
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(VideoFwdLinkTxt);
                        end;
                    }
                }
            }

            // Manual Deployment Instructions Step
            group(Step2)
            {
                Caption = '';
                Visible = ManualDeploymentStepVisible;
                group("Para2.1")
                {
                    Caption = 'Configure Outlook';
                    group("Para2.1SubGroup")
                    {
                        Caption = '';
                        field(DownloadAddins; DownloadAddinsLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                DownloadManifests();
                            end;
                        }
                        group("Para2.1.2.1")
                        {
                            Caption = '';
                            field(OpenOutlook; OpenOutlookLinkLbl)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Hyperlink(OutlookSideloadLinkTxt);
                                end;
                            }
                        }
                        group("Para2.1.2.2")
                        {
                            Caption = '';
                            InstructionalText = '3. Choose the ‘My Add-ins’ tab and ‘add a custom add-in’ from file.';
                        }
                        group("Para2.1.2.3")
                        {
                            Caption = '';
                            InstructionalText = '4. Select and install all downloaded XML files. You may need to repeat this step for each XML file within the ZIP file.';
                        }
                        group("Para2.1.2.4")
                        {
                            Caption = '';
                            InstructionalText = '5. Choose Finish when done.';
                        }
                        group("Para2.1.2.5")
                        {
                            Caption = '';
                            field(LearnMore; LearnMoreLbl)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;
                                Editable = false;

                                trigger OnDrillDown()
                                begin
                                    Hyperlink(LearnMoreFwdLinkTxt);
                                end;
                            }
                        }
                    }
                }
            }

            // Send Sample Email Step
            group(Step3)
            {
                Caption = '';
                Visible = SampleEmailStepVisible;
                group("Para3.1")
                {
                    Caption = 'Receive a sample email message to evaluate the add-in';
                    group("Para3.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'We can send you a sample email message from a contact in this evaluation company so that you can try out the Outlook add-in experience.';
                    }
                    field(SetupSampleEmails; SetupSampleEmails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Send sample email message';
                        ToolTip = 'Specifies whether to send a sample email to your Outlook inbox so you can experience how the add-in work.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Visible = NextActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(ActionDownload)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Add-in';
                Visible = DownloadActionVisible;
                Image = MoveDown;
                InFooterBar = true;
                ToolTip = 'Download the manifests for the add-in and continue.';

                trigger OnAction();
                begin
                    DownloadManifests();
                end;
            }
            action(ActionInstall)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Install to my Outlook';
                Visible = InstallActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PerformLastStep();
                end;
            }
            action(ActionDone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Visible = FinishActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PerformLastStep();
                end;
            }
        }
    }

    trigger OnInit()
    var
        User: Record User;
    begin
        LoadTopBanners();

        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            Email := User."Authentication Email";
    end;

    trigger OnOpenPage()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        if not (PrivacyNotice.GetPrivacyNoticeApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed) then
            ShowPrivacyNoticeStep()
        else begin
            Step := Step::Intro;
            ShowIntroStep();
        end;
    end;

    local procedure NextStep()
    begin
        Step := Step + 1;
        case Step of
            Step::PrivacyNotice:
                ShowPrivacyNoticeStep();
            Step::Intro:
                ShowIntroStep();
            Step::SampleEmail:
                ShowSampleEmailStep();
            Step::ManualDeployment:
                ShowManualDeploymentStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowPrivacyNoticeStep()
    begin
        ResetWizardControls();
        PrivacyNoticeStepVisible := true;
        NextActionVisible := true;
    end;

    local procedure ShowIntroStep()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        ResetWizardControls();
        IntroStepVisible := true;
        NextActionVisible := true;

        // User has agreed to the Privacy Notice
        PrivacyNotice.SetApprovalState(PrivacyNoticeRegistrations.GetExchangePrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);

        if not CredentialsInitialized then begin
            CredentialsRequired := (Email = '') or ExchangeAddinSetup.CredentialsRequired(CopyStr(Email, 1, 80));
            SampleEmailsAvailable := ExchangeAddinSetup.SampleEmailsAvailable();
            SetupSampleEmails := not CredentialsRequired and SampleEmailsAvailable;
            CredentialsInitialized := true;
        end;

        if not CredentialsRequired and (not ExchangeAddinSetup.SampleEmailsAvailable()) then begin
            NextActionVisible := false;
            InstallActionVisible := true;
        end;
    end;

    local procedure ShowSampleEmailStep()
    begin
        ResetWizardControls();
        if not CredentialsRequired and ExchangeAddinSetup.SampleEmailsAvailable() then begin
            SampleEmailStepVisible := true;
            FinishActionVisible := true;
            exit;
        end;
        // skip this step if manual deployment or sample emails not available
        NextStep();
    end;

    local procedure ShowManualDeploymentStep()
    begin
        ResetWizardControls();
        ManualDeploymentStepVisible := true;
        DownloadActionVisible := true;
        FinishActionVisible := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        NextActionVisible := false;
        FinishActionVisible := false;
        DownloadActionVisible := false;
        InstallActionVisible := false;

        // Tabs
        IntroStepVisible := false;
        PrivacyNoticeStepVisible := false;
        SampleEmailStepVisible := false;
        ManualDeploymentStepVisible := false;
    end;

    local procedure DeployToExchange()
    var
        OfficeAddin: Record "Office Add-in";
        ProgressWindow: Dialog;
    begin
        if SkipDeployment then
            exit;

        ProgressWindow.Open(ProgressTemplateMsg);
        ProgressWindow.Update(1, ConnectingMsg);
        ProgressWindow.Update(2, 3000);
        ProgressWindow.Update(1, DeployAccountMsg);
        ProgressWindow.Update(2, 6000);
        if ExchangeAddinSetup.TryDeployAddins(OfficeAddin) then begin
            if SetupSampleEmails then begin
                ProgressWindow.Update(1, DeploySampleMailMsg);
                ProgressWindow.Update(2, 9000);
                ExchangeAddinSetup.DeploySampleEmails(Email);
                Session.LogMessage('0000IA1', SampleEmailSentTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
            end;
            Session.LogMessage('0000IA2', SetupCompletedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
            ProgressWindow.Update(1, DeployingCompletedMsg);
            ProgressWindow.Update(2, 10000);
        end else begin
            Session.LogMessage('0000IA3', StrSubstNo(SetupFailedTelemetryTxt, GetLastErrorText(true)), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
            ProgressWindow.Update(1, StrSubstNo(DeplyingFailedMsg, GetLastErrorText(false)));
            ProgressWindow.Update(2, 10000);
        end;
        ProgressWindow.Close();
    end;

    local procedure PerformLastStep()
    begin
        if not CredentialsRequired then
            DeployToExchange();
        CurrPage.Close();
    end;

    local procedure DownloadManifests()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestMgt: Codeunit "Add-in Manifest Management";
    begin
        if OfficeAddin.GetAddins() then
            AddinManifestMgt.DownloadMultipleManifestsToClient(OfficeAddin);
    end;

    internal procedure SkipDeploymentStage(Skip: Boolean)
    begin
        SkipDeployment := Skip;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryOutlook.Get('OutlookAddinIllustration.png', Format(ClientTypeManagement.GetCurrentClientType())) then
            if MediaResourcesOutlook.Get(MediaRepositoryOutlook."Media Resources Ref") then
                TopBannerVisible := MediaResourcesOutlook."Media Reference".HasValue;
    end;

    var
        MediaRepositoryOutlook: Record "Media Repository";
        MediaResourcesOutlook: Record "Media Resources";
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        OfficeMgt: Codeunit "Office Management";
        Email: Text[250];
        Step: Option PrivacyNotice,Intro,SampleEmail,ManualDeployment;
        NextActionVisible: Boolean;
        FinishActionVisible: Boolean;
        DownloadActionVisible: Boolean;
        InstallActionVisible: Boolean;
        TopBannerVisible: Boolean;
        PrivacyNoticeStepVisible: Boolean;
        IntroStepVisible: Boolean;
        ManualDeploymentStepVisible: Boolean;
        SampleEmailStepVisible: Boolean;
        SampleEmailsAvailable: Boolean;
        SkipDeployment: Boolean;
        SetupSampleEmails: Boolean;
        CredentialsRequired: Boolean;
        CredentialsInitialized: Boolean;
        ConnectingMsg: Label 'Connecting to Exchange.';
        DeployAccountMsg: Label 'Deploying add-in for your account.';
        DeploySampleMailMsg: Label 'Deploying sample email to your mailbox.';
        DeployingCompletedMsg: Label 'Deploying completed.';
        DeplyingFailedMsg: Label 'Deploying failed. Error: %1', Comment = '%1 last error text';
        ProgressTemplateMsg: Label '#1##########\@2@@@@@@@@@@', Locked = true;
        VideoFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2165118', Locked = true;
        LearnMoreFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2102702', Locked = true;
        OutlookSideloadLinkTxt: Label 'https://aka.ms/olksideload', Locked = true;
        LearnMoreLbl: Label 'Learn more about installing Outlook add-in';
        WatchVideoLbl: Label 'Watch the video';
        DownloadAddinsLbl: Label '1. Download the add-in files to your device.';
        OpenOutlookLinkLbl: Label '2. Go to aka.ms/olksideload.';
        PrivacyStatementTxt: Label 'Privacy and cookies';
        SetupCompletedTelemetryTxt: Label 'Outlook add-in deployed.', Locked = true;
        SetupFailedTelemetryTxt: Label 'Outlook add-in deployment failed. Last Error: %1', Locked = true;
        SampleEmailSentTelemetryTxt: Label 'Sample email deployed.', Locked = true;
}

