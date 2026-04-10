// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Stores temporary data during drop shipment posting to link purchase and sales transactions.
/// </summary>
table 223 "Drop Shpt. Post. Buffer"
{
    Caption = 'Drop Shpt. Post. Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the sales order number associated with this drop shipment entry.
        /// </summary>
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the line number of the sales order line for this drop shipment.
        /// </summary>
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the item ledger entry number created when the shipment was posted.
        /// </summary>
        field(3; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the quantity shipped in the sales unit of measure.
        /// </summary>
        field(4; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the quantity shipped in the base unit of measure.
        /// </summary>
        field(5; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
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
