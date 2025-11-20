// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

table 223 "Drop Shpt. Post. Buffer"
{
    Caption = 'Drop Shpt. Post. Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            DataClassification = SystemMetadata;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(5; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Order No.", "Order Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

