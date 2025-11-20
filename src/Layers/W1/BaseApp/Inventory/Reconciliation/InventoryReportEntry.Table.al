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
            Caption = 'Inventory';
        }
        field(9; "Inventory (Interim)"; Decimal)
        {
            Caption = 'Inventory (Interim)';
        }
        field(10; "WIP Inventory"; Decimal)
        {
            Caption = 'WIP Inventory';
        }
        field(11; "Direct Cost Applied Actual"; Decimal)
        {
            Caption = 'Direct Cost Applied Actual';
        }
        field(12; "Overhead Applied Actual"; Decimal)
        {
            Caption = 'Overhead Applied Actual';
        }
        field(13; "Purchase Variance"; Decimal)
        {
            Caption = 'Purchase Variance';
        }
        field(14; "Inventory Adjmt."; Decimal)
        {
            Caption = 'Inventory Adjmt.';
        }
        field(16; "Invt. Accrual (Interim)"; Decimal)
        {
            Caption = 'Invt. Accrual (Interim)';
        }
        field(17; COGS; Decimal)
        {
            Caption = 'COGS';
        }
        field(18; "COGS (Interim)"; Decimal)
        {
            Caption = 'COGS (Interim)';
        }
        field(19; "Material Variance"; Decimal)
        {
            Caption = 'Material Variance';
        }
        field(20; "Capacity Variance"; Decimal)
        {
            Caption = 'Capacity Variance';
        }
        field(21; "Subcontracted Variance"; Decimal)
        {
            Caption = 'Subcontracted Variance';
        }
        field(22; "Capacity Overhead Variance"; Decimal)
        {
            Caption = 'Capacity Overhead Variance';
        }
        field(23; "Mfg. Overhead Variance"; Decimal)
        {
            Caption = 'Mfg. Overhead Variance';
        }
        field(28; Total; Decimal)
        {
            Caption = 'Total';
        }
        field(29; "G/L Total"; Decimal)
        {
            Caption = 'G/L Total';
        }
        field(30; Difference; Decimal)
        {
            Caption = 'Difference';
        }
        field(31; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item';
            OptionMembers = " ","G/L Account",Item;
        }
        field(32; "Direct Cost Applied WIP"; Decimal)
        {
            Caption = 'Direct Cost Applied WIP';
        }
        field(33; "Overhead Applied WIP"; Decimal)
        {
            Caption = 'Overhead Applied WIP';
        }
        field(35; "Inventory To WIP"; Decimal)
        {
            Caption = 'Inventory To WIP';
        }
        field(36; "WIP To Interim"; Decimal)
        {
            Caption = 'WIP To Interim';
        }
        field(37; "Direct Cost Applied"; Decimal)
        {
            Caption = 'Direct Cost Applied';
        }
        field(38; "Overhead Applied"; Decimal)
        {
            Caption = 'Overhead Applied';
        }
        field(39; Description; Text[100])
        {
            Caption = 'Description';
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
            Caption = 'Material Non-Inventory Variance';
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

