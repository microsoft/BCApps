// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;

table 99000880 "Order Promising Line"
{
    Caption = 'Order Promising Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number of the item that is on the promised order.';
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(13; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units, calculated by subtracting the reserved quantity from the outstanding quantity in the Sales Line table.';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(15; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Unavailable Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unavailable Quantity';
            ToolTip = 'Specifies the quantity of items that are not available for the requested delivery date on the order.';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unavailable Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unavailable Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Required Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Required Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(20; "Source Type"; Enum "Order Promising Line Source Type")
        {
            Caption = 'Source Type';
        }
        field(21; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
        }
        field(22; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(23; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the entry.';
        }
        field(31; "Required Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Required Quantity';
            ToolTip = 'Specifies the quantity required for order promising lines.';
            DecimalPlaces = 0 : 5;
        }
        field(40; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the requested delivery date for the entry.';

            trigger OnValidate()
            begin
                OnValidateRequestedDeliveryDate(Rec);
            end;
        }
        field(41; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';

            trigger OnValidate()
            begin
                if "Planned Delivery Date" <> 0D then
                    OnValidatePlannedDeliveryDate(Rec);
            end;
        }
        field(42; "Original Shipment Date"; Date)
        {
            Caption = 'Original Shipment Date';
            ToolTip = 'Specifies the shipment date of the entry.';
        }
        field(43; "Earliest Shipment Date"; Date)
        {
            Caption = 'Earliest Shipment Date';
            ToolTip = 'Specifies the Capable to Promise function as the earliest possible shipment date for the item.';

            trigger OnValidate()
            begin
                OnValidateEarliestDeliveryDate(Rec);
            end;
        }
        field(44; "Requested Shipment Date"; Date)
        {
            Caption = 'Requested Shipment Date';
            ToolTip = 'Specifies the delivery date that the customer requested, minus the shipping time.';
            Editable = false;
        }
        field(45; "Unavailability Date"; Date)
        {
            Caption = 'Unavailability Date';
            ToolTip = 'Specifies the date when the order promising line is no longer available.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Requested Shipment Date")
        {
        }
    }

    fieldgroups
    {
    }




    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CalcAvailability(): Decimal
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Enum "Analysis Period Type";
        AvailabilityDate: Date;
    begin
        if Item.Get("Item No.") then begin
            if "Original Shipment Date" > 0D then
                AvailabilityDate := "Original Shipment Date"
            else
                AvailabilityDate := WorkDate();

            Item.Reset();
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", "Variant Code");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Drop Shipment Filter", false);
            exit(
              AvailableToPromise.CalcQtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePlannedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEarliestDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;



}
