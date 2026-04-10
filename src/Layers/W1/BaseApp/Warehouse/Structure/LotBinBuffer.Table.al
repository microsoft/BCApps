// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

table 7351 "Lot Bin Buffer"
{
    Caption = 'Lot Bin Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item that exists as lot numbers in the bin.';
            DataClassification = SystemMetadata;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(4; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the zone that is assigned to the bin where the lot number exists.';
            DataClassification = SystemMetadata;
        }
        field(5; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the lot number exists.';
            DataClassification = SystemMetadata;
        }
        field(6; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number that exists in the bin.';
            DataClassification = SystemMetadata;
        }
        field(7; "Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code", "Zone Code", "Bin Code", "Lot No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

