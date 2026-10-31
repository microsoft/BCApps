// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Extends posted purchase receipt lines with Intercompany-specific fields.
/// </summary>
tableextension 8438 ICPurchRcptLine extends "Purch. Rcpt. Line"
{
    fields
    {
        field(107; "IC Partner Ref. Type"; Enum Microsoft.Intercompany.Partner."IC Partner Reference Type")
        {
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
    }
}
