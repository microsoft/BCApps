#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 12152 SubcontractingManagement
{
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        WorkCenterVendorDoesntExistErr: Label 'Vendor %1 on Work Center %2 does not exist.', Comment = 'Parameter 1 - subcontractor number, 2 - vendor number.';
        UpdateIsCancelledErr: Label 'The update is canceled.';
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';

    procedure GetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(WorkCenterNo);
        if WorkCenter."Subcontractor No." <> '' then begin
            if not Vendor.Get(WorkCenter."Subcontractor No.") then
                Error(WorkCenterVendorDoesntExistErr, WorkCenter."Subcontractor No.", WorkCenter."No.");
            Vendor.TestField("Subcontracting Location Code");
            exit(true);
        end;
        exit(false);
    end;

    procedure GetConsLocation(var ProdOrdComponent: Record "Prod. Order Component"; LocationCode: Code[10]): Code[10]
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrdRoutLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        Vendor: Record Vendor;
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        ProdOrdComponent.CalcFields("Qty. on Transfer Order (Base)");
        if ProdOrdComponent."Qty. on Transfer Order (Base)" <> 0 then
            exit(ProdOrdComponent."Location Code");

        ProdOrdRoutLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrdRoutLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrdRoutLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrdRoutLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrdRoutLine.SetRange("Routing Link Code", ProdOrdComponent."Routing Link Code");
        ProdOrdRoutLine.SetRange(Type, ProdOrdRoutLine.Type::"Work Center");
        if ProdOrdRoutLine.FindFirst() then begin
            WorkCenter.Get(ProdOrdRoutLine."Work Center No.");
            if WorkCenter."Subcontractor No." <> '' then begin
                if FindSubcOrder(ProdOrdRoutLine, PurchLine, PurchHeader) then
                    exit(PurchHeader."Subcontracting Location Code");

                Vendor.Get(WorkCenter."Subcontractor No.");
                if Vendor."Subcontractor Procurement" then begin
                    IsHandled := false;
                    OnGetConsLocationOnBeforeConfirmSubcontractingLocationCode(ProdOrdComponent, Vendor, LocationCode, IsHandled);
                    if IsHandled then
                        exit(LocationCode);
                    ProdOrdComponent.TestField("Location Code", Vendor."Subcontracting Location Code");
                    exit(Vendor."Subcontracting Location Code");
                end;
            end;
        end;

        exit(LocationCode);
    end;

    procedure FindSubcOrder(ProdOrdRoutLine: Record "Prod. Order Routing Line"; var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"): Boolean
    begin
        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.",
          "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrdRoutLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrdRoutLine."Routing Reference No.");
        PurchLine.SetRange("Routing No.", ProdOrdRoutLine."Routing No.");
        PurchLine.SetRange("Operation No.", ProdOrdRoutLine."Operation No.");
        if PurchLine.FindFirst() then begin
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            exit(true);
        end;
        exit(false);
    end;

    procedure UpdLinkedComponents(ProdOrdRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrdComponent: Record "Prod. Order Component";
        ProdOrdLine: Record "Prod. Order Line";
        Vendor: Record Vendor;
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        Subcontracting: Boolean;
        IsHandled: Boolean;
    begin
        Subcontracting := false;

        if ProdOrdRoutingLine.Type = ProdOrdRoutingLine.Type::"Work Center" then
            Subcontracting := GetSubcontractor(ProdOrdRoutingLine."No.", Vendor);

        ProdOrdComponent.SetRange(Status, ProdOrdRoutingLine.Status);
        ProdOrdComponent.SetRange("Prod. Order No.", ProdOrdRoutingLine."Prod. Order No.");
        ProdOrdComponent.SetRange("Prod. Order Line No.", ProdOrdRoutingLine."Routing Reference No.");
        ProdOrdComponent.SetRange("Routing Link Code", ProdOrdRoutingLine."Routing Link Code");
        if ProdOrdComponent.FindSet() then begin
            if ShowMsg then
                if not Confirm(RoutingLinkUpdConfQst, true, ProdOrdRoutingLine."Routing Link Code") then
                    Error(UpdateIsCancelledErr);
            ProdOrdLine.Get(ProdOrdRoutingLine.Status, ProdOrdComponent."Prod. Order No.", ProdOrdComponent."Prod. Order Line No.");
            GetPlanningParameters.AtSKU(
              SKU, ProdOrdLine."Item No.",
              ProdOrdLine."Variant Code",
              ProdOrdLine."Location Code");
            repeat
                if not Subcontracting then
                    ProdOrdComponent.Validate("Location Code", SKU."Components at Location")
                else
                    if Vendor."Subcontractor Procurement" then
                        ProdOrdComponent.Validate("Location Code", Vendor."Subcontracting Location Code")
                    else
                        ProdOrdComponent.Validate("Location Code", SKU."Components at Location");
                IsHandled := false;
                OnUpdLinkedComponentsOnBeforeModify(ProdOrdRoutingLine, ProdOrdComponent, ProdOrdLine, SKU, IsHandled);
                if not IsHandled then
                    ProdOrdComponent.Modify();
            until ProdOrdComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure DelLocationLinkedComponents(ProdOrdRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrdComponent: Record "Prod. Order Component";
        ProdOrdLine: Record "Prod. Order Line";
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        ProdOrdComponent.SetRange(Status, ProdOrdRoutingLine.Status);
        ProdOrdComponent.SetRange("Prod. Order No.", ProdOrdRoutingLine."Prod. Order No.");
        ProdOrdComponent.SetRange("Prod. Order Line No.", ProdOrdRoutingLine."Routing Reference No.");
        ProdOrdComponent.SetRange("Routing Link Code", ProdOrdRoutingLine."Routing Link Code");
        if ProdOrdComponent.FindSet() then begin
            if ShowMsg then
                if not Confirm(RoutingLinkUpdConfQst, true, ProdOrdRoutingLine."Routing Link Code") then
                    Error(UpdateIsCancelledErr);
            ProdOrdLine.Get(ProdOrdRoutingLine.Status, ProdOrdComponent."Prod. Order No.", ProdOrdComponent."Prod. Order Line No.");
            GetPlanningParameters.AtSKU(
              SKU, ProdOrdLine."Item No.",
              ProdOrdLine."Variant Code",
              ProdOrdLine."Location Code");
            repeat
                ProdOrdComponent.Validate("Location Code", SKU."Components at Location");
                IsHandled := false;
                OnDelLocationLinkedComponentsOnBeforeModify(ProdOrdRoutingLine, ProdOrdComponent, ProdOrdLine, SKU, IsHandled);
                if not IsHandled then
                    ProdOrdComponent.Modify();
            until ProdOrdComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure CheckVendorVsWorkCenter(ReqLine: Record "Requisition Line"; Vendor: Record Vendor; ShowMsg: Boolean)
    var
        ProdOrdLine: Record "Prod. Order Line";
        ProdOrdComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        ProdOrderRoutingLine.Get(
            ProdOrderRoutingLine.Status::Released, ReqLine."Prod. Order No.",
            ReqLine."Routing Reference No.", ReqLine."Routing No.", ReqLine."Operation No.");

        ProdOrdComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrdComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrdComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrdComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if ProdOrdComponent.FindSet() then begin
            if ShowMsg then
                if not Confirm(RoutingLinkUpdConfQst, true, ProdOrderRoutingLine."Routing Link Code") then
                    Error(UpdateIsCancelledErr);
            ProdOrdLine.Get(ProdOrdComponent.Status, ProdOrdComponent."Prod. Order No.", ProdOrdComponent."Prod. Order Line No.");
            GetPlanningParameters.AtSKU(
              SKU, ProdOrdLine."Item No.",
              ProdOrdLine."Variant Code",
              ProdOrdLine."Location Code");
            repeat
                if Vendor."Subcontractor Procurement" then
                    ProdOrdComponent.Validate("Location Code", Vendor."Subcontracting Location Code")
                else
                    ProdOrdComponent.Validate("Location Code", SKU."Components at Location");
                IsHandled := false;
                OnCheckVendorVsWorkCenterOnBeforeModify(ReqLine, ProdOrdComponent, ProdOrdLine, SKU, IsHandled);
                if not IsHandled then
                    ProdOrdComponent.Modify();
            until ProdOrdComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure CalculateHeaderValue(var TransHeader: Record "Transfer Header")
    var
        TransLine: Record "Transfer Line";
        GrossWeight: Decimal;
        NetWeight: Decimal;
        ParcelUnit: Decimal;
        TotVolume: Decimal;
    begin
        GrossWeight := 0;
        NetWeight := 0;
        ParcelUnit := 0;
        TotVolume := 0;

        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.SetRange("Derived From Line No.", 0);
        if TransLine.FindSet() then
            repeat
                GrossWeight := GrossWeight + (TransLine.Quantity * TransLine."Gross Weight");
                NetWeight := NetWeight + (TransLine.Quantity * TransLine."Net Weight");
                if TransLine."Units per Parcel" = 0 then
                    TransLine."Units per Parcel" := 1;
                ParcelUnit := ParcelUnit + Round(TransLine.Quantity * TransLine."Units per Parcel", 1, '>');
                TotVolume := TotVolume + (TransLine.Quantity * TransLine."Unit Volume");
            until TransLine.Next() = 0;

        GrossWeight := Round(GrossWeight, 0.01);
        NetWeight := Round(NetWeight, 0.01);
        ParcelUnit := Round(ParcelUnit, 1, '>');
        TotVolume := Round(TotVolume, 0.01);

        if TransHeader.Status = TransHeader.Status::Released then begin
            if TransHeader."Gross Weight" = 0 then
                TransHeader."Gross Weight" := GrossWeight;
            if TransHeader."Net Weight" = 0 then
                TransHeader."Net Weight" := NetWeight;
            if TransHeader."Parcel Units" = 0 then
                TransHeader."Parcel Units" := ParcelUnit;

            if TransHeader.Volume = 0 then
                TransHeader.Volume := TotVolume;
        end else begin
            TransHeader."Gross Weight" := GrossWeight;
            TransHeader."Net Weight" := NetWeight;
            TransHeader."Parcel Units" := ParcelUnit;
            TransHeader.Volume := TotVolume;
        end;
    end;

    procedure TransfSUBOrdCompToSUBTransfOrd(TransferLine: Record "Transfer Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        TrackingSpecification: Record "Tracking Specification";
        Item: Record Item;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        TotalQty: Decimal;
    begin
        ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservEntry);

        if ReservEntry.FindSet() then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next() = 0;

        ReservMgt.SetReservSource(ProdOrderComponent);
        ReservMgt.SetItemTrackingHandling(1); // allow deletion
        ReservMgt.DeleteReservEntries(true, 0);
        Clear(ReservMgt);

        if TempReservEntry.FindSet() then
            repeat
                if Item.Get(TempReservEntry."Item No.") then begin
                    CreateReservEntry.CreateReservEntryFor(
                      DATABASE::"Transfer Line", 1,
                      TransferLine."Document No.", TempReservEntry."Source Batch Name",
                      TransferLine."Derived From Line No.", TransferLine."Line No.",
                      TransferLine."Qty. per Unit of Measure", -TempReservEntry.Quantity, -TempReservEntry."Quantity (Base)",
                      TempReservEntry);
                    ProdOrderCompReserve.InitFromProdOrderComp(TrackingSpecification, ProdOrderComponent);
                    TrackingSpecification."Source Subtype" := "Production Order Status"::Released.AsInteger();
                    TrackingSpecification.CopyTrackingFromReservEntry(TempReservEntry);
                    CreateReservEntry.CreateReservEntryFrom(TrackingSpecification);
                    CreateReservEntry.CreateEntry(
                      TempReservEntry."Item No.", TempReservEntry."Variant Code",
                      TransferLine."Transfer-to Code", TempReservEntry.Description,
                      TempReservEntry."Expected Receipt Date", TempReservEntry."Shipment Date",
                      TempReservEntry."Entry No.", TempReservEntry."Reservation Status");
                    // Refresh Related Line for Item Ledger Entry
                    if ReservEntry.Get(TempReservEntry."Entry No.", not TempReservEntry.Positive) then
                        if Item."Order Tracking Policy".AsInteger() > Item."Order Tracking Policy"::None.AsInteger() then begin
                            TotalQty := ReservMgt.SourceQuantity(ReservEntry, true);
                            ReservMgt.AutoTrack(TotalQty);
                        end;
                end;
            until TempReservEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelLocationLinkedComponentsOnBeforeModify(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdLinkedComponentsOnBeforeModify(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendorVsWorkCenterOnBeforeModify(var RequisitionLine: Record "Requisition Line"; var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetConsLocationOnBeforeConfirmSubcontractingLocationCode(var ProdOrderComponent: Record "Prod. Order Component"; Vendor: Record Vendor; var LocationCode: Code[10]; IsHandled: Boolean)
    begin
    end;
}
#endif
