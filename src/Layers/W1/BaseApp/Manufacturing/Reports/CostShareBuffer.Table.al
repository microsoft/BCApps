// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.MachineCenter;

table 5848 "Cost Share Buffer"
{
    Caption = 'Cost Share Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Capacity Ledger Entry No."; Integer)
        {
            Caption = 'Capacity Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
        }
        field(6; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(21; "Direct Cost"; Decimal)
        {
            Caption = 'Direct Cost';
            DataClassification = SystemMetadata;
        }
        field(22; "Indirect Cost"; Decimal)
        {
            Caption = 'Indirect Cost';
            DataClassification = SystemMetadata;
        }
        field(23; Revaluation; Decimal)
        {
            Caption = 'Revaluation';
            DataClassification = SystemMetadata;
        }
        field(24; Rounding; Decimal)
        {
            Caption = 'Rounding';
            DataClassification = SystemMetadata;
        }
        field(25; Variance; Decimal)
        {
            Caption = 'Variance';
            DataClassification = SystemMetadata;
        }
        field(26; "Purchase Variance"; Decimal)
        {
            Caption = 'Purchase Variance';
            DataClassification = SystemMetadata;
        }
        field(27; "Material Variance"; Decimal)
        {
            Caption = 'Material Variance';
            DataClassification = SystemMetadata;
        }
        field(28; "Capacity Variance"; Decimal)
        {
            Caption = 'Capacity Variance';
            DataClassification = SystemMetadata;
        }
        field(29; "Capacity Overhead Variance"; Decimal)
        {
            Caption = 'Capacity Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(30; "Mfg. Overhead Variance"; Decimal)
        {
            Caption = 'Mfg. Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(31; "Subcontracted Variance"; Decimal)
        {
            Caption = 'Subcontracted Variance';
            DataClassification = SystemMetadata;
        }
        field(32; Material; Decimal)
        {
            Caption = 'Material';
            DataClassification = SystemMetadata;
        }
        field(34; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DataClassification = SystemMetadata;
        }
        field(35; "Capacity Overhead"; Decimal)
        {
            Caption = 'Capacity Overhead';
            DataClassification = SystemMetadata;
        }
        field(36; "Material Overhead"; Decimal)
        {
            Caption = 'Material Overhead';
            DataClassification = SystemMetadata;
        }
        field(37; Subcontracted; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Subcontracted';
            DataClassification = SystemMetadata;
        }
        field(40; "New Quantity"; Decimal)
        {
            Caption = 'New Quantity';
            DataClassification = SystemMetadata;
        }
        field(41; "New Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Direct Cost';
            DataClassification = SystemMetadata;
        }
        field(42; "New Indirect Cost"; Decimal)
        {
            Caption = 'New Indirect Cost';
            DataClassification = SystemMetadata;
        }
        field(43; "New Revaluation"; Decimal)
        {
            Caption = 'New Revaluation';
            DataClassification = SystemMetadata;
        }
        field(44; "New Rounding"; Decimal)
        {
            Caption = 'New Rounding';
            DataClassification = SystemMetadata;
        }
        field(45; "New Variance"; Decimal)
        {
            Caption = 'New Variance';
            DataClassification = SystemMetadata;
        }
        field(46; "New Purchase Variance"; Decimal)
        {
            Caption = 'New Purchase Variance';
            DataClassification = SystemMetadata;
        }
        field(47; "New Material Variance"; Decimal)
        {
            Caption = 'New Material Variance';
            DataClassification = SystemMetadata;
        }
        field(48; "New Capacity Variance"; Decimal)
        {
            Caption = 'New Capacity Variance';
            DataClassification = SystemMetadata;
        }
        field(49; "New Capacity Overhead Variance"; Decimal)
        {
            Caption = 'New Capacity Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(50; "New Mfg. Overhead Variance"; Decimal)
        {
            Caption = 'New Mfg. Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(51; "New Subcontracted Variance"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'New Subcontracted Variance';
            DataClassification = SystemMetadata;
        }
        field(52; "Share of Cost in Period"; Decimal)
        {
            Caption = 'Share of Cost in Period';
            DataClassification = SystemMetadata;
        }
        field(54; "New Material"; Decimal)
        {
            Caption = 'New Material';
            DataClassification = SystemMetadata;
        }
        field(56; "New Capacity"; Decimal)
        {
            Caption = 'New Capacity';
            DataClassification = SystemMetadata;
        }
        field(57; "New Capacity Overhead"; Decimal)
        {
            Caption = 'New Capacity Overhead';
            DataClassification = SystemMetadata;
        }
        field(58; "New Material Overhead"; Decimal)
        {
            Caption = 'New Material Overhead';
            DataClassification = SystemMetadata;
        }
        field(59; "New Subcontracted"; Decimal)
        {
            Caption = 'New Subcontracted';
            DataClassification = SystemMetadata;
        }
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            DataClassification = SystemMetadata;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Item Ledger Entry No.", "Capacity Ledger Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Location Code", "Variant Code", "Entry Type")
        {
        }
        key(Key3; "Order Type", "Order No.", "Order Line No.", "Entry Type")
        {
        }
    }

    fieldgroups
    {
    }
}

