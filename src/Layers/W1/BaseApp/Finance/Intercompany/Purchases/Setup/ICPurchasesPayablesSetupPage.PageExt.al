// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

/// <summary>
/// Extends Purchases &amp; Payables Setup page with Intercompany-specific controls.
/// Adds the IC journal template fields used when posting intercompany purchase invoices and credit memos.
/// </summary>
pageextension 8532 ICPurchasesPayablesSetupPage extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("P. Prep. Cr.Memo Template Name")
        {
            field("IC Purch. Invoice Templ. Name"; Rec."IC Purch. Invoice Templ. Name")
            {
                ApplicationArea = Basic, Suite;
            }
            field("IC Purch. Cr. Memo Templ. Name"; Rec."IC Purch. Cr. Memo Templ. Name")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
