// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000874 "Assembly Availability Mgt."
{
    var
        AssemblyTxt: Label 'Assembly';
        AssemblyOrderTxt: Label 'Assembly Order %1', Comment = '%1 - document type';
        AssemblyComponentTxt: Label 'Assembly Component %1', Comment = '%1 - document type';
#pragma warning disable AA0074
        Text012: Label 'Do you want to change %1 from %2 to %3?', Comment = '%1=FieldCaption, %2=OldDate, %3=NewDate';
#pragma warning restore AA0074

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnLookupDemandNo', '', false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text);
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrders: Page "Assembly Orders";
    begin
        if DemandType = DemandType::"Production Demand" then begin
            AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
            AssemblyOrders.SetTableView(AssemblyHeader);
            AssemblyOrders.LookupMode := true;
            if AssemblyOrders.RunModal() = ACTION::LookupOK then begin
                AssemblyOrders.GetRecord(AssemblyHeader);
                Text := AssemblyHeader."No.";
                Result := true;
            end;
            Result := false;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        case AvailabilityCalcOverview."Source Type" of
            Database::"Assembly Header",
            Database::"Assembly Line":
                Text := AssemblyTxt;
        end;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetItemToPlanFilters(Item, AssemblyLine."Document Type"::Order);
        if AssemblyLine.FindFirst() then
            repeat
                AssemblyLine.SetRange("Location Code", AssemblyLine."Location Code");
                AssemblyLine.SetRange("Variant Code", AssemblyLine."Variant Code");
                AssemblyLine.SetRange("Due Date", AssemblyLine."Due Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  AssemblyLine."Due Date", AssemblyLine."Location Code", AssemblyLine."Variant Code");

                AssemblyLine.FindLast();
                AssemblyLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                AssemblyLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                AssemblyLine.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until AssemblyLine.Next() = 0;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyDates', '', false, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetItemToPlanFilters(Item, AssemblyHeader."Document Type"::Order);
        if AssemblyHeader.FindFirst() then
            repeat
                AssemblyHeader.SetRange("Location Code", AssemblyHeader."Location Code");
                AssemblyHeader.SetRange("Variant Code", AssemblyHeader."Variant Code");
                AssemblyHeader.SetRange("Due Date", AssemblyHeader."Due Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  AssemblyHeader."Due Date", AssemblyHeader."Location Code", AssemblyHeader."Variant Code");

                AssemblyHeader.FindLast();
                AssemblyHeader.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                AssemblyHeader.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                AssemblyHeader.SetFilter("Due Date", Item.GetFilter("Date Filter"));
            until AssemblyHeader.Next() = 0;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        if AsmLine.FindItemToPlanLines(Item, AsmLine."Document Type"::Order) then
            repeat
                AsmHeader.Get(AsmLine."Document Type", AsmLine."Document No.");
                AsmLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, AsmLine."Due Date", AsmLine."Location Code", AsmLine."Variant Code",
                    -AsmLine."Remaining Quantity (Base)", -AsmLine."Reserved Qty. (Base)",
                    Database::"Assembly Line", AsmLine."Document Type".AsInteger(), AsmLine."Document No.", AsmHeader.Description,
                    "Demand Order Source Type"::"Assembly Demand");
            until AsmLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyEntries', '', false, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order) then
            repeat
                AssemblyHeader.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Supply, AssemblyHeader."Due Date", AssemblyHeader."Location Code", AssemblyHeader."Variant Code",
                    AssemblyHeader."Remaining Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)",
                    Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", AssemblyHeader.Description,
                    Enum::"Demand Order Source Type"::"All Demands");
            until AssemblyHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnCheckItemInRange', '', false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if DemandType = DemandType::"Assembly Demand" then
            if AssemblyLine.ItemToPlanLinesExist(Item, AssemblyLine."Document Type"::Order) then
                if DemandNo <> '' then begin
                    AssemblyLine.SetRange("Document No.", DemandNo);
                    Found := not AssemblyLine.IsEmpty();
                end else
                    Found := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        Exists := Exists or AssemblyLine.ItemToPlanLinesExist(Item, AssemblyLine."Document Type"::Order);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnSupplyExist', '', false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    var
        AsmHeader: Record "Assembly Header";
    begin
        Exists := Exists or AsmHeader.ItemToPlanLinesExist(Item, AsmHeader."Document Type"::Order);
    end;

    // Codeunit "Calc. Item Availability"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetDocumentEntries', '', false, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    begin
        TryGetAsmOrderDemandEntries(InvtEventBuf, Item, sender);
        TryGetAsmOrderSupllyEntries(InvtEventBuf, Item, sender);
    end;

    local procedure TryGetAsmOrderDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        AsmLine: Record "Assembly Line";
    begin
        if not AsmLine.ReadPermission then
            exit;

        if AsmLine.FindItemToPlanLines(Item, AsmLine."Document Type"::Order) then
            repeat
                TransferFromAsmOrderLine(InvtEventBuf, AsmLine);
                sender.InsertEntry(InvtEventBuf);
            until AsmLine.Next() = 0;
    end;

    local procedure TryGetAsmOrderSupllyEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        AsmHeader: Record "Assembly Header";
    begin
        if not AsmHeader.ReadPermission then
            exit;

        if AsmHeader.FindItemToPlanLines(Item, AsmHeader."Document Type"::Order) then
            repeat
                TransferFromAsmOrder(InvtEventBuf, AsmHeader);
                sender.InsertEntry(InvtEventBuf);
            until AsmHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetSourceReferences', '', false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordId; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceRefNo: Integer; var IsHandled: Boolean; RecRef: RecordRef)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        case RecRef.Number of
            Database::"Assembly Header":
                begin
                    RecRef.SetTable(AssemblyHeader);
                    SourceType := Database::"Assembly Header";
                    SourceSubtype := AssemblyHeader."Document Type".AsInteger();
                    SourceID := AssemblyHeader."No.";
                    IsHandled := true;
                end;
            Database::"Assembly Line":
                begin
                    RecRef.SetTable(AssemblyLine);
                    SourceType := Database::"Assembly Line";
                    SourceSubtype := AssemblyLine."Document Type".AsInteger();
                    SourceID := AssemblyLine."Document No.";
                    SourceRefNo := AssemblyLine."Line No.";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterShowDocument', '', false, false)]
    local procedure OnAfterShowDocument(RecordID: RecordId; RecRef: RecordRef; var IsHandled: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        case RecordID.TableNo() of
            Database::"Assembly Header":
                begin
                    RecRef.SetTable(AssemblyHeader);
                    PAGE.RunModal(Page::"Assembly Order", AssemblyHeader);
                    IsHandled := true;
                end;
            Database::"Assembly Line":
                begin
                    RecRef.SetTable(AssemblyLine);
                    AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
                    PAGE.RunModal(Page::"Assembly Order", AssemblyHeader);
                    IsHandled := true;
                end
        end;
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnAssemComp(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnAssemblyOrder(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnAssemComp(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupScheduledReceipt', '', false, false)]
    local procedure OnLookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnAssemblyOrder(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnAssemblyOrder(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Assembly Header",
            Format(ReservationEntry."Source Subtype"::"1"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnAssemComp(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Assembly Line",
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

    procedure ShowItemAvailabilityFromAsmHeader(var AsmHeader: Record "Assembly Header"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        AsmHeader.TestField("Item No.");
        Item.Reset();
        Item.Get(AsmHeader."Item No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, AsmHeader."Location Code", AsmHeader."Variant Code", AsmHeader."Due Date");

        OnBeforeShowItemAvailFromAsmHeader(Item, AsmHeader);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromAsmHeader(Item, AsmHeader);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(
                    Item, AsmHeader.FieldCaption(AsmHeader."Due Date"), AsmHeader."Due Date", NewDate) then
                    AsmHeader.Validate(AsmHeader."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(
                    Item, AsmHeader.FieldCaption(AsmHeader."Variant Code"), AsmHeader."Variant Code", NewVariantCode) then
                    AsmHeader.Validate(AsmHeader."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, AsmHeader.FieldCaption(AsmHeader."Location Code"), AsmHeader."Location Code", NewLocationCode) then
                    AsmHeader.Validate(AsmHeader."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, AsmHeader.FieldCaption(AsmHeader."Due Date"), AsmHeader."Due Date", NewDate, false) then
                    AsmHeader.Validate(AsmHeader."Due Date", NewDate);
            AvailabilityType::BOM:
                if ShowCustomAsmItemAvailByBOMLevel(AsmHeader, AsmHeader.FieldCaption(AsmHeader."Due Date"), AsmHeader."Due Date", NewDate) then
                    AsmHeader.Validate(AsmHeader."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, AsmHeader.FieldCaption(AsmHeader."Unit of Measure Code"), AsmHeader."Unit of Measure Code", NewUnitOfMeasureCode) then
                    AsmHeader.Validate(AsmHeader."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure ShowCustomAsmItemAvailByBOMLevel(var AsmHeader: Record "Assembly Header"; FieldCaption: Text; OldDate: Date; var NewDate: Date): Boolean
    var
        ItemAvailByBOMLevel: Page "Item Availability by BOM Level";
    begin
        Clear(ItemAvailByBOMLevel);
        ItemAvailByBOMLevel.InitSource(AsmHeader, "BOM Structure Show By"::Assembly);
        ItemAvailByBOMLevel.InitDate(OldDate);
        if FieldCaption <> '' then
            ItemAvailByBOMLevel.LookupMode(true);
        if ItemAvailByBOMLevel.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByBOMLevel.GetSelectedDate();
            if OldDate <> NewDate then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure ShowItemAvailabilityFromAsmLine(var AsmLine: Record "Assembly Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        AsmLine.TestField(Type, AsmLine.Type::Item);
        AsmLine.TestField("No.");
        Item.Reset();
        Item.Get(AsmLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, AsmLine."Location Code", AsmLine."Variant Code", AsmLine."Due Date");

        OnBeforeShowItemAvailFromAsmLine(Item, AsmLine);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromAsmLine(Item, AsmLine);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(
                    Item, AsmLine.FieldCaption(AsmLine."Due Date"), AsmLine."Due Date", NewDate) then
                    AsmLine.Validate(AsmLine."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(
                    Item, AsmLine.FieldCaption(AsmLine."Variant Code"), AsmLine."Variant Code", NewVariantCode) then
                    AsmLine.Validate(AsmLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(
                    Item, AsmLine.FieldCaption(AsmLine."Location Code"), AsmLine."Location Code", NewLocationCode) then
                    AsmLine.Validate(AsmLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(
                    Item, AsmLine.FieldCaption(AsmLine."Due Date"), AsmLine."Due Date", NewDate, false) then
                    AsmLine.Validate(AsmLine."Due Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(
                    Item, AsmLine.FieldCaption(AsmLine."Due Date"), AsmLine."Due Date", NewDate) then
                    AsmLine.Validate(AsmLine."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(
                    Item, AsmLine.FieldCaption(AsmLine."Unit of Measure Code"), AsmLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    AsmLine.Validate(AsmLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmHeader(var Item: Record Item; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmLine(var Item: Record Item; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    procedure ShowAsmOrders(var Item: Record Item)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
        PAGE.Run(0, AssemblyHeader);
    end;

    procedure ShowAsmCompLines(var Item: Record Item)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.FindItemToPlanLines(Item, AssemblyLine."Document Type"::Order);
        PAGE.Run(0, AssemblyLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields(
            "Qty. on Assembly Order",
            "Qty. on Asm. Component");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean; SourceRefNo: Integer)
    begin
        case SourceType of
            DATABASE::"Assembly Header":
                begin
                    TransferAssemblyHeader(InventoryEventBuffer, InventoryPageData, SourceSubtype, SourceID);
                    IsHandled := true;
                end;
            DATABASE::"Assembly Line":
                begin
                    TransferAssemblyLine(InventoryEventBuffer, InventoryPageData, SourceSubtype, SourceID, SourceRefNo);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure TransferAssemblyHeader(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
        RecRef: RecordRef;
    begin
        AssemblyHeader.Get(SourceSubtype, SourceID);
        RecRef.GetTable(AssemblyHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := AssemblyHeader."No.";
        InventoryPageData.Type := InventoryPageData.Type::"Assembly Order";
        InventoryPageData.Description := AssemblyHeader.Description;
        InventoryPageData.Source := StrSubstNo(AssemblyOrderTxt, Format(AssemblyHeader."Document Type"));
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferAssemblyLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        RecRef: RecordRef;
    begin
        AssemblyLine.Get(SourceSubtype, SourceID, SourceRefNo);
        RecRef.GetTable(AssemblyLine);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := AssemblyLine."Document No.";
        InventoryPageData."Line No." := AssemblyLine."Line No.";
        InventoryPageData.Type := InventoryPageData.Type::"Assembly Component";
        InventoryPageData.Description := AssemblyLine.Description;
        InventoryPageData.Source := StrSubstNo(AssemblyComponentTxt, Format(AssemblyLine."Document Type"));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Assembly Line", Item.FieldNo("Qty. on Asm. Component"),
                    AssemblyLine.TableCaption(), Item."Qty. on Asm. Component", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Scheduled Order Receipt":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Assembly Header", Item.FieldNo("Qty. on Assembly Order"),
                    AssemblyHeader.TableCaption(), Item."Qty. on Assembly Order", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Assembly Header":
                begin
                    AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
                    PAGE.RunModal(0, AssemblyHeader);
                end;
            Database::"Assembly Line":
                begin
                    AssemblyLine.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
                    PAGE.RunModal(0, AssemblyLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromAsmOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyHeader: Record "Assembly Header")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::"Assembly Order";
        RecRef.GetTable(AssemblyHeader);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := AssemblyHeader."Item No.";
        InventoryEventBuffer."Variant Code" := AssemblyHeader."Variant Code";
        InventoryEventBuffer."Location Code" := AssemblyHeader."Location Code";
        InventoryEventBuffer."Availability Date" := AssemblyHeader."Due Date";
        AssemblyHeader.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := AssemblyHeader."Remaining Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := AssemblyHeader."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromAsmOrder(InventoryEventBuffer, AssemblyHeader);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromAsmOrder(InventoryEventBuffer, AssemblyHeader);
#endif
    end;

    procedure TransferFromAsmOrderLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyLine: Record "Assembly Line")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::"Assembly Component";
        RecRef.GetTable(AssemblyLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := AssemblyLine."No.";
        InventoryEventBuffer."Variant Code" := AssemblyLine."Variant Code";
        InventoryEventBuffer."Location Code" := AssemblyLine."Location Code";
        InventoryEventBuffer."Availability Date" := AssemblyLine."Due Date";
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -AssemblyLine."Remaining Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -AssemblyLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromAsmOrderLine(InventoryEventBuffer, AssemblyLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromAsmOrderLine(InventoryEventBuffer, AssemblyLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrderLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyLine: Record "Assembly Line")
    begin
    end;
}
