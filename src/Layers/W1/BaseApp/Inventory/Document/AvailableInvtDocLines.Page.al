// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

page 6873 "Available - Invt. Doc. Lines"
{
    Caption = 'Available - Invt. Doc. Lines';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Invt. Document Line";
    SourceTableView = sorting("Document Type", "Document No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity on the line expressed in base units of measure.';
                }
                field("Reserved Qty. Inbnd. (Base)"; Rec."Reserved Qty. Inbnd. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item base quantity that is reserved at the warehouse of the receiver.';
                }
                field("Reserved Qty. Outbnd. (Base)"; Rec."Reserved Qty. Outbnd. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item base quantity that is reserved at the warehouse of the receiver.';
                }
                field(QtyToReserveBase; QtyToReserveBase)
                {
                    ApplicationArea = Basic, Suite;
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
                        Rec.SetReservationFilters(ReservEntry2);
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
                        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Rec."Document Type".AsInteger());
                        ReservMgt.CalculateRemainingQty(NewQtyReserved, NewQtyReservedBase);
                        ReservMgt.CopySign(NewQtyReservedBase, QtyToReserveBase);
                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        if NewQtyReservedBase <> 0 then
                            if Abs(NewQtyReservedBase) > Abs(QtyToReserveBase) then
                                CreateReservation(QtyToReserve, QtyToReserveBase)
                            else
                                CreateReservation(NewQtyReserved, NewQtyReservedBase)
                        else
                            Error(FullyReservedErr);
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
                        if not Confirm(CancelReservationQst, false) then
                            exit;

                        ReservEntry2.Copy(ReservEntry);
                        Rec.SetReservationFilters(ReservEntry2);
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
        Rec.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Rec."Document Type".AsInteger());
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        Rec.SetFilter("Document Date", ReservMgt.GetAvailabilityFilter(ReservEntry."Shipment Date"));
        Rec.SetRange("Location Code", ReservEntry."Location Code");
        Rec.SetRange("Item No.", ReservEntry."Item No.");
        Rec.SetRange("Variant Code", ReservEntry."Variant Code");
        Rec.SetFilter(Quantity, '>0');
    end;

    var
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        NewQtyReserved: Decimal;
        NewQtyReservedBase: Decimal;
        CaptionText: Text;
        Direction: Option Outbound,Inbound;
        FullyReservedErr: Label 'Fully reserved.';
        CancelReservationQst: Label 'Do you want to cancel the reservation?';
        AvailableQuantityErr: Label 'Available Quantity is %1.', Comment = '%1 - quantity';

    protected var
        ReservEntry: Record "Reservation Entry";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        QtyReserved: Decimal;
        QtyReservedBase: Decimal;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry")
    var
        TransferDirection: Enum "Transfer Direction";
    begin
        SetSource(CurrentSourceRecRef, CurrentReservEntry, TransferDirection::Outbound);
    end;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; TransferDirection: Enum "Transfer Direction")
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, TransferDirection);
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, TransferDirection);

        SetInbound(ReservMgt.IsPositive());
    end;

    procedure CreateReservation(ReserveQuantity: Decimal; ReserveQuantityBase: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        QtyThisLine: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
    begin
        case Rec."Document Type" of
            Rec."Document Type"::Shipment:
                begin
                    Rec.CalcFields("Reserved Qty. Outbnd. (Base)");
                    QtyThisLine := Rec."Quantity (Base)";
                    ReservQty := Rec."Reserved Qty. Outbnd. (Base)";
                    EntryDate := Rec."Document Date";
                    Rec.TestField("Location Code", ReservEntry."Location Code");
                    LocationCode := Rec."Location Code";
                end;
            Rec."Document Type"::Receipt:
                begin
                    Rec.CalcFields("Reserved Qty. Inbnd. (Base)");
                    QtyThisLine := Rec."Quantity (Base)";
                    ReservQty := Rec."Reserved Qty. Inbnd. (Base)";
                    EntryDate := Rec."Document Date";
                    Rec.TestField("Location Code", ReservEntry."Location Code");
                    LocationCode := Rec."Location Code";
                end;
        end;

        if QtyThisLine - ReservQty < ReserveQuantityBase then
            Error(AvailableQuantityErr, QtyThisLine + ReservQty);

        Rec.TestField("Item No.", ReservEntry."Item No.");
        Rec.TestField("Variant Code", ReservEntry."Variant Code");

        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Invt. Document Line", Rec."Document Type".AsInteger(), Rec."Document No.", '', 0, Rec."Line No.",
          Rec."Variant Code", LocationCode, Rec."Qty. per Unit of Measure");
        ReservMgt.CreateReservation(
          ReservEntry.Description, EntryDate, ReserveQuantity, ReserveQuantityBase, TrackingSpecification);

        UpdateReservFrom();
    end;

    local procedure UpdateReservFrom()
    begin
        SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
    end;

    local procedure UpdateReservMgt()
    begin
        Clear(ReservMgt);
        ReservMgt.SetReservSource(SourceRecRef, ReservEntry.GetTransferDirection());
    end;

    protected procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        Rec.SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    procedure SetInbound(DirectionIsInbound: Boolean)
    begin
        if DirectionIsInbound then
            Direction := Direction::Inbound
        else
            Direction := Direction::Outbound;
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure SetSource', '27.0')]
    procedure SetAssemblyLine(var CurrentAssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyLine);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by procedure SetSource', '27.0')]
    procedure SetAssemblyHeader(var CurrentAssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; CurrentReservEntry: Record "Reservation Entry")
    begin
        SourceRecRef.GetTable(CurrentAssemblyHeader);
        SetSource(SourceRecRef, CurrentReservEntry);
    end;
#endif
}

