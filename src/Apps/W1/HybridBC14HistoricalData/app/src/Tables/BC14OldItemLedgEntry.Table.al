// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

using Microsoft.Inventory.Ledger;

table 46899 "BC14 Old Item Ledg. Entry"
{
    Caption = 'BC14 Old Item Ledger Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BC14 Old Item Ledg. List";
    LookupPageId = "BC14 Old Item Ledg. List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(5; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
        }
        field(13; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            AutoFormatType = 0;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            AutoFormatType = 0;
        }
        field(29; "Open"; Boolean)
        {
            Caption = 'Open';
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(100; "Cost Amount (Actual)"; Decimal)
        {
            Caption = 'Cost Amount (Actual)';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(200; "Migrated On"; DateTime)
        {
            Caption = 'Migrated On';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Posting Date")
        {
            SumIndexFields = Quantity, "Remaining Quantity", "Cost Amount (Actual)";
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
    }
}
