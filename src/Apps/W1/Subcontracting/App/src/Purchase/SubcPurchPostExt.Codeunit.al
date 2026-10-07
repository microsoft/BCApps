// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Warehouse.History;
codeunit 20535 "Subc. Purch. Post Ext"
{
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        CancelNotSupportedErr: Label 'You cannot cancel or correct posted purchase invoice %1 because it contains item charges assigned to a subcontracting order receipt.\Use the ''Create Corrective Credit Memo'' action to create a credit memo for this invoice.', Comment = '%1 = Posted Purchase Invoice No.';
        SeparateInvoiceReversalNotSupportedErr: Label 'You cannot automatically reverse this posted purchase invoice because it contains lines copied from a subcontracting order receipt.';
        SeparateInvoiceReversalNotSupportedTitleLbl: Label 'Posted purchase invoice cannot be reversed';
        SeparateInvoiceReversalNotSupportedDetailedMsg: Label 'Cancel, Correct, and Create Corrective Credit Memo are not supported for purchase invoices created from subcontracting receipt lines.';
        ShowPostedPurchaseInvoiceLbl: Label 'Show Posted Purchase Invoice';
        ItemChargeAgainstUndoneRcptErr: Label 'You cannot post the item charge because it is assigned to subcontracting receipt %1, line %2, which has been undone.\Remove the item charge assignment from the undone receipt line.', Comment = '%1 = Posted Receipt No., %2 = Posted Receipt Line No.';
        GetTrackedSubcontractingRcptNotSupportedErr: Label 'You cannot copy tracked subcontracting receipt lines into this document. Invoice tracked subcontracting receipts from the subcontracting order instead.';
        ItemLedgerEntryBufferMustBeTemporaryErr: Label 'The item ledger entry buffer must be temporary.';

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", OnBeforeInsertInvLineFromRcptLine, '', false, false)]
    local procedure BlockTrackedSubcontractingReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        if not PurchRcptLineHasProdOrder(PurchRcptLine) or not ItemIsTracked(PurchRcptLine."No.") then
            exit;
        if not PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;
        SetQuantityBaseOnSubcontractingServiceLine(PurchOrderLine, PurchRcptLine);
        if IsFullTrackedSubcontractingReceiptSupported(PurchRcptLine) then
            exit;

        Error(GetTrackedSubcontractingRcptNotSupportedErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Matched Order Line Mgmt.", OnGetPurchaseOrderLinesOnAfterSetPurchaseLineOrderFilters, '', false, false)]
    local procedure ExcludeSubcontractingLinesOnGetPurchaseOrderLines(var PurchaseLineOrder: Record "Purchase Line"; PurchaseHeaderInvoice: Record "Purchase Header")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PurchaseLineOrder.SetRange("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnAfterTestCorrectInvoiceIsAllowed, '', false, false)]
    local procedure BlockCancelIfHasSubcontractingItemChargeValueEntry(var PurchInvHeader: Record "Purch. Inv. Header"; Cancelling: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.SetFilter("Item Charge No.", '<>%1', '');
        ValueEntry.SetFilter("Capacity Ledger Entry No.", '<>%1', 0);
        if ValueEntry.IsEmpty() then
            exit;

        Error(CancelNotSupportedErr, PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnBeforeTestIfInvoiceIsPaid, '', false, false)]
    local procedure BlockSeparateSubcontractingInvoiceReversalBeforeLineValidation(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        CheckSeparateSubcontractingInvoiceReversalIsSupported(PurchInvHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnBeforeCreateCopyDocument, '', false, false)]
    local procedure BlockSeparateSubcontractingInvoiceCopy(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; SkipCopyFromDescription: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        CheckSeparateSubcontractingInvoiceReversalIsSupported(PurchInvHeader);
    end;

    local procedure CheckSeparateSubcontractingInvoiceReversalIsSupported(PurchInvHeader: Record "Purch. Inv. Header")
    var
        ValueEntry: Record "Value Entry";
    begin
        if (PurchInvHeader."Pre-Assigned No." = '') or (PurchInvHeader."Order No." = '') then
            exit;
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Capacity Ledger Entry No.", '<>%1', 0);
        if not ValueEntry.IsEmpty() then
            Error(CreateSeparateInvoiceReversalNotSupportedErrorInfo(PurchInvHeader));
    end;

    local procedure CreateSeparateInvoiceReversalNotSupportedErrorInfo(PurchInvHeader: Record "Purch. Inv. Header") ReversalNotSupportedErrorInfo: ErrorInfo
    begin
        ReversalNotSupportedErrorInfo.Title := SeparateInvoiceReversalNotSupportedTitleLbl;
        ReversalNotSupportedErrorInfo.Message := SeparateInvoiceReversalNotSupportedErr;
        ReversalNotSupportedErrorInfo.DetailedMessage := SeparateInvoiceReversalNotSupportedDetailedMsg;
        ReversalNotSupportedErrorInfo.DataClassification := DataClassification::SystemMetadata;
        ReversalNotSupportedErrorInfo.ErrorType := ErrorType::Client;
        ReversalNotSupportedErrorInfo.RecordId := PurchInvHeader.RecordId;
        ReversalNotSupportedErrorInfo.PageNo := Page::"Posted Purchase Invoice";
        ReversalNotSupportedErrorInfo.AddNavigationAction(ShowPostedPurchaseInvoiceLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnBeforeCopyHandledItemTrkgToPurchLine, '', false, false)]
    local procedure CopyTrackedSubcontractingOutputToSeparateInvoice(FromPurchLine: Record "Purchase Line"; var ToPurchLine: Record "Purchase Line"; CheckLineQty: Boolean; var IsHandled: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MissingExactCostReversingLink: Boolean;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ToPurchLine."Document Type" <> ToPurchLine."Document Type"::Invoice then
            exit;
        if not PurchRcptLine.Get(ToPurchLine."Receipt No.", ToPurchLine."Receipt Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) or not ItemIsTracked(PurchRcptLine."No.") then
            exit;
        if not PurchRcptLineIsLastOperation(PurchRcptLine) then begin
            IsHandled := true;
            exit;
        end;
        if CheckLineQty and (ToPurchLine.Quantity <> PurchRcptLine.Quantity) then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);

        SetQuantityBaseOnSubcontractingServiceLine(FromPurchLine, PurchRcptLine);
        if not IsFullTrackedOutputSetSupported(PurchRcptLine, ItemLedgerEntry) then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);

        ToPurchLine.Validate(Quantity, PurchRcptLine.Quantity);
        ToPurchLine.Validate("Qty. to Invoice", ToPurchLine.Quantity);
        PurchRcptLine.CalcBaseQuantities(ToPurchLine, PurchRcptLine."Quantity (Base)" / PurchRcptLine.Quantity);
        ToPurchLine.Modify(true);
        if not CopyItemLedgerEntriesUpToQuantity(
            TempItemLedgerEntry, ItemLedgerEntry, PurchRcptLine."Quantity (Base)", 0)
        then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);

        IsHandled := true;
        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
            TempItemLedgerEntry, ToPurchLine, false, MissingExactCostReversingLink,
            false, false, true);
        CreateInvoiceTrackingSpecifications(ToPurchLine, TempItemLedgerEntry);
    end;

    local procedure CopyItemLedgerEntriesUpToQuantity(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; QuantityBase: Decimal; QuantityAlreadyInvoicedBase: Decimal): Boolean
    var
        BufferMustBeTemporaryErrorInfo: ErrorInfo;
        EntryQuantityBase: Decimal;
        QuantityToCopy: Decimal;
        QuantityToSkipBase: Decimal;
        RemainingQuantityBase: Decimal;
    begin
        if not TempItemLedgerEntry.IsTemporary() then begin
            BufferMustBeTemporaryErrorInfo.DataClassification := DataClassification::SystemMetadata;
            BufferMustBeTemporaryErrorInfo.ErrorType := ErrorType::Internal;
            BufferMustBeTemporaryErrorInfo.Verbosity := Verbosity::Error;
            BufferMustBeTemporaryErrorInfo.Message := ItemLedgerEntryBufferMustBeTemporaryErr;
            Error(BufferMustBeTemporaryErrorInfo);
        end;

        TempItemLedgerEntry.Reset();
        TempItemLedgerEntry.DeleteAll();
        RemainingQuantityBase := Abs(QuantityBase);
        QuantityToSkipBase := Abs(QuantityAlreadyInvoicedBase);
        if (RemainingQuantityBase = 0) or not ItemLedgerEntry.FindSet() then
            exit(false);
        repeat
            EntryQuantityBase := Abs(ItemLedgerEntry.Quantity);
            if QuantityToSkipBase >= EntryQuantityBase then
                QuantityToSkipBase -= EntryQuantityBase
            else begin
                QuantityToCopy := EntryQuantityBase - QuantityToSkipBase;
                QuantityToSkipBase := 0;
                if QuantityToCopy > RemainingQuantityBase then
                    QuantityToCopy := RemainingQuantityBase;
                RemainingQuantityBase -= QuantityToCopy;
                if ItemLedgerEntry.Quantity < 0 then
                    QuantityToCopy := -QuantityToCopy;

                TempItemLedgerEntry := ItemLedgerEntry;
                TempItemLedgerEntry.Quantity := QuantityToCopy;
                TempItemLedgerEntry."Remaining Quantity" := QuantityToCopy;
                TempItemLedgerEntry.Insert();
            end;
        until (ItemLedgerEntry.Next() = 0) or (RemainingQuantityBase = 0);

        TempItemLedgerEntry.Reset();
        exit((RemainingQuantityBase = 0) and not TempItemLedgerEntry.IsEmpty());
    end;

    local procedure CreateInvoiceTrackingSpecifications(PurchaseLine: Record "Purchase Line"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        NextEntryNo: Integer;
    begin
        ReservationEntry.SetSourceFilter(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
            PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        if not ReservationEntry.FindSet(true) then
            exit;

        TrackingSpecification.LockTable();
        NextEntryNo := TrackingSpecification.GetLastEntryNo() + 1;
        repeat
            SetReservationEntryOutputApplication(ReservationEntry, TempItemLedgerEntry);
            TrackingSpecification.Init();
            TrackingSpecification.TransferFields(ReservationEntry);
            TrackingSpecification."Entry No." := NextEntryNo;
            TrackingSpecification."Source Type" := Database::"Purchase Line";
            TrackingSpecification."Source Subtype" := PurchaseLine."Document Type".AsInteger();
            TrackingSpecification."Source ID" := PurchaseLine."Document No.";
            TrackingSpecification."Source Ref. No." := PurchaseLine."Line No.";
            TrackingSpecification."Qty. to Handle" := 0;
            TrackingSpecification."Qty. to Handle (Base)" := 0;
            TrackingSpecification."Qty. to Invoice (Base)" := ReservationEntry."Qty. to Invoice (Base)";
            TrackingSpecification."Item Ledger Entry No." := ReservationEntry."Appl.-to Item Entry";
            TrackingSpecification.Insert();

            ReservationEntry."Item Ledger Entry No." := TrackingSpecification."Entry No.";
            ReservationEntry.Modify();
            NextEntryNo += 1;
        until ReservationEntry.Next() = 0;
    end;

    local procedure SetReservationEntryOutputApplication(var ReservationEntry: Record "Reservation Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
        TempItemLedgerEntry.Reset();
        TempItemLedgerEntry.SetRange("Item No.", ReservationEntry."Item No.");
        TempItemLedgerEntry.SetRange("Variant Code", ReservationEntry."Variant Code");
        TempItemLedgerEntry.SetRange("Serial No.", ReservationEntry."Serial No.");
        TempItemLedgerEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        TempItemLedgerEntry.SetRange("Package No.", ReservationEntry."Package No.");
        if TempItemLedgerEntry.Count() <> 1 then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);
        TempItemLedgerEntry.FindFirst();
        if Abs(TempItemLedgerEntry.Quantity) <> Abs(ReservationEntry."Quantity (Base)") then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);

        ReservationEntry."Appl.-to Item Entry" := TempItemLedgerEntry."Entry No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeGetPurchRcptLineFromTrackingOrUpdateItemEntryRelation, '', false, false)]
    local procedure UseSubcontractingOutputApplicationForTrackedReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line"; var TrackingSpecification: Record "Tracking Specification"; var ItemEntryRelation: Record "Item Entry Relation"; var IsHandled: Boolean)
    begin
        if not PurchRcptLineHasProdOrder(PurchRcptLine) or not ItemIsTracked(PurchRcptLine."No.") then
            exit;
        if not PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;
        if TrackingSpecification."Item Ledger Entry No." = 0 then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);

        ItemEntryRelation."Item Entry No." := TrackingSpecification."Item Ledger Entry No.";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeItemJnlPostLine, '', false, false)]
    local procedure "Purch.-Post_OnBeforeItemJnlPostLine"(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        FillItemJnlLineForSubcontractingItemCharge(ItemJournalLine, TempItemChargeAssignmentPurch);
        if not PurchRcptLine.Get(PurchaseLine."Receipt No.", PurchaseLine."Receipt Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) or not ItemIsTracked(PurchRcptLine."No.") or not PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;

        CopySubcontractingProdOrderFieldsToItemJnlLine(ItemJournalLine, PurchRcptLine);
        ItemJournalLine."Subc. Item Charge Assign." := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Purch.-Post", OnAfterPostItemJnlLineCopyProdOrder, '', false, false)]
    local procedure MfgPurchPostOnAfterPostItemJnlLineCopyProdOrder(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PurchRcptLine.Get(PurchLine."Receipt No.", PurchLine."Receipt Line No.") then
            SetSubcontractingPurchaseIdentity(ItemJnlLine, PurchRcptLine)
        else begin
            ItemJnlLine."Subc. Purch. Order No." := PurchLine."Document No.";
            ItemJnlLine."Subc. Purch. Order Line No." := PurchLine."Line No.";
            ItemJnlLine."Subc. Operation No." := PurchLine."Operation No.";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnInsertValueEntryOnBeforeUpdateItemLedgerEntry, '', false, false)]
    local procedure UpdateTrackedSubcontractingInvoiceCapacityEntries(
        var ValueEntry: Record "Value Entry";
        var ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        var IsHandled: Boolean)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if IsHandled then
            exit;
        if ValueEntry."Entry Type" <> ValueEntry."Entry Type"::"Direct Cost" then
            exit;
        if not SetTrackedSubcontractingCapacityEntryFilters(CapacityLedgerEntry, ItemLedgerEntry, ItemJournalLine) then
            exit;

        CapacityLedgerEntry.LockTable();
        if not CapacityLedgerEntry.FindSet(true) then
            exit;
        repeat
            CapacityLedgerEntry."Invoiced Quantity" := CapacityLedgerEntry."Output Quantity";
            CapacityLedgerEntry."Completely Invoiced" := true;
            CapacityLedgerEntry.Modify();
        until CapacityLedgerEntry.Next() = 0;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnBeforeInsertValueEntry, '', false, false)]
    local procedure SetTrackedSubcontractingInvoiceCapacityCostTarget(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not ItemLedgerEntry.Get(ItemJournalLine."Item Shpt. Entry No.") then
            exit;
        if not SetTrackedSubcontractingCapacityEntryFilters(CapacityLedgerEntry, ItemLedgerEntry, ItemJournalLine) then
            exit;
        if not CapacityLedgerEntry.FindFirst() then
            exit;

        ValueEntry."Item Ledger Entry No." := 0;
        ValueEntry."Capacity Ledger Entry No." := CapacityLedgerEntry."Entry No.";
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::" ";
    end;

    local procedure SetTrackedSubcontractingCapacityEntryFilters(
        var CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        if ItemJournalLine."Entry Type" <> ItemJournalLine."Entry Type"::Purchase then
            exit(false);
        if ItemJournalLine."Subc. Item Charge Assign." or (ItemJournalLine."Subc. Purch. Order No." = '') then
            exit(false);
        if (ItemJournalLine.Quantity <> 0) or (ItemJournalLine."Invoiced Quantity" = 0) then
            exit(false);
        if ItemLedgerEntry."Entry No." <> ItemJournalLine."Item Shpt. Entry No." then
            exit(false);

        CapacityLedgerEntry.SetRange("Item Register No.", ItemLedgerEntry."Item Register No.");
        CapacityLedgerEntry.SetRange(Subcontracting, true);
        CapacityLedgerEntry.SetRange("Subc. Purch. Order No.", ItemJournalLine."Subc. Purch. Order No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order Line No.", ItemJournalLine."Subc. Purch. Order Line No.");
        exit(true);
    end;

    local procedure SetSubcontractingPurchaseIdentity(var ItemJnlLine: Record "Item Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        ItemJnlLine."Subc. Purch. Order No." := PurchRcptLine."Order No.";
        ItemJnlLine."Subc. Purch. Order Line No." := PurchRcptLine."Order Line No.";
        ItemJnlLine."Subc. Operation No." := PurchRcptLine."Operation No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemChargePerRcptOnAfterCalcDistributeCharge, '', false, false)]
    local procedure "Purch.-Post_OnPostItemChargePerRcptOnAfterCalcDistributeCharge"(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SetQuantityBaseOnSubcontractingServiceLine(PurchLine, PurchRcptLine);
    end;

    ///Preserves receipt context for subcontracting item charges, except tracked last-operation receipts that use base item-ledger handling.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforePostItemChargePerRcpt, '', false, false)]
    local procedure StorePurchRcptLineForItemCharge(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var IsHandled: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SubcSessionState: Codeunit "Subc. Session State";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcSessionState.ClearAllDictionariesForKey('PurchRcptLineForItemCharge');
        if not PurchRcptLine.Get(TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) then
            exit;
        if PurchRcptLineIsLastOperation(PurchRcptLine) and ItemIsTracked(PurchRcptLine."No.") then
            exit;
        SubcSessionState.SetRecordID('PurchRcptLineForItemCharge', PurchRcptLine.RecordId);
    end;

    local procedure ItemIsTracked(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(ItemNo) then
            exit(false);
        exit(Item."Item Tracking Code" <> '');
    end;

    local procedure IsFullTrackedSubcontractingReceiptSupported(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if IsWarehouseReceiptOrigin(PurchRcptLine) then
            exit(false);
        if not UsesBaseUnitOfMeasure(PurchRcptLine) then
            exit(false);
        if not ItemUsesSupportedFullTracking(PurchRcptLine."No.") then
            exit(false);
        if PurchRcptLine."Qty. Invoiced (Base)" <> 0 then
            exit(false);
        if PurchRcptLine."Qty. Rcd. Not Invoiced" <> PurchRcptLine.Quantity then
            exit(false);
        if not PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit(false);

        exit(IsFullTrackedOutputSetSupported(PurchRcptLine, ItemLedgerEntry));
    end;

    local procedure IsWarehouseReceiptOrigin(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange(
            "Posted Source Document", PostedWhseReceiptLine."Posted Source Document"::"Posted Receipt");
        PostedWhseReceiptLine.SetRange("Posted Source No.", PurchRcptLine."Document No.");
        PostedWhseReceiptLine.SetRange("Source No.", PurchRcptLine."Order No.");
        PostedWhseReceiptLine.SetRange("Source Line No.", PurchRcptLine."Order Line No.");
        exit(not PostedWhseReceiptLine.IsEmpty());
    end;

    local procedure UsesBaseUnitOfMeasure(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Base Unit of Measure");
        if not Item.Get(PurchRcptLine."No.") then
            exit(false);

        exit(
            (PurchRcptLine."Unit of Measure Code" = Item."Base Unit of Measure") and
            (PurchRcptLine."Qty. per Unit of Measure" = 1));
    end;

    local procedure ItemUsesSupportedFullTracking(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.SetLoadFields("Item Tracking Code");
        Item.Get(ItemNo);
        ItemTrackingCode.SetLoadFields(
            "SN Specific Tracking", "Lot Specific Tracking", "Package Specific Tracking");
        ItemTrackingCode.Get(Item."Item Tracking Code");
        if ItemTrackingCode."Package Specific Tracking" then
            exit(false);

        exit(
            ItemTrackingCode."SN Specific Tracking" xor
            ItemTrackingCode."Lot Specific Tracking");
    end;

    local procedure IsFullTrackedOutputSetSupported(
        PurchRcptLine: Record "Purch. Rcpt. Line";
        var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        OutputQuantityBase: Decimal;
    begin
        if not SetSubcontractingOutputEntryFilters(ItemLedgerEntry, PurchRcptLine) then
            exit(false);
        if not ItemLedgerEntry.FindSet() then
            exit(false);
        repeat
            OutputQuantityBase += Abs(ItemLedgerEntry.Quantity);
            if (ItemLedgerEntry."Serial No." <> '') and (Abs(ItemLedgerEntry.Quantity) <> 1) then
                exit(false);
            if not HasUniqueOutputTrackingKey(ItemLedgerEntry, ItemLedgerEntry) then
                exit(false);
        until ItemLedgerEntry.Next() = 0;

        exit(OutputQuantityBase = Abs(PurchRcptLine."Quantity (Base)"));
    end;

    local procedure HasUniqueOutputTrackingKey(
        var FilteredItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        MatchingItemLedgerEntry: Record "Item Ledger Entry";
    begin
        MatchingItemLedgerEntry.CopyFilters(FilteredItemLedgerEntry);
        MatchingItemLedgerEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        MatchingItemLedgerEntry.SetRange("Variant Code", ItemLedgerEntry."Variant Code");
        MatchingItemLedgerEntry.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
        MatchingItemLedgerEntry.SetRange("Lot No.", ItemLedgerEntry."Lot No.");
        MatchingItemLedgerEntry.SetRange("Package No.", ItemLedgerEntry."Package No.");
        exit(MatchingItemLedgerEntry.Count() = 1);
    end;

    local procedure SetSubcontractingOutputEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
#pragma warning disable AA0210
        CapacityLedgerEntry.SetRange(Subcontracting, true);
        CapacityLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
        CapacityLedgerEntry.SetRange("Item No.", PurchRcptLine."No.");
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        CapacityLedgerEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order No.", PurchRcptLine."Order No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order Line No.", PurchRcptLine."Order Line No.");
        if not CapacityLedgerEntry.FindFirst() then
            exit(false);
#pragma warning restore AA0210

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", PurchRcptLine."No.");
        ItemLedgerEntry.SetRange("Item Register No.", CapacityLedgerEntry."Item Register No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", PurchRcptLine."Prod. Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", PurchRcptLine."Prod. Order Line No.");
        ItemLedgerEntry.SetRange("Subc. Purch. Order No.", PurchRcptLine."Order No.");
        ItemLedgerEntry.SetRange("Subc. Purch. Order Line No.", PurchRcptLine."Order Line No.");
        ItemLedgerEntry.SetRange(Positive, true);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeUpdatePurchLineDimSetIDFromAppliedEntry, '', false, false)]
    local procedure UpdatePurchLineDimSetIDFromCapLedgEntryForNonLastOperations(var PurchaseLineToPost: Record "Purchase Line"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SubcSessionState: Codeunit "Subc. Session State";
        StoredRecordID: RecordId;
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PurchaseLineToPost."Appl.-to Item Entry" = 0 then
            exit;
        SubcSessionState.GetRecordID('PurchRcptLineForItemCharge', StoredRecordID);
        SubcSessionState.ClearAllDictionariesForKey('PurchRcptLineForItemCharge');
        if StoredRecordID.TableNo() = 0 then
            exit;
        PurchRcptLine.SetLoadFields("Item Rcpt. Entry No.");
        PurchRcptLine.Get(StoredRecordID);
        if PurchRcptLine."Item Rcpt. Entry No." <> PurchaseLineToPost."Appl.-to Item Entry" then
            exit;
        CapacityLedgerEntry.SetLoadFields("Dimension Set ID");
        if CapacityLedgerEntry.Get(PurchaseLineToPost."Appl.-to Item Entry") then
            PurchaseLineToPost."Dimension Set ID" := CapacityLedgerEntry."Dimension Set ID";
        IsHandled := true;
    end;

    local procedure FillItemJnlLineForSubcontractingItemCharge(var ItemJournalLine: Record "Item Journal Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if ItemJournalLine."Item Charge No." = '' then
            exit;
        if not PurchRcptLine.Get(TempItemChargeAssignmentPurch."Applies-to Doc. No.", TempItemChargeAssignmentPurch."Applies-to Doc. Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) then
            exit;
        if PurchRcptLine.Correction then
            Error(ItemChargeAgainstUndoneRcptErr, PurchRcptLine."Document No.", PurchRcptLine."Line No.");

        CopySubcontractingProdOrderFieldsToItemJnlLine(ItemJournalLine, PurchRcptLine);
    end;

    local procedure SetQuantityBaseOnSubcontractingServiceLine(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if PurchRcptLine."Quantity (Base)" = 0 then
            if PurchRcptLineHasProdOrder(PurchRcptLine) then
                PurchRcptLine."Quantity (Base)" := UnitofMeasureManagement.CalcBaseQty(
                        PurchRcptLine."No.", PurchRcptLine."Variant Code", PurchRcptLine."Unit of Measure Code", PurchRcptLine.Quantity, PurchRcptLine."Qty. per Unit of Measure", PurchaseLine."Qty. Rounding Precision (Base)");
    end;

    local procedure PurchRcptLineHasProdOrder(PurchRcptLine: Record "Purch. Rcpt. Line") HasProdOrder: Boolean
    begin
        HasProdOrder := (PurchRcptLine."Prod. Order No." <> '') and
                            (PurchRcptLine."Routing No." <> '') and
                            (PurchRcptLine."Operation No." <> '');
        exit(HasProdOrder);
    end;

    local procedure CopySubcontractingProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Inventory Posting Group", "Item Tracking Code");
        Item.Get(ItemJournalLine."Item No.");
        ItemJournalLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ItemJournalLine."Subc. Item Charge Assign." := true;
        if PurchRcptLineIsLastOperation(PurchRcptLine) then begin
            if Item."Item Tracking Code" <> '' then begin
                ItemJournalLine.Subcontracting := false;
                ItemJournalLine."Entry Type" := "Item Ledger Entry Type"::Purchase;
            end else begin
                ItemJournalLine.Subcontracting := true;
                ItemJournalLine."Order Type" := "Inventory Order Type"::Production;
                ItemJournalLine."Order No." := PurchRcptLine."Prod. Order No.";
                ItemJournalLine."Order Line No." := PurchRcptLine."Prod. Order Line No.";
                ItemJournalLine."Entry Type" := "Item Ledger Entry Type"::Output;
                ItemJournalLine.Type := "Capacity Type Journal"::"Work Center";
                ItemJournalLine."No." := PurchRcptLine."Subc. Work Center No.";
                ItemJournalLine."Routing No." := PurchRcptLine."Routing No.";
                ItemJournalLine."Routing Reference No." := PurchRcptLine."Routing Reference No.";
                ItemJournalLine."Operation No." := PurchRcptLine."Operation No.";
                ItemJournalLine."Work Center No." := PurchRcptLine."Work Center No.";
                ItemJournalLine."Unit Cost Calculation" := ItemJournalLine."Unit Cost Calculation"::Units;
            end;
            exit;
        end;

        ItemJournalLine.Subcontracting := true;
        ItemJournalLine."Order Type" := "Inventory Order Type"::Production;
        ItemJournalLine."Order No." := PurchRcptLine."Prod. Order No.";
        ItemJournalLine."Order Line No." := PurchRcptLine."Prod. Order Line No.";
        ItemJournalLine."Entry Type" := "Item Ledger Entry Type"::Output;
        ItemJournalLine.Type := "Capacity Type Journal"::"Work Center";
        ItemJournalLine."No." := PurchRcptLine."Subc. Work Center No.";
        ItemJournalLine."Routing No." := PurchRcptLine."Routing No.";
        ItemJournalLine."Routing Reference No." := PurchRcptLine."Routing Reference No.";
        ItemJournalLine."Operation No." := PurchRcptLine."Operation No.";
        ItemJournalLine."Work Center No." := PurchRcptLine."Work Center No.";
        ItemJournalLine."Unit Cost Calculation" := ItemJournalLine."Unit Cost Calculation"::Units;
    end;

    local procedure PurchRcptLineIsLastOperation(PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetLoadFields("Next Operation No.");
        if ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchRcptLine."Prod. Order No.", PurchRcptLine."Routing Reference No.", PurchRcptLine."Routing No.", PurchRcptLine."Operation No.") then
            exit(ProdOrderRoutingLine."Next Operation No." = '');
        if ProdOrderRoutingLine.Get("Production Order Status"::Finished, PurchRcptLine."Prod. Order No.", PurchRcptLine."Routing Reference No.", PurchRcptLine."Routing No.", PurchRcptLine."Operation No.") then
            exit(ProdOrderRoutingLine."Next Operation No." = '');
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemJnlLineOnAfterPostItemJnlLineJobConsumption, '', false, false)]
    local procedure ProcessLastOperationWarehouseTracking_OnPostItemJnlLineOnAfterPostItemJnlLineJobConsumption(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; OriginalItemJnlLine: Record "Item Journal Line"; var TempReservationEntry: Record "Reservation Entry" temporary; var TrackingSpecification: Record "Tracking Specification" temporary; QtyToBeInvoiced: Decimal; QtyToBeReceived: Decimal; var PostJobConsumptionBeforePurch: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then
            CreateTempWhseSplitSpecificationForLastOperationSubcontracting(PurchaseLine, ItemJnlPostLine, TrackingSpecification, TempWhseTrackingSpecification);
    end;

    local procedure CreateTempWhseSplitSpecificationForLastOperationSubcontracting(PurchLine: Record "Purchase Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var TempWhseSplitSpecification: Record "Tracking Specification" temporary)
    begin
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then begin
            TempWhseSplitSpecification.Reset();
            TempWhseSplitSpecification.DeleteAll();
            if TempHandlingSpecification.FindSet() then
                repeat
                    TempWhseSplitSpecification := TempHandlingSpecification;
                    TempWhseSplitSpecification."Source Type" := DATABASE::"Purchase Line";
                    TempWhseSplitSpecification."Source Subtype" := PurchLine."Document Type".AsInteger();
                    TempWhseSplitSpecification."Source ID" := PurchLine."Document No.";
                    TempWhseSplitSpecification."Source Ref. No." := PurchLine."Line No.";
                    TempWhseSplitSpecification.Insert();
                until TempHandlingSpecification.Next() = 0;
        end;
    end;

}
