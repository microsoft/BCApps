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
codeunit 99001535 "Subc. Purch. Post Ext"
{
    var
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        CancelNotSupportedErr: Label 'You cannot cancel or correct posted purchase invoice %1 because it contains item charges assigned to a subcontracting order receipt.\Use the ''Create Corrective Credit Memo'' action to create a credit memo for this invoice.', Comment = '%1 = Posted Purchase Invoice No.';
        ItemChargeAgainstUndoneRcptErr: Label 'You cannot post the item charge because it is assigned to subcontracting receipt %1, line %2, which has been undone.\Remove the item charge assignment from the undone receipt line.', Comment = '%1 = Posted Receipt No., %2 = Posted Receipt Line No.';
        GetSubcontractingRcptNotSupportedErr: Label 'You cannot copy subcontracting receipt lines into this document. Subcontracting purchase orders must be invoiced from the subcontracting order itself, not by getting the receipt lines into a separate document.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Get Receipt", OnAfterPurchRcptLineSetFilters, '', false, false)]
    local procedure ExcludeSubcontractingLinesOnAfterPurchRcptLineSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseHeader: Record "Purchase Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PurchRcptLine.SetRange("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Get Receipt", OnCreateInvLinesOnBeforeInsertLineIteration, '', false, false)]
    local procedure BlockSubcontractingLinesOnCreateInvLinesOnBeforeInsertLineIteration(var PurchRcptLine2: Record "Purch. Rcpt. Line"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TransferLine: Boolean; var IsHandled: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PurchRcptLine2."Prod. Order No." <> '' then
            Error(GetSubcontractingRcptNotSupportedErr);
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
        if not ValueEntry.IsEmpty() then
            Error(CancelNotSupportedErr, PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeItemJnlPostLine, '', false, false)]
    local procedure "Purch.-Post_OnBeforeItemJnlPostLine"(var ItemJournalLine: Record "Item Journal Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        FillItemJnlLineForSubcontractingItemCharge(ItemJournalLine, TempItemChargeAssignmentPurch);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Purch.-Post", OnAfterPostItemJnlLineCopyProdOrder, '', false, false)]
    local procedure MfgPurchPostOnAfterPostItemJnlLineCopyProdOrder(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ItemJnlLine."Subc. Purch. Order No." := PurchLine."Document No.";
        ItemJnlLine."Subc. Purch. Order Line No." := PurchLine."Line No.";
        ItemJnlLine."Subc. Operation No." := PurchLine."Operation No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemChargePerRcptOnAfterCalcDistributeCharge, '', false, false)]
    local procedure "Purch.-Post_OnPostItemChargePerRcptOnAfterCalcDistributeCharge"(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SetQuantityBaseOnSubcontractingServiceLine(PurchLine, PurchRcptLine);
    end;

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
        if PurchRcptLineIsLastOperation(PurchRcptLine) then
            exit;
        SubcSessionState.SetRecordID('PurchRcptLineForItemCharge', PurchRcptLine.RecordId);
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
#if not CLEAN28
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