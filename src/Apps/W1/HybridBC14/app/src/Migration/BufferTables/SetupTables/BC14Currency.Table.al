// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50193 "BC14 Currency"
{
    Caption = 'BC14 Currency';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Description"; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Unrealized Gains Acc."; Code[20])
        {
            Caption = 'Unrealized Gains Acc.';
        }
        field(4; "Realized Gains Acc."; Code[20])
        {
            Caption = 'Realized Gains Acc.';
        }
        field(5; "Unrealized Losses Acc."; Code[20])
        {
            Caption = 'Unrealized Losses Acc.';
        }
        field(6; "Realized Losses Acc."; Code[20])
        {
            Caption = 'Realized Losses Acc.';
        }
        field(7; "Invoice Rounding Precision"; Decimal)
        {
            Caption = 'Invoice Rounding Precision';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,2:5><Standard Format,0>';
        }
        field(8; "Invoice Rounding Type"; Option)
        {
            Caption = 'Invoice Rounding Type';
            OptionMembers = Nearest,Up,Down;
            OptionCaption = 'Nearest,Up,Down';
        }
        field(9; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,2:5><Standard Format,0>';
        }
        field(10; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,2:5><Standard Format,0>';
        }
        field(12; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
        }
        field(13; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
        }
        field(14; "Appln. Rounding Precision"; Decimal)
        {
            Caption = 'Appln. Rounding Precision';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,2:5><Standard Format,0>';
        }
        field(15; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
        }
        field(17; "Residual Gains Account"; Code[20])
        {
            Caption = 'Residual Gains Account';
        }
        field(18; "Residual Losses Account"; Code[20])
        {
            Caption = 'Residual Losses Account';
        }
        field(19; "Conv. LCY Rndg. Debit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Debit Acc.';
        }
        field(20; "Conv. LCY Rndg. Credit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Credit Acc.';
        }
        field(21; "Max. VAT Difference Allowed"; Decimal)
        {
            Caption = 'Max. VAT Difference Allowed';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(22; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            OptionMembers = Nearest,Up,Down;
            OptionCaption = 'Nearest,Up,Down';
        }
        field(25; "Symbol"; Text[10])
        {
            Caption = 'Symbol';
        }
        field(27; "ISO Code"; Code[3])
        {
            Caption = 'ISO Code';
        }
        field(28; "ISO Numeric Code"; Code[3])
        {
            Caption = 'ISO Numeric Code';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
}
