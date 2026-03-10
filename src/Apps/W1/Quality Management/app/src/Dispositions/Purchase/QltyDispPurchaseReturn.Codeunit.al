// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Purchase;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Utilities;

/// <summary>
/// The purpose of this reaction is to create a purchase return as a reaction to an inspection result.
/// </summary>
codeunit 20441 "Qlty. Disp. Purchase Return" implements "Qlty. Disposition"
{
    var
        TempCreatedBufferPurchaseHeader: Record "Purchase Header" temporary;
        NoPurchRcptLineErr: Label 'Could not find a related purchase receipt line with sufficient quantity for %1 from Quality Inspection %2,%3. Confirm the inspection source is a Purchase Line and that it has been received prior to creating a return.', Comment = '%1=item,%2=inspection,%3=re-inspection';
        DocumentTypeLbl: Label 'Purchase Return';

    /// <summary>
    /// Creates a Purchase Return Order from a Quality Inspection
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="QltyQuantityBehavior">Use a specific quantity, tracked quantity, sample size, or pass/fail quantity</param>
    /// <param name="OptionalSpecificQuantity">The specific quantity(base) to use, if designated</param>
    /// <param name="OptionalSourceLocationFilter">Optional additional location filter for item on inspection</param>
    /// <param name="OptionalSourceBinFilter">Optional additional bin filter for item on inspection</param>
    /// <param name="ReasonCode">Optional Return Reason code</param>
    /// <param name="ExternalDocumentNo">Optional Vendor Credit Memo No.</param>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSpecificQuantity: Decimal; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; ReasonCode: Code[10]; ExternalDocumentNo: Code[35]): Boolean
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Purchase Return";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := OptionalSpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(OptionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(OptionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        TempInstructionQltyDispositionBuffer."Reason Code" := ReasonCode;
        TempInstructionQltyDispositionBuffer."External Document No." := ExternalDocumentNo;

        exit(PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        CreatedReturnOrderPurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        IsHandled: Boolean;
        VendorCreditMemoNo: Code[35];
    begin
        VendorCreditMemoNo := CopyStr(TempInstructionQltyDispositionBuffer."External Document No.", 1, MaxStrLen(VendorCreditMemoNo));
        OnBeforeProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething, IsHandled);
        if IsHandled then
            exit;

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        if not FindPurchaseReceiptLineForInspection(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, PurchRcptLine) then
            Error(NoPurchRcptLineErr, QltyInspectionHeader."Source Item No.", QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        TempQuantityToActQltyDispositionBuffer.FindSet();
        repeat
            if CreatedReturnOrderPurchaseHeader."No." = '' then
                CreatePurchaseReturnOrderFromPurchaseReceiptLine(PurchRcptLine, CreatedReturnOrderPurchaseHeader, VendorCreditMemoNo);

            CreatePurchaseReturnOrderLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, PurchRcptLine, CreatedReturnOrderPurchaseHeader);
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        OnAfterProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, CreatedReturnOrderPurchaseHeader, DidSomething);

        if CreatedReturnOrderPurchaseHeader."No." <> '' then
            QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl, CreatedReturnOrderPurchaseHeader."No.", CreatedReturnOrderPurchaseHeader)
        else
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    local procedure FindPurchaseReceiptLineForInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        MgmtItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        UOMMgtUnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        AvailableQty: Decimal;
        AvailableQtyBase: Decimal;
        ReturnQtyBase: Decimal;
        UnusedRevUnitCostLCY: Decimal;
    begin
        TempQuantityToActQltyDispositionBuffer.CalcSums("Qty. To Handle (Base)");
        ReturnQtyBase := TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)";

        PurchRcptLine2.SetRange("Order No.", QltyInspectionHeader."Source Document No.");
        PurchRcptLine2.SetRange("Order Line No.", QltyInspectionHeader."Source Document Line No.");
        if QltyInspectionHeader."Source Item No." <> '' then begin
            PurchRcptLine2.SetRange(Type, PurchRcptLine.Type::Item);
            PurchRcptLine2.SetRange("No.", QltyInspectionHeader."Source Item No.");
        end;
        if QltyInspectionHeader.IsItemTrackingUsed() then begin
            PurchRcptLine2.SetLoadFields("Document No.", "Line No.");
            if PurchRcptLine2.FindSet() then
                repeat
                    MgmtItemTrackingDocManagement.RetrieveEntriesFromShptRcpt(TempItemLedgerEntry, Database::"Purch. Rcpt. Line",
                        0,
                        PurchRcptLine2."Document No.",
                        '',
                        0,
                        PurchRcptLine2."Line No.");

                    if QltyInspectionHeader."Source Lot No." <> '' then
                        TempItemLedgerEntry.SetRange("Lot No.", QltyInspectionHeader."Source Lot No.");
                    if QltyInspectionHeader."Source Serial No." <> '' then
                        TempItemLedgerEntry.SetRange("Serial No.", QltyInspectionHeader."Source Serial No.");
                    if QltyInspectionHeader."Source Package No." <> '' then
                        TempItemLedgerEntry.SetRange("Package No.", QltyInspectionHeader."Source Package No.");
                    if not TempItemLedgerEntry.IsEmpty() then begin
                        TempItemLedgerEntry.CalcSums("Remaining Quantity");
                        if TempItemLedgerEntry."Remaining Quantity" >= ReturnQtyBase then
                            exit(PurchRcptLine.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No."));
                    end;
                until PurchRcptLine2.Next() = 0;
        end else begin
            PurchRcptLine2.SetLoadFields("Document No.", "Line No.", "Qty. per Unit of Measure");
            if PurchRcptLine2.FindSet() then
                repeat
                    PurchRcptLine2.CalcReceivedPurchNotReturned(AvailableQty, UnusedRevUnitCostLCY, true);
                    AvailableQtyBase := UOMMgtUnitOfMeasureManagement.CalcBaseQty(AvailableQty, PurchRcptLine2."Qty. per Unit of Measure");
                    if AvailableQtyBase >= ReturnQtyBase then
                        exit(PurchRcptLine.Get(PurchRcptLine2."Document No.", PurchRcptLine2."Line No."));
                until PurchRcptLine2.Next() = 0;
        end;
    end;

    local procedure CreatePurchaseReturnOrderFromPurchaseReceiptLine(var InPurchRcptLine: Record "Purch. Rcpt. Line"; var ReturnOrderPurchaseHeader: Record "Purchase Header"; VendorCreditMemoNotMemo: Code[35])
    begin
        ReturnOrderPurchaseHeader.Init();
        ReturnOrderPurchaseHeader."Document Type" := ReturnOrderPurchaseHeader."Document Type"::"Return Order";
        ReturnOrderPurchaseHeader.Validate("Buy-from Vendor No.", InPurchRcptLine."Buy-from Vendor No.");
        if VendorCreditMemoNotMemo <> '' then
            ReturnOrderPurchaseHeader."Vendor Cr. Memo No." := VendorCreditMemoNotMemo;

        ReturnOrderPurchaseHeader.Insert(true);
        if TempCreatedBufferPurchaseHeader."No." <> ReturnOrderPurchaseHeader."No." then begin
            TempCreatedBufferPurchaseHeader := ReturnOrderPurchaseHeader;
            TempCreatedBufferPurchaseHeader.Insert();
        end;
    end;

    local procedure CreatePurchaseReturnOrderLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var PurchRcptLine: Record "Purch. Rcpt. Line"; var ReturnOrderPurchaseHeader: Record "Purchase Header")
    var
        ReturnOrderPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DocCopyDocumentMgt: Codeunit "Copy Document Mgt.";
        UOMMgtUnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        UnusedLinesNotCopied: Integer;
        QtyPerUOM: Decimal;
        QtyToReturn: Decimal;
        UnusedMissingExCostRevLink: Boolean;
        ExistingLine: Boolean;
        ItemTracking: Boolean;
        IsHandled: Boolean;

    begin
        Item.Get(QltyInspectionHeader."Source Item No.");
        ItemTracking := QltyInspectionHeader.IsItemTrackingUsed();

        ReturnOrderPurchaseLine.SetRange("Document Type", ReturnOrderPurchaseLine."Document Type"::"Return Order");
        ReturnOrderPurchaseLine.SetRange("Document No.", ReturnOrderPurchaseHeader."No.");
        ReturnOrderPurchaseLine.SetRange(Type, ReturnOrderPurchaseLine.Type::Item);
        ReturnOrderPurchaseLine.SetRange("No.", QltyInspectionHeader."Source Item No.");
        ReturnOrderPurchaseLine.SetRange("Variant Code", QltyInspectionHeader."Source Variant Code");
        if ReturnOrderPurchaseLine.FindFirst() then
            ExistingLine := true;

        OnBeforeCreateOrUpdatePurchaseReturnOrderLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, PurchRcptLine, ReturnOrderPurchaseHeader, ReturnOrderPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if not ExistingLine then begin
            if not GuiAllowed() then
                DocCopyDocumentMgt.SetHideProcessWindow(true);

            PurchRcptLine.SetRecFilter();
            DocCopyDocumentMgt.CopyPurchRcptLinesToDoc(ReturnOrderPurchaseHeader, PurchRcptLine, UnusedLinesNotCopied, UnusedMissingExCostRevLink);
            if ReturnOrderPurchaseLine.FindFirst() then begin
                QtyPerUOM := UOMMgtUnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, ReturnOrderPurchaseLine."Unit of Measure Code");
                QtyToReturn := UOMMgtUnitOfMeasureManagement.CalcQtyFromBase(
                    TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)",
                    QtyPerUOM);

                if ItemTracking then
                    QltyItemTrackingMgmt.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, ReturnOrderPurchaseLine, QtyToReturn);
                if ReturnOrderPurchaseLine.Quantity <> QtyToReturn then
                    ReturnOrderPurchaseLine.Validate(Quantity, QtyToReturn);

                if TempQuantityToActQltyDispositionBuffer."Reason Code" <> '' then
                    ReturnOrderPurchaseLine.Validate("Return Reason Code", TempQuantityToActQltyDispositionBuffer."Reason Code");

                ReturnOrderPurchaseLine.Modify(true);
            end;
        end else begin
            QtyPerUOM := UOMMgtUnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, ReturnOrderPurchaseLine."Unit of Measure Code");
            QtyToReturn := UOMMgtUnitOfMeasureManagement.CalcQtyFromBase(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)", QtyPerUOM);
            QtyToReturn := QtyToReturn + ReturnOrderPurchaseLine.Quantity;

            if ItemTracking then
                QltyItemTrackingMgmt.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, ReturnOrderPurchaseLine, QtyToReturn);
            ReturnOrderPurchaseLine.Validate(Quantity, QtyToReturn);
            ReturnOrderPurchaseLine.Modify(true);
        end;

        OnAfterCreateOrUpdatePurchaseReturnOrderLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, PurchRcptLine, ReturnOrderPurchaseHeader, ReturnOrderPurchaseLine);
    end;

    /// <summary>
    /// Gets the created purchase return headers that were created as buffer tables.
    /// </summary>
    /// <param name="TempCreatedBufferPurchaseHeader2"></param>
    internal procedure GetCreatedPurchaseReturnBuffer(var TempCreatedBufferPurchaseHeader2: Record "Purchase Header" temporary)
    begin
        TempCreatedBufferPurchaseHeader2.Copy(TempCreatedBufferPurchaseHeader, true);
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="DidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    /// <param name="IsHandled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="CreatedReturnOrderPurchaseHeader">The created purchase return order</param>
    /// <param name="DidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var CreatedReturnOrderPurchaseHeader: Record "Purchase Header"; var DidSomething: Boolean)
    begin
    end;

    /// <summary>
    /// Provies an ability to replace the handling of the creation or purchase return order lines.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="PurchRcptLine">The original purchase receipt line.</param>
    /// <param name="ReturnOrderPurchaseHeader">The purchase return order</param>
    /// <param name="ReturnOrderPurchaseLine">The new or existing purchase return order line.</param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeCreateOrUpdatePurchaseReturnOrderLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var PurchRcptLine: Record "Purch. Rcpt. Line"; var ReturnOrderPurchaseHeader: Record "Purchase Header"; var ReturnOrderPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an ability to extend the handling of the creation or purchase return order lines.
    /// after the system has processed the update.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="PurchRcptLine">The original purchase receipt line.</param>
    /// <param name="ReturnOrderPurchaseHeader">The purchase return order</param>
    /// <param name="ReturnOrderPurchaseLine">The new or existing purchase return order line.</param>

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateOrUpdatePurchaseReturnOrderLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var PurchRcptLine: Record "Purch. Rcpt. Line"; var ReturnOrderPurchaseHeader: Record "Purchase Header"; var ReturnOrderPurchaseLine: Record "Purchase Line")
    begin
    end;
}
