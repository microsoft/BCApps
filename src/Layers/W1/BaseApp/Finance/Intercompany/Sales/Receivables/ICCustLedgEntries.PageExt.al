// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Extends Customer Ledger Entries with Intercompany-specific controls.
/// </summary>
pageextension 8477 ICCustLedgEntries extends "Customer Ledger Entries"
{
    layout
    {
        addafter("Customer Posting Group")
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
