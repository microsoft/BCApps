// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Costing;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;

codeunit 912 "Calculate Assembly Cost"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempItem: Record Item temporary;
        TempPriceListLine: Record "Price List Line" temporary;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        UOMMgt: Codeunit "Unit of Measure Management";
#if not CLEAN28
        CalculateStandardCost: Codeunit Microsoft.Manufacturing.StandardCost."Calculate Standard Cost";
#endif
        Window: Dialog;
        MaxLevel: Integer;
        NextPriceListLineNo: Integer;
        CalculationDate: Date;
        CalcMultiLevel: Boolean;
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

    procedure SetProperties(NewCalculationDate: Date; NewCalcMultiLevel: Boolean; NewLogErrors: Boolean; NewStdCostWkshName: Text[50]; NewShowDialog: Boolean)
    begin
        TempItem.DeleteAll();
        ClearAll();

        OnBeforeSetProperties(NewCalculationDate, NewCalcMultiLevel, NewLogErrors, NewStdCostWkshName, NewShowDialog);

        CalculationDate := NewCalculationDate;
        CalcMultiLevel := NewCalcMultiLevel;
        LogErrors := NewLogErrors;
        StdCostWkshName := NewStdCostWkshName;
        ShowDialog := NewShowDialog;

        MaxLevel := 50;
        GLSetup.Get();

        OnAfterSetProperties(NewCalculationDate, NewCalcMultiLevel, NewLogErrors, NewStdCostWkshName, NewShowDialog);
    end;

    procedure TestPreconditions(var Item: Record Item)
    var
        TempItem2: Record Item temporary;
    begin
        CalcItems(Item, TempItem2);
    end;

    local procedure AnalyzeAssemblyList(var Item: Record Item; var Depth: Integer; var NonAssemblyItemWithList: Boolean; var ContainsProdBOM: Boolean)
    var
        BOMComponent: Record "BOM Component";
        SubItem: Record Item;
        BaseDepth: Integer;
        MaxDepth: Integer;
    begin
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

    procedure CalcItem(ItemNo: Code[20])
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
        OnBeforeCalcItem(Item, IsHandled);
#if not CLEAN28
        CalculateStandardCost.RunOnBeforeCalcItem(Item, true, IsHandled);
#endif
        if IsHandled then
            exit;

        Instruction := PrepareAssemblyCalculation(Item, Depth, 1, AssemblyContainsProdBOM); // 1=StandardCost

        ShowStrMenu := Depth > 1;
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

        SetProperties(WorkDate(), NewCalcMultiLevel, false, '', false);

        ShowConfirm := NewCalcMultiLevel and AssemblyContainsProdBOM;
        OnCalcItemOnAfterCalcShowConfirm(Item, CalcMfgItems, ShowConfirm);
        if ShowConfirm then
            CalcMfgItems := Confirm(CalcMfgPrompt, false, Item."No.");
        CalcAssemblyItem(ItemNo, Item, 0, CalcMfgItems);

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
#if not CLEAN28
        CalculateStandardCost.RunOnBeforeCalcItems(Item);
#endif

        NoOfRecords := Item.Count();
        if ShowDialog then
            Window.Open(Text002);

        if Item2.Find('-') then
            repeat
                LineCount := LineCount + 1;
                if ShowDialog then
                    Window.Update(1, Round(LineCount / NoOfRecords * 10000, 1));
                CalcAssemblyItem(Item2."No.", Item3, 0, true);
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
#if not CLEAN28
            CalculateStandardCost.RunOnCalcAssemblyItemOnAfterInitItemCost(Item);
#endif
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
                                        CalcAssemblyItem(BOMComp."No.", CompItem, Level + 1, CalcMfgItems);
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
#if not CLEAN28
                            CalculateStandardCost.RunOnCalcAssemblyItemOnAfterCalcItemCost(Item, CompItem, BOMComp, ComponentQuantity);
#endif
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
#if not CLEAN28
            CalculateStandardCost.RunOnCalcAssemblyItemOnAfterCalcItemRolledupCost(Item);
#endif

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
#if not CLEAN28
            CalculateStandardCost.RunOnCalcAssemblyItemOnAfterCalcSingleLevelCost(Item);
#endif

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

        SetProperties(WorkDate(), NewCalcMultiLevel, false, '', false);

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
#if not CLEAN28
        CalculateStandardCost.RunOnBeforeDoCalcAssemblyItemPrice(Item, Level, MaxLevel, CalcMultiLevel, IsHandled);
#endif
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
#if not CLEAN28
        CalculateStandardCost.RunOnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(Item, BOMComp);
#endif
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

    local procedure GetItem(ItemNo: Code[20]; var Item: Record Item) IsInBuffer: Boolean
    var
        StdCostWksh: Record Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet";
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
#if not CLEAN28
        CalculateStandardCost.RunOnAfterGetItem(Item, StdCostWkshName, IsInBuffer);
#endif
    end;

    local procedure GetResCost(ResourceNo: Code[20]; var PriceListLine: Record "Price List Line")
    var
        StdCostWksh: Record Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet";
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItems(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItem(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterInitItemCost(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterCalcItemRolledupCost(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAssemblyItemOnAfterCalcSingleLevelCost(var Item: Record Item)
    begin
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
    local procedure OnAfterGetItem(var Item: Record Item; StdCostWkshName: Text[50]; IsInBuffer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProperties(var NewCalculationDate: Date; var NewCalcMultiLevel: Boolean; var NewLogErrors: Boolean; var NewStdCostWkshName: Text[50]; var NewShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoCalcAssemblyItemPrice(var Item: Record Item; Level: Integer; MaxLevel: Integer; CalcMultiLevel: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoCalcAssemblyItemPriceOnAfterSetBOMCompFilters(var Item: Record Item; var BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResCostOnBeforeAssignPriceListLineToTemp(var PriceListLine: Record "Price List Line"; var TempItem: Record Item temporary; StdCostWkshName: Text[50])
    begin
    end;

    // Subscribers

    [EventSubscriber(ObjectType::Table, Database::Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet", 'OnAfterGetItemCosts', '', false, false)]
    local procedure OnAfterGetItemCosts(var StandardCostWorksheet: Record Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet"; var Item: Record Item)
    begin
        if Item.IsMfgItem() then
            StandardCostWorksheet.TransferManufCostsFromItem(Item);
    end;
}

