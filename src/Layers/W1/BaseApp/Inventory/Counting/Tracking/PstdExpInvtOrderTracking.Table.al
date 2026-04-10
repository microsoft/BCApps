// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Counting.History;

table 6027 "Pstd.Exp.Invt.Order.Tracking"
{
    Caption = 'Pstd. Exp. Phys. Invt. Track';
    DrillDownPageID = "Posted.Exp.Invt.Order.Tracking";
    LookupPageID = "Posted.Exp.Invt.Order.Tracking";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
            ToolTip = 'Specifies the document number of the Posted Inventory Order.';
            DataClassification = SystemMetadata;
            TableRelation = "Pstd. Phys. Invt. Order Hdr";
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            ToolTip = 'Specifies the line number of the Posted Inventory Order Line.';
            DataClassification = SystemMetadata;
            TableRelation = "Pstd. Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No"));
        }
        field(3; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the expected Serial No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the expected Lot No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Package No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the expected Package No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the expected Expiration Date';
            DataClassification = SystemMetadata;
        }
        field(30; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Order No", "Order Line No.", "Serial No.", "Lot No.", "Package No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

