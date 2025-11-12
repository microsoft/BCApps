// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 99000758 "Mfg. Cost Calculation Mgt."
{
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Prod. Order Capacity Need" = r,
                  TableData "Value Entry" = r;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        CostCalculationMgt: Codeunit "Cost Calculation Management";

    [EventSubscriber(ObjectType::Table, Database::Item, OnBeforeValidateStandardCost, '', false, false)]
    local procedure OnBeforeValidateStandardCost(var Item: Record Item; xItem: Record Item)
    begin
        if CanIncNonInvCostIntoProductionItem() then
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                Item."Single-Lvl Mat. Non-Invt. Cost" := 0;
                Item."Rolled-up Mat. Non-Invt. Cost" := 0;
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", OnBeforeValidateStandardCost, '', false, false)]
    local procedure OnBeforeValidateSKUStandardCost(var StockkeepingUnit: Record "Stockkeeping Unit"; xStockkeepingUnit: Record "Stockkeeping Unit")
    var
        Item: Record Item;
    begin
        if CanIncNonInvCostIntoProductionItem() then begin
            Item.Get(StockkeepingUnit."Item No.");
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                StockkeepingUnit."Single-Lvl Mat. Non-Invt. Cost" := 0;
                StockkeepingUnit."Rolled-up Mat. Non-Invt. Cost" := 0;
            end;
        end;
    end;

    procedure CalcRoutingCostPerUnit(Type: Enum "Capacity Type"; No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case Type of
            Type::"Work Center":
                WorkCenter.Get(No);
            Type::"Machine Center":
                MachineCenter.Get(No);
        end;
        CalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
    end;

    procedure CalcRoutingCostPerUnit(Type: Enum "Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter, IsHandled);
#endif
        if IsHandled then
            exit;

        UnitCostCalculation := UnitCostCalculation::Time;
        case Type of
            Type::"Work Center":
                begin
                    UnitCostCalculation := WorkCenter."Unit Cost Calculation";
                    IndirCostPct := WorkCenter."Indirect Cost %";
                    OvhdRate := WorkCenter."Overhead Rate";
                    if WorkCenter."Specific Unit Cost" then
                        DirUnitCost := CostCalculationMgt.CalcDirUnitCost(UnitCost, OvhdRate, IndirCostPct)
                    else begin
                        DirUnitCost := WorkCenter."Direct Unit Cost";
                        UnitCost := WorkCenter."Unit Cost";
                    end;
                end;
            Type::"Machine Center":
                begin
                    MachineCenter.TestField("Work Center No.");
                    DirUnitCost := MachineCenter."Direct Unit Cost";
                    OvhdRate := MachineCenter."Overhead Rate";
                    IndirCostPct := MachineCenter."Indirect Cost %";
                    UnitCost := MachineCenter."Unit Cost";
                end;
        end;
        OnAfterCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
#if not CLEAN26
        CostCalculationMgt.RunOnAfterCalcRoutingCostPerUnit(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
#endif
    end;

    procedure CalcShareOfTotalCapCost(ProdOrderLine: Record "Prod. Order Line"; var ShareOfTotalCapCost: Decimal)
    var
        Qty: Decimal;
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ShareOfTotalCapCost := 0;
        Qty := ProdOrderLine.Quantity;
        ProdOrderLine.CalcSums(Quantity);
        if ProdOrderLine.Quantity <> 0 then
            ShareOfTotalCapCost := Qty / ProdOrderLine.Quantity;

        OnAfterCalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
#if not CLEAN26
        CostCalculationMgt.RunOnAfterCalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
#endif
    end;

    procedure CalcProdOrderLineStdCost(ProdOrderLine: Record "Prod. Order Line"; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal)
    var
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        QtyBase: Decimal;
        IsHandled: Boolean;
    begin
        if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.") and
           InvtAdjmtEntryOrder."Completely Invoiced"
        then begin
            Item."Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost";
            if CanIncNonInvCostIntoProductionItem() then
                Item."Single-Lvl Mat. Non-Invt. Cost" := InvtAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost";
            Item."Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost";
            Item."Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
            Item."Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
            Item."Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
            OnCalcProdOrderLineStdCostOnAfterCalcSingleLevelCost(Item, InvtAdjmtEntryOrder);
#if not CLEAN26
            CostCalculationMgt.RunOnCalcProdOrderLineStdCostOnAfterCalcSingleLevelCost(Item, InvtAdjmtEntryOrder);
#endif
            QtyBase := ProdOrderLine."Finished Qty. (Base)";
        end else begin
            Item.Get(ProdOrderLine."Item No.");
            UpdateCostFromSKU(Item, ProdOrderLine);
            QtyBase := ProdOrderLine."Quantity (Base)";
        end;

        IsHandled := false;
        OnBeforeCalcProdOrderLineStdCost(
          ProdOrderLine, QtyBase, CurrencyFactor, RndgPrec,
          StdMatCost, StdCapDirCost, StdSubDirCost, StdCapOvhdCost, StdMfgOvhdCost, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcProdOrderLineStdCost(
          ProdOrderLine, QtyBase, CurrencyFactor, RndgPrec,
          StdMatCost, StdCapDirCost, StdSubDirCost, StdCapOvhdCost, StdMfgOvhdCost, IsHandled);
#endif
        if IsHandled then
            exit;

        if CanIncNonInvCostIntoProductionItem() then
            StdMatCost := StdMatCost +
              Round(QtyBase * (Item."Single-Level Material Cost" + Item."Single-Lvl Mat. Non-Invt. Cost") * CurrencyFactor, RndgPrec)
        else
            StdMatCost := StdMatCost +
              Round(QtyBase * Item."Single-Level Material Cost" * CurrencyFactor, RndgPrec);
        StdCapDirCost := StdCapDirCost +
          Round(QtyBase * Item."Single-Level Capacity Cost" * CurrencyFactor, RndgPrec);
        StdSubDirCost := StdSubDirCost +
          Round(QtyBase * Item."Single-Level Subcontrd. Cost" * CurrencyFactor, RndgPrec);
        StdCapOvhdCost := StdCapOvhdCost +
          Round(QtyBase * Item."Single-Level Cap. Ovhd Cost" * CurrencyFactor, RndgPrec);
        StdMfgOvhdCost := StdMfgOvhdCost +
          Round(QtyBase * Item."Single-Level Mfg. Ovhd Cost" * CurrencyFactor, RndgPrec);
    end;

    procedure CalcProdOrderLineStdCost(ProdOrderLine: Record "Prod. Order Line"; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdNonInvMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal)
    var
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        QtyBase: Decimal;
    begin
        if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.") and
           InvtAdjmtEntryOrder."Completely Invoiced"
        then begin
            Item."Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost";
            Item."Single-Lvl Mat. Non-Invt. Cost" := InvtAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost";
            Item."Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost";
            Item."Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
            Item."Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
            Item."Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
            QtyBase := ProdOrderLine."Finished Qty. (Base)";
        end else begin
            Item.Get(ProdOrderLine."Item No.");
            UpdateCostFromSKU(Item, ProdOrderLine);
            QtyBase := ProdOrderLine."Quantity (Base)";
        end;

        StdMatCost := StdMatCost + Round(QtyBase * Item."Single-Level Material Cost" * CurrencyFactor, RndgPrec);
        StdNonInvMatCost := StdNonInvMatCost + Round(QtyBase * (Item."Single-Lvl Mat. Non-Invt. Cost") * CurrencyFactor, RndgPrec);
        StdCapDirCost := StdCapDirCost +
          Round(QtyBase * Item."Single-Level Capacity Cost" * CurrencyFactor, RndgPrec);
        StdSubDirCost := StdSubDirCost +
          Round(QtyBase * Item."Single-Level Subcontrd. Cost" * CurrencyFactor, RndgPrec);
        StdCapOvhdCost := StdCapOvhdCost +
          Round(QtyBase * Item."Single-Level Cap. Ovhd Cost" * CurrencyFactor, RndgPrec);
        StdMfgOvhdCost := StdMfgOvhdCost +
          Round(QtyBase * Item."Single-Level Mfg. Ovhd Cost" * CurrencyFactor, RndgPrec);
    end;

    local procedure UpdateCostFromSKU(var Item: Record Item; ProdOrderLine: Record "Prod. Order Line")
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if not Item.ShouldTryCostFromSKU() then
            exit;

        SKU.SetLoadFields(
            "Location Code",
            "Item No.",
            "Location Code",
            "Standard Cost",
            "Single-Level Material Cost",
            "Single-Level Capacity Cost",
            "Single-Level Subcontrd. Cost",
            "Single-Level Cap. Ovhd Cost",
            "Single-Level Mfg. Ovhd Cost");

        if not SKU.Get(ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code") then
            exit;

        Item."Single-Level Material Cost" := SKU."Single-Level Material Cost";
        Item."Single-Level Capacity Cost" := SKU."Single-Level Capacity Cost";
        Item."Single-Level Subcontrd. Cost" := SKU."Single-Level Subcontrd. Cost";
        Item."Single-Level Cap. Ovhd Cost" := SKU."Single-Level Cap. Ovhd Cost";
        Item."Single-Level Mfg. Ovhd Cost" := SKU."Single-Level Mfg. Ovhd Cost";
    end;

    procedure CalcProdOrderLineExpCost(ProdOrderLine: Record "Prod. Order Line"; ShareOfTotalCapCost: Decimal; var ExpMatCost: Decimal; var ExpCapDirCost: Decimal; var ExpSubDirCost: Decimal; var ExpCapOvhdCost: Decimal; var ExpMfgOvhdCost: Decimal)
    var
        WorkCenter: Record "Work Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ExpOperCost: Decimal;
        ExpMfgDirCost: Decimal;
        ExpCapDirCostRtng: Decimal;
        ExpSubDirCostRtng: Decimal;
        ExpCapOvhdCostRtng: Decimal;
        ExpOvhdCost: Decimal;
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        OnCalcProdOrderLineExpCostOnAfterProdOrderCompSetFilters(ProdOrderComp, ProdOrderLine);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcProdOrderLineExpCostOnAfterProdOrderCompSetFilters(ProdOrderComp, ProdOrderLine);
#endif
        if ProdOrderComp.Find('-') then
            repeat
                ExpMatCost := ExpMatCost + ProdOrderComp."Cost Amount";
            until ProdOrderComp.Next() = 0;

        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        OnCalcProdOrderLineExpCostOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine, ProdOrderLine);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcProdOrderLineExpCostOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine, ProdOrderLine);
#endif
        if ProdOrderRtngLine.Find('-') then
            repeat
                ExpOperCost :=
                  ProdOrderRtngLine."Expected Operation Cost Amt." -
                  ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
                OnCalcProdOrderLineExpCostOnExpOperCostCalculated(ExpOperCost, ProdOrderRtngLine);
#if not CLEAN26
                CostCalculationMgt.RunOnCalcProdOrderLineExpCostOnExpOperCostCalculated(ExpOperCost, ProdOrderRtngLine);
#endif
                if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                    if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                        Clear(WorkCenter);
                end else
                    Clear(WorkCenter);

                if WorkCenter."Subcontractor No." <> '' then
                    ExpSubDirCostRtng := ExpSubDirCostRtng + ExpOperCost
                else
                    ExpCapDirCostRtng := ExpCapDirCostRtng + ExpOperCost;
                ExpCapOvhdCostRtng := ExpCapOvhdCostRtng + ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
            until ProdOrderRtngLine.Next() = 0;

        ExpCapDirCost := ExpCapDirCost + Round(ExpCapDirCostRtng * ShareOfTotalCapCost);
        ExpSubDirCost := ExpSubDirCost + Round(ExpSubDirCostRtng * ShareOfTotalCapCost);
        ExpCapOvhdCost := ExpCapOvhdCost + Round(ExpCapOvhdCostRtng * ShareOfTotalCapCost);
        ExpMfgDirCost := ExpMatCost + ExpCapDirCost + ExpSubDirCost + ExpCapOvhdCost;
        ExpOvhdCost := ExpMfgOvhdCost;
        if ExpMfgDirCost = 0 then
            ExpMfgOvhdCost := ExpOvhdCost +
              Round(CostCalculationMgt.CalcOvhdCost(ExpMfgDirCost, ProdOrderLine."Indirect Cost %", ProdOrderLine."Overhead Rate", ProdOrderLine."Quantity (Base)"))
        else
            ExpMfgOvhdCost := Round(CostCalculationMgt.CalcOvhdCost(ExpMfgDirCost, ProdOrderLine."Indirect Cost %", ProdOrderLine."Overhead Rate", ProdOrderLine."Quantity (Base)"));

        OnAfterCalcProdOrderLineExpCost(ProdOrderLine, ShareOfTotalCapCost, ExpMatCost, ExpCapDirCost, ExpSubDirCost, ExpCapOvhdCost, ExpMfgOvhdCost);
#if not CLEAN26
        CostCalculationMgt.RunOnAfterCalcProdOrderLineExpCost(ProdOrderLine, ShareOfTotalCapCost, ExpMatCost, ExpCapDirCost, ExpSubDirCost, ExpCapOvhdCost, ExpMfgOvhdCost);
#endif
    end;

    procedure CalcProdOrderLineExpCost(ProdOrderLine: Record "Prod. Order Line"; ShareOfTotalCapCost: Decimal; var ExpMatCost: Decimal; var ExpNonInvMatCost: Decimal; var ExpCapDirCost: Decimal; var ExpSubDirCost: Decimal; var ExpCapOvhdCost: Decimal; var ExpMfgOvhdCost: Decimal)
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ExpOperCost: Decimal;
        ExpMfgDirCost: Decimal;
        ExpCapDirCostRtng: Decimal;
        ExpSubDirCostRtng: Decimal;
        ExpCapOvhdCostRtng: Decimal;
        ExpOvhdCost: Decimal;
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.");
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.Find('-') then
            repeat
                Item.Get(ProdOrderComp."Item No.");
                if Item.IsNonInventoriableType() then
                    ExpNonInvMatCost += ProdOrderComp."Cost Amount"
                else
                    ExpMatCost := ExpMatCost + ProdOrderComp."Cost Amount";
            until ProdOrderComp.Next() = 0;

        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        if ProdOrderRtngLine.Find('-') then
            repeat
                ExpOperCost :=
                  ProdOrderRtngLine."Expected Operation Cost Amt." -
                  ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
                if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                    if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                        Clear(WorkCenter);
                end else
                    Clear(WorkCenter);

                if WorkCenter."Subcontractor No." <> '' then
                    ExpSubDirCostRtng := ExpSubDirCostRtng + ExpOperCost
                else
                    ExpCapDirCostRtng := ExpCapDirCostRtng + ExpOperCost;
                ExpCapOvhdCostRtng := ExpCapOvhdCostRtng + ProdOrderRtngLine."Expected Capacity Ovhd. Cost";
            until ProdOrderRtngLine.Next() = 0;

        ExpCapDirCost := ExpCapDirCost + Round(ExpCapDirCostRtng * ShareOfTotalCapCost);
        ExpSubDirCost := ExpSubDirCost + Round(ExpSubDirCostRtng * ShareOfTotalCapCost);
        ExpCapOvhdCost := ExpCapOvhdCost + Round(ExpCapOvhdCostRtng * ShareOfTotalCapCost);
        ExpMfgDirCost := ExpMatCost + ExpNonInvMatCost + ExpCapDirCost + ExpSubDirCost + ExpCapOvhdCost;
        ExpOvhdCost := ExpMfgOvhdCost + ProdOrderLine."Overhead Rate" * ProdOrderLine."Quantity (Base)";
        ExpMfgOvhdCost := ExpOvhdCost +
          Round(CostCalculationMgt.CalcOvhdCost(ExpMfgDirCost, ProdOrderLine."Indirect Cost %", 0, 0));
    end;

    procedure CalcProdOrderLineActCost(ProdOrderLine: Record "Prod. Order Line"; var ActMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    var
        TempSourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        OutputQty: Decimal;
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then begin
            ActMatCost := 0;
            ActCapDirCost := 0;
            ActSubDirCost := 0;
            ActCapOvhdCost := 0;
            ActMfgOvhdCost := 0;
            ActMatCostCostACY := 0;
            ActCapDirCostACY := 0;
            ActCapOvhdCostACY := 0;
            ActSubDirCostACY := 0;
            ActMfgOvhdCostACY := 0;
            exit;
        end;

        OnCalcProdOrderLineActCostOnBeforeSetProdOrderLine(ProdOrderLine, ActMatCost, ActCapDirCost, ActSubDirCost, ActCapOvhdCost, ActMfgOvhdCost, ActMatCostCostACY, ActCapDirCostACY, ActSubDirCostACY, ActCapOvhdCostACY, ActMfgOvhdCostACY);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcProdOrderLineActCostOnBeforeSetProdOrderLine(ProdOrderLine, ActMatCost, ActCapDirCost, ActSubDirCost, ActCapOvhdCost, ActMfgOvhdCost, ActMatCostCostACY, ActCapDirCostACY, ActSubDirCostACY, ActCapOvhdCostACY, ActMfgOvhdCostACY);
#endif
        TempSourceInvtAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
        OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(TempSourceInvtAdjmtEntryOrder, false);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(TempSourceInvtAdjmtEntryOrder, OutputQty, TempSourceInvtAdjmtEntryOrder);

        if not CanIncNonInvCostIntoProductionItem() then
            ActMatCost += TempSourceInvtAdjmtEntryOrder."Single-Level Material Cost"
        else
            ActMatCost += TempSourceInvtAdjmtEntryOrder."Single-Level Material Cost" + TempSourceInvtAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost";
        ActCapDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Capacity Cost";
        ActSubDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
        ActCapOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
        ActMfgOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
        if not CanIncNonInvCostIntoProductionItem() then
            ActMatCostCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)"
        else
            ActMatCostCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)" + TempSourceInvtAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)";
        ActCapDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)";
        ActCapOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)";
        ActSubDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)";
        ActMfgOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)";
    end;

    procedure CalcProdOrderLineActCost(ProdOrderLine: Record "Prod. Order Line"; var ActMatCost: Decimal; var ActNonInvMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostACY: Decimal; var ActNonInvMatCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    var
        TempSourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        OutputQty: Decimal;
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then begin
            ActMatCost := 0;
            ActNonInvMatCost := 0;
            ActCapDirCost := 0;
            ActSubDirCost := 0;
            ActCapOvhdCost := 0;
            ActMfgOvhdCost := 0;
            ActMatCostACY := 0;
            ActNonInvMatCostACY := 0;
            ActCapDirCostACY := 0;
            ActCapOvhdCostACY := 0;
            ActSubDirCostACY := 0;
            ActMfgOvhdCostACY := 0;
            exit;
        end;

        TempSourceInvtAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);
        OutputQty := CalcInvtAdjmtOrder.CalcOutputQty(TempSourceInvtAdjmtEntryOrder, false);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(TempSourceInvtAdjmtEntryOrder, OutputQty, TempSourceInvtAdjmtEntryOrder);

        ActMatCost += TempSourceInvtAdjmtEntryOrder."Single-Level Material Cost";
        ActNonInvMatCost += TempSourceInvtAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost";
        ActCapDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Capacity Cost";
        ActSubDirCost += TempSourceInvtAdjmtEntryOrder."Single-Level Subcontrd. Cost";
        ActCapOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
        ActMfgOvhdCost += TempSourceInvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
        ActMatCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)";
        ActNonInvMatCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)";
        ActCapDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)";
        ActCapOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)";
        ActSubDirCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)";
        ActMfgOvhdCostACY += TempSourceInvtAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)";
    end;

    procedure CalcProdOrderExpCapNeed(ProdOrder: Record "Production Order"; DrillDown: Boolean): Decimal
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        WorkCenter: Record "Work Center";
        NeededTime: Decimal;
        ExpectedCapNeed: Decimal;
    begin
        OnBeforeCalcProdOrderExpCapNeed(ProdOrder, ProdOrderCapNeed, ProdOrderRtngLine);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcProdOrderExpCapNeed(ProdOrder, ProdOrderCapNeed, ProdOrderRtngLine);
