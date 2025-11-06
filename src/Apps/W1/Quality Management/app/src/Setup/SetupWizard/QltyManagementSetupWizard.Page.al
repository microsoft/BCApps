// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupWizard;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Setup.Setup;
using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;

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
            group(SettingsFor_StepWhatAreYouMakingQITestsFor)
            {
                Caption = 'Where do you plan on using Quality Inspection Tests?';
                Visible = (StepWhatAreYouMakingQITestsFor = CurrentStepCounter);
                InstructionalText = 'Where do you plan on using Quality Inspection Tests?';

                // TODO: Decouple Manufacturing dependency
                group(SettingsFor_WhatFor_ProductionOutput)
                {
                    Caption = 'Production';
                    InstructionalText = 'I want to create tests when recording production output. The most common scenarios are when inventory is posted from the output journal, but it could also be for intermediate steps or other triggers.';

                    field(ChooseWhatFor_ProductionOutput; WhatForProduction)
                    {
                        ApplicationArea = Manufacturing;
                        ShowCaption = false;
                        Caption = 'I want to create tests when recording production output.';
                        ToolTip = 'I want to create tests when recording production output. The most common scenarios are when inventory is posted from the output journal, but it could also be for intermediate steps or other triggers.';
                    }
                }

                group(SettingsFor_WhatFor_Receiving)
                {
                    Caption = 'Receiving';
                    InstructionalText = 'I want to create tests when receiving inventory.';

                    field(ChooseWhatFor_Receiving; WhatForReceiving)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want to create tests when receiving inventory.';
                        ToolTip = 'I want to create tests when receiving inventory.';
                    }
                }
                group(SettingsFor_WhatFor_SomethingElse)
                {
                    Caption = 'Something Else';
                    InstructionalText = 'You can use Quality Management to create manual tests for effectively any table. Use this option if you want to create tests in other areas, or if you want to manually configure this later.';

                    field(ChooseWhatFor_SomethingElse; WhatForSomethingElse)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want to create tests for something different.';
                        ToolTip = 'I want to create tests for something different.';
                    }
                }
            }
            // TODO: Decouple Manufacturing dependency
            group(SettingsFor_StepProductionConfig)
            {
                Caption = 'Production Test Configuration';
                Visible = (StepProductionConfig = CurrentStepCounter);
                InstructionalText = 'In production scenarios, how do you want to make the tests?';

                group(SettingsFor_Production_Production_CreateTestsAutomatically)
                {
                    Caption = 'I want tests created automatically when output is recorded.';
                    InstructionalText = 'Creating a test automatically when output is recorded means that as output is recorded, the system will make tests for you. Use this option when tests must exist when production is output. Do not use this option if your process requires that the Quality Management users make the tests.';

                    field(ChooseProduction_Production_CreateTestsAutomatically; ProductionCreateTestsAutomatically)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want tests created automatically when output is recorded.';
                        ToolTip = 'Creating a test automatically when output is recorded means that as output is recorded, the system will make tests for you. Use this option when tests must exist when production is output. Do not use this option if your process requires that the Quality Management users make the tests.';

                        trigger OnValidate()
                        begin
                            ProductionCreateTestsManually := not ProductionCreateTestsAutomatically;
                        end;
                    }
                }
                group(SettingsFor_Production_Production_CreateTestsManually)
                {
                    Caption = 'I want a person to make a test.';
                    InstructionalText = 'In this scenario a person is manually creating tests by clicking a button. Use this option when your process requires a person to create a test, or are performing ad-hoc tests. Examples could be creating tests for Non Conformance Reports, or to track re-work, or to track damage.';

                    field(ChooseProduction_Production_CreateTestsManually; ProductionCreateTestsManually)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I want an inspector or another person to make a test.';
                        ToolTip = 'In this scenario a person is manually creating tests by clicking a button. Use this option when your process requires a person to create a test, or are performing ad-hoc tests. Examples could be creating tests for Non Conformance Reports, or to track re-work, or to track damage.';

                        trigger OnValidate()
                        begin
                            ProductionCreateTestsAutomatically := not ProductionCreateTestsManually;
                        end;
                    }
                }
            }
            group(SettingsFor_StepReceivingConfig)
            {
                Caption = 'Receiving Test Configuration';
                Visible = (StepReceivingConfig = CurrentStepCounter);
                InstructionalText = 'In receiving scenarios, how do you want to make the tests?';

                field(ChooseAutomaticallyCreateTestPurchase; ReceiveCreateTestsAutomaticallyPurchase)
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Receipts';
                    ToolTip = 'Specifies that a test will be automatically created when product is received via a purchase order.';
                }
                field(ChooseAutomaticallyCreateTestTransfer; ReceiveCreateTestsAutomaticallyTransfer)
                {
                    ApplicationArea = All;
                    Caption = 'Transfer Receipts';
                    ToolTip = 'Specifies that a test will be automatically created when product is received via a transfer order.';
                }
                field(ChooseAutomaticallyCreateTestWarehouseReceipt; ReceiveCreateTestsAutomaticallyWarehouseReceipt)
                {
                    ApplicationArea = All;
                    Caption = 'Warehouse Receipts';
                    ToolTip = 'Specifies that a test will be automatically created when product is received via a warehouse receipt.';
                }
                field(ChooseAutomaticallyCreateTestSalesReturn; ReceiveCreateTestsAutomaticallySalesReturn)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Return Receipts';
                    ToolTip = 'Specifies that a test will be automatically created when product is received via a sales return.';
                }
                group(SettingsFor__Receive_CreateTestsManually)
                {
                    Caption = 'I only want people to make tests.';
                    InstructionalText = 'In this scenario a person is manually creating tests by clicking a button. Use this option when your process requires a person to create a test, or are performing ad-hoc tests. Examples could be creating tests for Non Conformance Reports, or to track damage for goods or material received.';

                    field(ChooseReceive_CreateTestsManually; ReceiveCreateTestsManually)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'I only want people to make tests.';
                        ToolTip = 'In this scenario a person is manually creating tests by clicking a button. Use this option when your process requires a person to create a test, or are performing ad-hoc tests. Examples could be creating tests for Non Conformance Reports, or to track damage for goods or material received.';

                        trigger OnValidate()
                        begin
                            if ReceiveCreateTestsManually then begin
                                ReceiveCreateTestsAutomaticallyPurchase := false;
                                ReceiveCreateTestsAutomaticallyTransfer := false;
                                ReceiveCreateTestsAutomaticallySalesReturn := false;
                                ReceiveCreateTestsAutomaticallyWarehouseReceipt := false;
                            end else
                                ReceiveCreateTestsAutomaticallyPurchase := true;
                        end;
                    }
                }
            }
            group(SettingsFor_StepShowTests_detectAuto)
            {
                Caption = 'Show Automatic Tests?';
                Visible = (StepShowTests = CurrentStepCounter) and (
                    // TODO: Decouple Manufacturing dependency
                    //ProductionCreateTestsAutomatically or
                    ReceiveCreateTestsAutomaticallyPurchase or
                    ReceiveCreateTestsAutomaticallyTransfer or
                    ReceiveCreateTestsAutomaticallyWarehouseReceipt or
                    ReceiveCreateTestsAutomaticallySalesReturn);
                InstructionalText = 'When tests are created automatically, should the test immediately show?';

                group(SettingsFor_detectAuto__Show_AutoAndManual)
                {
                    Caption = 'Yes';
                    InstructionalText = 'Yes, because the person doing the activity (such as posting) is also the person collecting the test results. Activities that trigger a test without direct interaction in Business Central, such as background posting or through a web service integration such as Power Automate will still create a test but it will not immediately be shown.';

                    field(ChoosedetectAuto_Show_AutoAndManual; ShowAutoAndManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Yes';
                        ToolTip = 'Yes, because the person doing the activity (such as posting) is also the person collecting the test results. Activities that trigger a test without direct interaction in Business Central, such as background posting or through a web service integration such as Power Automate will still create a test but it will not immediately be shown.';

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
                    InstructionalText = 'No, because the person doing the activity is not the person collecting the test results. Just make the test and do not show it.';

                    field(ChoosedetectAuto_Show_OnlyManual; ShowOnlyManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'No';
                        ToolTip = 'No, because the person doing the activity is not the person collecting the test results. Just make the test and do not show it.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowOnlyManual;
                            ShowNever := not ShowOnlyManual;
                        end;
                    }
                }
                group(SettingsFor_detectAuto__Show_Never)
                {
                    Caption = 'No, not even manually created tests.';
                    InstructionalText = 'No, not even tests created by clicking a button. The person creating the test is not involved in completing the test.';

                    field(ChoosedetectAuto_Show_Never; ShowNever)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'No, not even manually created tests.';
                        ToolTip = 'No, not even tests created by clicking a button. The person creating the test is not involved in completing the test.';

                        trigger OnValidate()
                        begin
                            ShowAutoAndManual := not ShowNever;
                            ShowOnlyManual := not ShowNever;
                        end;
                    }
                }
            }
            group(SettingsFor_StepShowTests_detectManualOnly)
            {
                Caption = 'Show Tests As They Are Created';
                Visible = (StepShowTests = CurrentStepCounter) and not
                    // TODO: Decouple Manufacturing dependency
                    (ProductionCreateTestsAutomatically or
                    ReceiveCreateTestsAutomaticallyPurchase or
                    ReceiveCreateTestsAutomaticallyTransfer or
                    ReceiveCreateTestsAutomaticallyWarehouseReceipt or
                    ReceiveCreateTestsAutomaticallySalesReturn);
                InstructionalText = 'When tests are created, should they show up immediately?';

                group(SettingsFor__Show_AutoAndManual)
                {
                    Caption = 'Show Automatic and Manually Created Tests';
                    InstructionalText = 'Use this when you want a test shown to the person who triggered the test. For example if you are creating tests automatically when posting then the test would show to the person who posted. Do not use this option if the person doing the activity triggering the test is not the person recording the data.';

                    field(ChooseShow_AutoAndManual; ShowAutoAndManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Show Automatic and Manually Created Tests';
                        ToolTip = 'Use this when you want a test shown to the person who triggered the test. For example if you are creating tests automatically when posting then the test would show to the person who posted. Do not use this option if the person doing the activity triggering the test is not the person recording the data.';

                        trigger OnValidate()
                        begin
                            ShowOnlyManual := not ShowAutoAndManual;
                            ShowNever := not ShowAutoAndManual;
                        end;
                    }
                }
                group(SettingsFor__Show_OnlyManual)
                {
                    Caption = 'Only Manually Created Tests';
                    InstructionalText = 'Use this when you want tests that were created automatically to not show up immediately. If someone presses a button to create a test to make sure that those show up.';

                    field(ChooseShow_OnlyManual; ShowOnlyManual)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Caption = 'Only Manually Created Tests';
                        ToolTip = 'Use this when you want tests that were created automatically to not show up immediately, however if someone presses a button to create a test to make sure that those show up.';

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
                    InstructionalText = 'Use this to always make resulting tests hidden. Use this when other people need to trigger tests but should not be editing them. ';

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
                    ShowCaption = false;
                    Visible = ShowHTMLHeader;
                    InstructionalText = 'Thank you for installing Quality Inspections. Get started by navigating to Quality Inspection Templates and Test Generation Rules.';
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
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CurrentStepCounter: Integer;
        IsBackEnabled: Boolean;
        IsNextEnabled: Boolean;
        IsFinishEnabled: Boolean;
        IsMovingForward: Boolean;
        // TODO: Decouple Manufacturing dependency - FIXED
        WhatForProduction: Boolean;
        WhatForReceiving: Boolean;
        WhatForSomethingElse: Boolean;
        // TODO: Decouple Manufacturing dependency - FIXED
        ProductionCreateTestsAutomatically: Boolean;
        ProductionCreateTestsManually: Boolean;
        ReceiveCreateTestsAutomaticallyTransfer: Boolean;
        ReceiveCreateTestsAutomaticallyPurchase: Boolean;
        ReceiveCreateTestsAutomaticallySalesReturn: Boolean;
        ReceiveCreateTestsAutomaticallyWarehouseReceipt: Boolean;
        ReceiveCreateTestsManually: Boolean;
        ShowAutoAndManual: Boolean;
        ShowOnlyManual: Boolean;
        ShowNever: Boolean;
        ShowHTMLHeader: Boolean;
        StepWelcome: Integer;
        StepGettingStarted: Integer;
        StepReceivingConfig: Integer;
        StepWhatAreYouMakingQITestsFor: Integer;
        StepProductionConfig: Integer;
        StepShowTests: Integer;
        StepDone: Integer;
        MaxStep: Integer;
        ApplyConfigurationPackage: Option "Apply Getting Started Data","Do Not Apply Configuration.";
        ReRunThisWizardWithMorePermissionErr: Label 'It looks like you need more permissions to run this wizard successfully. Please ask your Business Central administrator to grant more permission.';
        FinishWizardLbl: Label 'Finish wizard.', Locked = true;
        QualityManagementTok: Label 'Quality Management', Locked = true;

    trigger OnInit();
    begin
        ShowHTMLHeader := true;
        CopyPreviousSetup();

        StepWelcome := 1;
        StepGettingStarted := 2;
        StepWhatAreYouMakingQITestsFor := 3;
        StepProductionConfig := 4;
        StepReceivingConfig := 5;
        StepShowTests := 6;
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
    begin
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

                    QltyAutoConfigure.EnsureBasicSetup(false);
                    if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Qlty. Management Setup Wizard") or
                       QltyAutoConfigure.GuessDoesAppearToBeSetup() or
                       QltyAutoConfigure.GuessDoesAppearToBeUsed()
                    then
                        ApplyConfigurationPackage := ApplyConfigurationPackage::"Do Not Apply Configuration."
                    else
                        ApplyConfigurationPackage := ApplyConfigurationPackage::"Apply Getting Started Data";
                end;
            StepWhatAreYouMakingQITestsFor:
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
            StepShowTests:
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
            StepWhatAreYouMakingQITestsFor:
                case true of
                    // TODO: Decouple Manufacturing dependency
                    WhatForProduction:
                        MovingToThisStep := StepProductionConfig;
                    WhatForReceiving:
                        MovingToThisStep := StepReceivingConfig;
                    else
                        MovingToThisStep := StepShowTests;
                end;
            StepProductionConfig:
                case true of
                    WhatForReceiving:
                        MovingToThisStep := StepReceivingConfig;
                    else
                        MovingToThisStep := StepShowTests;
                end;
        end;
        OnAfterLeavingStepMovingForward(LeavingThisStep, MovingToThisStep);
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

        // TODO: Decouple Manufacturing dependency
        if WhatForProduction then begin
            case true of
                ProductionCreateTestsManually:
                    QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
                ProductionCreateTestsAutomatically:
                    QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOutputPost;
            end;

            QltyAutoConfigure.EnsureBasicSetup(false);
        end;

        if WhatForReceiving then begin
            case true of
                ReceiveCreateTestsAutomaticallyTransfer and (QltyManagementSetup."Transfer Trigger" = QltyManagementSetup."Transfer Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::OnTransferOrderPostReceive);
                (not ReceiveCreateTestsAutomaticallyTransfer) and (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateTestsAutomaticallyPurchase and (QltyManagementSetup."Purchase Trigger" = QltyManagementSetup."Purchase Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::OnPurchaseOrderPostReceive);
                (not ReceiveCreateTestsAutomaticallyPurchase) and (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateTestsAutomaticallyWarehouseReceipt and (QltyManagementSetup."Warehouse Receive Trigger" = QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
                (not ReceiveCreateTestsAutomaticallyWarehouseReceipt) and (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger);
            end;

            case true of
                ReceiveCreateTestsAutomaticallySalesReturn and (QltyManagementSetup."Sales Return Trigger" = QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
                (not ReceiveCreateTestsAutomaticallySalesReturn) and (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger):
                    QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            end;
        end;

        case true of
            ShowAutoAndManual:
                QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests";
            ShowOnlyManual:
                QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Only manually created tests";
            ShowNever:
                QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Do not show created tests";
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
            // TODO: Decouple Manufacturing dependency
            WhatForProduction := (QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger);

            WhatForReceiving := (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger) or
                (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger) or
                (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger) or
                (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger);

            // TODO: Decouple Manufacturing dependency
            ProductionCreateTestsAutomatically := QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger;
            ProductionCreateTestsManually := not ProductionCreateTestsAutomatically;
            ReceiveCreateTestsAutomaticallyPurchase := (QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger);
            ReceiveCreateTestsAutomaticallyWarehouseReceipt := (QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger);
            ReceiveCreateTestsAutomaticallySalesReturn := (QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger);
            ReceiveCreateTestsAutomaticallyTransfer := (QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger);

            ReceiveCreateTestsManually := not (ReceiveCreateTestsAutomaticallyPurchase or
                ReceiveCreateTestsAutomaticallyTransfer or
                ReceiveCreateTestsAutomaticallyWarehouseReceipt or
                ReceiveCreateTestsAutomaticallySalesReturn);

            ShowAutoAndManual := QltyManagementSetup."Show Test Behavior" = QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests";
            ShowOnlyManual := QltyManagementSetup."Show Test Behavior" = QltyManagementSetup."Show Test Behavior"::"Only manually created tests";
            ShowNever := QltyManagementSetup."Show Test Behavior" = QltyManagementSetup."Show Test Behavior"::"Do not show created tests";
        end
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterLeavingStepMovingForward(LeavingThisStep: Integer; var MovingToThisStep: Integer)
    begin
    end;
}
