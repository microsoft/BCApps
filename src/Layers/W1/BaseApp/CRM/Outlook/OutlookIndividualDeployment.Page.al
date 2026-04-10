// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Foundation.Company;
using System.Environment;
using System.Integration;
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
#if not CLEAN29
            group(Step0)
            {
                Caption = '';
                Visible = false;
                ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';

                group(PrivacyNoticeGroup)
                {
                    Caption = 'Your privacy is important to us';
                    ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';

                    group(PrivacyNoticeInner)
                    {
                        ShowCaption = false;
                        ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '29.0';

                        label(PrivacyNoticeLabel)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'This feature utilizes Microsoft Exchange. By continuing you are affirming that you understand that the data handling and compliance standards of Microsoft Exchange may not be the same as those provided by Microsoft Dynamics 365 Business Central. Please consult the documentation for Exchange to learn more.';
                            ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                            ObsoleteState = Pending;
                            ObsoleteTag = '29.0';
                        }
                        field(PrivacyNoticeStatement; PrivacyStatementTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                            ObsoleteState = Pending;
                            ObsoleteTag = '29.0';

                            trigger OnDrillDown()
                            begin
                                Hyperlink('https://go.microsoft.com/fwlink/?linkid=831305');
                            end;
                        }
                    }
                }
            }
#endif
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
                        group("Para2.1.2.12")
                        {
                            Caption = '';
                            InstructionalText = '2. Right-click the .zip file and choose Extract All to extract the add-in files.';
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
                            InstructionalText = '4. Choose the ‘My Add-ins’ tab and ‘add a custom add-in’ from file.';
                        }
                        group("Para2.1.2.3")
                        {
                            Caption = '';
                            InstructionalText = '5. Select and install all downloaded XML files. You may need to repeat this step for each XML file within the ZIP file.';
                        }
                        group("Para2.1.2.4")
                        {
                            Visible = IsSaaS;
                            Caption = '';
                            InstructionalText = '6. Choose Next when done.';
                        }
                        group("Para2.1.2.41")
                        {
                            Visible = not IsSaaS;
                            Caption = '';
                            InstructionalText = '6. Choose Finish when done.';
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
#if not CLEAN29
            action(ActionInstall)
            {
                ApplicationArea = Basic, Suite;
                ObsoleteReason = 'Exchange is depracated. Please deploy add-in manually.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Caption = 'Install to my Outlook';
                Visible = false;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PerformLastStep();
                end;
            }
#endif
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
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        LoadTopBanners();

        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            Email := User."Authentication Email";

        if Email <> '' then
            SampleEmailStepVisible := true;

        IsSaaS := EnvironmentInfo.IsSaaSInfrastructure();
    end;

    trigger OnOpenPage()
    begin
        Session.LogMessage('0000RPP', PageGetOutlookOpenTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
        Step := Step::Intro;
        ShowIntroStep();
    end;

    local procedure NextStep()
    begin
        Step := Step + 1;
        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::ManualDeployment:
                ShowManualDeploymentStep();
            Step::SampleEmail:
                ShowSampleEmailStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroStepVisible := true;
        NextActionVisible := true;
    end;

    local procedure ShowSampleEmailStep()
    begin
        ResetWizardControls();
        SampleEmailStepVisible := true;
        FinishActionVisible := true;
    end;

    local procedure ShowManualDeploymentStep()
    begin
        ResetWizardControls();
        ManualDeploymentStepVisible := true;
        DownloadActionVisible := true;
        if IsSaaS then
            NextActionVisible := true
        else
            FinishActionVisible := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        NextActionVisible := false;
        FinishActionVisible := false;
        DownloadActionVisible := false;

        // Tabs
        IntroStepVisible := false;
        SampleEmailStepVisible := false;
        ManualDeploymentStepVisible := false;
    end;

#if not CLEAN29
    [Obsolete('Exchange is depracated. Please deploy add-in manually.', '29.0')]
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
#endif

    local procedure PerformLastStep()
    begin
        CurrPage.Close();

        if SetupSampleEmails then
            SendEmail();
    end;

    local procedure SendEmail()
    var
        OfficeAddinSampleEmails: Codeunit "Office Add-In Sample Emails";
        O365GraphAuthentication: Codeunit "O365 Graph Authentication";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        RequestBody: JsonObject;
        MessageBody: JsonObject;
        EmailAddress: JsonObject;
        Recipient: JsonObject;
        Recipients: JsonArray;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        AccessToken: SecretText;
        RequestContentTxt: Text;
        RequestUri: Text;
    begin
        O365GraphAuthentication.GetAccessToken(AccessToken);
        if AccessToken.IsEmpty() then
            Error(FailedToAcquireGraphTokenErr);

        MessageBody.Add('subject', StrSubstNo(WelcomeSubjectTxt, PRODUCTNAME.Marketing()));
        if CompanyInformationMgt.IsDemoCompany() then
            MessageBody.Add('body', BuildGraphBody(OfficeAddinSampleEmails.GetHTMLSampleMsg()))
        else
            MessageBody.Add('body', BuildGraphBody(OfficeAddinSampleEmails.GetHTMLSampleMsgNonEvalCompany()));

        EmailAddress.Add('address', Email);
        Recipient.Add('emailAddress', EmailAddress);
        Recipients.Add(Recipient);
        MessageBody.Add('toRecipients', Recipients);

        RequestBody.Add('message', MessageBody);
        RequestBody.Add('saveToSentItems', true);

        RequestBody.WriteTo(RequestContentTxt);
        Content.WriteFrom(RequestContentTxt);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');

        Client.DefaultRequestHeaders().Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));
        Client.DefaultRequestHeaders().Add('Accept', 'application/json');

        RequestUri := StrSubstNo(SendMailUriLbl, O365GraphAuthentication.GetURLForGraph());
        if not Client.Post(RequestUri, Content, ResponseMessage) then
            Error(GraphConnectionErr);

        if not ResponseMessage.IsSuccessStatusCode() then begin
            Session.LogMessage('0000RPQ', StrSubstNo(GraphErrorTelemetryTxt, ResponseMessage.HttpStatusCode()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
            Error(FailedToSendGraphEmailErr);
        end;
    end;

    local procedure BuildGraphBody(BodyHtml: Text): JsonObject
    var
        BodyJson: JsonObject;
    begin
        BodyJson.Add('contentType', 'HTML');
        BodyJson.Add('content', BodyHtml);
        exit(BodyJson);
    end;

    local procedure DownloadManifests()
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestMgt: Codeunit "Add-in Manifest Management";
    begin
        if OfficeAddin.GetAddins() then
            AddinManifestMgt.DownloadMultipleManifestsToClient(OfficeAddin);
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
        OfficeMgt: Codeunit "Office Management";
#if not CLEAN29
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
#endif
        ClientTypeManagement: Codeunit "Client Type Management";
        Email: Text[250];
        Step: Option Intro,ManualDeployment,SampleEmail;
        NextActionVisible: Boolean;
        FinishActionVisible: Boolean;
        DownloadActionVisible: Boolean;
        TopBannerVisible: Boolean;
        IntroStepVisible: Boolean;
        ManualDeploymentStepVisible: Boolean;
        SampleEmailStepVisible: Boolean;
        SetupSampleEmails: Boolean;
        IsSaaS: Boolean;
#if not CLEAN29
        SkipDeployment: Boolean;
        ConnectingMsg: Label 'Connecting to Exchange.';
        DeployAccountMsg: Label 'Deploying add-in for your account.';
        DeploySampleMailMsg: Label 'Deploying sample email to your mailbox.';
        DeployingCompletedMsg: Label 'Deploying completed.';
        DeplyingFailedMsg: Label 'Deploying failed. Error: %1', Comment = '%1 last error text';
        ProgressTemplateMsg: Label '#1##########\@2@@@@@@@@@@', Locked = true;
#endif
        VideoFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2165118', Locked = true;
        LearnMoreFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2102702', Locked = true;
        OutlookSideloadLinkTxt: Label 'https://aka.ms/olksideload', Locked = true;
        WelcomeSubjectTxt: Label 'Welcome to %1 in Outlook', Comment = '%1 - Application name';
        LearnMoreLbl: Label 'Learn more about installing Outlook add-in';
        WatchVideoLbl: Label 'Watch the video';
        DownloadAddinsLbl: Label '1. Download the add-in files to your device.';
        OpenOutlookLinkLbl: Label '3. Go to aka.ms/olksideload.';
        SendMailUriLbl: Label '%1/v1.0/me/sendMail', Locked = true;
        GraphConnectionErr: Label 'Could not establish the connection to Microsoft Graph when sending the sample email.';
        FailedToAcquireGraphTokenErr: Label 'Could not acquire a Microsoft Graph access token for sending the sample email.';
        FailedToSendGraphEmailErr: Label 'Failed to send sample email through Microsoft Graph. Try again later.';
#if not CLEAN29
        PrivacyStatementTxt: Label 'Privacy and cookies';
        SetupCompletedTelemetryTxt: Label 'Outlook add-in deployed.', Locked = true;
        SetupFailedTelemetryTxt: Label 'Outlook add-in deployment failed. Last Error: %1', Locked = true;
        SampleEmailSentTelemetryTxt: Label 'Sample email deployed.', Locked = true;
#endif
        PageGetOutlookOpenTelemetryTxt: Label 'Page Get Outlook Open.', Locked = true;
        GraphErrorTelemetryTxt: Label 'Graph error occurred while sending sample email. Error code: %1', Comment = '%1 - Error code', Locked = true;
}
