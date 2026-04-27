// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupGuide;

using Microsoft.QualityManagement.Setup;
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
    AccessByPermission = tabledata "Qlty. Management Setup" = R;
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
                    InstructionalText = 'Select the link below to open the Quality Manager Role Center and follow the guided tours.';
                }
                field(SettingsLink; SettingsLinkLbl)
                {
                    Caption = 'Open My Settings';
                    ShowCaption = false;
                    ToolTip = 'Open My Settings';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"User Settings");
                    end;

                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Done)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Done';
                ToolTip = 'Done';
                InFooterBar = true;
                Image = Close;

                trigger OnAction();
                begin
                    DoneAction();
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
        QualityManagementTok: Label 'Quality Management', Locked = true;
        SettingsLinkLbl: Label 'Open My Settings';

    trigger OnInit();
    begin
        MainPageVisible := true;
        LoadTopBanners();
    end;

    trigger OnOpenPage();
    begin
        FeatureTelemetry.LogUptake('0000QIC', QualityManagementTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    local procedure DoneAction();
    var
        GuidedExperience: Codeunit "Guided Experience";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Qlty. Management Setup Guide");

        FeatureTelemetry.LogUptake('0000QIB', QualityManagementTok, Enum::"Feature Uptake Status"::"Set up");

        QltyNotificationMgmt.InitializeAllNotifications();
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