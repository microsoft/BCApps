// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 12115 "Contribution Payment"
{
    Caption = 'Contribution Payment';
    DrillDownPageID = "Contribution Payment List";
    LookupPageID = "Contribution Payment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Month; Integer)
        {
            Caption = 'Month';
        }
        field(3; Year; Integer)
        {
            Caption = 'Year';
        }
        field(4; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(10; "Gross Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Gross Amount';
        }
        field(11; "Non Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount';
        }
        field(12; "Contribution Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Contribution Base';
        }
        field(13; "Total Social Security Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Social Security Amount';
        }
        field(14; "Free-Lance Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Free-Lance Amount';
        }
        field(15; "Company Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Company Amount';
        }
        field(31; "Series Number"; Text[30])
        {
            Caption = 'Series Number';
        }
        field(32; "Quiettance No."; Text[30])
        {
            Caption = 'Quiettance No.';
        }
        field(33; "Contribution Type"; Option)
        {
            Caption = 'Contribution Type';
            OptionCaption = 'INPS,INAIL';
            OptionMembers = INPS,INAIL;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contribution Type", Year, Month)
        {
        }
        key(Key3; "Contribution Type", "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}

