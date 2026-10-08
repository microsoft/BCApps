// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Warehouse.Journal;

codeunit 5985 "Serv-Item Tracking Rsrv. Mgt."
{
    Permissions = TableData "Item Entry Relation" = ri,
                  TableData "Value Entry Relation" = ri,
                  TableData "Tracking Specification" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The %1 does not match the quantity defined in item tracking.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CheckTrackingSpecification(ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    var
        ServLineToCheck: Record "Service Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        ServLineQtyHandled: Decimal;
        ServLineQtyToHandle: Decimal;
        TrackingQtyHandled: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        CheckServLine: Boolean;
        IsHandled: Boolean;
    begin
        // if a SalesLine is posted with ItemTracking then the whole quantity of
        // the regarding SalesLine has to be post with Item-Tracking

        if ServHeader."Document Type" <> ServHeader."Document Type"::Order then
            exit;

        TrackingQtyToHandle := 0;
        TrackingQtyHandled := 0;

        ServLineToCheck.Copy(ServLine);
        ServLineToCheck.SetRange("Document Type", ServLine."Document Type");
        ServLineToCheck.SetRange("Document No.", ServLine."Document No.");
        ServLineToCheck.SetRange(Type, ServLineToCheck.Type::Item);
        ServLineToCheck.SetFilter("Quantity Shipped", '<>%1', 0);
        ErrorFieldCaption := ServLineToCheck.FieldCaption("Qty. to Ship");

        if ServLineToCheck.FindSet() then begin
            ReservationEntry."Source Type" := DATABASE::"Service Line";
            ReservationEntry."Source Subtype" := ServHeader."Document Type".AsInteger();
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            repeat
                // Only Item where no SerialNo or LotNo is required
                ServLineToCheck.TestField(Type, ServLineToCheck.Type::Item);
                ServLineToCheck.TestField("No.");
                Item.Get(ServLineToCheck."No.");
                if Item."Item Tracking Code" <> '' then begin
                    Inbound := (ServLineToCheck.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";
                    IsHandled := false;
                    OnCheckTrackingSpecificationOnBeforeGetItemTrackingSetup(ServLineToCheck, ItemTrackingSetup, IsHandled);
                    if not IsHandled then
                        ItemTrackingMgt.GetItemTrackingSetup(
                            ItemTrackingCode, ItemJnlLine."Entry Type"::Sale, Inbound, ItemTrackingSetup);
                    CheckServLine := not ItemTrackingSetup.TrackingRequired();
                    if CheckServLine then
                        CheckServLine := CheckTrackingExists(ServLineToCheck);
                end else
                    CheckServLine := false;

                TrackingQtyToHandle := 0;
                TrackingQtyHandled := 0;

                if CheckServLine then begin
                    GetTrackingQuantities(ServLineToCheck, TrackingQtyToHandle, TrackingQtyHandled);
                    TrackingQtyToHandle := TrackingQtyToHandle * SignFactor;
                    TrackingQtyHandled := TrackingQtyHandled * SignFactor;
                    ServLineQtyToHandle := ServLineToCheck."Qty. to Ship (Base)";
                    ServLineQtyHandled := ServLineToCheck."Qty. Shipped (Base)";
                    if ((TrackingQtyHandled + TrackingQtyToHandle) <> (ServLineQtyHandled + ServLineQtyToHandle)) or
                       (TrackingQtyToHandle <> ServLineQtyToHandle)
                    then
                        Error(Text001, ErrorFieldCaption);
                end;
            until ServLineToCheck.Next() = 0;
        end;
    end;

    local procedure CheckTrackingExists(ServLine: Record "Service Line"): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        TrackingSpecification.SetSourceFilter(
          DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", true);
        TrackingSpecification.SetSourceFilter('', 0);
        ReservEntry.SetSourceFilter(
          DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);

        TrackingSpecification.SetRange(Correction, false);
        if not TrackingSpecification.IsEmpty() then
            exit(true);
        ReservEntry.SetFilter("Serial No.", '<>%1', '');
        if not ReservEntry.IsEmpty() then
            exit(true);
        ReservEntry.SetRange("Serial No.");
        ReservEntry.SetFilter("Lot No.", '<>%1', '');
        if not ReservEntry.IsEmpty() then
            exit(true);
        ReservEntry.SetRange("Lot No.");
        ReservEntry.SetFilter("Package No.", '<>%1', '');
        if not ReservEntry.IsEmpty() then
            exit(true);

        IsHandled := false;
        OnAfterCheckTrackingExists(ReservEntry, IsHandled);
        if IsHandled then
            exit(true);
    end;

    local procedure GetTrackingQuantities(ServLine: Record "Service Line"; var TrackingQtyToHandle: Decimal; var TrackingQtyHandled: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.SetSourceFilter(
          DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", true);
        TrackingSpecification.SetSourceFilter('', 0);
        TrackingSpecification.CalcSums("Quantity Handled (Base)");
        TrackingQtyHandled := TrackingSpecification."Quantity Handled (Base)";

        ReservEntry.SetSourceFilter(
          DATABASE::"Service Line", ServLine."Document Type".AsInteger(), ServLine."Document No.", ServLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        if ReservEntry.FindSet() then
            repeat
                if ReservEntry.TrackingExists() then
                    TrackingQtyToHandle := TrackingQtyToHandle + ReservEntry."Qty. to Handle (Base)";
            until ReservEntry.Next() = 0;
    end;

    procedure SaveInvoiceSpecification(var TempInvoicingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification: Record "Tracking Specification")
    begin
        TempInvoicingSpecification.Reset();
        if TempInvoicingSpecification.Find('-') then begin
            repeat
                TempInvoicingSpecification."Quantity Invoiced (Base)" += TempInvoicingSpecification."Qty. to Invoice (Base)";
                TempTrackingSpecification := TempInvoicingSpecification;
                TempTrackingSpecification."Buffer Status" := TempTrackingSpecification."Buffer Status"::MODIFY;
                TempTrackingSpecification.Insert();
            until TempInvoicingSpecification.Next() = 0;
            TempInvoicingSpecification.DeleteAll();
        end;
    end;

    procedure InsertTrackingSpecification(var ServHeader: Record "Service Header"; var TempTrackingSpecification: Record "Tracking Specification")
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.Find('-') then begin
            repeat
                TrackingSpecification := TempTrackingSpecification;
                TrackingSpecification."Buffer Status" := 0;
                TrackingSpecification.Correction := false;
                TrackingSpecification.InitQtyToShip();
                TrackingSpecification."Quantity actual Handled (Base)" := 0;
                if TempTrackingSpecification."Buffer Status" = TempTrackingSpecification."Buffer Status"::MODIFY then
                    TrackingSpecification.Modify()
                else
                    TrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0;
            TempTrackingSpecification.DeleteAll();
        end;

        ServiceLineReserve.UpdateItemTrackingAfterPosting(ServHeader);
    end;

    procedure InsertTempHandlngSpecification(SrcType: Integer; var ServLine: Record "Service Line"; var TempHandlingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecificationInv: Record "Tracking Specification"; QtyToInvoiceNonZero: Boolean)
    begin
        if TempHandlingSpecification.Find('-') then
            repeat
                TempTrackingSpecification := TempHandlingSpecification;
                TempTrackingSpecification."Source Type" := SrcType;
                TempTrackingSpecification."Source Subtype" := ServLine."Document Type".AsInteger();
                TempTrackingSpecification."Source ID" := ServLine."Document No.";
                TempTrackingSpecification."Source Batch Name" := '';
                TempTrackingSpecification."Source Prod. Order Line" := 0;
                TempTrackingSpecification."Source Ref. No." := ServLine."Line No.";
                if TempTrackingSpecification.Insert() then;
                if QtyToInvoiceNonZero then begin
                    TempTrackingSpecificationInv := TempTrackingSpecification;
                    if TempTrackingSpecificationInv.Insert() then;
                end;
            until TempHandlingSpecification.Next() = 0;
    end;

    procedure RetrieveInvoiceSpecification(var ServLine: Record "Service Line"; var TempInvoicingSpecification: Record "Tracking Specification"; Consume: Boolean) Ok: Boolean
    begin
        Ok := ServiceLineReserve.RetrieveInvoiceSpecification(ServLine, TempInvoicingSpecification, Consume);
    end;

    procedure DeleteInvoiceSpecFromHeader(var ServHeader: Record "Service Header")
    begin
        ServiceLineReserve.DeleteInvoiceSpecFromHeader(ServHeader);
    end;

    procedure InsertShptEntryRelation(var ServiceShptLine: Record "Service Shipment Line"; var TempHandlingSpecification: Record "Tracking Specification"; var TempTrackingSpecificationInv: Record "Tracking Specification"; ItemLedgShptEntryNo: Integer): Integer
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        TempTrackingSpecificationInv.Reset();
        if TempTrackingSpecificationInv.Find('-') then begin
            repeat
                TempHandlingSpecification := TempTrackingSpecificationInv;
                if TempHandlingSpecification.Insert() then;
            until TempTrackingSpecificationInv.Next() = 0;
            TempTrackingSpecificationInv.DeleteAll();
        end;

        TempHandlingSpecification.Reset();
        if TempHandlingSpecification.Find('-') then begin
            repeat
                ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification);
                ServiceShptLine.TransferToItemEntryRelation(ItemEntryRelation);
                ItemEntryRelation.Insert();
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
            exit(0);
        end;
        exit(ItemLedgShptEntryNo);
    end;

    procedure InsertValueEntryRelation(var TempValueEntryRelation: Record "Value Entry Relation")
    var
        ValueEntryRelation: Record "Value Entry Relation";
    begin
        TempValueEntryRelation.Reset();
        if TempValueEntryRelation.Find('-') then begin
            repeat
                ValueEntryRelation := TempValueEntryRelation;
                ValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0;
            TempValueEntryRelation.DeleteAll();
        end;
    end;

    procedure TransServLineToItemJnlLine(var ServiceLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeShippedBase: Decimal; var CheckApplFromItemEntry: Boolean)
    begin
        ServiceLineReserve.TransServLineToItemJnlLine(ServiceLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry);
    end;

    procedure TransferReservToItemJnlLine(var ServiceLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; QtyToBeShippedBase: Decimal; var CheckApplFromItemEntry: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferReservToItemJnlLine(ServiceLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry, IsHandled);
        if IsHandled then
            exit;

        if QtyToBeShippedBase = 0 then
            exit;
        Clear(ServiceLineReserve);
        ServiceLineReserve.TransServLineToItemJnlLine(
          ServiceLine, ItemJnlLine, QtyToBeShippedBase, CheckApplFromItemEntry)
    end;

    procedure SplitWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line"; var TempWhseJnlLine2: Record "Warehouse Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; ToTransfer: Boolean)
    begin
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, ToTransfer);
    end;

    procedure AdjustQuantityRounding(RemQtyToBeInvoiced: Decimal; QtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
        ItemTrackingMgt.AdjustQuantityRounding(
          RemQtyToBeInvoiced, QtyToBeInvoiced,
          RemQtyToBeInvoicedBase, QtyToBeInvoicedBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingExists(var ReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferReservToItemJnlLine(var ServiceLine: Record "Service Line"; var ItemJnlLine: Record "Item Journal Line"; var QtyToBeShippedBase: Decimal; var CheckApplFromItemEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTrackingSpecificationOnBeforeGetItemTrackingSetup(ServLineToCheck: Record "Service Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;
}

