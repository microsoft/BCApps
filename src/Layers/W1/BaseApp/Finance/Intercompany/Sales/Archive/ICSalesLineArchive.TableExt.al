// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends Sales Line Archive with Intercompany-specific fields.
/// </summary>
tableextension 8468 ICSalesLineArchive extends "Sales Line Archive"
{
    fields
    {
        /// <summary>
        /// Specifies the type of reference used for intercompany transactions.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the item or account reference used by the intercompany partner.
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
        }
        /// <summary>
        /// Specifies the item reference number used by the intercompany partner.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
    }
}
