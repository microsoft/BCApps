// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupWizard;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// This setup wizard is used to help configure the system initially.
/// </summary>
page 20438 "Qlty. Management Setup Wizard"
{
    Caption = 'Quality Management Setup Wizard';
    PageType = NavigatePage;
    UsageCategory = Administration;
    ApplicationArea = Basic, Suite;
    SourceTable = "Qlty. Management Setup";

    layout
    {
        area(Content)
        {
            group(Header)
            {
                ShowCaption = false;
                Visible = false;
            }
            group(StandardBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not (StepDone = CurrentStepCounter);
                field(MediaResourcesStd; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FinishedBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and (StepDone = CurrentStepCounter);
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(SettingsFor_StepWelcome)
            {
                Visible = (CurrentStepCounter = StepWelcome);

                group(SettingsFor_StepWelcome_Header_ExpressOnly)
                {
                    ShowCaption = false;
                    Visible = ShowHTMLHeader;
                    InstructionalText = 'This wizard will guide you through the initial setup required to perform quality inspections.';
                }
            }
            group(DemoData)
            {
                Caption = 'Demo data for Quality Management';
                Visible = (StepDemoData = CurrentStepCounter);

                group(DemoDataIntroduction)
                {
                    Caption = 'Demo data for Quality Management';
                    InstructionalText = 'The Quality Management application includes demo data available through the Contoso Coffee Demo Dataset application.';
                }
                group(DemoDataInstructions)
                {
                    Caption = 'Install demo data';
                    InstructionalText = 'To install demo data, go to the Contoso Demo Tool page and select the Quality Management module.';
                }
            }
            group(SettingsFor_StepWhatAreYouMakingQltyInspectionsFor)
            {
                Caption = 'Where do you plan on using Quality Inspections?';
                Visible = (StepWhatAreYouMakingQltyInspectionsFor = CurrentStepCounter);
                InstructionalText = 'Where do you plan on using Quality Inspections?';

                group(SettingsFor_WhatFor_ProductionOutput)
                {
                    Caption = 'Production';
                    Visible = IsPremiumExperienceEnabled;
                    InstructionalText = 'I want to create inspections when recording production output. The most common scenarios are when inventory is posted from the output journal, but it could also be for intermediate steps or other triggers.';

                    field(ChooseWhatFor_ProductionOutput; WhatForProduction)
                    {
                        ApplicationArea = Manufacturing;
                        ShowCaption = false;
                        Caption = 'I want to create inspections when recording production output.';
                        ToolTip = 'I want to create inspections when recording production output. The most common scenarios are when inventory is posted from the output journal, but it could also be for intermediate steps or other triggers.';
                    }
                }
                group(SettingsFor_WhatFor_Receiving)
                {
                    Caption = 'Receiving';
                    InstructionalText = 'I want to create inspections when receiving inventory.';

                    field(ChooseWhatFor_Receiving; WhatForReceiving)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want to create inspections when receiving inventory.';
                        ToolTip = 'I want to create inspections when receiving inventory.';
                    }
                }
                group(SettingsFor_WhatFor_SomethingElse)
                {
                    Caption = 'Something Else';
                    InstructionalText = 'You can use Quality Management to create manual inspections for effectively any table. Use this option if you want to create inspections in other areas, or if you want to manually configure this later.';

                    field(ChooseWhatFor_SomethingElse; WhatForSomethingElse)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want to create inspections for something different.';
                        ToolTip = 'I want to create inspections for something different.';
                    }
                }
            }
            group(SettingsFor_StepProductionConfig)
            {
                Caption = 'Production Inspection Configuration';
                Visible = (StepProductionConfig = CurrentStepCounter);
                InstructionalText = 'In production scenarios, how do you want to make the inspections?';

                group(SettingsFor_Production_Production_CreateInspectionsAutomatically)
                {
                    Caption = 'I want inspections created automatically when output is recorded.';
                    InstructionalText = 'Creating an inspection automatically when output is recorded means that as output is recorded, the system will make inspections for you. Use this option when inspections must exist when production is output. Do not use this option if your process requires that the Quality Management users make the inspections.';

                    field(ChooseProduction_Production_CreateInspectionsAutomatically; ProductionCreateInspectionsAutomatically)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want inspections created automatically when output is recorded.';
                        ToolTip = 'Creating an inspection automatically when output is recorded means that as output is recorded, the system will make inspections for you. Use this option when inspections must exist when production is output. Do not use this option if your process requires that the Quality Management users make the inspections.';

                        trigger OnValidate()
                        begin
                            ProductionCreateInspectionsManually := not ProductionCreateInspectionsAutomatically;
                        end;
                    }
                }
                group(SettingsFor_Production_Production_CreateInspectionsManually)
                {
                    Caption = 'I want a person to make an inspection.';
                    InstructionalText = 'In this scenario a person is manually creating inspections by clicking a button. Use this option when your process requires a person to create an inspection, or are performing ad-hoc inspections. Examples could be creating inspections for Non Conformance Reports, or to track re-work, or to track damage.';

                    field(ChooseProduction_Production_CreateInspectionsManually; ProductionCreateInspectionsManually)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want an inspector or another person to make an inspection.';
                        ToolTip = 'In this scenario a person is manually creating inspections by clicking a button. Use this option when your process requires a person to create an inspection, or are performing ad-hoc inspections. Examples could be creating inspections for Non Conformance Reports, or to track re-work, or to track damage.';

                        trigger OnValidate()
                        begin
                            ProductionCreateInspectionsAutomatically := not ProductionCreateInspectionsManually;
                        end;
                    }
                }
            }
            group(SettingsFor_StepReceivingConfig)
            {
                Caption = 'Receiving Inspection Configuration';
                Visible = (StepReceivingConfig = CurrentStepCounter);
                InstructionalText = 'In receiving scenarios, how do you want to make the inspections?';

                field(ChooseAutomaticallyCreateInspectionPurchase; ReceiveCreateInspectionsAutomaticallyPurchase)
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Receipts';
                    ToolTip = 'Specifies that an inspection will be automatically created when product is received via a purchase order.';
                }
                field(ChooseAutomaticallyCreateInspectionTransfer; ReceiveCreateInspectionsAutomaticallyTransfer)
                {
                    ApplicationArea = All;
                    Caption = 'Transfer Receipts';
                    ToolTip = 'Specifies that an inspection will be automatically created when product is received via a transfer order.';
                }
                field(ChooseAutomaticallyCreateInspectionWarehouseReceipt; ReceiveCreateInspectionsAutomaticallyWarehouseReceipt)
                {
                    ApplicationArea = All;
                    Caption = 'Warehouse Receipts';
                    ToolTip = 'Specifies that an inspection will be automatically created when product is received via a warehouse receipt.';
                }
                field(ChooseAutomaticallyCreateInspectionSalesReturn; ReceiveCreateInspectionsAutomaticallySalesReturn)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Return Receipts';
                    ToolTip = 'Specifies that an inspection will be automatically created when product is received via a sales return.';
                }
                group(SettingsFor__Receive_CreateInspectionsManually)
                {
                    Caption = 'I only want people to make inspections.';
                    InstructionalText = 'In this scenario a person is manually creating inspections by clicking a button. Use this option when your process requires a person to create an inspection, or are performing ad-hoc inspections. Examples could be creating inspections for Non Conformance Reports, or to track damage for goods or material received.';

                    field(ChooseReceive_CreateInspectionsManually; ReceiveCreateInspectionsManually)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I only want people to make inspections.';
                        ToolTip = 'In this scenario a person is manually creating inspections by clicking a button. Use this option when your process requires a person to create an inspection, or are performing ad-hoc inspections. Examples could be creating inspections for Non Conformance Reports, or to track damage for goods or material received.';

                        trigger OnValidate()
                        begin
                            if ReceiveCreateInspectionsManually then begin
                                ReceiveCreateInspectionsAutomaticallyPurchase := false;
                                ReceiveCreateInspectionsAutomaticallyTransfer := false;
                                ReceiveCreateInspectionsAutomaticallySalesReturn := false;
                                ReceiveCreateInspectionsAutomaticallyWarehouseReceipt := false;
                            end else
                                ReceiveCreateInspectionsAutomaticallyPurchase := true;
                        end;
                    }
                }
            }
            group(SettingsFor_StepDone)
            {
                Visible = (StepDone = CurrentStepCounter);

                group(SettingsFor_StepDone_Header_ExpressOnly)
                {
                    Caption = 'You''re all set!';
                    Visible = ShowHTMLHeader;
                    InstructionalText = 'Thank you for installing Quality Management.';
                }

                group(Control18)
                {
                    Caption = 'Get Started';
                    InstructionalText = 'Get started by navigating to Quality Inspections and Quality Inspection Generation Rules.';
                    ShowCaption = false;

                    field(QualityInspections; QualityInspectionsLbl)
                    {
                        Caption = 'Quality Inspections';
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        begin
                            Page.RunModal(Page::"Qlty. Inspection List");
                        end;
                    }
                    field(QualityInspectionGenerationRulesLbl; QualityInspectionGenerationRulesLbl)
                    {
                        Caption = 'Quality Inspection Generation Rules';
                        ShowCaption = false;
                        Editable = false;
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        begin
                            Page.RunModal(Page::"Qlty. Inspection Gen. Rules");
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                ApplicationArea = All;
                Caption = 'Back';
                ToolTip = 'Back';
                Enabled = IsBackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    BackAction();
                end;
            }
            action(Next)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                ToolTip = 'Next';
                Enabled = IsNextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    NextAction();
                end;
            }
            action(Finish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                ToolTip = 'Finish';
                Enabled = IsFinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TempRecPreviousQltyManagementSetup: Record "Qlty. Management Setup" temporary;
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesDone: Record "Media Resources";
        MediaResourcesStandard: Record "Media Resources";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CurrentStepCounter: Integer;
        IsBackEnabled: Boolean;
        IsNextEnabled: Boolean;
        IsFinishEnabled: Boolean;
        IsMovingForward: Boolean;
        WhatForProduction: Boolean;
        WhatForReceiving: Boolean;
        WhatForSomethingElse: Boolean;
        ProductionCreateInspectionsAutomatically: Boolean;
        ProductionCreateInspectionsManually: Boolean;
        ReceiveCreateInspectionsAutomaticallyTransfer: Boolean;
        ReceiveCreateInspectionsAutomaticallyPurchase: Boolean;
        ReceiveCreateInspectionsAutomaticallySalesReturn: Boolean;
        ReceiveCreateInspectionsAutomaticallyWarehouseReceipt: Boolean;
        ReceiveCreateInspectionsManually: Boolean;
        ShowHTMLHeader: Boolean;
        IsPremiumExperienceEnabled: Boolean;
        TopBannerVisible: Boolean;
        StepWelcome: Integer;
        StepDemoData: Integer;
        StepReceivingConfig: Integer;
        StepWhatAreYouMakingQltyInspectionsFor: Integer;
        StepProductionConfig: Integer;
        StepDone: Integer;
        MaxStep: Integer;
        ReRunThisWizardWithMorePermissionErr: Label 'It looks like you need more permissions to run this wizard successfully. Please ask your Business Central administrator to grant more permission.';
        FinishWizardLbl: Label 'Finish wizard.', Locked = true;
        QualityManagementTok: Label 'Quality Management', Locked = true;
        QualityInspectionsLbl: Label 'Quality Inspections', Locked = true;
        QualityInspectionGenerationRulesLbl: Label 'Quality Inspection Generation Rules', Locked = true;

    trigger OnInit();
    begin
        LoadTopBanners();
        ShowHTMLHeader := true;
        CopyPreviousSetup();

        StepWelcome := 1;
        StepDemoData := 2;
        StepWhatAreYouMakingQltyInspectionsFor := 3;
        StepProductionConfig := 4;
        StepReceivingConfig := 5;
        StepDone := 6;

        MaxStep := StepDone;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            FeatureTelemetry.LogUptake('0000QIB', QualityManagementTok, Enum::"Feature Uptake Status"::"Set up");
            exit(true);
        end;
    end;

    local procedure CopyPreviousSetup()
    begin
        GetLatestSetupRecord(false, false);
        TempRecPreviousQltyManagementSetup := QltyManagementSetup;
    end;

    trigger OnOpenPage();
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsPremiumExperienceEnabled := ApplicationAreaMgmtFacade.IsManufacturingEnabled();
        FeatureTelemetry.LogUptake('0000QIC', QualityManagementTok, Enum::"Feature Uptake Status"::Discovered);
        ChangeToStep(StepWelcome);
        Commit();
    end;

    local procedure ChangeToStep(Step: Integer);
    begin
        if Step < 1 then
            Step := 1;

        if Step > MaxStep then
            Step := MaxStep;

        IsMovingForward := Step > CurrentStepCounter;

        if IsMovingForward then
            LeavingStepMovingForward(CurrentStepCounter, Step);

        ShowHTMLHeader := (Step = StepWelcome) or (Step = StepDone);

        case Step of
            StepWelcome:
                begin
                    IsBackEnabled := false;
                    IsNextEnabled := true;
                    IsFinishEnabled := false;
                    Commit();

                    QltyAutoConfigure.EnsureBasicSetupExists(false);
                end;
            StepWhatAreYouMakingQltyInspectionsFor:
                begin
                    IsBackEnabled := true;
                    IsNextEnabled := true;
                    IsFinishEnabled := false;
                end;
            StepProductionConfig:
                begin
                    IsBackEnabled := true;
                    IsNextEnabled := true;
                    IsFinishEnabled := false;
                end;
            StepReceivingConfig:
                begin
                    IsBackEnabled := true;
                    IsNextEnabled := true;
                    IsFinishEnabled := false;
                end;
            StepDone:
                begin
                    IsBackEnabled := true;
                    IsNextEnabled := false;
                    IsFinishEnabled := true;
                end;
        end;

        CurrentStepCounter := Step;

        CurrPage.Update(true);
    end;

    local procedure LeavingStepMovingForward(LeavingThisStep: Integer; var MovingToThisStep: Integer);
    begin
        case LeavingThisStep of
            StepWelcome:
                Commit();
            StepDemoData:
                begin
                    GetLatestSetupRecord(true, true);
                    Commit();
                    GetLatestSetupRecord(false, true);
                end;
            StepWhatAreYouMakingQltyInspectionsFor:
                case true of
                    WhatForProduction:
                        MovingToThisStep := StepProductionConfig;
                    WhatForReceiving:
                        MovingToThisStep := StepReceivingConfig;
                    else
                        MovingToThisStep := StepDone;
                end;
            StepProductionConfig:
                case true of
                    WhatForReceiving:
                        MovingToThisStep := StepReceivingConfig;
                    else
                        MovingToThisStep := StepDone;
                end;
        end;
    end;

    local procedure BackAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter - 1);
    end;

    local procedure NextAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter + 1);
    end;

    local procedure FinishAction();
    var
        GuidedExperience: Codeunit "Guided Experience";
        EnvironmentInformation: Codeunit "Environment Information";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Qlty. Management Setup Wizard");
        CustomDimensions.Add('RegDetail5', EnvironmentInformation.GetEnvironmentName());
        CustomDimensions.Add('RegDetail6', CompanyName());

        LogMessage('QMUSG001', FinishWizardLbl, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::All, CustomDimensions);

        GetLatestSetupRecord(false, true);

        if WhatForProduction then begin
            case true of
                ProductionCreateInspectionsManually:
                    QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
                ProductionCreateInspectionsAutomatically:
                    QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::OnProductionOutputPost;
            end;

            QltyAutoConfigure.EnsureBasicSetupExists(false);
        end;

        if WhatForReceiving then begin
            case true of
                ReceiveCreateInspectionsAutomaticallyTransfer and (QltyManagementSetup."Transfer Order Trigger" = QltyManagementSetup."Transfer Order Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Order Trigger", QltyManagementSetup."Transfer Order Trigger"::OnTransferOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallyTransfer) and (QltyManagementSetup."Transfer Order Trigger" <> QltyManagementSetup."Transfer Order Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Order Trigger", QltyManagementSetup."Transfer Order Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallyPurchase and (QltyManagementSetup."Purchase Order Trigger" = QltyManagementSetup."Purchase Order Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Order Trigger", QltyManagementSetup."Purchase Order Trigger"::OnPurchaseOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallyPurchase) and (QltyManagementSetup."Purchase Order Trigger" <> QltyManagementSetup."Purchase Order Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Order Trigger", QltyManagementSetup."Purchase Order Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallyWarehouseReceipt and (QltyManagementSetup."Warehouse Receipt Trigger" = QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receipt Trigger", QltyManagementSetup."Warehouse Receipt Trigger"::OnWarehouseReceiptPost);
                (not ReceiveCreateInspectionsAutomaticallyWarehouseReceipt) and (QltyManagementSetup."Warehouse Receipt Trigger" <> QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receipt Trigger", QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallySalesReturn and (QltyManagementSetup."Sales Return Trigger" = QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallySalesReturn) and (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            end;
        end;

        QltyNotificationMgmt.EnsureDefaultNotifications();

        if QltyManagementSetup.Visibility = QltyManagementSetup.Visibility::Hide then
            QltyManagementSetup.Validate(Visibility, QltyManagementSetup.Visibility::Show);

        QltyManagementSetup.Modify();
        Commit();

        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
        CurrPage.Close();
    end;

    local procedure GetLatestSetupRecord(ResetWizardPageVariables: Boolean; CreateSetupRecordIfNotCreatedYet: Boolean)
    begin
        if not QltyManagementSetup.Get() then
            if CreateSetupRecordIfNotCreatedYet then begin
                QltyManagementSetup.Init();
                if not QltyManagementSetup.Insert() then
                    Error(ReRunThisWizardWithMorePermissionErr);
            end;

        if ResetWizardPageVariables then begin
            WhatForProduction := (QltyManagementSetup."Production Order Trigger" <> QltyManagementSetup."Production Order Trigger"::NoTrigger);

            WhatForReceiving := (QltyManagementSetup."Purchase Order Trigger" <> QltyManagementSetup."Purchase Order Trigger"::NoTrigger) or
                (QltyManagementSetup."Warehouse Receipt Trigger" <> QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger) or
                (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger) or
                (QltyManagementSetup."Transfer Order Trigger" <> QltyManagementSetup."Transfer Order Trigger"::NoTrigger);

            ProductionCreateInspectionsAutomatically := QltyManagementSetup."Production Order Trigger" <> QltyManagementSetup."Production Order Trigger"::NoTrigger;
            ProductionCreateInspectionsManually := not ProductionCreateInspectionsAutomatically;

            ReceiveCreateInspectionsAutomaticallyPurchase := (QltyManagementSetup."Purchase Order Trigger" <> QltyManagementSetup."Purchase Order Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallyWarehouseReceipt := (QltyManagementSetup."Warehouse Receipt Trigger" <> QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallySalesReturn := (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallyTransfer := (QltyManagementSetup."Transfer Order Trigger" <> QltyManagementSetup."Transfer Order Trigger"::NoTrigger);

            ReceiveCreateInspectionsManually := not (ReceiveCreateInspectionsAutomaticallyPurchase or
                ReceiveCreateInspectionsAutomaticallyTransfer or
                ReceiveCreateInspectionsAutomaticallyWarehouseReceipt or
                ReceiveCreateInspectionsAutomaticallySalesReturn);

        end
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png',
           Format(CurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png',
           Format(CurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue();
    end;
}