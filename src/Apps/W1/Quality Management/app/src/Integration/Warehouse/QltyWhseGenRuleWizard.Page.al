// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Warehouse;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 20460 "Qlty. Whse. Gen. Rule Wizard"
{
    Caption = 'Quality Management - Warehouse Movement Quality Test Generation Rule Wizard';
    PageType = NavigatePage;
    UsageCategory = Administration;
    ApplicationArea = Warehouse;
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
                    InstructionalText = 'Use this feature with lot warehouse tracked items or serial warehouse tracked items, allowing you to define a rule for lot or serial related tests when products move into or out of specific bins. This will work with movements, reclass, and put-away documents. A Quality Inspection Test Generation Rule will be made or updated.';
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
                    Caption = 'Choose Template';
                    ToolTip = 'Specifies which Quality Inspection template do you want to use?';
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditQltyInspectionTemplate(TemplateCode);
                    end;
                }
            }
            group(SettingsFor_iStepWhichToBin)
            {
                Caption = ' ';
                ShowCaption = false;
                InstructionalText = 'A test should be created when items are moved into which bin?';
                Visible = (StepWhichToBinCounter = CurrentStepCounter);

                field(ChoosechooseLocation; LocationCodeFilter)
                {
                    Caption = 'Location';
                    ToolTip = 'Specifies a Location filter.';

                    trigger OnAssistEdit()
                    begin
                        AssistEditLocation();
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(LocationFilterErr, GetLastErrorText());
                    end;
                }
                field(ChoosechooseToZone; ToZoneCodeFilter)
                {
                    Caption = 'Zone';
                    ToolTip = 'Specifies a Zone filter.';

                    trigger OnAssistEdit()
                    begin
                        AssistEditZone();
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ToZoneFilterErr, GetLastErrorText());
                    end;
                }
                field(ChoosechooseToBin; ToBinCodeFilter)
                {
                    Caption = 'Bin';
                    ToolTip = 'Specifies a Bin filter.';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditBin(LocationCodeFilter, ToZoneCodeFilter, ToBinCodeFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(ToBinFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseJustForPutAways; JustPutAways)
                {
                    Caption = 'Just put-aways';
                    ToolTip = 'Specifies to limit this to only put-aways.';

                    trigger OnValidate()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                    end;
                }
                field(Chooseadvanced; 'Click here to choose advanced fields...')
                {
                    ApplicationArea = All;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        UpdateFullTextRuleStringsFromFilters();
                        AssistEditFullWhseFilter();
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

                field(ChooseItemFilter; ItemNoFilter)
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
                field(ChooseInventoryPostingGroup; InventoryPostingGroupCode)
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
                            Error(InventoryPostingGroupFilterErr, GetLastErrorText());
                    end;
                }
                field(ChooseVendorNoFilter; VendorNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor No.';
                    ToolTip = 'Specifies a Vendor No.';

                    trigger OnAssistEdit()
                    begin
                        QltyFilterHelpers.AssistEditVendor(VendorNoFilter);
                    end;

                    trigger OnValidate()
                    begin
                        if not UpdateFullTextRuleStringsFromFilters() then
                            Error(VendorFilterErr, GetLastErrorText());
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
                    InstructionalText = 'We have a Test Generation Rule ready. Click ''Finish'' to save this to the system.';
                    ShowCaption = false;
                }
                group(SettingsFor_iStepDone_Instruction2)
                {
                    Caption = ' ';
                    InstructionalText = 'Please review and set any additional filters you may need, for example if you want to limit this to specific items.';
                    ShowCaption = false;
                }
                field(ChooseFilters_Whse; WhseRule)
                {
                    ApplicationArea = All;
                    Caption = 'Filters';
                    ToolTip = 'Specifies additional filters you may need to review and set.';
                    MultiLine = true;

                    trigger OnAssistEdit()
                    begin
                        AssistEditFullWhseFilter();
                    end;
                }
                field(ChooseFilters_Item; ItemRule)
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
                group(SettingsForbAutomaticallyCreateTest)
                {
                    ShowCaption = false;
                    InstructionalText = 'Do you want to automatically create a test when product is moved to a bin? This setting affects the entire company, not just this rule.';

                    field(ChooseeMoveAutomaticallyCreateTest; QltyWarehouseTrigger)
                    {
                        ApplicationArea = All;
                        Caption = 'Automatically Create Test';
                        ToolTip = 'Specifies whether to automatically create a test when product is moved to this bin.';
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
                Enabled = IsIsBackEnabledd;
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
                Enabled = IsIsNextEnabledd;
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
                Enabled = IsIsFinishEnabledd;
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
        WarehouseEmployee: Record "Warehouse Employee";
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        TempItem: Record "Item" temporary;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        Zone: Record Zone;
        Bin: Record Bin;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        CurrentStepCounter: Integer;
        LocationCodeFilter: Code[20];
        TemplateCode: Code[20];
        ToZoneCodeFilter: Code[20];
        ToBinCodeFilter: Code[20];
        ItemNoFilter: Code[20];
        CategoryCodeFilter: Code[20];
        InventoryPostingGroupCode: Code[20];
        VendorNoFilter: Code[20];
        QltyWarehouseTrigger: Enum "Qlty. Warehouse Trigger";
        WhseRule: Text[400];
        ItemRule: Text[400];
        IsIsBackEnabledd: Boolean;
        IsIsNextEnabledd: Boolean;
        IsIsFinishEnabledd: Boolean;
        IsMovingForward: Boolean;
        JustPutAways: Boolean;
        StepWhichTemplateCounter: Integer;
        StepWhichToBinCounter: Integer;
        StepWhichItemFilterCounter: Integer;
        StepDoneCounter: Integer;
        MaxStep: Integer;
        LocationFilterErr: Label 'This Location filter needs an adjustment. Location codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        ToZoneFilterErr: Label 'This To Zone filter needs an adjustment. Zone codes are no more than 10 characters. %1', Comment = '%1 = Text of the original error message';
        ToBinFilterErr: Label 'This To Bin filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemFilterErr: Label 'This Item filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        ItemCategoryFilterErr: Label 'This Item Category filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        InventoryPostingGroupFilterErr: Label 'This Inventory Posting Group filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        VendorFilterErr: Label 'This Vendor No. filter needs an adjustment. %1', Comment = '%1 = Text of the original error message';
        YourUserDoesNotAppearToBeConfiguredAsAWarehouseEmployeeMsg: Label 'Your user id of %1 does not appear to be configured as a warehouse employee. Navigate to Warehouse Employees and create appropriate warehouse employee configuration before using this screen.', Comment = '%1=the user id.';
        YouMustChooseATemplateFirstMsg: Label 'Please choose a template before proceeding.';
        AlreadyThereQst: Label 'You already have at least one rule with these same conditions. Are you sure you want to proceed?';
        FilterLengthErr: Label 'This filter is too long and must be less than %1 characters.', Comment = '%1=filter string maximum length';

    trigger OnInit();
    begin
        QltyManagementSetup.Get();
        StepWhichTemplateCounter := 1;
        StepWhichToBinCounter := 2;
        StepWhichItemFilterCounter := 3;
        StepDoneCounter := 4;

        InitializeDefaultValues();

        QltyWarehouseTrigger := QltyManagementSetup."Warehouse Trigger";

        MaxStep := StepDoneCounter;
    end;

    trigger OnOpenPage();
    begin
        ChangeToStep(StepWhichTemplateCounter);
        Commit();
    end;

    /// <summary>
    /// Intended to help intialize default values.
    /// </summary>
    local procedure InitializeDefaultValues()
    begin
        JustPutAways := true;
        InitializeDefaultTemplate();
        InitializeDefaultLocation();
        InitializeDefaultZone();
        InitializeDefaultBin();
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

    local procedure InitializeDefaultLocation()
    begin
        if LocationCodeFilter <> '' then
            exit;

        WarehouseEmployee.Reset();
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.SetRange("Default", true);
        if WarehouseEmployee.FindFirst() then
            LocationCodeFilter := WarehouseEmployee."Location Code"
        else begin
            WarehouseEmployee.SetRange("Default");
            if WarehouseEmployee.FindFirst() then
                LocationCodeFilter := WarehouseEmployee."Location Code"
            else
                Message(YourUserDoesNotAppearToBeConfiguredAsAWarehouseEmployeeMsg, UserId());
        end;
    end;

    local procedure InitializeDefaultZone()
    begin
        if ToZoneCodeFilter <> '' then
            exit;

        Zone.Reset();
        if LocationCodeFilter <> '' then
            Zone.SetFilter("Location Code", LocationCodeFilter);

        Zone.SetFilter(Code, 'QC|QUAL*');
        if Zone.FindFirst() then
            ToZoneCodeFilter := Zone.Code
        else begin
            Zone.SetRange(Code);
            Zone.SetFilter("Bin Type Code", 'QC|QUAL*');
            if Zone.FindFirst() then
                ToZoneCodeFilter := Zone.Code
            else
                Zone.SetRange("Bin Type Code");
        end;
    end;

    local procedure InitializeDefaultBin()
    var
        SearchBin: Record Bin;
        CharacterIterator: Integer;
        Different: Boolean;
        TestMatch: Text;
    begin
        if ToBinCodeFilter <> '' then
            exit;

        Bin.Reset();
        if LocationCodeFilter <> '' then
            Bin.SetFilter("Location Code", LocationCodeFilter);
        if ToZoneCodeFilter <> '' then
            Bin.SetFilter("Zone Code", ToZoneCodeFilter);
        if Bin.Count() = 1 then begin
            Bin.FindFirst();
            ToBinCodeFilter := Bin.Code;
        end else
            if not Bin.IsEmpty() then begin
                Bin.FindFirst();
                SearchBin.SetView(Bin.GetView());
                repeat
                    CharacterIterator += 1;
                    TestMatch := CopyStr(Bin.Code, 1, CharacterIterator) + '*';
                    SearchBin.SetFilter(Code, TestMatch);
                    Different := SearchBin.Count() <> Bin.Count();
                    if not Different then
                        ToBinCodeFilter := CopyStr(TestMatch, 1, MaxStrLen(ToBinCodeFilter));
                until Different or (CharacterIterator >= (MaxStrLen(Bin.Code) - 1));
            end;
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
                    IsIsBackEnabledd := false;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepWhichToBinCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepWhichItemFilterCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := true;
                    IsIsFinishEnabledd := false;
                end;
            StepDoneCounter:
                begin
                    IsIsBackEnabledd := true;
                    IsIsNextEnabledd := false;
                    IsIsFinishEnabledd := true;
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
            if MovingToThisStep = StepWhichToBinCounter then
                if not QltyInspectionTemplateHdr.Get(TemplateCode) then begin
                    Message(YouMustChooseATemplateFirstMsg);
                    MovingToThisStep := StepWhichTemplateCounter;
                end;
    end;

    local procedure AssistEditLocation()
    begin
        if QltyFilterHelpers.AssistEditLocation(LocationCodeFilter) then begin
            Zone.Reset();
            Zone.SetFilter("Location Code", LocationCodeFilter);
            Zone.SetFilter("Code", ToZoneCodeFilter);
            if Zone.IsEmpty() or (ToZoneCodeFilter = '') then begin
                ToZoneCodeFilter := '';
                ToBinCodeFilter := '';
            end;
            InitializeDefaultZone();
            InitializeDefaultBin();
        end;
    end;

    local procedure AssistEditZone()
    begin
        if QltyFilterHelpers.AssistEditZone(LocationCodeFilter, ToZoneCodeFilter) then begin
            Bin.Reset();
            Bin.SetFilter("Location Code", LocationCodeFilter);
            Bin.SetFilter("Zone Code", ToZoneCodeFilter);
            Bin.SetFilter("Code", ToBinCodeFilter);
            if Bin.IsEmpty() then
                ToBinCodeFilter := '';

            InitializeDefaultBin();
        end;
    end;

    local procedure AssistEditFullWhseFilter()

    begin
        TempQltyInTestGenerationRule."Source Table No." := Database::"Warehouse Journal Line";
        TempQltyInTestGenerationRule."Condition Filter" := WhseRule;

        if TempQltyInTestGenerationRule.AssistEditConditionTableFilter() then begin
            WhseRule := TempQltyInTestGenerationRule."Condition Filter";

            TempWarehouseJournalLine.SetView(WhseRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    local procedure AssistEditFullItemFilter()
    begin
        TempQltyInTestGenerationRule."Item Filter" := ItemRule;
        if TempQltyInTestGenerationRule.AssistEditConditionItemFilter() then begin
            ItemRule := TempQltyInTestGenerationRule."Item Filter";

            TempItem.SetView(ItemRule);
            UpdateTableVariablesFromRecordFilters();
            CleanUpWhereClause();
        end;
    end;

    [TryFunction]
    local procedure UpdateFullTextRuleStringsFromFilters()
    begin
        if JustPutAways then
            TempWarehouseJournalLine.SetRange("Reference Document", TempWarehouseJournalLine."Reference Document"::"Put-away")
        else
            if TempWarehouseJournalLine.GetFilter("Reference Document") <> '' then
                if TempWarehouseJournalLine.GetRangeMin("Reference Document") = TempWarehouseJournalLine."Reference Document"::"Put-away" then
                    TempWarehouseJournalLine.SetRange("Reference Document");

        TempWarehouseJournalLine.SetFilter("Location Code", LocationCodeFilter);
        TempWarehouseJournalLine.SetFilter("To Zone Code", ToZoneCodeFilter);
        TempWarehouseJournalLine.SetFilter("To Bin Code", ToBinCodeFilter);
        WhseRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause400(TempWarehouseJournalLine.GetView(true)), 1, MaxStrLen(TempQltyInTestGenerationRule."Condition Filter"));

        TempItem.SetFilter("No.", ItemNoFilter);
        TempItem.SetFilter("Item Category Code", CategoryCodeFilter);
        TempItem.SetFilter("Inventory Posting Group", InventoryPostingGroupCode);
        TempItem.SetFilter("Vendor No.", VendorNoFilter);
        ItemRule := CopyStr(QltyFilterHelpers.CleanUpWhereClause400(TempItem.GetView(true)), 1, MaxStrLen(TempQltyInTestGenerationRule."Item Filter"));

        CleanUpWhereClause();

        if StrLen(QltyFilterHelpers.CleanUpWhereClause400(TempWarehouseJournalLine.GetView(true))) > MaxStrLen(TempQltyInTestGenerationRule."Condition Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInTestGenerationRule."Condition Filter"));

        if StrLen(QltyFilterHelpers.CleanUpWhereClause400(TempItem.GetView(true))) > MaxStrLen(TempQltyInTestGenerationRule."Item Filter") then
            Error(FilterLengthErr, MaxStrLen(TempQltyInTestGenerationRule."Item Filter"));
    end;

    local procedure CleanUpWhereClause()
    begin
        WhseRule := QltyFilterHelpers.CleanUpWhereClause400(WhseRule);
        ItemRule := QltyFilterHelpers.CleanUpWhereClause400(ItemRule);
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
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ExistingQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        if not QltyInTestGenerationRule.Get(TempQltyInTestGenerationRule.RecordId()) then begin
            QltyInTestGenerationRule.Init();
            QltyInTestGenerationRule.SetEntryNo();
            QltyInTestGenerationRule.UpdateSortOrder();
            QltyInTestGenerationRule."Source Table No." := 0;
            QltyInTestGenerationRule.Insert();
        end;
        QltyInTestGenerationRule."Source Table No." := Database::"Warehouse Journal Line";
        QltyInTestGenerationRule.Intent := QltyInTestGenerationRule.Intent::"Warehouse Movement";
        QltyInTestGenerationRule.Validate("Template Code", TemplateCode);
        QltyInTestGenerationRule."Condition Filter" := WhseRule;
        QltyInTestGenerationRule."Item Filter" := ItemRule;
        QltyInTestGenerationRule.SetIntentAndDefaultTriggerValuesFromSetup();
        QltyInTestGenerationRule."Warehouse Movement Trigger" := QltyWarehouseTrigger;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup.Get();
        QltyManagementSetup."Warehouse Trigger" := QltyWarehouseTrigger;
        if QltyManagementSetup.Modify(false) then;

        ExistingQltyInTestGenerationRule.SetRange("Template Code", QltyInTestGenerationRule."Template Code");
        ExistingQltyInTestGenerationRule.SetRange("Source Table No.", QltyInTestGenerationRule."Source Table No.");
        ExistingQltyInTestGenerationRule.SetRange("Condition Filter", QltyInTestGenerationRule."Condition Filter");
        ExistingQltyInTestGenerationRule.SetRange("Item Filter", QltyInTestGenerationRule."Item Filter");
        if ExistingQltyInTestGenerationRule.Count() > 1 then
            if not Confirm(AlreadyThereQst) then
                Error('');

        CurrPage.Close();
    end;

    /// <summary>
    /// Start the wizard using this generation rule as a pre-requisite.
    /// Use this to edit an existing rule.
    /// You can also use it to start a new rule with a default template by supplying a template filter.
    /// </summary>
    /// <param name="QltyInTestGenerationRule"></param>
    /// <returns></returns>
    procedure RunModalWithGenerationRule(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"): Action
    begin
        TempQltyInTestGenerationRule := QltyInTestGenerationRule;
        Clear(TempWarehouseJournalLine);
        Clear(TempItem);
        TempWarehouseJournalLine.SetView(TempQltyInTestGenerationRule."Condition Filter");
        TempItem.SetView(TempQltyInTestGenerationRule."Item Filter");
        UpdateTableVariablesFromRecordFilters();

        TemplateCode := QltyInTestGenerationRule.GetTemplateCodeFromRecordOrFilter(false);
        UpdateFullTextRuleStringsFromFilters();

        exit(CurrPage.RunModal());
    end;

    local procedure UpdateTableVariablesFromRecordFilters()
    begin
        LocationCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("Location Code"), 1, MaxStrLen(LocationCodeFilter));
        ToZoneCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("To Zone Code"), 1, MaxStrLen(ToZoneCodeFilter));
        ToBinCodeFilter := CopyStr(TempWarehouseJournalLine.GetFilter("To Bin Code"), 1, MaxStrLen(ToBinCodeFilter));

        ItemNoFilter := CopyStr(TempItem.GetFilter("No."), 1, MaxStrLen(ItemNoFilter));
        CategoryCodeFilter := CopyStr(TempItem.GetFilter("Item Category Code"), 1, MaxStrLen(CategoryCodeFilter));
        InventoryPostingGroupCode := CopyStr(TempItem.GetFilter("Inventory Posting Group"), 1, MaxStrLen(InventoryPostingGroupCode));
        VendorNoFilter := CopyStr(TempItem.GetFilter("Vendor No."), 1, MaxStrLen(VendorNoFilter));

        if TempWarehouseJournalLine.GetFilter("Reference Document") <> '' then
            if TempWarehouseJournalLine.GetRangeMin("Reference Document") = TempWarehouseJournalLine."Reference Document"::"Put-away" then
                JustPutAways := true
            else
                JustPutAways := false;
    end;
}
