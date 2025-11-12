// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Requisition;
using Microsoft.Service.History;
using Microsoft.Inventory.Tracking;

codeunit 6452 "Serv. Availability Mgt."
{
    var
        AvailabilityManagement: Codeunit AvailabilityManagement;
        ServiceTxt: Label 'Service';
        ServiceOrderTxt: Label 'Service Order';
        ServiceDocumentTxt: Label 'Service %1', Comment = '%1 - document type';

    // Codeunit AvailabilityManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OnSetSourceRecord(var OrderPromisingLine: Record "Order Promising Line"; var SourceRecordVar: Variant; var CaptionText: Text; TableID: Integer; var sender: Codeunit AvailabilityManagement)
    var
        ServiceHeader: Record "Service Header";
    begin
        case TableID of
            Database::"Service Header":
                begin
                    AvailabilityManagement := sender;
                    ServiceHeader := SourceRecordVar;
                    SetServiceHeader(OrderPromisingLine, ServiceHeader, CaptionText);
                end;
        end;
    end;

    procedure SetServiceHeader(var OrderPromisingLine: Record "Order Promising Line"; var ServiceHeader: Record "Service Header"; var CaptionText: Text)
    var
        ServiceLine: Record "Service Line";
        ServAvailabilityMgt: Codeunit "Serv. Availability Mgt.";
    begin
        CaptionText := ServiceOrderTxt;
        OrderPromisingLine.DeleteAll();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("Outstanding Quantity", '>0');
        OnSetServiceHeaderOnAfterFilterServiceLine(ServiceLine, ServiceHeader);
        if ServiceLine.Find('-') then
            repeat
                OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                ServAvailabilityMgt.TransferToOrderPromisingLine(OrderPromisingLine, ServiceLine);
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                AvailabilityManagement.InsertPromisingLine(
                    OrderPromisingLine, ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCalcCapableToPromiseLine', '', false, false)]
    local procedure OnCalcCapableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    var
        ServiceLine: Record "Service Line";
        CapableToPromise: Codeunit "Capable to Promise";
        QtyReservedTotal: Decimal;
        OldCTPQty: Decimal;
        FeasibleDate: Date;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::"Service Order":
                begin
                    Clear(OrderPromisingLine."Earliest Shipment Date");
                    Clear(OrderPromisingLine."Planned Delivery Date");
                    ServiceLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    ServiceLine.CalcFields("Reserved Quantity");
                    QtyReservedTotal := ServiceLine."Reserved Quantity";
                    CapableToPromise.RemoveReqLines(ServiceLine."Document No.", ServiceLine."Line No.", 0, false);
                    ServiceLine.CalcFields("Reserved Quantity");
                    OldCTPQty := QtyReservedTotal - ServiceLine."Reserved Quantity";
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
        ServiceLine: Record "Service Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::"Service Order":
                if ServiceLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.") then
                    RequestedDeliveryDate := ServiceLine."Requested Delivery Date";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnUpdateSourceLine', '', false, false)]
    local procedure OnUpdateSourceLine(var OrderPromisingLine: Record "Order Promising Line")
    var
        ServiceLine: Record "Service Line";
        ServLineReserve: Codeunit "Service Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::"Service Order":
                begin
                    ServiceLine.Get(
                      OrderPromisingLine."Source Subtype",
                      OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    if OrderPromisingLine."Earliest Shipment Date" <> 0D then
                        ServiceLine.Validate("Needed by Date", OrderPromisingLine."Earliest Shipment Date");

                    ServLineReserve.ReservQuantity(ServiceLine, QtyToReserve, QtyToReserveBase);
                    if (ServiceLine."Needed by Date" <> 0D) and
                       (ServiceLine.Reserve = ServiceLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservationManagement.SetReservSource(ServiceLine);
                        ReservationManagement.AutoReserve(
                          FullAutoReservation, '', ServiceLine."Needed by Date", QtyToReserve, QtyToReserveBase);
                        ServiceLine.CalcFields("Reserved Quantity");
                    end;
                    ServiceLine.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnCalcNeededQuantity', '', false, false)]
    local procedure OnCreateReservationsOnCalcNeededQuantity(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::"Service Order":
                begin
                    ServiceLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    ServiceLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := ServiceLine."Outstanding Quantity" - ServiceLine."Reserved Quantity";
                    NeededQtyBase := ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnBindToTracking', '', false, false)]
    local procedure OnCreateReservationsOnBindToTracking(var OrderPromisingLine: Record "Order Promising Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var TempRecordBuffer: Record System.IO."Record Buffer" temporary)
    var
        ServiceLine: Record "Service Line";
        TrackingSpecification: Record "Tracking Specification";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        SourceRecRef: RecordRef;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::"Service Order":
                begin
                    ServiceLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Requisition Line",
                        0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
                        ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
                    ServiceLineReserve.BindToTracking(
                        ServiceLine, TrackingSpecification, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
                    if ServiceLine.Reserve = ServiceLine.Reserve::Never then begin
                        SourceRecRef.GetTable(ServiceLine);
                        TempRecordBuffer.InsertRecordBuffer(SourceRecRef);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCancelReservations', '', false, false)]
    local procedure OnCancelReservations(var TempRecordBuffer: Record System.IO."Record Buffer" temporary)
    var
        ServiceLine: Record "Service Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
    begin
        TempRecordBuffer.SetRange("Table No.", Database::"Service Line");
        if TempRecordBuffer.FindSet() then
            repeat
                SourceRecRef := TempRecordBuffer."Record Identifier".GetRecord();
                SourceRecRef.SetTable(ServiceLine);
                ServiceLine.Find();
                ServiceLine.Reserve := ServiceLine.Reserve::Optional;
                ServiceLine.Modify();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                ServiceLine.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                ServiceLine.Reserve := ServiceLine.Reserve::Never;
                ServiceLine.Modify();
            until TempRecordBuffer.Next() = 0;
    end;

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnLookupDemandNo', '', false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text);
    var
        ServiceHeader: Record "Service Header";
        ServiceOrders: Page "Service Orders";
    begin
        if DemandType = DemandType::"Service Demand" then begin
            ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
            ServiceOrders.SetTableView(ServiceHeader);
            ServiceOrders.LookupMode := true;
            if ServiceOrders.RunModal() = ACTION::LookupOK then begin
                ServiceOrders.GetRecord(ServiceHeader);
                Text := ServiceHeader."No.";
                Result := true;
            end;
            Result := false;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        if AvailabilityCalcOverview."Source Type" = Database::"Service Line" then
            Text := ServiceTxt;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.FilterLinesWithItemToPlan(Item);
        if ServiceLine.FindFirst() then
            repeat
                ServiceLine.SetRange("Location Code", ServiceLine."Location Code");
                ServiceLine.SetRange("Variant Code", ServiceLine."Variant Code");
                ServiceLine.SetRange("Needed by Date", ServiceLine."Needed by Date");

                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                    ServiceLine."Needed by Date", ServiceLine."Location Code", ServiceLine."Variant Code");

                ServiceLine.FindLast();
                ServiceLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ServiceLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ServiceLine.SetFilter("Needed by Date", Item.GetFilter("Date Filter"));
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        if ServiceLine.FindLinesWithItemToPlan(Item) then
            repeat
                ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, ServiceLine."Needed by Date", ServiceLine."Location Code", ServiceLine."Variant Code",
                    -ServiceLine."Outstanding Qty. (Base)", -ServiceLine."Reserved Qty. (Base)",
                    Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceHeader."Ship-to Name",
                    Enum::"Demand Order Source Type"::"Service Demand");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnCheckItemInRange', '', false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        if DemandType = DemandType::"Service Demand" then
            if ServiceLine.LinesWithItemToPlanExist(Item) then
                if DemandNo <> '' then begin
                    ServiceLine.SetRange("Document No.", DemandNo);
                    Found := not ServiceLine.IsEmpty();
                end else
                    Found := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        Exists := Exists or ServiceLine.LinesWithItemToPlanExist(Item);
    end;

    // Table "Order Promising Line"

    procedure TransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var ServiceLine: Record "Service Line")
    begin
        OrderPromisingLine."Source Type" := OrderPromisingLine."Source Type"::"Service Order";
        OrderPromisingLine."Source Subtype" := ServiceLine."Document Type".AsInteger();
        OrderPromisingLine."Source ID" := ServiceLine."Document No.";
        OrderPromisingLine."Source Line No." := ServiceLine."Line No.";

        OrderPromisingLine."Item No." := ServiceLine."No.";
        OrderPromisingLine."Variant Code" := ServiceLine."Variant Code";
        OrderPromisingLine."Location Code" := ServiceLine."Location Code";
        OrderPromisingLine.Validate("Requested Delivery Date", ServiceLine."Requested Delivery Date");
        OrderPromisingLine."Original Shipment Date" := ServiceLine."Needed by Date";
        OrderPromisingLine.Description := ServiceLine.Description;
        OrderPromisingLine.Quantity := ServiceLine."Outstanding Quantity";
        OrderPromisingLine."Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        OrderPromisingLine."Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        OrderPromisingLine."Quantity (Base)" := ServiceLine."Outstanding Qty. (Base)";

        OnAfterTransferToOrderPromisingLine(OrderPromisingLine, ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var ServiceLine: Record "Service Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateRequestedDeliveryDate', '', false, false)]
    local procedure OnValidateRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::"Service Order" then begin
            ServiceLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.");
            OrderPromisingLine."Requested Shipment Date" := ServiceLine."Needed by Date";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidatePlannedDeliveryDate', '', false, false)]
    local procedure OnValidatePlannedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::"Service Order" then
            OrderPromisingLine."Earliest Shipment Date" := OrderPromisingLine."Planned Delivery Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateEarliestDeliveryDate', '', false, false)]
    local procedure OnValidateEarliestDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::"Service Order" then
            if OrderPromisingLine."Earliest Shipment Date" <> 0D then
                OrderPromisingLine."Planned Delivery Date" := OrderPromisingLine."Earliest Shipment Date";
    end;

    // Page "Order Promising Lines"

    [EventSubscriber(ObjectType::Page, Page::"Order Promising Lines", 'OnOpenPageOnSetSource', '', false, false)]
    local procedure OnOpenPageOnSetSource(var OrderPromisingLine: Record "Order Promising Line"; var CrntSourceType: Enum "Order Promising Line Source Type"; var CrntSourceID: Code[20]; var AvailabilityMgt: Codeunit AvailabilityManagement)
    var
        ServiceHeader: Record "Service Header";
    begin
        if CrntSourceType = OrderPromisingLine."Source Type"::"Service Order" then begin
            ServiceHeader.Get(ServiceHeader."Document Type"::Order, OrderPromisingLine.GetRangeMin("Source ID"));
            AvailabilityMgt.SetSourceRecord(OrderPromisingLine, ServiceHeader);
            CrntSourceType := CrntSourceType::"Service Order";
            CrntSourceID := ServiceHeader."No.";
        end;
    end;

    // Codeunit "Calc. Item Availability"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetDocumentEntries', '', false, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    begin
        TryGetServOrderDemandEntries(InvtEventBuf, Item, sender);
    end;

    local procedure TryGetServOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceLine: Record "Service Line";
    begin
        if not ServiceLine.ReadPermission then
            exit;

        if ServiceLine.FindLinesWithItemToPlan(Item) then
            repeat
                TransferFromServiceNeed(InvtEventBuf, ServiceLine);
                sender.InsertEntry(InvtEventBuf);
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetSourceReferences', '', false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordId; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceRefNo: Integer; var IsHandled: Boolean; RecRef: RecordRef)
    var
        ServiceLine: Record "Service Line";
    begin
        if RecRef.Number = Database::"Service Line" then begin
            RecRef.SetTable(ServiceLine);
            SourceType := Database::"Service Line";
            SourceSubtype := ServiceLine."Document Type".AsInteger();
            SourceID := ServiceLine."Document No.";
            SourceRefNo := ServiceLine."Line No.";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterShowDocument', '', false, false)]
    local procedure OnAfterShowDocument(RecordID: RecordId; RecRef: RecordRef; var IsHandled: Boolean)
    var
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case RecordID.TableNo() of
            Database::"Service Shipment Header":
                begin
                    RecRef.SetTable(ServShptHeader);
                    PAGE.RunModal(Page::"Posted Service Shipment", ServShptHeader);
                    IsHandled := true;
                end;
            Database::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServInvHeader);
                    PAGE.RunModal(Page::"Posted Service Invoice", ServInvHeader);
                    IsHandled := true;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServCrMemoHeader);
                    PAGE.RunModal(Page::"Posted Service Credit Memo", ServCrMemoHeader);
                    IsHandled := true;
                end;
        end;
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnServiceOrder(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnServiceOrder(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Service Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromServLine(var ServLine: Record "Service Line"; AvailabilityType: Enum "Item Availability Type")
    var
        ServHeader: Record "Service Header";
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        ServHeader.Get(ServLine."Document Type", ServLine."Document No.");
        ServLine.TestField(Type, ServLine.Type::Item);
        ServLine.TestField("No.");
        Item.Reset();
        Item.Get(ServLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, ServLine."Location Code", ServLine."Variant Code", ServHeader."Response Date");

        OnBeforeShowItemAvailFromServLine(Item, ServLine);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromServLine(Item, ServLine);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(ServHeader.FieldCaption("Response Date")), ServHeader."Response Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(ServLine.FieldCaption(ServLine."Variant Code")), ServLine."Variant Code", NewVariantCode) then
                    ServLine.Validate(ServLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, GetFieldCaption(ServLine.FieldCaption(ServLine."Location Code")), ServLine."Location Code", NewLocationCode) then
                    ServLine.Validate(ServLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(ServHeader.FieldCaption("Response Date")), ServHeader."Response Date", NewDate, false);
            AvailabilityType::BOM:
                ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, GetFieldCaption(ServHeader.FieldCaption("Response Date")), ServHeader."Response Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(ServLine.FieldCaption(ServLine."Unit of Measure Code")), ServLine."Unit of Measure Code", NewUnitOfMeasureCode)
                then
                    ServLine.Validate(ServLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure GetFieldCaption(FieldCaption: Text): Text[80]
    begin
        exit(CopyStr(FieldCaption, 1, 80));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromServLine(var Item: Record Item; var ServLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;

    procedure ShowServiceLines(var Item: Record Item)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.FindLinesWithItemToPlan(Item);
        Page.Run(0, ServiceLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields("Qty. on Service Order");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean)
    begin
        if SourceType = DATABASE::"Service Line" then begin
            TransferServiceLine(InventoryEventBuffer, InventoryPageData, SourceSubtype, SourceID);
            IsHandled := true;
        end;
    end;

    local procedure TransferServiceLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ServHeader: Record "Service Header";
        RecRef: RecordRef;
    begin
        ServHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ServHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ServHeader."No.";
        InventoryPageData.Type := InventoryPageData.Type::Service;
        InventoryPageData.Description := ServHeader."Ship-to Name";
        InventoryPageData.Source := StrSubstNo(ServiceDocumentTxt, Format(ServHeader."Document Type"));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;


    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Service Line", Item.FieldNo("Qty. on Service Order"),
                    ServiceLine.TableCaption(), Item."Qty. on Service Order", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        ServiceLine: Record "Service Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Service Line":
                begin
                    ServiceLine.FindLinesWithItemToPlan(Item);
                    Page.RunModal(0, ServiceLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromServiceNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; ServiceLine: Record "Service Line")
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        RecRef: RecordRef;
        RemQty: Decimal;
    begin
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(ServiceLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := ServiceLine."No.";
        InventoryEventBuffer."Variant Code" := ServiceLine."Variant Code";
        InventoryEventBuffer."Location Code" := ServiceLine."Location Code";
        InventoryEventBuffer."Availability Date" := ServiceLine."Needed by Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Service;
        ServiceLineReserve.ReservQuantity(ServiceLine, RemQty, InventoryEventBuffer."Remaining Quantity (Base)");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -ServiceLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromServiceNeed(InventoryEventBuffer, ServiceLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromServiceNeed(InventoryEventBuffer, ServiceLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServiceNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;

    // Codeunit "Available to Promise"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalculateAvailability', '', false, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var sender: Codeunit "Available to Promise")
    begin
        UpdateServOrderAvail(AvailabilityAtDate, Item, sender);
    end;

    local procedure UpdateServOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var AvailableToPromise: Codeunit "Available to Promise")
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServOrderAvail(AvailabilityAtDate, Item, IsHandled);
#if not CLEAN25
        AvailableToPromise.RunOnBeforeUpdateServOrderAvail(AvailabilityAtDate, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if ServiceLine.FindLinesWithItemToPlan(Item) then
            repeat
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateGrossRequirement(
                    AvailabilityAtDate, ServiceLine."Needed by Date", ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)");
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetServiceHeaderOnAfterFilterServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcQtyOnServiceOrder', '', false, false)]
    local procedure OnCalcQtyOnServiceOrder(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Qty. on Service Order");
        Result := Item."Qty. on Service Order";
    end;
}
