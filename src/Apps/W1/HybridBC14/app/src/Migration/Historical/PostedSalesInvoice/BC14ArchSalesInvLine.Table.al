// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50183 "BC14 Arch. Sales Inv. Line"
{
    Caption = 'BC14 Archived Sales Invoice Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
        }
        field(11; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(12; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
        }
        field(20; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            AutoFormatType = 2;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(21; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
        }
        field(22; "Line Discount Amount"; Decimal)
        {
            Caption = 'Line Discount Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(23; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(24; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(30; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
        }
        field(31; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
        }
        field(40; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
        }
        field(41; "VAT Base Amount"; Decimal)
        {
            Caption = 'VAT Base Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(50; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(ItemNo; "No.")
        {
        }
    }
}
