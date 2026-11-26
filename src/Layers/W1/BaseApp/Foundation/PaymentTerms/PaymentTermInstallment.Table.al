// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

table 8840 "Payment Term Installment"
{
    Caption = 'Payment Term Installment';
    DataClassification = CustomerContent;
    LookupPageId = "Payment Term Installments";
    DrillDownPageId = "Payment Term Installments";

    fields
    {
        field(1; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            ToolTip = 'Specifies the payment terms that own the installment rule.';
            NotBlank = true;
            TableRelation = "Payment Terms";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the calculation order of the installment rule.';
            MinValue = 1;
        }
        field(3; "Allocation Type"; Enum "Installment Allocation Type")
        {
            Caption = 'Allocation Type';
            ToolTip = 'Specifies whether the installment uses a percentage of the original amount or the remaining balance.';

            trigger OnValidate()
            begin
                if "Allocation Type" = "Allocation Type"::"Remaining Amount" then
                    "Payment %" := 0;
            end;
        }
        field(4; "Payment %"; Decimal)
        {
            Caption = 'Payment %';
            ToolTip = 'Specifies the percentage of the original invoice amount allocated to this installment.';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(5; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
            ToolTip = 'Specifies the formula used to calculate the installment due date from the document date.';
        }
        field(6; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
            ToolTip = 'Specifies the formula used to calculate the payment discount date from the document date.';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            ToolTip = 'Specifies the payment discount percentage for this installment.';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the installment.';
        }
    }

    keys
    {
        key(PK; "Payment Terms Code", "Line No.")
        {
            Clustered = true;
        }
    }
}
