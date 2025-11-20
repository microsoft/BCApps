// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;

codeunit 5812 "Calculate Standard Cost"
{

    trigger OnRun()
    begin
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        GLSetup: Record "General Ledger Setup";
        TempItem: Record Item temporary;
        TempSKU: Record "Stockkeeping Unit" temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        TempPriceListLine: Record "Price List Line" temporary;
        TempProductionBOMVersion: Record "Production BOM Version" temporary;
        TempRoutingVersion: Record "Routing Version" temporary;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        VersionMgt: Codeunit VersionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        MaxLevel: Integer;
        NextPriceListLineNo: Integer;
        CalculationDate: Date;
        CalcMultiLevel: Boolean;
        UseAssemblyList: Boolean;
        LogErrors: Boolean;
        ShowDialog: Boolean;
        StdCostWkshName: Text[50];
        ColIdx: Option ,StdCost,ExpCost,ActCost,Dev,"Var";
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Too many levels. Must be below %1.';
#pragma warning restore AA0470
        Text001: Label '&Top level,&All levels';
        Text002: Label '@1@@@@@@@@@@@@@';
#pragma warning disable AA0470
        CalcMfgPrompt: Label 'One or more subassemblies on the assembly list for item %1 use replenishment system Prod. Order. Do you want to calculate standard cost for those subassemblies?';
#pragma warning restore AA0470
        TargetText: Label 'Standard Cost,Unit Price';
#pragma warning disable AA0470
        RecursionInstruction: Label 'Calculate the %3 of item %1 %2 by rolling up the assembly list components. Select All levels to include and update the %3 of any subassemblies.', Comment = '%1 = Item No., %2 = Description';
        NonAssemblyItemError: Label 'Item %1 %2 does not use replenishment system Assembly. The %3 will not be calculated.', Comment = '%1 = Item No., %2 = Description';
        NoAssemblyListError: Label 'Item %1 %2 has no assembly list. The %3 will not be calculated.', Comment = '%1 = Item No., %2 = Description';
        NonAssemblyComponentWithList: Label 'One or more subassemblies on the assembly list for this item does not use replenishment system Assembly. The %1 for these subassemblies will not be calculated. Are you sure that you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetProperties(NewCalculationDate: Date; NewCalcMultiLevel: Boolean; NewUseAssemblyList: Boolean; NewLogErrors: Boolean; NewStdCostWkshName: Text[50]; NewShowDialog: Boolean)
    begin
        TempItem.DeleteAll();
        TempProductionBOMVersion.DeleteAll();
        TempRoutingVersion.DeleteAll();
        ClearAll();

        OnBeforeSetProperties(NewCalculationDate, NewCalcMultiLevel, NewUseAssemblyList, NewLogErrors, NewStdCostWkshName, NewShowDialog);

        CalculationDate := NewCalculationDate;
        CalcMultiLevel := NewCalcMultiLevel;
        UseAssemblyList := NewUseAssemblyList;
        LogErrors := NewLogErrors;
        StdCostWkshName := NewStdCostWkshName;
        ShowDialog := NewShowDialog;

        MaxLevel := 50;
        MfgSetup.Get();
        GLSetup.Get();

        OnAfterSetProperties(NewCalculationDate, NewCalcMultiLevel, NewUseAssemblyList, NewLogErrors, NewStdCostWkshName, NewShowDialog);
    end;

    procedure TestPreconditions(var Item: Record Item; var TempNewProductionBOMVersion: Record "Production BOM Version" temporary; var NewRtngVersionErrBuf: Record "Routing Version")
    var
        TempItem2: Record Item temporary;
    begin
        CalcItems(Item, TempItem2);

        TempProductionBOMVersion.Reset();
        if TempProductionBOMVersion.Find('-') then
            repeat
                TempNewProductionBOMVersion := TempProductionBOMVersion;
                TempNewProductionBOMVersion.Insert();
            until TempProductionBOMVersion.Next() = 0;

        TempRoutingVersion.Reset();
        if TempRoutingVersion.Find('-') then
            repeat
                NewRtngVersionErrBuf := TempRoutingVersion;
                NewRtngVersionErrBuf.Insert();
            until TempRoutingVersion.Next() = 0;
    end;

    local procedure AnalyzeAssemblyList(var Item: Record Item; var Depth: Integer; var NonAssemblyItemWithList: Boolean; var ContainsProdBOM: Boolean)
    var
        BOMComponent: Record "BOM Component";
        SubItem: Record Item;
        BaseDepth: Integer;
        MaxDepth: Integer;
    begin
        if Item.IsMfgItem() and ((Item."Production BOM No." <> '') or (Item."Routing No." <> '')) then begin
            ContainsProdBOM := true;
            if Item."Production BOM No." <> '' then
                AnalyzeProdBOM(Item."Production BOM No.", Depth, NonAssemblyItemWithList, ContainsProdBOM)
            else
                Depth += 1;
            exit
        end;
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        if BOMComponent.FindSet() then begin
            if not Item.IsAssemblyItem() then begin
                NonAssemblyItemWithList := true;
                exit
            end;
            Depth += 1;
            BaseDepth := Depth;
            repeat
                if BOMComponent.Type = BOMComponent.Type::Item then begin
                    SubItem.Get(BOMComponent."No.");
                    MaxDepth := BaseDepth;
                    AnalyzeAssemblyList(SubItem, MaxDepth, NonAssemblyItemWithList, ContainsProdBOM);
                    if MaxDepth > Depth then
                        Depth := MaxDepth
                end
            until BOMComponent.Next() = 0
        end;
    end;

    local procedure AnalyzeProdBOM(ProductionBOMNo: Code[20]; var Depth: Integer; var NonAssemblyItemWithList: Boolean; var ContainsProdBOM: Boolean)
    var
        ProdBOMLine: Record "Production BOM Line";
        SubItem: Record Item;
        PBOMVersionCode: Code[20];
        BaseDepth: Integer;
        MaxDepth: Integer;
    begin
        SetProdBOMFilters(ProdBOMLine, PBOMVersionCode, ProductionBOMNo);
        if ProdBOMLine.FindSet() then begin
            Depth += 1;
            BaseDepth := Depth;
            repeat
                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            SubItem.Get(ProdBOMLine."No.");
                            MaxDepth := BaseDepth;
                            AnalyzeAssemblyList(SubItem, MaxDepth, NonAssemblyItemWithList, ContainsProdBOM);
                            if MaxDepth > Depth then
                                Depth := MaxDepth
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        begin
                            MaxDepth := BaseDepth;
                            AnalyzeProdBOM(ProdBOMLine."No.", MaxDepth, NonAssemblyItemWithList, ContainsProdBOM);
                            MaxDepth -= 1;
                            if MaxDepth > Depth then
                                Depth := MaxDepth
                        end;
                end;
            until ProdBOMLine.Next() = 0
        end
    end;

    local procedure PrepareAssemblyCalculation(var Item: Record Item; var Depth: Integer; Target: Option "Standard Cost","Unit Price"; var ContainsProdBOM: Boolean) Instruction: Text[1024]
    var
        CalculationTarget: Text;
        SubNonAssemblyItemWithList: Boolean;
    begin
        CalculationTarget := SelectStr(Target, TargetText);
        if not Item.IsAssemblyItem() then
            Error(NonAssemblyItemError, Item."No.", Item.Description, CalculationTarget);
        AnalyzeAssemblyList(Item, Depth, SubNonAssemblyItemWithList, ContainsProdBOM);
        if Depth = 0 then
            Error(NoAssemblyListError, Item."No.", Item.Description, CalculationTarget);
        Instruction := StrSubstNo(RecursionInstruction, Item."No.", Item.Description, CalculationTarget);
        if SubNonAssemblyItemWithList then
            Instruction += StrSubstNo(NonAssemblyComponentWithList, CalculationTarget)
    end;

    procedure CalcItem(ItemNo: Code[20]; NewUseAssemblyList: Boolean)
    var
        Item: Record Item;
        ItemCostMgt: Codeunit ItemCostManagement;
        Instruction: Text[1024];
        NewCalcMultiLevel: Boolean;
        Depth: Integer;
        AssemblyContainsProdBOM: Boolean;
        CalcMfgItems: Boolean;
        IsHandled: Boolean;
        ShowStrMenu: Boolean;
        ShowConfirm: Boolean;
    begin
        Item.Get(ItemNo);
        IsHandled := false;
        OnBeforeCalcItem(Item, NewUseAssemblyList, IsHandled);
        if IsHandled then
            exit;

        if NewUseAssemblyList then
            Instruction := PrepareAssemblyCalculation(Item, Depth, 1, AssemblyContainsProdBOM) // 1=StandardCost
        else
            if not Item.IsMfgItem() then
                exit;

        ShowStrMenu := not NewUseAssemblyList or (Depth > 1);
        OnCalcItemOnBeforeShowStrMenu(Item, ShowStrMenu, NewCalcMultiLevel);
        if ShowStrMenu then
            case StrMenu(Text001, 1, Instruction) of
                0:
                    exit;
                1:
                    NewCalcMultiLevel := false;
                2:
                    NewCalcMultiLevel := true;
            end;

        SetProperties(WorkDate(), NewCalcMultiLevel, NewUseAssemblyList, false, '', false);

        if NewUseAssemblyList then begin
            ShowConfirm := NewCalcMultiLevel and AssemblyContainsProdBOM;
            OnCalcItemOnAfterCalcShowConfirm(Item, CalcMfgItems, ShowConfirm);
            if ShowConfirm then
                CalcMfgItems := Confirm(CalcMfgPrompt, false, Item."No.");
            CalcAssemblyItem(ItemNo, Item, 0, CalcMfgItems)
        end else
            CalcMfgItem(ItemNo, Item, 0);

        if TempItem.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('procedure that was implemented to throw the error has now been identified as unnecessary', '27.0')]
    procedure CalcItemForNonInventoryValue(var Item: Record Item)
    begin
    end;

    [Obsolete('procedure that was implemented to throw the error has now been identified as unnecessary', '27.0')]
    procedure CalcSKUForNonInventoryValue(var SKU: Record "Stockkeeping Unit")
    begin
    end;
