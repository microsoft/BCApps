// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

page 99001505 "Subcontracting Setup Wizard"
{
    ApplicationArea = All;
    Caption = 'Subcontracting Setup';
    PageType = NavigatePage;
    SourceTable = "Manufacturing Setup";

    layout
    {
        area(Content)
        {
            group(StandardBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not ReadyToConfigureStepVisible;

                field(StandardBannerImage; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the image for the assisted setup.';
                }
            }
            group(FinishedBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and ReadyToConfigureStepVisible;

                field(FinishedBannerImage; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the image for the completed assisted setup.';
                }
            }
            group(WelcomeStep)
            {
                ShowCaption = false;
                Visible = WelcomeStepVisible;

                group(Welcome)
                {
                    Caption = 'Welcome to Subcontracting';
                    InstructionalText = 'Subcontracting in Business Central helps you purchase production operations from vendors and manage the components that you supply to them.';
                }
                group(WelcomeSequence)
                {
                    Caption = 'Let''s get started';
                    InstructionalText = 'First, review your company defaults. Then continue with the subcontractors, prices, component supply methods, and worksheet that support your subcontracting process.';
                }
            }
            group(CompanyDefaultsStep)
            {
                ShowCaption = false;
                Visible = CompanyDefaultsStepVisible;

                group(CompanyDefaults)
                {
                    Caption = 'Review company defaults';
                    InstructionalText = 'Review the defaults created when the Subcontracting app was installed. You can change these values now or maintain them later from Manufacturing Setup.';

                    field("Subcontracting Template Name"; Rec."Subcontracting Template Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the subcontracting worksheet template used to create subcontracting orders from released production order routings.';
                    }
                    field("Subcontracting Batch Name"; Rec."Subcontracting Batch Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the subcontracting worksheet batch used to create subcontracting orders from released production order routings.';
                    }
                    field("Create Prod. Order Info Line"; Rec."Create Prod. Order Info Line")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether subcontracting purchase orders include an information line for the production order line.';
                    }
                    field("Component Direct Unit Cost"; Rec."Component Direct Unit Cost")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether subcontracting purchase orders use standard component pricing or the direct unit cost from the production order component.';
                    }
                    field("Subc. Comp. Transfer Lead Time"; Rec."Subc. Comp. Transfer Lead Time")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the lead time for transferring components to the subcontractor.';
                    }
                    field("Subc. Default Comp. Location"; Rec."Subc. Default Comp. Location")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies where to get the default location for components supplied to the subcontractor.';
                    }
                }
            }
            group(ReadyToConfigureStep)
            {
                ShowCaption = false;
                Visible = ReadyToConfigureStepVisible;

                group(ReadyToConfigure)
                {
                    Caption = 'Ready to configure Subcontracting';
                    InstructionalText = 'Your company defaults are ready. Use these links to complete the data needed for your subcontracting process, or choose Finish and return to them later.';
                }
                field(WorkCentersLink; WorkCentersLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up subcontractor work centers';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the Work Centers page to set up work centers for subcontractors.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Work Center List");
                    end;
                }
                field(VendorsLink; VendorsLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up vendors';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the Vendors page to set up subcontractors.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Vendor List");
                    end;
                }
                field(LocationsLink; LocationsLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up locations';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the Locations page to set up locations used for subcontracting.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Location List");
                    end;
                }
                field(SubcontractorPricesLink; SubcontractorPricesLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up subcontractor prices';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the Subcontractor Prices page.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Subcontractor Prices");
                    end;
                }
                field(ComponentSupplyMethodsLink; ComponentSupplyMethodsLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Set up component supply methods';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the Production BOMs page to specify how components are supplied to subcontractors.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Production BOM List");
                    end;
                }
                field(DocumentationLink; DocumentationLinkLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Read the Subcontracting documentation';
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Open the documentation for Subcontracting.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(DocumentationUrlLbl);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Return to the previous step.';

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Continue to the next step.';

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Complete the Subcontracting assisted setup.';

                trigger OnAction()
                begin
                    FinishSetup();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        EnableControls();
    end;

    trigger OnOpenPage()
    begin
        Rec.Get();
        FeatureTelemetry.LogUptake('0001Q7N', SubcontractingTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if SetupCompleted then
            exit(true);

        exit(Confirm(SetupNotCompletedQst, false));
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        BackActionEnabled: Boolean;
        CompanyDefaultsStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        ReadyToConfigureStepVisible: Boolean;
        SetupCompleted: Boolean;
        TopBannerVisible: Boolean;
        WelcomeStepVisible: Boolean;
        Step: Option Welcome,CompanyDefaults,ReadyToConfigure;
        ComponentSupplyMethodsLinkLbl: Label 'Set up component supply methods';
        DocumentationLinkLbl: Label 'Read the Subcontracting documentation';
        DocumentationUrlLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2345593', Locked = true;
        LocationsLinkLbl: Label 'Set up locations';
        SetupNotCompletedQst: Label 'The Subcontracting setup is not complete. Are you sure you want to exit?';
        SubcontractingTok: Label 'Subcontracting', Locked = true;
        SubcontractorPricesLinkLbl: Label 'Set up subcontractor prices';
        VendorsLinkLbl: Label 'Set up vendors';
        WorkCentersLinkLbl: Label 'Set up subcontractor work centers';

    local procedure NextStep(Backwards: Boolean)
    begin
        if not Backwards and (Step = Step::CompanyDefaults) then
            CurrPage.SaveRecord();

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure EnableControls()
    begin
        WelcomeStepVisible := Step = Step::Welcome;
        CompanyDefaultsStepVisible := Step = Step::CompanyDefaults;
        ReadyToConfigureStepVisible := Step = Step::ReadyToConfigure;

        BackActionEnabled := not WelcomeStepVisible;
        NextActionEnabled := not ReadyToConfigureStepVisible;
        FinishActionEnabled := ReadyToConfigureStepVisible;
    end;

    local procedure FinishSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        SubcApplicationAreaMgmt: Codeunit "Subc. Application Area Mgmt.";
    begin
        CurrPage.SaveRecord();
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Subcontracting Setup Wizard");
        FeatureTelemetry.LogUptake('0001Q7O', SubcontractingTok, Enum::"Feature Uptake Status"::"Set up");
        SubcApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
        SetupCompleted := true;
        CurrPage.Close();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue() and MediaResourcesDone."Media Reference".HasValue();
    end;
}
