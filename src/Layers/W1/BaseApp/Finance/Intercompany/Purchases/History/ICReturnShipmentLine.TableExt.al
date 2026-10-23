// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends posted return shipment lines with Intercompany-specific fields.
/// </summary>
tableextension 8465 ICReturnShipmentLine extends "Return Shipment Line"
{
    fields
    {
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
    }
}
