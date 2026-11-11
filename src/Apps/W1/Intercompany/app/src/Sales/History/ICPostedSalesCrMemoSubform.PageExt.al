// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Extends posted sales credit memo subform with Intercompany-specific controls.
/// </summary>
pageextension 8466 ICPostedSalesCrMemoSubform extends "Posted Sales Cr. Memo Subform"
{
    layout
    {
        addafter("Item Reference No.")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
