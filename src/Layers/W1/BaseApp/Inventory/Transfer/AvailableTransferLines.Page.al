// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

page 99000896 "Available - Transfer Lines"
{
    Caption = 'Available - Transfer Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Transfer Line";
    SourceTableView = sorting("Document No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the items on this line.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';
                }
                field("Reserved Qty. Inbnd. (Base)"; Rec."Reserved Qty. Inbnd. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-to location, expressed in base units of measure.';
                }
                field("Reserved Qty. Outbnd. (Base)"; Rec."Reserved Qty. Outbnd. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-from location, expressed in the base unit of measure.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Location;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available.';
                }
                field(ReservedQuantity; GetReservedQtyInLine())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the document type.';

                    trigger OnDrillDown()
                    begin
                        ReservEntry2.Reset();
                        Rec.SetReservationFilters(ReservEntry2, TransferDirection);
                        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
                        ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry);
                        PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry2);
                        UpdateReservFrom();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ReservEntry.LockTable();
                        UpdateReservMgt();
                        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, TransferDirection.AsInteger());
                        ReservMgt.CalculateRemainingQty(NewQtyReserved, NewQtyReservedBase);
                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        ReservMgt.CopySign(NewQtyReservedBase, QtyToReserveBase);
                        if NewQtyReservedBase <> 0 then
                            if NewQtyReservedBase > QtyToReserveBase then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReserved, NewQtyReservedBase)
                        else
                            Error(Text001);
                    end;
                }
                action(CancelReservation)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text002, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        Rec.SetReservationFilters(ReservEntry2, TransferDirection);
                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt();
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next() = 0;

                            UpdateReservFrom();
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, TransferDirection.AsInteger());
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");
        if not DirectionIsSet then
            Error(Text000);

        SetSourceTableFilters();
    end;

    var
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        NewQtyReserved: Decimal;
        NewQtyReservedBase: Decimal;
        CaptionText: Text;
        TransferDirection: Enum "Transfer Direction";
        DirectionIsSet: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Direction has not been set.';
        Text001: Label 'Fully reserved.';
        Text002: Label 'Do you want to cancel the reservation?';
#pragma warning disable AA0470
        Text003: Label 'Available Quantity is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ReservEntry: Record "Reservation Entry";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry")
    begin
        SetSource(CurrentSourceRecRef, CurrentReservEntry, TransferDirection::Outbound);
    end;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, Direction);
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, Direction);

        SetInbound(ReservMgt.IsPositive());
    end;

    local procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyThisLine: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
    begin
        case TransferDirection of
            TransferDirection::Outbound:
                begin
                    Rec.CalcFields("Reserved Qty. Outbnd. (Base)");
                    QtyThisLine := Rec."Outstanding Qty. (Base)";
                    ReservQty := Rec."Reserved Qty. Outbnd. (Base)";
                    EntryDate := Rec."Shipment Date";
                    Rec.TestField("Transfer-from Code", ReservEntry."Location Code");
                    LocationCode := Rec."Transfer-from Code";
                end;
            TransferDirection::Inbound:
                begin
                    Rec.CalcFields("Reserved Qty. Inbnd. (Base)");
                    QtyThisLine := Rec."Outstanding Qty. (Base)";
                    ReservQty := Rec."Reserved Qty. Inbnd. (Base)";
                    EntryDate := Rec."Receipt Date";
                    Rec.TestField("Transfer-to Code", ReservEntry."Location Code");
                    LocationCode := Rec."Transfer-to Code";
                end;
        end;

        if QtyThisLine - ReservQty < ReserveQuantityBase then
            Error(Text003, QtyThisLine + ReservQty);

        Rec.TestField("Item No.", ReservEntry."Item No.");
        Rec.TestField("Variant Code", ReservEntry."Variant Code");

        UpdateReservMgt();
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Transfer Line", TransferDirection.AsInteger(), Rec."Document No.", '', Rec."Derived From Line No.", Rec."Line No.",
          Rec."Variant Code", LocationCode, Rec."Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, EntryDate, ReserveQuantity, ReserveQuantityBase, TrackingSpecification);
        UpdateReservFrom();
    end;

    local procedure UpdateReservFrom()
    begin
        SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());

        OnAfterUpdateReservFrom(ReservEntry);
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, ReservEntry.GetTransferDirection());

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    protected procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        Rec.SetReservationFilters(ReservEntry2, TransferDirection);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetInbound(DirectionIsInbound: Boolean)
    begin
        if DirectionIsInbound then
            TransferDirection := TransferDirection::Inbound
        else
            TransferDirection := TransferDirection::Outbound;
        DirectionIsSet := true;
    end;

    local procedure SetSourceTableFilters()
    begin
        case TransferDirection of
            TransferDirection::Outbound:
                begin
                    Rec.SetFilter("Shipment Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
                    Rec.SetRange("Transfer-from Code", ReservEntry."Location Code");
                end;
            TransferDirection::Inbound:
                begin
                    Rec.SetFilter("Receipt Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
                    Rec.SetRange("Transfer-to Code", ReservEntry."Location Code");
                end;
        end;

        Rec.SetRange("Item No.", ReservEntry."Item No.");
        Rec.SetRange("Variant Code", ReservEntry."Variant Code");
        Rec.SetFilter("Outstanding Qty. (Base)", '>0');

        OnAfterSetFilters(Rec, ReservEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var TransferLine: Record "Transfer Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservFrom(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservMgt(var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}

