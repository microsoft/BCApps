// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

codeunit 99001551 "Subc. WhsePostReceipt Ext"
{
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", OnBeforeOpenItemTrackingLines, '', false, false)]
    local procedure "Warehouse Receipt Line_OnBeforeOpenItemTrackingLines"(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean; CallingFieldNo: Integer)
    var
        NotLastOperationLineErr: Label 'Item tracking lines can only be viewed for subcontracting purchase lines which are linked to a routing line which is the last operation.';
    begin
        if WarehouseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::None then
            exit;
        if WarehouseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            Error(NotLastOperationLineErr);
        CheckOverDelivery(WarehouseReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnAfterTransRcptLineModify, '', false, false)]
    local procedure OnAfterTransRcptLineModify(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.TransferReservationEntryFromPstTransferLineToProdOrderComp(TransferReceiptLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", OnAfterGetQuantityRelatedParameter, '', false, false)]
    local procedure "Purchases Warehouse Mgt._OnAfterGetQuantityRelatedParameter"(PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var QtyPerUoM: Decimal; var QtyBasePurchaseLine: Decimal)
    var
        Item: Record Microsoft.Inventory.Item.Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then begin
            Item.Get(PurchaseLine."No.");
            QtyPerUoM := UOMMgt.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");
            QtyBasePurchaseLine := PurchaseLine.CalcBaseQtyFromQuantity(PurchaseLine.Quantity, PurchaseLine.FieldCaption("Qty. Rounding Precision"), PurchaseLine.FieldCaption("Quantity"), PurchaseLine.FieldCaption("Quantity (Base)"));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", OnPurchLine2ReceiptLineOnAfterInitNewLine, '', false, false)]
    local procedure "Purchases Warehouse Mgt._OnPurchLine2ReceiptLineOnAfterInitNewLine"(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        WarehouseReceiptLine."Subc. Purchase Line Type" := PurchaseLine."Subc. Purchase Line Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", OnBeforeCheckIfPurchLine2ReceiptLine, '', false, false)]
    local procedure "Purchases Warehouse Mgt._OnBeforeCheckIfPurchLine2ReceiptLine"(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    var
        OutstandingQtyBase: Decimal;
        WhseOutstandingQtyBase: Decimal;
    begin
        case PurchaseLine."Subc. Purchase Line Type" of
            "Subc. Purchase Line Type"::None:
                exit;
            "Subc. Purchase Line Type"::LastOperation,
            "Subc. Purchase Line Type"::NotLastOperation:
                begin
                    PurchaseLine.CalcFields("Whse. Outstanding Quantity");
                    OutstandingQtyBase := PurchaseLine.CalcBaseQtyFromQuantity(PurchaseLine."Outstanding Quantity", PurchaseLine.FieldCaption("Qty. Rounding Precision"), PurchaseLine.FieldCaption("Outstanding Quantity"), PurchaseLine.FieldCaption("Outstanding Qty. (Base)"));
                    WhseOutstandingQtyBase := PurchaseLine.CalcBaseQtyFromQuantity(PurchaseLine."Whse. Outstanding Quantity", PurchaseLine.FieldCaption("Qty. Rounding Precision"), PurchaseLine.FieldCaption("Whse. Outstanding Quantity"), PurchaseLine.FieldCaption("Whse. Outstanding Qty. (Base)"));
                    ReturnValue := (Abs(OutstandingQtyBase) > Abs(WhseOutstandingQtyBase));
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Purch. Release", OnReleaseOnBeforeCreateWhseRequest, '', false, false)]
    local procedure "Whse.-Purch. Release_OnReleaseOnBeforeCreateWhseRequest"(var PurchaseLine: Record "Purchase Line"; var DoCreateWhseRequest: Boolean)
    begin
        DoCreateWhseRequest := DoCreateWhseRequest or PurchaseLine.IsInventoriableItem();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", OnBeforeCalcBaseQty, '', false, false)]
    local procedure "Warehouse Receipt Line_OnBeforeCalcBaseQty"(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text; var SuppressQtyPerUoMTestfield: Boolean)
    begin
        SuppressQtyPerUoMTestfield := WarehouseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", OnValidateQtyToReceiveOnBeforeUOMMgtValidateQtyIsBalanced, '', false, false)]
    local procedure "Warehouse Receipt Line_OnValidateQtyToReceiveOnBeforeUOMMgtValidateQtyIsBalanced"(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; xWarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
        if (WarehouseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnBeforePostWhseJnlLine, '', false, false)]
    local procedure "Whse.-Post Receipt_OnBeforePostWhseJnlLine"(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var WhseReceiptLine: Record "Warehouse Receipt Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
        if PostedWhseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnPostWhseJnlLineOnAfterInsertWhseItemEntryRelation, '', false, false)]
    local procedure "Whse.-Post Receipt_OnPostWhseJnlLineOnAfterInsertWhseItemEntryRelation"(var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempWhseSplitSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean; ReceivingNo: Code[20]; PostingDate: Date; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
        if PostedWhseRcptLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::None then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", OnBeforeOpenItemTrackingLineForPurchLine, '', false, false)]
    local procedure "Warehouse Receipt Line_OnBeforeOpenItemTrackingLineForPurchLine"(PurchaseLine: Record "Purchase Line"; SecondSourceQtyArray: array[3] of Decimal; var SkipCallItemTracking: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::LastOperation then
            if PurchaseLine.IsSubcontractingLineWithLastOperation(ProdOrderLine) then begin
                OpenItemTrackingOfProdOrderLine(SecondSourceQtyArray, ProdOrderLine);
                SkipCallItemTracking := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnCreatePostedRcptLineOnBeforePutAwayProcessing, '', false, false)]
    local procedure "Whse.-Post Receipt_OnIsReceiptForSubcontracting"(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var SkipPutAwayProcessing: Boolean)
    begin
        if SkipPutAwayProcessing then
            exit;
        SkipPutAwayProcessing := PostedWhseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnBeforeCreatePutAwayLine, '', false, false)]
    local procedure "Whse.-Post Receipt_OnIsReceiptIsForSubcontractingNotLastOperation"(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var SkipPutAwayCreationForLine: Boolean)
    begin
        if PostedWhseReceiptLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            SkipPutAwayCreationForLine := true;
    end;

    local procedure OpenItemTrackingOfProdOrderLine(var SecondSourceQtyArray: array[3] of Decimal; var ProdOrderLine: Record "Prod. Order Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        ProdOrderLineReserve.InitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderLine."Due Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQtyArray);
        ItemTrackingLines.RunModal();
    end;

    local procedure CheckOverDelivery(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
        QtyMismatchTitleLbl: Label 'Quantity Mismatch';
        QtyMessageLbl: Label 'The quantity (%1) in %2 is greater than the remaining quantity (%3) in %4. In order to open item tracking lines, first adjust the quantity on %4 to at least match the quantity on %2. You can adjust the quantity from %5 to %6 by using the action below.',
        Comment = '%1 = Warehouse Receipt Line Quantity, %2 = Tablecaption WarehouseReceiptLine, %3 = ProdOrderLine Remaining Qty, %4 = Tablecaption ProdOrderLine, %5 = Current ProdOrderLine Quantity, %6 = WarehouseReceiptLine Quantity';
        ShowProductionOrderActionLbl: Label 'Show Prod. Order';
        AdjustQtyActionLbl: Label 'Adjust Quantity';
        OpenItemTrackingAnywayActionLbl: Label 'Open anyway';
        CannotInvoiceErrorInfo: ErrorInfo;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not PurchaseLine.Get(WarehouseReceiptLine."Source Subtype", WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then
            exit;
        if PurchaseLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::LastOperation then
            exit;
        if not PurchaseLine.IsSubcontractingLineWithLastOperation(ProdOrderLine) then
            exit;
        if ProdOrderLine.Quantity < WarehouseReceiptLine.Quantity then begin
            CannotInvoiceErrorInfo.Title := QtyMismatchTitleLbl;
            CannotInvoiceErrorInfo.Message := StrSubstNo(QtyMessageLbl, WarehouseReceiptLine.Quantity, WarehouseReceiptLine.TableCaption(), ProdOrderLine."Remaining Quantity", ProdOrderLine.TableCaption(), ProdOrderLine.Quantity, WarehouseReceiptLine.Quantity);

            CannotInvoiceErrorInfo.RecordId := PurchaseLine.RecordId;
            CustomDimensions.Add(GetWarehouseReceiptLineSystemIdCustomDimensionLbl(), WarehouseReceiptLine.SystemId);
            CannotInvoiceErrorInfo.CustomDimensions(CustomDimensions);
            CannotInvoiceErrorInfo.AddAction(
                StrSubstNo(AdjustQtyActionLbl),
                Codeunit::"Subc. WhsePostReceipt Ext",
                'AdjustProdOrderLineQuantity'
            );
            CannotInvoiceErrorInfo.AddAction(
                StrSubstNo(ShowProductionOrderActionLbl),
                Codeunit::"Subc. WhsePostReceipt Ext",
                'ShowProductionOrder'
            );
            CannotInvoiceErrorInfo.AddAction(
                StrSubstNo(OpenItemTrackingAnywayActionLbl),
                Codeunit::"Subc. Purchase Line Ext",
                'OpenItemTrackingWithoutAdjustment'
            );
            Error(CannotInvoiceErrorInfo);
        end;
    end;

    internal procedure ShowProductionOrder(OverDeliveryErrorInfo: ErrorInfo)
    var
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PageManagement: Codeunit "Page Management";
        CannotOpenProductionOrderErr: Label 'Cannot open Production Order %1.', Comment = '%1=Production Order No.';
    begin
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.");
        if not PageManagement.PageRun(ProductionOrder) then
            Error(CannotOpenProductionOrderErr, ProductionOrder."No.");
    end;

    internal procedure AdjustProdOrderLineQuantity(OverDeliveryErrorInfo: ErrorInfo)
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SecondSourceQtyArray: array[3] of Decimal;
        CustomDimensions: Dictionary of [Text, Text];
        WarehouseReceiptLineSystemId: Guid;
    begin
        CustomDimensions := OverDeliveryErrorInfo.CustomDimensions();
        if CustomDimensions.ContainsKey(GetWarehouseReceiptLineSystemIdCustomDimensionLbl()) then
            if not Evaluate(WarehouseReceiptLineSystemId, CustomDimensions.Get(GetWarehouseReceiptLineSystemIdCustomDimensionLbl())) then
                exit;
        if not WarehouseReceiptLine.GetBySystemId(WarehouseReceiptLineSystemId) then
            exit;
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.");
        if WarehouseReceiptLine.Quantity > ProdOrderLine.Quantity then begin
            ProdOrderLine.Validate(Quantity, WarehouseReceiptLine.Quantity);
            ProdOrderLine.Modify();
            Commit();
        end;
        SecondSourceQtyArray[1] := Database::"Warehouse Receipt Line";
        SecondSourceQtyArray[2] := WarehouseReceiptLine."Qty. to Receive (Base)";
        SecondSourceQtyArray[3] := 0;

        OpenItemTrackingOfProdOrderLine(SecondSourceQtyArray, ProdOrderLine);
    end;

    internal procedure OpenItemTrackingWithoutAdjustment(OverDeliveryErrorInfo: ErrorInfo)
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SecondSourceQtyArray: array[3] of Decimal;
        CustomDimensions: Dictionary of [Text, Text];
        WarehouseReceiptLineSystemId: Guid;
    begin
        CustomDimensions := OverDeliveryErrorInfo.CustomDimensions();
        if CustomDimensions.ContainsKey(GetWarehouseReceiptLineSystemIdCustomDimensionLbl()) then
            if not Evaluate(WarehouseReceiptLineSystemId, CustomDimensions.Get(GetWarehouseReceiptLineSystemIdCustomDimensionLbl())) then
                exit;
        if not WarehouseReceiptLine.GetBySystemId(WarehouseReceiptLineSystemId) then
            exit;
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.");

        SecondSourceQtyArray[1] := Database::"Warehouse Receipt Line";
        SecondSourceQtyArray[2] := WarehouseReceiptLine."Qty. to Receive (Base)";
        SecondSourceQtyArray[3] := 0;

        OpenItemTrackingOfProdOrderLine(SecondSourceQtyArray, ProdOrderLine);
    end;

    procedure GetWarehouseReceiptLineSystemIdCustomDimensionLbl(): Text
    var
        WarehouseReceiptLineSystemIdCustomDimensionLbl: Label 'WarehouseReceiptLineSystemId', Locked = true;
    begin
        exit(WarehouseReceiptLineSystemIdCustomDimensionLbl);
    end;
}