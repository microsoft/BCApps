// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Planning;

codeunit 99000867 "Mfg. Order Planning Mgt."
{
    SingleInstance = true;

    var
        ProdOrderComp: Record "Prod. Order Component";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertAltSupplyLocationOnAfterSelectSubstitution', '', true, true)]
    local procedure OnInsertAltSupplyLocationOnAfterSelectSubstitution(var RequisitionLine: Record "Requisition Line"; var TempItemSub: Record "Item Substitution" temporary)
    var
        MfgItemSubstitution: Codeunit "Mfg. Item Substitution";
    begin
        ProdOrderComp.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.", RequisitionLine."Demand Ref. No.");
        MfgItemSubstitution.UpdateProdOrderComp(ProdOrderComp, TempItemSub."Substitute No.", TempItemSub."Substitute Variant Code");
        ProdOrderComp.Modify(true);
        ProdOrderComp.AutoReserve();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertAltSupplyLocationOnUpdateReqLine', '', true, true)]
    local procedure OnInsertAltSupplyLocationOnUpdateReqLine(var RequisitionLine: Record "Requisition Line"; var TempItemSub: Record "Item Substitution" temporary)
    var
        TempReqLine2: Record "Requisition Line" temporary;
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        PlanningLineMgt: Codeunit "Planning Line Management";
        UnAvailableQtyBase: Decimal;
    begin
        TempReqLine2 := RequisitionLine; // Save Original Line

        UnAvailableQtyBase :=
            OrderPlanningMgt.CalcNeededQty(TempItemSub."Quantity Avail. on Shpt. Date", TempReqLine2."Demand Quantity (Base)");

        // Update Req.Line
        RequisitionLine."Worksheet Template Name" := TempReqLine2."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := TempReqLine2."Journal Batch Name";
        RequisitionLine."Line No." := TempReqLine2."Line No.";
        RequisitionLine."Location Code" := ProdOrderComp."Location Code";
        RequisitionLine."Bin Code" := ProdOrderComp."Bin Code";
        RequisitionLine.Validate("No.", ProdOrderComp."Item No.");
        RequisitionLine.Validate("Variant Code", ProdOrderComp."Variant Code");
        RequisitionLine."Unit Of Measure Code (Demand)" := ProdOrderComp."Unit of Measure Code";
        RequisitionLine."Qty. per UOM (Demand)" := ProdOrderComp."Qty. per Unit of Measure";
        RequisitionLine.SetSupplyQty(TempReqLine2."Demand Quantity (Base)", UnAvailableQtyBase);
        RequisitionLine.SetSupplyDates(TempReqLine2."Demand Date");
        RequisitionLine."Original Item No." := TempReqLine2."No.";
        RequisitionLine."Original Variant Code" := TempReqLine2."Variant Code";
        OnBeforeReqLineModify(RequisitionLine, TempReqLine2, ProdOrderComp);
#if not CLEAN27
        OrderPlanningMgt.RunOnBeforeReqLineModify(RequisitionLine, TempReqLine2, ProdOrderComp);
#endif
        RequisitionLine.Modify();
        PlanningLineMgt.Calculate(RequisitionLine, 1, true, true, 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnSubstitutionPossibleOnAfterCheckReqLine', '', true, true)]
    local procedure OnSubstitutionPossibleOnAfterCheckReqLine(var RequisitionLine: Record "Requisition Line"; var ShouldExit: Boolean)
    begin
        if ProdOrderComp.Get(
             RequisitionLine."Demand Subtype",
             RequisitionLine."Demand Order No.",
             RequisitionLine."Demand Line No.",
             RequisitionLine."Demand Ref. No.")
        then
            if ProdOrderComp."Supplied-by Line No." <> 0 then
                ShouldExit := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqLineModify(var RequisitionLine: Record "Requisition Line"; RequisitionLine2: Record "Requisition Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
}