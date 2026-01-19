// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using System.Reflection;

/// <summary>
/// A Quality Inspection generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.
/// </summary>
table 20404 "Qlty. Inspection Gen. Rule"
{
    Caption = 'Quality Inspection Generation Rule';
    DrillDownPageId = "Qlty. Inspection Gen. Rules";
    LookupPageId = "Qlty. Inspection Gen. Rules";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Sort Order"; Integer)
        {
            Caption = 'Sort Order';
            ToolTip = 'Specifies the order to look for matches. The smallest value will get looked at first.';
        }
        field(3; Intent; Enum "Qlty. Gen. Rule Intent")
        {
            Caption = 'Intent';
            ToolTip = 'Specifies the intent of this rule. This is used for categorization and to help control the editability of various trigger fields.';
        }
        field(4; "Schedule Group"; Code[20])
        {
            Description = 'Specifies a group which allows a schedule to refer to multiple inspection generation rules.';
            Caption = 'Schedule Group';
            ToolTip = 'Specifies a group which allows a schedule to refer to multiple inspection generation rules.';

            trigger OnValidate()
            var
                QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
            begin
                if xRec."Schedule Group" <> Rec."Schedule Group" then
                    if Rec."Schedule Group" <> '' then begin
                        QltyJobQueueManagement.CheckIfGenerationRuleCanBeScheduled(Rec);
                        Rec.Modify();
                        QltyJobQueueManagement.PromptCreateJobQueueEntryIfMissing(Rec."Schedule Group");
                    end else
                        QltyJobQueueManagement.DeleteJobQueueIfNothingElseIsUsingThisGroup(Rec, xRec."Schedule Group");
            end;
        }
        field(10; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            NotBlank = true;
            TableRelation = "Qlty. Inspection Template Hdr.".Code;
            ToolTip = 'Specifies the Quality Inspection Template to use when the conditions match.';

            trigger OnValidate()
            var
                HeaderQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
            begin
                if HeaderQltyInspectionTemplateHdr.Get("Template Code") then
                    Rec.Description := HeaderQltyInspectionTemplateHdr.Description;

                UpdateSortOrder();
            end;
        }
        field(12; "Source Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table),
                                                                "Object ID" = field("Table ID Filter"));
            ToolTip = 'Specifies the table for this rule. For example for receiving to a purchase line, you would use table 39. For production typically 5409 for Production Order Routing Lines.';

            trigger OnValidate()
            begin
                Rec.CalcFields("Table Caption");
                if xRec."Source Table No." <> Rec."Source Table No." then
                    SetIntentAndDefaultTriggerValuesFromSetup();
            end;
        }
        field(13; "Condition Filter"; Text[400])
        {
            Caption = 'Condition Filter';
            Description = 'Specifies the criteria for defining when to use this template. For example, if you wanted to only use a template for a certain item then you would define that item here.';
            ToolTip = 'Specifies the criteria for defining when to use this template. For example, if you wanted to only use a template for a certain item then you would define that item here.';
        }
        field(14; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies an explanation of this rule.';
        }
        field(15; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("Source Table No.")));
            Caption = 'Table';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the table for this rule. For example for receiving to a purchase line, you would use table 39. For production typically 5409 for Production Order Routing Lines.';
        }
        field(18; "Table ID Filter"; Integer)
        {
            FieldClass = FlowFilter;
            Caption = 'Table ID Filter';
        }
        field(19; "Item Filter"; Text[400])
        {
            Caption = 'Item Filter';
            ToolTip = 'Specifies the item specific criteria for defining when to use this template. ';
        }
        field(20; "Item Attribute Filter"; Text[400])
        {
            Caption = 'Attribute Filter';
            ToolTip = 'Specifies the item attribute specific criteria for defining when to use this template. ';
        }
        field(21; "Activation Trigger"; Enum "Qlty. Gen. Rule Act. Trigger")
        {
            Caption = 'Activation Trigger';
            InitValue = "Manual or Automatic";
            ToolTip = 'Specifies whether the generation rule is active for manually created inspections only, automatically created inspections only, both, or disabled entirely.';
        }
        field(22; "Warehouse Receive Trigger"; Enum "Qlty. Whse. Receive Trigger")
        {
            Caption = 'Warehouse Receive Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a warehouse receive trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Warehouse Receive Trigger" <> Rec."Warehouse Receive Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Warehouse Receive Trigger"));
            end;
        }
        field(23; "Purchase Trigger"; Enum "Qlty. Purchase Trigger")
        {
            Caption = 'Purchase Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a purchase receive trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Purchase Trigger" <> Rec."Purchase Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Purchase Trigger"));
            end;
        }
        field(24; "Sales Return Trigger"; Enum "Qlty. Sales Return Trigger")
        {
            Caption = 'Sales Return Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a sales return receive trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Sales Return Trigger" <> Rec."Sales Return Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Sales Return Trigger"));
            end;
        }
        field(25; "Transfer Trigger"; Enum "Qlty. Transfer Trigger")
        {
            Caption = 'Transfer Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a transfer receive trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Transfer Trigger" <> Rec."Transfer Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Transfer Trigger"));
            end;
        }
        field(26; "Production Trigger"; Enum "Qlty. Production Trigger")
        {
            Caption = 'Production Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a production trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Production Trigger" <> Rec."Production Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Production Trigger"));
            end;
        }
        field(27; "Assembly Trigger"; Enum "Qlty. Assembly Trigger")
        {
            Caption = 'Assembly Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on an assembly trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Assembly Trigger" <> Rec."Assembly Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Assembly Trigger"));
            end;
        }
        field(28; "Warehouse Movement Trigger"; Enum "Qlty. Warehouse Trigger")
        {
            Caption = 'Warehouse Movement Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create inspections based on a warehouse movement trigger.';

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Warehouse Movement Trigger" <> Rec."Warehouse Movement Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledLbl, Rec."Sort Order", Rec."Template Code", Rec."Warehouse Movement Trigger"));
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Sort Order")
        {
        }
        key(Key3; "Sort Order", Intent)
        {
        }
        key(bySearchAndSort; "Template Code", "Source Table No.", "Sort Order")
        {
        }
        key(siftOnSort; "Source Table No.")
        {
        }
        key(byActivation; "Activation Trigger", "Sort Order")
        {
        }
        key(byScheduleGroup; "Template Code", "Schedule Group", Description)
        {
        }
    }

    var
        TriggerNotActiveConfirmQst: Label 'You have set an automatic trigger but the inspection generation rule activation is set to "%1". Do you want to update the activation trigger to "%2?"', Comment = '%1=current activation trigger,%2=proposed activation trigger';
        RuleCurrentlyDisabledLbl: Label 'The generation rule Sort Order %1, Template Code %2 is currently disabled. It will need to have an activation trigger of "Automatic Only" or "Manual or Automatic" before it will be triggered by "%3"', Comment = '%1=generation rule sort order,%2=generation rule template code,%3=auto trigger';
        ChooseTemplateFirstErr: Label 'Please choose the template first.';
        FilterLengthErr: Label 'This filter is too long and must be less than %1 characters.', Comment = '%1=filter string maximum length';

    trigger OnInsert()
    begin
        UpdateSortOrder();
        SetEntryNo();
        SetIntentAndDefaultTriggerValuesFromSetup();
    end;

    trigger OnModify()
    begin
        UpdateSortOrder();
        if (xRec."Source Table No." <> Rec."Source Table No.") or (Rec.Intent = Rec.Intent::Unknown) or not GuiAllowed() then
            SetIntentAndDefaultTriggerValuesFromSetup();
    end;

    internal procedure SetEntryNo()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if Rec."Entry No." = 0 then begin
            QltyInspectionGenRule.SetCurrentKey("Entry No.");
            QltyInspectionGenRule.SetLoadFields("Entry No.");
            if QltyInspectionGenRule.FindLast() then;
            Rec."Entry No." := QltyInspectionGenRule."Entry No." + 1;
        end;
    end;

    internal procedure UpdateSortOrder()
    var
        FindHighestQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if (Rec."Sort Order" = 0) or (Rec."Sort Order" = 1) then begin
            FindHighestQltyInspectionGenRule.SetCurrentKey("Sort Order");
            FindHighestQltyInspectionGenRule.Ascending(false);
            if FindHighestQltyInspectionGenRule.FindFirst() then;
            Rec."Sort Order" := FindHighestQltyInspectionGenRule."Sort Order" + 10;
        end;
    end;

    internal procedure HandleOnAssistEditSourceTable()
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
        Filter: Text;
    begin
        if Rec."Template Code" = '' then
            Error(ChooseTemplateFirstErr);
        if IsNullGuid(Rec.SystemId) and not Rec.IsTemporary() then
            Rec.Insert();
        Filter := QltyInspecGenRuleMgmt.GetFilterForAvailableConfigurations();
        QltyFilterHelpers.RunModalLookupTable(Rec."Source Table No.", Filter);
        Rec.CalcFields("Table Caption");
        Rec.Validate("Source Table No.");
    end;

    /// <summary>
    /// Provides the ability to assist edit a condition filter.
    /// </summary>
    /// <returns></returns>
    procedure AssistEditConditionTableFilter() Result: Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        Value: Text;
    begin
        Value := Rec."Condition Filter";
        if QltyFilterHelpers.BuildFilter(Rec."Source Table No.", true, Value) then begin
            if (Value <> Rec."Condition Filter") and (Value <> '') then begin
                Rec."Condition Filter" := CopyStr(Value, 1, MaxStrLen(Rec."Condition Filter"));
                if StrLen(Value) > MaxStrLen(Rec."Condition Filter") then
                    Error(FilterLengthErr, MaxStrLen(Rec."Condition Filter"));
            end;
            Result := true;
        end;
    end;

    /// <summary>
    /// Provides the ability to assist edit an item filter.
    /// </summary>
    /// <returns></returns>
    procedure AssistEditConditionItemFilter() Result: Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        Value: Text;
    begin
        Value := Rec."Item Filter";
        if QltyFilterHelpers.BuildFilter(Database::Item, true, Value) then begin
            if (Value <> Rec."Item Filter") and (Value <> '') then begin
                Rec."Item Filter" := CopyStr(Value, 1, MaxStrLen(Rec."Item Filter"));
                if StrLen(Value) > MaxStrLen(Rec."Item Filter") then
                    Error(FilterLengthErr, MaxStrLen(Rec."Item Filter"));
            end;
            Result := true;
        end;
    end;

    /// <summary>
    /// Provides the ability to assist edit an attribute filter.
    /// </summary>
    procedure AssistEditConditionAttributeFilter()
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.BuildItemAttributeFilter400(Rec."Item Attribute Filter");
    end;

    /// <summary>
    /// Gets the template code from either the selected record, or the filter.
    /// </summary>
    /// <param name="OnlyFilters"></param>
    /// <returns></returns>
    procedure GetTemplateCodeFromRecordOrFilter(OnlyFilters: Boolean) TemplateCode: Code[20]
    var
        FilterGroupIterator: Integer;
    begin
        if (not OnlyFilters) and (Rec."Template Code" <> '') then
            exit(Rec."Template Code");
        FilterGroupIterator := 4;
        repeat
            Rec.FilterGroup(FilterGroupIterator);
            if Rec.GetFilter("Template Code") <> '' then
                TemplateCode := Rec.GetRangeMin("Template Code");

            FilterGroupIterator -= 1;
        until (FilterGroupIterator < 0) or (TemplateCode <> '');
        Rec.FilterGroup(0);
    end;

    /// <summary>
    /// Sets the default automatic inspection creation triggers for generation rules based on the values set in Quality Management Setup
    /// </summary>
    procedure SetIntentAndDefaultTriggerValuesFromSetup()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        InferredIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        if not TryInferGenerationRuleIntent(InferredIntent, Certainty) then
            exit;

        if (InferredIntent = InferredIntent::Unknown) or (InferredIntent = Rec.Intent) then
            exit;

        if not QltyManagementSetup.Get() then
            exit;
        if Certainty = Certainty::Yes then begin
            Rec.Intent := InferredIntent;
            SetDefaultTriggerValuesToNoTrigger();
            if Rec."Activation Trigger" in [Rec."Activation Trigger"::"Manual or Automatic", Rec."Activation Trigger"::"Automatic only"] then
                case InferredIntent of
                    InferredIntent::Assembly:
                        Rec."Assembly Trigger" := QltyManagementSetup."Assembly Trigger";
                    InferredIntent::Production:
                        Rec."Production Trigger" := QltyManagementSetup."Production Trigger";
                    InferredIntent::Purchase:
                        Rec."Purchase Trigger" := QltyManagementSetup."Purchase Trigger";
                    InferredIntent::"Sales Return":
                        Rec."Sales Return Trigger" := QltyManagementSetup."Sales Return Trigger";
                    InferredIntent::Transfer:
                        Rec."Transfer Trigger" := QltyManagementSetup."Transfer Trigger";
                    InferredIntent::"Warehouse Movement":
                        Rec."Warehouse Movement Trigger" := QltyManagementSetup."Warehouse Trigger";
                    InferredIntent::"Warehouse Receipt":
                        Rec."Warehouse Receive Trigger" := QltyManagementSetup."Warehouse Receive Trigger";
                end;
        end;
    end;

    local procedure ConfirmUpdateManualTriggerStatus()
    begin
        if (Rec."Activation Trigger" = Rec."Activation Trigger"::"Manual only") and GuiAllowed() then
            if not ((Rec."Assembly Trigger" = Rec."Assembly Trigger"::NoTrigger) and (Rec."Transfer Trigger" = Rec."Transfer Trigger"::NoTrigger) and
               (Rec."Production Trigger" = Rec."Production Trigger"::NoTrigger) and (Rec."Purchase Trigger" = Rec."Purchase Trigger"::NoTrigger) and
               (Rec."Sales Return Trigger" = Rec."Sales Return Trigger"::NoTrigger) and (Rec."Warehouse Receive Trigger" = Rec."Warehouse Receive Trigger"::NoTrigger) and
               (Rec."Warehouse Movement Trigger" = Rec."Warehouse Movement Trigger"::NoTrigger))
            then
                if Confirm(StrSubstNo(TriggerNotActiveConfirmQst, Rec."Activation Trigger", Rec."Activation Trigger"::"Manual or Automatic")) then
                    Rec."Activation Trigger" := Rec."Activation Trigger"::"Manual or Automatic";
    end;

    local procedure SetDefaultTriggerValuesToNoTrigger()
    begin
        Rec."Warehouse Receive Trigger" := Rec."Warehouse Receive Trigger"::NoTrigger;
        Rec."Purchase Trigger" := Rec."Purchase Trigger"::NoTrigger;
        Rec."Sales Return Trigger" := Rec."Sales Return Trigger"::NoTrigger;
        Rec."Transfer Trigger" := Rec."Transfer Trigger"::NoTrigger;
        Rec."Production Trigger" := Rec."Production Trigger"::NoTrigger;
        Rec."Assembly Trigger" := Rec."Assembly Trigger"::NoTrigger;
        Rec."Warehouse Movement Trigger" := Rec."Warehouse Movement Trigger"::NoTrigger;
    end;

    [TryFunction]
    procedure TryInferGenerationRuleIntent(var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        InferGenerationRuleIntent(QltyGenRuleIntent, QltyCertainty);
    end;

    /// <summary>
    /// Gets the intent of the generation rule if it can be determined
    /// </summary>
    /// <param name="QltyGenRuleIntent">intent of the rule</param>
    /// <param name="QltyCertainty">if it is certain (yes), likely (maybe)</param>
    procedure InferGenerationRuleIntent(var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        case Rec."Source Table No." of
            Database::"Warehouse Receipt Line":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Receipt";
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Warehouse Entry":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Movement";
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Purchase Line":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Purchase;
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Sales Line":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::"Sales Return";
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Transfer Line", Database::"Transfer Receipt Line":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Transfer;
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Prod. Order Routing Line", Database::"Prod. Order Line", Database::"Production Order":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Production;
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Posted Assembly Header", Database::"Assembly Line":
                begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Assembly;
                    QltyCertainty := QltyCertainty::Yes;
                end;
            Database::"Item Journal Line":
                if GetIsProductionIntent() then begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Production;
                    QltyCertainty := QltyCertainty::Yes;
                end else
                    if InferItemJournalIntentFromConditionFilter(QltyGenRuleIntent) then
                        QltyCertainty := QltyCertainty::Yes
                    else
                        if GetIsOnlyAutoTriggerInSetup(QltyGenRuleIntent::Production) then begin
                            QltyGenRuleIntent := QltyGenRuleIntent::Production;
                            QltyCertainty := QltyCertainty::Maybe;
                        end;
            Database::"Item Ledger Entry":
                if GetIsProductionIntent() then begin
                    QltyGenRuleIntent := QltyGenRuleIntent::Production;
                    QltyCertainty := QltyCertainty::Yes;
                end else
                    if InferItemLedgerIntentFromConditionFilter(QltyGenRuleIntent) then
                        QltyCertainty := QltyCertainty::Yes
                    else
                        if GetIsOnlyAutoTriggerInSetup(QltyGenRuleIntent::Production) then begin
                            QltyGenRuleIntent := QltyGenRuleIntent::Production;
                            QltyCertainty := QltyCertainty::Maybe;
                        end;
            Database::"Warehouse Journal Line":
                case true of
                    InferIsWarehouseReceiveIntentFromCondition():
                        begin
                            QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Receipt";
                            QltyCertainty := QltyCertainty::Yes;
                            exit;
                        end;
                    InferIsWarehouseMoveIntentFromCondition():
                        begin
                            QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Movement";
                            QltyCertainty := QltyCertainty::Yes;
                            exit;
                        end;
                    GetIsOnlyAutoTriggerInSetup(QltyGenRuleIntent::"Warehouse Receipt"):
                        begin
                            QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Receipt";
                            QltyCertainty := QltyCertainty::Maybe;
                            exit;
                        end;
                    GetIsOnlyAutoTriggerInSetup(QltyGenRuleIntent::"Warehouse Movement"):
                        begin
                            QltyGenRuleIntent := QltyGenRuleIntent::"Warehouse Movement";
                            QltyCertainty := QltyCertainty::Maybe;
                        end;
                end;
        end;
    end;

    /// <summary>
    /// Purpose is to help determine if the line is intended to be used for production based
    /// on the table number and filter.
    /// </summary>
    /// <returns></returns>
    local procedure GetIsProductionIntent(): Boolean
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if Rec."Source Table No." = 0 then
            exit(false);

        if Rec."Condition Filter" = '' then
            exit(false);

        case Rec."Source Table No." of
            Database::"Prod. Order Routing Line",
            Database::"Prod. Order Line",
            Database::"Production Order":
                exit(true);
            Database::"Item Ledger Entry":
                if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::Output) then
                    exit(true)
                else
                    if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Order Type"), TempItemLedgerEntry."Order Type"::Production) then
                        exit(true);
            Database::"Item Journal Line":
                if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Entry Type"), TempItemJournalLine."Entry Type"::Output) then
                    exit(true)
                else
                    if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Order Type"), TempItemJournalLine."Order Type"::Production) then
                        exit(true);
        end;
    end;

    local procedure InferIsWarehouseReceiveIntentFromCondition(): Boolean
    var
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if (Rec."Source Table No." = Database::"Warehouse Journal Line") and (Rec."Condition Filter" <> '') then
            if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempWarehouseJournalLine.FieldNo("Whse. Document Type"), TempWarehouseJournalLine."Whse. Document Type"::Receipt) then
                exit(true)
            else
                if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempWarehouseJournalLine.FieldNo("Reference Document"), TempWarehouseJournalLine."Reference Document"::"Posted Rcpt.") then
                    exit(true);
    end;

    local procedure InferIsWarehouseMoveIntentFromCondition(): Boolean
    var
        TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if (Rec."Source Table No." = Database::"Warehouse Journal Line") and (Rec."Condition Filter" <> '') then begin
            if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempWarehouseJournalLine.FieldNo("Whse. Document Type"), TempWarehouseJournalLine."Whse. Document Type"::"Internal Put-away") then
                exit(true);
            if QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempWarehouseJournalLine.FieldNo("Entry Type"), Format(TempWarehouseJournalLine."Entry Type"::Movement)) then
                exit(true);
        end;
    end;

    local procedure InferItemJournalIntentFromConditionFilter(var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"): Boolean
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if (Rec."Source Table No." = Database::"Item Journal Line") and (Rec."Condition Filter" <> '') then
            case true of
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Document Type"), TempItemJournalLine."Document Type"::"Purchase Receipt"):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Purchase;
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Document Type"), TempItemJournalLine."Document Type"::"Sales Return Receipt"):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::"Sales Return";
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Document Type"), TempItemJournalLine."Document Type"::"Transfer Receipt"):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Transfer;
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemJournalLine.FieldNo("Document Type"), TempItemJournalLine."Document Type"::"Direct Transfer"):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Transfer;
                        exit(true);
                    end;
                else
                    exit(false);
            end;
    end;

    local procedure InferItemLedgerIntentFromConditionFilter(var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"): Boolean
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        if (Rec."Source Table No." = Database::"Item Ledger Entry") and (Rec."Condition Filter" <> '') then
            case true of
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::Purchase):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Purchase;
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::Sale):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::"Sales Return";
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::Transfer):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Transfer;
                        exit(true);
                    end;
                QltyFilterHelpers.GetIsFilterSetToValue(Rec."Source Table No.", Rec."Condition Filter", TempItemLedgerEntry.FieldNo("Entry Type"), TempItemLedgerEntry."Entry Type"::"Assembly Output"):
                    begin
                        QltyGenRuleIntent := QltyGenRuleIntent::Assembly;
                        exit(true);
                    end;
                else
                    exit(false);
            end;
    end;

    local procedure GetIsOnlyAutoTriggerInSetup(IntentToCheck: Enum "Qlty. Gen. Rule Intent"): Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TriggerCount: Integer;
        IntentSet: Boolean;
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        if QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Purchase then
                IntentSet := true;
        end;
        if QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::"Sales Return" then
                IntentSet := true;
        end;
        if QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::"Warehouse Receipt" then
                IntentSet := true;
        end;
        if QltyManagementSetup."Warehouse Trigger" <> QltyManagementSetup."Warehouse Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::"Warehouse Movement" then
                IntentSet := true;
        end;
        if QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Transfer then
                IntentSet := true;
        end;
        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Production then
                IntentSet := true;
        end;
        if QltyManagementSetup."Assembly Trigger" <> QltyManagementSetup."Assembly Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Assembly then
                IntentSet := true;
        end;

        exit((TriggerCount = 1) and IntentSet);
    end;
}
