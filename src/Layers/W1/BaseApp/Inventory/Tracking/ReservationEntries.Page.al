// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;

page 497 "Reservation Entries"
{
    Caption = 'Reservation Entries';
    DataCaptionExpression = Rec.TextCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
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
                    Editable = false;
                    ToolTip = 'Specifies the status of the reservation.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item that has been reserved in this entry.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the Location of the items that have been reserved in the entry.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Serial No.", Rec."Serial No.");
                    end;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the lot number of the item that is being handled with the associated document line.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Lot No.", Rec."Lot No.");
                    end;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the package number of the item that is being handled with the associated document line.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."Item No.", Rec."Variant Code", "Item Tracking Type"::"Package No.", Rec."Package No.");
                    end;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the reserved items are expected to enter inventory.';
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item that has been reserved in the entry.';

                    trigger OnValidate()
                    begin
                        ReservEngineMgt.ModifyReservEntry(xRec, Rec."Quantity (Base)", Rec.Description, false);
                        QuantityBaseOnAfterValidate();
                    end;
                }
                field("ReservEngineMgt.CreateForText(Rec)"; ReservEngineMgt.CreateForText(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved For';
                    Editable = false;
                    ToolTip = 'Specifies which line or entry the items are reserved for.';

                    trigger OnDrillDown()
                    begin
                        LookupReservedFor();
                    end;
                }
                field(ReservedFrom; ReservEngineMgt.CreateFromText(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved From';
                    Editable = false;
                    ToolTip = 'Specifies which line or entry the items are reserved from.';

                    trigger OnDrillDown()
                    begin
                        LookupReservedFrom();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies a description of the reservation entry.';
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies for which source type the reservation entry is related to.';
                    Visible = false;
                }
                field("Source Subtype"; Rec."Source Subtype")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which source subtype the reservation entry is related to.';
                    Visible = false;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which source ID the reservation entry is related to.';
                    Visible = false;
                }
                field("Source Batch Name"; Rec."Source Batch Name")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the journal batch name if the reservation entry is related to a journal or requisition line.';
                    Visible = false;
                }
                field("Source Ref. No."; Rec."Source Ref. No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies a reference number for the line, which the reservation entry is related to.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the entry was created.';
                    Visible = false;
                }
                field("Transferred from Entry No."; Rec."Transferred from Entry No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies a value when the order tracking entry is for the quantity that remains on a document line after a partial posting.';
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
                action(CancelReservation)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the selected reservation entry.';
                    Scope = Repeater;
                    trigger OnAction()
                    var
                        ReservEntry: Record "Reservation Entry";
                    begin
                        CurrPage.SetSelectionFilter(ReservEntry);
                        if ReservEntry.Find('-') then
                            repeat
                                ReservEntry.TestField("Reservation Status", Rec."Reservation Status"::Reservation);
                                ReservEntry.TestField("Disallow Cancellation", false);
                                OnCancelReservationOnBeforeConfirm(ReservEntry);
                                if Confirm(
                                     CancelReservationQst, false, ReservEntry."Quantity (Base)",
                                     ReservEntry."Item No.", ReservEngineMgt.CreateForText(Rec),
                                     ReservEngineMgt.CreateFromText(Rec))
                                then begin
                                    ReservEngineMgt.CancelReservation(ReservEntry);
                                    Commit();
                                end;
                            until ReservEntry.Next() = 0;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CancelReservation_Promoted; CancelReservation)
                {
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModifyRecord(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservEngineMgt.ModifyReservEntry(xRec, Rec."Quantity (Base)", Rec.Description, true);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        CancelReservationQst: Label 'Cancel reservation of %1 of item number %2, reserved for %3 from %4?', Comment = '%1 - quantity, %2 - item number, %3 - from table name, %4 - to table name';

    protected var
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";

    local procedure LookupReservedFor()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Get(Rec."Entry No.", false);
        LookupReserved(ReservationEntry);
    end;

    local procedure LookupReservedFrom()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Get(Rec."Entry No.", true);
        LookupReserved(ReservationEntry);
    end;

    procedure LookupReserved(ReservationEntry: Record "Reservation Entry")
    begin
        OnLookupReserved(ReservationEntry);

        OnAfterLookupReserved(ReservationEntry);
    end;

    protected procedure QuantityBaseOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupReserved(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModifyRecord(var ReservEntry: Record "Reservation Entry"; xReservEntry: Record "Reservation Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelReservationOnBeforeConfirm(var ReservEntry: Record "Reservation Entry")
    begin
    end;
}

