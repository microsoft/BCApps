// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

table 8845 "Installment Calculation Line"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Plan ID"; Guid) { }
        field(2; "Line No."; Integer) { }
        field(3; "Allocation Type"; Enum "Installment Allocation Type") { }
        field(4; "Payment %"; Decimal) { DecimalPlaces = 0 : 5; }
        field(5; "Due Date Calculation"; DateFormula) { }
        field(6; "Discount Date Calculation"; DateFormula) { }
        field(7; "Discount %"; Decimal) { DecimalPlaces = 0 : 5; }
        field(8; Description; Text[100]) { }
        field(9; "Installment No."; Integer) { }
        field(10; "Due Date"; Date) { }
        field(11; "Pmt. Discount Date"; Date) { }
        field(12; Amount; Decimal) { DecimalPlaces = 0 : 5; }
        field(13; "Amount (LCY)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(14; "Rounding Adjustment"; Decimal) { DecimalPlaces = 0 : 5; }
        field(15; "Rounding Adjustment (LCY)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(16; "Original Pmt. Disc. Possible"; Decimal) { DecimalPlaces = 0 : 5; }
        field(17; "Source Currency Amount"; Decimal) { DecimalPlaces = 0 : 5; }
        field(18; "Sales/Purch. (LCY)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(19; "Profit (LCY)"; Decimal) { DecimalPlaces = 0 : 5; }
        field(20; "Inv. Discount (LCY)"; Decimal) { DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Plan ID", "Line No.")
        {
            Clustered = true;
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
}
