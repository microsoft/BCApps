// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Extends Sales Invoice Subform with Intercompany-specific controls.
/// </summary>
pageextension 8484 ICSalesInvoiceSubform extends "Sales Invoice Subform"
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
