// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;

table 5530 "Inventory Event Buffer"
{
    Caption = 'Inventory Event Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
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
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Location;
        }
        field(14; "Availability Date"; Date)
        {
            Caption = 'Availability Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(15; Type; Enum "Inventory Event Buffer Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Remaining Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Remaining Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Transfer Direction"; Enum "Transfer Direction")
        {
            Caption = 'Transfer Direction';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(23; "Reserved Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reserved Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(31; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(32; "Forecast Type"; Option)
        {
            Caption = 'Forecast Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ',Sales,Component';
            OptionMembers = ,Sales,Component;
        }
        field(33; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(34; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(35; "Orig. Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Orig. Quantity (Base)';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(37; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Assembly,Transfer';
            OptionMembers = " ",Purchase,"Prod. Order",Assembly,Transfer;
        }
        field(38; "Ref. Order Line No."; Integer)
        {
            Caption = 'Ref. Order Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Availability Date", Type)
        {
        }
    }

    fieldgroups
    {
    }

    var
        RecRef: RecordRef;









    procedure TransferInventoryQty(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        Init();
        RecRef.GetTable(ItemLedgEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ItemLedgEntry."Item No.";
        "Variant Code" := ItemLedgEntry."Variant Code";
        "Location Code" := ItemLedgEntry."Location Code";
        "Availability Date" := 0D;
        Type := Type::Inventory;
        "Remaining Quantity (Base)" := ItemLedgEntry."Remaining Quantity";

        "Reserved Quantity (Base)" := CalcReservedQuantity(ItemLedgEntry);

        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferInventoryQty(Rec, ItemLedgEntry);
    end;






    procedure TransferFromForecast(ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean)
    begin
        TransferFromForecast(ProdForecastEntry, UnconsumedQtyBase, ForecastOnLocation, false);
    end;

    procedure TransferFromForecast(ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean; ForecastOnVariant: Boolean)
    var
        RecRef: RecordRef;
    begin
        Init();
        RecRef.GetTable(ProdForecastEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ProdForecastEntry."Item No.";
        "Variant Code" := '';
        if ForecastOnLocation then
            "Location Code" := ProdForecastEntry."Location Code"
        else
            "Location Code" := '';
        if ForecastOnVariant then
            "Variant Code" := ProdForecastEntry."Variant Code"
        else
            "Variant Code" := '';
        "Availability Date" := ProdForecastEntry."Forecast Date";
        Type := Type::Forecast;
        if ProdForecastEntry."Component Forecast" then
            "Forecast Type" := "Forecast Type"::Component
        else
            "Forecast Type" := "Forecast Type"::Sales;
        "Remaining Quantity (Base)" := -UnconsumedQtyBase;
        "Reserved Quantity (Base)" := 0;
        "Orig. Quantity (Base)" := -ProdForecastEntry."Forecast Quantity (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromForecast(Rec, ProdForecastEntry);
    end;


    procedure PlanRevertEntry(InvtEventBuf: Record "Inventory Event Buffer"; ParentActionMessage: Enum "Action Message Type")
    begin
        Rec := InvtEventBuf;
        Type := Type::"Plan Revert";
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := 0;
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ParentActionMessage;
        "Attached to Line No." := InvtEventBuf."Entry No.";
    end;



    procedure CalcReservedQuantity(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source ID", '');
        ReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
        ReservEntry.SetRange("Source Subtype", 0);
        ReservEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        ReservEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
        ReservEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.CalcSums("Quantity (Base)");
        exit(ReservEntry."Quantity (Base)");
    end;









    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryQty(var InventoryEventBuffer: Record "Inventory Event Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;






    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;



}
