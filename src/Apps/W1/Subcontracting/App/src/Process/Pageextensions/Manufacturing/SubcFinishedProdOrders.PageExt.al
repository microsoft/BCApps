// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 99001543 "Subc. Finished Prod. Orders" extends "Finished Production Orders"
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
    }
}