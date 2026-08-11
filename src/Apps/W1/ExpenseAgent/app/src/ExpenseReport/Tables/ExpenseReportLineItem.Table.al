// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6911 "Expense Report Line Item"
{
    Access = Internal;
    Caption = 'Expense Report Line Itemization';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Report Line Items";
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
            TableRelation = "Expense Category".Code where(Inactive = const(false));
        }
        field(7; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category Code"), Inactive = const(false));

            trigger OnValidate()
            var
                ExpenseSubCategory: Record "Expense Subcategory";
            begin
                TestStatusOpenOfExpenseReport();

                if xRec."Expense Subcategory Code" <> Rec."Expense Subcategory Code" then begin
                    Rec.Refundable := false;

                    if Rec."Expense Subcategory Code" <> '' then begin
                        ExpenseSubCategory.Get(Rec."Expense Category Code", Rec."Expense Subcategory Code");

                        Rec.Description := ExpenseSubCategory."Posting Description";
                        Rec.Refundable := ExpenseSubCategory.Refundable;

                        UpdateItemizationInformationOnExpenseReportLine(false);
                    end else begin
                        Rec.Description := '';
                        Rec."Start Date" := 0D;
                        Rec."Quantity" := 1;
                        Rec.Validate("Daily Rate", 0);
                    end;
                end;
            end;
        }
        field(8; "Description"; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();
            end;
        }
        field(9; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();
            end;
        }
        field(10; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            InitValue = 1;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                Rec.Validate("Amount", Quantity * "Daily Rate");
            end;
        }
        field(11; "Daily Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Daily Rate';

            trigger OnValidate()
            begin
                TestStatusOpenOfExpenseReport();

                if Rec."Daily Rate" <> 0 then
                    Rec.TestField("Expense Subcategory Code");

                Rec.Validate("Amount", Quantity * "Daily Rate");
            end;
        }
        field(12; "Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                if Rec.Amount <> xRec.Amount then
                    UpdateItemizationInformationOnExpenseReportLine(false);
            end;
        }
        field(13; "Refundable"; Boolean)
        {
            Caption = 'Refundable';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense Report No.", "Expense Report Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Expense Report No.", "Expense Report Line No.")
        {
            SumIndexFields = Amount;
        }
    }

    trigger OnInsert()
    begin
        Rec.TestField("Expense Report No.");
        Rec.TestField("Expense Report Line No.");
        Rec.TestField("Expense Category Code");
        Rec.TestField("Expense Subcategory Code");

        UpdateExpenseReportLineInformation(Rec."Expense Report No.", Rec."Expense Report Line No.");
    end;

    trigger OnDelete()
    begin
        TestStatusOpenOfExpenseReport();

        UpdateItemizationInformationOnExpenseReportLine(true);
    end;

    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHelper: Codeunit "Expense Report";

    local procedure UpdateExpenseReportLineInformation(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer)
    begin
        ExpenseReportLine := ExpenseReportHelper.GetExpenseReportLine(ExpenseReportNo, ExpenseReportLineNo);

        Rec.Validate("Expense No.", ExpenseReportLine."Expense No.");
        Rec.Validate("Expense Category Code", ExpenseReportLine."Expense Category");

        if Rec.Description = '' then
            Rec.Validate("Description", ExpenseReportLine.Description);
    end;

    local procedure UpdateItemizationInformationOnExpenseReportLine(CalledFromDelete: Boolean)
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        ExpenseReportLine := ExpenseReportHelper.GetExpenseReportLine(Rec."Expense Report No.", Rec."Expense Report Line No.");

        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineItemization.SetFilter("Line No.", '<>%1', Rec."Line No.");
        ExpenseReportLineItemization.SetRange(Refundable, false);
        ExpenseReportLineItemization.CalcSums(Amount);

        ExpenseReportLine."Non-Refundable Amount" := ExpenseReportLineItemization.Amount;
        if not CalledFromDelete then
            if not Rec.Refundable then
                ExpenseReportLine."Non-Refundable Amount" += Rec.Amount;

        ExpenseReportLine.UpdateAmounts();
        ExpenseReportLine.Modify();
    end;

    local procedure TestStatusOpenOfExpenseReport()
    var
        ExpReportLine: Record "Expense Report Line";
    begin
        ExpReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.");

        ExpReportLine.TestStatusOpen();
    end;
}
