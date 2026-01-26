// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

table 12114 "Withholding Tax Payment"
{
    Caption = 'Withholding Tax Payment';
    DrillDownPageID = "Withholding Tax Payment List";
    LookupPageID = "Withholding Tax Payment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; Month; Integer)
        {
            Caption = 'Month';
            Editable = false;
        }
        field(3; Year; Integer)
        {
            Caption = 'Year';
            Editable = false;
        }
        field(10; "Tax Code"; Text[4])
        {
            Caption = 'Tax Code';
            Editable = false;
        }
        field(20; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount';
            Editable = false;
        }
        field(21; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';
            Editable = false;
        }
        field(22; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';
            Editable = false;
        }
        field(23; "Non Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount';
            Editable = false;
        }
        field(24; "Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Taxable Amount';
            Editable = false;
        }
        field(25; "Withholding Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Withholding Tax Amount';
            Editable = false;
        }
        field(26; "Payable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Payable Amount';
            Editable = false;
        }
        field(30; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(31; "Series Number"; Text[30])
        {
            Caption = 'Series Number';
        }
        field(32; "Quittance No."; Text[30])
        {
            Caption = 'Quittance No.';
        }
        field(33; "C/T"; Option)
        {
            Caption = 'C/T';
            OptionCaption = ' ,Concessionary,State Treasury';
            OptionMembers = " ",Concessionary,"State Treasury";
        }
        field(34; "L/P/B"; Option)
        {
            Caption = 'L/P/B';
            OptionCaption = ' ,List,Post Office,Bank';
            OptionMembers = " ",List,"Post Office",Bank;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Year, Month)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        WithholdingTax.Reset();
        WithholdingTax.SetRange(Month, Month);
        WithholdingTax.SetRange(Year, Year);
        WithholdingTax.SetRange("Tax Code", "Tax Code");
        WithholdingTax.ModifyAll(Paid, false);
    end;

    var
        WithholdingTax: Record "Withholding Tax";
}

