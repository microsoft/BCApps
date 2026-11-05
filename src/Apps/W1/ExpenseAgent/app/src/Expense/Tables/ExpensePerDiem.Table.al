// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using System.Environment.Configuration;

table 6905 "Expense Per Diem"
{
    Access = Internal;
    Caption = 'Per Diem Expense';
    DataClassification = CustomerContent;
    LookupPageId = "Per Diem Expenses";
    ReplicateData = false;

    fields
    {
        field(1; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";

            trigger OnValidate()
            begin
                if "Expense No." <> xRec."Expense No." then
                    CheckForExpenseReportAssociation(Rec.FieldCaption("Expense No."));

                UpdateExpenseInformation("Expense No.");
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category".Code where(Inactive = const(false));
        }
        field(5; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category Code"), Inactive = const(false));
        }
        field(6; "Expense Location"; Code[30])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location"."No.";
        }
        field(7; "Description"; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();
            end;
        }
        field(8; "Date"; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();
            end;
        }
        field(9; "Breakfast"; Boolean)
        {
            Caption = 'Breakfast';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                if Rec.Breakfast <> xRec.Breakfast then
                    UpdateAmountReduction();
            end;
        }
        field(10; "Lunch"; Boolean)
        {
            Caption = 'Lunch';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                if Rec.Lunch <> xRec.Lunch then
                    UpdateAmountReduction();
            end;
        }
        field(11; "Dinner"; Boolean)
        {
            Caption = 'Dinner';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                if Rec.Dinner <> xRec.Dinner then
                    UpdateAmountReduction();
            end;
        }
        field(12; "Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Per Diem Amount';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();
            end;
        }
        field(13; "Original Per Diem Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Original Per Diem Amount';
            Editable = false;
        }
        field(14; "Breakfast Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Breakfast Reduction Percent';
            Editable = false;
        }
        field(15; "Lunch Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Lunch Reduction Percent';
            Editable = false;
        }
        field(16; "Dinner Reduction Percent"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Dinner Reduction Percent';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        TestStatusOpenOfExpense();

        Expense.Get(Rec."Expense No.");
        if Expense."Expense Report No." <> '' then
            Error(CannotDeleteWithExpenseReportErr, Expense."Expense User No.", Rec."Expense No.", Rec."Line No.");

        UpdateTotalOnExpense(Rec."Line No.");
    end;

    var
        ExpenseCurrency: Record Currency;
        Expense: Record Expense;
        ExpenseHelper: Codeunit "Expense Currency";
        CannotDeleteWithExpenseReportErr: Label 'You cannot delete per diem entry %1 %2 %3 because it has been copied to expense report lines.', Comment = '%1 = Expense User No., %2 = Expense No., %3 = Line No.';
        CannotModifyWithExpenseReportErr: Label 'You cannot modify %1 field of per diem entry %2 %3 because it has been copied to expense report lines.', Comment = '%1 = Field Name, %2 = Expense No., %3 = Line No.';
        ExpenseLocationMissingMsg: Label '%1 is missing in Expense No. %2.', Comment = '%1 = Expense Location Caption, %2 = Expense No.';
        TotalReductionPercentExceededErr: Label 'Total Reduction Percent cannot exceed 100.';

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
        ExpenseRecord: Record Expense;
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpensePerDiem.SetRange("Expense No.", Rec."Expense No.");
        if ExcludeLineNo <> 0 then
            ExpensePerDiem.SetFilter("Line No.", '<>%1', ExcludeLineNo);

        if not ExpensePerDiem.IsEmpty() then
            ExpensePerDiem.CalcSums("Per Diem Amount");

        ExpenseRecord.Get(Rec."Expense No.");
        ExpenseRecord.TestStatusOpen();

        ExpenseRecord.Amount := ExpensePerDiem."Per Diem Amount";
        ExpenseRecord.UpdateAmount();
        ExpenseRecord.Modify();
        ExpenseRuleValidation.ValidateExpenseAgainstRule(ExpenseRecord);
    end;

    local procedure UpdateExpenseInformation(ExpenseNo: Code[20])
    begin
        Expense := ExpenseHelper.GetExpense(ExpenseNo);
        Expense.CheckExpensePrerequisitesBeforeUsing();

        Rec.Validate("Expense Category Code", Expense."Expense Category");
        Rec.Validate("Expense Subcategory Code", Expense."Expense Subcategory");
        Rec.Validate("Expense Location", Expense."Expense Location");
    end;

    local procedure CheckForExpenseReportAssociation(FieldName: Text)
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Line No.", Rec."Line No.");
        ExpenseReportLinePerDiem.SetFilter("Expense Report No.", '<>%1', '');
        if not ExpenseReportLinePerDiem.IsEmpty() then
            Error(CannotModifyWithExpenseReportErr, FieldName, Rec."Expense No.", Rec."Line No.");
    end;

    local procedure TestStatusOpenOfExpense()
    var
        ExpenseRecord: Record Expense;
    begin
        ExpenseRecord.SetLoadFields(Status);
        ExpenseRecord.Get("Expense No.");

        ExpenseRecord.TestStatusOpen();
    end;

    local procedure InitializeRoundingPrecision()
    begin
        Expense := ExpenseHelper.GetExpense(Rec."Expense No.");

        if Expense."Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(Expense."Currency Code");
    end;

    procedure SendMissingExpenseLocationNotification(ExpenseRecord: Record Expense)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetMissingExpenseLocationNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message(StrSubstNo(ExpenseLocationMissingMsg, ExpenseRecord.FieldCaption("Expense Location"), ExpenseRecord."No."));
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    local procedure GetMissingExpenseLocationNotificationID(): Guid
    begin
        exit('2ba7b836-43c5-40be-9555-aec25bcc809c');
    end;
}
