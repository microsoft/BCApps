// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupGuide;

using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

page 20438 "Qlty. Management Setup Guide"
{
    Caption = 'Quality Management Setup Guide';
    PageType = NavigatePage;
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(StandardBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible;

                field(MediaResourcesStd; MediaResourcesStandard."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(MainPage)
            {
                Caption = '';
                InstructionalText = '';
                Visible = MainPageVisible;

                group(WelcomeText1)
                {
                    Caption = 'Welcome to Quality Management';
                    InstructionalText = 'Quality Management in Business Central helps you set up and manage inspection processes to support consistent product quality.';
                }
                group(WelcomeText2)
                {
                    ShowCaption = false;
                    InstructionalText = 'We''ve prepared a dedicated Role Center and a getting started checklist with guided tours to help you explore key pages and default setup steps.';
                }
                group(LetsGoText)
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Select the link below to explore the Quality Management Role Center and checklist in a new browser tab at your own pace. Your current Role Center remains available.';
                }
                field(LetsGoLink; LetsGoLinkLbl)
                {
                    Caption = 'Explore Quality Management';
                    ShowCaption = false;
                    ToolTip = 'Open Quality Management Role Center and checklist in a new browser tab.';
                    Editable = false;
                    ApplicationArea = QualityManagement;

                    trigger OnDrillDown()
                    var
                        TargetURL: Text;
                    begin
                        TargetURL := GetUrl(ClientType::Web, CompanyName, ObjectType::Page, 20426) + URLProfileLbl;
                        Hyperlink(TargetURL);
                    end;

                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Finish)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Finish';
                ToolTip = 'Finish';
                InFooterBar = true;
                Image = Approve;

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TopBannerVisible: Boolean;
        MainPageVisible: Boolean;
        FinishedSetupGuideLbl: Label 'Quality Management Setup Guide finished.', Locked = true;
        QualityManagementTok: Label 'Quality Management', Locked = true;
        LetsGoLinkLbl: Label 'Explore Quality Management';
        URLProfileLbl: Label '&profile=QLTY.%20MANAGER', Locked = true;

    trigger OnInit();
    begin
        MainPageVisible := true;
        LoadTopBanners();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            FeatureTelemetry.LogUptake('0000QIB', QualityManagementTok, Enum::"Feature Uptake Status"::"Set up");
            exit(true);
        end;
    end;

    trigger OnOpenPage();
    begin
        FeatureTelemetry.LogUptake('0000QIC', QualityManagementTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    local procedure FinishAction();
    var
        GuidedExperience: Codeunit "Guided Experience";
        EnvironmentInformation: Codeunit "Environment Information";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Qlty. Management Setup Guide");
        CustomDimensions.Add('RegDetail5', EnvironmentInformation.GetEnvironmentName());
        CustomDimensions.Add('RegDetail6', CompanyName());
        CustomDimensions.Add('RegDetail7', UserId());

        LogMessage('QMUSG001', FinishedSetupGuideLbl, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::All, CustomDimensions);

        QltyNotificationMgmt.EnsureDefaultNotifications();
        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
        CurrPage.Close();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;
}