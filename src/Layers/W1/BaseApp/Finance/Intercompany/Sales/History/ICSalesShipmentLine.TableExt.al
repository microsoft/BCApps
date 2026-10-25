// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends posted sales shipment lines with Intercompany-specific fields.
/// </summary>
tableextension 8463 ICSalesShipmentLine extends "Sales Shipment Line"
{
    fields
    {
        /// <summary>
        /// Specifies the type of intercompany partner reference.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum Microsoft.Intercompany.Partner."IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany partner reference code.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the item reference number for intercompany transactions.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
    }
}