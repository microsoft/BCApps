// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;

codeunit 99000857 "Prod. Order Line-Planning"
{
    Permissions = tabledata "Production Order" = r,
                  tabledata "Prod. Order Component" = r,
                  tabledata "Prod. Order Capacity Need" = r;

    var
        ProductionOrder: Record "Production Order";
#if not CLEAN27
        GetUnplannedDemand: Codeunit "Get Unplanned Demand";
#endif
        ProductionTxt: Label 'Production';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Production then
            RequisitionLine."Demand Type" := Database::"Prod. Order Component";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        ProdOrder: Record "Production Order";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Production:
                begin
                    ProdOrder.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand.Description := ProdOrder.Description;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then begin
            ProdOrderComp.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
            RequisitionLine.TestField("No.", ProdOrderComp."Item No.");
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (ProdOrderComp."Due Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", ProdOrderComp."Due Date");
            RequisitionLine.TestField("Qty. per UOM (Demand)", ProdOrderComp."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", ProdOrderComp."Variant Code");
            RequisitionLine.TestField("Location Code", ProdOrderComp."Location Code");
            ProdOrderComp.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Production then begin
            ProdOrderComponent.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.", UnplannedDemand."Demand Ref. No.");
            ItemTrackingManagement.CopyItemTracking(ProdOrderComponent.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then begin
            ProductionOrder.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case ProductionOrder.Status of
                ProductionOrder.Status::Planned:
                    PAGE.Run(PAGE::"Planned Production Order", ProductionOrder);
                ProductionOrder.Status::"Firm Planned":
                    PAGE.Run(PAGE::"Firm Planned Prod. Order", ProductionOrder);
                ProductionOrder.Status::Released:
                    PAGE.Run(PAGE::"Released Production Order", ProductionOrder);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Production Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Prod. Order Component");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
                Text := Format(Enum::"Production Order Status".FromInteger(RequisitionLine.Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
                Text := ProductionTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Prod. Order Component" then
            Text := Format(Enum::"Production Order Status".FromInteger(RequisitionLine.Status));
    end;

    // Codeunit "Get Unplanned Demand"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnBeforeOpenWindow', '', false, false)]
    local procedure OnBeforeOpenPlanningWindow(var RecordCounter: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetFilter(
            Status, '%1|%2|%3', ProdOrderComp.Status::Planned, ProdOrderComp.Status::"Firm Planned", ProdOrderComp.Status::Released);
        RecordCounter += ProdOrderComp.Count();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnAfterGetUnplanned', '', false, false)]
    local procedure OnAfterGetUnplanned(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    begin
        GetUnplannedProdOrderComp(UnplannedDemand, ItemFilter, sender);
    end;

    local procedure GetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    var
        ProdOrderComp: Record "Prod. Order Component";
        NeedInsertUnplannedDemand: Boolean;
        DemandQtyBase: Decimal;
    begin
        OnBeforeGetUnplannedProdOrderComp(UnplannedDemand, ProdOrderComp);
#if not CLEAN27
        GetUnplannedDemand.RunOnBeforeGetUnplannedProdOrderComp(UnplannedDemand, ProdOrderComp);
#endif

        ProdOrderComp.SetFilter(
            Status, '%1|%2|%3', ProdOrderComp.Status::Planned, ProdOrderComp.Status::"Firm Planned", ProdOrderComp.Status::Released);
        ProdOrderComp.SetFilter("Item No.", ItemFilter.ToText());
        if ProdOrderComp.FindSet() then
            repeat
                sender.UpdateWindow();
                DemandQtyBase := GetProdOrderCompNeededQty(ProdOrderComp);
                if DemandQtyBase > 0 then begin
                    NeedInsertUnplannedDemand :=
                        not ((ProdOrderComp.Status.AsInteger() = UnplannedDemand."Demand SubType") and
                        (ProdOrderComp."Prod. Order No." = UnplannedDemand."Demand Order No."));
                    OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(UnplannedDemand, ProdOrderComp, NeedInsertUnplannedDemand);
#if not CLEAN27
                    GetUnplannedDemand.RunOnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(UnplannedDemand, ProdOrderComp, NeedInsertUnplannedDemand);
#endif
                    if NeedInsertUnplannedDemand then begin
                        sender.InsertUnplannedDemand(
                            UnplannedDemand, UnplannedDemand."Demand Type"::Production,
                            ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp.Status.AsInteger());
                        OnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(UnplannedDemand, ProdOrderComp);
#if not CLEAN27
                        GetUnplannedDemand.RunOnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(UnplannedDemand, ProdOrderComp);
#endif
                    end;
                    InsertProdOrderCompLine(UnplannedDemand, ProdOrderComp, DemandQtyBase);
                    OnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(UnplannedDemand, ProdOrderComp);
#if not CLEAN27
                    GetUnplannedDemand.RunOnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(UnplannedDemand, ProdOrderComp);
#endif
                end;
            until ProdOrderComp.Next() = 0;
    end;

    local procedure GetProdOrderCompNeededQty(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        NeededQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetProdOrderCompNeededQty(ProdOrderComp, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        if ProdOrderComp."Item No." = '' then
            exit(0);

        ProdOrderComp.CalcFields(ProdOrderComp."Reserved Qty. (Base)");
        exit(ProdOrderComp."Remaining Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
    end;

    local procedure InsertProdOrderCompLine(var UnplannedDemand: Record "Unplanned Demand"; ProdOrderCOmp: Record "Prod. Order Component"; DemandQtyBase: Decimal)
    var
        UnplannedDemand2: Record "Unplanned Demand";
        Item: Record Item;
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.InitRecord(
          ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.", ProdOrderComp."Item No.", ProdOrderComp.Description,
          ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Bin Code", ProdOrderComp."Unit of Measure Code",
          ProdOrderComp."Qty. per Unit of Measure", DemandQtyBase, ProdOrderComp."Due Date");
        Item.Get(UnplannedDemand."Item No.");
        UnplannedDemand.Reserve :=
          (Item.Reserve = Item.Reserve::Always) and
          not ((UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Production) and
               (UnplannedDemand."Demand SubType" = ProdOrderComp.Status::Planned.AsInteger()));
        OnInsertProdOrderCompLineOnBeforeInsert(UnplannedDemand, ProdOrderComp);
#if not CLEAN27
        GetUnplannedDemand.RunOnInsertProdOrderCompLineOnBeforeInsert(UnplannedDemand, ProdOrderComp);
#endif
        UnplannedDemand.Insert();
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertAltSupplyLocationOnAfterSelectSubstitution', '', false, false)]
    local procedure OnInsertAltSupplyLocationOnAfterSelectSubstitution(var RequisitionLine: Record "Requisition Line"; var TempItemSub: Record "Item Substitution" temporary)
    var
        ProdOrderComp: Record "Prod. Order Component";
        MfgItemSubstitution: Codeunit "Mfg. Item Substitution";
    begin
        ProdOrderComp.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
        MfgItemSubstitution.UpdateProdOrderComp(ProdOrderComp, TempItemSub."Substitute No.", TempItemSub."Substitute Variant Code");
        ProdOrderComp.Modify(true);
        ProdOrderComp.AutoReserve();
    end;



    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeedInsertUnplannedDemand: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderCompLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderCompNeededQty(ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;
}
