// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

table 6902 "Expense Itemization"
{
    Access = Internal;
    Caption = 'Expense Itemization';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Itemizations";
    ReplicateData = false;

    fields
    {
        field(1; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = "Currency";
            Editable = false;
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

            trigger OnValidate()
            var
                ExpenseSubCategory: Record "Expense Subcategory";
            begin
                TestStatusOpenOfExpense();

                if xRec."Expense Subcategory Code" <> Rec."Expense Subcategory Code" then begin
                    Rec.Refundable := false;

                    if Rec."Expense Subcategory Code" <> '' then begin
                        ExpenseSubCategory.Get(Rec."Expense Category Code", Rec."Expense Subcategory Code");

                        Rec.Description := ExpenseSubCategory."Posting Description";
                        Rec.Refundable := ExpenseSubCategory.Refundable;

                        UpdateItemizationInformationOnExpense(false);
                    end else begin
                        Rec.Description := '';
                        Rec."Start Date" := 0D;
                        Rec."Quantity" := 1;
                        Rec.Validate("Daily Rate", 0);
                    end;
                end;
            end;
        }
        field(6; "Description"; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();
            end;
        }
        field(7; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();
            end;
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
            InitValue = 1;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpense();

                Rec.Validate("Amount", Quantity * "Daily Rate");
            end;
        }
        field(9; "Daily Rate"; Decimal)
        {
            Caption = 'Daily Rate';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            var
                Expense: Record Expense;
            begin
                TestStatusOpenOfExpense();

                if Rec."Daily Rate" <> 0 then begin
                    Expense.Get(Rec."Expense No.");
                    if not Expense.IsEnforcedItemizationRequired() then
                        Rec.TestField("Expense Subcategory Code");
                end;
                Rec."Daily Rate" := RoundAmount(Rec."Daily Rate");

                Rec.Validate("Amount", Quantity * "Daily Rate");
            end;
        }
        field(10; "Amount"; Decimal)
        {
            Caption = 'Amount';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                Rec.Amount := RoundAmount(Rec.Amount);
                if Rec.Amount <> xRec.Amount then
                    UpdateItemizationInformationOnExpense(false);
            end;
        }
        field(11; "Refundable"; Boolean)
        {
            Caption = 'Refundable';
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

    trigger OnInsert()
    begin
        Expense.Get("Expense No.");
        if not Expense.IsItemizationRequired() then
            Error(CannotAddItemizationErr, Expense."No.");

        Rec.TestField("Expense No.");
        Rec.TestField("Expense Category Code");
        if not Expense.IsEnforcedItemizationRequired() then
            Rec.TestField("Expense Subcategory Code");

        "Currency Code" := Expense."Currency Code";
        "Expense Category Code" := Expense."Expense Category";
        if Description = '' then
            Description := Expense.Description;
    end;

    trigger OnModify()
    begin
        Expense.Get(Rec."Expense No.");
        if not Expense.IsEnforcedItemizationRequired() then
            Rec.TestField("Expense Subcategory Code");
    end;

    trigger OnDelete()
    begin
        TestStatusOpenOfExpense();

        UpdateItemizationInformationOnExpense(true);
    end;

    var
        Expense: Record Expense;
        Currency: Record Currency;
        CannotAddItemizationErr: Label 'Cannot add Itemizations to Expense No. %1 as there is no applicable Expense Rule that requires itemizations.', Comment = '%1 - Expense No.';

    local procedure RoundAmount(CurrAmount: Decimal): Decimal
    begin
        Currency.Initialize(Rec."Currency Code");
        exit(Round(CurrAmount, Currency."Amount Rounding Precision"));
    end;

    local procedure UpdateItemizationInformationOnExpense(CalledFromDelete: Boolean)
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        Expense.Get(Rec."Expense No.");
        if Expense.IsEnforcedItemizationRequired() then
            exit;

        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        ExpenseItemization.SetFilter("Line No.", '<>%1', Rec."Line No.");
        ExpenseItemization.SetRange(Refundable, false);
        ExpenseItemization.CalcSums(Amount);

        Expense."Non-Refundable Amount" := ExpenseItemization.Amount;
        if not CalledFromDelete then
            if not Rec.Refundable then
                Expense."Non-Refundable Amount" += Rec.Amount;

        Expense.UpdateAmount();
        Expense.Modify();
    end;

    local procedure TestStatusOpenOfExpense()
    var
        ExpenseRecord: Record Expense;
    begin
        ExpenseRecord.SetLoadFields(Status);
        ExpenseRecord.Get("Expense No.");

        ExpenseRecord.TestStatusOpen();
    end;
}