// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;

codeunit 99001534 "Subc. Purchase Line Ext"
{
    var
        SubcSynchronizeManagement: Codeunit "Subc. Synchronize Management";
        QtyMismatchTitleLbl: Label 'Quantity Mismatch';
        QtyMismatchErr: Label 'The quantity (%1) in %2 is greater than the specified quantity (%3) in %4. In order to open item tracking lines, first adjust the quantity on %2 to at least match the quantity on %4. You can adjust the quantity from %5 to %6 by using the action below.',
        Comment = '%1 = PurchaseLine Outstanding Qty, %2 = Tablecaption PurchaseLine, %3 = ProdOrderLine Remaining Qty, %4 = Tablecaption ProdOrderLine, %5 = Current ProdOrderLine Qty, %6 = New PurchaseLine Qty';
        NotLastOperationLineErr: Label 'Item tracking lines can only be viewed for subcontracting purchase lines which are linked to a routing line which is the last operation.';
        CannotOpenProductionOrderErr: Label 'Cannot open Production Order %1.', Comment = '%1=Production Order No.';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        SubcSynchronizeManagement.DeleteEnhancedDocumentsByDeletePurchLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Expected Receipt Date", false, false)]
    local procedure OnAfterValidateExpectedReceiptDate(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            SubcSynchronizeManagement.SynchronizeExpectedReceiptDate(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidateQuantity(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            SubcSynchronizeManagement.SynchronizeQuantity(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Unit of Measure Code", false, false)]
    local procedure OnAfterValidateUnitOfMeasureCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            SubcSynchronizeManagement.SynchronizeQuantity(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeUpdateDirectUnitCost, '', false, false)]
    local procedure OnBeforeUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
        if PurchLine."Prod. Order No." <> '' then begin
            Handled := true;
            PurchLine.UpdateAmounts();

            GetSubcontractingPrice(PurchLine);
            PurchLine.Validate("Line Discount %");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnValidateVariantCodeOnBeforeDropShipmentError, '', false, false)]
    local procedure OnValidateVariantCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    var
        ChangeVariantNoNotAllowedErr: Label 'You cannot change %1 because the order line is associated with production order %2.', Comment = '%1=Field Caption, %2=Production Order No.';
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(ChangeVariantNoNotAllowedErr, PurchaseLine.FieldCaption(PurchaseLine."Variant Code"), PurchaseLine."Prod. Order No.");
    end;

    local procedure GetSubcontractingPrice(var PurchaseLine: Record "Purchase Line")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if (PurchaseLine.Type = PurchaseLine.Type::Item) and (PurchaseLine."No." <> '') and (PurchaseLine."Prod. Order No." <> '') and (PurchaseLine."Operation No." <> '') then
            SubcPriceManagement.GetSubcPriceForPurchLine(PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeOpenItemTrackingLines, '', false, false)]
    local procedure OpenProdOrderLineItemTrackingOnBeforeOpenItemTrackingLines(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        if OpenItemTrackingOfProdOrderLine(PurchaseLine, false) then
            IsHandled := true;
    end;

    local procedure CheckItem(PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        PurchaseLine.TestField(Type, "Purchase Line Type"::Item);
        PurchaseLine.TestField("No.");
        Item.SetLoadFields("Item Tracking Code");
        Item.Get(PurchaseLine."No.");
        Item.TestField("Item Tracking Code");
        ItemTrackingCode.Get(Item."Item Tracking Code");
    end;

    local procedure CheckOverDeliveryQty(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        ShowProductionOrderActionLbl: Label 'Show Prod. Order';
        AdjustQtyActionLbl: Label 'Adjust Quantity';
        OpenItemTrackingAnywayActionLbl: Label 'Open anyway';
        CannotInvoiceErrorInfo: ErrorInfo;
    begin
        if PurchaseLine.Quantity > ProdOrderLine.Quantity then begin
            CannotInvoiceErrorInfo.Title := QtyMismatchTitleLbl;
            CannotInvoiceErrorInfo.Message := StrSubstNo(QtyMismatchErr, PurchaseLine."Outstanding Quantity", PurchaseLine.TableCaption(), ProdOrderLine."Remaining Quantity", ProdOrderLine.TableCaption(), ProdOrderLine.Quantity, PurchaseLine.Quantity);

            CannotInvoiceErrorInfo.RecordId := PurchaseLine.RecordId;
            CannotInvoiceErrorInfo.AddAction(
                AdjustQtyActionLbl,
                Codeunit::"Subc. Purchase Line Ext",
                'AdjustProdOrderLineQuantity'
            );
            CannotInvoiceErrorInfo.AddAction(
                ShowProductionOrderActionLbl,
                Codeunit::"Subc. Purchase Line Ext",
                'ShowProductionOrder'
            );
            CannotInvoiceErrorInfo.AddAction(
                OpenItemTrackingAnywayActionLbl,
                Codeunit::"Subc. Purchase Line Ext",
                'OpenItemTrackingWithoutAdjustment'
            );
            Error(CannotInvoiceErrorInfo);
        end;
    end;

    local procedure OpenItemTrackingOfProdOrderLine(var PurchaseLine: Record "Purchase Line"; SkipOverDeliveryCheck: Boolean): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        TrackingSpecification: Record "Tracking Specification";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
        SecondSourceQtyArray: array[3] of Decimal;
    begin
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::None then
            exit(false);
        CheckItem(PurchaseLine);
        if PurchaseLine."Subc. Purchase Line Type" = "Subc. Purchase Line Type"::NotLastOperation then
            Error(NotLastOperationLineErr);
        if PurchaseLine."Subc. Purchase Line Type" <> "Subc. Purchase Line Type"::LastOperation then
            exit(false);
        if not PurchaseLine.IsSubcontractingLineWithLastOperation(ProdOrderLine) then
            exit(false);

        SecondSourceQtyArray[1] := Database::"Warehouse Receipt Line";
        SecondSourceQtyArray[2] := PurchaseLine.CalcBaseQtyFromQuantity(PurchaseLine."Qty. to Receive", PurchaseLine.FieldCaption("Qty. Rounding Precision"), PurchaseLine.FieldCaption("Qty. to Receive"), PurchaseLine.FieldCaption("Qty. to Receive (Base)"));
        SecondSourceQtyArray[3] := 0;

        if not SkipOverDeliveryCheck then
            CheckOverDeliveryQty(PurchaseLine, ProdOrderLine);

        ProdOrderLineReserve.InitFromProdOrderLine(TrackingSpecification, ProdOrderLine);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderLine."Due Date");
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQtyArray);
        ItemTrackingLines.RunModal();
        exit(true);
    end;

    internal procedure ShowProductionOrder(OverDeliveryErrorInfo: ErrorInfo)
    var
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PageManagement: Codeunit "Page Management";
    begin
        PurchaseLine.SetLoadFields("Prod. Order No.");
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.");
        if not PageManagement.PageRun(ProductionOrder) then
            Error(CannotOpenProductionOrderErr, ProductionOrder."No.");
    end;

    internal procedure AdjustProdOrderLineQuantity(OverDeliveryErrorInfo: ErrorInfo)
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        PurchaseLine.SetLoadFields(Type, "No.", "Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", Quantity, "Qty. to Receive", "Qty. to Receive (Base)", "Qty. Rounding Precision", "Outstanding Quantity");
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.");
        if PurchaseLine.Quantity > ProdOrderLine.Quantity then begin
            ProdOrderLine.Validate(Quantity, PurchaseLine.Quantity);
            ProdOrderLine.Modify();
            Commit();
        end;
        OpenItemTrackingOfProdOrderLine(PurchaseLine, true);
    end;

    internal procedure OpenItemTrackingWithoutAdjustment(OverDeliveryErrorInfo: ErrorInfo)
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        PurchaseLine.SetLoadFields(Type, "No.", "Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Qty. to Receive", "Qty. to Receive (Base)", "Qty. Rounding Precision", "Outstanding Quantity");
        PurchaseLine.Get(OverDeliveryErrorInfo.RecordId);
        ProdOrderLine.SetLoadFields(SystemId);
        ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.");
        OpenItemTrackingOfProdOrderLine(PurchaseLine, true);
    end;
}