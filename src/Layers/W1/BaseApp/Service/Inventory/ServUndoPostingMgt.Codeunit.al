// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Ledger;

codeunit 6484 "Serv. Undo Posting Mgt."
{
    var
        UndoPostingManagement: Codeunit "Undo Posting Management";

    procedure TestServShptLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        UndoPostingManagement.TestAllTransactions(
            DATABASE::"Service Shipment Line", ServShptLine."Document No.", ServShptLine."Line No.",
            DATABASE::"Service Line", ServLine."Document Type"::Order.AsInteger(), ServShptLine."Order No.", ServShptLine."Order Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", 'OnShouldRevertBaseQtySign', '', false, false)]
    local procedure OnShouldCollectSourceType(SourceType: Integer; var RevertSign: Boolean);
    begin
        RevertSign := RevertSign or (SourceType = Database::"Service Shipment Line");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", 'OnSkipTestWarehouseShipmentLine', '', false, false)]
    local procedure OnSkipTestWarehouseShipmentLine(UndoType: Integer; var SkipTest: Boolean);
    begin
        SkipTest := SkipTest or (UndoType = Database::"Service Shipment Line");
    end;

    procedure UpdateServLine(ServLine: Record "Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xServLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServLine(ServLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
#if not CLEAN25
        UndoPostingManagement.RunOnBeforeUpdateServLine(ServLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
#endif
        if IsHandled then
            exit;

        xServLine := ServLine;
        case ServLine."Document Type" of
            ServLine."Document Type"::Order:
                begin
                    ServLine."Quantity Shipped" := ServLine."Quantity Shipped" - UndoQty;
                    ServLine."Qty. Shipped (Base)" := ServLine."Qty. Shipped (Base)" - UndoQtyBase;
                    ServLine."Qty. to Consume" := 0;
                    ServLine."Qty. to Consume (Base)" := 0;
                    ServLine.InitOutstanding();
                    ServLine.InitQtyToShip();
                end;
            else
                ServLine.FieldError("Document Type");
        end;
        ServLine.Modify();
        RevertPostedItemTrackingFromServiceLine(ServLine, TempUndoneItemLedgEntry);
        xServLine."Quantity (Base)" := 0;
        ServiceLineReserveVerifyQuantity(ServLine, xServLine);

        UndoPostingManagement.UpdateWarehouseRequest(
            DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Location Code");

        OnAfterUpdateServLine(ServLine);
#if not CLEAN25
        UndoPostingManagement.RunOnAfterUpdateServLine(ServLine);
#endif
    end;

    local procedure RevertPostedItemTrackingFromServiceLine(ServiceLine: Record "Service Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine, TempUndoneItemLedgEntry, IsHandled);
#if not CLEAN25
        UndoPostingManagement.RunOnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine, TempUndoneItemLedgEntry, IsHandled);
#endif
        if IsHandled then
            exit;

        UndoPostingManagement.RevertPostedItemTracking(TempUndoneItemLedgEntry, ServiceLine."Posting Date", false);
    end;

    local procedure ServiceLineReserveVerifyQuantity(ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
#if not CLEAN25
        UndoPostingManagement.RunOnBeforeServiceLineReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceLineReserve.VerifyQuantity(ServiceLine, xServiceLine);
    end;

    procedure UpdateServLineCnsm(var ServLine: Record "Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ServHeader: Record "Service Header";
        xServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ServCalcDiscount: Codeunit "Service-Calc. Discount";
    begin
        xServLine := ServLine;
        case ServLine."Document Type" of
            ServLine."Document Type"::Order:
                begin
                    ServLine."Quantity Consumed" := ServLine."Quantity Consumed" - UndoQty;
                    ServLine."Qty. Consumed (Base)" := ServLine."Qty. Consumed (Base)" - UndoQtyBase;
                    ServLine."Quantity Shipped" := ServLine."Quantity Shipped" - UndoQty;
                    ServLine."Qty. Shipped (Base)" := ServLine."Qty. Shipped (Base)" - UndoQtyBase;
                    ServLine."Qty. to Invoice" := 0;
                    ServLine."Qty. to Invoice (Base)" := 0;
                    ServLine.InitOutstanding();
                    ServLine.InitQtyToShip();
                    ServLine.Validate(ServLine."Line Discount %");
                    ServLine.ConfirmAdjPriceLineChange();
                    ServLine.Modify();

                    SalesSetup.Get();
                    if SalesSetup."Calc. Inv. Discount" then begin
                        ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
                        ServCalcDiscount.CalculateWithServHeader(ServHeader, ServLine, ServLine);
                    end;
                end;
            else
                ServLine.FieldError(ServLine."Document Type");
        end;
        ServLine.Modify();
        UndoPostingManagement.RevertPostedItemTracking(TempUndoneItemLedgEntry, ServLine."Posting Date", false);
        xServLine."Quantity (Base)" := 0;
        ServiceLineCnsmReserveVerifyQuantity(ServLine, xServLine);
    end;

    local procedure ServiceLineCnsmReserveVerifyQuantity(ServiceLine: Record "Service Line"; xServiceLine: Record "Service Line")
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
#if not CLEAN25
        UndoPostingManagement.RunOnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceLineReserve.VerifyQuantity(ServiceLine, xServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServLine(var ServiceLine: Record "Service Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServLine(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}