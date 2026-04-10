// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

table 5774 "Warehouse Pick Summary"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    Access = Internal;
    Caption = 'Warehouse Pick Summary';
    DataCaptionFields = "Source Document", "Source No.", "Item No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            ToolTip = 'Specifies the type of source document to which the warehouse activity line relates, such as sales, purchase, and production.';
            Editable = false;
        }
        field(3; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
            Editable = false;
        }
        field(5; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            ToolTip = 'Specifies the line number of the source document';
            Editable = false;
        }
        field(6; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            ToolTip = 'Specifies the subline number of the source document';
            Editable = false;
        }
        field(7; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
            Editable = false;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code for the location where the pick activity occurs.';
            Editable = false;
            TableRelation = Location;
        }
        field(12; "Bin Code"; Code[20])
        {
            Editable = false;
            TableRelation = Bin.Code;
            ValidateTableRelation = false;
        }
        field(14; "Item No."; Code[20])
        {
            ToolTip = 'Specifies the item number of the item to be picked.';
            Editable = false;
            TableRelation = Item."No.";
        }
        field(15; "Variant Code"; Code[10])
        {
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            ValidateTableRelation = false;
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
            ValidateTableRelation = false;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(26; "Qty. to Handle"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Handle';
            ToolTip = 'Specifies how many units to handle in this warehouse activity.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(27; "Qty. to Handle (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(28; "Qty. Handled"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Handled';
            ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Qty. Handled (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "Qty. in Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Inventory';
            ToolTip = 'Specifies the quantity in the inventory.';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No."),
                                                                  "Location Code" = field("Location Code"),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Code")));

        }
        field(41; "Qty. Available to Pick"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Available to Pick';
            ToolTip = 'Specifies the quantity that is actually available to pick.';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Potential Pickable Qty."; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Potential Qty. Available to Pick';
            ToolTip = 'Specifies the maximum quantity that can be considered for picking. This quantity consists of items in pickable bins excluding bins that are blocked, dedicated, blocked by item tracking or items that are being picked. This quantity cannot be more than the total quantity in the warehouse including adjustment bins.';
            DecimalPlaces = 0 : 5;
        }
        field(43; "Available Qty. Not in Ship Bin"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Available Quantity Excluding Ship Bin';
            ToolTip = 'Specifies the quantity available to pick in the warehouse excluding the shipment bins, bins that are blocked, dedicated, blocked by item tracking or items that are being picked.';
            DecimalPlaces = 0 : 5;
        }
        field(44; "Qty. Assigned"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Assigned';
            ToolTip = 'Specifies the quantity that has been handled for other source lines. If tracking is enabled, then the same source line is also included. The quantity consists of the current execution of create warehouse pick action.';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Qty. Reserved in Warehouse"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Reserved in Warehouse';
            ToolTip = 'Specifies the quantity reserved in warehouse. This quantity consists of inventory from reservation including inventory that is picked or being picked but not yet shipped or consumed. It excludes the quantity blocked by bins, item tracking or reserved against dedicated bins.';
            DecimalPlaces = 0 : 5;
        }
        field(51; "Qty. Res. in Pick/Ship Bins"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Reserved in Pick/Ship Bins';
            ToolTip = 'Specifies the quantity reserved in pick/ship bins.';
            DecimalPlaces = 0 : 5;
        }
        field(52; "Qty. Reserved for this Line"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Reserved for this Line';
            ToolTip = 'Specifies the quantity reserved for the selected line.';
            DecimalPlaces = 0 : 5;
        }
        field(60; "Qty. in Blocked Item Tracking"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Blocked Item Tracking';
            ToolTip = 'Specifies the quantity in blocked item tracking for the pickable/takeable bins.';
            DecimalPlaces = 0 : 5;
        }
        field(61; "Qty. in Active Pick Lines"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Active Pick Lines';
            ToolTip = 'Specifies the quantity assigned in active warehouse pick documents.';
            DecimalPlaces = 0 : 5;
        }
        field(62; "Qty. in Pickable Bins"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Pickable Bins';
            ToolTip = 'Specifies the quantity in takeable bins. The quantity is not reduced by item tracking.';
            DecimalPlaces = 0 : 5;
        }
        field(63; "Qty. in Warehouse"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Warehouse';
            ToolTip = 'Specifies the quantity in warehouse.';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Qty. Block. Item Tracking Res."; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Blocked Item Tracking for Checking Reservation';
            ToolTip = 'Specifies the quantity in blocked item tracking for the quantity reserved in warehouse.';
            DecimalPlaces = 0 : 5;
        }
        field(71; "Qty. in Active Pick Lines Res."; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. in Active Pick Lines for Checking Reservation';
            ToolTip = 'Specifies the quantity assigned in active warehouse pick documents.';
            DecimalPlaces = 0 : 5;
        }
        field(72; "Qty. Not in Ship Bin"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
            Caption = 'Qty. Not in Ship Bins for Checking Reservation';
            DecimalPlaces = 0 : 5;
        }
        field(80; ActiveWhseWorksheetLine; Guid)
        {
            Caption = 'Active Worksheet Line';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure IncrementEntryNumber()
    var
        TempWarehousePickSummary: Record "Warehouse Pick Summary" temporary;
    begin
        TempWarehousePickSummary.Copy(Rec, true);
        if TempWarehousePickSummary.FindLast() then
            Rec."Entry No." := TempWarehousePickSummary."Entry No." + 1;
    end;

    internal procedure ShowBinContents(BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins)
    var
        BinContent: Record "Bin Content";
        CreatePick: Codeunit "Create Pick";
        BinContentsPage: Page "Bin Contents";
    begin
        BinContent.SetRange("Item No.", Rec."Item No.");
        BinContent.SetRange("Variant Code", Rec."Variant Code");
        BinContent.SetRange("Location Code", Rec."Location Code");
        BinContent.SetRange("Block Movement", BinContent."Block Movement"::" ", BinContent."Block Movement"::Inbound);
        BinContent.SetRange(Dedicated, false);
        case BinTypeFilter of
            BinTypeFilter::ExcludeReceive:
                BinContent.SetFilter("Bin Type Code", '<>%1', CreatePick.GetBinTypeFilter(0));
            BinTypeFilter::ExcludeShip:
                BinContent.SetFilter("Bin Type Code", '<>%1', CreatePick.GetBinTypeFilter(1));
            BinTypeFilter::OnlyPickBins:
                BinContent.SetFilter("Bin Type Code", CreatePick.GetBinTypeFilter(3));
        end;
        BinContentsPage.SetTableView(BinContent);
        BinContentsPage.RunModal();
    end;

    internal procedure SetQtyToHandleStyle(): Text
    begin
        if Rec."Qty. to Handle (Base)" <> 0 then
            case true of
                Rec."Qty. to Handle (Base)" = Rec."Qty. Handled (Base)":
                    exit('favorable');
                Rec."Qty. Handled (Base)" = 0:
                    exit('unfavorable');
                Rec."Qty. to Handle (Base)" > Rec."Qty. Handled (Base)":
                    exit('attention');
            end
        else
            exit('unfavorable');
    end;

    internal procedure ShowPickWorksheet(WhseWorksheetLine: Record "Whse. Worksheet Line"; FilterToLine: Boolean)
    var
        PickWorksheetPage: Page "Pick Worksheet";
    begin
        if FilterToLine then
            WhseWorksheetLine.SetRecFilter()
        else begin
            WhseWorksheetLine.SetRecFilter();
            WhseWorksheetLine.SetRange("Line No."); //Remove the filter on Line No.
        end;

        PickWorksheetPage.SetTableView(WhseWorksheetLine);
        PickWorksheetPage.DrillDownFromCalculationSummary(WhseWorksheetLine);
        PickWorksheetPage.RunModal();
    end;

    internal procedure ShowReservationEntries()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservationEntry);
        Page.RunModal(Page::"Reservation Entries", ReservationEntry);
    end;

    local procedure SetReservationFilters(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("Source Type", Database::"Item Ledger Entry");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetRange("Reservation Status", Enum::"Reservation Status"::Reservation);
        ReservationEntry.SetRange("Location Code", Rec."Location Code");
        ReservationEntry.SetRange("Item No.", Rec."Item No.");
        ReservationEntry.SetRange("Variant Code", Rec."Variant Code");
    end;
}
