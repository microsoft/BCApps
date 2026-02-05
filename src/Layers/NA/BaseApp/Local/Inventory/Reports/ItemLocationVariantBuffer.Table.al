// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

table 10139 "Item Location Variant Buffer"
{
    Caption = 'Item Location Variant Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
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
        field(4; Label; Text[250])
        {
            Caption = 'Label';
            DataClassification = SystemMetadata;
        }
        field(5; "Remaining Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Remaining Quantity';
            DataClassification = SystemMetadata;
        }
        field(6; Value1; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value1';
            DataClassification = SystemMetadata;
        }
        field(7; Value2; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value2';
            DataClassification = SystemMetadata;
        }
        field(8; Value3; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value3';
            DataClassification = SystemMetadata;
        }
        field(9; Value4; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value4';
            DataClassification = SystemMetadata;
        }
        field(10; Value5; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value5';
            DataClassification = SystemMetadata;
        }
        field(11; Value6; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value6';
            DataClassification = SystemMetadata;
        }
        field(12; Value7; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value7';
            DataClassification = SystemMetadata;
        }
        field(13; Value8; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value8';
            DataClassification = SystemMetadata;
        }
        field(14; Value9; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value9';
            DataClassification = SystemMetadata;
        }
        field(15; Value10; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value10';
            DataClassification = SystemMetadata;
        }
        field(16; Value11; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Value11';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

