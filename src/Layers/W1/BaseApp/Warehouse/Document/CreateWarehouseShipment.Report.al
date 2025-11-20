// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Request;

report 5708 "Create Warehouse Shipment"
{
    UsageCategory = Tasks;
    ApplicationArea = Warehouse;
    ProcessingOnly = true;
    Caption = 'Create Warehouse Shipment';

    dataset
    {
        dataitem("Warehouse Request"; "Warehouse Request")
        {
            DataItemTableView = sorting("Source Document", "Source No.") where(Type = const(Outbound), "Document Status" = const(Released));
            RequestFilterFields = "Source Document", "Source No.", "Location Code";

            trigger OnAfterGetRecord()
            var
                Location: Record Location;
            begin
                if not Location.RequireShipment("Location Code") then
                    CurrReport.Skip();

                case "Source Document" of
                    "Source Document"::"Purchase Return Order":
                        CreateWarehouseShipmentForPurchaseReturnOrder();
                    "Source Document"::"Sales Order":
                        CreateWarehouseShipmentForSalesOrder();
                    "Source Document"::"Outbound Transfer":
                        CreateWarehouseShipmentForTransferOrder();
                end;

                OnWarehouseRequestOnAfterGetRecord("Warehouse Request");

            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field("Do Not Fill Qty. to Handle"; DoNotFillQtytoHandle)
                    {
                        Caption = 'Do not fill Qty. to Handle';
                        ToolTip = 'Specifies if the Quantity to Handle field in the warehouse document is prefilled according to the source document quantities.';
                    }
                    field("Reserved Stock Only"; ReservedFromStock)
                    {
                        Caption = 'Reserved stock only';
                        ToolTip = 'Specifies if you want to include only source document lines that are fully or partially reserved from current stock.';
                        ValuesAllowed = " ", "Full and Partial", Full;
                    }
                }
            }
        }

    }

    var
        DoNotFillQtytoHandle: Boolean;
        ReservedFromStock: Enum "Reservation From Stock";

    procedure InitializeRequest(NewDoNotFillQtyToHandle: Boolean; NewReservedFromStock: Enum "Reservation From Stock")
    begin
        DoNotFillQtytoHandle := NewDoNotFillQtyToHandle;
        ReservedFromStock := NewReservedFromStock;
    end;

    local procedure CreateWarehouseShipmentForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        WarehouseRequest.Copy("Warehouse Request");

        SalesHeader.Get(SalesHeader."Document Type"::Order, WarehouseRequest."Source No.");
        if SalesHeader.Status <> SalesHeader.Status::Released then
            exit;

        if not SalesHeader.IsApprovedForPostingBatch() then
            exit;

        if SalesHeader.WhseShipmentConflict(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Shipping Advice") then
            exit;

        if GetSourceDocOutbound.CheckSalesHeader(SalesHeader, false) then
            exit;

        CreateWarehouseShipmentFromWhseRequest(WarehouseRequest);
    end;

    local procedure CreateWarehouseShipmentForPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.Copy("Warehouse Request");

        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", WarehouseRequest."Source No.");
        if PurchaseHeader.Status <> PurchaseHeader.Status::Released then
            exit;

        CreateWarehouseShipmentFromWhseRequest(WarehouseRequest);
    end;

    local procedure CreateWarehouseShipmentForTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        WarehouseRequest.Copy("Warehouse Request");

        TransferHeader.Get(WarehouseRequest."Source No.");
        if TransferHeader.Status <> TransferHeader.Status::Released then
            exit;

        if GetSourceDocOutbound.CheckTransferHeader(TransferHeader, false) then
            exit;

        CreateWarehouseShipmentFromWhseRequest(WarehouseRequest);
    end;

    procedure CreateWarehouseShipmentFromWhseRequest(var WarehouseRequest: Record "Warehouse Request")
    var
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WarehouseRequest.SetRecFilter();
        GetSourceDocuments.SetDoNotFillQtytoHandle(DoNotFillQtytoHandle);
        GetSourceDocuments.SetReservedFromStock(ReservedFromStock);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.RunModal();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWarehouseRequestOnAfterGetRecord(WarehouseRequest: Record "Warehouse Request")
    begin
    end;
}
