// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Ledger;
pageextension 99001504 "Sub. Rel. Prod. Order" extends "Released Production Order"
{
    actions
    {
        addafter("Registered Invt. Movement Lines")
        {
            action("Subcontracting Purchase Lines")
            {
                ApplicationArea = All;
                Caption = 'Subcontracting Order Lines';
                Image = SubcontractingWorksheet;
                RunObject = page "Purchase Lines";
                RunPageLink = "Document Type" = const(Order), "Prod. Order No." = field("No.");
                ToolTip = 'Shows Purchase Order Lines for Subcontracting.';
            }
        }
        addafter("Item Ledger E&ntries")
        {
            action("Subcontracting Transfer Entries")
            {
                ApplicationArea = All;
                Caption = 'Subcontracting Transfer Entries';
                Image = ItemLedger;
                RunObject = page "Item Ledger Entries";
                RunPageLink = "Entry Type" = const(Transfer),
                                      "Prod. Order No." = field("No.");
                RunPageView = sorting("Order Type", "Order No.");
                ToolTip = 'View the list of subcontracting transfers.';
            }
        }
    }
}