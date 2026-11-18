// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Foundation.PaymentTerms;

table 8841 "Sales Installment Plan Line"
{
    Caption = 'Sales Installment Plan Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
            TableRelation = "Sales Installment Plan";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Allocation Type"; Enum "Installment Allocation Type")
        {
            Caption = 'Allocation Type';
        }
        field(4; "Payment %"; Decimal)
        {
            Caption = 'Payment %';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(5; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(6; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Installment No."; Integer)
        {
            Caption = 'Installment No.';
        }
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(12; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(14; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(15; "Rounding Adjustment"; Decimal)
        {
            Caption = 'Rounding Adjustment';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(16; "Rounding Adjustment (LCY)"; Decimal)
        {
            Caption = 'Rounding Adjustment (LCY)';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(17; "Original Pmt. Disc. Possible"; Decimal)
        {
            Caption = 'Original Pmt. Disc. Possible';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(18; "Source Currency Amount"; Decimal)
        {
            Caption = 'Source Currency Amount';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(19; "Sales (LCY)"; Decimal)
        {
            Caption = 'Sales (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
        }
        field(20; "Profit (LCY)"; Decimal)
        {
            Caption = 'Profit (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
        }
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            Caption = 'Inv. Discount (LCY)';
            AutoFormatExpression = '';
            AutoFormatType = 1;
        }
        field(22; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            TableRelation = "Cust. Ledger Entry";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Plan ID", "Line No.")
        {
            Clustered = true;
        }
        key(Installment; "Plan ID", "Installment No.")
        {
        }
        key(CustLedgerEntry; "Plan ID", "Cust. Ledger Entry No.")
        {
        }
    }

    internal procedure CopyFromPaymentTermInstallment(PaymentTermInstallment: Record "Payment Term Installment")
    begin
        "Line No." := PaymentTermInstallment."Line No.";
        "Allocation Type" := PaymentTermInstallment."Allocation Type";
        "Payment %" := PaymentTermInstallment."Payment %";
        "Due Date Calculation" := PaymentTermInstallment."Due Date Calculation";
        "Discount Date Calculation" := PaymentTermInstallment."Discount Date Calculation";
        "Discount %" := PaymentTermInstallment."Discount %";
        Description := PaymentTermInstallment.Description;
    end;

    internal procedure CopyRulesFromPlanLine(PlanLine: Record "Sales Installment Plan Line")
    begin
        "Line No." := PlanLine."Line No.";
        "Allocation Type" := PlanLine."Allocation Type";
        "Payment %" := PlanLine."Payment %";
        "Due Date Calculation" := PlanLine."Due Date Calculation";
        "Discount Date Calculation" := PlanLine."Discount Date Calculation";
        "Discount %" := PlanLine."Discount %";
        Description := PlanLine.Description;
    end;

    internal procedure CopyToCalculationLine(var CalculationLine: Record "Installment Calculation Line" temporary)
    begin
        CalculationLine."Plan ID" := "Plan ID";
        CalculationLine."Line No." := "Line No.";
        CalculationLine."Allocation Type" := "Allocation Type";
        CalculationLine."Payment %" := "Payment %";
        CalculationLine."Due Date Calculation" := "Due Date Calculation";
        CalculationLine."Discount Date Calculation" := "Discount Date Calculation";
        CalculationLine."Discount %" := "Discount %";
        CalculationLine.Description := Description;
        CalculationLine."Installment No." := "Installment No.";
        CalculationLine."Due Date" := "Due Date";
        CalculationLine."Pmt. Discount Date" := "Pmt. Discount Date";
        CalculationLine.Amount := Amount;
        CalculationLine."Amount (LCY)" := "Amount (LCY)";
        CalculationLine."Rounding Adjustment" := "Rounding Adjustment";
        CalculationLine."Rounding Adjustment (LCY)" := "Rounding Adjustment (LCY)";
        CalculationLine."Original Pmt. Disc. Possible" := "Original Pmt. Disc. Possible";
        CalculationLine."Source Currency Amount" := "Source Currency Amount";
        CalculationLine."Sales/Purch. (LCY)" := "Sales (LCY)";
        CalculationLine."Profit (LCY)" := "Profit (LCY)";
        CalculationLine."Inv. Discount (LCY)" := "Inv. Discount (LCY)";
    end;

    internal procedure CopyFromCalculationLine(CalculationLine: Record "Installment Calculation Line" temporary)
    begin
        "Plan ID" := CalculationLine."Plan ID";
        "Line No." := CalculationLine."Line No.";
        "Allocation Type" := CalculationLine."Allocation Type";
        "Payment %" := CalculationLine."Payment %";
        "Due Date Calculation" := CalculationLine."Due Date Calculation";
        "Discount Date Calculation" := CalculationLine."Discount Date Calculation";
        "Discount %" := CalculationLine."Discount %";
        Description := CalculationLine.Description;
        "Installment No." := CalculationLine."Installment No.";
        "Due Date" := CalculationLine."Due Date";
        "Pmt. Discount Date" := CalculationLine."Pmt. Discount Date";
        Amount := CalculationLine.Amount;
        "Amount (LCY)" := CalculationLine."Amount (LCY)";
        "Rounding Adjustment" := CalculationLine."Rounding Adjustment";
        "Rounding Adjustment (LCY)" := CalculationLine."Rounding Adjustment (LCY)";
        "Original Pmt. Disc. Possible" := CalculationLine."Original Pmt. Disc. Possible";
        "Source Currency Amount" := CalculationLine."Source Currency Amount";
        "Sales (LCY)" := CalculationLine."Sales/Purch. (LCY)";
        "Profit (LCY)" := CalculationLine."Profit (LCY)";
        "Inv. Discount (LCY)" := CalculationLine."Inv. Discount (LCY)";
    end;
}
