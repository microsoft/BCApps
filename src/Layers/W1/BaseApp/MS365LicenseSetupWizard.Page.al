// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Inventory.Item;
using System.Apps;
using System.Azure.Identity;
using System.Environment;
using System.Reflection;
using System.Utilities;

page 1978 "MS 365 License Setup Wizard"
{
    Caption = 'Set up access with Microsoft 365 licenses';
    Extensible = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    Permissions = tabledata Company = r,
                  tabledata "Media Resources" = r,
                  tabledata "Media Repository" = r,
                  tabledata "Permission Set In Plan Buffer" = r,
                  tabledata Item = r;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Teams, tabs, M365, Microsoft, collaboration, Office, channel, free, access, free access, freemium, Teams setup, teams access';
    AccessByPermission = tabledata "All Profile" = IMD;

    layout
    {
        area(Content)
        {
            group(BannerNotCompleted)
            {
                Editable = false;
                ShowCaption = false;
                Visible = (WizardStep <> WizardStep::Success) and (WizardStep <> WizardStep::TryItOut);

                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerCompleted)
            {
                Editable = false;
                ShowCaption = false;
                Visible = (WizardStep = WizardStep::Success) or (WizardStep = WizardStep::TryItOut);

                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(LandingSaas)
            {
                Visible = (WizardStep = WizardStep::Landing) and (WizardLanding = WizardLanding::Saas);
                ShowCaption = false;
                group(LandingSaasPara1)
                {
                    Caption = 'Set up access to Business Central with Microsoft 365 licenses';
                    InstructionalText = 'To help Business Central users easily share and collaborate on business data with their coworkers, you can enable access with Microsoft 365 licenses.';
                }
                group(LandingSaasPara2)
                {
                    ShowCaption = false;
                    InstructionalText = 'When enabled, users within the same organization that have an applicable Microsoft 365 license will be able to read (but not write) Business Central data that is shared with them in Microsoft Teams, without needing a Business Central license.';
                }
                field(LandingSaasLink; LandingSaasLinkLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(AdminAccessM365LicenseFwdLinkTxt);
                    end;
                }
                group(LandingOnPremPara3)
                {
                    Caption = 'Let’s go!';
                    InstructionalText = 'Choose Next to get started.';
                }
            }
            group(LandingOnPrem)
            {
                Visible = (WizardStep = WizardStep::Landing) and (WizardLanding = WizardLanding::OnPrem);
                ShowCaption = false;
                group(LandingOnPremPara1)
                {
                    Caption = 'This feature is not available';
                    InstructionalText = 'Accessing Business Central data in Microsoft Teams is only available with Business Central online.';
                }
                group(LandingOnPremPara2)
                {
                    ShowCaption = false;
                    InstructionalText = 'When enabled, users within the same organization that have an applicable Microsoft 365 license will be able to read (but not write) Business Central data that is shared with them in Microsoft Teams, without needing a Business Central license.';
                }
                field(LandingOnPremLink; LandingOnPremLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(AdminAccessM365LicenseFwdLinkTxt);
                    end;
                }
            }
            group(Permissions)
            {
                Visible = (WizardStep = WizardStep::Permissions);
                ShowCaption = false;
                group(PermissionsPara1)
                {
                    Caption = 'Configure what can be accessed';
                    InstructionalText = 'When people access Business Central with their Microsoft 365 license for the first time, their user record will be created, and object permissions will be automatically assigned.';
                    Visible = WizardPermissions <> WizardPermissions::PermissionsEmptyInConfig;
                }
                group(PermissionsEmptyInConfigPara0)
                {
                    Caption = 'Configure what can be accessed';
                    InstructionalText = 'Admins determine which data is accessible by applying object permissions.';
                    Visible = WizardPermissions = WizardPermissions::PermissionsEmptyInConfig;
                }
                group(PermissionsEmptyInConfigPara01)
                {
                    ShowCaption = false;
                    InstructionalText = 'When people access Business Central with their Microsoft 365 license for the first time, their user record will be created, and permissions will be automatically assigned.';
                    Visible = WizardPermissions = WizardPermissions::PermissionsEmptyInConfig;
                }
                group(PermissionsEmptyInConfigPara1)
                {
                    ShowCaption = false;
                    InstructionalText = 'You choose which permissions are assigned in the License Configuration page for the Microsoft 365 license. Business Central will not allow these users to edit data, no matter which permissions you configure.';
                    Visible = WizardPermissions <> WizardPermissions::PermissionsEmptyInConfigAndEvalCompany;
                }
                group(PermissionsEvalCompanyPara1)
                {
                    Caption = '';
                    InstructionalText = 'Since this is an evaluation company, you can make it easier to try out this feature by not restricting access using permissions. You can always change this afterwards from the license configuration page.';
                    Visible = WizardPermissions = WizardPermissions::PermissionsEmptyInConfigAndEvalCompany;
                }
                field(PermissionsLink; PermissionsLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(AssignPermissionsToUsersFwdLinkTxt);
                    end;
                }
                group(PermissionsExistInConfigPara1)
                {
                    Caption = '';
                    InstructionalText = 'You appear to have some permissions configured already. Choose Next to proceed with these permissions.';
                    Visible = WizardPermissions = WizardPermissions::PermissionsExistsInConfig;
                }
            }
            group(TAC)
            {
                Visible = (WizardStep = WizardStep::TAC);
                ShowCaption = false;
                group(TACEnablePara1)
                {
                    Caption = 'Enable access';
                    InstructionalText = 'Now that you have configured object permissions, you are ready to enable access on this environment from the Business Central admin center.';
                    Visible = WizardTAC = WizardTAC::DisabledInTAC;
                }
                group(TACEnablePara2)
                {
                    ShowCaption = false;
                    InstructionalText = 'Choose ‘Enable’ to continue. You can also turn this off or on at any time from the Business Central admin center.';
                    Visible = WizardTAC = WizardTAC::DisabledInTAC;
                }
                group(TACConfigurePara1)
                {
                    Caption = 'Enable access';
                    InstructionalText = 'Access is already enabled for this environment in the Business Central admin center.';
                    Visible = WizardTAC = WizardTAC::EnabledInTAC;
                }
            }
            group(AccessControl)
            {
                Visible = (WizardStep = WizardStep::AccessControl);
                ShowCaption = false;
                group(AccessControlDynPara1)
                {
                    Caption = 'Choose who gets access';
                    InstructionalText = 'This environment does not have a security group assigned: anyone with a Microsoft 365 license within your organization can access records shared with them.';
                }
                group(AccessControlPara2)
                {
                    ShowCaption = false;
                    InstructionalText = 'To restrict who gets access, you can assign a security group in the Business Central admin center that determines which licensed Business Central users and which Microsoft 365 license-holders can access this environment.';
                }
                field(AccessControlLink; AccessControlLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(ManageAccessToEnvsFwdLinkTxt);
                    end;
                }
            }
            group(AppDeployment)
            {
                Visible = (WizardStep = WizardStep::AppDeployment);
                ShowCaption = false;
                group(AppDeploymentPara1)
                {
                    Caption = 'Deploy the Business Central app for Teams';
                    InstructionalText = 'Data can only be shared and read in Microsoft Teams if people have the Business Central app for Teams installed.';
                }
                group(AppDeploymentPara2)
                {
                    ShowCaption = false;
                    InstructionalText = 'If you have deployed the app before, or have done this only for licensed Business Central users, consider deploying more broadly to make it available to everyone in your organization.';
                }
                field(AppDeploymentLink; AppDeploymentLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(AppDeploymentFwdLinkTxt);
                    end;
                }
            }
            group(Success)
            {
                Visible = (WizardStep = WizardStep::Success);
                ShowCaption = false;
                group(SuccessPara1)
                {
                    Caption = 'Success!';
                    InstructionalText = 'You’re all set up so that people in your organization that only have a Microsoft 365 license can access data from this environment.';
                }
                group(SuccessPara2)
                {
                    Visible = ShowSwitcherText;
                    ShowCaption = false;
                    InstructionalText = 'To configure other environments, close this setup window, use the switcher (Ctrl+O) to go to another environment, then run this guided setup again.';
                }
                group(SuccessPara3)
                {
                    ShowCaption = false;
                    InstructionalText = 'Choose ‘Try it out’ to experience how people will share and read data in Microsoft Teams.';
                }
            }
            group(TryItOut)
            {
                Visible = (WizardStep = WizardStep::TryItOut);
                ShowCaption = false;
                group(TryItOutPara1)
                {
                    Caption = 'Find your buddy';
                    InstructionalText = 'To get started, identify a coworker that has a Microsoft 365 license but does not have a Business Central license';
                }
                field(TryItOutLink2; TryItOutLink2Txt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Microsoft365License.OpenM365AdminCenter();
                    end;
                }

                group(TryItOutPara2)
                {
                    Caption = 'Share something with them';
                    InstructionalText = 'Go to any list or card page and use the Share action to Share to Teams.';
                }
                field(TryItOutLink3; TryItOutLink3Txt)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    Visible = ShowItemCardLink;

                    trigger OnDrillDown()
                    var
                        SpotlightTour: Codeunit "Spotlight Tour";
                        SpotlightTourType: Enum "Spotlight Tour Type";
                    begin
                        CurrPage.Close();
                        SpotlightTour.Start(Page::"Item Card", SpotlightTourType::"Share to Teams", ShareToTeamsStep1TitleTxt, ShareToTeamsStep1TextTxt, ShareToTeamsStep2TileTxt, ShareToTeamsStep2TextTxt);
                    end;
                }
                group(TryItOutPara3)
                {
                    ShowCaption = false;
                    InstructionalText = '💡 Tip: when sharing to Teams, make sure to include the link preview as a card. Your coworker can only access the page or record from the Card details, or from any tabs you add to Teams.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ConfigPermissionsDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Configure permissions';
                Visible = ConfigPermissionsDefaultActionVisible;
                InFooterBar = true;

                trigger OnAction()
                begin
                    RunPermissionAction();
                end;
            }

            action(ConfigPermissionsSecondary)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Configure permissions';
                Visible = ConfigPermissionsSecondaryActionVisible;
                InFooterBar = true;

                trigger OnAction()
                begin
                    RunPermissionAction();
                end;
            }
            action(GoToAdminCenter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go to admin center';
                Visible = GoToAdminCenterActionVisible;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Microsoft365License.OpenBCAdminCenter();
                end;
            }
            action(AccessControlAdminCenter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go to admin center';
                Visible = AccessControlAdminCenterActionVisible;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Microsoft365License.OpenBCAdminCenter();
                    WizardNextSkip := WizardNextSkip::Next;
                    UpdateActionVisibility();
                end;
            }
            action(GoToGuidedDevelopment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go to guided deployment';
                Visible = GoToGuidedDevelopmentActionVisble;
                InFooterBar = true;

                trigger OnAction()
                var
                    TeamCentralizedDeployment: Page "Teams Centralized Deployment";
                begin
                    TeamCentralizedDeployment.LaunchFromM365Guide();
                    TeamCentralizedDeployment.RunModal();
                    WizardNextSkip := WizardNextSkip::Next;
                    UpdateActionVisibility();
                end;
            }
            action(TryItOutAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Try It Out';
                Visible = TryItOutActionVisible;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(Back)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Visible = BackActionVisible;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PrevStep();
                end;
            }
            action(Next)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Visible = NextActionVisible;
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(EnableInAdminCenter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enable';
                Visible = EnableInAdminCenterActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    EnvironmentInformation: Codeunit "Environment Information";
                begin
                    EnvironmentInformation.EnableM365Collaboration();
                    NextStep();
                end;
            }
            action(Close)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close';
                Visible = CloseActionVisible;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"MS 365 License Setup Wizard");
                    CurrPage.Close();
                end;
            }
            action(Skip)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Skip';
                Visible = SkipActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(Done)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Done';
                Visible = DoneActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"MS 365 License Setup Wizard");
                    CurrPage.Close();
                end;
            }
            action(DontRestrict)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Don’t restrict access';
                Visible = DontRestrictActionVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Microsoft365License.AssignMicrosoft365ReadPermission(false);
                    NextStep();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Item: Record Item;
    begin
        M365PlanId := PlanIds.GetMicrosoft365PlanId();
        ShowSwitcherText := (CurrentClientType <> ClientType::Tablet) and
                            (CurrentClientType <> ClientType::Phone) and
                            (CurrentClientType <> ClientType::Teams);
        ShowItemCardLink := not Item.IsEmpty();

        LoadTopBanners();
        ShowLandingStep();
        UpdateActionVisibility();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;

    local procedure NextStep()
    begin
        case WizardStep of
            WizardStep::Landing:
                ShowPermissionsStep();
            WizardStep::Permissions:
                ShowTAC();
            WizardStep::TAC:
                ShowAccessControl();
            WizardStep::AccessControl:
                ShowAppDeployment();
            WizardStep::AppDeployment:
                ShowSuccess();
            WizardStep::Success:
                ShowTryItOut();
        end;
        UpdateActionVisibility();
    end;

    local procedure PrevStep()
    begin
        case WizardStep of
            WizardStep::Permissions:
                ShowLandingStep();
            WizardStep::TAC:
                ShowPermissionsStep();
            WizardStep::AccessControl:
                ShowTAC();
        end;
        UpdateActionVisibility();
    end;

    local procedure ShowLandingStep()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        WizardStep := WizardStep::Landing;
        if EnvironmentInformation.IsSaaS() then
            WizardLanding := WizardLanding::Saas
        else
            WizardLanding := WizardLanding::OnPrem;
    end;

    local procedure ShowPermissionsStep()
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        WizardStep := WizardStep::Permissions;
        if HasLicenseConfiguration() then
            WizardPermissions := WizardPermissions::PermissionsExistsInConfig
        else
            if Company."Evaluation Company" then
                WizardPermissions := WizardPermissions::PermissionsEmptyInConfigAndEvalCompany
            else
                WizardPermissions := WizardPermissions::PermissionsEmptyInConfig;
    end;

    local procedure ShowTAC()
    begin
        WizardStep := WizardStep::TAC;
        if AzureADGraph.IsM365CollaborationEnabled() then
            WizardTAC := WizardTAC::EnabledInTAC
        else
            WizardTAC := WizardTAC::DisabledInTAC;
    end;

    local procedure ShowAccessControl()
    begin
        WizardStep := WizardStep::AccessControl;
        WizardNextSkip := WizardNextSkip::Skip;

        if AzureADGraph.IsEnvironmentSecurityGroupDefined() then
            ShowAppDeployment();
    end;

    local procedure ShowAppDeployment()
    begin
        WizardStep := WizardStep::AppDeployment;
        WizardNextSkip := WizardNextSkip::Skip;
    end;

    local procedure ShowSuccess()
    begin
        WizardStep := WizardStep::Success;
    end;

    local procedure ShowTryItOut()
    begin
        WizardStep := WizardStep::TryItOut;
    end;

    local procedure UpdateActionVisibility()
    begin
        DontRestrictActionVisible := (WizardStep = WizardStep::Permissions) and (WizardPermissions = WizardPermissions::PermissionsEmptyInConfigAndEvalCompany);
        DoneActionVisible := WizardStep = WizardStep::Success;
        TryItOutActionVisible := WizardStep = WizardStep::Success;
        GoToGuidedDevelopmentActionVisble := WizardStep = WizardStep::AppDeployment;
        AccessControlAdminCenterActionVisible := WizardStep = WizardStep::AccessControl;
        EnableInAdminCenterActionVisible := ((WizardStep = WizardStep::TAC) and (WizardTAC = WizardTAC::DisabledInTAC));
        GoToAdminCenterActionVisible := (WizardStep = WizardStep::TAC);
        ConfigPermissionsDefaultActionVisible := (WizardStep = WizardStep::Permissions) and (WizardPermissions = WizardPermissions::PermissionsEmptyInConfig);
        ConfigPermissionsSecondaryActionVisible := (WizardStep = WizardStep::Permissions) and (WizardPermissions <> WizardPermissions::PermissionsEmptyInConfig);

        NextActionVisible :=
            ((WizardStep = WizardStep::Landing) and (WizardLanding = WizardLanding::Saas)) or
            ((WizardStep = WizardStep::Permissions) and (WizardPermissions <> WizardPermissions::PermissionsEmptyInConfigAndEvalCompany)) or
            ((WizardStep = WizardStep::TAC) and (WizardTAC = WizardTAC::EnabledInTAC)) or
            ((WizardStep = WizardStep::AccessControl) and (WizardNextSkip = WizardNextSkip::Next)) or
            ((WizardStep = WizardStep::AppDeployment) and (WizardNextSkip = WizardNextSkip::Next));

        NextActionEnabled :=
            not ((WizardStep = WizardStep::Permissions) and (WizardPermissions = WizardPermissions::PermissionsEmptyInConfig));

        BackActionVisible :=
            (WizardStep = WizardStep::Permissions) or
            (WizardStep = WizardStep::TAC) or
            (WizardStep = WizardStep::AccessControl);

        CloseActionVisible :=
            ((WizardStep = WizardStep::Landing) and (WizardLanding = WizardLanding::OnPrem)) or
            (WizardStep = WizardStep::TryItOut);

        SkipActionVisible :=
            (((WizardStep = WizardStep::AccessControl) and (WizardNextSkip = WizardNextSkip::Skip)) or
            ((WizardStep = WizardStep::AppDeployment) and (WizardNextSkip = WizardNextSkip::Skip)));

        CurrPage.Update(true);
    end;

    local procedure RunPermissionAction()
    begin
        OpenPlanConfigurationForM365();
        ShowPermissionsStep();
        UpdateActionVisibility();
    end;

    local procedure OpenPlanConfigurationForM365()
    var
        PlanConfigurationCard: Page "Plan Configuration Card";
    begin
        PlanConfigurationCard.SetPlan(M365PlanId);
        PlanConfigurationCard.RunModal();
    end;

    local procedure HasLicenseConfiguration(): Boolean
    var
        PermissionSetInPlanBuffer: Record "Permission Set In Plan Buffer";
        PlanConfiguration: Codeunit "Plan Configuration";
    begin
        PlanConfiguration.GetCustomPermissions(PermissionSetInPlanBuffer);
        PermissionSetInPlanBuffer.SetRange("Plan ID", M365PlanId);
        PermissionSetInPlanBuffer.SetFilter("Role ID", '<>%1', LoginTok);
        exit(PermissionSetInPlanBuffer.Count() > 0);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        AzureADGraph: Codeunit "Azure AD Graph";
        ClientTypeManagement: Codeunit "Client Type Management";
        Microsoft365License: Codeunit "Microsoft 365 License";
        PlanIds: Codeunit "Plan Ids";
        GuidedExperience: Codeunit "Guided Experience";
        M365PlanId: Guid;
        TopBannerVisible, NextActionVisible, NextActionEnabled, BackActionVisible, CloseActionVisible, SkipActionVisible, ShowSwitcherText, ShowItemCardLink : Boolean;
        DontRestrictActionVisible, DoneActionVisible, TryItOutActionVisible, GoToGuidedDevelopmentActionVisble : Boolean;
        AccessControlAdminCenterActionVisible, GoToAdminCenterActionVisible, EnableInAdminCenterActionVisible, ConfigPermissionsDefaultActionVisible, ConfigPermissionsSecondaryActionVisible : Boolean;
        WizardStep: Option Landing,Permissions,TAC,AccessControl,AppDeployment,Success,TryItOut;
        WizardLanding: Option Saas,OnPrem;
        WizardPermissions: Option PermissionsExistsInConfig,PermissionsEmptyInConfig,PermissionsEmptyInConfigAndEvalCompany;
        WizardTAC: Option EnabledInTAC,DisabledInTAC;
        WizardNextSkip: Option Skip,Next;
        LandingOnPremLinkTxt: Label 'Learn about minimum requirements for Teams integration';
        LandingSaasLinkLinkTxt: Label 'Learn more';
        PermissionsLinkTxt: Label 'Learn about permissions';
        AccessControlLinkTxt: Label 'Learn more about securing environments';
        AppDeploymentLinkTxt: Label 'Learn more about the Business Central app for Teams';
        TryItOutLink2Txt: Label 'Find more people from the Microsoft 365 admin center users list';
        TryItOutLink3Txt: Label 'Help me share the item card';
        ShareToTeamsStep1TitleTxt: Label 'Try it out with Teams';
        ShareToTeamsStep1TextTxt: Label 'Experience just one of many ways in which Business Central users across your organization can share and collaborate with others, regardless of whether recipients have a Business Central license.';
        ShareToTeamsStep2TileTxt: Label 'Share to Teams';
        ShareToTeamsStep2TextTxt: Label 'When you use the share icon to share a link to this item record, the compose window will automatically display the link preview as a card. Make sure you include the card with your message: recipients can only access the record from the card details.';
        AdminAccessM365LicenseFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2209653', Locked = true;
        AssignPermissionsToUsersFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2185295', Locked = true;
        ManageAccessToEnvsFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2171715', Locked = true;
        AppDeploymentFwdLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170851', Locked = true;
        LoginTok: Label 'LOGIN', Locked = true;

}
