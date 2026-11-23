// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;

codeunit 20581 "Subc. WIP Receipt Mgt."
{
    Access = Internal;
    Permissions = tabledata "Subcontractor WIP Ledger Entry" = RI,
                  tabledata "Subc. WIP Receipt Appl." = RIM,
                  tabledata "Subc. WIP Receipt Detail" = RI;

    var
        Availability: Codeunit "Subc. WIP Availability";
        ShortfallErr: Label 'There is insufficient matching unprocessed WIP at the subcontractor to receive this quantity.';
        DependentMovementErr: Label 'The original processed WIP has been moved or allocated. Reverse the dependent movement and release its open transfer quantity before undoing this receipt.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInsertCapLedgEntry, '', false, false)]
    local procedure CaptureReceipt(var CapLedgEntry: Record "Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    var
        Application: Record "Subc. WIP Receipt Appl.";
        PurchaseLine: Record "Purchase Line";
        RoutingLine: Record "Prod. Order Routing Line";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
    begin
        if (ItemJournalLine."Document Type" <> ItemJournalLine."Document Type"::"Purchase Receipt") or
           (CapLedgEntry."Output Quantity" <= 0) or
           (ItemJournalLine."Subc. Purch. Order No." = '')
        then
            exit;
        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order,
            ItemJournalLine."Subc. Purch. Order No.", ItemJournalLine."Subc. Purch. Order Line No.")
        then
            exit;
        if not CohortMgt.IsTracked("Production Order Status"::Released, PurchaseLine."Prod. Order No.") then
            exit;
        if not RoutingLine.Get(RoutingLine.Status::Released, PurchaseLine."Prod. Order No.",
            PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            exit;
        if not RoutingLine."Transfer WIP Item" then
            exit;
        if Application.Get(CapLedgEntry."Entry No.") then
            exit;
        Application."Capacity Entry No." := CapLedgEntry."Entry No.";
        Application."Receipt No." := ItemJournalLine."Document No.";
        Application."Receipt Line No." := ItemJournalLine."Document Line No.";
        Application."Purchase Order No." := PurchaseLine."Document No.";
        Application."Purchase Order Line No." := PurchaseLine."Line No.";
        Application."Application ID" := CreateGuid();
        Application.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterPurchRcptLineInsert, '', false, false)]
    local procedure FinalizeReceipt(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        Application: Record "Subc. WIP Receipt Appl.";
        CapacityEntry: Record "Capacity Ledger Entry";
    begin
        Application.LockTable();
        Application.SetRange("Receipt No.", PurchRcptLine."Document No.");
        Application.SetRange("Receipt Line No.", PurchRcptLine."Line No.");
        Application.SetRange(Finalized, false);
        if Application.FindSet(true) then
            repeat
                CapacityEntry.Get(Application."Capacity Entry No.");
                Application."Quantity (Base)" := CapacityEntry."Output Quantity";
                ApplyReceipt(Application, PurchaseLine, PurchRcptLine);
                Application.Finalized := true;
                Application.Modify();
            until Application.Next() = 0;
    end;

    local procedure ApplyReceipt(Application: Record "Subc. WIP Receipt Appl."; PurchaseLine: Record "Purchase Line"; ReceiptLine: Record "Purch. Rcpt. Line")
    var
        Donor: Record "Subcontractor WIP Ledger Entry";
        ProductionLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Detail: Record "Subc. WIP Receipt Detail";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        ProcessedLots: List of [Guid];
        LocationCode: Code[10];
        Remaining: Decimal;
        QuantityBase: Decimal;
        DetailNo: Integer;
    begin
        ProductionLine.LockTable();
        ProductionLine.Get(ProductionLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        LocationCode := PurchaseHeader."Subc. Location Code";
        if LocationCode = '' then
            LocationCode := Vendor."Subc. Location Code";
        Donor.SetRange("State Tracked", true);
        Donor.SetRange("Lineage ID", CohortMgt.GetLineage(ProductionLine.Status, ProductionLine."Prod. Order No."));
        Donor.SetRange("Prod. Order Status", ProductionLine.Status);
        Donor.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        Donor.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        Donor.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        Donor.SetRange("Routing No.", PurchaseLine."Routing No.");
        Donor.SetRange("Operation No.", PurchaseLine."Operation No.");
        Donor.SetRange("Item No.", ProductionLine."Item No.");
        Donor.SetRange("Variant Code", ProductionLine."Variant Code");
        Donor.SetRange("Location Code", LocationCode);
        Donor.SetRange("In Transit", false);
        Donor.SetRange("WIP State", Donor."WIP State"::Unprocessed);
        Donor.SetFilter("Quantity (Base)", '>0');
        Remaining := Application."Quantity (Base)";
        if Donor.FindSet() then
            repeat
                if not ProcessedLots.Contains(Donor."Supply Lot ID") then begin
                    ProcessedLots.Add(Donor."Supply Lot ID");
                    Availability.LockPosition(Donor."Source Position No.");
                    QuantityBase := Availability.Available(Donor."Source Position No.", Donor."WIP State", Donor."Supply Lot ID", '', 0);
                    if QuantityBase > Remaining then
                        QuantityBase := Remaining;
                    if QuantityBase > 0 then begin
                        DetailNo += 1;
                        Detail.Init();
                        Detail."Capacity Entry No." := Application."Capacity Entry No.";
                        Detail."Detail No." := DetailNo;
                        Detail."Source Position No." := Donor."Source Position No.";
                        Detail."Donor Lot ID" := Donor."Supply Lot ID";
                        Detail."Quantity (Base)" := QuantityBase;
                        Detail."Unprocessed Entry No." := InsertEffect(Donor, Application, ReceiptLine, -QuantityBase, false);
                        Detail."Processed Entry No." := InsertEffect(Donor, Application, ReceiptLine, QuantityBase, true);
                        Detail.Insert();
                        Remaining -= QuantityBase;
                    end;
                end;
            until (Donor.Next() = 0) or (Remaining = 0);
        if Remaining <> 0 then
            Error(ShortfallErr);
    end;

    local procedure InsertEffect(Template: Record "Subcontractor WIP Ledger Entry"; Application: Record "Subc. WIP Receipt Appl."; ReceiptLine: Record "Purch. Rcpt. Line"; QuantityBase: Decimal; Processed: Boolean): Integer
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
    begin
        Entry := Template;
        Entry."Entry No." := Entry.GetNextEntryNo();
        Entry."Document Type" := Entry."Document Type"::"Purchase Receipt";
        Entry."Document No." := ReceiptLine."Document No.";
        Entry."Document Line No." := ReceiptLine."Line No.";
        Entry."Posting Date" := ReceiptLine."Posting Date";
        Entry."Purchase Receipt No." := ReceiptLine."Document No.";
        Entry."Purchase Receipt Line No." := ReceiptLine."Line No.";
        Entry."Receipt Application ID" := Application."Application ID";
        Entry."Quantity (Base)" := QuantityBase;
        Entry."Reversed Entry No." := 0;
        if Processed then begin
            Entry."WIP State" := Entry."WIP State"::Processed;
            Entry."Supply Lot ID" := Application."Application ID";
        end;
        if QuantityBase > 0 then
            Entry."Entry Type" := Entry."Entry Type"::"Positive Adjustment"
        else
            Entry."Entry Type" := Entry."Entry Type"::"Negative Adjustment";
        Entry.Insert();
        exit(Entry."Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", OnAfterPurchRcptLineModify, '', false, false)]
    local procedure UndoReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        ReverseReceipt(PurchRcptLine);
    end;

    internal procedure ReverseReceipt(ReceiptLine: Record "Purch. Rcpt. Line")
    var
        Application: Record "Subc. WIP Receipt Appl.";
        Detail: Record "Subc. WIP Receipt Detail";
        Original: Record "Subcontractor WIP Ledger Entry";
        ProductionLine: Record "Prod. Order Line";
    begin
        Application.LockTable();
        Application.SetRange("Receipt No.", ReceiptLine."Document No.");
        Application.SetRange("Receipt Line No.", ReceiptLine."Line No.");
        Application.SetRange(Finalized, true);
        Application.SetRange(Reversed, false);
        if Application.FindSet(true) then
            repeat
                Detail.SetRange("Capacity Entry No.", Application."Capacity Entry No.");
                if Detail.FindSet() then
                    repeat
                        Original.Get(Detail."Processed Entry No.");
                        ProductionLine.LockTable();
                        ProductionLine.Get(Original."Prod. Order Status", Original."Prod. Order No.", Original."Prod. Order Line No.");
                        Availability.LockPosition(Detail."Source Position No.");
                        if Availability.Available(Detail."Source Position No.", "Subc. WIP Processing State"::Processed,
                            Application."Application ID", '', 0) < Detail."Quantity (Base)"
                        then
                            Error(DependentMovementErr);
                        ReverseEntry(Original);
                        Original.Get(Detail."Unprocessed Entry No.");
                        ReverseEntry(Original);
                    until Detail.Next() = 0;
                Application.Reversed := true;
                Application.Modify();
            until Application.Next() = 0;
    end;

    local procedure ReverseEntry(Original: Record "Subcontractor WIP Ledger Entry")
    var
        Inverse: Record "Subcontractor WIP Ledger Entry";
    begin
        Inverse := Original;
        Inverse."Entry No." := Inverse.GetNextEntryNo();
        Inverse."Posting Date" := WorkDate();
        Inverse."Quantity (Base)" := -Original."Quantity (Base)";
        Inverse."Reversed Entry No." := Original."Entry No.";
        if Inverse."Quantity (Base)" > 0 then
            Inverse."Entry Type" := Inverse."Entry Type"::"Positive Adjustment"
        else
            Inverse."Entry Type" := Inverse."Entry Type"::"Negative Adjustment";
        Inverse.Insert();
    end;
}
