// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Extends General Ledger Entries with Intercompany-specific controls.
/// Adds the IC Partner Code column for identifying intercompany transactions.
/// </summary>
pageextension 8522 ICGeneralLedgerEntries extends "General Ledger Entries"
{
    layout
    {
        addafter("Global Dimension 2 Code")
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