#endif

        if ProdOrder.Status <> ProdOrder.Status::Finished then begin
            ProdOrderCapNeed.SetRange(Status, ProdOrder.Status);
            ProdOrderCapNeed.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderCapNeed.SetFilter(Type, ProdOrder.GetFilter("Capacity Type Filter"));
            ProdOrderCapNeed.SetFilter("No.", ProdOrder.GetFilter("Capacity No. Filter"));
            ProdOrderCapNeed.SetFilter("Work Center No.", ProdOrder.GetFilter("Work Center Filter"));
            ProdOrderCapNeed.SetFilter(Date, ProdOrder.GetFilter("Date Filter"));
            ProdOrderCapNeed.SetRange("Requested Only", false);
            OnCalcProdOrderExpCapNeedOnAfterProdOrderCapNeedSetFilters(ProdOrderCapNeed, ProdOrder);
#if not CLEAN26
            CostCalculationMgt.RunOnCalcProdOrderExpCapNeedOnAfterProdOrderCapNeedSetFilters(ProdOrderCapNeed, ProdOrder);
#endif
            if ProdOrderCapNeed.FindSet() then begin
                repeat
                    if ProdOrderCapNeed.Type = ProdOrderCapNeed.Type::"Work Center" then begin
                        if not WorkCenter.Get(ProdOrderCapNeed."No.") then
                            Clear(WorkCenter);
                    end else
                        Clear(WorkCenter);
                    if WorkCenter."Subcontractor No." = '' then begin
                        NeededTime += ProdOrderCapNeed."Needed Time (ms)";
                        ProdOrderCapNeed.Mark(true);
                    end;
                until ProdOrderCapNeed.Next() = 0;
                ProdOrderCapNeed.MarkedOnly(true);
            end;
            if DrillDown then
                PAGE.Run(0, ProdOrderCapNeed, ProdOrderCapNeed."Needed Time")
            else
                exit(NeededTime);
        end else begin
            ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
            if ProdOrderRtngLine.FindSet() then begin
                repeat
                    if ProdOrderRtngLine.Type = ProdOrderRtngLine.Type::"Work Center" then begin
                        if not WorkCenter.Get(ProdOrderRtngLine."No.") then
                            Clear(WorkCenter);
                    end else
                        Clear(WorkCenter);
                    if WorkCenter."Subcontractor No." = '' then begin
                        ExpectedCapNeed += ProdOrderRtngLine."Expected Capacity Need";
                        OnCalcProdOrderExpCapNeedOnBeforeMarkNotFinishedProdOrderRtngLine(ProdOrderRtngLine, WorkCenter, ExpectedCapNeed);
