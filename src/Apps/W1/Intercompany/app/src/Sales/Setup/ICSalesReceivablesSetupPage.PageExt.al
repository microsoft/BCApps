// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Extends Sales &amp; Receivables Setup page with Intercompany-specific fields.
/// Adds journal template fields for intercompany sales invoices and credit memos.
/// </summary>
pageextension 8511 ICSalesReceivablesSetupPage extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("S. Prep. Cr.Memo Template Name")
        {
            field("IC Sales Invoice Template Name"; Rec."IC Sales Invoice Template Name")
            {
                ApplicationArea = Intercompany;
            }
            field("IC Sales Cr. Memo Templ. Name"; Rec."IC Sales Cr. Memo Templ. Name")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
}
