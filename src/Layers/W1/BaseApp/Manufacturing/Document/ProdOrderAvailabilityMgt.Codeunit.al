// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
#if not CLEAN27
using Microsoft.Inventory.Planning;
#endif
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Forecast;
#if not CLEAN27
using Microsoft.Manufacturing.Reports;
#endif
using Microsoft.Manufacturing.Setup;

codeunit 99000875 "Prod. Order Availability Mgt."
{
    var
#if not CLEAN27
        CalcItemAvailability: Codeunit "Calc. Item Availability";
#endif
        ProductionTxt: Label 'Production';
        ProdCompTxt: Label 'Prod. Comp.';
        ProdDocumentTxt: Label 'Production %1', Comment = '%1 - status';
        ProdComponentTxt: Label 'Component %1', Comment = '%1 - status';
        PlanRevertedTxt: Label 'Plan Reverted';
        ForecastSalesTxt: Label 'Forecast Sales';
        ForecastComponentTxt: Label 'Forecast Component';
        PlannedOrderReceiptTxt: Label '%1 Receipt', Comment = '%1 - table caption';
        PlannedOrderReleaseTxt: Label '%1 Release', Comment = '%1 - table caption';
        FirmPlannedOrderReceiptTxt: Label 'Firm planned %1', Comment = '%1 - table caption';
        ReleasedOrderReceiptTxt: Label 'Released %1', Comment = '%1 - table caption';
#pragma warning disable AA0074
        ChangeConfirmationQst: Label 'Do you want to change %1 from %2 to %3?', Comment = '%1=FieldCaption, %2=OldDate, %3=NewDate';
#pragma warning restore AA0074

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnLookupDemandNo', '', false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text);
    var
        ProdOrder: Record "Production Order";
        ProdOrderList: Page "Production Order List";
    begin
        if DemandType = DemandType::"Production Demand" then begin
            ProdOrder.SetRange(Status, ProdOrder.Status::Planned, ProdOrder.Status::Released);
            ProdOrderList.SetTableView(ProdOrder);
            ProdOrderList.LookupMode := true;
            if ProdOrderList.RunModal() = ACTION::LookupOK then begin
                ProdOrderList.GetRecord(ProdOrder);
                Text := ProdOrder."No.";
                Result := true;
            end;
            Result := false;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        case AvailabilityCalcOverview."Source Type" of
            DATABASE::"Prod. Order Line":
                Text := ProductionTxt;
            DATABASE::"Prod. Order Component":
                Text := ProdCompTxt;
        end;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.FilterLinesWithItemToPlan(Item, true);
        if ProdOrderComp.FindFirst() then
            repeat
                ProdOrderComp.SetRange("Location Code", ProdOrderComp."Location Code");
                ProdOrderComp.SetRange("Variant Code", ProdOrderComp."Variant Code");
                ProdOrderComp.SetRange("Due Date", ProdOrderComp."Due Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  ProdOrderComp."Due Date", ProdOrderComp."Location Code", ProdOrderComp."Variant Code");

                ProdOrderComp.FindLast();
                ProdOrderComp.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ProdOrderComp.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ProdOrderComp.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until ProdOrderComp.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyDates', '', false, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.FilterLinesWithItemToPlan(Item, true);
        if ProdOrderLine.FindFirst() then
            repeat
                ProdOrderLine.SetRange("Location Code", ProdOrderLine."Location Code");
                ProdOrderLine.SetRange("Variant Code", ProdOrderLine."Variant Code");
                ProdOrderLine.SetRange("Due Date", ProdOrderLine."Due Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  ProdOrderLine."Due Date", ProdOrderLine."Location Code", ProdOrderLine."Variant Code");

                ProdOrderLine.FindLast();
                ProdOrderLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                ProdOrderLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                ProdOrderLine.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until ProdOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrder: Record "Production Order";
    begin
        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrder.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.");
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, ProdOrderComp."Due Date", ProdOrderComp."Location Code", ProdOrderComp."Variant Code",
                    -ProdOrderComp."Remaining Qty. (Base)", -ProdOrderComp."Reserved Qty. (Base)",
                    Database::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrder.Description,
                    "Demand Order Source Type"::"Production Demand");
            until ProdOrderComp.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyEntries', '', false, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
    begin
        if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Supply, ProdOrderLine."Due Date", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                    ProdOrderLine."Remaining Qty. (Base)", ProdOrderLine."Reserved Qty. (Base)",
                    Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrder.Description,
                    "Demand Order Source Type"::"All Demands");
            until ProdOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnCheckItemInRange', '', false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if DemandType = DemandType::"Production Demand" then
            if ProdOrderComp.LinesWithItemToPlanExist(Item, true) then
                if DemandNo <> '' then begin
                    ProdOrderComp.SetRange("Prod. Order No.", DemandNo);
                    Found := not ProdOrderComp.IsEmpty();
                end else
                    Found := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        Exists := Exists or ProdOrderComp.LinesWithItemToPlanExist(Item, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnSupplyExist', '', false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        Exists := Exists or ProdOrderLine.LinesWithItemToPlanExist(Item, true);
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnCompLines(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnPlannedOrderReceipt(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnProdReceipt(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnCompLines(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupPlannedOrderReceipt', '', false, false)]
    local procedure OnLookupPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnPlannedOrderReceipt(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupScheduledReceipt', '', false, false)]
    local procedure OnLookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnProdReceipt(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnCompLines(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Component",
            AvailabilityInfoBuffer.GetRangeFilter(
                ReservationEntry."Source Subtype"::"1", ReservationEntry."Source Subtype"::"3"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnPlannedOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            Format(ReservationEntry."Reservation Status"::Prospect),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnProdReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Prod. Order Line",
            AvailabilityInfoBuffer.GetRangeFilter(
                ReservationEntry."Source Subtype"::"2", ReservationEntry."Source Subtype"::"3"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    // Codeunit "Calc. Item Availability"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetDocumentEntries', '', false, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    begin
        TryGetProdOrderCompDemandEntries(InvtEventBuf, Item, sender);
        TryGetProdOrderSupplyEntries(InvtEventBuf, Item, sender);
    end;

    local procedure TryGetProdOrderCompDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability"): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
    begin
        if not ProdOrderComp.ReadPermission then
            exit(false);

        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrderAvailabilityMgt.TransferFromProdComp(InvtEventBuf, ProdOrderComp);
                sender.InsertEntry(InvtEventBuf);
            until ProdOrderComp.Next() = 0;

        exit(true);
    end;

    local procedure TryGetProdOrderSupplyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability"): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
    begin
        if not ProdOrderLine.ReadPermission then
            exit(false);

        if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrderAvailabilityMgt.TransferFromProdOrder(InvtEventBuf, ProdOrderLine);
                sender.InsertEntry(InvtEventBuf);
            until ProdOrderLine.Next() = 0;

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterShowDocument', '', false, false)]
    local procedure OnAfterShowDocument(RecordID: RecordId; RecRef: RecordRef; var IsHandled: Boolean)
    var
        ProductionOrder: Record "Production Order";
    begin
        case RecordID.TableNo() of
            Database::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder);
                    RunProductionOrderPage(ProductionOrder);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure RunProductionOrderPage(var ProductionOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunProductionOrderPage(ProductionOrder, IsHandled);
#if not CLEAN27
        CalcItemAvailability.RunOnBeforeRunProductionOrderPage(ProductionOrder, IsHandled);
#endif
        if IsHandled then
            exit;

        case ProductionOrder.Status of
            ProductionOrder.Status::Planned:
                PAGE.RunModal(Page::"Planned Production Order", ProductionOrder);
            ProductionOrder.Status::"Firm Planned":
                PAGE.RunModal(Page::"Firm Planned Prod. Order", ProductionOrder);
            ProductionOrder.Status::Released:
                PAGE.RunModal(Page::"Released Production Order", ProductionOrder);
            ProductionOrder.Status::Finished:
                PAGE.RunModal(Page::"Finished Production Order", ProductionOrder);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetSourceReferences', '', false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordId; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceRefNo: Integer; var IsHandled: Boolean; RecRef: RecordRef; var SourceProdOrderLine: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        case RecRef.Number of
            Database::"Prod. Order Line":
                begin
                    RecRef.SetTable(ProdOrderLine);
                    SourceType := Database::"Prod. Order Line";
                    SourceSubtype := ProdOrderLine.Status.AsInteger();
                    SourceID := ProdOrderLine."Prod. Order No.";
                    SourceProdOrderLine := ProdOrderLine."Line No.";
                end;
            Database::"Prod. Order Component":
                begin
                    RecRef.SetTable(ProdOrderComp);
                    SourceType := Database::"Prod. Order Component";
                    SourceSubtype := ProdOrderComp.Status.AsInteger();
                    SourceID := ProdOrderComp."Prod. Order No.";
                    SourceProdOrderLine := ProdOrderComp."Prod. Order Line No.";
                    SourceRefNo := ProdOrderComp."Line No.";
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunProductionOrderPage(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnParentIsInPlanning', '', false, false)]
    local procedure OnParentIsInPlanning(InvtEventBuf: Record "Inventory Event Buffer"; var ParentActionMessage: Enum "Action Message Type"; var Result: Boolean)
    begin
        Result := ParentIsInPlanning(InvtEventBuf, ParentActionMessage);
    end;

    local procedure ParentIsInPlanning(InvtEventBuf: Record "Inventory Event Buffer"; var ParentActionMessage: Enum "Action Message Type"): Boolean
    var
        ReqLine: Record "Requisition Line";
        ProdOrderComp: Record "Prod. Order Component";
        RecRef: RecordRef;
        RecordID: RecordID;
    begin
        // Check if the parent of a component line is represented with a planning suggestion
        RecordID := InvtEventBuf."Source Line ID";
        RecRef := RecordID.GetRecord();
        RecRef.SetTable(ProdOrderComp);
        ReqLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        ReqLine.SetRange("Ref. Order Type", ReqLine."Ref. Order Type"::"Prod. Order");
        ReqLine.SetRange("Ref. Order Status", ProdOrderComp.Status);
        ReqLine.SetRange("Ref. Order No.", ProdOrderComp."Prod. Order No.");
        ReqLine.SetRange("Ref. Line No.", ProdOrderComp."Prod. Order Line No.");
        ReqLine.SetRange("Operation No.", '');
        OnParentIsInPlanningOnAfterReqLineSetFilters(ReqLine, ProdOrderComp);
#if not CLEAN27
        CalcItemAvailability.RunOnParentIsInPlanningOnAfterReqLineSetFilters(ReqLine, ProdOrderComp);
#endif
        if ReqLine.FindFirst() then begin
            ParentActionMessage := ReqLine."Action Message";
            exit(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnParentIsInPlanningOnAfterReqLineSetFilters(var RequisitionLine: Record "Requisition Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        ProdOrderLine.TestField("Item No.");
        Item.Reset();
        Item.Get(ProdOrderLine."Item No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, ProdOrderLine."Location Code", ProdOrderLine."Variant Code", ProdOrderLine."Due Date");

        OnBeforeShowItemAvailFromProdOrderLine(Item, ProdOrderLine);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromProdOrderLine(Item, ProdOrderLine);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Due Date")), ProdOrderLine."Due Date", NewDate) then
                    ProdOrderLine.Validate(ProdOrderLine."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Variant Code")), ProdOrderLine."Variant Code", NewVariantCode) then
                    ProdOrderLine.Validate(ProdOrderLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Location Code")), ProdOrderLine."Location Code", NewLocationCode) then
                    ProdOrderLine.Validate(ProdOrderLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Due Date")), ProdOrderLine."Due Date", NewDate, false) then
                    ProdOrderLine.Validate(ProdOrderLine."Due Date", NewDate);
            AvailabilityType::BOM:
                if ShowCustomProdItemAvailByBOMLevel(ProdOrderLine, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Due Date")), ProdOrderLine."Due Date", NewDate) then
                    ProdOrderLine.Validate(ProdOrderLine."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(ProdOrderLine.FieldCaption(ProdOrderLine."Unit of Measure Code")), ProdOrderLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    ProdOrderLine.Validate(ProdOrderLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure ShowCustomProdItemAvailByBOMLevel(var ProdOrderLine: Record "Prod. Order Line"; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    var
        ItemAvailByBOMLevel: Page "Item Availability by BOM Level";
    begin
        Clear(ItemAvailByBOMLevel);
        ItemAvailByBOMLevel.InitSource(ProdOrderLine, "BOM Structure Show By"::Production);
        ItemAvailByBOMLevel.InitDate(OldDate);
        if FieldCaption <> '' then
            ItemAvailByBOMLevel.LookupMode(true);
        if ItemAvailByBOMLevel.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByBOMLevel.GetSelectedDate();
            if OldDate <> NewDate then
                if Confirm(ChangeConfirmationQst, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailFromProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        ProdOrderComp.TestField("Item No.");
        Item.Reset();
        Item.Get(ProdOrderComp."Item No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, ProdOrderComp."Location Code", ProdOrderComp."Variant Code", ProdOrderComp."Due Date");

        OnBeforeShowItemAvailFromProdOrderComp(Item, ProdOrderComp);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromProdOrderComp(Item, ProdOrderComp);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Due Date")), ProdOrderComp."Due Date", NewDate) then
                    ProdOrderComp.Validate(ProdOrderComp."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Variant Code")), ProdOrderComp."Variant Code", NewVariantCode) then
                    ProdOrderComp.Validate(ProdOrderComp."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Location Code")), ProdOrderComp."Location Code", NewLocationCode) then
                    ProdOrderComp.Validate(ProdOrderComp."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Due Date")), ProdOrderComp."Due Date", NewDate, false) then
                    ProdOrderComp.Validate(ProdOrderComp."Due Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Due Date")), ProdOrderComp."Due Date", NewDate) then
                    ProdOrderComp.Validate(ProdOrderComp."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(ProdOrderComp.FieldCaption(ProdOrderComp."Unit of Measure Code")), ProdOrderComp."Unit of Measure Code", NewUnitOfMeasureCode) then
                    ProdOrderComp.Validate(ProdOrderComp."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderLine(var Item: Record Item; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderComp(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    local procedure GetFieldCaption(FieldCaption: Text): Text[80]
    begin
        exit(CopyStr(FieldCaption, 1, 80));
    end;

    procedure ShowSchedReceipt(var Item: Record Item)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.FindLinesWithItemToPlan(Item, true);
        PAGE.Run(0, ProdOrderLine);
    end;

    procedure ShowSchedNeed(var Item: Record Item)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.FindLinesWithItemToPlan(Item, true);
        PAGE.Run(0, ProdOrderComp);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields(
            "Planned Order Receipt (Qty.)",
            "FP Order Receipt (Qty.)",
            "Rel. Order Receipt (Qty.)",
            "Planned Order Release (Qty.)",
            "Scheduled Receipt (Qty.)",
            "Qty. on Component Lines");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean; SourceRefNo: Integer)
    begin
        case SourceType of
            DATABASE::"Prod. Order Line":
                begin
                    TransferProdOrderLine(InventoryEventBuffer, InventoryPageData, SourceSubtype, SourceID);
                    IsHandled := true;
                end;
            DATABASE::"Prod. Order Component":
                begin
                    TransferProdOrderComp(InventoryEventBuffer, InventoryPageData, SourceSubtype, SourceID);
                    IsHandled := true;
                end;
            DATABASE::"Production Forecast Entry":
                begin
                    TransferProdForecastEntry(InventoryEventBuffer, InventoryPageData, SourceRefNo);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure TransferProdOrderLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
        RecRef: RecordRef;
    begin
        ProdOrder.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ProdOrder);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdOrder."No.";
        InventoryPageData.Type := InventoryPageData.Type::Production;
        InventoryPageData.Description := ProdOrder.Description;
        InventoryPageData.Source := StrSubstNo(ProdDocumentTxt, Format(ProdOrder.Status));
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferProdOrderComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Integer; SourceID: Code[20])
    var
        ProdOrder: Record "Production Order";
#if not CLEAN25
        CalcInventoryPageData: Codeunit "Calc. Inventory Page Data";
#endif
        RecRef: RecordRef;
    begin
        ProdOrder.Get(SourceSubtype, SourceID);
        RecRef.GetTable(ProdOrder);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdOrder."No.";
        InventoryPageData.Description := ProdOrder.Description;
        case InventoryEventBuffer.Type of
            InventoryEventBuffer.Type::Component:
                begin
                    InventoryPageData.Type := InventoryPageData.Type::Component;
                    InventoryPageData.Source := StrSubstNo(ProdComponentTxt, Format(ProdOrder.Status));
                    InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            InventoryEventBuffer.Type::"Plan Revert":
                begin
                    InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                    InventoryPageData.Source := PlanRevertedTxt;
                    InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
                end;
        end;
        OnAfterTransferProdOrderComp(InventoryPageData, ProdOrder);
#if not CLEAN25
        CalcInventoryPageData.RunOnAfterTransferProdOrderComp(InventoryPageData, ProdOrder);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderComp(var InventoryPageData: Record "Inventory Page Data"; var ProductionOrder: Record "Production Order")
    begin
    end;

    local procedure TransferProdForecastEntry(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceRefNo: Integer)
    var
        ProdForecastName: Record "Production Forecast Name";
        ProdForecastEntry: Record "Production Forecast Entry";
        RecRef: RecordRef;
    begin
        ProdForecastEntry.Get(SourceRefNo);
        ProdForecastName.Get(ProdForecastEntry."Production Forecast Name");
        RecRef.GetTable(ProdForecastName);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ProdForecastName.Name;
        InventoryPageData.Type := InventoryPageData.Type::Forecast;
        InventoryPageData.Description := ProdForecastName.Description;
        if InventoryEventBuffer."Forecast Type" = InventoryEventBuffer."Forecast Type"::Sales then
            InventoryPageData.Source := ForecastSalesTxt
        else
            InventoryPageData.Source := ForecastComponentTxt;
        InventoryPageData.Forecast := InventoryEventBuffer."Orig. Quantity (Base)";
        InventoryPageData."Remaining Forecast" := InventoryEventBuffer."Remaining Quantity (Base)";
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Prod. Order Component", Item.FieldNo("Qty. on Component Lines"),
                    ProdOrderComp.TableCaption(), Item."Qty. on Component Lines", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Planned Order Receipt":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Prod. Order Line", Item.FieldNo("Planned Order Receipt (Qty.)"),
                    StrSubstNo(PlannedOrderReceiptTxt, ProdOrderLine.TableCaption()), Item."Planned Order Receipt (Qty.)", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Planned Order Release":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Prod. Order Line", Item.FieldNo("Planned Order Release (Qty.)"),
                    StrSubstNo(PlannedOrderReleaseTxt, ProdOrderLine.TableCaption()), Item."Planned Order Release (Qty.)", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Scheduled Order Receipt":
                begin
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Prod. Order Line",
                      Item.FieldNo("FP Order Receipt (Qty.)"),
                      StrSubstNo(FirmPlannedOrderReceiptTxt, ProdOrderLine.TableCaption()),
                      Item."FP Order Receipt (Qty.)", QtyByUnitOfMeasure, Sign);
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Prod. Order Line",
                      Item.FieldNo("Rel. Order Receipt (Qty.)"),
                      StrSubstNo(ReleasedOrderReceiptTxt, ProdOrderLine.TableCaption()),
                      Item."Rel. Order Receipt (Qty.)", QtyByUnitOfMeasure, Sign);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComp.FindLinesWithItemToPlan(Item, true);
                    PAGE.RunModal(0, ProdOrderComp);
                end;
            Database::"Prod. Order Line":
                begin
                    ProdOrderLine.Reset();
                    ProdOrderLine.SetCurrentKey(Status, "Item No.");
                    case ItemAvailabilityLine.QuerySource of
                        Item.FieldNo("Planned Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                        Item.FieldNo("Planned Order Release (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Starting Date");
                            end;
                        Item.FieldNo("FP Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                        Item.FieldNo("Rel. Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                    end;
                    ProdOrderLine.SetRange("Item No.", Item."No.");
                    Item.CopyFilter("Variant Filter", ProdOrderLine."Variant Code");
                    Item.CopyFilter("Location Filter", ProdOrderLine."Location Code");
                    Item.CopyFilter("Global Dimension 1 Filter", ProdOrderLine."Shortcut Dimension 1 Code");
                    Item.CopyFilter("Global Dimension 2 Filter", ProdOrderLine."Shortcut Dimension 2 Code");
                    Item.CopyFilter("Unit of Measure Filter", ProdOrderLine."Unit of Measure Code");
                    PAGE.RunModal(0, ProdOrderLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderComp: Record "Prod. Order Component")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        RecRef.GetTable(ProdOrderComp);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := ProdOrderComp."Item No.";
        InventoryEventBuffer."Variant Code" := ProdOrderComp."Variant Code";
        InventoryEventBuffer."Location Code" := ProdOrderComp."Location Code";
        InventoryEventBuffer."Availability Date" := ProdOrderComp."Due Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Component;
        ProdOrderComp.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -ProdOrderComp."Remaining Qty. (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -ProdOrderComp."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromProdComp(InventoryEventBuffer, ProdOrderComp);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromProdComp(InventoryEventBuffer, ProdOrderComp);
#endif
    end;

    procedure TransferFromProdOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderLine: Record "Prod. Order Line")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        RecRef.GetTable(ProdOrderLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := ProdOrderLine."Item No.";
        InventoryEventBuffer."Variant Code" := ProdOrderLine."Variant Code";
        InventoryEventBuffer."Location Code" := ProdOrderLine."Location Code";
        InventoryEventBuffer."Availability Date" := ProdOrderLine."Due Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Production;
        ProdOrderLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := ProdOrderLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromProdOrder(InventoryEventBuffer, ProdOrderLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromProdOrder(InventoryEventBuffer, ProdOrderLine);
#endif
    end;

#if not CLEAN27
    [Obsolete('Moved back to InventoryEventBuffer', '27.0')]
    procedure TransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record "Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean)
    begin
        TransferFromForecast(InventoryEventBuffer, ProdForecastEntry, UnconsumedQtyBase, ForecastOnLocation, false);
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved back to InventoryEventBuffer', '27.0')]
    procedure TransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record "Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean; ForecastOnVariant: Boolean)
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        RecRef.GetTable(ProdForecastEntry);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := ProdForecastEntry."Item No.";
        InventoryEventBuffer."Variant Code" := '';
        if ForecastOnLocation then
            InventoryEventBuffer."Location Code" := ProdForecastEntry."Location Code"
        else
            InventoryEventBuffer."Location Code" := '';
        if ForecastOnVariant then
            InventoryEventBuffer."Variant Code" := ProdForecastEntry."Variant Code"
        else
            InventoryEventBuffer."Variant Code" := '';
        InventoryEventBuffer."Availability Date" := ProdForecastEntry."Forecast Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Forecast;
        if ProdForecastEntry."Component Forecast" then
            InventoryEventBuffer."Forecast Type" := InventoryEventBuffer."Forecast Type"::Component
        else
            InventoryEventBuffer."Forecast Type" := InventoryEventBuffer."Forecast Type"::Sales;
        InventoryEventBuffer."Remaining Quantity (Base)" := -UnconsumedQtyBase;
        InventoryEventBuffer."Reserved Quantity (Base)" := 0;
        InventoryEventBuffer."Orig. Quantity (Base)" := -ProdForecastEntry."Forecast Quantity (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromForecast(InventoryEventBuffer, ProdForecastEntry);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

#if not CLEAN27
    [Obsolete('Moved back to InventoryEventBuffer', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record "Production Forecast Entry")
    begin
    end;
#endif

    // Codeunit "Available to Promise"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalculateAvailability', '', false, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var sender: Codeunit "Available to Promise")
    begin
        UpdateSchedRcptAvail(AvailabilityAtDate, Item, sender);
        UpdateSchedNeedAvail(AvailabilityAtDate, Item, sender);
    end;

    local procedure UpdateSchedRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var AvailableToPromise: Codeunit "Available to Promise")
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSchedRcptAvail(AvailabilityAtDate, Item, IsHandled);
#if not CLEAN25
        AvailableToPromise.RunOnBeforeUpdateSchedRcptAvail(AvailabilityAtDate, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateScheduledReceipt(
                    AvailabilityAtDate, ProdOrderLine."Due Date", ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)");
            until ProdOrderLine.Next() = 0;
    end;

    local procedure UpdateSchedNeedAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var AvailableToPromise: Codeunit "Available to Promise")
    var
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSchedNeedAvail(AvailabilityAtDate, Item, IsHandled);
#if not CLEAN25
        AvailableToPromise.RunOnBeforeUpdateSchedNeedAvail(AvailabilityAtDate, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateGrossRequirement(
                    AvailabilityAtDate, ProdOrderComp."Due Date", ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
            until ProdOrderComp.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSchedNeedAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSchedRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AvailabilityManagement", 'OnAfterCalcCapableToPromise', '', false, false)]
    local procedure OnAfterCalcCapableToPromise(OrderPromisingID: Code[20])
    begin
        ReassignRefOrderNos(OrderPromisingID);
    end;

    procedure ReassignRefOrderNos(OrderPromisingID: Code[20])
    var
        MfgSetup: Record "Manufacturing Setup";
        RequisitionLine: Record "Requisition Line";
        NoSeries: Codeunit "No. Series";
#if not CLEAN27
        CapableToPromise: Codeunit "Capable to Promise";
#endif
        NewRefOrderNo: Code[20];
        LastRefOrderNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReassignRefOrderNos(OrderPromisingID, IsHandled);
#if not CLEAN27
        CapableToPromise.RunOnBeforeReassignRefOrderNos(OrderPromisingID, IsHandled);
#endif
        if IsHandled then
            exit;

        RequisitionLine.SetCurrentKey("Ref. Order Type", "Ref. Order Status", "Ref. Order No.", "Ref. Line No.");
        RequisitionLine.SetRange("Order Promising ID", OrderPromisingID);
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.SetRange("Ref. Order Status", RequisitionLine."Ref. Order Status"::Planned);
        RequisitionLine.SetFilter("Ref. Order No.", '<>%1', '');
        if not RequisitionLine.FindLast() then
            exit;
        LastRefOrderNo := RequisitionLine."Ref. Order No.";

        MfgSetup.Get();
        MfgSetup.TestField("Planned Order Nos.");

        RequisitionLine.SetFilter("Ref. Order No.", '<>%1&<=%2', '', LastRefOrderNo);
        RequisitionLine.Find('-');
        repeat
            RequisitionLine.SetRange("Ref. Order No.", RequisitionLine."Ref. Order No.");
            RequisitionLine.FindLast();
            NewRefOrderNo := '';
            if not NoSeries.AreRelated(MfgSetup."Planned Order Nos.", RequisitionLine."No. Series") then
                RequisitionLine."No. Series" := MfgSetup."Planned Order Nos.";
            NewRefOrderNo := NoSeries.GetNextNo(RequisitionLine."No. Series", RequisitionLine."Due Date");
            RequisitionLine.ModifyAll("Ref. Order No.", NewRefOrderNo);
            OnReassignRefOrderNosOnAfterRequisitionLineModifyAll(RequisitionLine);
#if not CLEAN27
            CapableToPromise.RunOnReassignRefOrderNosOnAfterRequisitionLineModifyAll(RequisitionLine);
#endif
            RequisitionLine.SetFilter("Ref. Order No.", '<>%1&<=%2', '', LastRefOrderNo);
        until RequisitionLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReassignRefOrderNos(OrderPromisingID: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReassignRefOrderNosOnAfterRequisitionLineModifyAll(var RequisitionLine: Record "Requisition Line");
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcScheduledReceiptQty', '', false, false)]
    local procedure OnCalcScheduledReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Scheduled Receipt (Qty.)");
        Result := Item."Scheduled Receipt (Qty.)";
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcQtyOnComponentLines', '', false, false)]
    local procedure OnCalcQtyOnComponentLines(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Qty. on Component Lines");
        Result := Item."Qty. on Component Lines";
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcQtyOnProdOrder', '', false, false)]
    local procedure OnCalcQtyOnProdOrder(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Qty. on Prod. Order");
        Result := Item."Qty. on Prod. Order";
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcPlannedOrderReceiptQty', '', false, false)]
    local procedure OnCalcPlannedOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Planned Order Receipt (Qty.)");
        Result := Item."Planned Order Receipt (Qty.)";
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcFPOrderReceiptQty', '', false, false)]
    local procedure OnCalcFPOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("FP Order Receipt (Qty.)");
        Result := Item."FP Order Receipt (Qty.)";
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnCalcRelOrderReceiptQty', '', false, false)]
    local procedure OnCalcRelOrderReceiptQty(var Item: Record Item; var Result: Decimal)
    begin
        Item.CalcFields("Rel. Order Receipt (Qty.)");
        Result := Item."Rel. Order Receipt (Qty.)";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnCalcAllItemFieldsOnAfterItemCalcFields', '', false, false)]
    local procedure OnCalcAllItemFieldsOnAfterItemCalcFields(var Item: Record Item)
    begin
        Item.CalcFields(
          "Qty. on Component Lines",
          "Res. Qty. on Prod. Order Comp.",
          "Scheduled Receipt (Qty.)",
          "Reserved Qty. on Prod. Order");
    end;
#if not CLEAN27
    [EventSubscriber(ObjectType::Report, Report::"Planning Availability", 'OnRequisitionLineOnBeforeTempPlanningBufferInsert', '', false, false)]
    local procedure OnRequisitionLineOnBeforeTempPlanningBufferInsert(var TempPlanningBuffer: Record "Planning Buffer" temporary; RequisitionLine: Record "Requisition Line")
    begin
        TempPlanningBuffer."Document No." := RequisitionLine."Prod. Order No.";
    end;
#endif
}