// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Sales.Receivables;

table 8841 "Installment Plan Line"
{
    Caption = 'Installment Plan Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
            TableRelation = "Installment Plan";
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

    internal procedure CopyRulesFromPlanLine(PlanLine: Record "Installment Plan Line")
    begin
        "Line No." := PlanLine."Line No.";
        "Allocation Type" := PlanLine."Allocation Type";
        "Payment %" := PlanLine."Payment %";
        "Due Date Calculation" := PlanLine."Due Date Calculation";
        "Discount Date Calculation" := PlanLine."Discount Date Calculation";
        "Discount %" := PlanLine."Discount %";
        Description := PlanLine.Description;
    end;
}
