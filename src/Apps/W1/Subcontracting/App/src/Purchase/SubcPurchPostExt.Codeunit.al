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

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", OnBeforeInsertInvLineFromRcptLine, '', false, false)]
    local procedure BlockTrackedSubcontractingReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not PurchRcptLineHasProdOrder(PurchRcptLine) then
            exit;
        if not ItemIsTracked(PurchRcptLine."No.") then
            exit;
        if not PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;

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

        Error(CancelNotSupportedErr, PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch. Invoice", OnBeforeTestIfInvoiceIsPaid, '', false, false)]
    local procedure BlockSeparateSubcontractingInvoiceReversalBeforeLineValidation(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
#if not CLEAN29
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
#if not CLEAN29
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
        if PurchInvHeader."Pre-Assigned No." = '' then
            exit;
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", PurchInvHeader."No.");
        ValueEntry.SetRange("Item Ledger Entry No.", 0);
        ValueEntry.SetFilter("Capacity Ledger Entry No.", '<>%1', 0);
        ValueEntry.SetRange("Item Charge No.", '');
        if ValueEntry.IsEmpty() then
            exit;

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
    local procedure SkipPhysicalTrackingForNonLastSubcontractingReceipt(FromPurchLine: Record "Purchase Line"; var ToPurchLine: Record "Purchase Line"; CheckLineQty: Boolean; var IsHandled: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PurchRcptLine.SetLoadFields("No.", "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        if not PurchRcptLine.Get(ToPurchLine."Receipt No.", ToPurchLine."Receipt Line No.") then
            exit;
        if not PurchRcptLineHasProdOrder(PurchRcptLine) then
            exit;
        if not ItemIsTracked(PurchRcptLine."No.") then
            exit;
        if PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;

        IsHandled := true;
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
        PurchRcptLine.SetLoadFields("Order No.", "Order Line No.", "Operation No.");
        if PurchRcptLine.Get(PurchLine."Receipt No.", PurchLine."Receipt Line No.") then
            SetSubcontractingPurchaseIdentity(ItemJnlLine, PurchRcptLine)
        else begin
            ItemJnlLine."Subc. Purch. Order No." := PurchLine."Document No.";
            ItemJnlLine."Subc. Purch. Order Line No." := PurchLine."Line No.";
            ItemJnlLine."Subc. Operation No." := PurchLine."Operation No.";
        end;
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
