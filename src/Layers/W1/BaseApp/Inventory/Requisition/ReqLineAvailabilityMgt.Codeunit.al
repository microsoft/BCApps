// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;

codeunit 99000879 "Req. Line Availability Mgt."
{
    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromReqLine(var ReqLine: Record "Requisition Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        ForecastName: Code[10];
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        ReqLine.TestField(Type, ReqLine.Type::Item);
        ReqLine.TestField("No.");
        Item.Reset();
        Item.Get(ReqLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, ReqLine."Location Code", ReqLine."Variant Code", ReqLine."Due Date");

        OnBeforeShowItemAvailabilityFromReqLine(Item, ReqLine, AvailabilityType);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromReqLine(Item, ReqLine, AvailabilityType);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, ReqLine.FieldCaption(ReqLine."Due Date"), ReqLine."Due Date", NewDate) then
                    ReqLine.Validate(ReqLine."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, ReqLine.FieldCaption(ReqLine."Variant Code"), ReqLine."Variant Code", NewVariantCode) then
                    ReqLine.Validate(ReqLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, ReqLine.FieldCaption(ReqLine."Location Code"), ReqLine."Location Code", NewLocationCode) then
                    ReqLine.Validate(ReqLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                begin
                    Item.SetRange("Date Filter");
                    ForecastName := '';
                    ReqLine.FindCurrForecastName(ForecastName);
                    ItemAvailabilityFormsMgt.SetForecastName(ForecastName);
                    if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, ReqLine.FieldCaption(ReqLine."Due Date"), ReqLine."Due Date", NewDate, true) then
                        ReqLine.Validate(ReqLine."Due Date", NewDate);
                end;
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, ReqLine.FieldCaption(ReqLine."Due Date"), ReqLine."Due Date", NewDate) then
                    ReqLine.Validate(ReqLine."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, ReqLine.FieldCaption(ReqLine."Unit of Measure Code"), ReqLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    ReqLine.Validate(ReqLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityFromReqLine(var Item: Record Item; var ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line"; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        ReqLine: Record "Requisition Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Planned Order Receipt":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Requisition Line", Item.FieldNo("Purch. Req. Receipt (Qty.)"),
                    ReqLine.TableCaption(), Item."Purch. Req. Receipt (Qty.)", QtyByUnitOfMeasure, Sign);
            AvailabilityType::"Planned Order Release":
                begin
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Requisition Line", Item.FieldNo("Purch. Req. Release (Qty.)"),
                      ReqLine.TableCaption(), Item."Purch. Req. Release (Qty.)", QtyByUnitOfMeasure, Sign);
                    ItemAvailabilityLine.InsertEntry(
                      Database::"Requisition Line", Item.FieldNo("Planning Release (Qty.)"),
                      ReqLine.TableCaption(), Item."Planning Release (Qty.)", QtyByUnitOfMeasure, Sign);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        ReqLine: Record "Requisition Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Requisition Line":
                begin
                    ReqLine.FindLinesWithItemToPlan(Item);
                    case ItemAvailabilityLine.QuerySource of
                        Item.FieldNo("Purch. Req. Receipt (Qty.)"):
                            Item.CopyFilter("Date Filter", ReqLine."Due Date");
                        Item.FieldNo("Purch. Req. Release (Qty.)"):
                            begin
                                Item.CopyFilter("Date Filter", ReqLine."Order Date");
                                ReqLine.SetFilter("Planning Line Origin", '%1|%2',
                                  ReqLine."Planning Line Origin"::" ", ReqLine."Planning Line Origin"::Planning);
                            end;
                    end;
                    PAGE.RunModal(0, ReqLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; PlngComp: Record "Planning Component")
    var
        ReqLine: Record "Requisition Line";
        RecRef: RecordRef;
    begin
        InventoryEventBuffer.Init();
        ReqLine.Get(PlngComp."Worksheet Template Name", PlngComp."Worksheet Batch Name", PlngComp."Worksheet Line No.");
        RecRef.GetTable(PlngComp);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := PlngComp."Item No.";
        InventoryEventBuffer."Variant Code" := PlngComp."Variant Code";
        InventoryEventBuffer."Location Code" := PlngComp."Location Code";
        InventoryEventBuffer."Availability Date" := PlngComp."Due Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Plan;
        PlngComp.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -PlngComp."Expected Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -PlngComp."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Action Message" := ReqLine."Action Message";
        InventoryEventBuffer."Ref. Order No." := ReqLine."Ref. Order No.";
        InventoryEventBuffer."Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");

        OnAfterTransferFromPlanProdComp(InventoryEventBuffer, PlngComp, ReqLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromPlanProdComp(InventoryEventBuffer, PlngComp, ReqLine);
#endif
    end;

    procedure TransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; ReqLine: Record "Requisition Line")
    var
        RecRef: RecordRef;
    begin
        if ReqLine.Type <> ReqLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(ReqLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := ReqLine."No.";
        InventoryEventBuffer."Variant Code" := ReqLine."Variant Code";
        InventoryEventBuffer."Location Code" := ReqLine."Transfer-from Code";
        InventoryEventBuffer."Availability Date" := ReqLine."Transfer Shipment Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Transfer;
        ReqLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -ReqLine."Quantity (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -ReqLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Action Message" := ReqLine."Action Message";
        InventoryEventBuffer."Ref. Order No." := ReqLine."Ref. Order No.";
        InventoryEventBuffer."Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");
        // Notice: Planned outbound transfer uses an opposite direction of transfer
        InventoryEventBuffer."Transfer Direction" := InventoryEventBuffer."Transfer Direction"::Inbound;

        OnAfterTransferFromReqLineTransDemand(InventoryEventBuffer, ReqLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromReqLineTransDemand(InventoryEventBuffer, ReqLine);
#endif
    end;

    procedure TransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; ReqLine: Record "Requisition Line"; AtLocation: Code[10]; AtDate: Date; DeltaQtyBase: Decimal; RecID: RecordID)
    begin
        if ReqLine.Type <> ReqLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        InventoryEventBuffer."Source Line ID" := RecID;
        InventoryEventBuffer."Item No." := ReqLine."No.";
        InventoryEventBuffer."Variant Code" := ReqLine."Variant Code";
        InventoryEventBuffer."Location Code" := AtLocation;
        InventoryEventBuffer."Availability Date" := AtDate;
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Plan;
        ReqLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := DeltaQtyBase;
        InventoryEventBuffer."Reserved Quantity (Base)" := ReqLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);
        InventoryEventBuffer."Action Message" := ReqLine."Action Message";
        InventoryEventBuffer."Ref. Order No." := ReqLine."Ref. Order No.";
        InventoryEventBuffer."Ref. Order Type" := GetRefOrderTypeFromReqLine(ReqLine."Ref. Order Type");

        OnAfterTransferFromReqLine(InventoryEventBuffer, ReqLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromReqLine(InventoryEventBuffer, ReqLine);
#endif
    end;

    local procedure GetRefOrderTypeFromReqLine(ReqLineRefOrderType: Enum "Requisition Ref. Order Type"): Integer
    var
        ReqLine: Record "Requisition Line";
        InventoryEventBuffer: Record "Inventory Event Buffer";
    begin
        case ReqLineRefOrderType of
            ReqLine."Ref. Order Type"::" ":
                exit(InventoryEventBuffer."Ref. Order Type"::" ");
            ReqLine."Ref. Order Type"::Purchase:
                exit(InventoryEventBuffer."Ref. Order Type"::Purchase);
            ReqLine."Ref. Order Type"::"Prod. Order":
                exit(InventoryEventBuffer."Ref. Order Type"::"Prod. Order");
            ReqLine."Ref. Order Type"::Transfer:
                exit(InventoryEventBuffer."Ref. Order Type"::Transfer);
            ReqLine."Ref. Order Type"::Assembly:
                exit(InventoryEventBuffer."Ref. Order Type"::Assembly);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
    end;
}
