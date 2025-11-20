// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using System.Utilities;

page 6503 "Avail. - Item Tracking Lines"
{
    Caption = 'Avail. - Item Tracking Lines';
    DataCaptionExpression = CaptionText;
    DataCaptionFields = "Lot No.", "Serial No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Reservation Entry" = rm;
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reservation Status"; Rec."Reservation Status")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the status of the reservation.';
                    Visible = false;
                }
                field(TextCaption; Rec.TextCaption())
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the type of document.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies for which source type the reservation entry is related to.';
                    Visible = false;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies which source ID the reservation entry is related to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the Location of the items that have been reserved in the entry.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number of the item that is being handled with the associated document line.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the package number of the item that is being handled with the associated document line.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the date on which the reserved items are expected to enter inventory.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item that has been reserved in the entry.';
                }
                field(ReservedQtyBase; GetReservedQtyBase())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Qty. (Base)';
                    Editable = false;
                    ToolTip = 'Specifies the quantity that has been reserved for the item.';
                }
                field(QtyToReserve; QtyToReserve)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Available Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is available for reservation.';
                }
                field(ReservedThisLine; GetReservedQty())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is reserved for the document type.';
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
            group(FunctionButton2)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionButton2Visible;
                action("&Show Document")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        ReservMgt.LookupDocument(
                            Rec."Source Type", Rec."Source Subtype", Rec."Source ID",
                            Rec."Source Batch Name", Rec."Source Prod. Order Line", Rec."Source Ref. No.");
                    end;
                }
            }
            group(FunctionButton1)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = FunctionButton1Visible;
                action("&Cancel Reservation")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = '&Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the reservation that exists for the document line that you opened this window for.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not EnableReservations then
                            exit;
                        if not ConfirmManagement.GetResponseOrDefault(CancelReservationQst, true) then
                            exit;
                        ReservEngineMgt.CancelReservation(Rec);
                        UpdateReservFrom();
                    end;
                }
                action(Action36)
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        ReservMgt.LookupDocument(
                            Rec."Source Type", Rec."Source Subtype", Rec."Source ID",
                            Rec."Source Batch Name", Rec."Source Prod. Order Line", Rec."Source Ref. No.");
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        FunctionButton2Visible := true;
        FunctionButton1Visible := true;
    end;

    trigger OnOpenPage()
    begin
        FunctionButton1Visible := EnableReservations;
        FunctionButton2Visible := not EnableReservations;
    end;

    var
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
        QtyToReserve: Decimal;
        CaptionText: Text;
        EnableReservations: Boolean;
        FunctionButton1Visible: Boolean;
        FunctionButton2Visible: Boolean;

        CancelReservationQst: Label 'Cancel reservation?';

    procedure SetReservSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry")
    var
        TransferDirection: Enum "Transfer Direction";
    begin
        SetReservSource(CurrentSourceRecRef, CurrentReservEntry, TransferDirection::Outbound);
    end;

    procedure SetReservSource(CurrentSourceRecRef: RecordRef; CurrentReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
    begin
        Clear(ReservMgt);

        SourceRecRef := CurrentSourceRecRef;
        ReservEntry := CurrentReservEntry;

        ReservMgt.TestItemType(SourceRecRef);
        ReservMgt.SetReservSource(SourceRecRef, Direction);
        CaptionText := ReservMgt.FilterReservFor(SourceRecRef, ReservEntry, Direction);
    end;

    procedure SetItemTrackingLine(LookupType: Integer; LookupSubtype: Integer; CurrentReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; AvailabilityDate: Date)
    begin
        ReservMgt.SetMatchFilter(CurrentReservEntry, Rec, SearchForSupply, AvailabilityDate);
        Rec.SetRange("Source Type", LookupType);
        Rec.SetRange("Source Subtype", LookupSubtype);
        EnableReservations := true;
    end;

    local procedure UpdateReservFrom()
    begin
        SetReservSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());

        OnAfterUpdateReservFrom(ReservEntry);
    end;

    local procedure GetReservedQty(): Decimal
    begin
        // This procedure is intentionally left blank.
    end;

    local procedure GetReservedQtyBase(): Decimal
    begin
        // This procedure is intentionally left blank.
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateReservFrom(var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}

