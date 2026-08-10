// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.UOM;

table 6927 "Expense Rule Header"
{
    Access = Internal;
    Caption = 'Expense Rule Header';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category";
            NotBlank = true;
        }
        field(2; "Expense Location"; Code[20])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location";

            trigger OnValidate()
            var
                ExpenseCategory: Record "Expense Category";
            begin
                ExpenseCategory.Get(Rec."Expense Category Code");

                if Rec."Expense Location" <> '' then
                    if not (ExpenseCategory."Expense Detail Required" = ExpenseCategory."Expense Detail Required"::"Per Diem") then
                        Error(
                            ExpenseDetailRequiredMustBePerDiemErr,
                            ExpenseCategory.FieldCaption("Expense Detail Required"),
                            ExpenseCategory."Expense Detail Required"::"Per Diem",
                            ExpenseCategory.TableCaption(),
                            Rec."Expense Category Code",
                            Rec.FieldCaption("Expense Location"),
                            Rec."Expense Location");
            end;
        }
        field(3; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
        }
        field(30; "Justification Required"; Enum "Expense Justification")
        {
            Caption = 'Justification Required';
        }
        field(40; "Required Specific Merchant"; Boolean)
        {
            Caption = 'Required Specific Merchant';
        }
        field(41; "Specific Merchant Name"; Text[100])
        {
            Caption = 'Specific Merchant Name';
        }
        field(60; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(61; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
    }

    keys
    {
        key(PK; "Expense Category Code", "Expense Location", "Effective Date")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        CheckRuleIsAppliedOnExpenseOrExpenseReportLine(Rec.SystemId);
        DeleteRelatedConditions();
    end;

    trigger OnRename()
    begin
        CheckRuleIsAppliedOnExpenseOrExpenseReportLine(Rec.SystemId);
        RenameRelatedConditions();
    end;

    var
        ExpenseDetailRequiredMustBePerDiemErr: Label '%1 must be set to %2 in %3 %4 to create an Expense Rule for %5 %6.',
                                                     Comment = '%1 = Field Caption, %2 = Field Value, %3 = Table Caption, %4 = Expense Category Code, %5 = Field Caption, %6 = Expense Location';
        ExpenseRuleAppliedErr: Label 'You cannot delete or rename this %1 because it has been applied to at least one %2 or %3.', Comment = '%1 = Expense Rule Header table caption, %2 = Expense table caption, %3 = Expense Report Line table caption';

    procedure FindApplicableRule(ExpenseReportLine: Record "Expense Report Line"): Boolean
    begin
        Rec.SetRange("Expense Category Code", ExpenseReportLine."Expense Category");
        Rec.SetRange("Expense Location", ExpenseReportLine."Expense Location");
        Rec.SetFilter("Effective Date", '<=%1|%2', ExpenseReportLine."Expense Date", 0D);
        if Rec.FindLast() then
            exit(true);

        exit(false);
    end;

    procedure FindApplicableRule(Expense: Record Expense): Boolean
    begin
        Rec.SetRange("Expense Category Code", Expense."Expense Category");
        Rec.SetRange("Expense Location", Expense."Expense Location");
        Rec.SetFilter("Effective Date", '<=%1|%2', Expense."Expense Date", 0D);
        if Rec.FindLast() then
            exit(true);

        exit(false);
    end;

    local procedure CheckRuleIsAppliedOnExpenseOrExpenseReportLine(RuleSystemId: Guid)
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Expense.SetRange("Applied Rule Id", RuleSystemId);
        if not Expense.IsEmpty() then
            Error(ExpenseRuleAppliedErr, Rec.TableCaption(), Expense.TableCaption(), ExpenseReportLine.TableCaption());

        ExpenseReportLine.SetRange("Applied Rule Id", RuleSystemId);
        if not ExpenseReportLine.IsEmpty() then
            Error(ExpenseRuleAppliedErr, Rec.TableCaption(), Expense.TableCaption(), ExpenseReportLine.TableCaption());
    end;

    local procedure DeleteRelatedConditions()
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        ExpenseRuleCondition.SetRange("Expense Category Code", "Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", "Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", "Effective Date");
        ExpenseRuleCondition.DeleteAll(true);
    end;

    local procedure RenameRelatedConditions()
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        if (Rec."Expense Category Code" = xRec."Expense Category Code") and
           (Rec."Expense Location" = xRec."Expense Location") and
           (Rec."Effective Date" = xRec."Effective Date")
        then
            exit;

        ExpenseRuleCondition.SetRange("Expense Category Code", xRec."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", xRec."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", xRec."Effective Date");
        while ExpenseRuleCondition.FindFirst() do
            ExpenseRuleCondition.Rename(Rec."Expense Category Code", Rec."Expense Location", Rec."Effective Date", ExpenseRuleCondition."Line No.");
    end;
}