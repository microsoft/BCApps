#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting;

table 5005360 "Phys. Invt. Tracking Buffer"
{
    Caption = 'Phys. Invt. Tracking Buffer';
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Lot No"; Code[50])
        {
            Caption = 'Lot No';
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
    }

    keys
    {
        key(Key1; "Serial No.", "Lot No")
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

 
#endif