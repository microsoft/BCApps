// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000973 "Purch. Availability Mgt."
{
    var
        PurchaseTxt: Label 'Purchase';
        PurchaseDocumentTxt: Label 'Purchase %1', Comment = '%1 - document type';
        UnsupportedEntitySourceErr: Label 'Unsupported Entity Source Type = %1, Source Subtype = %2.', Comment = '%1 = source type, %2 = source subtype';

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        if AvailabilityCalcOverview."Source Type" = Database::"Purchase Line" then
            Text := PurchaseTxt;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.FilterLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order");
        if PurchLine.FindFirst() then
            repeat
                PurchLine.SetRange("Location Code", PurchLine."Location Code");
                PurchLine.SetRange("Variant Code", PurchLine."Variant Code");
                PurchLine.SetRange("Expected Receipt Date", PurchLine."Expected Receipt Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code");

                PurchLine.FindLast();
                PurchLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                PurchLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                PurchLine.SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
            until PurchLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyDates', '', false, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.FilterLinesWithItemToPlan(Item, PurchLine."Document Type"::Order);
        if PurchLine.FindFirst() then
            repeat
                PurchLine.SetRange("Location Code", PurchLine."Location Code");
                PurchLine.SetRange("Variant Code", PurchLine."Variant Code");
                PurchLine.SetRange("Expected Receipt Date", PurchLine."Expected Receipt Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code");

                PurchLine.FindLast();
                PurchLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                PurchLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                PurchLine.SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
            until PurchLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order") then
            repeat
                PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                PurchLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code",
                    -PurchLine."Outstanding Qty. (Base)", -PurchLine."Reserved Qty. (Base)",
                    Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchHeader."Buy-from Vendor Name",
                    Enum::"Demand Order Source Type"::"All Demands");
            until PurchLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyEntries', '', false, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order) then
            repeat
                PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                PurchLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Supply, PurchLine."Expected Receipt Date", PurchLine."Location Code", PurchLine."Variant Code",
                    PurchLine."Outstanding Qty. (Base)", PurchLine."Reserved Qty. (Base)",
                    Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchHeader."Buy-from Vendor Name",
                    Enum::"Demand Order Source Type"::"All Demands");
            until PurchLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Exists := Exists or PurchaseLine.LinesWithItemToPlanExist(Item, "Purchase Document Type"::"Return Order");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnSupplyExist', '', false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Exists := Exists or PurchaseLine.LinesWithItemToPlanExist(Item, "Purchase Document Type"::Order);
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnPurchReturn(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnPurchOrder(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnPurchReqReceipt(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnPurchReturn(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupPlannedOrderReceipt', '', false, false)]
    local procedure OnLookupPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnPurchReqReceipt(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupScheduledReceipt', '', false, false)]
    local procedure OnLookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnPurchOrder(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnPurchReturn(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Purchase Line",
            Format(ReservationEntry."Source Subtype"::"5"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPurchOrder(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Purchase Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPurchReqReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Requisition Line",
            Format(ReservationEntry."Source Subtype"::"0"),
            Format(ReservationEntry."Reservation Status"::Prospect),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromPurchLine(var PurchLine: Record "Purchase Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
        IsHandled: Boolean;
    begin
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("No.");
        Item.Reset();
        Item.Get(PurchLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, PurchLine."Location Code", PurchLine."Variant Code", PurchLine."Expected Receipt Date");

        IsHandled := false;
        OnBeforeShowItemAvailFromPurchLine(Item, PurchLine, IsHandled, AvailabilityType);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromPurchLine(Item, PurchLine, IsHandled, AvailabilityType);
#endif
        if IsHandled then
            exit;

        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Expected Receipt Date")), PurchLine."Expected Receipt Date", NewDate) then
                    PurchLine.Validate(PurchLine."Expected Receipt Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Variant Code")), PurchLine."Variant Code", NewVariantCode) then
                    PurchLine.Validate(PurchLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Location Code")), PurchLine."Location Code", NewLocationCode) then
                    PurchLine.Validate(PurchLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Expected Receipt Date")), PurchLine."Expected Receipt Date", NewDate, false) then
                    PurchLine.Validate(PurchLine."Expected Receipt Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Expected Receipt Date")), PurchLine."Expected Receipt Date", NewDate) then
                    PurchLine.Validate(PurchLine."Expected Receipt Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(PurchLine.FieldCaption(PurchLine."Unit of Measure Code")), PurchLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    PurchLine.Validate(PurchLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure GetFieldCaption(FieldCaption: Text): Text[80]
    begin
        exit(CopyStr(FieldCaption, 1, 80));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPurchLine(var Item: Record Item; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

    procedure ShowPurchLines(var Item: Record Item)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order);
        PAGE.Run(0, PurchLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields(
            "Qty. on Purch. Order",
            "Qty. on Purch. Return");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean)
    begin
        if SourceType = DATABASE::"Purchase Line" then begin
            TransferPurchaseLine(InventoryEventBuffer, InventoryPageData, SourceType, SourceSubtype, SourceID);
            IsHandled := true;
        end;
    end;

    local procedure TransferPurchaseLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        PurchHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(PurchHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData.Description := PurchHeader."Buy-from Vendor Name";
        InventoryPageData.Source := StrSubstNo(PurchaseDocumentTxt, Format(PurchHeader."Document Type"));
        InventoryPageData."Document No." := PurchHeader."No.";
        case "Purchase Document Type".FromInteger(SourceSubtype) of
            "Purchase Document Type"::Order,
            "Purchase Document Type"::Invoice,
            "Purchase Document Type"::"Credit Memo":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::Purchase;
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            "Purchase Document Type"::"Return Order":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::"Purch. Return";
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Purchase Line", 0,
                    PurchaseLine.TableCaption(), Item."Qty. on Purch. Return", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Scheduled Order Receipt":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Purchase Line", Item.FieldNo("Qty. on Purch. Order"),
                    PurchaseLine.TableCaption(), Item."Qty. on Purch. Order", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        PurchaseLine: Record "Purchase Line";
#if not CLEAN25
        ItemAvailabilityLineList: page "Item Availability Line List";
#endif
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Purchase Line":
                begin
                    PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
                    if ItemAvailabilityLine.QuerySource > 0 then
                        PurchaseLine.FindLinesWithItemToPlan(Item, PurchaseLine."Document Type"::Order)
                    else
                        PurchaseLine.FindLinesWithItemToPlan(Item, PurchaseLine."Document Type"::"Return Order");
                    PurchaseLine.SetRange("Drop Shipment", false);
                    OnLookupEntriesOnAfterPurchLineSetFilters(Item, PurchaseLine);
#if not CLEAN25
                    ItemAvailabilityLineList.RunOnLookupEntriesOnAfterPurchLineSetFilters(Item, PurchaseLine);
#endif
                    PAGE.RunModal(0, PurchaseLine);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupEntriesOnAfterPurchLineSetFilters(var Item: Record Item; var PurchLine: Record "Purchase Line")
    begin
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromPurchase(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        RecRef: RecordRef;
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(PurchaseLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := PurchaseLine."No.";
        InventoryEventBuffer."Variant Code" := PurchaseLine."Variant Code";
        InventoryEventBuffer."Location Code" := PurchaseLine."Location Code";
        InventoryEventBuffer."Availability Date" := PurchaseLine."Expected Receipt Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Purchase;
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -PurchLineReserve.ReservQuantity(PurchaseLine);
        InventoryEventBuffer."Reserved Quantity (Base)" := PurchaseLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromPurchase(InventoryEventBuffer, PurchaseLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromPurchase(InventoryEventBuffer, PurchaseLine);
#endif
    end;

    procedure TransferFromPurchReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        RecRef: RecordRef;
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(PurchaseLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := PurchaseLine."No.";
        InventoryEventBuffer."Variant Code" := PurchaseLine."Variant Code";
        InventoryEventBuffer."Location Code" := PurchaseLine."Location Code";
        InventoryEventBuffer."Availability Date" := PurchaseLine."Expected Receipt Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Purchase;
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -PurchLineReserve.ReservQuantity(PurchaseLine);
        InventoryEventBuffer."Reserved Quantity (Base)" := PurchaseLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromPurchReturn(InventoryEventBuffer, PurchaseLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromPurchReturn(InventoryEventBuffer, PurchaseLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchase(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    // Codeunit "Available to Promise"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalculateAvailability', '', false, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var sender: Codeunit "Available to Promise")
    begin
        UpdatePurchOrderAvail(AvailabilityAtDate, Item, sender);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Purchase Line", 'r')]
    local procedure UpdatePurchOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var AvailableToPromise: Codeunit "Available to Promise")
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchOrderAvail(AvailabilityAtDate, Item, IsHandled);
#if not CLEAN25
        AvailableToPromise.RunOnBeforeUpdatePurchOrderAvail(AvailabilityAtDate, Item, IsHandled);
#endif
        if PurchaseLine.FindLinesWithItemToPlan(Item, PurchaseLine."Document Type"::Order) then
            repeat
                PurchaseLine.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateScheduledReceipt(
                    AvailabilityAtDate, PurchaseLine."Expected Receipt Date", PurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Reserved Qty. (Base)");
            until PurchaseLine.Next() = 0;

        if PurchaseLine.FindLinesWithItemToPlan(Item, PurchaseLine."Document Type"::"Return Order") then
            repeat
                PurchaseLine.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateGrossRequirement(
                    AvailabilityAtDate, PurchaseLine."Expected Receipt Date", PurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Reserved Qty. (Base)")
            until PurchaseLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
}
