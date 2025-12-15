// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;

page 20462 "Qlty. Prod. Gen. Rule Wizard"
{
    Caption = 'Quality Management - Production and Assembly Quality Test Generation Rule Wizard';
    PageType = NavigatePage;
    UsageCategory = None;
    ApplicationArea = QualityManagement;
    SourceTable = "Qlty. Management Setup";

    layout
    {
        area(Content)
        {
            group(SettingsFor_iStepWhichTemplate)
            {
                Caption = ' ';
                ShowCaption = false;
                Visible = (StepWhichTemplateCounter = CurrentStepCounter);

                group(SettingsFor_iStepWhichTemplate_Instruction1)
                {
                    InstructionalText = 'Define a rule for lot or serial related tests when products are produced.';
                    Caption = ' ';
                    ShowCaption = false;
                }
                group(SettingsFor_iStepWhichTemplate_Instruction2)
                {
                    InstructionalText = 'Which Quality Inspection template do you want to use?';
                    Caption = ' ';
                    ShowCaption = false;
                }
                field(ChoosechooseTemplate; TemplateCode)
                {
                    ApplicationArea = All;
                    Caption = 'Choose Template';
                    ToolTip = 'Specifies which Quality Inspection template do you want to use?';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditQltyInspectionTemplate(TemplateCode);
                    end;
                }
            }
            group(SettingsFor_iStepAssemblyOrProduction)
            {
                Caption = ' ';
                ShowCaption = false;
                Visible = (StepAssemblyOrProductionCounter = CurrentStepCounter);
                InstructionalText = 'Choose whether this is for production orders or assembly orders.';

                field(ChoosechooseProductionOrder; IsProductionOrder)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Orders';
                    ToolTip = 'Specifies to create an inspection generation rule for Production Orders';

                    trigger OnValidate()
                    begin
                        if IsProductionOrder then
                            IsAssemblyOrder := false;
                    end;
                }
                field(ChoosechooseAssemblyOrder; IsAssemblyOrder)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    ToolTip = 'Specifies to create an inspection generation rule for Assembly Orders';

                    trigger OnValidate()
                    begin
                        if IsAssemblyOrder then
                            IsProductionOrder := false;
                    end;
                }
            }
            group(SettingsFor_iStepWhichProdOrderRoutingLine)
            {
                Caption = ' ';
                ShowCaption = false;
                InstructionalText = 'A test should be created for production order routing lines when these filters match. You can choose other fields on the last step.';
                Visible = (StepWhichLineCounter = CurrentStepCounter);

                group(SettingsFor_LocationWrapper)
                {
                    ShowCaption = false;

                    field(ChoosechooseLocation; LocationCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Location';
                        ToolTip = 'Specifies a Location';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditLocation(LocationCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(LocationFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseFromBinCodeFilter; FromBinCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'From Bin';
                        ToolTip = 'Specifies a bin.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditBin(LocationCodeFilter, '', FromBinCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(FromBinFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseToBinFilter; ToBinCodeFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'To Bin';
                        ToolTip = 'Specifies a destination bin.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditBin(LocationCodeFilter, '', ToBinCodeFilter);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(ToBinFilterErr, GetLastErrorText());
                        end;
                    }
                }
                group(SettingsFor_ProdOrderRoutingLineFieldsWrapper)
                {
                    ShowCaption = false;

                    field(ChooseRoutingNoFilter; RoutingNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Routing No.';
                        ToolTip = 'Specifies which Routing?';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditRouting(RoutingNoFilter);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(RoutingNoFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseOperationNo; OperationNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Operation No.';
                        ToolTip = 'Specifies which operation?';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditRoutingOperation(RoutingNoFilter, OperationNo);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(OperationNoErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseWorkCenterNo; WorkCenterNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Work Center No.';
                        ToolTip = 'Specifies a work center.';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditWorkCenter(WorkCenterNo);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(WorkCenterNoErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseSpecificMachineNoFilter; SpecificNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Machine No.';
                        ToolTip = 'Specifies which machine?';

                        trigger OnAssistEdit()
                        begin
                            QltyFilterHelpers.AssistEditMachine(SpecificNoFilter);
                        end;

                        trigger OnValidate()
                        begin
                            if not UpdateFullTextRuleStringsFromFilters() then
                                Error(MachineNoFilterErr, GetLastErrorText());
                        end;
                    }
                    field(ChooseDescriptionPattern; DescriptionPattern)
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description pattern.';

                        trigger OnValidate()
                        begin
                            UpdateFullTextRuleStringsFromFilters();
                        end;
                    }
                }
                field(Chooseadvanced; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        AssistEditFullProdOrderRoutingLineFilter();
                        UpdateTableVariablesFromRecordFilters();
                    end;
                }
            }
            group(SettingsFor_iStepWhichAssemblyOrder)
            {
                ShowCaption = false;
                InstructionalText = 'A test should be created for an assembly order when these filters match. You can choose other fields on the last step.';
                Visible = (StepWhichAssemblyOrderCounter = CurrentStepCounter);

                field(ChoosechooseAssemblyLocation; LocationCodeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Location';
                    ToolTip = 'Specifies a location filter';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditLocation(LocationCodeFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(LocationFilterErr, GetLastErrorText());
                    end;
                }
                field(ToBinCodeFilter; ToBinCodeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'To Bin';
                    ToolTip = 'Specifies a destination bin.';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditBin(LocationCodeFilter, '', ToBinCodeFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ToBinFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseAssemblyDescriptionPattern; DescriptionPattern)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies a filter for description';

                    trigger OnValidate()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                    end;
                }
                field(ChooseadvancedAssembly; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        AssistEditFullPostedAssemblyHeaderFilter();
                        UpdateTableVariablesFromRecordFilters();
                    end;
                }
            }
            group(SettingsFor_iStepWhichItem)
            {
                Caption = ' ';
                ShowCaption = false;
                InstructionalText = 'Does it matter which items? You can optionally limit this to only items that match this criteria.';
                Visible = (StepWhichItemFilterCounter = CurrentStepCounter);

                field(ChooseItemNoFilter; ItemNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Specific Item';
                    ToolTip = 'Specifies a specific Item';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditItemNo(ItemNoFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ItemFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseCategoryCodeFilter; CategoryCodeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Category';
                    ToolTip = 'Specifies a specific Category';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditItemCategory(CategoryCodeFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ItemCategoryFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseInventoryPostingGroupCode; InventoryPostingGroupCode)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Posting Group';
                    ToolTip = 'Specifies a Inventory Posting Group';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditInventoryPostingGroup(InventoryPostingGroupCode);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(InventoryPostingGroupErr, GetLastErrorText());
                    end;
                }
                field(Chooseadvanced_item; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        AssistEditFullItemFilter();
                        UpdateTableVariablesFromRecordFilters();
                    end;
                }
            }
            group(SettingsFor_iStepDone)
            {
                Caption = ' ';
                InstructionalText = '';
                ShowCaption = false;
                Visible = (StepDoneCounter = CurrentStepCounter);

                group(SettingsFor_iStepDone_Instruction1)
                {
                    Caption = ' ';
                    InstructionalText = 'We have an Inspection Generation Rule ready. Click ''Finish'' to save this to the system.';
                    ShowCaption = false;
                }
                group(SettingsFor_iStepDone_Instruction2)
                {
                    Caption = ' ';
                    InstructionalText = 'Please review and set any additional filters you may need, for example if you want to limit this to specific items.';
                    ShowCaption = false;
                }
                group(SettingsForWrapProdOrderRoutingLineRule)
                {
                    Visible = IsProductionOrder;
                    ShowCaption = false;

                    field(ChooseProdOrderRoutingLineRuleFilter; ProdOrderRoutingLineRuleFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies additional filters you may need to review and set.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullProdOrderRoutingLineFilter();
                        end;
                    }
                }
                group(SettingsForWrapAssemblyOrderRule)
                {
                    Visible = IsAssemblyOrder;
                    ShowCaption = false;

                    field(ChoosePostedAssemblyOrderRuleFilter; PostedAssemblyOrderRuleFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
                        ToolTip = 'Specifies additional filters you may need to review and set.';
                        MultiLine = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditFullPostedAssemblyHeaderFilter();
                        end;
                    }
                }
                field(ChooseFilters_Item; ItemRuleFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies additional filters you may need to review and set.';
                    MultiLine = true;

                    trigger OnAssistEdit()
                    begin
                        AssistEditFullItemFilter();
                    end;
                }
                group(SettingsForbAutomaticallyCreateInspection)
                {
                    ShowCaption = false;
                    InstructionalText = 'Do you want to automatically create inspections when these are produced?  This will set the activation trigger for this rule and set the default trigger value for inspection generation rules of this record type.';

                    group(SettingsForAutoProductionTriggerWrapper)
                    {
                        Visible = IsProductionOrder;
                        ShowCaption = false;

                        field(ChooseeAutomaticallyCreateProductionTest; QltyProductionTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is produced.';
                        }
                    }
                    group(SettingsForAutoAssemblyProductionTriggerWrapper)
                    {
                        Visible = IsAssemblyOrder;
                        ShowCaption = false;

                        field(ChooseeAutomaticallyCreateAssemblyTest; QltyAssemblyTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Inspection';
                            ToolTip = 'Specifies whether to automatically create an inspection when product is produced.';
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
            action(Back)
            {
                Caption = 'Back';
                ToolTip = 'Back';
                Enabled = IsBackEnabledd;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    BackAction();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ToolTip = 'Next';
                Enabled = IsNextEnabledd;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    NextAction();
                end;
            }
            action(Finish)
            {
                Caption = 'Finish';
                ToolTip = 'Finish';
                Enabled = IsFinishEnabledd;
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
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempItem: Record "Item" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        CurrentStepCounter: Integer;
        LocationCodeFilter: Code[20];
        TemplateCode: Code[20];
        RoutingNoFilter: Code[20];
        SpecificNoFilter: Code[20];
        WorkCenterNo: Code[20];
        FromBinCodeFilter: Code[20];
        ToBinCodeFilter: Code[20];
        OperationNo: Code[20];
        DescriptionPattern: Text[100];
        ItemNoFilter: Code[20];
        CategoryCodeFilter: Code[20];
        InventoryPostingGroupCode: Code[20];
        QltyProductionTrigger: Enum "Qlty. Production Trigger";
        QltyAssemblyTrigger: Enum "Qlty. Assembly Trigger";
        ProdOrderRoutingLineRuleFilter: Text[400];
        PostedAssemblyOrderRuleFilter: Text[400];
        ItemRuleFilter: Text[400];
        IsBackEnabledd: Boolean;
        IsNextEnabledd: Boolean;
        IsFinishEnabledd: Boolean;
        IsMovingForward: Boolean;
        IsMovingBackward: Boolean;
        IsAssemblyOrder: Boolean;
        IsProductionOrder: Boolean;
        StepWhichTemplateCounter: Integer;
        StepWhichLineCounter: Integer;
        StepWhichItemFilterCounter: Integer;
        StepAssemblyOrProductionCounter: Integer;
        StepWhichAssemblyOrderCounter: Integer;
        StepDoneCounter: Integer;
        MaxStep: Integer;
        LocationFilterErr: Label 'This Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        FromBinFilterErr: Label 'This From Bin filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ToBinFilterErr: Label 'This To Bin filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        RoutingNoFilterErr: Label 'This Routing No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        OperationNoErr: Label 'This Operation No. filter needs an adjustment. Operation Nos. are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        MachineNoFilterErr: Label 'This Machine No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemFilterErr: Label 'This Item filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemCategoryFilterErr: Label 'This Item Category filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        InventoryPostingGroupErr: Label 'This Inventory Posting Group filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        YouMustChooseATemplateFirstMsg: Label 'Please choose a template before proceeding.';
        WorkCenterNoErr: Label 'This Work Center No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        RuleAlreadyThereQst: Label 'You already have at least one rule with these same conditions. Are you sure you want to proceed?';
        FilterLengthErr: Label 'This filter is too long and must be less than %1 characters.', Comment = '%1=filter string maximum length';

    trigger OnInit();
    begin
        QltyManagementSetup.Get();
        StepWhichTemplateCounter := 1;
        StepAssemblyOrProductionCounter := 2;
        StepWhichLineCounter := 3;
        StepWhichAssemblyOrderCounter := 4;
        StepWhichItemFilterCounter := 5;
        StepDoneCounter := 6;

        InitializeDefaultValues();

        MaxStep := StepDoneCounter;
    end;

    trigger OnOpenPage();
    begin
        ChangeToStep(StepWhichTemplateCounter);
        Commit();
    end;

    /// <summary>
    /// Intended to help initialize default values.
    /// </summary>
    local procedure InitializeDefaultValues()
    begin
        InitializeDefaultTemplate();
        if not IsProductionOrder and not IsAssemblyOrder then
            IsProductionOrder := true;
    end;

    local procedure InitializeDefaultTemplate()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if TemplateCode <> '' then
            exit;

        QltyInspectionTemplateHdr.SetCurrentKey(SystemModifiedAt);
        QltyInspectionTemplateHdr.Ascending(false);
        if QltyInspectionTemplateHdr.FindFirst() then
            TemplateCode := QltyInspectionTemplateHdr.Code;
    end;

    local procedure ChangeToStep(Step: Integer);
    begin
        if Step < 1 then
            Step := 1;

        if Step > MaxStep then
            Step := MaxStep;

        IsMovingForward := Step > CurrentStepCounter;
        IsMovingBackward := Step < CurrentStepCounter;

        if IsMovingForward then
            LeavingStepMovingForward(CurrentStepCounter, Step);

        if IsMovingBackward then
            LeavingStepMovingBackward(CurrentStepCounter, Step);

        case Step of
            StepWhichTemplateCounter:
                begin
                    IsBackEnabledd := false;
                    IsNextEnabledd := true;
                    IsFinishEnabledd := false;
                end;
            StepAssemblyOrProductionCounter:
                begin
                    IsBackEnabledd := true;
                    IsNextEnabledd := true;
                    IsFinishEnabledd := false;
                end;
            StepWhichLineCounter:
                begin
                    IsBackEnabledd := true;
                    IsNextEnabledd := true;
                    IsFinishEnabledd := false;
                end;
            StepWhichAssemblyOrderCounter:
                begin
                    IsBackEnabledd := true;
                    IsNextEnabledd := true;
                    IsFinishEnabledd := false;
                end;
            StepWhichItemFilterCounter:
                begin
                    IsBackEnabledd := true;
                    IsNextEnabledd := true;
                    IsFinishEnabledd := false;
                end;
            StepDoneCounter:
                begin
                    IsBackEnabledd := true;
                    IsNextEnabledd := false;
                    IsFinishEnabledd := true;
                    UpdateFullTextRuleStringsFromFilters();
                end;
        end;

        CurrentStepCounter := Step;

        CurrPage.Update(true);
    end;

    local procedure LeavingStepMovingForward(LeavingThisStep: Integer; var MovingToThisStep: Integer);
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if LeavingThisStep = StepWhichTemplateCounter then
            if MovingToThisStep = StepAssemblyOrProductionCounter then
                if not QltyInspectionTemplateHdr.Get(TemplateCode) then begin
                    Message(YouMustChooseATemplateFirstMsg);
                    MovingToThisStep := StepWhichTemplateCounter;
                end;
        if LeavingThisStep = StepAssemblyOrProductionCounter then
            if IsProductionOrder then begin
                MovingToThisStep := StepWhichLineCounter;
                QltyProductionTrigger := QltyManagementSetup."Production Trigger";
            end else begin
                MovingToThisStep := StepWhichAssemblyOrderCounter;
                QltyAssemblyTrigger := QltyManagementSetup."Assembly Trigger";
            end;
        if LeavingThisStep = StepWhichLineCounter then
            MovingToThisStep := StepWhichItemFilterCounter;
    end;

    local procedure LeavingStepMovingBackward(LeavingThisStep: Integer; var MovingToThisStep: Integer)
    begin
        if LeavingThisStep = StepWhichItemFilterCounter then
            if IsProductionOrder then
                MovingToThisStep := StepWhichLineCounter
            else
                MovingToThisStep := StepWhichAssemblyOrderCounter;
        if LeavingThisStep = StepWhichAssemblyOrderCounter then
            MovingToThisStep := StepAssemblyOrProductionCounter;
    end;

    local procedure AssistEditFullProdOrderRoutingLineFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Prod. Order Routing Line";
        TempQltyInspectionGenRule."Condition Filter" := ProdOrderRoutingLineRuleFilter;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            ProdOrderRoutingLineRuleFilter := TempQltyInspectionGenRule."Condition Filter";

            TempProdOrderRoutingLine.SetView(ProdOrderRoutingLineRuleFilter);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullItemFilter()
    begin
        TempQltyInspectionGenRule."Item Filter" := ItemRuleFilter;
        if TempQltyInspectionGenRule.AssistEditConditionItemFilter() then begin
            ItemRuleFilter := TempQltyInspectionGenRule."Item Filter";

            TempItem.SetView(ItemRuleFilter);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullPostedAssemblyHeaderFilter()
    begin
        TempQltyInspectionGenRule."Source Table No." := Database::"Posted Assembly Header";
        TempQltyInspectionGenRule."Condition Filter" := PostedAssemblyOrderRuleFilter;

        if TempQltyInspectionGenRule.AssistEditConditionTableFilter() then begin
            PostedAssemblyOrderRuleFilter := TempQltyInspectionGenRule."Condition Filter";

            TempPostedAssemblyHeader.SetView(PostedAssemblyOrderRuleFilter);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure CleanUpWhereClause()
    begin
        if IsProductionOrder then
            ProdOrderRoutingLineRuleFilter := QltyFilterHelpers.CleanUpWhereClause400(ProdOrderRoutingLineRuleFilter);
        if IsAssemblyOrder then
            PostedAssemblyOrderRuleFilter := QltyFilterHelpers.CleanUpWhereClause400(PostedAssemblyOrderRuleFilter);
        ItemRuleFilter := QltyFilterHelpers.CleanUpWhereClause400(ItemRuleFilter);
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ExistingQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if not QltyInspectionGenRule.Get(TempQltyInspectionGenRule.RecordId()) then begin
            QltyInspectionGenRule.Init();
            QltyInspectionGenRule.SetEntryNo();
            QltyInspectionGenRule.UpdateSortOrder();
            QltyInspectionGenRule.Insert();
        end;
        QltyInspectionGenRule.Validate("Template Code", TemplateCode);
        QltyManagementSetup.Get();
        if IsProductionOrder then begin
            QltyInspectionGenRule."Source Table No." := Database::"Prod. Order Routing Line";
            QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::Production;
            QltyInspectionGenRule."Condition Filter" := ProdOrderRoutingLineRuleFilter;
            QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
            QltyInspectionGenRule."Production Trigger" := QltyProductionTrigger;

            QltyManagementSetup."Production Trigger" := QltyProductionTrigger;
        end else begin
            QltyInspectionGenRule."Source Table No." := Database::"Posted Assembly Header";
            QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::Assembly;
            QltyInspectionGenRule."Condition Filter" := PostedAssemblyOrderRuleFilter;
            QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
            QltyInspectionGenRule."Assembly Trigger" := QltyAssemblyTrigger;
            QltyManagementSetup."Assembly Trigger" := QltyAssemblyTrigger;
        end;
        if QltyManagementSetup.Modify(false) then;
        QltyInspectionGenRule."Item Filter" := ItemRuleFilter;
        QltyInspectionGenRule.Modify();

        ExistingQltyInspectionGenRule.SetRange("Template Code", QltyInspectionGenRule."Template Code");
        ExistingQltyInspectionGenRule.SetRange("Source Table No.", QltyInspectionGenRule."Source Table No.");
        ExistingQltyInspectionGenRule.SetRange("Condition Filter", QltyInspectionGenRule."Condition Filter");
        ExistingQltyInspectionGenRule.SetRange("Item Filter", QltyInspectionGenRule."Item Filter");
        if ExistingQltyInspectionGenRule.Count() > 1 then
            if not Confirm(RuleAlreadyThereQst) then
                Error('');

        CurrPage.Close();
    end;

    /// <summary>
    /// Start the wizard using this generation rule as a pre-requisite.
    /// Use this to edit an existing rule.
    /// You can also use it to start a new rule with a default template by supplying a template filter.
    /// </summary>
    /// <param name="QltyInspectionGenRule"></param>
    /// <returns></returns>
    procedure RunModalWithGenerationRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Action
    begin
        TempQltyInspectionGenRule := QltyInspectionGenRule;
        Clear(TempProdOrderRoutingLine);
        Clear(TempPostedAssemblyHeader);
        Clear(TempItem);

        if QltyInspectionGenRule."Source Table No." = Database::"Prod. Order Routing Line" then begin
            TempProdOrderRoutingLine.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsProductionOrder := true;
            IsAssemblyOrder := false;
        end;
        if QltyInspectionGenRule."Source Table No." = Database::"Posted Assembly Header" then begin
            TempPostedAssemblyHeader.SetView(TempQltyInspectionGenRule."Condition Filter");
            IsAssemblyOrder := true;
            IsProductionOrder := false;
        end;

        TempItem.SetView(TempQltyInspectionGenRule."Item Filter");
        UpdateTableVariablesFromRecordFilters();

        TemplateCode := QltyInspectionGenRule.GetTemplateCodeFromRecordOrFilter(false);
        UpdateFullTextRuleStringsFromFilters();

        exit(CurrPage.RunModal());
    end;

    [TryFunction]
    local procedure UpdateFullTextRuleStringsFromFilters()
    begin
        if IsProductionOrder then begin
            TempProdOrderRoutingLine.SetFilter("Location Code", LocationCodeFilter);
            TempProdOrderRoutingLine.SetFilter("Routing No.", RoutingNoFilter);
            TempProdOrderRoutingLine.SetFilter("Work Center No.", WorkCenterNo);
            TempProdOrderRoutingLine.SetFilter("No.", SpecificNoFilter);
            TempProdOrderRoutingLine.SetFilter("From-Production Bin Code", FromBinCodeFilter);
            TempProdOrderRoutingLine.SetFilter("To-Production Bin Code", ToBinCodeFilter);
            TempProdOrderRoutingLine.SetFilter("Operation No.", OperationNo);
            TempProdOrderRoutingLine.SetFilter("Description", DescriptionPattern);
            ProdOrderRoutingLineRuleFilter := CopyStr(QltyFilterHelpers.CleanUpWhereClause400(TempProdOrderRoutingLine.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end else begin
            TempPostedAssemblyHeader.SetFilter("Location Code", LocationCodeFilter);
            TempPostedAssemblyHeader.SetFilter(Description, DescriptionPattern);
            PostedAssemblyOrderRuleFilter := CopyStr(QltyFilterHelpers.CleanUpWhereClause400(TempPostedAssemblyHeader.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));
        end;

        TempItem.SetFilter("No.", ItemNoFilter);
        TempItem.SetFilter("Item Category Code", CategoryCodeFilter);
        TempItem.SetFilter("Inventory Posting Group", InventoryPostingGroupCode);

        ItemRuleFilter := CopyStr(QltyFilterHelpers.CleanUpWhereClause400(TempItem.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));
        CleanUpWhereClause();

        if StrLen(QltyFilterHelpers.CleanUpWhereClause400(TempProdOrderRoutingLine.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause400(TempPostedAssemblyHeader.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause400(TempItem.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Item Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));
    end;

    local procedure UpdateTableVariablesFromRecordFilters()
    begin
        if IsProductionOrder then begin
            LocationCodeFilter := CopyStr(TempProdOrderRoutingLine.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
            RoutingNoFilter := CopyStr(TempProdOrderRoutingLine.GetFilter("Routing No."), 1, MaxStrLen(RoutingNoFilter));
            WorkCenterNo := CopyStr(TempProdOrderRoutingLine.GetFilter("Work Center No."), 1, MaxStrLen(WorkCenterNo));
            SpecificNoFilter := CopyStr(TempProdOrderRoutingLine.GetFilter("No."), 1, MaxStrLen(SpecificNoFilter));
            FromBinCodeFilter := CopyStr(TempProdOrderRoutingLine.GetFilter("From-Production Bin Code"), 1, MaxStrLen(FromBinCodeFilter));
            ToBinCodeFilter := CopyStr(TempProdOrderRoutingLine.GetFilter("To-Production Bin Code"), 1, MaxStrLen(ToBinCodeFilter));
            OperationNo := CopyStr(TempProdOrderRoutingLine.GetFilter("Operation No."), 1, MaxStrLen(OperationNo));
            DescriptionPattern := CopyStr(TempProdOrderRoutingLine.GetFilter("Description"), 1, MaxStrLen(DescriptionPattern));
        end else begin
            LocationCodeFilter := CopyStr(TempPostedAssemblyHeader.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
            DescriptionPattern := CopyStr(TempPostedAssemblyHeader.GetFilter(Description), 1, MaxStrLen(DescriptionPattern));
            ToBinCodeFilter := CopyStr(TempPostedAssemblyHeader.GetFilter("Bin Code"), 1, MaxStrLen(ToBinCodeFilter));
        end;

        ItemNoFilter := CopyStr(TempItem.GetFilter("No."), 1, MaxStrLen(ItemNoFilter));
        CategoryCodeFilter := CopyStr(TempItem.GetFilter("Item Category Code"), 1, MaxStrLen(CategoryCodeFilter));
        InventoryPostingGroupCode := CopyStr(TempItem.GetFilter("Inventory Posting Group"), 1, MaxStrLen(InventoryPostingGroupCode));
    end;
}
