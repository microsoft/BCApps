// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

/// <summary>
/// Extends Vend. Ledg. Entries Preview with Intercompany-specific controls.
/// Adds the IC Partner Code column for tracing intercompany transactions.
/// </summary>
pageextension 8521 ICVendLedgEntriesPreview extends "Vend. Ledg. Entries Preview"
{
    layout
    {
        addafter("Vendor Posting Group")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Editable = false;
                Visible = false;
            }
        }
    }
}
