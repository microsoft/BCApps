// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

table 5846 "Inventory Report Entry"
{
    Caption = 'Inventory Report Entry';
    DrillDownPageID = "Inventory Report Entry";
    LookupPageID = "Inventory Report Entry";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(5; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(8; Inventory; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(9; "Inventory (Interim)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory (Interim)';
        }
        field(10; "WIP Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'WIP Inventory';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(11; "Direct Cost Applied Actual"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Direct Cost Applied Actual';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(12; "Overhead Applied Actual"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Overhead Applied Actual';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(13; "Purchase Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Purchase Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(14; "Inventory Adjmt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory Adjmt.';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(16; "Invt. Accrual (Interim)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Invt. Accrual (Interim)';
        }
        field(17; COGS; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'COGS';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(18; "COGS (Interim)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'COGS (Interim)';
        }
        field(19; "Material Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Material Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(20; "Capacity Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(21; "Subcontracted Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Subcontracted Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(22; "Capacity Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity Overhead Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(23; "Mfg. Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mfg. Overhead Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(28; Total; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Total';
        }
        field(29; "G/L Total"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'G/L Total';
        }
        field(30; Difference; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Difference';
        }
        field(31; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the inventory report entry refers to an item or a general ledger account.';
            OptionCaption = ' ,G/L Account,Item';
            OptionMembers = " ","G/L Account",Item;
        }
        field(32; "Direct Cost Applied WIP"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Direct Cost Applied WIP';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(33; "Overhead Applied WIP"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Overhead Applied WIP';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(35; "Inventory To WIP"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory To WIP';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(36; "WIP To Interim"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'WIP To Interim';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(37; "Direct Cost Applied"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Direct Cost Applied';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(38; "Overhead Applied"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Overhead Applied';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
        field(39; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a value that depends on the type of the inventory report entry.';
        }
        field(40; Warning; Text[50])
        {
            Caption = 'Warning';
        }
        field(61; "Cost is Posted to G/L Warning"; Boolean)
        {
            Caption = 'Cost is Posted to G/L Warning';
        }
        field(62; "Expected Cost Posting Warning"; Boolean)
        {
            Caption = 'Expected Cost Posting Warning';
        }
        field(63; "Compression Warning"; Boolean)
        {
            Caption = 'Compression Warning';
        }
        field(64; "Posting Group Warning"; Boolean)
        {
            Caption = 'Posting Group Warning';
        }
        field(65; "Direct Postings Warning"; Boolean)
        {
            Caption = 'Direct Postings Warning';
        }
        field(66; "Posting Date Warning"; Boolean)
        {
            Caption = 'Posting Date Warning';
        }
        field(67; "Closing Period Overlap Warning"; Boolean)
        {
            Caption = 'Closing Period Overlap Warning';
        }
        field(68; "Similar Accounts Warning"; Boolean)
        {
            Caption = 'Similar Accounts Warning';
        }
        field(69; "Deleted G/L Accounts Warning"; Boolean)
        {
            Caption = 'Deleted G/L Accounts Warning';
        }
        field(70; "Mat. Non-Inventory Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Material Non-Inventory Variance';
            ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';
        }
    }

    keys
    {
        key(Key1; Type, "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

