// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Subcontracting;

pageextension 149913 "Subc. Prod. Order Rtng. TST" extends "Prod. Order Routing"
{
    actions
    {
        addlast(Processing)
        {
            action(CreateWIPLedgerEntry)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create WIP Ledger Entry (Test)';
                Image = CreateDocument;
                ToolTip = 'Creates a WIP ledger entry for this routing line at the specified location and quantity, then opens the WIP Adjustment page to verify the result.';

                trigger OnAction()
                var
                    ProdOrder: Record "Production Order";
                    ProdOrderLine: Record "Prod. Order Line";
                    WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
                    SubcMgmtLibrary: Codeunit "Subc. Management Library";
                    WIPEntryCreateDlg: Page "Subc. WIP Entry Create Dialog";
                begin
                    if WIPEntryCreateDlg.RunModal() <> Action::OK then
                        exit;

                    ProdOrder.Get(Rec.Status, Rec."Prod. Order No.");
                    ProdOrderLine.Get(Rec.Status, Rec."Prod. Order No.", Rec."Routing Reference No.");

                    SubcMgmtLibrary.CreateWIPLedgerEntry(
                        WIPLedgerEntry,
                        ProdOrderLine."Item No.",
                        WIPEntryCreateDlg.GetLocationCode(),
                        ProdOrder,
                        ProdOrderLine,
                        Rec,
                        Rec."Work Center No.",
                        WIPEntryCreateDlg.GetQuantityBase(),
                        false);
                end;
            }
        }
    }
}