#if not CLEAN26
                        CostCalculationMgt.RunOnCalcProdOrderExpCapNeedOnBeforeMarkNotFinishedProdOrderRtngLine(ProdOrderRtngLine, WorkCenter, ExpectedCapNeed);
#endif
                        ProdOrderRtngLine.Mark(true);
                    end;
                until ProdOrderRtngLine.Next() = 0;
                ProdOrderRtngLine.MarkedOnly(true);
            end;
            if DrillDown then
                PAGE.Run(0, ProdOrderRtngLine, ProdOrderRtngLine."Expected Capacity Need")
            else
                exit(ExpectedCapNeed);
        end;
    end;

    procedure CalcProdOrderActTimeUsed(ProdOrder: Record "Production Order"; DrillDown: Boolean): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
        Qty: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCalcProdOrderActTimeUsed(ProdOrder, CapLedgEntry);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcProdOrderActTimeUsed(ProdOrder, CapLedgEntry);
#endif

        if ProdOrder.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", ProdOrder."No.");
        OnCalcProdOrderActTimeUsedOnAfterCapacityLedgerEntrySetFilters(CapLedgEntry, ProdOrder);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcProdOrderActTimeUsedOnAfterCapacityLedgerEntrySetFilters(CapLedgEntry, ProdOrder);
