// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;
using Microsoft.Sales.Document;

table 10003 "Document Line"
{
    Caption = 'Document Line';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Document Header"."No.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(22; "Unit Price/Direct Unit Cost"; Decimal)
        {
            Caption = 'Unit Price/Direct Unit Cost';
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            Caption = 'Unit Cost (LCY)';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            Caption = 'Line Discount Amount';
        }
        field(29; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(10001; "Retention Attached to Line No."; Integer)
        {
            Caption = 'Retention Attached to Line No.';
        }
        field(10002; "Retention VAT %"; Decimal)
        {
            Caption = 'Retention VAT %';
            AutoFormatType = 2;	    
        }
        field(10003; "Custom Transit Number"; Text[30])
        {
            Caption = 'Custom Transit Number';
        }
        field(10004; "SAT Customs Document Type"; Code[10])
        {
            Caption = 'SAT Customs Document Type';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsTemporary then
            Error(TemporaryErr);
    end;

    var
        TemporaryErr: Label 'Developer Message: The record must be temporary.';
}

