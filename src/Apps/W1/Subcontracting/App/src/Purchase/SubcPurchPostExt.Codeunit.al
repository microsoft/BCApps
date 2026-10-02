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
using Microsoft.Utilities;
codeunit 20535 "Subc. Purch. Post Ext"
{
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        CancelNotSupportedErr: Label 'You cannot cancel or correct this posted purchase invoice because it contains item charges assigned to a subcontracting order receipt.\Use the ''Create Corrective Credit Memo'' action to create a credit memo for this invoice.';
        CancelNotSupportedTitleLbl: Label 'Posted purchase invoice cannot be cancelled';
        CancelNotSupportedDetailedMsg: Label 'This invoice contains item charges assigned to a subcontracting order receipt. Create a corrective credit memo to reverse the invoice while preserving the subcontracting cost application.';
        ShowPostedPurchaseInvoiceLbl: Label 'Show Posted Purchase Invoice';
        ItemChargeAgainstUndoneRcptErr: Label 'You cannot post the item charge because it is assigned to subcontracting receipt %1, line %2, which has been undone.\Remove the item charge assignment from the undone receipt line.', Comment = '%1 = Posted Receipt No., %2 = Posted Receipt Line No.';
        GetTrackedSubcontractingRcptNotSupportedErr: Label 'You cannot copy tracked subcontracting receipt lines into this document. Invoice tracked subcontracting receipts from the subcontracting order instead.';

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", OnBeforeInsertInvLineFromRcptLine, '', false, false)]
    local procedure BlockTrackedSubcontractingReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        if (PurchRcptLine."Prod. Order No." <> '') and ItemIsTracked(PurchRcptLine."No.") then
            Error(GetTrackedSubcontractingRcptNotSupportedErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Matched Order Line Mgmt.", OnGetPurchaseOrderLinesOnAfterSetPurchaseLineOrderFilters, '', false, false)]
    local procedure ExcludeSubcontractingLinesOnGetPurchaseOrderLines(var PurchaseLineOrder: Record "Purchase Line"; PurchaseHeaderInvoice: Record "Purchase Header")
    begin
#if not CLEAN29
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
#if not CLEAN29
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

        Error(CreateCancelNotSupportedErrorInfo(PurchInvHeader));
    end;

    internal procedure CreateCancelNotSupportedErrorInfo(PurchInvHeader: Record "Purch. Inv. Header") CancelNotSupportedErrorInfo: ErrorInfo
    begin
        CancelNotSupportedErrorInfo.Title := CancelNotSupportedTitleLbl;
        CancelNotSupportedErrorInfo.Message := CancelNotSupportedErr;
        CancelNotSupportedErrorInfo.DetailedMessage := CancelNotSupportedDetailedMsg;
        CancelNotSupportedErrorInfo.DataClassification := DataClassification::SystemMetadata;
        CancelNotSupportedErrorInfo.ErrorType := ErrorType::Client;
        CancelNotSupportedErrorInfo.RecordId := PurchInvHeader.RecordId;
        CancelNotSupportedErrorInfo.PageNo := Page::"Posted Purchase Invoice";
        CancelNotSupportedErrorInfo.AddNavigationAction(ShowPostedPurchaseInvoiceLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnTestPurchaseLinesOnAfterCalcThrowItemReturnedError, '', false, false)]
    local procedure AllowCapacityOnlySubcontractingInvoiceCancellation(PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line"; var ThrowItemReturnedError: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.SetRange("Document Line No.", PurchInvLine."Line No.");
        ValueEntry.SetFilter("Capacity Ledger Entry No.", '<>%1', 0);
        if ValueEntry.IsEmpty() then
            exit;

        ValueEntry.SetRange("Capacity Ledger Entry No.");
        ValueEntry.SetFilter("Item Ledger Entry No.", '<>%1', 0);
        if ValueEntry.IsEmpty() then
            ThrowItemReturnedError := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnAfterCopyPurchLineFromPurchLineBuffer, '', false, false)]
    local procedure RestoreSubcontractingOutputApplication(var ToPurchLine: Record "Purchase Line"; FromPurchInvLine: Record "Purch. Inv. Line"; ToPurchHeader: Record "Purchase Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DirectUnitCost: Decimal;
        MissingExactCostReversingLink: Boolean;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ToPurchHeader."Document Type" <> ToPurchHeader."Document Type"::"Credit Memo" then
            exit;
        if FromPurchInvLine.Type <> FromPurchInvLine.Type::Item then
            exit;
        if not PurchRcptLine.Get(FromPurchInvLine."Receipt No.", FromPurchInvLine."Receipt Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) then
            exit;
        if not SetSubcontractingOutputEntryFilters(ItemLedgerEntry, PurchRcptLine) then
            exit;
        if ItemLedgerEntry.IsEmpty() then
            exit;

        RestoreSubcontractingIdentity(ToPurchLine, PurchRcptLine);
        if not ItemIsTracked(PurchRcptLine."No.") then begin
            ItemLedgerEntry.FindFirst();
            ToPurchLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            ToPurchLine.Modify(true);
            exit;
        end;

        DirectUnitCost := ToPurchLine."Direct Unit Cost";
        if not CopyPostedInvoiceOutputEntriesToTemp(
            TempItemLedgerEntry, ItemLedgerEntry, FromPurchInvLine)
        then
            exit;
        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
            TempItemLedgerEntry, ToPurchLine, true, MissingExactCostReversingLink,
            ToPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", false);
        CreateInvoiceTrackingSpecifications(ToPurchLine);
        ToPurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        ToPurchLine.Modify(true);
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

        if not SetSubcontractingOutputEntryFilters(ItemLedgerEntry, PurchRcptLine) then
            exit;

        ToPurchLine.Validate(Quantity, PurchRcptLine."Qty. Rcd. Not Invoiced");
        ToPurchLine.Modify(true);
        if not CopyItemLedgerEntriesUpToQuantity(
            TempItemLedgerEntry, ItemLedgerEntry, ToPurchLine."Quantity (Base)", PurchRcptLine."Qty. Invoiced (Base)")
        then
            exit;

        IsHandled := true;
        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
            TempItemLedgerEntry, ToPurchLine, false, MissingExactCostReversingLink,
            false, false, true);
        CreateInvoiceTrackingSpecifications(ToPurchLine);
    end;

    local procedure CopyPostedInvoiceOutputEntriesToTemp(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; FromPurchInvLine: Record "Purch. Inv. Line"): Boolean
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ValueEntry: Record "Value Entry";
        PreviousValueEntry: Record "Value Entry";
        ValueEntryRelation: Record "Value Entry Relation";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        InvoiceRowID: Text[250];
        InvoicedQuantityBase: Decimal;
        PreviouslyInvoicedQuantityBase: Decimal;
        RelatedCapacityLedgerEntryNo: Integer;
        RelatedValueEntries: Dictionary of [Integer, Boolean];
        OutputInvoicedQuantities: Dictionary of [Integer, Decimal];
    begin
        InvoiceRowID := ItemTrackingMgt.ComposeRowID(
            Database::"Purch. Inv. Line", 0, FromPurchInvLine."Document No.", '', 0, FromPurchInvLine."Line No.");
        ValueEntryRelation.SetCurrentKey("Source RowId");
        ValueEntryRelation.SetRange("Source RowId", InvoiceRowID);
        if not ValueEntryRelation.FindSet() then
            exit(false);
        repeat
            RelatedValueEntries.Add(ValueEntryRelation."Value Entry No.", true);
        until ValueEntryRelation.Next() = 0;

        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", FromPurchInvLine."Document No.");
        ValueEntry.SetRange("Document Line No.", FromPurchInvLine."Line No.");
        if not ValueEntry.FindSet() then
            exit(false);
        repeat
            if RelatedValueEntries.ContainsKey(ValueEntry."Entry No.") then
                if ValueEntry."Item Ledger Entry No." <> 0 then begin
                    if OutputInvoicedQuantities.Get(ValueEntry."Item Ledger Entry No.", InvoicedQuantityBase) then
                        OutputInvoicedQuantities.Set(
                            ValueEntry."Item Ledger Entry No.", InvoicedQuantityBase + Abs(ValueEntry."Invoiced Quantity"))
                    else
                        OutputInvoicedQuantities.Add(ValueEntry."Item Ledger Entry No.", Abs(ValueEntry."Invoiced Quantity"));
                end else
                    if (ValueEntry."Capacity Ledger Entry No." <> 0) and (ValueEntry."Invoiced Quantity" <> 0) then begin
                        RelatedCapacityLedgerEntryNo := ValueEntry."Capacity Ledger Entry No.";
                        InvoicedQuantityBase += Abs(ValueEntry."Invoiced Quantity");

                        PreviousValueEntry.SetRange("Capacity Ledger Entry No.", RelatedCapacityLedgerEntryNo);
                        PreviousValueEntry.SetRange("Entry Type", ValueEntry."Entry Type");
                        PreviousValueEntry.SetRange("Document Type", PreviousValueEntry."Document Type"::"Purchase Invoice");
                        PreviousValueEntry.SetFilter("Entry No.", '<%1', ValueEntry."Entry No.");
                        PreviousValueEntry.CalcSums("Invoiced Quantity");
                        PreviouslyInvoicedQuantityBase += Abs(PreviousValueEntry."Invoiced Quantity");
                    end;
        until ValueEntry.Next() = 0;

        TempItemLedgerEntry.Reset();
        TempItemLedgerEntry.DeleteAll();
        if OutputInvoicedQuantities.Count() = 0 then begin
            if (RelatedCapacityLedgerEntryNo = 0) or (InvoicedQuantityBase = 0) then
                exit(false);
            if not CapacityLedgerEntry.Get(RelatedCapacityLedgerEntryNo) then
                exit(false);
            ItemLedgerEntry.SetRange("Item Register No.", CapacityLedgerEntry."Item Register No.");
            exit(CopyItemLedgerEntriesUpToQuantity(
                TempItemLedgerEntry, ItemLedgerEntry, InvoicedQuantityBase, PreviouslyInvoicedQuantityBase));
        end;

        if not ItemLedgerEntry.FindSet() then
            exit(false);
        repeat
            if OutputInvoicedQuantities.Get(ItemLedgerEntry."Entry No.", InvoicedQuantityBase) then begin
                TempItemLedgerEntry := ItemLedgerEntry;
                TempItemLedgerEntry.Quantity := InvoicedQuantityBase;
                TempItemLedgerEntry."Remaining Quantity" := InvoicedQuantityBase;
                TempItemLedgerEntry.Insert();
            end;
        until ItemLedgerEntry.Next() = 0;
        TempItemLedgerEntry.Reset();

        exit(not TempItemLedgerEntry.IsEmpty());
    end;

    local procedure CopyItemLedgerEntriesUpToQuantity(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; QuantityBase: Decimal; QuantityAlreadyInvoicedBase: Decimal): Boolean
    var
        EntryQuantityBase: Decimal;
        QuantityToCopy: Decimal;
        QuantityToSkipBase: Decimal;
        RemainingQuantityBase: Decimal;
    begin
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
        exit(not TempItemLedgerEntry.IsEmpty());
    end;

    local procedure CreateInvoiceTrackingSpecifications(PurchaseLine: Record "Purchase Line")
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeItemJnlPostLine, '', false, false)]
    local procedure "Purch.-Post_OnBeforeItemJnlPostLine"(var ItemJournalLine: Record "Item Journal Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        FillItemJnlLineForSubcontractingItemCharge(ItemJournalLine, TempItemChargeAssignmentPurch);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemJnlLineOnBeforeItemJnlPostLineRunWithCheck, '', false, false)]
    local procedure RestoreCorrectionSubcontractingPurchaseIdentity(var ItemJnlLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::"Credit Memo" then
            exit;
        if not ItemLedgerEntry.Get(ItemJnlLine."Applies-to Entry") then
            exit;
        if ItemLedgerEntry."Subc. Purch. Order No." = '' then
            exit;

        ItemJnlLine."Subc. Purch. Order No." := ItemLedgerEntry."Subc. Purch. Order No.";
        ItemJnlLine."Subc. Purch. Order Line No." := ItemLedgerEntry."Subc. Purch. Order Line No.";
        ItemJnlLine."Subc. Operation No." := ItemLedgerEntry."Subc. Operation No.";
        RestoreCorrectionCapacityApplication(ItemJnlLine, ItemLedgerEntry);
    end;

    local procedure RestoreCorrectionCapacityApplication(var ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Item Register No.", ItemLedgerEntry."Item Register No.");
        CapacityLedgerEntry.SetRange(Subcontracting, true);
        CapacityLedgerEntry.SetRange("Subc. Purch. Order No.", ItemLedgerEntry."Subc. Purch. Order No.");
        CapacityLedgerEntry.SetRange("Subc. Purch. Order Line No.", ItemLedgerEntry."Subc. Purch. Order Line No.");
        if CapacityLedgerEntry.FindFirst() then
            ItemJnlLine."Item Shpt. Entry No." := CapacityLedgerEntry."Entry No.";
    end;

    local procedure SetSubcontractingPurchaseIdentity(var ItemJnlLine: Record "Item Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        ItemJnlLine."Subc. Purch. Order No." := PurchRcptLine."Order No.";
        ItemJnlLine."Subc. Purch. Order Line No." := PurchRcptLine."Order Line No.";
        ItemJnlLine."Subc. Operation No." := PurchRcptLine."Operation No.";
    end;

    local procedure RestoreSubcontractingIdentity(var PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        Clear(PurchaseLine."Receipt No.");
        PurchaseLine."Receipt Line No." := 0;
        PurchaseLine."Location Code" := PurchRcptLine."Location Code";
        PurchaseLine."Prod. Order No." := PurchRcptLine."Prod. Order No.";
        PurchaseLine."Prod. Order Line No." := PurchRcptLine."Prod. Order Line No.";
        PurchaseLine."Routing No." := PurchRcptLine."Routing No.";
        PurchaseLine."Routing Reference No." := PurchRcptLine."Routing Reference No.";
        PurchaseLine."Operation No." := PurchRcptLine."Operation No.";
        PurchaseLine."Work Center No." := PurchRcptLine."Work Center No.";
        PurchaseLine."Subc. Prod. Order No." := PurchRcptLine."Subc. Prod. Order No.";
        PurchaseLine."Subc. Prod. Order Line No." := PurchRcptLine."Subc. Prod. Order Line No.";
        PurchaseLine."Subc. Routing No." := PurchRcptLine."Subc. Routing No.";
        PurchaseLine."Subc. Rtng Reference No." := PurchRcptLine."Subc. Rtng Reference No.";
        PurchaseLine."Subc. Operation No." := PurchRcptLine."Subc. Operation No.";
        PurchaseLine."Subc. Work Center No." := PurchRcptLine."Subc. Work Center No.";
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