#endif
        if CapLedgEntry.FindSet() then begin
            repeat
                ClearWorkCenter(CapLedgEntry, WorkCenter);
                if WorkCenter."Subcontractor No." = '' then begin
                    if CapLedgEntry."Qty. per Cap. Unit of Measure" = 0 then
                        GetCapacityUoM(CapLedgEntry);

                    IsHandled := false;
                    OnCalcProdOrderActTimeUsedOnBeforeCalcQty(CapLedgEntry, Qty, IsHandled);
#if not CLEAN26
                    CostCalculationMgt.RunOnCalcProdOrderActTimeUsedOnBeforeCalcQty(CapLedgEntry, Qty, IsHandled);
#endif
                    if not IsHandled then
                        Qty +=
                            CapLedgEntry.Quantity /
                            CapLedgEntry."Qty. per Cap. Unit of Measure" *
                            CalendarMgt.TimeFactor(CapLedgEntry."Cap. Unit of Measure Code");
                    CapLedgEntry.Mark(true);
                end;
            until CapLedgEntry.Next() = 0;
            CapLedgEntry.MarkedOnly(true);
        end;

        if DrillDown then
            PAGE.Run(0, CapLedgEntry, CapLedgEntry.Quantity)
        else
            exit(Qty);
    end;

    local procedure GetCapacityUoM(var CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        WorkCenter: Record "Work Center";
    begin
        CapacityLedgerEntry."Qty. per Cap. Unit of Measure" := 1;
        if WorkCenter.Get(CapacityLedgerEntry."Work Center No.") then
            CapacityLedgerEntry."Cap. Unit of Measure Code" := WorkCenter."Unit of Measure Code";
    end;

    local procedure ClearWorkCenter(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var WorkCenter: Record "Work Center")
    begin
        if CapacityLedgerEntry.Type = CapacityLedgerEntry.Type::"Work Center" then begin
            if not WorkCenter.Get(CapacityLedgerEntry."No.") then
                Clear(WorkCenter);
        end else
            Clear(WorkCenter);
        OnAfterClearWorkCenter(CapacityLedgerEntry, WorkCenter);
#if not CLEAN26
        CostCalculationMgt.RunOnAfterClearWorkCenter(CapacityLedgerEntry, WorkCenter);
#endif
    end;

    procedure CalcOutputQtyBaseOnPurchOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        OutstandingBaseQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OutstandingBaseQty := 0;
        OnBeforeCalcOutputQtyBaseOnPurchOrder(ProdOrderLine, ProdOrderRtngLine, OutstandingBaseQty, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcOutputQtyBaseOnPurchOrder(ProdOrderLine, ProdOrderRtngLine, OutstandingBaseQty, IsHandled);
#endif
        if IsHandled then
            exit;

        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        PurchLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        if PurchLine.Find('-') then
            repeat
                if Item."No." <> PurchLine."No." then
                    Item.Get(PurchLine."No.");
                OutstandingBaseQty :=
                  OutstandingBaseQty +
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, PurchLine."Unit of Measure Code") * PurchLine."Outstanding Quantity";
            until PurchLine.Next() = 0;
        exit(OutstandingBaseQty);
    end;

    procedure CalcActOutputQtyBase(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetFilterByProdOrderRoutingLine(
            ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
            ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        OnCalcActOutputQtyBaseOnAfterSetFilters(CapLedgEntry, ProdOrderLine, ProdOrderRtngLine);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcActOutputQtyBaseOnAfterSetFilters(CapLedgEntry, ProdOrderLine, ProdOrderRtngLine);
#endif
        CapLedgEntry.CalcSums("Output Quantity");
        exit(CapLedgEntry."Output Quantity");
    end;

    procedure CalcActualOutputQtyWithNoCapacity(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.Status.AsInteger() < ProdOrderLine.Status::Released.AsInteger() then
            exit(0);

        CapLedgEntry.SetFilterByProdOrderRoutingLine(
            ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
            ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        CapLedgEntry.SetRange(Quantity, 0);
        CapLedgEntry.CalcSums("Output Quantity", "Scrap Quantity");
        exit(CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity");
    end;

    procedure CalcActQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetFilterByProdOrderRoutingLine(
            ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
            ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        CapLedgEntry.CalcSums(CapLedgEntry.Quantity);
        exit(CapLedgEntry.Quantity / ProdOrderLine."Qty. per Unit of Measure");
    end;

    procedure CalcActOperOutputAndScrap(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line") OutputQtyBase: Decimal
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if ProdOrderLine.IsStatusLessThanReleased() then
            exit(0);

        CapLedgEntry.SetFilterByProdOrderRoutingLine(
            ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
            ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        CapLedgEntry.SetRange("Last Output Line", true);
        OnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(CapLedgEntry);
#if not CLEAN26
        CostCalculationMgt.RunOnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(CapLedgEntry);
#endif
        CapLedgEntry.CalcSums("Output Quantity", "Scrap Quantity");
        OutputQtyBase := CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity";

        exit(OutputQtyBase);
    end;

    procedure CalcActNeededQtyBase(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; OutputQtyBase: Decimal) Result: Decimal
    var
        CompQtyBasePerMfgQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActNeededQtyBase(OutputQtyBase, ProdOrderComp, ProdOrderLine, Result, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcActNeededQtyBase(OutputQtyBase, ProdOrderComp, ProdOrderLine, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if (ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::"Pick + Backward") and
            (ProdOrderComp."Calculation Formula" = ProdOrderComp."Calculation Formula"::" ") then
            CompQtyBasePerMfgQtyBase := (ProdOrderComp."Quantity per" * ProdOrderComp."Qty. per Unit of Measure") / ProdOrderLine."Qty. per Unit of Measure"
        else
            CompQtyBasePerMfgQtyBase := (ProdOrderComp."Quantity" * ProdOrderComp."Qty. per Unit of Measure") / ProdOrderLine."Qty. per Unit of Measure";

        if (ProdOrderComp."Calculation Formula" = ProdOrderComp."Calculation Formula"::"Fixed Quantity") and (OutputQtyBase <> 0) then
            exit(CalcQtyAdjdForBOMScrap(CompQtyBasePerMfgQtyBase, ProdOrderComp."Scrap %"))
        else
            exit(CalcQtyAdjdForBOMScrap(OutputQtyBase * CompQtyBasePerMfgQtyBase, ProdOrderComp."Scrap %"));
    end;

    procedure CalcActTimeAndQtyBase(ProdOrderLine: Record "Prod. Order Line"; OperationNo: Code[10]; var ActRunTime: Decimal; var ActSetupTime: Decimal; var ActOutputQty: Decimal; var ActScrapQty: Decimal)
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.SetFilterByProdOrderRoutingLine(
            ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
            ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
        CapLedgEntry.SetRange("Operation No.", OperationNo);
        OnCalcActTimeAndQtyBaseOnAfterFilterCapLedgEntry(CapLedgEntry);
        if CapLedgEntry.Find('-') then
            repeat
                ActSetupTime += CapLedgEntry."Setup Time";
                ActRunTime += CapLedgEntry."Run Time";
                // Base Units
                ActOutputQty += CapLedgEntry."Output Quantity";
                ActScrapQty += CapLedgEntry."Scrap Quantity";
            until CapLedgEntry.Next() = 0;
    end;

    procedure CalcCompItemQtyBase(ProdBOMComponent: Record "Production BOM Line"; CalculationDate: Date; MfgItemQtyBase: Decimal; RtngNo: Code[20]; AdjdForRtngScrap: Boolean): Decimal
    var
        RtngLine: Record "Routing Line";
        IsHandled: Boolean;
    begin
        OnBeforeCalcCompItemQtyBase(ProdBOMComponent, CalculationDate, MfgItemQtyBase, RtngNo, AdjdForRtngScrap, IsHandled);
        if IsHandled then
            exit(MfgItemQtyBase);

        if ProdBOMComponent."Calculation Formula" = ProdBOMComponent."Calculation Formula"::"Fixed Quantity" then
            MfgItemQtyBase := ProdBOMComponent.Quantity * ProdBOMComponent.GetQtyPerUnitOfMeasure()
        else begin
            MfgItemQtyBase := CalcQtyAdjdForBOMScrap(MfgItemQtyBase, ProdBOMComponent."Scrap %");
            if AdjdForRtngScrap and FindRoutingLine(RtngLine, ProdBOMComponent, CalculationDate, RtngNo) then
                MfgItemQtyBase := CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, RtngLine."Scrap Factor % (Accumulated)", RtngLine."Fixed Scrap Qty. (Accum.)");
            MfgItemQtyBase := MfgItemQtyBase * ProdBOMComponent.Quantity * ProdBOMComponent.GetQtyPerUnitOfMeasure();
        end;
        exit(MfgItemQtyBase);
    end;

    procedure CalculateCostTime(MfgItemQtyBase: Decimal; SetupTime: Decimal; SetupTimeUOMCode: Code[10]; RunTime: Decimal; RunTimeUOMCode: Code[10]; RtngLotSize: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; WorkCenterNo: Code[20]; UnitCostCalculation: Enum "Unit Cost Calculation Type"; CostInclSetup: Boolean; ConcurrentCapacities: Decimal) CostTime: Decimal
    var
        ShopCalendarManagement: Codeunit "Shop Calendar Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        RunTimePer: Decimal;
    begin
        if ConcurrentCapacities = 0 then
            ConcurrentCapacities := 1;

        case UnitCostCalculation of
            UnitCostCalculation::Time:
                begin
                    if RtngLotSize = 0 then
                        RtngLotSize := 1;
                    RunTimePer := RunTime / RtngLotSize;
                    CostTime :=
                      CalcQtyAdjdForRoutingScrap(
                        Round(
                          RunTimePer * MfgItemQtyBase * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UnitOfMeasureManagement.TimeRndPrecision()),
                        ScrapFactorPctAccum,
                        Round(
                          RunTimePer * FixedScrapQtyAccum * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, RunTimeUOMCode),
                          UnitOfMeasureManagement.TimeRndPrecision()));
                    if CostInclSetup then
                        CostTime :=
                          CostTime +
                          Round(
                            ConcurrentCapacities *
                            SetupTime * ShopCalendarManagement.QtyperTimeUnitofMeasure(WorkCenterNo, SetupTimeUOMCode),
                            UnitOfMeasureManagement.TimeRndPrecision());
                end;
            UnitCostCalculation::Units:
                CostTime := CalcQtyAdjdForRoutingScrap(MfgItemQtyBase, ScrapFactorPctAccum, FixedScrapQtyAccum);
        end;

        OnAfterCalculateCostTime(MfgItemQtyBase, ScrapFactorPctAccum, FixedScrapQtyAccum, UnitCostCalculation, CostTime);
    end;

    procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; ProdBOMLine: Record "Production BOM Line"; CalculationDate: Date; RoutingNo: Code[20]) RecFound: Boolean
    var
        VersionMgt: Codeunit VersionManagement;
    begin
        if RoutingNo = '' then
            exit(false);

        RecFound := false;
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionMgt.GetRtngVersion(RoutingNo, CalculationDate, true));
        OnFindRoutingLineOnAfterRoutingLineSetFilters(RoutingLine, ProdBOMLine, CalculationDate, RoutingNo);
#if not CLEAN26
        CostCalculationMgt.RunOnFindRountingLineOnAfterRoutingLineSetFilters(RoutingLine, ProdBOMLine, CalculationDate, RoutingNo);
#endif
        if not RoutingLine.IsEmpty() then begin
            if ProdBOMLine."Routing Link Code" <> '' then
                RoutingLine.SetRange("Routing Link Code", ProdBOMLine."Routing Link Code");
            RecFound := RoutingLine.FindFirst();
            if not RecFound then begin
                RoutingLine.SetRange("Routing Link Code");
                RecFound := RoutingLine.FindFirst();
            end;
        end;

        exit(RecFound);
    end;

    procedure CalcQtyAdjdForBOMScrap(Qty: Decimal; ScrapPct: Decimal) QtyAdjdForBOMScrap: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAdjdForBOMScrap(Qty, ScrapPct, QtyAdjdForBomScrap, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcQtyAdjdForBOMScrap(Qty, ScrapPct, QtyAdjdForBomScrap, IsHandled);
#endif
        if not IsHandled then
            exit(Qty * (1 + ScrapPct / 100));
    end;

    procedure CalcQtyAdjdForRoutingScrap(Qty: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal) QtyAdjdForRoutingScrap: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAdjdForRoutingScrap(Qty, ScrapFactorPctAccum, FixedScrapQtyAccum, QtyAdjdForRoutingScrap, IsHandled);
#if not CLEAN26
        CostCalculationMgt.RunOnBeforeCalcQtyAdjdForRoutingScrap(Qty, ScrapFactorPctAccum, FixedScrapQtyAccum, QtyAdjdForRoutingScrap, IsHandled);
#endif
        if not IsHandled then
            exit(Qty * (1 + ScrapFactorPctAccum) + FixedScrapQtyAccum);
    end;

    procedure CanIncNonInvCostIntoProductionItem(): Boolean
    begin
        ManufacturingSetup.Get();
        exit(ManufacturingSetup."Inc. Non. Inv. Cost To Prod");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Calculation Management", 'OnCanIncNonInvCostIntoProductionItem', '', true, true)]
    local procedure OnCanIncNonInvCostIntoProductionItem(var Result: Boolean)
    begin
        ManufacturingSetup.Get();
        Result := ManufacturingSetup."Inc. Non. Inv. Cost To Prod";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingCostPerUnit(Type: Enum Microsoft.Manufacturing.Capacity."Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; MachineCenter: Record Microsoft.Manufacturing.MachineCenter."Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingCostPerUnit(Type: Enum Microsoft.Manufacturing.Capacity."Capacity Type"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; MachineCenter: Record Microsoft.Manufacturing.MachineCenter."Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcShareOfTotalCapCost(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ShareOfTotalCapCost: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineStdCostOnAfterCalcSingleLevelCost(var Item: record Item; InvtAdjmtEntryOrder: record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLineStdCost(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; QtyBase: Decimal; CurrencyFactor: Decimal; RndgPrec: Decimal; var StdMatCost: Decimal; var StdCapDirCost: Decimal; var StdSubDirCost: Decimal; var StdCapOvhdCost: Decimal; var StdMfgOvhdCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnAfterProdOrderCompSetFilters(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineExpCostOnExpOperCostCalculated(var ExpOperCost: Decimal; ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcProdOrderLineExpCost(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ShareOfTotalCapCost: Decimal; var ExpMatCost: Decimal; var ExpCapDirCost: Decimal; var ExpSubDirCost: Decimal; var ExpCapOvhdCost: Decimal; var ExpMfgOvhdCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderLineActCostOnBeforeSetProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ActMatCost: Decimal; var ActCapDirCost: Decimal; var ActSubDirCost: Decimal; var ActCapOvhdCost: Decimal; var ActMfgOvhdCost: Decimal; var ActMatCostCostACY: Decimal; var ActCapDirCostACY: Decimal; var ActSubDirCostACY: Decimal; var ActCapOvhdCostACY: Decimal; var ActMfgOvhdCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderExpCapNeed(ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderCapacityNeed: Record Microsoft.Manufacturing.Document."Prod. Order Capacity Need"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderExpCapNeedOnAfterProdOrderCapNeedSetFilters(var ProdOrderCapNeed: Record Microsoft.Manufacturing.Document."Prod. Order Capacity Need"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderExpCapNeedOnBeforeMarkNotFinishedProdOrderRtngLine(ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; WorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; var ExpectedCapNeed: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderActTimeUsed(ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderActTimeUsedOnAfterCapacityLedgerEntrySetFilters(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdOrderActTimeUsedOnBeforeCalcQty(CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var Qty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearWorkCenter(var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var WorkCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcOutputQtyBaseOnPurchOrder(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var OutstandingBaseQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActOutputQtyBaseOnAfterSetFilters(var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActOperOutputAndScrapOnAfterFilterCapLedgEntry(var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActNeededQtyBase(var OutputQtyBase: Decimal; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcActTimeAndQtyBaseOnAfterFilterCapLedgEntry(var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCompItemQtyBase(ProdBOMComponent: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; CalculationDate: Date; var MfgItemQtyBase: Decimal; RtngNo: Code[20]; AdjdForRtngScrap: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRoutingLineOnAfterRoutingLineSetFilters(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; CalculationDate: Date; RoutingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAdjdForBOMScrap(Qty: Decimal; ScrapPct: Decimal; var QtyAdjdForBomScrap: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAdjdForRoutingScrap(Qty: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; var QtyAdjdForRoutingScrap: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCostTime(MfgItemQtyBase: Decimal; ScrapFactorPctAccum: Decimal; FixedScrapQtyAccum: Decimal; UnitCostCalculationType: Enum "Unit Cost Calculation Type"; var CostTime: Decimal)
    begin
    end;
}