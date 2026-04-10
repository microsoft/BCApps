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
            AutoFormatType = 0;
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(21; "Direct Cost"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Direct Cost';
            DataClassification = SystemMetadata;
        }
        field(22; "Indirect Cost"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost';
            DataClassification = SystemMetadata;
        }
        field(23; Revaluation; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Revaluation';
            DataClassification = SystemMetadata;
        }
        field(24; Rounding; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rounding';
            DataClassification = SystemMetadata;
        }
        field(25; Variance; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Variance';
            DataClassification = SystemMetadata;
        }
        field(26; "Purchase Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Purchase Variance';
            DataClassification = SystemMetadata;
        }
        field(27; "Material Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Material Variance';
            DataClassification = SystemMetadata;
        }
        field(28; "Capacity Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity Variance';
            DataClassification = SystemMetadata;
        }
        field(29; "Capacity Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(30; "Mfg. Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mfg. Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(31; "Subcontracted Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Subcontracted Variance';
            DataClassification = SystemMetadata;
        }
        field(32; Material; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Material';
            DataClassification = SystemMetadata;
        }
        field(34; Capacity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity';
            DataClassification = SystemMetadata;
        }
        field(35; "Capacity Overhead"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity Overhead';
            DataClassification = SystemMetadata;
        }
        field(36; "Material Overhead"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Material Overhead';
            DataClassification = SystemMetadata;
        }
        field(37; Subcontracted; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Subcontracted';
            DataClassification = SystemMetadata;
        }
        field(40; "New Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Quantity';
            DataClassification = SystemMetadata;
        }
        field(41; "New Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'New Direct Cost';
            DataClassification = SystemMetadata;
        }
        field(42; "New Indirect Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'New Indirect Cost';
            DataClassification = SystemMetadata;
        }
        field(43; "New Revaluation"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Revaluation';
            DataClassification = SystemMetadata;
        }
        field(44; "New Rounding"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Rounding';
            DataClassification = SystemMetadata;
        }
        field(45; "New Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Variance';
            DataClassification = SystemMetadata;
        }
        field(46; "New Purchase Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Purchase Variance';
            DataClassification = SystemMetadata;
        }
        field(47; "New Material Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Material Variance';
            DataClassification = SystemMetadata;
        }
        field(48; "New Capacity Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Capacity Variance';
            DataClassification = SystemMetadata;
        }
        field(49; "New Capacity Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Capacity Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(50; "New Mfg. Overhead Variance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Mfg. Overhead Variance';
            DataClassification = SystemMetadata;
        }
        field(51; "New Subcontracted Variance"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'New Subcontracted Variance';
            DataClassification = SystemMetadata;
        }
        field(52; "Share of Cost in Period"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Share of Cost in Period';
            DataClassification = SystemMetadata;
        }
        field(54; "New Material"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Material';
            DataClassification = SystemMetadata;
        }
        field(56; "New Capacity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Capacity';
            DataClassification = SystemMetadata;
        }
        field(57; "New Capacity Overhead"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Capacity Overhead';
            DataClassification = SystemMetadata;
        }
        field(58; "New Material Overhead"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'New Material Overhead';
            DataClassification = SystemMetadata;
        }
        field(59; "New Subcontracted"; Decimal)
        {
            AutoFormatType = 0;
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

