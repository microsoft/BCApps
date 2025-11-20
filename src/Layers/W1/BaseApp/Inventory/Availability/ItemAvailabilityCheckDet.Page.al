// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;

page 1873 "Item Availability Check Det."
{
    Caption = 'Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies a description of the item.';
            }
            field(GrossReq; GrossReq)
            {
                ApplicationArea = All;
                Caption = 'Gross Requirement';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies dependent demand plus independent demand. Dependent demand comes from production order components of all statuses, assembly order components, and planning lines. Independent demand comes from sales orders, transfer orders, service orders, project tasks, and demand forecasts.';
                Visible = GrossReq <> 0;
            }
            field(ReservedReq; ReservedReq)
            {
                ApplicationArea = Reservation;
                Caption = 'Reserved Requirement';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies reservation quantities on demand records.';
                Visible = ReservedReq <> 0;
            }
            field(SchedRcpt; SchedRcpt)
            {
                ApplicationArea = All;
                Caption = 'Scheduled Receipt';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies how many units of the assembly component are inbound on purchase orders, transfer orders, assembly orders, firm planned production orders, and released production orders.';
                Visible = SchedRcpt <> 0;
            }
            field(ReservedRcpt; ReservedRcpt)
            {
                ApplicationArea = Reservation;
                Caption = 'Reserved Receipt';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies reservation quantities on supply records.';
                Visible = ReservedRcpt <> 0;
            }
            field(CurrentQuantity; CurrentQuantity)
            {
                ApplicationArea = All;
                Caption = 'Current Quantity';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies the quantity on the document for which the availability is checked.';
                Visible = CurrentQuantity <> 0;
            }
            field(CurrentReservedQty; CurrentReservedQty)
            {
                ApplicationArea = Reservation;
                Caption = 'Current Reserved Quantity';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies the quantity of the item on the document that is currently reserved.';
                Visible = CurrentReservedQty <> 0;
            }
            field(EarliestAvailable; EarliestAvailDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Earliest Availability Date';
                Editable = false;
                ToolTip = 'Specifies the arrival date of an inbound supply that can cover the needed quantity on a date later than the due date. Note that if the inbound supply only covers parts of the needed quantity, it is not considered available and the field will not contain a date.';
            }
            field(SubsituteExists; Rec."Substitutes Exist")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies that a substitute exists for this item.';
            }
            field(UnitOfMeasureCode; UnitOfMeasureCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unit of Measure Code';
                Editable = false;
                Lookup = false;
                ToolTip = 'Specifies the unit of measure that the availability figures are shown in.';
            }
        }
    }

    actions
    {
    }

    var
        UnitOfMeasureCode: Code[20];
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        ReservedReq: Decimal;
        ReservedRcpt: Decimal;
        CurrentQuantity: Decimal;
        CurrentReservedQty: Decimal;
        EarliestAvailDate: Date;

    procedure SetUnitOfMeasureCode(Value: Code[20])
    begin
        UnitOfMeasureCode := Value;
    end;

    procedure SetGrossReq(Value: Decimal)
    begin
        GrossReq := Value;
    end;

    procedure SetReservedRcpt(Value: Decimal)
    begin
        ReservedRcpt := Value;
    end;

    procedure SetReservedReq(Value: Decimal)
    begin
        ReservedReq := Value;
    end;

    procedure SetSchedRcpt(Value: Decimal)
    begin
        SchedRcpt := Value;
    end;

    procedure SetCurrentQuantity(Value: Decimal)
    begin
        CurrentQuantity := Value;
    end;

    procedure SetCurrentReservedQty(Value: Decimal)
    begin
        CurrentReservedQty := Value;
    end;

    procedure SetEarliestAvailDate(Value: Date)
    begin
        EarliestAvailDate := Value;
    end;
}

