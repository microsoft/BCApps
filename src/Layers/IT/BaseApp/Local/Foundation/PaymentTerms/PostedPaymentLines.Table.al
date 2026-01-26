// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

table 12171 "Posted Payment Lines"
{
    Caption = 'Posted Payment Lines';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Payment Terms,General Journal';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Payment Terms","General Journal";
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Payment %"; Decimal)
        {
            Caption = 'Payment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
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
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(8; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(9; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(10; "Sales/Purchase"; Option)
        {
            Caption = 'Sales/Purchase';
            OptionCaption = ' ,Sales,Purchase,Service';
            OptionMembers = " ",Sales,Purchase,Service;
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Sales/Purchase", Type, "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

