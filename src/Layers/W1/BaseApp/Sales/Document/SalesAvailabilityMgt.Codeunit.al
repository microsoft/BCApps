// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.Company;
using System.IO;
using Microsoft.Assembly.Document;

codeunit 99000872 "Sales Availability Mgt."
{
    var
        AvailabilityManagement: Codeunit AvailabilityManagement;
        SalesTxt: Label 'Sales';
        SalesOrderTxt: Label 'Sales Order';
        SalesDocumentTxt: Label 'Sales %1', Comment = '%1 - document type';
        UnsupportedEntitySourceErr: Label 'Unsupported Entity Source Type = %1, Source Subtype = %2.', Comment = '%1 = source type, %2 = source subtype';

    // Codeunit AvailabilityManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OnSetSourceRecord(var OrderPromisingLine: Record "Order Promising Line"; var SourceRecordVar: Variant; var CaptionText: Text; TableID: Integer; var sender: Codeunit AvailabilityManagement)
    var
        SalesHeader: Record "Sales Header";
    begin
        case TableID of
            Database::"Sales Header":
                begin
                    AvailabilityManagement := sender;
                    SalesHeader := SourceRecordVar;
                    SetSalesHeader(OrderPromisingLine, SalesHeader, CaptionText);
                end;
        end;
    end;

    procedure SetSalesHeader(var OrderPromisingLine: Record "Order Promising Line"; var SalesHeader: Record "Sales Header"; var CaptionText: Text)
    var
        SalesLine: Record "Sales Line";
        SalesAvailabilityMgt: Codeunit "Sales Availability Mgt.";
    begin
        CaptionText := SalesOrderTxt;
        OrderPromisingLine.DeleteAll();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        OnSetSalesHeaderOnAfterFilterSalesLine(SalesLine, SalesHeader);
        if SalesLine.FindSet() then
            repeat
                if SalesLine.IsInventoriableItem() then begin
                    OrderPromisingLine.Init();
                    OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                    SalesAvailabilityMgt.TransferToOrderPromisingLine(OrderPromisingLine, SalesLine);
                    SalesLine.CalcFields("Reserved Qty. (Base)");
                    AvailabilityManagement.InsertPromisingLine(
                        OrderPromisingLine, SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)");
                end;
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCalcCapableToPromiseLine', '', false, false)]
    local procedure OnCalcCapableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    var
        SalesLine: Record "Sales Line";
        CapableToPromise: Codeunit "Capable to Promise";
        QtyReservedTotal: Decimal;
        OldCTPQty: Decimal;
        FeasibleDate: Date;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                begin
                    Clear(OrderPromisingLine."Earliest Shipment Date");
                    Clear(OrderPromisingLine."Planned Delivery Date");

                    OnAfterClearDatesCalcCTP(OrderPromisingLine, SalesLine);

                    SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    SalesLine.CalcFields("Reserved Quantity");
                    QtyReservedTotal := SalesLine."Reserved Quantity";
                    CapableToPromise.RemoveReqLines(SalesLine."Document No.", SalesLine."Line No.", 0, false);
                    SalesLine.CalcFields("Reserved Quantity");
                    OldCTPQty := QtyReservedTotal - SalesLine."Reserved Quantity";
                    FeasibleDate :=
                        CapableToPromise.CalcCapableToPromiseDate(
                            OrderPromisingLine."Item No.", OrderPromisingLine."Variant Code", OrderPromisingLine."Location Code",
                            OrderPromisingLine."Original Shipment Date",
                            OrderPromisingLine."Unavailable Quantity" + OldCTPQty, OrderPromisingLine."Unit of Measure Code",
                            OrderPromisingID, OrderPromisingLine."Source Line No.",
                            LastValidLine, CompanyInfo."Check-Avail. Time Bucket",
                            CompanyInfo."Check-Avail. Period Calc.");
                    if FeasibleDate <> OrderPromisingLine."Original Shipment Date" then
                        OrderPromisingLine.Validate(OrderPromisingLine."Earliest Shipment Date", FeasibleDate)
                    else
                        OrderPromisingLine.Validate(OrderPromisingLine."Earliest Shipment Date", OrderPromisingLine."Original Shipment Date");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnGetRequestedDeliveryDate', '', false, false)]
    local procedure OnGetRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line"; var RequestedDeliveryDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                if SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.") then
                    RequestedDeliveryDate := SalesLine."Requested Delivery Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnUpdateSourceLine', '', false, false)]
    local procedure OnUpdateSourceLine(var OrderPromisingLine: Record "Order Promising Line")
    var
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                begin
                    SalesLine.Get(
                      OrderPromisingLine."Source Subtype",
                      OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    if OrderPromisingLine."Earliest Shipment Date" <> 0D then
                        SalesLine.Validate("Shipment Date", OrderPromisingLine."Earliest Shipment Date");

                    SalesLineReserve.ReservQuantity(SalesLine, QtyToReserve, QtyToReserveBase);
                    if (SalesLine."Shipment Date" <> 0D) and
                       (SalesLine.Reserve = SalesLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservationManagement.SetReservSource(SalesLine);
                        ReservationManagement.AutoReserve(
                          FullAutoReservation, '', SalesLine."Shipment Date", QtyToReserve, QtyToReserveBase);
                        SalesLine.CalcFields("Reserved Quantity");
                    end;
                    SalesLine.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnCalcNeededQuantity', '', false, false)]
    local procedure OnCreateReservationsOnCalcNeededQuantity(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                begin
                    SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := SalesLine."Outstanding Quantity" - SalesLine."Reserved Quantity";
                    NeededQtyBase := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnBindToTracking', '', false, false)]
    local procedure OnCreateReservationsOnBindToTracking(var OrderPromisingLine: Record "Order Promising Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        SalesLine: Record "Sales Line";
        TrackingSpecification: Record "Tracking Specification";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        SourceRecRef: RecordRef;
        FullAutoReservation: Boolean;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Sales:
                begin
                    SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    if (SalesLine.Reserve = SalesLine.Reserve::Never) and not SalesLine."Drop Shipment" then begin
                        SourceRecRef.GetTable(SalesLine);
                        TempRecordBuffer.InsertRecordBuffer(SourceRecRef);
                    end;
                    if SalesLine.Reserve <> SalesLine.Reserve::Never then begin
                        TrackingSpecification.InitTrackingSpecification(
                            Database::"Requisition Line",
                            0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
                            ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
                        SalesLineReserve.BindToTracking(
                            SalesLine, TrackingSpecification, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
                    end;

                    SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    if SalesLine.Quantity <> SalesLine."Reserved Quantity" then begin
                        SourceRecRef.GetTable(SalesLine);
                        ReservationManagement.SetReservSource(SourceRecRef);
                        ReservationManagement.AutoReserve(
                            FullAutoReservation, '', SalesLine."Shipment Date",
                            SalesLine.Quantity - SalesLine."Reserved Quantity",
                            SalesLine."Quantity (Base)" - SalesLine."Reserved Qty. (Base)");
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCancelReservations', '', false, false)]
    local procedure OnCancelReservations(var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
    begin
        TempRecordBuffer.SetRange("Table No.", Database::"Sales Line");
        if TempRecordBuffer.FindSet() then
            repeat
                SourceRecRef := TempRecordBuffer."Record Identifier".GetRecord();
                SourceRecRef.SetTable(SalesLine);
                SalesLine.Find();
                SalesLine.Reserve := SalesLine.Reserve::Optional;
                SalesLine.Modify();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                SalesLine.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                SalesLine.Reserve := SalesLine.Reserve::Never;
                SalesLine.Modify();
            until TempRecordBuffer.Next() = 0;
    end;

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnLookupDemandNo', '', false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text);
    var
        SalesHeader: Record "Sales Header";
        SalesList: Page "Sales List";
    begin
        if DemandType = DemandType::"Sales Demand" then begin
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesList.SetTableView(SalesHeader);
            SalesList.LookupMode := true;
            if SalesList.RunModal() = ACTION::LookupOK then begin
                SalesList.GetRecord(SalesHeader);
                Text := SalesHeader."No.";
                Result := true;
            end;
            Result := false;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        if AvailabilityCalcOverview."Source Type" = Database::"Sales Line" then
            Text := SalesTxt;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FilterLinesWithItemToPlan(Item, SalesLine."Document Type"::Order);
        if SalesLine.FindFirst() then
            repeat
                SalesLine.SetRange("Location Code", SalesLine."Location Code");
                SalesLine.SetRange("Variant Code", SalesLine."Variant Code");
                SalesLine.SetRange("Shipment Date", SalesLine."Shipment Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code");

                SalesLine.FindLast();
                SalesLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SalesLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                SalesLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyDates', '', false, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FilterLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order");
        if SalesLine.FindFirst() then
            repeat
                SalesLine.SetRange("Location Code", SalesLine."Location Code");
                SalesLine.SetRange("Variant Code", SalesLine."Variant Code");
                SalesLine.SetRange("Shipment Date", SalesLine."Shipment Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code");

                SalesLine.FindLast();
                SalesLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SalesLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                SalesLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)", "Sell-to Customer Name");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code",
                    -SalesLine."Outstanding Qty. (Base)", -SalesLine."Reserved Qty. (Base)",
                    Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Sell-to Customer Name",
                    "Demand Order Source Type"::"Sales Demand");
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyEntries', '', false, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)", "Sell-to Customer Name");
                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview,
                  AvailabilityCalcOverview.Type::Supply, SalesLine."Shipment Date", SalesLine."Location Code", SalesLine."Variant Code",
                  SalesLine."Outstanding Qty. (Base)", SalesLine."Reserved Qty. (Base)",
                  Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Sell-to Customer Name",
                  "Demand Order Source Type"::"All Demands");
            until SalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnCheckItemInRange', '', false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if DemandType = DemandType::"Sales Demand" then
            if SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::Order) then
                if DemandNo <> '' then begin
                    SalesLine.SetRange("Document No.", DemandNo);
                    Found := not SalesLine.IsEmpty();
                end else
                    Found := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        Exists := Exists or SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::Order);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnSupplyExist', '', false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        Exists := Exists or SalesLine.LinesWithItemToPlanExist(Item, SalesLine."Document Type"::"Return Order");
    end;

    // Table "Order Promising Line"

    procedure TransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var SalesLine: Record "Sales Line")
    begin
        OrderPromisingLine."Source Type" := OrderPromisingLine."Source Type"::Sales;
        OrderPromisingLine."Source Subtype" := SalesLine."Document Type".AsInteger();
        OrderPromisingLine."Source ID" := SalesLine."Document No.";
        OrderPromisingLine."Source Line No." := SalesLine."Line No.";

        OrderPromisingLine."Item No." := SalesLine."No.";
        OrderPromisingLine."Variant Code" := SalesLine."Variant Code";
        OrderPromisingLine."Location Code" := SalesLine."Location Code";
        OrderPromisingLine.Validate("Requested Delivery Date", SalesLine."Requested Delivery Date");
        OrderPromisingLine."Original Shipment Date" := SalesLine."Shipment Date";
        OrderPromisingLine.Description := SalesLine.Description;
        OrderPromisingLine.Quantity := SalesLine."Outstanding Quantity";
        OrderPromisingLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
        OrderPromisingLine."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        OrderPromisingLine."Quantity (Base)" := SalesLine."Outstanding Qty. (Base)";

        OnAfterTransferToOrderPromisingLine(OrderPromisingLine, SalesLine);
#if not CLEAN25
        OrderPromisingLine.RunOnAfterTransferFromSalesLine(OrderPromisingLine, SalesLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateRequestedDeliveryDate', '', false, false)]
    local procedure OnValidateRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Sales then begin
            SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
            OrderPromisingLine."Requested Shipment Date" := CalcReqShipDate(SalesLine);
        end;
    end;

    local procedure CalcReqShipDate(SalesLine: Record "Sales Line"): Date
    begin
        if (SalesLine."Requested Delivery Date" <> 0D) and
           (SalesLine."Promised Delivery Date" = 0D)
        then begin
            SalesLine.SuspendStatusCheck(true);
            SalesLine.Validate("Requested Delivery Date", SalesLine."Requested Delivery Date");
        end;
        exit(SalesLine."Shipment Date");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidatePlannedDeliveryDate', '', false, false)]
    local procedure OnValidatePlannedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Sales then begin
            SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
            SalesLine."Planned Delivery Date" := OrderPromisingLine."Planned Delivery Date";
            SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedDate();
            SalesLine."Shipment Date" := SalesLine.CalcShipmentDate();
            OrderPromisingLine."Planned Delivery Date" := SalesLine."Planned Delivery Date";
            OrderPromisingLine."Earliest Shipment Date" := SalesLine."Shipment Date";
            if OrderPromisingLine."Earliest Shipment Date" > OrderPromisingLine."Planned Delivery Date" then
                OrderPromisingLine."Planned Delivery Date" := OrderPromisingLine."Earliest Shipment Date";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateEarliestDeliveryDate', '', false, false)]
    local procedure OnValidateEarliestDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Sales then
            if OrderPromisingLine."Earliest Shipment Date" <> 0D then begin
                SalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                SalesLine.SuspendStatusCheck(true);
                SalesLine.Validate("Shipment Date", OrderPromisingLine."Earliest Shipment Date");
                OrderPromisingLine."Planned Delivery Date" := SalesLine."Planned Delivery Date";
            end;
    end;

    // Page "Order Promising Lines"

    [EventSubscriber(ObjectType::Page, Page::"Order Promising Lines", 'OnOpenPageOnSetSource', '', false, false)]
    local procedure OnOpenPageOnSetSource(var OrderPromisingLine: Record "Order Promising Line"; var CrntSourceType: Enum "Order Promising Line Source Type"; var CrntSourceID: Code[20]; var AvailabilityMgt: Codeunit AvailabilityManagement; var AcceptButtonEnable: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ShouldExit: Boolean;
    begin
        ShouldExit := CrntSourceType = OrderPromisingLine."Source Type"::Job;
        OnOpenPageOnSetSourceOnAfterSetShouldExit(CrntSourceType, ShouldExit);
        if ShouldExit then
            exit;

        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderPromisingLine.GetRangeMin("Source ID"));
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        CrntSourceType := CrntSourceType::Sales;
        CrntSourceID := SalesHeader."No.";
        AcceptButtonEnable := SalesHeader.Status = SalesHeader.Status::Open;
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnSalesOrder(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnSalesReturn(TempreservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnSalesOrder(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupPlannedOrderReceipt', '', false, false)]
    local procedure OnLookupPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupScheduledReceipt', '', false, false)]
    local procedure OnLookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnSalesReturn(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnSalesOrder(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Sales Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnSalesReturn(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Sales Line",
            Format(ReservationEntry."Source Subtype"::"5"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromSalesLine(var SalesLine: Record "Sales Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        AssemblyAvailabilityMgt: Codeunit "Assembly Availability Mgt.";
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
        IsHandled: Boolean;
    begin
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.");
        Item.Reset();
        Item.Get(SalesLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, SalesLine."Location Code", SalesLine."Variant Code", SalesLine."Shipment Date");

        IsHandled := false;
        OnBeforeShowItemAvailFromSalesLine(Item, SalesLine, IsHandled, AvailabilityType);
        if IsHandled then
            exit;

        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Shipment Date")), SalesLine."Shipment Date", NewDate) then
                    SalesLine.Validate(SalesLine."Shipment Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Variant Code")), SalesLine."Variant Code", NewVariantCode) then begin
                    SalesLine.Validate(SalesLine."Variant Code", NewVariantCode);
                    ItemCheckAvail.SalesLineCheck(SalesLine);
                end;
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Location Code")), SalesLine."Location Code", NewLocationCode) then begin
                    SalesLine.Validate(SalesLine."Location Code", NewLocationCode);
                    ItemCheckAvail.SalesLineCheck(SalesLine);
                end;
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Shipment Date")), SalesLine."Shipment Date", NewDate, false) then
                    SalesLine.Validate(SalesLine."Shipment Date", NewDate);
            AvailabilityType::BOM:
                if SalesLine.AsmToOrderExists(AsmHeader) then
                    AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmHeader(AsmHeader, AvailabilityType)
                else
                    if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Shipment Date")), SalesLine."Shipment Date", NewDate) then
                        SalesLine.Validate(SalesLine."Shipment Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(SalesLine.FieldCaption(SalesLine."Unit of Measure Code")), SalesLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    SalesLine.Validate(SalesLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure GetFieldCaption(FieldCaption: Text): Text[80]
    begin
        exit(CopyStr(FieldCaption, 1, 80));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromSalesLine(var Item: Record Item; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

    procedure ShowSalesLines(var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order);
        PAGE.Run(0, SalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields(
            "Qty. on Sales Order",
            "Qty. on Sales Return");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean)
    begin
        if SourceType = DATABASE::"Sales Line" then begin
            TransferSalesLine(InventoryEventBuffer, InventoryPageData, SourceType, SourceSubtype, SourceID);
            IsHandled := true;
        end;
    end;

    local procedure TransferSalesLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
    begin
        SalesHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(SalesHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData.Description := SalesHeader."Sell-to Customer Name";
        InventoryPageData.Source := StrSubstNo(SalesDocumentTxt, Format(SalesHeader."Document Type"));
        InventoryPageData."Document No." := SalesHeader."No.";
        case "Sales Document Type".FromInteger(SourceSubtype) of
            "Sales Document Type"::Order,
            "Sales Document Type"::Invoice,
            "Sales Document Type"::"Credit Memo":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::Sale;
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            "Sales Document Type"::"Blanket Order":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::"Blanket Sales Order";
                    InventoryPageData.Forecast := InventoryEventBuffer."Orig. Quantity (Base)";
                    InventoryPageData."Remaining Forecast" := InventoryEventBuffer."Remaining Quantity (Base)";
                end;
            "Sales Document Type"::"Return Order":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::"Sales Return";
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Sales Line", Item.FieldNo("Qty. on Sales Order"),
                    SalesLine.TableCaption(), Item."Qty. on Sales Order", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Scheduled Order Receipt":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Sales Line", 0,
                    SalesLine.TableCaption(), Item."Qty. on Sales Return", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        SalesLine: Record "Sales Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Sales Line":
                begin
                    if ItemAvailabilityLine.QuerySource > 0 then
                        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order)
                    else
                        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order");
                    SalesLine.SetRange("Drop Shipment", false);
                    Page.RunModal(0, SalesLine);
                end;
        end;
    end;


    procedure TransferFromSales(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        RecRef: RecordRef;
        RemQty: Decimal;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(SalesLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := SalesLine."No.";
        InventoryEventBuffer."Variant Code" := SalesLine."Variant Code";
        InventoryEventBuffer."Location Code" := SalesLine."Location Code";
        InventoryEventBuffer."Availability Date" := SalesLine."Shipment Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Sale;
        SalesLineReserve.ReservQuantity(SalesLine, RemQty, InventoryEventBuffer."Remaining Quantity (Base)");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -SalesLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        if InventoryEventBuffer."Derived from Blanket Order" then begin
            InventoryEventBuffer."Ref. Order No." := SalesLine."Blanket Order No.";
            InventoryEventBuffer."Ref. Order Line No." := SalesLine."Blanket Order Line No.";
        end;

        OnAfterTransferFromSales(InventoryEventBuffer, SalesLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromSales(InventoryEventBuffer, SalesLine);
#endif
    end;

    procedure TransferFromSalesBlanketOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line"; UnconsumedQtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(SalesLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := SalesLine."No.";
        InventoryEventBuffer."Variant Code" := SalesLine."Variant Code";
        InventoryEventBuffer."Location Code" := SalesLine."Location Code";
        InventoryEventBuffer."Availability Date" := SalesLine."Shipment Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::"Blanket Sales Order";
        InventoryEventBuffer."Remaining Quantity (Base)" := -UnconsumedQtyBase;
        InventoryEventBuffer."Reserved Quantity (Base)" := 0;
        InventoryEventBuffer."Orig. Quantity (Base)" := -SalesLine."Quantity (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromSalesBlanketOrder(InventoryEventBuffer, SalesLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromSalesBlanketOrder(InventoryEventBuffer, SalesLine);
#endif
    end;

    procedure TransferFromSalesReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        RecRef: RecordRef;
        RemQty: Decimal;
    begin
        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(SalesLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := SalesLine."No.";
        InventoryEventBuffer."Variant Code" := SalesLine."Variant Code";
        InventoryEventBuffer."Location Code" := SalesLine."Location Code";
        InventoryEventBuffer."Availability Date" := SalesLine."Shipment Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Sale;
        SalesLineReserve.ReservQuantity(SalesLine, RemQty, InventoryEventBuffer."Remaining Quantity (Base)");
        SalesLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -SalesLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Derived from Blanket Order" := SalesLine."Blanket Order No." <> '';
        if InventoryEventBuffer."Derived from Blanket Order" then begin
            InventoryEventBuffer."Ref. Order No." := SalesLine."Blanket Order No.";
            InventoryEventBuffer."Ref. Order Line No." := SalesLine."Blanket Order Line No.";
        end;

        OnAfterTransferFromSalesReturn(InventoryEventBuffer, SalesLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromSalesReturn(InventoryEventBuffer, SalesLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSales(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesBlanketOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnSetSourceOnAfterSetShouldExit(CrntSourceType: Enum "Order Promising Line Source Type"; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearDatesCalcCTP(var OrderPromisingLine: Record "Order Promising Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSalesHeaderOnAfterFilterSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;
}
