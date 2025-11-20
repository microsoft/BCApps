// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory;

codeunit 99000784 "Mfg. Undo Purch. Rcpt. Line"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnUpdateItemJnlLineProdOrderSubcontracting', '', false, false)]
    local procedure OnUpdateItemJnlLineProdOrderSubcontracting(var ItemJnlLine: Record "Item Journal Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempOutputItemLedgerEntry: Record "Item Ledger Entry" temporary; var OneLinePostingUndo: Boolean)
    begin
        UpdateItemJnlLineProdOrderSubcontracting(ItemJnlLine, PurchRcptLine, TempOutputItemLedgerEntry, OneLinePostingUndo);
    end;

    local procedure UpdateItemJnlLineProdOrderSubcontracting(var ItemJnlLine: Record "Item Journal Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempOutputItemLedgerEntry: Record "Item Ledger Entry" temporary; var OneLinePostingUndo: Boolean)
    var
        TempCapacityLedgEntry: Record "Capacity Ledger Entry" temporary;
        UOMMgt: Codeunit "Unit of Measure Management";
        OutputItemLedgerEntryCount: Integer;
    begin
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Production;
        ItemJnlLine."Order No." := PurchRcptLine."Prod. Order No.";
        ItemJnlLine."Order Line No." := PurchRcptLine."Prod. Order Line No.";

        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Vendor;
        ItemJnlLine."Source No." := PurchRcptLine."Buy-from Vendor No.";
        ItemJnlLine."Invoice-to Source No." := PurchRcptLine."Pay-to Vendor No.";

        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Output;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::" ";
        ItemJnlLine."Document Line No." := 0;
        ItemJnlLine.Description := PurchRcptLine.Description;
        ItemJnlLine.Subcontracting := true;

        GetCapacityAndItemLedgerEntries(TempCapacityLedgEntry, TempOutputItemLedgerEntry, PurchRcptLine);
        if TempCapacityLedgEntry.FindLast() then;

        OutputItemLedgerEntryCount := TempOutputItemLedgerEntry.Count();

        ItemJnlLine."Quantity (Base)" := -UOMMgt.CalcBaseQty(PurchRcptLine."No.", '', PurchRcptLine."Unit of Measure Code", PurchRcptLine.Quantity, PurchRcptLine."Qty. per Unit of Measure", 0);
        ItemJnlLine."Output Quantity" := -PurchRcptLine.Quantity;
        ItemJnlLine."Output Quantity (Base)" := ItemJnlLine."Quantity (Base)";
        ItemJnlLine."Invoiced Qty. (Base)" := 0;

        ItemJnlLine."Unit Cost" := PurchRcptLine."Unit Cost (LCY)";
        ItemJnlLine."Unit Cost (ACY)" := PurchRcptLine."Unit Cost";

        ItemJnlLine.Type := ItemJnlLine.Type::"Work Center";
        ItemJnlLine."No." := PurchRcptLine."Work Center No.";
        ItemJnlLine."Routing No." := PurchRcptLine."Routing No.";
        ItemJnlLine."Routing Reference No." := PurchRcptLine."Routing Reference No.";
        ItemJnlLine."Operation No." := PurchRcptLine."Operation No.";
        ItemJnlLine."Work Center No." := PurchRcptLine."Work Center No.";
        ItemJnlLine."Unit Cost Calculation" := ItemJnlLine."Unit Cost Calculation"::Units;

        //to undo capacity ledger entry time values
        ItemJnlLine."Run Time" := -TempCapacityLedgEntry."Run Time";
        ItemJnlLine."Setup Time" := -TempCapacityLedgEntry."Setup Time";
        ItemJnlLine."Run Time" := -TempCapacityLedgEntry."Run Time";
        ItemJnlLine."Stop Time" := -TempCapacityLedgEntry."Stop Time";

        ItemJnlLine."Applies-to Entry" := 0;

        if OutputItemLedgerEntryCount = 1 then begin
            TempOutputItemLedgerEntry.FindFirst();
            if (TempOutputItemLedgerEntry."Lot No." = '') and (TempOutputItemLedgerEntry."Serial No." = '') then
                ItemJnlLine."Applies-to Entry" := TempOutputItemLedgerEntry."Entry No.";
        end;

        OneLinePostingUndo := ItemJnlLine."Applies-to Entry" <> 0;
    end;

    local procedure GetCapacityAndItemLedgerEntries(var TempCapacityLedgEntry: Record "Capacity Ledger Entry" temporary; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        CapacityLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CapacityLedgEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        CapacityLedgEntry.SetCurrentKey("Document No.", "Posting Date");
        CapacityLedgEntry.SetRange("Document No.", PurchRcptLine."Document No.");
        CapacityLedgEntry.SetRange("Order Type", CapacityLedgEntry."Order Type"::Production);
        CapacityLedgEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        CapacityLedgEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");

        if CapacityLedgEntry.FindSet() then
            repeat
                TempCapacityLedgEntry := CapacityLedgEntry;
                TempCapacityLedgEntry.Insert();
            until CapacityLedgEntry.Next() = 0;

        ItemLedgEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        ItemLedgEntry.SetRange("Source Type", ItemLedgEntry."Source Type"::Vendor);
        ItemLedgEntry.SetRange("Source No.", PurchRcptLine."Buy-from Vendor No.");
        ItemLedgEntry.SetFilter("Remaining Quantity", '>0');
        if ItemLedgEntry.FindSet() then
            repeat
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert();
            until ItemLedgEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", 'OnCollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine', '', false, false)]
    local procedure OnCollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; PurchRcptLine: Record "Purch. Rcpt. Line"; var Result: Boolean)
    begin
        Result := CollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(TempItemLedgerEntry, PurchRcptLine);
    end;

    local procedure CollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        OutputEntriesExist: Boolean;
    begin
        TempItemLedgEntry.Reset();
        if not TempItemLedgEntry.IsEmpty() then
            TempItemLedgEntry.DeleteAll();

        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgEntry.SetBaseLoadFields();
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        ItemLedgEntry.SetRange("Item No.", PurchRcptLine."No.");
        ItemLedgEntry.SetRange(Open, true);

        if ItemLedgEntry.FindSet() then
            repeat
                TempItemLedgEntry := ItemLedgEntry;
                TempItemLedgEntry.Insert();
            until ItemLedgEntry.Next() = 0;

        OutputEntriesExist := not TempItemLedgEntry.IsEmpty();
        if not OutputEntriesExist then begin
            ItemLedgEntry.SetRange(Open);
            OutputEntriesExist := not ItemLedgEntry.IsEmpty();
        end;

        exit(OutputEntriesExist);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", 'OnPostItemJnlLineAppliedToListOnAfterSetInvoicedQty', '', true, true)]
    local procedure OnPostItemJnlLineAppliedToListOnAfterSetInvoicedQty(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
        if ItemJournalLine.Correction and ItemJournalLine.Subcontracting then
            ItemJournalLine."Output Quantity (Base)" := -TempApplyToItemLedgEntry.Quantity;
    end;

}