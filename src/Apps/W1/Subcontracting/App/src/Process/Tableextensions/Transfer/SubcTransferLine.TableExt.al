// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Document;

tableextension 99001517 "Subc. Transfer Line" extends "Transfer Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001530; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order.';
        }
        field(99001531; "Subcontr. PO Line No."; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related purchase order line.';
        }
        field(99001532; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ToolTip = 'Specifies the number of the related production order.';
        }
        field(99001533; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Prod. Order No."));
            ToolTip = 'Specifies the number of the related production order line.';
        }
        field(99001534; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Prod. Order Line No."));
            ToolTip = 'Specifies the line number of the related production order component line.';
        }
        field(99001535; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
            ToolTip = 'Specifies the number of the related production routing.';
        }
        field(99001536; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of the related production routing reference no.';
        }
        field(99001537; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
            ToolTip = 'Specifies the number of the related production work center.';
            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
            begin
                if "Work Center No." = '' then
                    exit;

                WorkCenter.Get("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
            end;
        }
        field(99001538; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));
            ToolTip = 'Specifies the number of the related production operation no.';
        }
        field(99001539; "Return Order"; Boolean)
        {
            Caption = 'Return Order';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this transfer line represents a WIP item transfer. When enabled, a WIP item transfer can be created.';

            trigger OnValidate()
            var
                Item: Record Item;
                UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
            begin
                if "Transfer WIP Item" then begin
                    CheckForExistingReservationsOrItemTracking();
                    "Qty. per Unit of Measure" := 0;
                end else begin
                    Item.SetLoadFields("Base Unit of Measure");
                    Item.Get(Rec."Item No.");
                    "Qty. per Unit of Measure" := UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                end;
                Validate(Quantity);
            end;
        }
        field(99001561; "Whse. Inbnd. Otsdg. Qty"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = sum("Warehouse Receipt Line"."Qty. Outstanding" where("Source Type" = const(5741),
                                                                                        "Source Subtype" = const("1"),
                                                                                        "Source No." = field("Document No."),
                                                                                        "Source Line No." = field("Line No.")));
            Caption = 'Whse. Inbnd. Otsdg. Qty';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001562; "Whse Outbnd. Otsdg. Qty"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding" where("Source Type" = const(5741),
                                                                                         "Source Subtype" = const("0"),
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No.")));
            Caption = 'Whse Outbnd. Otsdg. Qty';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001563; "Prev. Operation No."; Code[10])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Previous Operation No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));
            ToolTip = 'Specifies the number of the related previous production operation no.';
        }
    }
    keys
    {
        key(Key99001500; "Subcontr. Purch. Order No.", "Subcontr. PO Line No.", "Prod. Order No.", "Prod. Order Line No.", "Prod. Order Comp. Line No.") { }
        key(Key99001501; "Prod. Order No.", "Routing No.", "Routing Reference No.", "Operation No.", "Subcontr. Purch. Order No.") { }
        key(Key99001502; "Subcontr. Purch. Order No.", "Prod. Order No.", "Prod. Order Line No.", "Operation No.") { }
        key(Key99001503; "Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.") { }
        key(Key99001504; "Prod. Order No.", "Prod. Order Line No.", "Prod. Order Comp. Line No.", "Subcontr. Purch. Order No.", "Return Order") { }
    }

    internal procedure CheckForExistingReservationsOrItemTracking()
    var
        ReservationEntry: Record "Reservation Entry";
        ExistingReservationsErr: Label 'There are existing reservations for this transfer line. Please remove the reservations before changing the line to/from a WIP item transfer.';
        ExistingItemTrackingErr: Label 'There is existing item tracking for this transfer line. Please remove the item tracking before changing the line to/from a WIP item transfer.';
        ExistingReservationEntriesErr: Label 'There are existing reservation entries for this transfer line. Please remove the reservation entries before changing the line to/from a WIP item transfer.';
    begin
        Rec.SetReservationFilters(ReservationEntry, "Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Reservation Status", "Reservation Status"::Reservation);
        if not ReservationEntry.IsEmpty() then
            Error(ExistingReservationsErr);

        ReservationEntry.Reset();
        Rec.SetReservationFilters(ReservationEntry, "Transfer Direction"::Inbound);
        ReservationEntry.SetRange("Reservation Status", "Reservation Status"::Reservation);
        if not ReservationEntry.IsEmpty() then
            Error(ExistingReservationsErr);

        ReservationEntry.Reset();
        Rec.SetReservationFilters(ReservationEntry, "Transfer Direction"::Outbound);
        ReservationEntry.SetRange("Source Subtype");//Ignore Direction
        ReservationEntry.SetRange("Reservation Status", "Reservation Status"::Surplus);
        if not ReservationEntry.IsEmpty() then
            Error(ExistingItemTrackingErr);

        if Rec.ReservEntryExist() then
            Error(ExistingReservationEntriesErr);
    end;

    procedure CalcBaseQty(Quantity: Decimal) BaseQty: Decimal
    var
        Item: Record Item;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        QtyPerUoM: Decimal;
    begin
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get("Item No.");
        QtyPerUoM := UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        BaseQty := UnitOfMeasureManagement.CalcBaseQty(Quantity, QtyPerUoM);
    end;
}