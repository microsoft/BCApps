// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

page 504 "Available - Item Ledg. Entries"
{
    Caption = 'Available - Item Ledg. Entries';
    DataCaptionExpression = CaptionText;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Item Ledger Entry" = rm;
    SourceTable = "Item Ledger Entry";
    SourceTableView = sorting("Item No.", Open);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';
                    Visible = false;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a package number if the posted item carries such a number.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the line have been reserved.';
                }
                field(QtyToReserve; QtyToReserve)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available for reservation.';
                }
                field(ReservedQuantity; GetReservedQtyInLine())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved from the item ledger entry, for the current line or entry.';

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
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
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
                    var
                        NewQtyReserved2: Decimal;
                    begin
                        ReservEntry.LockTable();
                        UpdateReservMgt();
                        Rec.GetReservationQty(QtyReserved, QtyToReserve);
                        ReservMgt.CalculateRemainingQty(NewQtyReserved2, NewQtyReserved);
                        if MaxQtyDefined and (Abs(MaxQtyToReserve) < Abs(NewQtyReserved)) then
                            NewQtyReserved := MaxQtyToReserve;

                        ReservMgt.CopySign(NewQtyReserved, QtyToReserve);
                        if NewQtyReserved <> 0 then begin
                            OnBeforeCreateReservation(ReservEntry, Rec."Lot No.", Rec."Serial No.");
                            if Abs(NewQtyReserved) > Abs(QtyToReserve) then begin
                                CreateReservation(QtyToReserve);
                                MaxQtyToReserve := MaxQtyToReserve - QtyToReserve;
                            end else begin
                                CreateReservation(NewQtyReserved);
                                MaxQtyToReserve := MaxQtyToReserve - NewQtyReserved;
                            end;
                            if MaxQtyToReserve < 0 then
                                MaxQtyToReserve := 0;
                        end else
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

                        Rec.GetReservationQty(QtyReserved, QtyToReserve);

                        ReservEntry2.Copy(ReservEntry);
                        if ReservMgt.IsPositive() then
                            Rec.SetReservationFilters(ReservEntry2)
                        else
                            Error(CanCancelInventoryReservationOnlyErr);
                        ReservEntry2.SetRange("Expected Receipt Date");
                        if ReservEntry2.Find('-') then begin
                            UpdateReservMgt();
                            repeat
                                ReservEngineMgt.CancelReservation(ReservEntry2);
                            until ReservEntry2.Next() = 0;

                            TotalAvailQty := TotalAvailQty + QtyReserved;
                            MaxQtyToReserve := MaxQtyToReserve + QtyReserved;
                            UpdateReservFrom();
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Reserve_Promoted; Reserve)
                {
                }
                actionref(CancelReservation_Promoted; CancelReservation)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetReservationQty(QtyReserved, QtyToReserve);
    end;

    trigger OnOpenPage()
    begin
        ReservEntry.TestField("Source Type");

        SetFilters();
    end;

    var
        ReservEntry2: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        NewQtyReserved: Decimal;
        CaptionText: Text;
        FullyReservedErr: Label 'Fully reserved.';
        CancelReservationQst: Label 'Do you want to cancel the reservation?';
        ReservationCannotBeCarriedErr: Label 'Reservation cannot be carried out because the available quantity is already allocated in a warehouse.';
        CanCancelInventoryReservationOnlyErr: Label 'You can only cancel reservations to inventory.';
        CannotReserveFromSpecialOrderErr: Label 'You cannot reserve from this item ledger entry because the associated special sales order %1 has not been posted yet.', Comment = '%1: Sales Order No.';

    protected var
        ReservEntry: Record "Reservation Entry";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        QtyReserved: Decimal;
        TotalAvailQty: Decimal;
        MaxQtyToReserve: Decimal;
        MaxQtyDefined: Boolean;

    procedure SetSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry")
    var
        TransferDirection: Enum "Transfer Direction";
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
    end;

    procedure SetTotalAvailQty(TotalAvailQty2: Decimal)
    begin
        TotalAvailQty := TotalAvailQty2;
    end;

    procedure SetMaxQtyToReserve(NewMaxQtyToReserve: Decimal)
    begin
        MaxQtyToReserve := NewMaxQtyToReserve;
        MaxQtyDefined := true;
    end;

    local procedure CreateReservation(var ReserveQuantity: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        SpecialOrderSalesNo: Code[20];
    begin
        Rec.TestField("Drop Shipment", false);
        Rec.TestField("Item No.", ReservEntry."Item No.");
        Rec.TestField("Variant Code", ReservEntry."Variant Code");
        Rec.TestField("Location Code", ReservEntry."Location Code");
        SpecialOrderSalesNo := ReservMgt.FindUnfinishedSpecialOrderSalesNo(Rec);
        if SpecialOrderSalesNo <> '' then
            Error(CannotReserveFromSpecialOrderErr, SpecialOrderSalesNo);

        if TotalAvailQty < 0 then begin
            ReserveQuantity := 0;
            exit;
        end;

        if TotalAvailQty < ReserveQuantity then
            ReserveQuantity := TotalAvailQty;
        TotalAvailQty := TotalAvailQty - ReserveQuantity;

        if (TotalAvailQty = 0) and
           (ReserveQuantity = 0) and
           (QtyToReserve <> 0)
        then
            Error(ReservationCannotBeCarriedErr);

        UpdateReservMgt();
        TrackingSpecification.InitTrackingSpecification(
            DATABASE::"Item Ledger Entry", 0, '', '', 0, Rec."Entry No.",
            Rec."Variant Code", Rec."Location Code", Rec."Qty. per Unit of Measure");
        TrackingSpecification.CopyTrackingFromItemLedgEntry(Rec);
        ReservMgt.CreateReservation(
          ReservEntry.Description, 0D, 0, ReserveQuantity, TrackingSpecification);
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
        ReservMgt.SetTrackingFromReservEntry(ReservEntry);

        OnAfterUpdateReservMgt(ReservEntry);
    end;

    protected procedure GetReservedQtyInLine(): Decimal
    begin
        ReservEntry2.Reset();
        Rec.SetReservationFilters(ReservEntry2);
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Reservation);
        exit(ReservMgt.MarkReservConnection(ReservEntry2, ReservEntry));
    end;

    local procedure SetFilters()
    var
        ItemTrackingType: Enum "Item Tracking Type";
        FieldFilter: Text;
    begin
        Rec.Reset();
        Rec.SetRange("Item No.", ReservEntry."Item No.");
        Rec.SetRange("Variant Code", ReservEntry."Variant Code");
        Rec.SetRange("Location Code", ReservEntry."Location Code");
        Rec.SetRange("Drop Shipment", false);
        Rec.SetRange(Open, true);
        if ReservEntry.FieldFilterNeeded(FieldFilter, ReservMgt.IsPositive(), ItemTrackingType::"Lot No.") then
            Rec.SetFilter("Lot No.", FieldFilter);
        if ReservEntry.FieldFilterNeeded(FieldFilter, ReservMgt.IsPositive(), ItemTrackingType::"Serial No.") then
            Rec.SetFilter("Serial No.", FieldFilter);
        if ReservMgt.IsPositive() then begin
            Rec.SetRange(Positive, true);
            Rec.SetFilter("Remaining Quantity", '>0');
        end else begin
            Rec.SetRange(Positive, false);
            Rec.SetFilter("Remaining Quantity", '<0');
        end;

        OnAfterSetFilters(Rec, ReservEntry, ReservMgt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry: Record "Reservation Entry"; var ReservMgt: Codeunit "Reservation Management")
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(ReservationEntry: Record "Reservation Entry"; LotNo: Code[50]; SerialNo: Code[50])
    begin
    end;
}

