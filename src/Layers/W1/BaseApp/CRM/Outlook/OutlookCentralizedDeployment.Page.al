// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Utilities;

page 1831 "Outlook Centralized Deployment"
{
    Caption = 'Outlook Add-in Centralized Deployment';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Office Add-in";
    SourceTableTemporary = true;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Outlook, Office, O365, AddIn, M365, Microsoft 365, Addon, App, Plugin, Manifest, Install Outlook, Set up Outlook';

    layout
    {
        area(content)
        {
            group(TopBannerStandardGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not InstructionsStepVisible;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(TopBannerDoneGrp)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and InstructionsStepVisible;
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            // Introduction step
            group(Step1)
            {
                Caption = '';
                Visible = IntroStepVisible;
                group("Para1.1")
                {
                    Caption = 'Business Central Outlook add-in';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Deploy Business Central Outlook add-in for specific users, groups, or the entire organization, so users don’t have to install them themselves.';
                    }
                    group("Para1.1.2")
                    {
                        Caption = '';
                        Visible = IsSaaS;
                        field(CentralizedDeploymentRequirements; CentralizedDeploymentRequirementsLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            ShowCaption = false;
                            Editable = false;
                            Visible = IsSaas;

                            trigger OnDrillDown()
                            begin
                                Hyperlink(CentralizedDeploymentRequirementsFwdLinkTxt);
                            end;
                        }
                    }
                    group("Para1.1.3")
                    {
                        Caption = '';
                        InstructionalText = 'This doesn’t affect permissions assigned to users in Business Central.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    Visible = IsSaas;
                    InstructionalText = 'Centralized Deployment requires configuring both Business Central and Microsoft 365. Choose Next to get started.';
                }
                group("Para1.2A")
                {
                    Caption = 'Let''s go!';
                    Visible = not IsSaas;
                    InstructionalText = 'Centralized Deployment requires configuring Business Central along with Microsoft 365 or Exchange Server. Choose Next to get started.';
                }
            }

            group(Step1_5)
            {
                Caption = '';
                Visible = PrivacyNoticeStepVisible;

                group(PrivacyNotice)
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

            // Download manifests step
            group(Step2)
            {
                Caption = '';
                Visible = ManifestsStepVisible;
                group("Para2.1")
                {
                    Caption = '';
                    InstructionalText = 'Choose the add-in to download for deployment. Your choice here determines what functionality is available to users in Outlook.';

                    repeater(addins)
                    {
                        field(Name; Rec.Name)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the name of the add-in.';
                            Editable = false;
                        }
                        field(Deploy; Rec.Deploy)
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies whether the add-in will be deployed.';
                            Width = 5;
                        }
                        field(Description; Rec.Description)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies a description of the add-in.';
                            Editable = false;
                        }
                        field(Version; Rec.Version)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ToolTip = 'Specifies the version of the record.';
                        }
                    }
                }
            }

            // Deploy to M365 or Exchange Server step
            group(Step3)
            {
                Caption = '';
                Visible = DeployToStepVisible;
                group("Para3.1")
                {
                    Caption = 'Where do you want to deploy to?';
                    field(DeployTo; DeployTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Deploy Add-in to';
                        OptionCaption = 'Microsoft 365,Exchange Server';
                        ToolTip = 'Specifies the Exchange service where you want to deploy the add-in.';
                    }
                }
            }

            // Instructions Step for M365
            group("Step4A")
            {
                Caption = '';
                Visible = InstructionsStepVisible and (DeployTo = DeployTo::M365);
                group("Para4.1")
                {
                    Caption = 'Now configure Microsoft 365';
                    group("Para4.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You must configure and deploy the add-in to users and groups using the Microsoft 365 admin center. It requires the Office Apps admin role or the Global admin role.';
                    }
                    group("Para4.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'Follow these steps:';

                        group("Para4.1.2.1")
                        {
                            Caption = '';
                            InstructionalText = '1. In the Microsoft 365 admin center, go to Integrated Apps.';
                        }
                        group("Para4.1.2.2")
                        {
                            Caption = '';
                            InstructionalText = '2. Choose ‘Upload custom apps’ and select the XML files you downloaded earlier. If the files are zipped, you must unzip the files first.';
                        }
                        group("Para4.1.2.3")
                        {
                            Caption = '';
                            InstructionalText = '3. Follow the deployment instructions.';
                        }
                    }
                    field(IntegratedAppsSetup; IntegratedAppsLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(IntegratedAppsFwdLinkTxt);
                        end;
                    }
                }
            }
            // Instructions Step for Exchange Server
            group("Step4B")
            {
                Caption = '';
                Visible = InstructionsStepVisible and (DeployTo = DeployTo::ExchangeServer);
                group("Para4.2")
                {
                    Caption = 'Now configure Exchange Server';
                    group("Para4.2.1")
                    {
                        Caption = '';
                        InstructionalText = 'You must configure and deploy the add-in to users and groups using the Exchange admin center. It requires the Organization Management role or the Org Apps admin role.';
                    }
                    group("Para4.2.2")
                    {
                        Caption = '';
                        InstructionalText = 'Follow these steps:';
                        group("Para4.2.2.1")
                        {
                            Caption = '';
                            InstructionalText = '1. Go to ‘Organization’ and choose Add-ins in the Exchange admin center.';
                        }
                        group("Para4.2.2.2")
                        {
                            Caption = '';
                            InstructionalText = '2. Choose ‘Add from File’ option under New section and select the XML files you downloaded earlier. If the files are zipped, you must unzip the files first.';
                        }
                        group("Para4.2.2.3")
                        {
                            Caption = '';
                            InstructionalText = '3. Follow the deployment instructions.';
                        }
                    }
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

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Visible = NextActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionDownload)
            {
                ApplicationArea = All;
                Caption = 'Download and Continue';
                Visible = DownloadActionVisible;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Download the manifests for selected add-in and continue.';

                trigger OnAction();
                var
                    TempOfficeAddin: Record "Office Add-in" temporary;
                    AddinManifestMgt: Codeunit "Add-in Manifest Management";
                begin
                    TempOfficeAddin.Copy(Rec, true);
                    TempOfficeAddin.SetRange(Deploy, true);
                    if TempOfficeAddin.Findset() then
                        AddinManifestMgt.DownloadMultipleManifestsToClient(TempOfficeAddin);
                    NextStep(false);
                end;
            }
            action(ActionDone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Done';
                Visible = DoneActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    Session.LogMessage('0000F8S', StrSubstNo(SetupTelemetryTxt, Format(DeployTo)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OfficeMgt.GetOfficeAddinTelemetryCategory());
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Outlook Centralized Deployment");
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LoadTopBanners();
        IsSaaS := EnvironmentInformation.IsSaaS();
        DeployTo := DeployTo::M365;
    end;

    trigger OnOpenPage()
    var
        OfficeAddin: Record "Office Add-in";
    begin
        if OfficeAddin.GetAddins() then
            repeat
                Rec := OfficeAddin;
                Rec.Insert();
            until OfficeAddin.Next() = 0;
        ShowIntroStep();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::PrivacyNotice:
                ShowPrivacyNoticeStep();
            Step::Manifests:
                ShowManifestsStep();
            Step::DeployTo:
                ShowDeployToStep(Backwards);
            Step::Instructions:
                ShowInstructionsStep();
        end;

        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroStepVisible := true;
        BackActionEnabled := false;
    end;

    local procedure ShowPrivacyNoticeStep()
    begin
        ResetWizardControls();
        PrivacyNoticeStepVisible := true;
    end;

    local procedure ShowManifestsStep()
    begin
        ResetWizardControls();
        ManifestsStepVisible := true;
        NextActionVisible := false;
        DownloadActionVisible := true;
    end;

    local procedure ShowDeployToStep(Backwards: Boolean)
    begin
        ResetWizardControls();
        NextActionVisible := true;
        DeployToStepVisible := true;
        // Skip this step if SaaS
        if IsSaaS then
            NextStep(Backwards);
    end;

    local procedure ShowInstructionsStep()
    begin
        ResetWizardControls();
        InstructionsStepVisible := true;
        NextActionVisible := false;
        DoneActionVisible := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackActionEnabled := true;
        NextActionVisible := true;
        DoneActionVisible := false;
        DownloadActionVisible := false;

        // Tabs
        IntroStepVisible := false;
        PrivacyNoticeStepVisible := false;
        ManifestsStepVisible := false;
        DeployToStepVisible := false;
        InstructionsStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        OfficeMgt: Codeunit "Office Management";
        Step: Option Intro,PrivacyNotice,Manifests,DeployTo,Instructions;
        DeployTo: Option M365,ExchangeServer;
        BackActionEnabled: Boolean;
        NextActionVisible: Boolean;
        DoneActionVisible: Boolean;
        DownloadActionVisible: Boolean;
        TopBannerVisible: Boolean;
        IntroStepVisible: Boolean;
        PrivacyNoticeStepVisible: Boolean;
        ManifestsStepVisible: Boolean;
        DeployToStepVisible: Boolean;
        InstructionsStepVisible: Boolean;
        IsSaaS: Boolean;
        CentralizedDeploymentRequirementsFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2164357', Locked = true;
        CentralizedDeploymentRequirementsLbl: Label 'Requirements for Centralized Deployment of the add-in';
        IntegratedAppsFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2163967', Locked = true;
        IntegratedAppsLbl: Label 'Go to Microsoft 365 (opens in a new window)';
        LearnMoreFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2165028', Locked = true;
        LearnMoreLbl: Label 'Learn more about the add-in for Outlook in Exchange Server';
        SetupTelemetryTxt: Label 'Centralized deployment for Outlook Add-ins setup finished with deployment to = %1', Comment = '%1 specifies either M365 or ExchangeServer ', Locked = true;
        PrivacyStatementTxt: Label 'Privacy and cookies';
}
