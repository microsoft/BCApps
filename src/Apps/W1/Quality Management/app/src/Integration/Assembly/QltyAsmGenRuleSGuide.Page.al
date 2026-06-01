// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;

page 20464 "Qlty. Asm. Gen. Rule S. Guide"
{
    Caption = 'Assembly Quality Inspection Rule Setup Guide';
    PageType = NavigatePage;
    UsageCategory = None;
    ApplicationArea = Assembly;
    SourceTable = "Qlty. Management Setup";

    layout
    {
        area(Content)
        {
            group(StepWhichTemplate)
            {
                Caption = ' ';
                ShowCaption = false;
                Visible = (StepWhichTemplateCounter = CurrentStepCounter);

                group(StepWhichTemplate_Instruction1)
                {
                    InstructionalText = 'Define a rule for item tracking related tests when products are assembled.';
                    Caption = ' ';
                    ShowCaption = false;
                }
                group(StepWhichTemplate_Instruction2)
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

            group(StepWhichAssemblyOrder)
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
                        ClearLastError();
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
                        ClearLastError();
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
            group(StepWhichItem)
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
                        ClearLastError();
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
                        ClearLastError();
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
                        ClearLastError();
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
            group(StepDone)
            {
                Caption = ' ';
                InstructionalText = '';
                ShowCaption = false;
                Visible = (StepDoneCounter = CurrentStepCounter);

                group(StepDone_Instruction1)
                {
                    Caption = ' ';
                    InstructionalText = 'We have a Test Generation Rule ready. Click ''Finish'' to save this to the system.';
                    ShowCaption = false;
                }
                group(StepDone_Instruction2)
                {
                    Caption = ' ';
                    InstructionalText = 'Please review and set any additional filters you may need, for example if you want to limit this to specific items.';
                    ShowCaption = false;
                }
                group(WrapAssemblyOrderRule)
                {
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
                group(bAutomaticallyCreateTest)
                {
                    ShowCaption = false;
                    InstructionalText = 'Do you want to automatically create tests when these are produced?  This will set the activation trigger for this rule and set the default trigger value for test generation rules of this record type.';

                    group(AutoAssemblyTriggerWrapper)
                    {
                        ShowCaption = false;

                        field(ChooseAutomaticallyCreateAssemblyTest; QltyAssemblyTrigger)
                        {
                            ApplicationArea = All;
                            Caption = 'Automatically Create Test';
                            ToolTip = 'Specifies whether to automatically create a test when product is produced.';
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
        TempItem: Record "Item" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        CurrentStepCounter: Integer;
        LocationCodeFilter: Code[20];
        TemplateCode: Code[20];
        ToBinCodeFilter: Code[20];
        DescriptionPattern: Text[100];
        ItemNoFilter: Code[20];
        CategoryCodeFilter: Code[20];
        InventoryPostingGroupCode: Code[20];
        QltyAssemblyTrigger: Enum "Qlty. Assembly Trigger";
        PostedAssemblyOrderRuleFilter: Text[2048];
        ItemRuleFilter: Text[2048];
        IsBackEnabledd: Boolean;
        IsNextEnabledd: Boolean;
        IsFinishEnabledd: Boolean;
        IsMovingForward: Boolean;
        StepWhichTemplateCounter: Integer;
        StepWhichItemFilterCounter: Integer;
        StepWhichAssemblyOrderCounter: Integer;
        StepDoneCounter: Integer;
        MaxStep: Integer;
        LocationFilterErr: Label 'This Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        ToBinFilterErr: Label 'This To Bin filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemFilterErr: Label 'This Item filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemCategoryFilterErr: Label 'This Item Category filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        InventoryPostingGroupErr: Label 'This Inventory Posting Group filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        YouMustChooseATemplateFirstMsg: Label 'Please choose a template before proceeding.';
        RuleAlreadyThereQst: Label 'You already have at least one rule with these same conditions. Are you sure you want to proceed?';
        FilterLengthErr: Label 'This filter is too long and must be less than %1 characters.', Comment = '%1=filter string maximum length';

    trigger OnInit();
    begin
        QltyManagementSetup.Get();
        StepWhichTemplateCounter := 1;
        StepWhichAssemblyOrderCounter := 2;
        StepWhichItemFilterCounter := 3;
        StepDoneCounter := 4;

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

        if IsMovingForward then
            LeavingStepMovingForward(CurrentStepCounter, Step);

        case Step of
            StepWhichTemplateCounter:
                begin
                    IsBackEnabledd := false;
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
            if not QltyInspectionTemplateHdr.Get(TemplateCode) then begin
                Message(YouMustChooseATemplateFirstMsg);
                MovingToThisStep := StepWhichTemplateCounter;
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
        PostedAssemblyOrderRuleFilter := QltyFilterHelpers.CleanUpWhereClause2048(PostedAssemblyOrderRuleFilter);
        ItemRuleFilter := QltyFilterHelpers.CleanUpWhereClause2048(ItemRuleFilter);
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
        QltyInspectionGenRule."Source Table No." := Database::"Posted Assembly Header";
        QltyInspectionGenRule.Intent := QltyInspectionGenRule.Intent::Assembly;
        QltyInspectionGenRule."Condition Filter" := PostedAssemblyOrderRuleFilter;
        QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
        QltyInspectionGenRule."Assembly Trigger" := QltyAssemblyTrigger;
        QltyManagementSetup."Assembly Trigger" := QltyAssemblyTrigger;
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
    /// Start the setup guide using this generation rule as a pre-requisite.
    /// Use this to edit an existing rule.
    /// You can also use it to start a new rule with a default template by supplying a template filter.
    /// </summary>
    /// <param name="QltyInspectionGenRule"></param>
    /// <returns></returns>
    procedure RunModalWithGenerationRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Action
    begin
        TempQltyInspectionGenRule := QltyInspectionGenRule;
        Clear(TempPostedAssemblyHeader);
        Clear(TempItem);

        if QltyInspectionGenRule."Source Table No." = Database::"Posted Assembly Header" then
            TempPostedAssemblyHeader.SetView(TempQltyInspectionGenRule."Condition Filter");

        TempItem.SetView(TempQltyInspectionGenRule."Item Filter");
        UpdateTableVariablesFromRecordFilters();

        TemplateCode := QltyInspectionGenRule.GetTemplateCodeFromRecordOrFilter(false);
        UpdateFullTextRuleStringsFromFilters();

        exit(CurrPage.RunModal());
    end;

    [TryFunction]
    local procedure UpdateFullTextRuleStringsFromFilters()
    begin
        TempPostedAssemblyHeader.SetFilter("Location Code", LocationCodeFilter);
        TempPostedAssemblyHeader.SetFilter(Description, DescriptionPattern);
        PostedAssemblyOrderRuleFilter := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempPostedAssemblyHeader.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        TempItem.SetFilter("No.", ItemNoFilter);
        TempItem.SetFilter("Item Category Code", CategoryCodeFilter);
        TempItem.SetFilter("Inventory Posting Group", InventoryPostingGroupCode);

        ItemRuleFilter := CopyStr(QltyFilterHelpers.CleanUpWhereClause2048(TempItem.GetView(true)), 1, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));
        CleanUpWhereClause();

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempPostedAssemblyHeader.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause2048(TempItem.GetView(true))) > MaxStrLen(TempQltyInspectionGenRule."Item Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInspectionGenRule."Item Filter"));
    end;

    local procedure UpdateTableVariablesFromRecordFilters()
    begin
        LocationCodeFilter := CopyStr(TempPostedAssemblyHeader.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
        DescriptionPattern := CopyStr(TempPostedAssemblyHeader.GetFilter(Description), 1, MaxStrLen(DescriptionPattern));
        ToBinCodeFilter := CopyStr(TempPostedAssemblyHeader.GetFilter("Bin Code"), 1, MaxStrLen(ToBinCodeFilter));

        ItemNoFilter := CopyStr(TempItem.GetFilter("No."), 1, MaxStrLen(ItemNoFilter));
        CategoryCodeFilter := CopyStr(TempItem.GetFilter("Item Category Code"), 1, MaxStrLen(CategoryCodeFilter));
        InventoryPostingGroupCode := CopyStr(TempItem.GetFilter("Inventory Posting Group"), 1, MaxStrLen(InventoryPostingGroupCode));
    end;
}