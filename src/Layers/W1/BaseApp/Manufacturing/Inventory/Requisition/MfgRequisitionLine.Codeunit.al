// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;

codeunit 99000866 "Mfg. Requisition Line"
{
    var
        NoProductionOrderErr: Label 'There is no Production. Order for this line.';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnGetDimFromRefOrderLineElseCase', '', false, false)]
    local procedure OnGetDimFromRefOrderLineElseCase(var RequisitionLine: Record "Requisition Line"; DimSetIDArr: array[10] of Integer; i: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                if ProdOrderLine.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then
                    DimSetIDArr[i] := ProdOrderLine."Dimension Set ID";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnLookupRefOrderNoElseCase', '', false, false)]
    local procedure OnLookupRefOrderNoElseCase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    var
        ProdOrder: Record "Production Order";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                begin
                    if ProdOrder.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then
                        case ProdOrder.Status of
                            ProdOrder.Status::Planned:
                                PAGE.Run(PAGE::"Planned Production Order", ProdOrder);
                            ProdOrder.Status::"Firm Planned":
                                PAGE.Run(PAGE::"Firm Planned Prod. Order", ProdOrder);
                            ProdOrder.Status::Released:
                                PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                        end
                    else
                        Message(NoProductionOrderErr);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdBOMNo', '', false, false)]
    local procedure OnCleanProdBOMNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Production BOM No.", '');
        RequisitionLine.Validate("Routing No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdOrderNo', '', false, false)]
    local procedure OnCleanProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine."Prod. Order No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnIsProdOrder', '', false, false)]
    local procedure OnIsProdOrder(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
        Result := RequisitionLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnIsProductionBOM', '', false, false)]
    local procedure OnIsProductionBOM(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
        Result := RequisitionLine."Production BOM No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnIsProdDemand', '', false, false)]
    local procedure OnIsProdDemand(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
        Result :=
            (RequisitionLine."Demand Type" = Database::"Prod. Order Component") and
            (RequisitionLine."Demand Subtype" = "Production Order Status"::Planned.AsInteger());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnTestProdOrderNo', '', false, false)]
    local procedure OnTestProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.TestField("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterCopyFromItem', '', false, false)]
    local procedure OnAfterCopyFromItem(var RequisitionLine: Record "Requisition Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
        RequisitionLine."Scrap %" := Item."Scrap %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterTransferFromPurchaseLine', '', false, false)]
    local procedure OnAfterTransferFromPurchaseLine(var ReqLine: Record "Requisition Line"; PurchLine: Record "Purchase Line")
    begin
        ReqLine."Routing No." := PurchLine."Routing No.";
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Prod. Order Capacity Need", 'rimd')]
    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterDeleteRelations', '', false, false)]
    local procedure OnAfterDeleteRelations(var RequisitionLine: Record "Requisition Line"; DeleteAllLines: Boolean)
    var
        PlanningRtngLine: Record "Planning Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        if not DeleteAllLines then begin
            PlanningRtngLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            ProdOrderCapNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        end;

        PlanningRtngLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        if not PlanningRtngLine.IsEmpty() then
            PlanningRtngLine.DeleteAll();

        ProdOrderCapNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        if not ProdOrderCapNeed.IsEmpty() then
            ProdOrderCapNeed.DeleteAll();

        if not DeleteAllLines then
            ReactivateProdOrderCapacityNeed(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnClearPlanningWorksheetOnBeforeRequisitionLineDelete', '', false, false)]
    local procedure OnClearPlanningWorksheetOnBeforeRequisitionLineDelete(var RequisitionLine: Record "Requisition Line")
    begin
        ReactivateProdOrderCapacityNeed(RequisitionLine);
    end;

    local procedure ReactivateProdOrderCapacityNeed(RequisitionLine: Record "Requisition Line")
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapNeed.SetCurrentKey(Status, "Prod. Order No.", Active);
        ProdOrderCapNeed.SetRange(Status, RequisitionLine."Ref. Order Status");
        ProdOrderCapNeed.SetRange("Prod. Order No.", RequisitionLine."Ref. Order No.");
        ProdOrderCapNeed.SetRange(Active, false);
        if not ProdOrderCapNeed.IsEmpty() then
            ProdOrderCapNeed.ModifyAll(Active, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnRoutingLineExists', '', false, false)]
    local procedure OnRoutingLineExists(var RequisitionLine: Record "Requisition Line"; var RoutingExists: Boolean)
    begin
        RoutingExists := RequisitionLine.RoutingLineExists();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateStartingDate', '', false, false)]
    local procedure OnValidateStartingDate(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.GetWorkCenter();
        if not RequisitionLine.IsSubcontracting() then begin
            RequisitionLine.Validate("Production BOM No.");
            RequisitionLine.Validate("Routing No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateEndingDate', '', false, false)]
    local procedure OnValidateEndingDate(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.GetWorkCenter();
        if not RequisitionLine.IsSubcontracting() then begin
            RequisitionLine.Validate("Production BOM No.");
            RequisitionLine.Validate("Routing No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateStartingTimeOnBeforeUpdateDateTime', '', false, false)]
    local procedure OnValidateStartingTimeOnBeforeUpdateDateTime(var RequisitionLine: Record "Requisition Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if RequisitionLine."Starting Time" = 0T then begin
            ManufacturingSetup.Get();
            RequisitionLine."Starting Time" := ManufacturingSetup."Normal Starting Time";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateEndingTimeOnBeforeUpdateDateTime', '', false, false)]
    local procedure OnValidateEndingTimeOnBeforeUpdateDateTime(var RequisitionLine: Record "Requisition Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if RequisitionLine."Ending Time" = 0T then begin
            ManufacturingSetup.Get();
            RequisitionLine."Ending Time" := ManufacturingSetup."Normal Ending Time";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeGetDirectCost', '', false, false)]
    local procedure OnBeforeGetDirectCost(var ReqLine: Record "Requisition Line")
    begin
        ReqLine.GetWorkCenter();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetFromBinCodeOnSetBinCode', '', false, false)]
    local procedure OnSetFromBinCodeOnSetBinCode(var RequisitionLine: Record "Requisition Line"; Location: Record Location)
    var
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                begin
                    if RequisitionLine."Bin Code" = '' then
                        RequisitionLine."Bin Code" :=
                            ProdOrderWarehouseMgt.GetLastOperationFromBinCode(
                                RequisitionLine."Routing No.", RequisitionLine."Routing Version Code", RequisitionLine."Location Code", false, "Flushing Method"::Manual);
                    if RequisitionLine."Bin Code" = '' then
                        RequisitionLine."Bin Code" := Location."From-Production Bin Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterShouldCheckNewActionMessage', '', false, false)]
    local procedure OnAfterShouldCheckNewActionMessage(var RequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var ShouldCheck: Boolean)
    begin
        ShouldCheck := ShouldCheck or
            CurrentFieldNo in [RequisitionLine.FieldNo("Production BOM Version Code"),
                                RequisitionLine.FieldNo("Routing Version Code"),
                                RequisitionLine.FieldNo("Production BOM No."),
                                RequisitionLine.FieldNo("Routing No.")];
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnUpdateWorkCenterDescription', '', false, false)]
    local procedure OnUpdateWorkCenterDescription(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
        IsHandled := RequisitionLine.UpdateWorkCenterDescription();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateReplenishmentSystemCaseElse', '', false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        case RequisitionLine."Replenishment System" of
            "Replenishment System"::"Prod. Order":
                RequisitionLine.SetReplenishmentSystemFromProdOrder(StockkeepingUnit);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateReplenishmentSystemOnAfterSetStockkeepingUnit', '', false, false)]
    local procedure OnValidateReplenishmentSystemOnAfterSetStockkeepingUnit(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        if RequisitionLine.IsSubcontracting() then
            StockkeepingUnit."Replenishment System" := StockkeepingUnit."Replenishment System"::"Prod. Order";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterShouldUpdateEndingDateForSourceType', '', false, false)]
    local procedure OnAfterShouldUpdateEndingDateForSourceType(SourceType: Integer; var ShouldUpdate: Boolean)
    begin
        ShouldUpdate := ShouldUpdate or (SourceType = Database::"Prod. Order Line");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetSupplyDatesOnAfterValidateEndingDate', '', false, false)]
    local procedure OnSetSupplyDatesOnAfterValidateEndingDate(var RequisitionLine: Record "Requisition Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if (RequisitionLine."Replenishment System" = "Replenishment System"::"Prod. Order") and (RequisitionLine."Starting Time" = 0T) then begin
            ManufacturingSetup.Get();
            RequisitionLine."Starting Time" := ManufacturingSetup."Normal Starting Time";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Req. Wksh. Template", 'OnAfterValidateEvent', 'Recurring', false, false)]
    local procedure ReqWkshTemplateOnAfterValidateRecurring(var Rec: Record "Req. Wksh. Template")
    begin
        if not Rec.Recurring then
            case Rec.Type of
                Rec.Type::"For. Labor":
                    Rec."Page ID" := Page::"Subcontracting Worksheet";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::PlanningWkshManagement, 'OnGetRoutingDescription', '', false, false)]
    local procedure OnGetRoutingDescription(var ReqLine: Record "Requisition Line"; var RoutingDescription: Text[100])
    var
        RoutingHeader: Record "Routing Header";
    begin
        if ReqLine."Routing No." = '' then
            RoutingDescription := ''
        else
            if RoutingHeader.Get(ReqLine."Routing No.") then
                RoutingDescription := RoutingHeader.Description
            else
                RoutingDescription := '';
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Action Messages", 'OnInitReqFromSourceBySource', '', false, false)]
    local procedure OnInitReqFromSourceBySource(var ReqLine: Record "Requisition Line"; ActionMessageEntry: Record "Action Message Entry"; var IsHandled: Boolean; var ShouldExit: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case ActionMessageEntry."Source Type" of
            Database::"Prod. Order Line":
                begin
                    if ProdOrderLine.Get(ActionMessageEntry."Source Subtype", ActionMessageEntry."Source ID", ActionMessageEntry."Source Prod. Order Line") then begin
                        ReqLine.GetProdOrderLine(ProdOrderLine);
                        ShouldExit := true;
                    end;
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnResetReqLineFields', '', false, false)]
    local procedure OnResetReqLineFields(var RequisitionLine: Record "Requisition Line")
    begin
        ResetReqLineFields(RequisitionLine);
    end;

    procedure ResetReqLineFields(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine."Prod. Order Line No." := 0;
        RequisitionLine."Routing No." := '';
        RequisitionLine."Routing Reference No." := 0;
        RequisitionLine."Operation No." := '';
        RequisitionLine."Work Center No." := '';

        OnAfterResetReqLineFields(RequisitionLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnResetReqLineFields', '', false, false)]
    local procedure OnSetOperationNoFilterToBlank(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetRange("Operation No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", 'OnTransferFromReqLineToPurchLine', '', false, false)]
    local procedure OnTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
        PurchOrderLine.TransferFromReqLineToPurchLine(PurchOrderLine, RequisitionLine);
    end;
}