#endif

    procedure CalcItemSKU(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20])
    var
        SKU: Record "Stockkeeping Unit";
        ItemCostMgt: Codeunit ItemCostManagement;
        Instruction: Text[1024];
        NewCalcMultiLevel: Boolean;
        Depth: Integer;
        ShowStrMenu: Boolean;
    begin
        SKU.Get(LocationCode, ItemNo, VariantCode);

        if not SKU.IsMfgSKU() then
            exit;

        ShowStrMenu := (Depth > 1);
        if ShowStrMenu then
            case StrMenu(Text001, 1, Instruction) of
                0:
                    exit;
                1:
                    NewCalcMultiLevel := false;
                2:
                    NewCalcMultiLevel := true;
            end;

        SetProperties(WorkDate(), NewCalcMultiLevel, false, false, '', false);
        CalcMfgSKU(ItemNo, LocationCode, VariantCode, SKU, 0);

        if TempSKU.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostSharesForSKU(TempSKU);
            until TempSKU.Next() = 0;

        if TempItem.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
    end;

    procedure CalcItems(var Item: Record Item; var NewTempItem: Record Item)
    var
        Item2: Record Item;
        Item3: Record Item;
        NoOfRecords: Integer;
        LineCount: Integer;
    begin
        NewTempItem.DeleteAll();

        Item2.Copy(Item);
        OnBeforeCalcItems(Item2);

        NoOfRecords := Item.Count();
        if ShowDialog then
            Window.Open(Text002);

        if Item2.Find('-') then
            repeat
                LineCount := LineCount + 1;
                if ShowDialog then
                    Window.Update(1, Round(LineCount / NoOfRecords * 10000, 1));
                if UseAssemblyList then
                    CalcAssemblyItem(Item2."No.", Item3, 0, true)
                else
                    CalcMfgItem(Item2."No.", Item3, 0);
            until Item2.Next() = 0;

        TempItem.Reset();
        if TempItem.Find('-') then
            repeat
                NewTempItem := TempItem;
                NewTempItem.Insert();
            until TempItem.Next() = 0;

        if ShowDialog then
            Window.Close();
    end;

    local procedure CalcAssemblyItem(ItemNo: Code[20]; var Item: Record Item; Level: Integer; CalcMfgItems: Boolean)
    var
        BOMComp: Record "BOM Component";
        CompItem: Record Item;
        Res: Record Resource;
        LotSize: Decimal;
        ComponentQuantity: Decimal;
    begin
        if Level > MaxLevel then
            Error(Text000, MaxLevel);

        if GetItem(ItemNo, Item) then
            exit;

        if not Item.IsAssemblyItem() then
            exit;

        if not CalcMultiLevel and (Level <> 0) then
            exit;

        BOMComp.SetRange("Parent Item No.", ItemNo);
        BOMComp.SetFilter(Type, '<>%1', BOMComp.Type::" ");
        if BOMComp.FindSet() then begin
            Item."Rolled-up Material Cost" := 0;
            Item."Rolled-up Capacity Cost" := 0;
            Item."Rolled-up Cap. Overhead Cost" := 0;
            Item."Rolled-up Mfg. Ovhd Cost" := 0;
            Item."Rolled-up Subcontracted Cost" := 0;
            Item."Single-Level Material Cost" := 0;
            Item."Single-Level Capacity Cost" := 0;
            Item."Single-Level Cap. Ovhd Cost" := 0;
            Item."Single-Level Subcontrd. Cost" := 0;
            OnCalcAssemblyItemOnAfterInitItemCost(Item);

            repeat
                case BOMComp.Type of
                    BOMComp.Type::Item:
                        begin
                            GetItem(BOMComp."No.", CompItem);
                            ComponentQuantity :=
                              BOMComp."Quantity per" *
                              UOMMgt.GetQtyPerUnitOfMeasure(CompItem, BOMComp."Unit of Measure Code");
                            if CompItem.IsInventoriableType() then
                                if CompItem.IsAssemblyItem() or CompItem.IsMfgItem() then begin
                                    if CompItem.IsAssemblyItem() then
                                        CalcAssemblyItem(BOMComp."No.", CompItem, Level + 1, CalcMfgItems)
                                    else
                                        if CalcMfgItems then
                                            CalcMfgItem(BOMComp."No.", CompItem, Level + 1);
                                    Item."Rolled-up Material Cost" += ComponentQuantity * CompItem."Rolled-up Material Cost";
                                    Item."Rolled-up Capacity Cost" += ComponentQuantity * CompItem."Rolled-up Capacity Cost";
                                    Item."Rolled-up Cap. Overhead Cost" += ComponentQuantity * CompItem."Rolled-up Cap. Overhead Cost";
                                    Item."Rolled-up Mfg. Ovhd Cost" += ComponentQuantity * CompItem."Rolled-up Mfg. Ovhd Cost";
                                    Item."Rolled-up Subcontracted Cost" += ComponentQuantity * CompItem."Rolled-up Subcontracted Cost";
                                    Item."Single-Level Material Cost" += ComponentQuantity * CompItem."Standard Cost"
                                end else begin
                                    Item."Rolled-up Material Cost" += ComponentQuantity * CompItem."Unit Cost";
                                    Item."Single-Level Material Cost" += ComponentQuantity * CompItem."Unit Cost"
                                end;
                            OnCalcAssemblyItemOnAfterCalcItemCost(Item, CompItem, BOMComp, ComponentQuantity);
                        end;
                    BOMComp.Type::Resource:
                        begin
                            LotSize := 1;
                            if BOMComp."Resource Usage Type" = BOMComp."Resource Usage Type"::Fixed then
                                if Item."Lot Size" <> 0 then
                                    LotSize := Item."Lot Size";

                            GetResCost(BOMComp."No.", TempPriceListLine);
                            Res.Get(BOMComp."No.");
                            ComponentQuantity :=
                              BOMComp."Quantity per" *
                              UOMMgt.GetResQtyPerUnitOfMeasure(Res, BOMComp."Unit of Measure Code") /
                              LotSize;
                            Item."Single-Level Capacity Cost" += ComponentQuantity * TempPriceListLine."Direct Unit Cost";
                            Item."Single-Level Cap. Ovhd Cost" += ComponentQuantity * (TempPriceListLine."Unit Cost" - TempPriceListLine."Direct Unit Cost");
                        end;
                end;
            until BOMComp.Next() = 0;

            Item."Single-Level Mfg. Ovhd Cost" :=
              Round(
                (Item."Single-Level Material Cost" +
                 Item."Single-Level Capacity Cost" +
                 Item."Single-Level Cap. Ovhd Cost") * Item."Indirect Cost %" / 100 +
                Item."Overhead Rate",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Rolled-up Material Cost" :=
              Round(
                Item."Rolled-up Material Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Rolled-up Capacity Cost" :=
              Round(
                Item."Rolled-up Capacity Cost" + Item."Single-Level Capacity Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Rolled-up Cap. Overhead Cost" :=
              Round(
                Item."Rolled-up Cap. Overhead Cost" + Item."Single-Level Cap. Ovhd Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Rolled-up Mfg. Ovhd Cost" :=
              Round(
                Item."Rolled-up Mfg. Ovhd Cost" + Item."Single-Level Mfg. Ovhd Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Rolled-up Subcontracted Cost" :=
              Round(
                Item."Rolled-up Subcontracted Cost",
                GLSetup."Unit-Amount Rounding Precision");

            OnCalcAssemblyItemOnAfterCalcItemRolledupCost(Item);

            Item."Standard Cost" :=
              Round(
                Item."Single-Level Material Cost" +
                Item."Single-Level Capacity Cost" +
                Item."Single-Level Cap. Ovhd Cost" +
                Item."Single-Level Mfg. Ovhd Cost" +
                Item."Single-Level Subcontrd. Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Single-Level Capacity Cost" :=
              Round(
                Item."Single-Level Capacity Cost",
                GLSetup."Unit-Amount Rounding Precision");
            Item."Single-Level Cap. Ovhd Cost" :=
              Round(
                Item."Single-Level Cap. Ovhd Cost",
                GLSetup."Unit-Amount Rounding Precision");

            OnCalcAssemblyItemOnAfterCalcSingleLevelCost(Item);

            Item."Last Unit Cost Calc. Date" := CalculationDate;

            TempItem := Item;
            TempItem.Insert();
        end
    end;

    procedure CalcAssemblyItemPrice(ItemNo: Code[20])
    var
        Item: Record Item;
        Instruction: Text[1024];
        Depth: Integer;
        NewCalcMultiLevel: Boolean;
        AssemblyContainsProdBOM: Boolean;
    begin
        Item.Get(ItemNo);
        Instruction := PrepareAssemblyCalculation(Item, Depth, 2, AssemblyContainsProdBOM); // 2=UnitPrice
        if Depth > 1 then
            case StrMenu(Text001, 1, Instruction) of
                0:
                    exit;
                1:
                    NewCalcMultiLevel := false;
                2:
                    NewCalcMultiLevel := true;
            end;

        SetProperties(WorkDate(), NewCalcMultiLevel, true, false, '', false);

        Item.Get(ItemNo);
        DoCalcAssemblyItemPrice(Item, 0);
    end;

    local procedure DoCalcAssemblyItemPrice(var Item: Record Item; Level: Integer)
    var
        BOMComp: Record "BOM Component";
        CompItem: Record Item;
        CompResource: Record Resource;
        UnitPrice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoCalcAssemblyItemPrice(Item, Level, MaxLevel, CalcMultiLevel, IsHandled);
        if IsHandled then
            exit;

        if Level > MaxLevel then
            Error(Text000, MaxLevel);

        if not CalcMultiLevel and (Level <> 0) then
            exit;

        if not Item.IsAssemblyItem() then
            exit;

        BOMComp.SetRange("Parent Item No.", Item."No.");
        OnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(Item, BOMComp);
        if BOMComp.Find('-') then begin
            repeat
                case BOMComp.Type of
                    BOMComp.Type::Item:
                        if CompItem.Get(BOMComp."No.") then begin
                            DoCalcAssemblyItemPrice(CompItem, Level + 1);
                            UnitPrice +=
                              BOMComp."Quantity per" *
                              UOMMgt.GetQtyPerUnitOfMeasure(CompItem, BOMComp."Unit of Measure Code") *
                              CompItem."Unit Price";
                        end;
                    BOMComp.Type::Resource:
                        if CompResource.Get(BOMComp."No.") then
                            UnitPrice +=
                              BOMComp."Quantity per" *
                              UOMMgt.GetResQtyPerUnitOfMeasure(CompResource, BOMComp."Unit of Measure Code") *
                              CompResource."Unit Price";
                end
            until BOMComp.Next() = 0;
            UnitPrice := Round(UnitPrice, GLSetup."Unit-Amount Rounding Precision");
            Item.Validate("Unit Price", UnitPrice);
            Item.Modify(true)
        end;
    end;

    local procedure CalcMfgItem(ItemNo: Code[20]; var Item: Record Item; Level: Integer)
    var
        LotSize: Decimal;
        MfgItemQtyBase: Decimal;
        SLMat: Decimal;
        SLNonInvMat: Decimal;
        SLCap: Decimal;
        SLSub: Decimal;
        SLCapOvhd: Decimal;
        SLMfgOvhd: Decimal;
        RUMat: Decimal;
        RUNonInvMat: Decimal;
        RUCap: Decimal;
        RUSub: Decimal;
        RUCapOvhd: Decimal;
        RUMfgOvhd: Decimal;
    begin
        OnBeforeCalcMfgItem(Item, LogErrors, StdCostWkshName);

        if Level > MaxLevel then
            Error(Text000, MaxLevel);

        if GetItem(ItemNo, Item) then
            exit;

        if not CalcMultiLevel and (Level <> 0) then
            exit;

        LotSize := 1;

        if Item.IsMfgItem() then begin
            if Item."Lot Size" <> 0 then
                LotSize := Item."Lot Size";
            MfgItemQtyBase := MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(LotSize, Item."Scrap %");
            OnCalcMfgItemOnBeforeCalcRtngCost(Item, Level, LotSize, MfgItemQtyBase, SLCap);
            CalcRtngCost(Item."Routing No.", MfgItemQtyBase, SLCap, SLSub, SLCapOvhd, Item);
            CalcProdBOMCost(
              Item, Item."Production BOM No.", Item."Routing No.",
              MfgItemQtyBase, true, Level, SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd, SLNonInvMat, RUNonInvMat, Item);

            if not MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                SLMfgOvhd :=
                  CostCalcMgt.CalcOvhdCost(
                    SLMat + SLCap + SLSub + SLCapOvhd,
                    Item."Indirect Cost %", Item."Overhead Rate", LotSize)
            else
                SLMfgOvhd :=
                  CostCalcMgt.CalcOvhdCost(
                    SLMat + SLCap + SLSub + SLCapOvhd + SLNonInvMat,
                    Item."Indirect Cost %", Item."Overhead Rate", LotSize);

            Item."Last Unit Cost Calc. Date" := CalculationDate;
        end else
            if Item.IsAssemblyItem() then begin
                CalcAssemblyItem(ItemNo, Item, Level, true);
                exit
            end else begin
                SLMat := Item."Unit Cost";
                RUMat := Item."Unit Cost";
            end;

        OnCalcMfgItemOnBeforeCalculateCosts(
            SLMat, SLCap, SLSub, SLCapOvhd, SLMfgOvhd, Item, LotSize, MfgItemQtyBase, Level, CalculationDate, RUMat);

        Item."Single-Level Material Cost" := CalcCostPerUnit(SLMat, LotSize);
        Item."Single-Level Capacity Cost" := CalcCostPerUnit(SLCap, LotSize);
        Item."Single-Level Subcontrd. Cost" := CalcCostPerUnit(SLSub, LotSize);
        Item."Single-Level Cap. Ovhd Cost" := CalcCostPerUnit(SLCapOvhd, LotSize);
        Item."Single-Level Mfg. Ovhd Cost" := CalcCostPerUnit(SLMfgOvhd, LotSize);
        Item."Rolled-up Material Cost" := CalcCostPerUnit(RUMat, LotSize);
        Item."Rolled-up Capacity Cost" := CalcCostPerUnit(RUCap + SLCap, LotSize);
        Item."Rolled-up Subcontracted Cost" := CalcCostPerUnit(RUSub + SLSub, LotSize);
        Item."Rolled-up Cap. Overhead Cost" := CalcCostPerUnit(RUCapOvhd + SLCapOvhd, LotSize);
        Item."Rolled-up Mfg. Ovhd Cost" := CalcCostPerUnit(RUMfgOvhd + SLMfgOvhd, LotSize);
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            Item."Rolled-up Mat. Non-Invt. Cost" := CalcCostPerUnit(RUNonInvMat, LotSize);
            Item."Single-Lvl Mat. Non-Invt. Cost" := CalcCostPerUnit(SLNonInvMat, LotSize);
        end else begin
            Item."Rolled-up Mat. Non-Invt. Cost" := 0;
            Item."Single-Lvl Mat. Non-Invt. Cost" := 0;
        end;
        Item."Standard Cost" :=
          Item."Single-Level Material Cost" +
          Item."Single-Level Capacity Cost" +
          Item."Single-Level Subcontrd. Cost" +
          Item."Single-Level Cap. Ovhd Cost" +
          Item."Single-Level Mfg. Ovhd Cost" +
          Item."Single-Lvl Mat. Non-Invt. Cost";

        TempItem := Item;
        TempItem.Insert();
    end;

    local procedure CalcMfgSKU(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]; var SKU: Record "Stockkeeping Unit"; Level: Integer)
    var
        MainItem: Record Item;
        BOMNo: Code[20];
        RoutingNo: Code[20];
        LotSize: Decimal;
        MfgItemQtyBase: Decimal;
        SLMat: Decimal;
        SLNonInvMat: Decimal;
        SLCap: Decimal;
        SLSub: Decimal;
        SLCapOvhd: Decimal;
        SLMfgOvhd: Decimal;
        RUMat: Decimal;
        RUNonInvMat: Decimal;
        RUCap: Decimal;
        RUSub: Decimal;
        RUCapOvhd: Decimal;
        RUMfgOvhd: Decimal;
    begin
        if not MainItem.Get(SKU."Item No.") then
            exit;

        if Level > MaxLevel then
            Error(Text000, MaxLevel);

        if GetSKU(ItemNo, LocationCode, VariantCode, SKU) then
            exit;

        if not CalcMultiLevel and (Level <> 0) then
            exit;

        LotSize := 1;

        if not SKU.IsMfgSKU() then
            exit;

        if SKU."Production BOM No." = '' then
            BOMNo := MainItem."Production BOM No."
        else
            BOMNo := SKU."Production BOM No.";

        if SKU."Routing No." = '' then
            RoutingNo := MainItem."Routing No."
        else
            RoutingNo := SKU."Routing No.";

        if SKU."Lot Size" <> 0 then
            LotSize := SKU."Lot Size";
        MfgItemQtyBase := MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(LotSize, MainItem."Scrap %");
        CalcRtngCostSKU(RoutingNo, MfgItemQtyBase, SLCap, SLSub, SLCapOvhd);
        CalcProdBOMCost(
          MainItem, BOMNo, RoutingNo,
          MfgItemQtyBase, true, Level, SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd, SLNonInvMat, RUNonInvMat, SKU);

        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            SLMfgOvhd :=
              CostCalcMgt.CalcOvhdCost(
                SLMat + SLCap + SLSub + SLCapOvhd + SLNonInvMat,
                MainItem."Indirect Cost %", MainItem."Overhead Rate", LotSize)
        else
            SLMfgOvhd :=
              CostCalcMgt.CalcOvhdCost(
                SLMat + SLCap + SLSub + SLCapOvhd,
                MainItem."Indirect Cost %", MainItem."Overhead Rate", LotSize);

        SKU."Single-Level Material Cost" := CalcCostPerUnit(SLMat, LotSize);
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            SKU."Single-Lvl Mat. Non-Invt. Cost" := CalcCostPerUnit(SLNonInvMat, LotSize)
        else
            SKU."Single-Lvl Mat. Non-Invt. Cost" := 0;

        SKU."Single-Level Capacity Cost" := CalcCostPerUnit(SLCap, LotSize);
        SKU."Single-Level Subcontrd. Cost" := CalcCostPerUnit(SLSub, LotSize);
        SKU."Single-Level Cap. Ovhd Cost" := CalcCostPerUnit(SLCapOvhd, LotSize);
        SKU."Single-Level Mfg. Ovhd Cost" := CalcCostPerUnit(SLMfgOvhd, LotSize);
        SKU."Rolled-up Material Cost" := CalcCostPerUnit(RUMat, LotSize);
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            SKU."Rolled-up Mat. Non-Invt. Cost" := CalcCostPerUnit(RUNonInvMat, LotSize)
        else
            SKU."Rolled-up Mat. Non-Invt. Cost" := 0;
        SKU."Rolled-up Capacity Cost" := CalcCostPerUnit(RUCap + SLCap, LotSize);
        SKU."Rolled-up Subcontracted Cost" := CalcCostPerUnit(RUSub + SLSub, LotSize);
        SKU."Rolled-up Cap. Overhead Cost" := CalcCostPerUnit(RUCapOvhd + SLCapOvhd, LotSize);
        SKU."Rolled-up Mfg. Ovhd Cost" := CalcCostPerUnit(RUMfgOvhd + SLMfgOvhd, LotSize);

        SKU."Standard Cost" :=
          SKU."Single-Level Material Cost" +
          SKU."Single-Level Capacity Cost" +
          SKU."Single-Level Subcontrd. Cost" +
          SKU."Single-Level Cap. Ovhd Cost" +
          SKU."Single-Level Mfg. Ovhd Cost" +
          SKU."Single-Lvl Mat. Non-Invt. Cost";

        TempSKU := SKU;
        TempSKU.Insert();
    end;

    local procedure SetProdBOMFilters(var ProdBOMLine: Record "Production BOM Line"; var PBOMVersionCode: Code[20]; ProdBOMNo: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        PBOMVersionCode :=
          VersionMgt.GetBOMVersion(ProdBOMNo, CalculationDate, true);
        if PBOMVersionCode = '' then begin
            ProdBOMHeader.Get(ProdBOMNo);
            TestBOMVersionIsCertified(PBOMVersionCode, ProdBOMHeader);
        end;

        ProdBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine.SetRange("Version Code", PBOMVersionCode);
        ProdBOMLine.SetFilter("Starting Date", '%1|..%2', 0D, CalculationDate);
        ProdBOMLine.SetFilter("Ending Date", '%1|%2..', 0D, CalculationDate);
        ProdBOMLine.SetFilter("No.", '<>%1', '');

        OnAfterSetProdBOMFilters(ProdBOMLine, PBOMVersionCode, ProdBOMNo);
    end;

    local procedure CalcProdBOMCost(MfgItem: Record Item; ProdBOMNo: Code[20]; RtngNo: Code[20]; MfgItemQtyBase: Decimal; IsTypeItem: Boolean; Level: Integer; var SLMat: Decimal; var RUMat: Decimal; var RUCap: Decimal; var RUSub: Decimal; var RUCapOvhd: Decimal; var RUMfgOvhd: Decimal; var SLNonInvMat: Decimal; var RUNonInvMat: Decimal; var ParentItem: Record Item)
    var
        CompItem: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        CompItemQtyBase: Decimal;
        UOMFactor: Decimal;
        PBOMVersionCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcProdBOMCost(
            MfgItem, ProdBOMNo, RtngNo, MfgItemQtyBase, IsTypeItem, Level, SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd, IsHandled,
            CalculationDate, LogErrors, TempRoutingVersion, TempProductionBOMVersion);
        if IsHandled then
            exit;

        if ProdBOMNo = '' then
            exit;

        SetProdBOMFilters(ProdBOMLine, PBOMVersionCode, ProdBOMNo);

        if IsTypeItem then
            UOMFactor := UOMMgt.GetQtyPerUnitOfMeasure(MfgItem, VersionMgt.GetBOMUnitOfMeasure(ProdBOMNo, PBOMVersionCode))
        else
            UOMFactor := 1;

        if ProdBOMLine.Find('-') then
            repeat
                OnCalcProdBOMCostOnBeforeCalcCompItemQtyBase(ProdBOMLine, ParentItem, CalculationDate, MfgItem, MfgItemQtyBase, IsTypeItem, CompItemQtyBase, RtngNo, UOMFactor);

                CompItemQtyBase :=
                  UOMMgt.RoundQty(
                    MfgCostCalcMgt.CalcCompItemQtyBase(ProdBOMLine, CalculationDate, MfgItemQtyBase, RtngNo, IsTypeItem) / UOMFactor);

                OnCalcProdBOMCostOnAfterCalcCompItemQtyBase(
                  CalculationDate, MfgItem, MfgItemQtyBase, IsTypeItem, ProdBOMLine, CompItemQtyBase, RtngNo, UOMFactor);
                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            GetItem(ProdBOMLine."No.", CompItem);
                            if CompItem.IsInventoriableType() then begin
                                if CompItem.IsMfgItem() or CompItem.IsAssemblyItem() then begin
                                    CalcMfgItem(ProdBOMLine."No.", CompItem, Level + 1);
                                    IncrCost(SLMat, CompItem."Standard Cost", CompItemQtyBase);
                                    IncrCost(RUMat, CompItem."Rolled-up Material Cost", CompItemQtyBase);
                                    IncrCost(RUCap, CompItem."Rolled-up Capacity Cost", CompItemQtyBase);
                                    IncrCost(RUSub, CompItem."Rolled-up Subcontracted Cost", CompItemQtyBase);
                                    IncrCost(RUCapOvhd, CompItem."Rolled-up Cap. Overhead Cost", CompItemQtyBase);
                                    IncrCost(RUMfgOvhd, CompItem."Rolled-up Mfg. Ovhd Cost", CompItemQtyBase);

                                    if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                                        IncrCost(RUNonInvMat, CompItem."Rolled-up Mat. Non-Invt. Cost", CompItemQtyBase);

                                    OnCalcProdBOMCostOnAfterCalcMfgItem(ProdBOMLine, MfgItem, MfgItemQtyBase, CompItem, CompItemQtyBase, Level, IsTypeItem, UOMFactor, ParentItem);
                                end else begin
                                    IncrCost(SLMat, CompItem."Unit Cost", CompItemQtyBase);
                                    IncrCost(RUMat, CompItem."Unit Cost", CompItemQtyBase);
                                end;
                            end else
                                if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
                                    IncrCost(SLNonInvMat, CompItem."Unit Cost", CompItemQtyBase);
                                    IncrCost(RUNonInvMat, CompItem."Unit Cost", CompItemQtyBase);
                                end;

                            OnCalcProdBOMCostOnAfterCalcAnyItem(ProdBOMLine, MfgItem, MfgItemQtyBase, CompItem, CompItemQtyBase, Level, IsTypeItem, UOMFactor,
                                                                SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd);
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        CalcProdBOMCost(
                          MfgItem, ProdBOMLine."No.", RtngNo, CompItemQtyBase, false, Level, SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd, SLNonInvMat, RUNonInvMat, ParentItem);
                end;
            until ProdBOMLine.Next() = 0;
    end;

    local procedure CalcProdBOMCost(MfgItem: Record Item; ProdBOMNo: Code[20]; RtngNo: Code[20]; MfgItemQtyBase: Decimal; IsTypeItem: Boolean; Level: Integer; var SLMat: Decimal; var RUMat: Decimal; var RUCap: Decimal; var RUSub: Decimal; var RUCapOvhd: Decimal; var RUMfgOvhd: Decimal; var SLNonInvMat: Decimal; var RUNonInvMat: Decimal; var SKU: Record "Stockkeeping Unit")
    var
        CompItem: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        CompItemQtyBase: Decimal;
        UOMFactor: Decimal;
        PBOMVersionCode: Code[20];
    begin
        if ProdBOMNo = '' then
            exit;

        SetProdBOMFilters(ProdBOMLine, PBOMVersionCode, ProdBOMNo);

        if IsTypeItem then
            UOMFactor := UOMMgt.GetQtyPerUnitOfMeasure(MfgItem, VersionMgt.GetBOMUnitOfMeasure(ProdBOMNo, PBOMVersionCode))
        else
            UOMFactor := 1;

        if ProdBOMLine.Find('-') then
            repeat
                CompItemQtyBase :=
                  UOMMgt.RoundQty(
                    MfgCostCalcMgt.CalcCompItemQtyBase(ProdBOMLine, CalculationDate, MfgItemQtyBase, RtngNo, IsTypeItem) / UOMFactor);

                OnCalcProdBOMCostOnAfterCalcCompItemQtyBase(
                  CalculationDate, MfgItem, MfgItemQtyBase, IsTypeItem, ProdBOMLine, CompItemQtyBase, RtngNo, UOMFactor);
                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            GetItem(ProdBOMLine."No.", CompItem);
                            if CompItem.IsInventoriableType() then begin
                                if CompItem.IsMfgItem() or CompItem.IsAssemblyItem() then begin
                                    CalcMfgItem(ProdBOMLine."No.", CompItem, Level + 1);
                                    IncrCost(SLMat, CompItem."Standard Cost", CompItemQtyBase);
                                    IncrCost(RUMat, CompItem."Rolled-up Material Cost", CompItemQtyBase);
                                    IncrCost(RUCap, CompItem."Rolled-up Capacity Cost", CompItemQtyBase);
                                    IncrCost(RUSub, CompItem."Rolled-up Subcontracted Cost", CompItemQtyBase);
                                    IncrCost(RUCapOvhd, CompItem."Rolled-up Cap. Overhead Cost", CompItemQtyBase);
                                    IncrCost(RUMfgOvhd, CompItem."Rolled-up Mfg. Ovhd Cost", CompItemQtyBase);

                                    if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                                        IncrCost(RUNonInvMat, CompItem."Rolled-up Mat. Non-Invt. Cost", CompItemQtyBase);

                                end else begin
                                    IncrCost(SLMat, CompItem."Unit Cost", CompItemQtyBase);
                                    IncrCost(RUMat, CompItem."Unit Cost", CompItemQtyBase);
                                end;
                            end else
                                if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
                                    IncrCost(SLNonInvMat, CompItem."Unit Cost", CompItemQtyBase);
                                    IncrCost(RUNonInvMat, CompItem."Unit Cost", CompItemQtyBase);
                                end;
                            OnCalcProdBOMCostOnAfterCalcAnyItem(ProdBOMLine, MfgItem, MfgItemQtyBase, CompItem, CompItemQtyBase, Level, IsTypeItem, UOMFactor,
                                                                SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd);
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        CalcProdBOMCost(
                          MfgItem, ProdBOMLine."No.", RtngNo, CompItemQtyBase, false, Level, SLMat, RUMat, RUCap, RUSub, RUCapOvhd, RUMfgOvhd, SLNonInvMat, RUNonInvMat, SKU);
                end;
            until ProdBOMLine.Next() = 0;
    end;

    local procedure CalcRtngCost(RtngHeaderNo: Code[20]; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal; var ParentItem: Record Item)
    var
        RtngLine: Record "Routing Line";
        RtngHeader: Record "Routing Header";
        IsHandled: Boolean;
    begin
        if RtngLine.CertifiedRoutingVersionExists(RtngHeaderNo, CalculationDate) then begin
            if RtngLine."Version Code" = '' then begin
                RtngHeader.Get(RtngHeaderNo);
                TestRtngVersionIsCertified(RtngLine."Version Code", RtngHeader);
            end;

            repeat
                IsHandled := false;
                OnCalcRtngCostOnBeforeCalcRtngLineCost(RtngLine, ParentItem, LogErrors, IsHandled);
                if not IsHandled then
                    CalcRtngLineCost(RtngLine, MfgItemQtyBase, SLCap, SLSub, SLCapOvhd, ParentItem);
            until RtngLine.Next() = 0;
        end;
    end;

    local procedure CalcRtngCostSKU(RtngHeaderNo: Code[20]; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal)
    var
        RtngLine: Record "Routing Line";
        RtngHeader: Record "Routing Header";
    begin
        if RtngLine.CertifiedRoutingVersionExists(RtngHeaderNo, CalculationDate) then begin
            if RtngLine."Version Code" = '' then begin
                RtngHeader.Get(RtngHeaderNo);
                TestRtngVersionIsCertified(RtngLine."Version Code", RtngHeader);
            end;

            repeat
                CalcRtngLineCostSKU(RtngLine, MfgItemQtyBase, SLCap, SLSub, SLCapOvhd);
            until RtngLine.Next() = 0;
        end;
    end;

    local procedure CalcRoutingCostPerUnit(Type: Enum "Capacity Type Routing"; No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        IsHandled: Boolean;
    begin
        case Type of
            Type::"Work Center":
                GetWorkCenter(No, WorkCenter);
            Type::"Machine Center":
                GetMachineCenter(No, MachineCenter);
        end;

        IsHandled := false;
        OnCalcRoutingCostPerUnitOnBeforeCalc(Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        MfgCostCalcMgt.CalcRoutingCostPerUnit(
            Type, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation, WorkCenter, MachineCenter);
    end;

    local procedure CalcCostPerUnit(CostPerLot: Decimal; LotSize: Decimal): Decimal
    begin
        exit(Round(CostPerLot / LotSize, GLSetup."Unit-Amount Rounding Precision"));
    end;

    local procedure TestBOMVersionIsCertified(BOMVersionCode: Code[20]; ProdBOMHeader: Record "Production BOM Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestBOMVersionIsCertified(BOMVersionCode, ProdBOMHeader, LogErrors, IsHandled);
        if IsHandled then
            exit;

        if BOMVersionCode = '' then
            if ProdBOMHeader.Status <> ProdBOMHeader.Status::Certified then
                if LogErrors then
                    InsertInErrBuf(ProdBOMHeader."No.", '', false)
                else
                    ProdBOMHeader.TestField(Status, ProdBOMHeader.Status::Certified);
    end;

    local procedure InsertInErrBuf(No: Code[20]; Version: Code[10]; IsRtng: Boolean)
    begin
        if not LogErrors then
            exit;

        if IsRtng then begin
            TempRoutingVersion."Routing No." := No;
            TempRoutingVersion."Version Code" := Version;
            if TempRoutingVersion.Insert() then;
        end else begin
            TempProductionBOMVersion."Production BOM No." := No;
            TempProductionBOMVersion."Version Code" := Version;
            if TempProductionBOMVersion.Insert() then;
        end;
    end;

    local procedure GetItem(ItemNo: Code[20]; var Item: Record Item) IsInBuffer: Boolean
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        if TempItem.Get(ItemNo) then begin
            Item := TempItem;
            IsInBuffer := true;
        end else begin
            Item.Get(ItemNo);
            if (StdCostWkshName <> '') and
               not (Item.IsMfgItem() or Item.IsAssemblyItem())
            then
                if StdCostWksh.Get(StdCostWkshName, StdCostWksh.Type::Item, ItemNo) then begin
                    Item."Unit Cost" := StdCostWksh."New Standard Cost";
                    Item."Standard Cost" := StdCostWksh."New Standard Cost";
                    Item."Indirect Cost %" := StdCostWksh."New Indirect Cost %";
                    Item."Overhead Rate" := StdCostWksh."New Overhead Rate";
                end;
            IsInBuffer := false;
        end;

        OnAfterGetItem(Item, StdCostWkshName, IsInBuffer);
    end;

    local procedure GetSKU(ItemNo: Code[20]; LocationCode: Code[20]; VariantCode: Code[20]; var SKU: Record "Stockkeeping Unit") IsInSKUBuffer: Boolean
    begin
        if TempSKU.Get(LocationCode, ItemNo, VariantCode) then begin
            SKU := TempSKU;
            IsInSKUBuffer := true;
        end else
            IsInSKUBuffer := false;
    end;

    local procedure GetWorkCenter(No: Code[20]; var WorkCenter: Record "Work Center")
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        if TempWorkCenter.Get(No) then
            WorkCenter := TempWorkCenter
        else begin
            WorkCenter.Get(No);
            if StdCostWkshName <> '' then
                if StdCostWksh.Get(StdCostWkshName, StdCostWksh.Type::"Work Center", No) then begin
                    WorkCenter."Unit Cost" := StdCostWksh."New Standard Cost";
                    WorkCenter."Indirect Cost %" := StdCostWksh."New Indirect Cost %";
                    WorkCenter."Overhead Rate" := StdCostWksh."New Overhead Rate";
                    WorkCenter."Direct Unit Cost" :=
                      CostCalcMgt.CalcDirUnitCost(
                        StdCostWksh."New Standard Cost", StdCostWksh."New Overhead Rate", StdCostWksh."New Indirect Cost %");
                end;

            OnGetWorkCenterOnBeforeAssignWorkCenterToTemp(WorkCenter, TempItem, StdCostWkshName);
            TempWorkCenter := WorkCenter;
            TempWorkCenter.Insert();
        end;
    end;

    local procedure GetMachineCenter(No: Code[20]; var MachineCenter: Record "Machine Center")
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        if TempMachineCenter.Get(No) then
            MachineCenter := TempMachineCenter
        else begin
            MachineCenter.Get(No);
            if StdCostWkshName <> '' then
                if StdCostWksh.Get(StdCostWkshName, StdCostWksh.Type::"Machine Center", No) then begin
                    MachineCenter."Unit Cost" := StdCostWksh."New Standard Cost";
                    MachineCenter."Indirect Cost %" := StdCostWksh."New Indirect Cost %";
                    MachineCenter."Overhead Rate" := StdCostWksh."New Overhead Rate";
                    MachineCenter."Direct Unit Cost" :=
                      CostCalcMgt.CalcDirUnitCost(
                        StdCostWksh."New Standard Cost", StdCostWksh."New Overhead Rate", StdCostWksh."New Indirect Cost %");
                end;
            OnGetMachineCenterOnBeforeAssignMachineCenterToTemp(MachineCenter, TempItem, StdCostWkshName);
            TempMachineCenter := MachineCenter;
            TempMachineCenter.Insert();
        end;
    end;

    local procedure GetResCost(ResourceNo: Code[20]; var PriceListLine: Record "Price List Line")
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        TempPriceListLine.SetRange("Asset Type", TempPriceListLine."Asset Type"::Resource);
        TempPriceListLine.SetRange("Asset No.", ResourceNo);
        if TempPriceListLine.FindFirst() then
            PriceListLine := TempPriceListLine
        else begin
            PriceListLine.Init();
            PriceListLine."Price Type" := PriceListLine."Price Type"::Purchase;
            PriceListLine."Asset Type" := PriceListLine."Asset Type"::Resource;
            PriceListLine."Asset No." := ResourceNo;
            PriceListLine."Work Type Code" := '';

            FindResourceCost(PriceListLine);

            if StdCostWkshName <> '' then
                if StdCostWksh.Get(StdCostWkshName, StdCostWksh.Type::Resource, ResourceNo) then begin
                    PriceListLine."Unit Cost" := StdCostWksh."New Standard Cost";
                    PriceListLine."Direct Unit Cost" :=
                        CostCalcMgt.CalcDirUnitCost(
                            StdCostWksh."New Standard Cost",
                            StdCostWksh."New Overhead Rate",
                            StdCostWksh."New Indirect Cost %");
                end;

            OnGetResCostOnBeforeAssignPriceListLineToTemp(PriceListLine, TempItem, StdCostWkshName);
            TempPriceListLine := PriceListLine;
            NextPriceListLineNo += 1;
            TempPriceListLine."Line No." := NextPriceListLineNo;
            TempPriceListLine.Insert();
        end;
    end;

    local procedure FindResourceCost(var PriceListLine: Record "Price List Line")
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceListLinePrice: Codeunit "Price List Line - Price";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
        PriceType: Enum "Price Type";
    begin
        LineWithPrice := PriceListLinePrice;
        LineWithPrice.SetLine(PriceType::Purchase, PriceListLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(0);
        PriceCalculation.GetLine(Line);
        PriceListLine := Line;
    end;

    local procedure IncrCost(var Cost: Decimal; UnitCost: Decimal; Qty: Decimal)
    begin
        Cost := Cost + Round(Qty * UnitCost, GLSetup."Unit-Amount Rounding Precision");
    end;

    procedure CalculateAssemblyCostExp(AssemblyHeader: Record "Assembly Header"; var ExpCost: array[5] of Decimal)
    begin
        GLSetup.Get();

        ExpCost[RowIdx::AsmOvhd] :=
          Round(
            CalcOverHeadAmt(
              AssemblyHeader.CalcTotalCost(ExpCost),
              AssemblyHeader."Indirect Cost %",
              AssemblyHeader."Overhead Rate" * AssemblyHeader.Quantity),
            GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure CalculateAssemblyCostStd(ItemNo: Code[20]; QtyBase: Decimal; var StdCost: array[5] of Decimal)
    var
        Item: Record Item;
        StdTotalCost: Decimal;
    begin
        GLSetup.Get();

        Item.Get(ItemNo);
        StdCost[RowIdx::MatCost] :=
          Round(
            Item."Single-Level Material Cost" * QtyBase,
            GLSetup."Unit-Amount Rounding Precision");
        StdCost[RowIdx::ResCost] :=
          Round(
            Item."Single-Level Capacity Cost" * QtyBase,
            GLSetup."Unit-Amount Rounding Precision");
        StdCost[RowIdx::ResOvhd] :=
          Round(
            Item."Single-Level Cap. Ovhd Cost" * QtyBase,
            GLSetup."Unit-Amount Rounding Precision");
        StdTotalCost := StdCost[RowIdx::MatCost] + StdCost[RowIdx::ResCost] + StdCost[RowIdx::ResOvhd];
        StdCost[RowIdx::AsmOvhd] :=
          Round(
            CalcOverHeadAmt(
              StdTotalCost,
              Item."Indirect Cost %",
              Item."Overhead Rate" * QtyBase),
            GLSetup."Unit-Amount Rounding Precision");
    end;

    procedure CalcOverHeadAmt(CostAmt: Decimal; IndirectCostPct: Decimal; OverheadRateAmt: Decimal): Decimal
    begin
        exit(CostAmt * IndirectCostPct / 100 + OverheadRateAmt);
    end;

    local procedure CalculatePostedAssemblyCostExp(PostedAssemblyHeader: Record "Posted Assembly Header"; var ExpCost: array[5] of Decimal)
    begin
        GLSetup.Get();

        ExpCost[RowIdx::AsmOvhd] :=
          Round(
            CalcOverHeadAmt(
              PostedAssemblyHeader.CalcTotalCost(ExpCost),
              PostedAssemblyHeader."Indirect Cost %",
              PostedAssemblyHeader."Overhead Rate" * PostedAssemblyHeader.Quantity),
            GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure CalcTotalAndVar(var Value: array[5, 5] of Decimal)
    begin
        CalcTotal(Value);
        CalcVariance(Value);
    end;

    local procedure CalcTotal(var Value: array[5, 5] of Decimal)
    var
        RowId: Integer;
        ColId: Integer;
    begin
        for ColId := 1 to 3 do begin
            Value[ColId, 5] := 0;
            for RowId := 1 to 4 do
                Value[ColId, 5] += Value[ColId, RowId];
        end;
    end;

    local procedure CalcVariance(var Value: array[5, 5] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Value[ColIdx::Dev, i] := CalcIndicatorPct(Value[ColIdx::StdCost, i], Value[ColIdx::ActCost, i]);
            Value[ColIdx::"Var", i] := Value[ColIdx::ActCost, i] - Value[ColIdx::StdCost, i];
        end;
    end;

    local procedure CalcIndicatorPct(Value: Decimal; "Sum": Decimal): Decimal
    begin
        if Value = 0 then
            exit(0);

        exit(Round((Sum - Value) / Value * 100, 1));
    end;

    procedure CalcAsmOrderStatistics(AssemblyHeader: Record "Assembly Header"; var Value: array[5, 5] of Decimal)
    begin
        CalculateAssemblyCostStd(
          AssemblyHeader."Item No.",
          AssemblyHeader."Quantity (Base)",
          Value[ColIdx::StdCost]);
        CalculateAssemblyCostExp(AssemblyHeader, Value[ColIdx::ExpCost]);
        AssemblyHeader.CalcActualCosts(Value[ColIdx::ActCost]);
        CalcTotalAndVar(Value);
    end;

    procedure CalcPostedAsmOrderStatistics(PostedAssemblyHeader: Record "Posted Assembly Header"; var Value: array[5, 5] of Decimal)
    begin
        CalculateAssemblyCostStd(
          PostedAssemblyHeader."Item No.",
          PostedAssemblyHeader."Quantity (Base)",
          Value[ColIdx::StdCost]);
        CalculatePostedAssemblyCostExp(PostedAssemblyHeader, Value[ColIdx::ExpCost]);
        PostedAssemblyHeader.CalcActualCosts(Value[ColIdx::ActCost]);
        CalcTotalAndVar(Value);
    end;

    procedure CalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal)
    var
        DummyParentItem: Record Item;
    begin
        CalcRtngLineCost(RoutingLine, MfgItemQtyBase, SLCap, SLSub, SLCapOvhd, DummyParentItem);
    end;

    internal procedure CalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal; var ParentItem: Record Item)
    var
        WorkCenter: Record "Work Center";
        UnitCost: Decimal;
        DirUnitCost: Decimal;
        IndirCostPct: Decimal;
        OvhdRate: Decimal;
        CostTime: Decimal;
        UnitCostCalculation: Enum "Unit Cost Calculation Type";
    begin
        OnBeforeCalcRtngLineCost(RoutingLine, MfgItemQtyBase);
        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (RoutingLine."No." <> '') then
            WorkCenter.Get(RoutingLine."No.");

        UnitCost := RoutingLine."Unit Cost per";
        CalcRoutingCostPerUnit(RoutingLine.Type, RoutingLine."No.", DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation);
        OnCalcRtngLineCostOnAfterCalcRoutingCostPerUnit(RoutingLine, WorkCenter, MfgItemQtyBase, UnitCostCalculation);
        CostTime :=
          MfgCostCalcMgt.CalculateCostTime(
            MfgItemQtyBase,
            RoutingLine."Setup Time", RoutingLine."Setup Time Unit of Meas. Code",
            RoutingLine."Run Time", RoutingLine."Run Time Unit of Meas. Code", RoutingLine."Lot Size",
            RoutingLine."Scrap Factor % (Accumulated)", RoutingLine."Fixed Scrap Qty. (Accum.)",
            RoutingLine."Work Center No.", UnitCostCalculation, MfgSetup."Cost Incl. Setup",
            RoutingLine."Concurrent Capacities");

        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (WorkCenter."Subcontractor No." <> '') then
            IncrCost(SLSub, DirUnitCost, CostTime)
        else
            IncrCost(SLCap, DirUnitCost, CostTime);
        IncrCost(SLCapOvhd, CostCalcMgt.CalcOvhdCost(DirUnitCost, IndirCostPct, OvhdRate, 1), CostTime);

        OnAfterCalcRtngLineCost(RoutingLine, MfgItemQtyBase, SLCap, SLSub, SLCapOvhd, StdCostWkshName, ParentItem, CostTime);
    end;

    internal procedure CalcRtngLineCostSKU(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal)
    var
        WorkCenter: Record "Work Center";
        UnitCost: Decimal;
        DirUnitCost: Decimal;
        IndirCostPct: Decimal;
        OvhdRate: Decimal;
        CostTime: Decimal;
        UnitCostCalculation: Enum "Unit Cost Calculation Type";
    begin
        OnBeforeCalcRtngLineCost(RoutingLine, MfgItemQtyBase);
        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (RoutingLine."No." <> '') then
            WorkCenter.Get(RoutingLine."No.");

        UnitCost := RoutingLine."Unit Cost per";
        CalcRoutingCostPerUnit(RoutingLine.Type, RoutingLine."No.", DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculation);
        OnCalcRtngLineCostOnAfterCalcRoutingCostPerUnit(RoutingLine, WorkCenter, MfgItemQtyBase, UnitCostCalculation);
        CostTime :=
          MfgCostCalcMgt.CalculateCostTime(
            MfgItemQtyBase,
            RoutingLine."Setup Time", RoutingLine."Setup Time Unit of Meas. Code",
            RoutingLine."Run Time", RoutingLine."Run Time Unit of Meas. Code", RoutingLine."Lot Size",
            RoutingLine."Scrap Factor % (Accumulated)", RoutingLine."Fixed Scrap Qty. (Accum.)",
            RoutingLine."Work Center No.", UnitCostCalculation, MfgSetup."Cost Incl. Setup",
            RoutingLine."Concurrent Capacities");

        if (RoutingLine.Type = RoutingLine.Type::"Work Center") and (WorkCenter."Subcontractor No." <> '') then
            IncrCost(SLSub, DirUnitCost, CostTime)
        else
            IncrCost(SLCap, DirUnitCost, CostTime);
        IncrCost(SLCapOvhd, CostCalcMgt.CalcOvhdCost(DirUnitCost, IndirCostPct, OvhdRate, 1), CostTime);
    end;

    local procedure TestRtngVersionIsCertified(RtngVersionCode: Code[20]; RtngHeader: Record "Routing Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRtngVersionIsCertified(RtngVersionCode, RtngHeader, LogErrors, IsHandled);
        if IsHandled then
            exit;

        if RtngVersionCode = '' then
            if RtngHeader.Status <> RtngHeader.Status::Certified then
                if LogErrors then
                    InsertInErrBuf(RtngHeader."No.", '', true)
                else
                    RtngHeader.TestField(Status, RtngHeader.Status::Certified);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal; var StdCostWkshName: Text[50]; var ParentItem: Record Item; CostTime: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdBOMFilters(var ProdBOMLine: Record "Production BOM Line"; var PBOMVersionCode: Code[20]; var ProdBOMNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewUseAssemblyList: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    begin
    end;

    internal procedure RunOnBeforeCalcItems(var Item: Record Item)
    begin
        OnBeforeCalcItems(Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItems(var Item: Record Item)
    begin
    end;

    internal procedure RunOnBeforeCalcItem(var Item: Record Item; UseAssemblyList: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeCalcItem(Item, UseAssemblyList, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItem(var Item: Record Item; UseAssemblyList: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMfgItem(var Item: Record Item; var LogErrors: Boolean; StdCostWkshName: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRtngLineCost(var RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal)
    begin
    end;

    internal procedure RunOnCalcAssemblyItemOnAfterInitItemCost(var Item: Record Item)
    begin
        OnCalcAssemblyItemOnAfterInitItemCost(Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterInitItemCost(var Item: Record Item)
    begin
    end;

    internal procedure RunOnCalcAssemblyItemOnAfterCalcItemRolledupCost(var Item: Record Item)
    begin
        OnCalcAssemblyItemOnAfterCalcItemRolledupCost(Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterCalcItemRolledupCost(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBOMVersionIsCertified(BOMVersionCode: Code[20]; ProductionBOMHeader: Record "Production BOM Header"; LogErrors: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRtngVersionIsCertified(RtngVersionCode: Code[20]; RoutingHeader: Record "Routing Header"; LogErrors: Boolean; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnCalcAssemblyItemOnAfterCalcSingleLevelCost(var Item: Record Item)
    begin
        OnCalcAssemblyItemOnAfterCalcSingleLevelCost(Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterCalcSingleLevelCost(var Item: Record Item)
    begin
    end;

    internal procedure RunOnCalcAssemblyItemOnAfterCalcItemCost(var Item: Record Item; CompItem: Record Item; BOMComponent: Record "BOM Component"; ComponentQuantity: Decimal)
    begin
        OnCalcAssemblyItemOnAfterCalcItemCost(Item, CompItem, BOMComponent, ComponentQuantity);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterCalcItemCost(var Item: Record Item; CompItem: Record Item; BOMComponent: Record "BOM Component"; ComponentQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcItemOnBeforeShowStrMenu(var Item: Record Item; var ShowStrMenu: Boolean; var NewCalcMultiLevel: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcItemOnAfterCalcShowConfirm(Item: Record Item; var CalcMfgItems: Boolean; var ShowConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcMfgItemOnBeforeCalcRtngCost(var Item: Record Item; Level: Integer; var LotSize: Decimal; var MfgItemQtyBase: Decimal; var SLCap: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcMfgItemOnBeforeCalculateCosts(var SLMat: Decimal; var SLCap: Decimal; var SLSub: Decimal; var SLCapOvhd: Decimal; var SLMfgOvhd: Decimal; var Item: Record Item; LotSize: Decimal; MfgItemQtyBase: Decimal; Level: Integer; CalculationDate: Date; var RUMat: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdBOMCostOnAfterCalcCompItemQtyBase(CalculationDate: Date; MfgItem: Record Item; MfgItemQtyBase: Decimal; IsTypeItem: Boolean; var ProdBOMLine: Record "Production BOM Line"; var CompItemQtyBase: Decimal; RtngNo: Code[20]; UOMFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdBOMCostOnAfterCalcMfgItem(var ProdBOMLine: Record "Production BOM Line"; MfgItem: Record Item; MfgItemQtyBase: Decimal; CompItem: Record Item; CompItemQtyBase: Decimal; Level: Integer; IsTypeItem: Boolean; UOMFactor: Decimal; var ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdBOMCostOnAfterCalcAnyItem(var ProductionBOMLine: Record "Production BOM Line"; MfgItem: Record Item; MfgItemQtyBase: Decimal; CompItem: Record Item; CompItemQtyBase: Decimal; Level: Integer; IsTypeItem: Boolean; UOMFactor: Decimal; var SLMat: Decimal; var RUMat: Decimal; var RUCap: Decimal; var RUSub: Decimal; var RUCapOvhd: Decimal; var RUMfgOvhd: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRtngCostOnBeforeCalcRtngLineCost(var RoutingLine: Record "Routing Line"; ParentItem: Record Item; var LogErrors: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingCostPerUnitOnBeforeCalc(Type: Enum "Capacity Type Routing"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetWorkCenterOnBeforeAssignWorkCenterToTemp(var WorkCenter: Record "Work Center"; var TempItem: Record Item temporary; StdCostWkshName: Text[50])
    begin
    end;

    internal procedure RunOnAfterGetItem(var Item: Record Item; StdCostWkshName: Text[50]; IsInBuffer: Boolean)
    begin
        OnAfterGetItem(Item, StdCostWkshName, IsInBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var Item: Record Item; StdCostWkshName: Text[50]; IsInBuffer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewUseAssemblyList: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdBOMCost(MfgItem: Record Item; ProdBOMNo: Code[20]; RtngNo: Code[20]; MfgItemQtyBase: Decimal; IsTypeItem: Boolean; Level: Integer; var SLMat: Decimal; var RUMat: Decimal; var RUCap: Decimal; var RUSub: Decimal; var RUCapOvhd: Decimal; var RUMfgOvhd: Decimal; var IsHandled: Boolean; var CalculationDate: Date; var LogErrors: Boolean; var TempRoutingVersion: Record "Routing Version" temporary; var TempProductionBOMVersion: Record "Production BOM Version" temporary)
    begin
    end;

    internal procedure RunOnBeforeDoCalcAssemblyItemPrice(var Item: Record Item; Level: Integer; MaxLevel: Integer; CalcMultiLevel: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeDoCalcAssemblyItemPrice(Item, Level, MaxLevel, CalcMultiLevel, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoCalcAssemblyItemPrice(var Item: Record Item; Level: Integer; MaxLevel: Integer; CalcMultiLevel: Boolean; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(var Item: Record Item; var BOMComponent: Record "BOM Component")
    begin
        OnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(Item, BOMComponent);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(var Item: Record Item; var BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcProdBOMCostOnBeforeCalcCompItemQtyBase(var ProductionBOMLine: Record "Production BOM Line"; var ParentItem: Record Item; CalculationDate: Date; MfgItem: Record Item; MfgItemQtyBase: Decimal; IsTypeItem: Boolean; var CompItemQtyBase: Decimal; RtngNo: Code[20]; UOMFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResCostOnBeforeAssignPriceListLineToTemp(var PriceListLine: Record "Price List Line"; var TempItem: Record Item temporary; StdCostWkshName: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMachineCenterOnBeforeAssignMachineCenterToTemp(var MachineCenter: Record "Machine Center"; var TempItem: Record Item temporary; StdCostWkshName: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRtngLineCostOnAfterCalcRoutingCostPerUnit(RoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center"; var MfgItemQtyBase: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Cost Worksheet", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure OnValidateNoByType(var Rec: Record "Standard Cost Worksheet")
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        if Rec."No." = '' then
            exit;

        case Rec.Type of
            Rec.Type::"Work Center":
                begin
                    WorkCenter.Get(Rec."No.");
                    Rec.Description := WorkCenter.Name;
                    Rec.GetWorkCenterCosts(WorkCenter);
                end;
            Rec.Type::"Machine Center":
                begin
                    MachineCenter.Get(Rec."No.");
                    Rec.Description := MachineCenter.Name;
                    Rec.GetMachineCenterCosts(MachineCenter);
                end;
        end;
    end;
}

