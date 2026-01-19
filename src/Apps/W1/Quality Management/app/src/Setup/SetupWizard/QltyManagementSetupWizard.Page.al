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
            group(SettingsFor_StepGettingStarted)
            {
                Caption = 'Apply Getting Started Data?';
                Visible = (StepGettingStarted = CurrentStepCounter);
                InstructionalText = 'Would you like to apply getting started data?';

                group(SettingsFor_ApplyConfigurationPackage)
                {
                    Caption = 'What Is Getting Started Data?';
                    InstructionalText = 'Getting started data for Quality Management will include basic setup data and also some useful examples or other demonstration data. Getting Started data can help you get running quickly, or help you with evaluating if the application is a fit more quickly. Very basic setup data for common integration scenarios will still be applied if you choose not to apply the getting started data. If you do not want this data, or if you have been previously set up then do not apply this configuration.';

                    field(ChooseApplyConfigurationPackage; ApplyConfigurationPackage)
                    {
                        ApplicationArea = Basic, Suite;
                        OptionCaption = 'Apply Getting Started Data,Do Not Apply Configuration';
                        Caption = 'Getting Started Data?';
                        ShowCaption = false;
                        ToolTip = 'Specifies a configuration package of getting-started data is available to automatically apply.';
                    }
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
            group(SettingsFor_StepShowInspections_detectAuto)
            {
                Caption = 'Show Automatic Inspections?';
                Visible = (StepShowInspections = CurrentStepCounter) and (
                    ProductionCreateInspectionsAutomatically or
                    ReceiveCreateInspectionsAutomaticallyPurchase or
                    ReceiveCreateInspectionsAutomaticallyTransfer or
                    ReceiveCreateInspectionsAutomaticallyWarehouseReceipt or
                    ReceiveCreateInspectionsAutomaticallySalesReturn);
                InstructionalText = 'When inspections are created automatically, should the inspection immediately show?';

                group(SettingsFor_detectAuto__Show_AutoAndManual)
                {
                    Caption = 'Yes';
                    InstructionalText = 'Yes, because the person doing the activity (such as posting) is also the person collecting the inspection results. Activities that trigger an inspection without direct interaction in Business Central, such as background posting or through a web service integration such as Power Automate will still create an inspection but it will not immediately be shown.';

                    field(ChoosedetectAuto_Show_AutoAndManual; ShowAutoAndManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Yes';
                        ToolTip = 'Yes, because the person doing the activity (such as posting) is also the person collecting the inspection results. Activities that trigger an inspection without direct interaction in Business Central, such as background posting or through a web service integration such as Power Automate will still create an inspection but it will not immediately be shown.';

                        trigger OnValidate()
                        begin
                            ShowOnlyManual := not ShowAutoAndManual;
                            ShowNever := not ShowAutoAndManual;
                        end;
                    }
                }
                group(SettingsFor_detectAuto__Show_OnlyManual)
                {
                    Caption = 'No';
                    InstructionalText = 'No, because the person doing the activity is not the person collecting the inspection results. Just make the inspection and do not show it.';

                    field(ChoosedetectAuto_Show_OnlyManual; ShowOnlyManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'No';
                        ToolTip = 'No, because the person doing the activity is not the person collecting the inspection results. Just make the inspection and do not show it.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowOnlyManual;
                            ShowNever := not ShowOnlyManual;
                        end;
                    }
                }
                group(SettingsFor_detectAuto__Show_Never)
                {
                    Caption = 'No, not even manually created inspections.';
                    InstructionalText = 'No, not even inspections created by clicking a button. The person creating the inspection is not involved in completing the inspection.';

                    field(ChoosedetectAuto_Show_Never; ShowNever)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'No, not even manually created inspections.';
                        ToolTip = 'No, not even inspections created by clicking a button. The person creating the inspection is not involved in completing the inspection.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowNever;
                            ShowOnlyManual := not ShowNever;
                        end;
                    }
                }
            }
            group(SettingsFor_StepShowInspections_DetectManualOnly)
            {
                Caption = 'Show Inspections As They Are Created';
                Visible = (StepShowInspections = CurrentStepCounter) and not
                    (ProductionCreateInspectionsAutomatically or
                    ReceiveCreateInspectionsAutomaticallyPurchase or
                    ReceiveCreateInspectionsAutomaticallyTransfer or
                    ReceiveCreateInspectionsAutomaticallyWarehouseReceipt or
                    ReceiveCreateInspectionsAutomaticallySalesReturn);
                InstructionalText = 'When inspections are created, should they show up immediately?';

                group(SettingsFor__Show_AutoAndManual)
                {
                    Caption = 'Show Automatic and manually created inspections';
                    InstructionalText = 'Use this when you want an inspection shown to the person who triggered the inspection. For example if you are creating inspections automatically when posting then the inspection would show to the person who posted. Do not use this option if the person doing the activity triggering the inspection is not the person recording the data.';

                    field(ChooseShow_AutoAndManual; ShowAutoAndManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Show Automatic and manually created inspections';
                        ToolTip = 'Use this when you want an inspection shown to the person who triggered the inspection. For example if you are creating inspections automatically when posting then the inspection would show to the person who posted. Do not use this option if the person doing the activity triggering the inspection is not the person recording the data.';

                        trigger OnValidate()
                        begin
                            ShowOnlyManual := not ShowAutoAndManual;
                            ShowNever := not ShowAutoAndManual;
                        end;
                    }
                }
                group(SettingsFor__Show_OnlyManual)
                {
                    Caption = 'Only manually created inspections';
                    InstructionalText = 'Use this when you want inspections that were created automatically to not show up immediately. If someone presses a button to create an inspection to make sure that those show up.';

                    field(ChooseShow_OnlyManual; ShowOnlyManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Only manually created inspections';
                        ToolTip = 'Use this when you want inspections that were created automatically to not show up immediately, however if someone presses a button to create an inspection to make sure that those show up.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowOnlyManual;
                            ShowNever := not ShowOnlyManual;
                        end;
                    }
                }
                group(SettingsFor__Show_Never)
                {
                    Caption = 'Never';
                    InstructionalText = 'Use this to always make resulting inspections hidden. Use this when other people need to trigger inspections but should not be editing them.';

                    field(ChooseShow_Never; ShowNever)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Never immediately show.';
                        ToolTip = 'Never immediately show.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowNever;
                            ShowOnlyManual := not ShowNever;
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
        ShowAutoAndManual: Boolean;
        ShowOnlyManual: Boolean;
        ShowNever: Boolean;
        ShowHTMLHeader: Boolean;
        IsPremiumExperienceEnabled: Boolean;
        TopBannerVisible: Boolean;
        StepWelcome: Integer;
        StepGettingStarted: Integer;
        StepReceivingConfig: Integer;
        StepWhatAreYouMakingQltyInspectionsFor: Integer;
        StepProductionConfig: Integer;
        StepShowInspections: Integer;
        StepDone: Integer;
        MaxStep: Integer;
        ApplyConfigurationPackage: Option "Apply Getting Started Data","Do Not Apply Configuration.";
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
        StepGettingStarted := 2;
        StepWhatAreYouMakingQltyInspectionsFor := 3;
        StepProductionConfig := 4;
        StepReceivingConfig := 5;
        StepShowInspections := 6;
        StepDone := 7;

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
    var
        GuidedExperience: Codeunit "Guided Experience";
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
                    if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Qlty. Management Setup Wizard") or
                       QltyAutoConfigure.GuessDoesAppearToBeSetup() or
                       QltyAutoConfigure.GuessDoesAppearToBeUsed()
                    then
                        ApplyConfigurationPackage := ApplyConfigurationPackage::"Do Not Apply Configuration."
                    else
                        ApplyConfigurationPackage := ApplyConfigurationPackage::"Apply Getting Started Data";
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
            StepShowInspections:
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
            StepGettingStarted:
                begin
                    GetLatestSetupRecord(true, true);
                    if ApplyConfigurationPackage = ApplyConfigurationPackage::"Apply Getting Started Data" then begin
                        QltyAutoConfigure.ApplyGettingStartedData(true);
                        Commit();
                    end;
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
                        MovingToThisStep := StepShowInspections;
                end;
            StepProductionConfig:
                case true of
                    WhatForReceiving:
                        MovingToThisStep := StepReceivingConfig;
                    else
                        MovingToThisStep := StepShowInspections;
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
        CustomDimensions: Dictionary of [Text, Text];
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Qlty. Management Setup Wizard");
        CustomDimensions.Add('RegDetail5', EnvironmentInformation.GetEnvironmentName());
        CustomDimensions.Add('RegDetail6', CompanyName());
        CustomDimensions.Add('RegDetail7', UserId());

        LogMessage('QMUSG001', FinishWizardLbl, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::All, CustomDimensions);

        GetLatestSetupRecord(false, true);

        if WhatForProduction then begin
            case true of
                ProductionCreateInspectionsManually:
                    QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
                ProductionCreateInspectionsAutomatically:
                    QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOutputPost;
            end;

            QltyAutoConfigure.EnsureBasicSetupExists(false);
        end;

        if WhatForReceiving then begin
            case true of
                ReceiveCreateInspectionsAutomaticallyTransfer and (QltyManagementSetup."Transfer Trigger" = QltyManagementSetup."Transfer Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::OnTransferOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallyTransfer) and (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallyPurchase and (QltyManagementSetup."Purchase Trigger" = QltyManagementSetup."Purchase Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::OnPurchaseOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallyPurchase) and (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallyWarehouseReceipt and (QltyManagementSetup."Warehouse Receive Trigger" = QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
                (not ReceiveCreateInspectionsAutomaticallyWarehouseReceipt) and (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateInspectionsAutomaticallySalesReturn and (QltyManagementSetup."Sales Return Trigger" = QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
                (not ReceiveCreateInspectionsAutomaticallySalesReturn) and (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            end;
        end;

        case true of
            ShowAutoAndManual:
                QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Automatic and manually created inspections";
            ShowOnlyManual:
                QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Only manually created inspections";
            ShowNever:
                QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Do not show created inspections";
        end;

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
            WhatForProduction := (QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger);

            WhatForReceiving := (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger) or
                (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger) or
                (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger) or
                (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger);

            ProductionCreateInspectionsAutomatically := QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger;
            ProductionCreateInspectionsManually := not ProductionCreateInspectionsAutomatically;

            ReceiveCreateInspectionsAutomaticallyPurchase := (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallyWarehouseReceipt := (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallySalesReturn := (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            ReceiveCreateInspectionsAutomaticallyTransfer := (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger);

            ReceiveCreateInspectionsManually := not (ReceiveCreateInspectionsAutomaticallyPurchase or
                ReceiveCreateInspectionsAutomaticallyTransfer or
                ReceiveCreateInspectionsAutomaticallyWarehouseReceipt or
                ReceiveCreateInspectionsAutomaticallySalesReturn);

            ShowAutoAndManual := QltyManagementSetup."Show Inspection Behavior" = QltyManagementSetup."Show Inspection Behavior"::"Automatic and manually created inspections";
            ShowOnlyManual := QltyManagementSetup."Show Inspection Behavior" = QltyManagementSetup."Show Inspection Behavior"::"Only manually created inspections";
            ShowNever := QltyManagementSetup."Show Inspection Behavior" = QltyManagementSetup."Show Inspection Behavior"::"Do not show created inspections";
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
