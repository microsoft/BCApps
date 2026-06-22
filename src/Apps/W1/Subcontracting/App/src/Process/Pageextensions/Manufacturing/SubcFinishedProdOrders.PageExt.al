// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

pageextension 99001543 "Subc. Finished Prod. Orders" extends "Finished Production Orders"
{
    actions
    {
        addafter("E&ntries")
        {
            action("Subcontracting Purchase Lines")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting Order Lines';
                Image = SubcontractingWorksheet;
                RunObject = page "Purchase Lines";
                RunPageLink = "Document Type" = const(Order), "Prod. Order No." = field("No.");
                ToolTip = 'Show purchase order lines for subcontracting.';
            }
        }
        addafter("&Warehouse Entries")
        {
            action("Subc. Transfer Entries")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting Transfer Entries';
                Image = ItemLedger;
                RunObject = page "Item Ledger Entries";
                RunPageLink = "Entry Type" = const(Transfer), "Subc. Prod. Order No." = field("No.");
                RunPageView = sorting("Order Type", "Order No.");
                ToolTip = 'View the list of subcontracting transfers.';
            }
            action("WIP Ledger Entries")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting WIP Entries';
                Image = LedgerEntries;
                RunObject = page "Subc. WIP Ledger Entries";
                RunPageLink = "Prod. Order Status" = field(Status), "Prod. Order No." = field("No.");
                ToolTip = 'View the Subcontracting WIP Entries for this production order.';
            }
        }
    }
}