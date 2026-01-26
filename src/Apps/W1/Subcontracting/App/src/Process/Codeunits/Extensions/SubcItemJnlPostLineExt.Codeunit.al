// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;

codeunit 99001515 "Subc. ItemJnlPostLine Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInitItemLedgEntry, '', false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
        UpdateNewItemLedgerEntry(NewItemLedgEntry, ItemJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnBeforeInsertCapLedgEntry, '', false, false)]
    local procedure OnBeforeInsertCapLedgEntry(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        UpdateCapLedgerEntry(CapLedgEntry, ItemJournalLine);
    end;

#if not CLEAN27
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterPostOutput, '', false, false)]
#pragma warning restore AL0432
#else
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Item Jnl.-Post Line", OnAfterPostOutput, '', false, false)]
#endif
    local procedure OnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
        UpdateProdOrderRoutingLine(ProdOrderLine, ItemJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnBeforeInsertCapValueEntry, '', false, false)]
    local procedure "Item Jnl.-Post Line_OnBeforeInsertCapValueEntry"(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ClearInvoicedQuantityForItemChargeSubAssign(ValueEntry, ItemJnlLine);
    end;

    local procedure UpdateProdOrderRoutingLine(var ProdOrderLine: Record "Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
    begin
        if ItemJournalLine.Subcontracting then begin
            ProductionOrder.SetLoadFields("Created from Purch. Order");
            if ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.") then
                if ProdOrderRoutingLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", ProdOrderLine."Routing No.", ItemJournalLine."Operation No.") then begin
                    CapacityLedgerEntry.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
                    CapacityLedgerEntry.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
                    CapacityLedgerEntry.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
                    CapacityLedgerEntry.SetRange("Order No.", ProdOrderRoutingLine."Prod. Order No.");
                    CapacityLedgerEntry.CalcSums("Output Quantity");
                    if CapacityLedgerEntry."Output Quantity" >= ProdOrderLine."Quantity (Base)" then
                        ProdOrderRoutingLine."Routing Status" := "Prod. Order Routing Status"::Finished;
                    ProdOrderRoutingLine.Modify();
                end;
        end;
    end;

    local procedure UpdateNewItemLedgerEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgerEntry."Prod. Order No." := ItemJournalLine."Prod. Order No.";
        NewItemLedgerEntry."Prod. Order Line No." := ItemJournalLine."Prod. Order Line No.";
        NewItemLedgerEntry."Subcontr. Purch. Order No." := ItemJournalLine."Subcontr. Purch. Order No.";
        NewItemLedgerEntry."Subcontr. PO Line No." := ItemJournalLine."Subcontr. PO Line No.";
        NewItemLedgerEntry."Operation No." := ItemJournalLine."Subc. Operation No.";
    end;

    local procedure UpdateCapLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        CapacityLedgerEntry."Subcontractor No." := ItemJournalLine."Source No.";
        CapacityLedgerEntry."Subcontr. Purch. Order No." := ItemJournalLine."Subcontr. Purch. Order No.";
        CapacityLedgerEntry."Subcontr. PO Line No." := ItemJournalLine."Subcontr. PO Line No.";
    end;

    local procedure ClearInvoicedQuantityForItemChargeSubAssign(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine."Item Charge Sub. Assign." and (ValueEntry."Entry Type" = "Cost Entry Type"::"Direct Cost") then
            ValueEntry."Invoiced Quantity" := 0;
    end;
}