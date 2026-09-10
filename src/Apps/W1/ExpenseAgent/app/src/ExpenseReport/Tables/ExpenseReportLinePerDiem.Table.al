// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using System.Environment.Configuration;

table 6909 "Expense Report Line Per Diem"
{
    Access = Internal;
    Caption = 'Expense Report Line Per Diem';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Report Line Per Diems";
    ReplicateData = false;

    fields
    {
        field(1; "Expense Report No."; Code[20])
        {
            Caption = 'Expense Report No.';
            TableRelation = "Expense Report Header"."No.";
        }
        field(2; "Expense Report Line No."; Integer)
        {
            Caption = 'Expense Report Line No.';
            TableRelation = "Expense Report Line"."Line No." where("Document No." = field("Expense Report No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
        }
        field(8; "Expense Location"; Code[30])
        {
            Caption = 'Expense Location';
        }
        field(9; "Description"; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();
            end;
        }
        field(10; "Date"; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();
            end;
        }
        field(11; "Breakfast"; Boolean)
        {
            Caption = 'Breakfast';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                if Rec.Breakfast <> xRec.Breakfast then
                    UpdateAmountReduction();
            end;
        }
        field(12; "Lunch"; Boolean)
        {
            Caption = 'Lunch';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                if Rec.Lunch <> xRec.Lunch then
                    UpdateAmountReduction();
            end;
        }
        field(13; "Dinner"; Boolean)
        {
            Caption = 'Dinner';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                if Rec.Dinner <> xRec.Dinner then
                    UpdateAmountReduction();
            end;
        }
        field(14; "Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Per Diem Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();
            end;
        }
        field(15; "Original Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Original Per Diem Amount';
            Editable = false;
        }
        field(16; "Breakfast Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Breakfast Reduction Percent';
            Editable = false;
        }
        field(17; "Lunch Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Lunch Reduction Percent';
            Editable = false;
        }
        field(18; "Dinner Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Dinner Reduction Percent';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Expense Report No.");
        TestField("Expense Report Line No.");
        TestField("Line No.");

        UpdateExpenseReportLineInformation("Expense Report No.", "Expense Report Line No.");

        InvalidateParentPolicy();
    end;

    trigger OnModify()
    begin
        InvalidateParentPolicy();
    end;

    trigger OnDelete()
    begin
        TestStatusOpenOfExpenseReport();

        UpdateTotalOnExpense(Rec."Line No.");

        InvalidateParentPolicy();
    end;

    var
        ExpenseCurrency: Record Currency;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHelper: Codeunit "Expense Report";
        ExpenseReportLocationMissingMsg: Label '%1 is missing in Expense Report No. %2, Line No. %3.', Comment = '%1 = Expense Location Caption, %2 = Expense Report No., %3 = Line No.';
        TotalReductionPercentExceededErr: Label 'Total Reduction Percent cannot exceed 100.';

    local procedure InvalidateParentPolicy()
    var
        ParentExpenseReportLine: Record "Expense Report Line";
    begin
        if ParentExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
            ParentExpenseReportLine.InvalidatePolicyEvaluation();
    end;

    local procedure UpdateExpenseReportLineInformation(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer)
    begin
        ExpenseReportLine := ExpenseReportHelper.GetExpenseReportLine(ExpenseReportNo, ExpenseReportLineNo);

        Rec.Validate("Expense No.", ExpenseReportLine."Expense No.");
        Rec.Validate("Expense Category Code", ExpenseReportLine."Expense Category");
        Rec.Validate("Expense Subcategory Code", ExpenseReportLine."Expense Subcategory Code");
        Rec.Validate("Expense Location", ExpenseReportLine."Expense Location");
    end;

    local procedure UpdateAmountReduction()
    var
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        InitializeRoundingPrecision();

        CalculatedPerDiemAmount := Rec."Original Per Diem Amount";
        Rec."Per Diem Amount" := CalculatedPerDiemAmount;

        if CalculatedPerDiemAmount = 0 then begin
            UpdateTotalOnExpense(0);
            exit;
        end;

        if Rec.Breakfast then
            TotalReductionPercent += Rec."Breakfast Reduction Percent";
        if Rec.Lunch then
            TotalReductionPercent += Rec."Lunch Reduction Percent";
        if Rec.Dinner then
            TotalReductionPercent += Rec."Dinner Reduction Percent";

        if TotalReductionPercent > 100 then
            Error(TotalReductionPercentExceededErr);

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (Rec."Original Per Diem Amount" * TotalReductionPercent / 100);

        Rec."Per Diem Amount" := Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision");
        Modify();
        UpdateTotalOnExpense(0);
    end;

    local procedure UpdateTotalOnExpense(ExcludeLineNo: Integer)
    var
        ExpReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", Rec."Expense Report No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", Rec."Expense Report Line No.");
        if ExcludeLineNo <> 0 then
            ExpenseReportLinePerDiem.SetFilter("Line No.", '<>%1', ExcludeLineNo);

        if not ExpenseReportLinePerDiem.IsEmpty() then
            ExpenseReportLinePerDiem.CalcSums("Per Diem Amount");

        ExpReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.");
        ExpReportLine.TestStatusOpen();

        ExpReportLine.Amount := ExpenseReportLinePerDiem."Per Diem Amount";
        ExpReportLine.UpdateAmounts();
        ExpReportLine.Modify();
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpReportLine);
    end;

    local procedure TestStatusOpenOfExpenseReport()
    var
        ExpReportLine: Record "Expense Report Line";
    begin
        ExpReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.");

        ExpReportLine.TestStatusOpen();
    end;

    local procedure InitializeRoundingPrecision()
    begin
        ExpenseReportLine := ExpenseReportHelper.GetExpenseReportLine(Rec."Expense Report No.", Rec."Expense Report Line No.");

        if ExpenseReportLine."Expense Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(ExpenseReportLine."Expense Currency Code");
    end;

    procedure SendMissingExpenseLocationNotification(ExpReportLine: Record "Expense Report Line")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetMissingExpenseLocationNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message(StrSubstNo(ExpenseReportLocationMissingMsg, ExpReportLine.FieldCaption("Expense Location"), ExpReportLine."Document No.", ExpReportLine."Line No."));
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    local procedure GetMissingExpenseLocationNotificationID(): Guid
    begin
        exit('a6c07617-1a15-4b86-b4d0-ae5c2e4e1b3e');
    end;
}