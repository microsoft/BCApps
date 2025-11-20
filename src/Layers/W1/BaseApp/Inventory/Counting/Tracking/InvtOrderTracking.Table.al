// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

table 6025 "Invt. Order Tracking"
{
    Caption = 'Phys. Invt. Tracking';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Qty. Recorded (Base)"; Decimal)
        {
            Caption = 'Qty. Recorded (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(11; "Qty. Expected (Base)"; Decimal)
        {
            Caption = 'Qty. Expected (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(20; "Qty. To Transfer"; Decimal)
        {
            Caption = 'Qty. To Transfer';
            DataClassification = SystemMetadata;
        }
        field(21; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DataClassification = SystemMetadata;
        }
        field(22; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
        }
        field(23; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Serial No.", "Lot No.", "Package No.")
        {
            Clustered = true;
        }
        key(Key2; Open)
        {
        }
    }

    fieldgroups
    {
    }
}

