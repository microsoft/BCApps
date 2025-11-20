// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000820 "Mfg. Bom Buffer"
{
    var
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyPerFieldIsNotSetErr: Label 'The Quantity per. field in the BOM for Item %1 has not been set.', Comment = '%1 Item No.';

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnInitFromItemOnAfterSetReplenishmentSystem', '', false, false)]
    local procedure OnInitFromItemOnAfterSetReplenishmentSystem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit");
    var
        VersionMgt: Codeunit VersionManagement;
        ProductionBOMCheck: Codeunit "Production BOM-Check";
        VersionCode: Code[20];
    begin
        BOMBuffer."Production BOM No." := Item."Production BOM No.";
        BOMBuffer."Routing No." := Item."Routing No.";
        if BOMBuffer."Replenishment System" = BOMBuffer."Replenishment System"::"Prod. Order" then begin
            VersionCode := VersionMgt.GetBOMVersion(BOMBuffer."Production BOM No.", WorkDate(), true);
            BOMBuffer."BOM Unit of Measure Code" := VersionMgt.GetBOMUnitOfMeasure(BOMBuffer."Production BOM No.", VersionCode);
            ProductionBOMCheck.CheckBOM(BOMBuffer."Production BOM No.", VersionCode);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterGetUnitCost', '', false, false)]
    local procedure OnAfterGetUnitCost(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item)
    begin
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then begin
            BOMBuffer."Single-Lvl Mat. Non-Invt. Cost" :=
                BOMBuffer.RoundUnitAmt(Item."Single-Lvl Mat. Non-Invt. Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, BOMBuffer."Unit of Measure Code") * BOMBuffer."Qty. per Top Item");
            BOMBuffer."Rolled-up Mat. Non-Invt. Cost" :=
                BOMBuffer.RoundUnitAmt(Item."Unit Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, BOMBuffer."Unit of Measure Code") * BOMBuffer."Qty. per Top Item");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnGetItemCostsOnBeforeRoundCosts', '', false, false)]
    local procedure OnGetItemCostsOnBeforeRoundCosts(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item)
    begin
        if not Item.IsInventoriableType() then
            if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then begin
                BOMBuffer."Single-Lvl Mat. Non-Invt. Cost" := BOMBuffer."Unit Cost";
                BOMBuffer."Rolled-up Mat. Non-Invt. Cost" := BOMBuffer."Single-Lvl Mat. Non-Invt. Cost";
            end;

        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then begin
            if BOMBuffer."Qty. per Parent" <> 0 then
                BOMBuffer."Single-Level Scrap Cost" := (BOMBuffer."Single-Level Material Cost" + BOMBuffer."Single-Lvl Mat. Non-Invt. Cost") * BOMBuffer."Scrap Qty. per Parent" / BOMBuffer."Qty. per Parent";
            if BOMBuffer."Qty. per Top Item" <> 0 then
                BOMBuffer."Rolled-up Scrap Cost" := (BOMBuffer."Rolled-up Material Cost" + BOMBuffer."Rolled-up Mat. Non-Invt. Cost") * BOMBuffer."Scrap Qty. per Top Item" / BOMBuffer."Qty. per Top Item";
        end else begin
            if BOMBuffer."Qty. per Parent" <> 0 then
                BOMBuffer."Single-Level Scrap Cost" := BOMBuffer."Single-Level Material Cost" * BOMBuffer."Scrap Qty. per Parent" / BOMBuffer."Qty. per Parent";
            if BOMBuffer."Qty. per Top Item" <> 0 then
                BOMBuffer."Rolled-up Scrap Cost" := BOMBuffer."Rolled-up Material Cost" * BOMBuffer."Scrap Qty. per Top Item" / BOMBuffer."Qty. per Top Item";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterRoundCosts', '', false, false)]
    local procedure OnAfterRoundCosts(var BOMBuffer: Record "BOM Buffer"; ShareOfTotalCost: Decimal);
    begin
        BOMBuffer."Single-Level Subcontrd. Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Single-Level Subcontrd. Cost", ShareOfTotalCost);
        BOMBuffer."Single-Level Mfg. Ovhd Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Single-Level Mfg. Ovhd Cost", ShareOfTotalCost);
        BOMBuffer."Single-Level Scrap Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Single-Level Scrap Cost", ShareOfTotalCost);
        BOMBuffer."Rolled-up Subcontracted Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Rolled-up Subcontracted Cost", ShareOfTotalCost);
        BOMBuffer."Rolled-up Mfg. Ovhd Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Rolled-up Mfg. Ovhd Cost", ShareOfTotalCost);
        BOMBuffer."Rolled-up Scrap Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Rolled-up Scrap Cost", ShareOfTotalCost);
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then begin
            BOMBuffer."Single-Lvl Mat. Non-Invt. Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Single-Lvl Mat. Non-Invt. Cost", ShareOfTotalCost);
            BOMBuffer."Rolled-up Mat. Non-Invt. Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Rolled-up Mat. Non-Invt. Cost", ShareOfTotalCost);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterCalcIndirectCost', '', false, false)]
    local procedure OnAfterCalcIndirectCost(var BOMBuffer: Record "BOM Buffer"; var Cost: Decimal)
    begin
        Cost += BOMBuffer."Single-Level Mfg. Ovhd Cost";
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterCalcDirectCost', '', false, false)]
    local procedure OnAfterCalcDirectCost(var BOMBuffer: Record "BOM Buffer"; var Cost: Decimal)
    begin
        Cost += BOMBuffer."Single-Level Subcontrd. Cost";
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then
            Cost += BOMBuffer."Single-Lvl Mat. Non-Invt. Cost";
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterCalcOvhdCost', '', false, false)]
    local procedure OnAfterCalcOvhdCost(var BOMBuffer: Record "BOM Buffer"; LotSize: Decimal)
    begin
        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then
            BOMBuffer."Single-Level Mfg. Ovhd Cost" +=
              ((BOMBuffer."Single-Level Material Cost" +
                BOMBuffer."Single-Lvl Mat. Non-Invt. Cost" +
                BOMBuffer."Single-Level Capacity Cost" +
                BOMBuffer."Single-Level Subcontrd. Cost" +
                BOMBuffer."Single-Level Cap. Ovhd Cost") *
               BOMBuffer."Indirect Cost %" / 100) +
              (BOMBuffer."Overhead Rate" * LotSize)
        else
            BOMBuffer."Single-Level Mfg. Ovhd Cost" +=
              ((BOMBuffer."Single-Level Material Cost" +
                BOMBuffer."Single-Level Capacity Cost" +
                BOMBuffer."Single-Level Subcontrd. Cost" +
                BOMBuffer."Single-Level Cap. Ovhd Cost") *
               BOMBuffer."Indirect Cost %" / 100) +
              (BOMBuffer."Overhead Rate" * LotSize);
        BOMBuffer."Single-Level Mfg. Ovhd Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Single-Level Mfg. Ovhd Cost", 1);

        if MfgCostCalculationMgt.CanIncNonInvCostIntoProductionItem() then
            BOMBuffer."Rolled-up Mfg. Ovhd Cost" +=
              ((BOMBuffer."Rolled-up Material Cost" +
                BOMBuffer."Rolled-up Mat. Non-Invt. Cost" +
                BOMBuffer."Rolled-up Capacity Cost" +
                BOMBuffer."Rolled-up Subcontracted Cost" +
                BOMBuffer."Rolled-up Capacity Ovhd. Cost" +
                BOMBuffer."Rolled-up Mfg. Ovhd Cost") *
               BOMBuffer."Indirect Cost %" / 100) +
              (BOMBuffer."Overhead Rate" * LotSize)
        else
            BOMBuffer."Rolled-up Mfg. Ovhd Cost" +=
            ((BOMBuffer."Rolled-up Material Cost" +
              BOMBuffer."Rolled-up Capacity Cost" +
              BOMBuffer."Rolled-up Subcontracted Cost" +
              BOMBuffer."Rolled-up Capacity Ovhd. Cost" +
              BOMBuffer."Rolled-up Mfg. Ovhd Cost") *
             BOMBuffer."Indirect Cost %" / 100) +
            (BOMBuffer."Overhead Rate" * LotSize);

        OnBeforeRoundUnitAmtForRolledUpMfgOvhdCost(BOMBuffer);
        BOMBuffer."Rolled-up Mfg. Ovhd Cost" := BOMBuffer.RoundUnitAmt(BOMBuffer."Rolled-up Mfg. Ovhd Cost", 1);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnIsQtyPerOKOnAfterCheckItemAssemblyBOM', '', false, false)]
    local procedure OnIsQtyPerOKOnAfterCheckItemAssemblyBOM(Item: Record Item; var BOMWarningLog: Record "BOM Warning Log")
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if not Item."Assembly BOM" then
            if ProdBOMHeader.Get(Item."Production BOM No.") then
                BOMWarningLog.SetWarning(
                    StrSubstNo(QtyPerFieldIsNotSetErr, Item."No."), DATABASE::"Production BOM Header", CopyStr(ProdBOMHeader.GetPosition(), 1, 250));
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Buffer", 'OnAfterIsLineOk', '', false, false)]
    local procedure OnAfterIsLineOk(var BOMBuffer: Record "BOM Buffer"; LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"; var Result: Boolean)
    begin
        Result := Result and
          BOMBuffer.IsProdBOMOk(LogWarning, BOMWarningLog) and
          BOMBuffer.IsRoutingOk(LogWarning, BOMWarningLog);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Warning Log", 'OnAfterShowWarning', '', false, false)]
    local procedure OnAfterShowWarning(var BOMWarningLog: Record "BOM Warning Log"; RecRef: RecordRef)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case BOMWarningLog."Table ID" of
            DATABASE::"Production BOM Header":
                begin
                    RecRef.SetTable(ProdBOMHeader);
                    ProdBOMHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM", ProdBOMHeader);
                end;
            DATABASE::"Routing Header":
                begin
                    RecRef.SetTable(RoutingHeader);
                    RoutingHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::Routing, RoutingHeader);
                end;
            DATABASE::"Production BOM Version":
                begin
                    RecRef.SetTable(ProdBOMVersion);
                    ProdBOMVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM Version", ProdBOMVersion);
                end;
            DATABASE::"Routing Version":
                begin
                    RecRef.SetTable(RoutingVersion);
                    RoutingVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Routing Version", RoutingVersion);
                end;
            DATABASE::"Machine Center":
                begin
                    RecRef.SetTable(MachineCenter);
                    MachineCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Machine Center Card", MachineCenter);
                end;
            DATABASE::"Work Center":
                begin
                    RecRef.SetTable(WorkCenter);
                    WorkCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Work Center Card", WorkCenter);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundUnitAmtForRolledUpMfgOvhdCost(var BOMBuffer: Record "BOM Buffer")
    begin
    end;
}