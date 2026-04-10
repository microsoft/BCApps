// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;

table 5531 "Inventory Page Data"
{
    Caption = 'Inventory Page Data';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the first date in the selected period where a supply or demand event occurs that changes the item''s availability figures.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Period Type"; Option)
        {
            Caption = 'Period Type';
            Editable = false;
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(4; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies on which date the period starts, such as the first day of March, if the period is Month.';
            Editable = false;
        }
        field(5; "Period End"; Date)
        {
            Caption = 'Period End';
            Editable = false;
        }
        field(6; "Period No."; Integer)
        {
            Caption = 'Period No.';
            Editable = false;
        }
        field(7; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(9; "Source Line ID"; RecordID)
        {
            Caption = 'Source Line ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location of the demand document, from which the Item Availability by Event window was opened.';
            Editable = false;
            TableRelation = Location;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the availability line.';
            Editable = false;
        }
        field(14; "Availability Date"; Date)
        {
            Caption = 'Availability Date';
            Editable = false;
        }
        field(15; Type; Enum "Inventory Page Data Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the source document or source line.';
            Editable = false;
        }
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the document that the availability figure is based on.';
            Editable = false;
        }
        field(19; Source; Text[100])
        {
            Caption = 'Source';
            ToolTip = 'Specifies which type of document or line the availability figure is based on.';
            Editable = false;
        }
        field(20; "Remaining Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(22; "Gross Requirement"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Gross Requirement';
            ToolTip = 'Specifies the item''s total demand.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "Scheduled Receipt"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Scheduled Receipt';
            ToolTip = 'Specifies the sum of items on existing supply orders.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(24; Forecast; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Forecast';
            ToolTip = 'Specifies the quantity that is demanded on the demand forecast that the availability figure is based on.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Remaining Forecast"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Remaining Forecast';
            ToolTip = 'Specifies the quantity that remains on the demand forecast, after the forecast quantity on the availability line has been consumed.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(26; "Action Message Qty."; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Action Message Qty.';
            ToolTip = 'Specifies the quantity that is suggested in the planning or requisition line that this availability figure is based on.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
            ToolTip = 'Specifies the action message of the planning or requisition line that this availability figure is based on.';
            Editable = false;
        }
        field(30; "Source Document ID"; RecordID)
        {
            Caption = 'Source Document ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(31; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
        }
        field(34; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            Editable = false;
        }
        field(36; "Projected Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Projected Inventory';
            ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(37; "Forecasted Projected Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Forecasted Projected Inventory';
            ToolTip = 'Specifies the item''s inventory, including anticipated demand from demand forecasts or blanket sales orders.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(38; "Suggested Projected Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Suggested Projected Inventory';
            ToolTip = 'Specifies the item''s inventory, including the suggested supplies that occur in planning or requisition worksheet lines.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(39; "Reserved Requirement"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Reserved Requirement';
            ToolTip = 'Specifies the quantity of the item that is reserved from requirement.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "Reserved Receipt"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Reserved Receipt';
            ToolTip = 'Specifies the quantity of the item that is reserved from receipt.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
        }
        key(Key2; "Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Period Start", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure UpdateInventorys(var RunningInventory: Decimal; var RunningInventoryForecast: Decimal; var RunningInventorySuggestion: Decimal)
    begin
        "Projected Inventory" :=
          RunningInventory +
          ("Gross Requirement" - "Reserved Requirement") + ("Scheduled Receipt" - "Reserved Receipt");
        "Forecasted Projected Inventory" :=
          RunningInventoryForecast + "Remaining Forecast" +
          ("Gross Requirement" - "Reserved Requirement") + ("Scheduled Receipt" - "Reserved Receipt");
        "Suggested Projected Inventory" :=
          RunningInventorySuggestion + "Action Message Qty." + "Remaining Forecast" +
          ("Gross Requirement" - "Reserved Requirement") + ("Scheduled Receipt" - "Reserved Receipt");

        OnUpdateInventorysOnAfterCalculatingInventorys(Rec);

        if Level = 1 then begin
            RunningInventory := "Projected Inventory";
            RunningInventoryForecast := "Forecasted Projected Inventory";
            RunningInventorySuggestion := "Suggested Projected Inventory"
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInventorysOnAfterCalculatingInventorys(var InventoryPageData: Record "Inventory Page Data")
    begin
    end;
}

