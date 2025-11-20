// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000876 "Transfer Availability Mgt."
{
    var
        TransferTxt: Label 'Transfer';
        TransferDocumentTxt: Label 'Transfer %1', Comment = '%1 - location code';
        PlanRevertTxt: Label 'Plan Revert';
        UnsupportedEntitySourceErr: Label 'Unsupported Entity Source Type = %1, Source Subtype = %2.', Comment = '%1 = source type, %2 = source subtype';

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        case AvailabilityCalcOverview."Source Type" of
            Database::"Transfer Line":
                Text := TransferTxt;
        end;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.FilterLinesWithItemToPlan(Item, false, false);
        if TransLine.FindFirst() then
            repeat
                TransLine.SetRange("Transfer-from Code", TransLine."Transfer-from Code");
                TransLine.SetRange("Variant Code", TransLine."Variant Code");
                TransLine.SetRange("Shipment Date", TransLine."Shipment Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  TransLine."Shipment Date", TransLine."Transfer-from Code", TransLine."Variant Code");

                TransLine.FindLast();
                TransLine.SetFilter("Transfer-from Code", Item.GetFilter("Location Filter"));
                TransLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                TransLine.SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
            until TransLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyDates', '', false, false)]
    local procedure OnGetSupplyDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.FilterLinesWithItemToPlan(Item, true, false);
        if TransLine.FindFirst() then
            repeat
                TransLine.SetRange("Transfer-to Code", TransLine."Transfer-to Code");
                TransLine.SetRange("Variant Code", TransLine."Variant Code");
                TransLine.SetRange("Receipt Date", TransLine."Receipt Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  TransLine."Receipt Date", TransLine."Transfer-to Code", TransLine."Variant Code");

                TransLine.FindLast();
                TransLine.SetFilter("Transfer-to Code", Item.GetFilter("Location Filter"));
                TransLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                TransLine.SetFilter("Receipt Date", Item.GetFilter("Date Filter"));
            until TransLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        if TransLine.FindLinesWithItemToPlan(Item, false, false) then
            repeat
                TransHeader.Get(TransLine."Document No.");
                TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, TransLine."Shipment Date", TransLine."Transfer-from Code", TransLine."Variant Code",
                    -TransLine."Outstanding Qty. (Base)", -TransLine."Reserved Qty. Outbnd. (Base)",
                    Database::"Transfer Line", TransLine.Status, TransLine."Document No.", TransHeader."Transfer-to Name",
                    Enum::"Demand Order Source Type"::"All Demands");
            until TransLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetSupplyEntries', '', false, false)]
    local procedure OnGetSupplyEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        TransLine: Record "Transfer Line";
        TransHeader: Record "Transfer Header";
    begin
        if TransLine.FindLinesWithItemToPlan(Item, true, false) then
            repeat
                TransHeader.Get(TransLine."Document No.");
                TransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Supply, TransLine."Receipt Date", TransLine."Transfer-to Code", TransLine."Variant Code",
                    TransLine."Outstanding Qty. (Base)", TransLine."Reserved Qty. Inbnd. (Base)",
                    Database::"Transfer Line", TransLine.Status, TransLine."Document No.", TransHeader."Transfer-from Name",
                    Enum::"Demand Order Source Type"::"All Demands");
            until TransLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        Exists := Exists or TransferLine.LinesWithItemToPlanExist(Item, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnSupplyExist', '', false, false)]
    local procedure OnSupplyExist(var Item: Record Item; var Exists: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        Exists := Exists or TransferLine.LinesWithItemToPlanExist(Item, true);
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnTransOrdShipment(TempReservationEntry, sender);
        LookupReservationEntryForQtyOnTransOrderReceipt(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnTransOrdShipment(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupScheduledReceipt', '', false, false)]
    local procedure OnLookupScheduledReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnTransOrderReceipt(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnTransOrdShipment(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Transfer Line",
            Format(ReservationEntry."Source Subtype"::"0"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    local procedure LookupReservationEntryForQtyOnTransOrderReceipt(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Transfer Line",
            Format(ReservationEntry."Source Subtype"::"1"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Expected Receipt Date"
        );
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromTransLine(var TransLine: Record "Transfer Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        TransLine.TestField("Item No.");
        Item.Reset();
        Item.Get(TransLine."Item No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, TransLine."Transfer-from Code", TransLine."Variant Code", TransLine."Shipment Date");

        OnBeforeShowItemAvailabilityFromTransLine(Item, TransLine, AvailabilityType);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromTransLine(Item, TransLine, AvailabilityType);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, GetFieldCaption(TransLine.FieldCaption(TransLine."Shipment Date")), TransLine."Shipment Date", NewDate) then
                    TransLine.Validate("Shipment Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, GetFieldCaption(TransLine.FieldCaption(TransLine."Variant Code")), TransLine."Variant Code", NewVariantCode) then
                    TransLine.Validate("Variant Code", NewVariantCode);
            AvailabilityType::Location:
                ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, '', TransLine."Transfer-from Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, GetFieldCaption(TransLine.FieldCaption(TransLine."Shipment Date")), TransLine."Shipment Date", NewDate, false) then
                    TransLine.Validate("Shipment Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, GetFieldCaption(TransLine.FieldCaption(TransLine."Shipment Date")), TransLine."Shipment Date", NewDate) then
                    TransLine.Validate("Shipment Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, GetFieldCaption(TransLine.FieldCaption(TransLine."Unit of Measure Code")), TransLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    TransLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    local procedure GetFieldCaption(FieldCaption: Text): Text[80]
    begin
        exit(CopyStr(FieldCaption, 1, 80));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityFromTransLine(var Item: Record Item; var TransLine: Record "Transfer Line"; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

    procedure ShowTransLines(var Item: Record Item; What: Integer)
    var
        TransLine: Record "Transfer Line";
    begin
        case What of
            Item.FieldNo("Trans. Ord. Shipment (Qty.)"):
                TransLine.FindLinesWithItemToPlan(Item, false, false);
            Item.FieldNo("Qty. in Transit"),
          Item.FieldNo("Trans. Ord. Receipt (Qty.)"):
                TransLine.FindLinesWithItemToPlan(Item, true, false);
        end;
        PAGE.Run(0, TransLine);
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean; SourceRefNo: Integer)
    begin
        if SourceType = Database::"Transfer Line" then begin
            TransferTransLine(InventoryEventBuffer, InventoryPageData, SourceType, SourceSubtype, SourceID);
            IsHandled := true;
        end;
    end;

    local procedure TransferTransLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        TransHeader: Record "Transfer Header";
#if not CLEAN25
        CalcInventoryPageData: codeunit "Calc. Inventory Page Data";
#endif
        RecRef: RecordRef;
    begin
        TransHeader.Get(SourceID);
        RecRef.GetTable(TransHeader);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := TransHeader."No.";
        case SourceSubtype of
            0:
                case InventoryEventBuffer.Type of
                    InventoryEventBuffer.Type::Transfer:
                        begin
                            // Outbound Transfer
                            InventoryPageData.Type := InventoryPageData.Type::Transfer;
                            InventoryPageData.Description := TransHeader."Transfer-to Name";
                            InventoryPageData.Source := StrSubstNo(TransferDocumentTxt, Format(TransHeader."Transfer-to Code"));
                            InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
                            InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
                        end;
                    InventoryEventBuffer.Type::"Plan Revert":
                        begin
                            InventoryPageData.Type := InventoryPageData.Type::"Plan Revert";
                            InventoryPageData.Description := TransHeader."Transfer-to Name";
                            InventoryPageData.Source := PlanRevertTxt;
                            InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
                            InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
                        end;
                end;
            1:
                begin
                    // Inbound Transfer
                    InventoryPageData.Type := InventoryPageData.Type::Transfer;
                    InventoryPageData.Description := TransHeader."Transfer-from Name";
                    InventoryPageData.Source := StrSubstNo(TransferDocumentTxt, Format(TransHeader."Transfer-from Code"));
                    InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
                    InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
                end;
            else
                Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
        end;
        OnAfterTransferTransLine(InventoryPageData, TransHeader);
#if not CLEAN25
        CalcInventoryPageData.RunOnAfterTransferTransLine(InventoryPageData, TransHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTransLine(var InventoryPageData: Record "Inventory Page Data"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Transfer Line", Item.FieldNo("Trans. Ord. Shipment (Qty.)"),
                    Item.FieldCaption("Trans. Ord. Shipment (Qty.)"), Item."Trans. Ord. Shipment (Qty.)", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Scheduled Order Receipt":
                begin
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Transfer Line", Item.FieldNo("Qty. in Transit"),
                      Item.FieldCaption("Qty. in Transit"), Item."Qty. in Transit", QtyByUnitOfMeasure, Sign);
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Transfer Line", Item.FieldNo("Trans. Ord. Receipt (Qty.)"),
                      Item.FieldCaption("Trans. Ord. Receipt (Qty.)"), Item."Trans. Ord. Receipt (Qty.)", QtyByUnitOfMeasure, Sign);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        TransferLine: Record "Transfer Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Transfer Line":
                begin
                    case ItemAvailabilityLine.QuerySource of
                        Item.FieldNo("Trans. Ord. Shipment (Qty.)"):
                            TransferLine.FindLinesWithItemToPlan(Item, false, false);
                        Item.FieldNo("Trans. Ord. Receipt (Qty.)"), Item.FieldNo("Qty. in Transit"):
                            TransferLine.FindLinesWithItemToPlan(Item, true, false);
                    end;
                    PAGE.RunModal(0, TransferLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromOutboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransLine: Record "Transfer Line")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        RecRef.GetTable(TransLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := TransLine."Item No.";
        InventoryEventBuffer."Variant Code" := TransLine."Variant Code";
        InventoryEventBuffer."Location Code" := TransLine."Transfer-from Code";
        InventoryEventBuffer."Availability Date" := TransLine."Shipment Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Transfer;
        TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -TransLine."Outstanding Qty. (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -TransLine."Reserved Qty. Outbnd. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Transfer Direction" := InventoryEventBuffer."Transfer Direction"::Outbound;

        OnAfterTransferFromOutboundTransfer(InventoryEventBuffer, TransLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromOutboundTransfer(InventoryEventBuffer, TransLine);
#endif
    end;

    procedure TransferFromInboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransLine: Record "Transfer Line")
    var
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        RecRef.GetTable(TransLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := TransLine."Item No.";
        InventoryEventBuffer."Variant Code" := TransLine."Variant Code";
        InventoryEventBuffer."Location Code" := TransLine."Transfer-to Code";
        InventoryEventBuffer."Availability Date" := TransLine."Receipt Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Transfer;
        TransLine.CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Shipped (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := TransLine."Quantity (Base)" - TransLine."Qty. Received (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := TransLine."Reserved Qty. Inbnd. (Base)" + TransLine."Reserved Qty. Shipped (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Transfer Direction" := InventoryEventBuffer."Transfer Direction"::Inbound;

        OnAfterTransferFromInboundTransOrder(InventoryEventBuffer, TransLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromInboundTransOrder(InventoryEventBuffer, TransLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfer(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromInboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
}
