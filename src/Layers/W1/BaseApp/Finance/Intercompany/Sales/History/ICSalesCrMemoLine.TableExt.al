// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends posted sales credit memo lines with Intercompany-specific fields.
/// </summary>
tableextension 8462 ICSalesCrMemoLine extends "Sales Cr.Memo Line"
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
        /// Specifies the intercompany partner reference for cross-company transactions.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany partner code for cross-company transactions.
        /// </summary>
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "IC Partner";
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
        }
        /// <summary>
        /// Specifies the intercompany item reference number for cross-company transactions.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
    }
}
