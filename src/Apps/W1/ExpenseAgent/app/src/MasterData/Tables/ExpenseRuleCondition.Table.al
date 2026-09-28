// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6926 "Expense Rule Condition"
{
    Access = Internal;
    Caption = 'Expense Rule Condition';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category";
        }
        field(2; "Expense Location"; Code[20])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location";
        }
        field(3; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Condition Type"; Enum "Expense Rule Condition Type")
        {
            Caption = 'Condition Type';

            trigger OnValidate()
            begin
                CheckConditionType();
            end;
        }
        field(20; "Value"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value';
            DecimalPlaces = 2 : 5;
        }
    }

    keys
    {
        key(PK; "Expense Category Code", "Expense Location", "Effective Date", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnRename()
    begin
        CheckConditionTypeForPerDiem();
    end;

    var
        PerDiemOnlyDailyRateErr: Label 'You can''t set %1 to %2 for the %3 %4. Because this expense category requires Per Diem details, %1 must be %5.', Comment = '%1 = Condition Type field caption, %2 = Condition Type value entered, %3 = Expense Category Code field caption, %4 = Expense Category Code value, %5 = Daily Rate condition type';
        DuplicateConditionTypeErr: Label '%1 %2 already exists for %3 %4, %5 %6, and %7 %8. %1 must be unique for each expense rule.', Comment = '%1 = Condition Type field caption, %2 = Condition Type value, %3 = Expense Category Code field caption, %4 = Expense Category Code value, %5 = Expense Location field caption, %6 = Expense Location value, %7 = Effective Date field caption, %8 = Effective Date value';

    local procedure CheckConditionType()
    begin
        CheckConditionTypeForPerDiem();
        CheckConditionTypeMustBeUnique();
    end;

    local procedure CheckConditionTypeForPerDiem()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if Rec."Condition Type" in [Rec."Condition Type"::" ", Rec."Condition Type"::"Daily Rate"] then
            exit;

        ExpenseCategory.Get(Rec."Expense Category Code");
        if ExpenseCategory."Expense Detail Required" = ExpenseCategory."Expense Detail Required"::"Per Diem" then
            Error(
                PerDiemOnlyDailyRateErr,
                Rec.FieldCaption("Condition Type"),
                Rec."Condition Type",
                Rec.FieldCaption("Expense Category Code"),
                Rec."Expense Category Code",
                Rec."Condition Type"::"Daily Rate");
    end;

    local procedure CheckConditionTypeMustBeUnique()
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        if Rec."Condition Type" = Rec."Condition Type"::" " then
            exit;

        ExpenseRuleCondition.SetRange("Expense Category Code", Rec."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", Rec."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", Rec."Effective Date");
        ExpenseRuleCondition.SetRange("Condition Type", Rec."Condition Type");
        if not ExpenseRuleCondition.IsEmpty() then
            Error(
                DuplicateConditionTypeErr,
                Rec.FieldCaption("Condition Type"),
                Rec."Condition Type",
                Rec.FieldCaption("Expense Category Code"),
                Rec."Expense Category Code",
                Rec.FieldCaption("Expense Location"),
                Rec."Expense Location",
                Rec.FieldCaption("Effective Date"),
                Rec."Effective Date");
    end;
}