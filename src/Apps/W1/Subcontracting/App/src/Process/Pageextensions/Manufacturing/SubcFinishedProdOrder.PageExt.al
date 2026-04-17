// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 99001542 "Subc. Finished Prod. Order" extends "Finished Production Order"
{
    actions
    {
        addafter("&Warehouse Entries")
        {
            action("WIP Ledger Entries")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Ledger Entries';
                Image = LedgerEntries;
                RunObject = page "WIP Ledger Entries";
                RunPageLink = "Prod. Order Status" = field(Status), "Prod. Order No." = field("No.");
                ToolTip = 'View the Subcontractor WIP Ledger Entries for this production order.';
            }
        }
        addlast(Category_Entries)
        {
            actionref("WIP Entries_Promoted"; "WIP Ledger Entries") { }
        }
    }
}