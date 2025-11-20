// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

table 99000853 "Inventory Profile"
{
    Caption = 'Inventory Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Attribute Priority"; Integer)
        {
            Caption = 'Attribute Priority';
        }
        field(5; "Order Priority"; Integer)
        {
            Caption = 'Order Priority';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(14; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(15; IsSupply; Boolean)
        {
            Caption = 'IsSupply';
        }
        field(16; "Order Relation"; Option)
        {
            Caption = 'Order Relation';
            OptionCaption = 'Normal,Safety Stock,Reorder Point';
            OptionMembers = Normal,"Safety Stock","Reorder Point";
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(22; "Source Order Status"; Integer)
        {
            Caption = 'Source Order Status';
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(24; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(26; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(27; "Primary Order Status"; Integer)
        {
            Caption = 'Primary Order Status';
        }
        field(28; "Primary Order No."; Code[20])
        {
            Caption = 'Primary Order No.';
        }
        field(29; "Primary Order Line"; Integer)
        {
            Caption = 'Primary Order Line';
        }
        field(30; "Primary Order Type"; Integer)
        {
            Caption = 'Primary Order Type';
        }
        field(31; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(33; "Untracked Quantity"; Decimal)
        {
            Caption = 'Untracked Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(34; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
        }
        field(35; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(36; "Planning Flexibility"; Enum "Inventory Planning Flexibility")
        {
            Caption = 'Planning Flexibility';
        }
        field(37; "Fixed Date"; Date)
        {
            Caption = 'Fixed Date';
        }
        field(38; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
        }
        field(39; Binding; Enum "Reservation Binding")
        {
            Caption = 'Binding';
            Editable = false;
        }
        field(40; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(41; "Min. Quantity"; Decimal)
        {
            Caption = 'Min. Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(43; "Planning Line No."; Integer)
        {
            Caption = 'Planning Line No.';
        }
        field(44; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(45; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(46; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(47; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(51; "Planning Line Phase"; Option)
        {
            Caption = 'Planning Line Phase';
            OptionCaption = ' ,Line Created,Routing Created,Exploded';
            OptionMembers = " ","Line Created","Routing Created",Exploded;
        }
        field(52; "Due Time"; Time)
        {
            Caption = 'Due Time';
        }
        field(53; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(54; "Drop Shipment"; Boolean)
        {
            Caption = 'Drop Shipment';
        }
        field(55; "Special Order"; Boolean)
        {
            Caption = 'Special Order';
        }
        field(56; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            Editable = false;
        }
        field(57; "Ref. Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ref. Line No.';
            Editable = false;
        }
        field(58; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
        }
        field(59; "Ref. Blanket Order No."; Code[20])
        {
            Caption = 'Ref. Blanket Order No.';
        }
        field(60; "Tracking Reference"; Integer)
        {
            Caption = 'Tracking Reference';
        }
        field(61; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(62; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(63; "Max. Quantity"; Decimal)
        {
            Caption = 'Max. Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(64; "Safety Stock Quantity"; Decimal)
        {
            Caption = 'Safety Stock Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(65; "Is Exception Order"; Boolean)
        {
            Caption = 'Is Exception Order';
        }
        field(66; "Transfer Location Not Planned"; Boolean)
        {
            Caption = 'Transfer Location Not Planned';
        }
        field(67; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(68; "Ref. Order Type"; Enum "Requisition Ref. Order Type")
        {
            Caption = 'Ref. Order Type';
            Editable = false;
        }
        field(69; "Disallow Cancellation"; Boolean)
        {
            Caption = 'Disallow Cancellation';
        }
        field(70; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority")
        {
        }
        key(Key3; "Item No.", "Variant Code", "Location Code", IsSupply, "Primary Order Status", "Primary Order No.", "Due Date", "Order Priority")
        {
        }
        key(Key4; "Source Type", "Source Order Status", "Source ID", "Source Batch Name", "Source Ref. No.", "Source Prod. Order Line", IsSupply, "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";

#pragma warning disable AA0470
        IncorrectSourceTypeErr: Label 'Tab99000853, TransferToTrackingEntry: Illegal Source Type: %1.';
#pragma warning restore AA0470

    procedure TransferFromItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        "Source Type" := Database::"Item Ledger Entry";
        "Source Ref. No." := ItemLedgerEntry."Entry No.";
        "Item No." := ItemLedgerEntry."Item No.";
        "Variant Code" := ItemLedgerEntry."Variant Code";
        "Location Code" := ItemLedgerEntry."Location Code";
        Quantity := ItemLedgerEntry.Quantity;
        "Remaining Quantity" := ItemLedgerEntry."Remaining Quantity";
        "Finished Quantity" := Quantity - "Remaining Quantity";
        "Quantity (Base)" := ItemLedgerEntry.Quantity;
        "Remaining Quantity (Base)" := ItemLedgerEntry."Remaining Quantity";
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        ItemLedgerEntry.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := ItemLedgerEntry."Remaining Quantity" - ItemLedgerEntry."Reserved Quantity" + AutoReservedQty;
        "Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
        "Qty. per Unit of Measure" := 1;
        IsSupply := ItemLedgerEntry.Positive;
        "Due Date" := ItemLedgerEntry."Posting Date";
        CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        if TrackingExists() then
            "Tracking Reference" := "Line No.";
        "Planning Flexibility" := "Planning Flexibility"::None;

        OnAfterTransferFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromSalesLine in codeunit Sales Line-Invt. Profile', '25.0')]
    procedure TransferFromSalesLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        SalesLineInvtProfile: Codeunit Microsoft.Sales.Document."Sales Line Invt. Profile";
    begin
        SalesLineInvtProfile.TransferInventoryProfileFromSalesLine(Rec, SalesLine, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromProdOrderComp in codeunit Prod. Order Comp.-Invt. Profile', '25.0')]
    procedure TransferFromComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ProdOrderCompInvtProfile: Codeunit Microsoft.Manufacturing.Document."Prod. Order Comp. Invt.Profile";
    begin
        ProdOrderCompInvtProfile.TransferInventoryProfileFromProdOrderComponent(Rec, ProdOrderComponent, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromPlanComponent in codeunit Plng. Component-Invt. Profile', '25.0')]
    procedure TransferFromPlanComponent(var PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        PlngComponentInvtProfile: Codeunit Microsoft.Inventory.Planning."Plng. Component Invt. Profile";
    begin
        PlngComponentInvtProfile.TransferInventoryProfileFromPlanComponent(Rec, PlanningComponent, TrackingReservationEntry);
    end;
#endif

    procedure CalcReservedQty(var ReservationEntry: Record "Reservation Entry"; var ReservedQty: Decimal)
    var
        OppositeReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange(Binding, ReservationEntry.Binding::"Order-to-Order");
        IsHandled := false;
        OnCalcReservedQtyOnBeforeReservationEntryLoop(ReservationEntry, ReservedQty, IsHandled);
        if not IsHandled then
            if ReservationEntry.Find('-') then begin
                // Retrieving information about primary order:
                if ReservationEntry.Positive then
                    OppositeReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive)
                else
                    OppositeReservationEntry := ReservationEntry;
                if "Primary Order No." = '' then begin
                    "Primary Order Type" := OppositeReservationEntry."Source Type";
                    "Primary Order Status" := OppositeReservationEntry."Source Subtype";
                    "Primary Order No." := OppositeReservationEntry."Source ID";
                    if OppositeReservationEntry."Source Type" = 5407 then // Database::"Prod. Order Component"
                        "Primary Order Line" := OppositeReservationEntry."Source Prod. Order Line";
                end;

                Binding := ReservationEntry.Binding;
                repeat
                    ReservedQty := ReservedQty + ReservationEntry."Quantity (Base)";
                until ReservationEntry.Next() = 0;
            end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromPurchaseLine in codeunit Purch. Line-Invt. Profile', '25.0')]
    procedure TransferFromPurchaseLine(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        PurchaseLineInvtProfile: Codeunit Microsoft.Purchases.Document."Purchase Line Invt. Profile";
    begin
        PurchaseLineInvtProfile.TransferInventoryProfileFromPurchaseLine(Rec, PurchaseLine, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromProdOrderLine in codeunit Prod. Order Line Reserve', '25.0')]
    procedure TransferFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ProdOrderLineReserve: Codeunit Microsoft.Manufacturing.Document."Prod. Order Line-Reserve";
    begin
        ProdOrderLineReserve.TransferInventoryProfileFromProdOrderLine(Rec, ProdOrderLine, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromAssemblyLine in codeunit Assembly Line Invt. Profile', '25.0')]
    procedure TransferFromAsmLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        AssemblyLineInvtProfile: Codeunit Microsoft.Assembly.Document."Assembly Line Invt. Profile";
    begin
        AssemblyLineInvtProfile.TransferInventoryProfileFromAsmLine(Rec, AssemblyLine, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromAssemblyHeader in codeunit Assembly Header Invt. Profile', '25.0')]
    procedure TransferFromAsmHeader(var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        AssemblyHeaderInvtProfile: Codeunit Microsoft.Assembly.Document."Assembly Header Invt. Profile";
    begin
        AssemblyHeaderInvtProfile.TransferInventoryProfileFromAssemblyHeader(Rec, AssemblyHeader, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromRequisitionLine in codeunit Req. Line-Reserve', '25.0')]
    procedure TransferFromRequisitionLine(var RequisitionLine: Record "Requisition Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReqLineReserve: Codeunit "Req. Line-Reserve";
    begin
        ReqLineReserve.TransferInventoryProfileFromRequisitionLine(Rec, RequisitionLine, TrackingReservationEntry);
    end;
#endif

    procedure TransferFromOutboundTransfPlan(var RequisitionLine: Record "Requisition Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        RequisitionLine.TestField(Type, RequisitionLine.Type::Item);
        SetSource(
          Database::"Requisition Line", 1, RequisitionLine."Worksheet Template Name", RequisitionLine."Line No.",
          RequisitionLine."Journal Batch Name", 0);
        "Item No." := RequisitionLine."No.";
        "Variant Code" := RequisitionLine."Variant Code";
        "Location Code" := RequisitionLine."Transfer-from Code";
        "Bin Code" := RequisitionLine."Bin Code";
        RequisitionLine.CalcFields("Reserved Qty. (Base)");
        RequisitionLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        "Untracked Quantity" := RequisitionLine."Quantity (Base)" - RequisitionLine."Reserved Qty. (Base)" + AutoReservedQty;
        "Min. Quantity" := RequisitionLine."Reserved Qty. (Base)" - AutoReservedQty;
        Quantity := RequisitionLine.Quantity;
        "Finished Quantity" := 0;
        "Remaining Quantity" := RequisitionLine.Quantity;
        "Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Remaining Quantity (Base)" := RequisitionLine."Quantity (Base)";
        "Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" <= 0;
        "Due Date" := RequisitionLine."Transfer Shipment Date";

        OnAfterTransferFromOutboundTransfPlan(Rec, RequisitionLine);
    end;

    procedure TransferFromOutboundTransfer(var TransferLine: Record "Transfer Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        CurrentInventoryProfile: Record "Inventory Profile";
        TransferDirection: Enum "Transfer Direction";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", '', 0);
        "Item No." := TransferLine."Item No.";
        "Variant Code" := TransferLine."Variant Code";
        "Location Code" := TransferLine."Transfer-from Code";

        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Outbound);
        AutoReservedQty := -TransferBindings(ReservationEntry, TrackingReservationEntry);
        MinQtyOutbnd := TransferLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;

        CurrentInventoryProfile := Rec;
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Inbound);
        AutoReservedQty := TransferBindings(ReservationEntry, TempReservationEntry);
        MinQtyInbnd := TransferLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;
        Rec := CurrentInventoryProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransferLine."Outstanding Qty. (Base)" - MinQtyOutbnd;
        Quantity := TransferLine.Quantity;
        "Remaining Quantity" := TransferLine."Outstanding Quantity";
        "Finished Quantity" := TransferLine."Quantity Shipped";
        "Quantity (Base)" := TransferLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransferLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransferLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransferLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" < 0;
        "Due Date" := TransferLine."Shipment Date";
        "Planning Flexibility" := TransferLine."Planning Flexibility";

        OnAfterTransferFromOutboundTransfer(Rec, TransferLine);
    end;

    procedure TransferFromInboundTransfer(var TransferLine: Record "Transfer Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        CurrentInventoryProfile: Record "Inventory Profile";
        TransferDirection: Enum "Transfer Direction";
        AutoReservedQty: Decimal;
        MinQtyInbnd: Decimal;
        MinQtyOutbnd: Decimal;
    begin
        SetSource(Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", '', TransferLine."Derived From Line No.");
        "Item No." := TransferLine."Item No.";
        "Variant Code" := TransferLine."Variant Code";
        "Location Code" := TransferLine."Transfer-to Code";

        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Inbound);
        AutoReservedQty := TransferBindings(ReservationEntry, TrackingReservationEntry);
        MinQtyInbnd := TransferLine."Reserved Qty. Inbnd. (Base)" - AutoReservedQty;

        CurrentInventoryProfile := Rec;
        TransferLine.SetReservationFilters(ReservationEntry, TransferDirection::Outbound);
        AutoReservedQty := -TransferBindings(ReservationEntry, TempReservationEntry);
        MinQtyOutbnd := TransferLine."Reserved Qty. Outbnd. (Base)" - AutoReservedQty;
        Rec := CurrentInventoryProfile;

        if MinQtyInbnd > MinQtyOutbnd then
            "Min. Quantity" := MinQtyInbnd
        else
            "Min. Quantity" := MinQtyOutbnd;

        "Untracked Quantity" := TransferLine."Outstanding Qty. (Base)" - MinQtyInbnd;
        Quantity := TransferLine.Quantity;
        "Remaining Quantity" := TransferLine."Outstanding Quantity";
        "Finished Quantity" := TransferLine."Quantity Received";
        "Quantity (Base)" := TransferLine."Quantity (Base)";
        "Remaining Quantity (Base)" := TransferLine."Outstanding Qty. (Base)";
        "Unit of Measure Code" := TransferLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := TransferLine."Qty. per Unit of Measure";
        IsSupply := "Untracked Quantity" >= 0;
        "Starting Date" := TransferLine."Shipment Date";
        "Due Date" := TransferLine."Receipt Date";
        "Planning Flexibility" := TransferLine."Planning Flexibility";

        OnAfterTransferFromInboundTransfer(Rec, TransferLine);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromServLine in codeunit Service Line Invt. Profile', '25.0')]
    procedure TransferFromServLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ServiceLineInvtProfile: Codeunit Microsoft.Service.Document."Service Line Invt. Profile";
    begin
        ServiceLineInvtProfile.TransferInventoryProfileFromServLine(Rec, ServiceLine, TrackingReservationEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferInventoryProfileFromJobPlanningLine in codeunit Job Planning Invt. Profile', '25.0')]
    procedure TransferFromJobPlanningLine(var JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        JobPlanningInvtProfile: Codeunit Microsoft.Projects.Project.Planning."Job Planning Invt. Profile";
    begin
        JobPlanningInvtProfile.TransferInventoryProfileFromJobPlanningLine(Rec, JobPlanningLine, TrackingReservationEntry);
    end;
#endif

    procedure TransferBindings(var ReservationEntry: Record "Reservation Entry"; var TrackingReservationEntry: Record "Reservation Entry"): Decimal
    var
        OppositeReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
        Found: Boolean;
        InsertTracking: Boolean;
        IsHandled: Boolean;
        Result: Decimal;
    begin
        IsHandled := false;
        OnBeforeTransferBindings(ReservationEntry, TrackingReservationEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line",
          "Reservation Status");
        if ReservationEntry.FindSet() then
            repeat
                InsertTracking := not
                  ((ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) and
                   (ReservationEntry.Binding = ReservationEntry.Binding::" "));
                if InsertTracking and ReservationEntry.TrackingExists() and
                   (ReservationEntry."Source Type" <> Database::"Item Ledger Entry")
                then begin
                    TrackingReservationEntry := ReservationEntry;
                    TrackingReservationEntry.Insert();
                end;
                if (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) or
                    (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Tracking)
                then
                    if (ReservationEntry.Binding = ReservationEntry.Binding::"Order-to-Order")
                    then begin
                        if ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation then
                            AutoReservedQty := AutoReservedQty + ReservationEntry."Quantity (Base)";
                        if not Found then begin
                            if ReservationEntry.Positive then
                                OppositeReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive)
                            else
                                OppositeReservationEntry := ReservationEntry;
                            if "Primary Order No." = '' then begin
                                "Primary Order Type" := OppositeReservationEntry."Source Type";
                                "Primary Order Status" := OppositeReservationEntry."Source Subtype";
                                "Primary Order No." := OppositeReservationEntry."Source ID";
                                if OppositeReservationEntry."Source Type" <> 5407 then // Database::"Prod. Order Component"
                                    "Primary Order Line" := OppositeReservationEntry."Source Ref. No."
                                else
                                    "Primary Order Line" := OppositeReservationEntry."Source Prod. Order Line";
                            end;
                            OnTransferBindingsOnAfterAssignPrimaryOrderInfo(Rec, OppositeReservationEntry);
                            Binding := ReservationEntry.Binding;
                            "Disallow Cancellation" := ReservationEntry."Disallow Cancellation";
                            Found := true;
                        end;
                    end else
                        if (ReservationEntry."Reservation Status" = ReservationEntry."Reservation Status"::Reservation) and
                           (("Fixed Date" = 0D) or ("Fixed Date" > ReservationEntry."Shipment Date"))
                        then
                            "Fixed Date" := ReservationEntry."Shipment Date";
            until ReservationEntry.Next() = 0;
        exit(AutoReservedQty);
    end;

    procedure TransferQtyFromItemTrgkEntry(var TrackingReservationEntry: Record "Reservation Entry")
    begin
        "Original Quantity" := 0;
        Quantity := TrackingReservationEntry.Quantity;
        "Quantity (Base)" := TrackingReservationEntry."Quantity (Base)";
        "Finished Quantity" := 0;
        "Min. Quantity" := 0;
        "Remaining Quantity" := TrackingReservationEntry.Quantity;
        "Remaining Quantity (Base)" := TrackingReservationEntry."Quantity (Base)";
        "Untracked Quantity" := TrackingReservationEntry."Quantity (Base)";
        if not IsSupply then
            ChangeSign();

        OnAfterTransferQtyFromItemTrgkEntry(Rec, TrackingReservationEntry);
    end;

    procedure ReduceQtyByItemTracking(var NewInventoryProfile: Record "Inventory Profile")
    begin
        "Original Quantity" -= NewInventoryProfile."Original Quantity";
        Quantity -= NewInventoryProfile.Quantity;
        "Quantity (Base)" -= NewInventoryProfile."Quantity (Base)";
        "Finished Quantity" -= NewInventoryProfile."Finished Quantity";
        "Remaining Quantity" -= NewInventoryProfile."Remaining Quantity";
        "Remaining Quantity (Base)" -= NewInventoryProfile."Remaining Quantity (Base)";
        "Untracked Quantity" -= NewInventoryProfile."Untracked Quantity";

        OnAfterReduceQtyByItemTracking(Rec, NewInventoryProfile);
    end;

    procedure ChangeSign()
    begin
        "Original Quantity" := -"Original Quantity";
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Untracked Quantity" := -"Untracked Quantity";
        "Quantity (Base)" := -"Quantity (Base)";
        Quantity := -Quantity;
        "Remaining Quantity" := -"Remaining Quantity";
        "Finished Quantity" := -"Finished Quantity";

        OnAfterChangeSign(Rec);
    end;

    procedure TransferToTrackingEntry(var TrackingReservationEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean)
    var
        IsHandled: Boolean;
    begin
        case "Source Type" of
            0:
                begin
                    // Surplus, Reorder Point
                    TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                    TrackingReservationEntry."Suppressed Action Msg." := true;
                    exit;
                end;
            Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry":
                begin
                    // Will be marked as Surplus
                    TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Surplus;
                    TrackingReservationEntry.SetSource(Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry", 0, "Source ID", 0, '', 0);
                    TrackingReservationEntry."Suppressed Action Msg." := true;
                end;
            Database::"Item Ledger Entry":
                TrackingReservationEntry.SetSource(
                  Database::"Item Ledger Entry", 0, '', "Source Ref. No.", '', 0);
            Database::"Transfer Line":
                if IsSupply then
                    TrackingReservationEntry.SetSource(Database::"Transfer Line", 1, "Source ID", "Source Ref. No.", '', "Source Prod. Order Line")
                else
                    TrackingReservationEntry.SetSource(Database::"Transfer Line", 0, "Source ID", "Source Ref. No.", '', 0);
            else begin
                IsHandled := false;
                OnTransferToTrackingEntrySourceTypeElseCase(Rec, TrackingReservationEntry, UseSecondaryFields, IsHandled);
                if not IsHandled then
                    Error(IncorrectSourceTypeErr, "Source Type");
            end;
        end;

        TrackingReservationEntry."Item No." := "Item No.";
        TrackingReservationEntry."Location Code" := "Location Code";
        TrackingReservationEntry.Description := '';
        TrackingReservationEntry."Creation Date" := Today;
        TrackingReservationEntry."Created By" := CopyStr(UserId(), 1, 50);
        TrackingReservationEntry."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        TrackingReservationEntry."Variant Code" := "Variant Code";
        TrackingReservationEntry.Binding := Binding;
        TrackingReservationEntry."Disallow Cancellation" := "Disallow Cancellation";
        TrackingReservationEntry.CopyTrackingFromInvtProfile(Rec);
        TrackingReservationEntry."Expiration Date" := "Expiration Date";

        if IsSupply then
            TrackingReservationEntry."Quantity (Base)" := "Untracked Quantity"
        else
            TrackingReservationEntry."Quantity (Base)" := -"Untracked Quantity";

        TrackingReservationEntry.Quantity :=
          Round(TrackingReservationEntry."Quantity (Base)" / TrackingReservationEntry."Qty. per Unit of Measure", UnitofMeasureManagement.QtyRndPrecision());
        TrackingReservationEntry.Positive := TrackingReservationEntry."Quantity (Base)" > 0;

        if TrackingReservationEntry."Reservation Status" <> TrackingReservationEntry."Reservation Status"::Surplus then
            if ("Planning Level Code" > 0) or
               (Binding = Binding::"Order-to-Order")
            then
                TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Reservation
            else
                TrackingReservationEntry."Reservation Status" := TrackingReservationEntry."Reservation Status"::Tracking;

        if TrackingReservationEntry."Quantity (Base)" = 0 then begin
            TrackingReservationEntry."Expected Receipt Date" := GetExpectedReceiptDate();
            TrackingReservationEntry."Shipment Date" := "Due Date";
        end else
            if TrackingReservationEntry.Positive then
                TrackingReservationEntry."Expected Receipt Date" := GetExpectedReceiptDate()
            else
                TrackingReservationEntry."Shipment Date" := "Due Date";

        OnAfterTransferToTrackingEntry(TrackingReservationEntry, Rec, UseSecondaryFields);
    end;

    procedure ActiveInWarehouse(): Boolean
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
    begin
        if "Source Type" = Database::"Transfer Line" then
            exit(WhseValidateSourceLine.WhseLinesExist("Source Type", 0, "Source ID", "Source Ref. No.", 0, Quantity));

        exit(
            WhseValidateSourceLine.WhseLinesExist("Source Type", "Source Order Status", "Source ID", "Source Ref. No.", 0, Quantity) or
            WhseValidateSourceLine.WhseWorkSheetLinesExistForJobOrProdOrderComponent("Source Type", "Source Order Status", "Source ID", "Source Ref. No.", 0, Quantity));
    end;

    local procedure GetExpectedReceiptDate(): Date
    begin
        if "Action Message" in ["Action Message"::Reschedule, "Action Message"::"Resched. & Chg. Qty."] then
            exit("Original Due Date");
        exit("Due Date");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Order Status" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Type", SourceType);
        SetRange("Source Order Status", SourceSubtype);
        SetRange("Source ID", SourceID);
        SetRange("Source Ref. No.", SourceRefNo);
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetSourceTypeFilter(SourceType: Integer)
    var
        SourceTypeFilter: Text;
    begin
        SourceTypeFilter := Rec.GetFilter("Source Type");
        if SourceTypeFilter = '' then
            SetFilter("Source Type", '%1', SourceType)
        else begin
            SourceTypeFilter += StrSubstNo('|%1', SourceType);
            SetFilter("Source Type", SourceTypeFilter);
        end;
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromInvtProfile(InventoryProfile: Record "Inventory Profile")
    begin
        "Serial No." := InventoryProfile."Serial No.";
        "Lot No." := InventoryProfile."Lot No.";

        OnAfterCopyTrackingFromInvtProfile(Rec, InventoryProfile);
    end;

    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
    end;

    procedure SetTrackingFilter(InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Serial No." <> '' then
            SetRange("Serial No.", InventoryProfile."Serial No.")
        else
            SetRange("Serial No.");
        if InventoryProfile."Lot No." <> '' then
            SetRange("Lot No.", InventoryProfile."Lot No.")
        else
            SetRange("Lot No.");

        OnAfterSetTrackingFilter(Rec, InventoryProfile);
    end;

    procedure SetTrackingFilterFromInvtProfile(InventoryProfile: Record "Inventory Profile")
    begin
        SetRange("Lot No.", InventoryProfile."Lot No.");
        SetRange("Serial No.", InventoryProfile."Serial No.");

        OnAfterSetTrackingFilterFromInvtProfile(Rec, InventoryProfile);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean
    begin
        IsTrackingExists := ("Lot No." <> '') or ("Serial No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExists);
    end;

    procedure InsertSupplyInvtProfile(ToDate: Date)
    begin
        if Rec.IsSupply then begin
            if Rec."Due Date" > ToDate then
                Rec."Planning Flexibility" := Rec."Planning Flexibility"::None;
            Rec.Insert();
        end else
            if Rec."Due Date" <= ToDate then begin
                Rec.ChangeSign();
                Rec."Planning Flexibility" := Rec."Planning Flexibility"::None;
                Rec.Insert();
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var InventoryProfile: Record "Inventory Profile"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromItemLedgerEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromSalesLine(var InventoryProfile: Record "Inventory Profile"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterTransferFromSalesLine(InventoryProfile, SalesLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromSalesLine in codeunit Sales Line-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesLine(var InventoryProfile: Record "Inventory Profile"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromComponent(var InventoryProfile: Record "Inventory Profile"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnAfterTransferFromComponent(InventoryProfile, ProdOrderComp);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromProdOrderComponent in codeunit Prod. Order Comp.-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromComponent(var InventoryProfile: Record "Inventory Profile"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromPlanComponent(var InventoryProfile: Record "Inventory Profile"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component")
    begin
        OnAfterTransferFromPlanComponent(InventoryProfile, PlanningComponent);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromPlnanningComponent in codeunit Plng. Component-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPlanComponent(var InventoryProfile: Record "Inventory Profile"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromPurchaseLine(var InventoryProfile: Record "Inventory Profile"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterTransferFromPurchaseLine(InventoryProfile, PurchaseLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromProdOrderLine in codeunit Purch. Line-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchaseLine(var InventoryProfile: Record "Inventory Profile"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromProdOrderLine(var InventoryProfile: Record "Inventory Profile"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnAfterTransferFromProdOrderLine(InventoryProfile, ProdOrderLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromProdOrderLine in codeunit Prod. Order Line-Reserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrderLine(var InventoryProfile: Record "Inventory Profile"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromAsmLine(var InventoryProfile: Record "Inventory Profile"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnAfterTransferFromAsmLine(InventoryProfile, AssemblyLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromAssemblyLine  in codeunit Assembly Line-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmLine(var InventoryProfile: Record "Inventory Profile"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromAsmHeader(var InventoryProfile: Record "Inventory Profile"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnAfterTransferFromAsmHeader(InventoryProfile, AssemblyHeader);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromAssemblyHeader in codeunit Assembly Header-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmHeader(var InventoryProfile: Record "Inventory Profile"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromRequisitionLine(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
        OnAfterTransferFromRequisitionLine(InventoryProfile, RequisitionLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromRequisitionLine in codeunit Req. Line-Reserve', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromRequisitionLine(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromInboundTransfer(var InventoryProfile: Record "Inventory Profile"; TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfPlan(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfer(var InventoryProfile: Record "Inventory Profile"; TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromServLine(var InventoryProfile: Record "Inventory Profile"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterTransferFromServLine(InventoryProfile, ServiceLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromServiceLine in codeunit Service Line-Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServLine(var InventoryProfile: Record "Inventory Profile"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromJobPlanningLine(var InventoryProfile: Record "Inventory Profile"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
        OnAfterTransferFromJobPlanningLine(InventoryProfile, JobPlanningLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferInventoryProfileFromServiceLine in codeunit Job Planning Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobPlanningLine(var InventoryProfile: Record "Inventory Profile"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToTrackingEntry(var ReservationEntry: Record "Reservation Entry"; InventoryProfile: Record "Inventory Profile"; UseSecondaryFields: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(InventoryProfile: Record "Inventory Profile"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilter(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBindingsOnAfterAssignPrimaryOrderInfo(var InventoryProfile: Record "Inventory Profile"; OppositeReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; UseSecondaryFields: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBindings(var ReservEntry: Record "Reservation Entry"; var TrackingEntry: Record "Reservation Entry"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedQtyOnBeforeReservationEntryLoop(var ReservationEntry: Record "Reservation Entry"; var ReservedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferQtyFromItemTrgkEntry(var InventoryProfile: Record "Inventory Profile"; TrackingReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReduceQtyByItemTracking(var InventoryProfile: Record "Inventory Profile"; NewInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangeSign(var InventoryProfile: Record "Inventory Profile")
    begin
    end;
}

