// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Document;

tableextension 99000850 "Mfg. Planning Assignment" extends "Planning Assignment"
{
    procedure RoutingReplace(var Item: Record Item; OldRoutingNo: Code[20])
    begin
        if OldRoutingNo <> Item."Routing No." then
            if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                AssignPlannedOrders(Item."No.", false);

        OnAfterRoutingReplace(Item, OldRoutingNo);
    end;

    procedure BomReplace(var Item: Record Item; OldProductionBOMNo: Code[20])
    begin
        if OldProductionBOMNo <> Item."Production BOM No." then begin
            if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                AssignPlannedOrders(Item."No.", false);
            if OldProductionBOMNo <> '' then
                OldBom(OldProductionBOMNo);
        end;

        OnAfterBomReplace(Item, OldProductionBOMNo);
    end;

    procedure OldBom(ProductionBOMNo: Code[20])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        UseVersions: Boolean;
        EndLoop: Boolean;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.SetRange(Status, ProductionBOMVersion.Status::Certified);
        UseVersions := ProductionBOMVersion.FindSet();

        if ProductionBOMHeader.Get(ProductionBOMNo) and
           (ProductionBOMHeader.Status = ProductionBOMHeader.Status::Certified)
        then begin
            ProductionBOMVersion."Production BOM No." := ProductionBOMHeader."No.";
            ProductionBOMVersion."Version Code" := '';
        end else
            if not ProductionBOMVersion.FindSet() then
                exit;

        EndLoop := false;
        OnOldBomOnBeforeProcessProductionBOMLine(ProductionBOMNo, EndLoop);
        if EndLoop then
            exit;
        repeat
            ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMVersion."Production BOM No.");
            ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
            ProductionBOMLine.SetFilter(Type, '<>%1', ProductionBOMLine.Type::" ");
            if ProductionBOMLine.FindSet() then
                repeat
                    case ProductionBOMLine.Type of
                        ProductionBOMLine.Type::Item:
                            begin
                                Item.SetLoadFields("Reordering Policy");
                                if Item.Get(ProductionBOMLine."No.") then
                                    if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                                        AssignPlannedOrders(ProductionBOMLine."No.", false);
                            end;
                        ProductionBOMLine.Type::"Production BOM":
                            OldBom(ProductionBOMLine."No.");
                    end;
                until ProductionBOMLine.Next() = 0;
            if UseVersions then
                EndLoop := ProductionBOMVersion.Next() = 0
            else
                EndLoop := true;
        until EndLoop;
    end;

    procedure NewBOM(ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Production BOM No.");
        Item.SetRange("Production BOM No.", ProductionBOMNo);
        Item.SetLoadFields("Reordering Policy");
        if Item.FindSet() then
            repeat
                if Item."Reordering Policy" <> Item."Reordering Policy"::" " then
                    AssignPlannedOrders(Item."No.", false);
            until Item.Next() = 0;

        OnAfterNewBOM(ProductionBOMNo);
    end;

    procedure AssignPlannedOrders(ItemNo: Code[20]; CheckSKU: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        AssignThis: Boolean;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code");
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        if ProdOrderLine.FindSet(true) then
            repeat
                if CheckSKU then
                    AssignThis := not SKUExists(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code")
                else
                    AssignThis := true;
                if AssignThis then
                    AssignOne(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Location Code", WorkDate());
                ProdOrderLine.SetRange("Variant Code", ProdOrderLine."Variant Code");
                ProdOrderLine.SetRange("Location Code", ProdOrderLine."Location Code");
                ProdOrderLine.FindLast();
                ProdOrderLine.SetRange("Variant Code");
                ProdOrderLine.SetRange("Location Code");
            until ProdOrderLine.Next() = 0;

        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        if RequisitionLine.FindSet(true) then
            repeat
                if CheckSKU then
                    AssignThis := not SKUExists(RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Location Code")
                else
                    AssignThis := true;
                if AssignThis then
                    AssignOne(RequisitionLine."No.", RequisitionLine."Variant Code", RequisitionLine."Location Code", WorkDate());
                RequisitionLine.SetRange("Variant Code", RequisitionLine."Variant Code");
                RequisitionLine.SetRange("Location Code", RequisitionLine."Location Code");
                RequisitionLine.FindLast();
                RequisitionLine.SetRange("Variant Code");
                RequisitionLine.SetRange("Location Code");
            until RequisitionLine.Next() = 0;

        OnAfterAssignPlannedOrders(ItemNo, CheckSKU, AssignThis);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoutingReplace(var Item: Record Item; OldRoutingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBomReplace(var Item: Record Item; OldProductionBOMNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOldBomOnBeforeProcessProductionBOMLine(ProductionBOMNo: Code[20]; var EndLoop: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNewBOM(ProductionBOMNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignPlannedOrders(ItemNo: Code[20]; CheckSKU: Boolean; var AssignThis: Boolean)
    begin
    end;
}
