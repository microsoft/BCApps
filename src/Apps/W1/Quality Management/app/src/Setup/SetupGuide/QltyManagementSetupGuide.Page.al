// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupGuide;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
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
                    InstructionalText = @'Quality Management in Business Central helps you set up and manage inspection processes to support consistent product quality.
                    

                    We''ve prepared a dedicated Quality Manager Role Center and a getting started checklist with guided tours to help you explore key pages and default setup steps.';
                }
                group(LetsGoText)
                {
                    Caption = 'Let''s go!';

                    grid(LinksGrid)
                    {
                        ShowCaption = false;
                        GridLayout = Rows;

                        group(Link1)
                        {
                            InstructionalText = 'Choose the Quality Manager role in your settings and explore the checklist.';
                            ShowCaption = false;

                            field(MySettingsLink; MySettingsLbl)
                            {
                                ShowCaption = false;
                                ApplicationArea = All;
                                DrillDown = true;
                                Caption = 'Open My Settings';
                                ToolTip = 'Open My Settings page.';

                                trigger OnDrillDown()
                                begin
                                    Page.Run(Page::"User Settings");
                                end;
                            }
                        }

                        group(Link2)
                        {
                            InstructionalText = 'Or explore these key pages on your own:';
                            ShowCaption = false;

                            field(QualityInspectionResults; QualityInspectionResultsLbl)
                            {
                                ShowCaption = false;
                                ApplicationArea = All;
                                DrillDown = true;
                                Caption = 'Quality Inspection Results';
                                ToolTip = 'Open the Quality Inspection Results page.';

                                trigger OnDrillDown()
                                begin
                                    Page.Run(Page::"Qlty. Inspection Result List");
                                end;
                            }
                            field(QualityInspectionTemplates; QualityInspectionTemplatesLbl)
                            {
                                ShowCaption = false;
                                ApplicationArea = All;
                                DrillDown = true;
                                Caption = 'Quality Inspection Templates';
                                ToolTip = 'Open the Quality Inspection Templates page.';

                                trigger OnDrillDown()
                                begin
                                    Page.Run(Page::"Qlty. Inspection Template List");
                                end;
                            }
                            field(QualityInspectionGenerationRules; QualityInspectionGenerationRulesLbl)
                            {
                                ShowCaption = false;
                                ApplicationArea = All;
                                DrillDown = true;
                                Caption = 'Quality Inspection Generation Rules';
                                ToolTip = 'Open the Quality Inspection Generation Rules page.';

                                trigger OnDrillDown()
                                begin
                                    Page.Run(Page::"Qlty. Inspection Gen. Rules");
                                end;
                            }
                        }
                    }
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
        MySettingsLbl: Label 'Open My Settings', Locked = true;
        QualityInspectionResultsLbl: Label 'Quality Inspection Results', Locked = true;
        QualityInspectionTemplatesLbl: Label 'Quality Inspection Templates', Locked = true;
        QualityInspectionGenerationRulesLbl: Label 'Quality Inspection Generation Rules', Locked = true;

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