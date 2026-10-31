// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

/// <summary>
/// Extends Purchase Order Subform with Intercompany-specific controls.
/// </summary>
pageextension 8454 ICPurchaseOrderSubform extends "Purchase Order Subform"
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
            field("IC Partner Ref. Type"; Rec."IC Partner Ref. Type")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
            field("IC Partner Reference"; Rec."IC Partner Reference")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
