// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
pageextension 99001504 "Subc. Rel. Prod. Order" extends "Released Production Order"
{
    actions
    {
        addafter("Registered Invt. Movement Lines")
        {
            action("Subcontracting Purchase Lines")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Order Lines';
                Image = SubcontractingWorksheet;
                RunObject = page "Purchase Lines";
                RunPageLink = "Document Type" = const(Order), "Prod. Order No." = field("No.");
                ToolTip = 'Show purchase order lines for subcontracting.';
            }
        }
        addafter("Item Ledger E&ntries")
        {
            action("Subcontracting Transfer Entries")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Transfer Entries';
                Image = ItemLedger;
                RunObject = page "Item Ledger Entries";
                RunPageLink = "Entry Type" = const(Transfer),
                                      "Prod. Order No." = field("No.");
                RunPageView = sorting("Order Type", "Order No.");
                ToolTip = 'View the list of subcontracting transfers.';
            }
            action("WIP Ledger Entries")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Ledger Entries';
                Image = LedgerEntries;
                RunObject = page "Subc. WIP Ledger Entries";
                RunPageLink = "Prod. Order Status" = field(Status), "Prod. Order No." = field("No.");
                ToolTip = 'View the Subcontractor WIP Ledger Entries for this production order.';
            }
        }
        addlast("F&unctions")
        {
            action("WIP Adjustment")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Adjustment';
                Image = AdjustEntries;
                ToolTip = 'Manually adjust the WIP quantities for all routing operations of this production order.';

                trigger OnAction()
                var
                    WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
                    WIPAdjustmentPage: Page "Subc. WIP Adjustment";
                begin
                    WIPLedgerEntry.SetProductionOrderFilter(Rec, true);
                    WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
                    WIPAdjustmentPage.SetDocumentNo(Rec."No.");
                    WIPAdjustmentPage.RunModal();
                end;
            }
        }
    }
}