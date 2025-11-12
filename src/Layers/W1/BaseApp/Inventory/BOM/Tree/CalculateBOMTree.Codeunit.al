// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

codeunit 5870 "Calculate BOM Tree"
{

    trigger OnRun()
    begin
    end;

    var
        TempItemAvailByDate: Record "Item Availability by Date" temporary;
        TempMemoizedResult: Record "Memoized Result" temporary;
        ItemFilter: Record Item;
        TempItem: Record Item temporary;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        LocationSpecific: Boolean;
        HideDialog: Boolean;
        EntryNo: Integer;
        AvailToUse: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail;
        MarkBottleneck: Boolean;
        ShowTotalAvailability: Boolean;
        GlobalTreeType: Enum "BOM Tree Type";

#pragma warning disable AA0074
        Text000: Label 'Generating Tree @1@@@@@@@';
#pragma warning restore AA0074

    local procedure OpenWindow()
    begin
        if HideDialog or not GuiAllowed() then
            exit;

        Window.Open(Text000);
        WindowUpdateDateTime := CurrentDateTime;
    end;

    local procedure UpdateWindow(ProgressValue: Integer)
    begin
        if HideDialog or not GuiAllowed() then
            exit;

        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, ProgressValue);
        end;
    end;

    procedure InitVars()
    begin
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();
        TempMemoizedResult.Reset();
        TempMemoizedResult.DeleteAll();
        TempItem.Reset();
        TempItem.DeleteAll();
    end;

    procedure InitBOMBuffer(var BOMBuffer: Record "BOM Buffer")
    begin
        BOMBuffer.Reset();
        BOMBuffer.DeleteAll();
    end;

    procedure InitTreeType(NewTreeType: Enum "BOM Tree Type")
    begin
        GlobalTreeType := NewTreeType;
    end;

    procedure GetTreeType(): Enum "BOM Tree Type"
    begin
        exit(GlobalTreeType);
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure GenerateTreeForManyItems', '27.0')]
    procedure GenerateTreeForItems(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; TreeType: Option " ",Availability,Cost)
    begin
        GenerateTreeForManyItems(ParentItem, BOMBuffer, "BOM Tree Type".FromInteger(TreeType));
    end;
#endif

    procedure GenerateTreeForManyItems(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type")
    var
        i: Integer;
        NoOfRecords: Integer;
        DemandDate: Date;
        IsHandled: Boolean;
    begin
        OnBeforeGenerateTreeForItems(HideDialog);

        OpenWindow();

        IsHandled := false;
        OnBeforeInitBOMBuffer(BOMBuffer, IsHandled);
        if not IsHandled then
            InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        ItemFilter.Copy(ParentItem);

        if ParentItem.GetFilter(ParentItem."Date Filter") <> '' then
            DemandDate := ParentItem.GetRangeMax(ParentItem."Date Filter")
        else
            DemandDate := 99981231D;
        NoOfRecords := ParentItem.Count;
        if ParentItem.FindSet() then
            repeat
                i += 1;
                UpdateWindow(Round(i / NoOfRecords * 10000, 1));
                GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
            until ParentItem.Next() = 0;

        ParentItem.Copy(ItemFilter);

        if not HideDialog and GuiAllowed() then
            Window.Close();
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure GenerateTreeForOneItem()', '27.0')]
    procedure GenerateTreeForItem(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
        GenerateTreeForOneItem(ParentItem, BOMBuffer, DemandDate, "BOM Tree Type".FromInteger(TreeType));
    end;
#endif

    procedure GenerateTreeForOneItem(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Enum "BOM Tree Type")
    begin
        ItemFilter.Copy(ParentItem);

        ParentItem.Get(ParentItem."No.");
        InitBOMBuffer(BOMBuffer);
        InitTreeType(TreeType);
        GenerateTreeForItemLocal(ParentItem, BOMBuffer, DemandDate, TreeType);
        ParentItem.Copy(ItemFilter);
    end;

    local procedure GenerateTreeForItemLocal(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Enum "BOM Tree Type")
    var
        TreeTypeOption: Option;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenerateTreeForItemLocal(ParentItem, DemandDate, TreeType.AsInteger(), BOMBuffer, IsHandled);
        if IsHandled then
            exit;

        InitVars();

        if ParentItem.HasBOM() or (ParentItem.HasRoutingNo()) then begin
            IsHandled := false;
            OnBeforeFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType.AsInteger(), IsHandled);
            if not IsHandled then begin
                BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                BOMBuffer.TransferFromItem(EntryNo, ParentItem, DemandDate);
                GenerateItemSubTree(ParentItem."No.", BOMBuffer);
                TreeTypeOption := TreeType.AsInteger();
                OnGenerateTreeForItemLocalOnBeforeCalculateTreeType(ParentItem, BOMBuffer, TreeTypeOption, EntryNo);
                TreeType := "BOM Tree Type".FromInteger(TreeTypeOption);
                CalculateTreeType(BOMBuffer, ShowTotalAvailability, TreeType);
                OnAfterFilterBOMBuffer(ParentItem, BOMBuffer, DemandDate, TreeType.AsInteger());
            end;
        end;
    end;

    procedure GenerateTreeForSource(SourceRecordVar: Variant; var BOMBuffer: Record "BOM Buffer"; BOMTreeType: Enum "BOM Tree Type"; ShowBy: Enum "BOM Structure Show By"; DemandDate: Date)
    begin
        OnGenerateTreeForSource(SourceRecordVar, BOMBuffer, BOMTreeType, ShowBy, DemandDate, ItemFilter, EntryNo);
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure GenerateTreeForAssemblyHeader()', '27.0')]
    procedure GenerateTreeForAsm(AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit AsmCalculateBOMTree', '27.0')]
    procedure GenerateTreeForAssemblyHeader(AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; var BOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type")
    begin
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by procedure GenerateTreeForProdOrderLine', '27.0')]
    procedure GenerateTreeForProdLine(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        GenerateTreeForProdOrderLine(ProdOrderLine, BOMBuffer, "BOM Tree Type".FromInteger(TreeType));
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    procedure GenerateTreeForProdOrderLine(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type")
    begin
    end;
#endif

    procedure CalculateTreeType(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability2: Boolean; TreeType: Enum "BOM Tree Type")
    begin
        case TreeType of
            "BOM Tree Type"::Availability:
                UpdateAvailability(BOMBuffer, ShowTotalAvailability2);
            "BOM Tree Type"::Cost:
                UpdateCost(BOMBuffer);
        end;
    end;

    procedure GenerateItemSubTree(ItemNo: Code[20]; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        ParentItem: Record Item;
    begin
        ParentItem.Get(ItemNo);
        OnGenerateItemSubTreeOnAfterParentItemGet(ParentItem);
        if TempItem.Get(ItemNo) then begin
            BOMBuffer."Is Leaf" := false;
            BOMBuffer.Modify(true);
            exit(false);
        end;
        TempItem := ParentItem;
        TempItem.Insert();

        if ParentItem.IsMfgItem() then begin
            OnGenerateItemSubTreeOnSetIsLeaf(ParentItem, BOMBuffer, ItemFilter, EntryNo);
            if BOMBuffer."Is Leaf" then
                BOMBuffer."Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
        end else begin
            BOMBuffer."Is Leaf" := not GenerateBOMCompSubTree(ParentItem, BOMBuffer);
            if BOMBuffer."Is Leaf" then
                OnGenerateItemSubTreeOnSetIsLeaf(ParentItem, BOMBuffer, ItemFilter, EntryNo);
        end;
        BOMBuffer.Modify(true);

        TempItem.Get(ItemNo);
        TempItem.Delete();
        exit(not BOMBuffer."Is Leaf");
    end;

    local procedure GenerateBOMCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"): Boolean
    var
        BOMComp: Record "BOM Component";
        ParentBOMBuffer: Record "BOM Buffer";
        IsHandled: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        BOMComp.SetRange("Parent Item No.", ParentItem."No.");
        if BOMComp.FindSet() then begin
            if not ParentItem.IsAssemblyItem() then
                exit(true);

            IsHandled := false;
            OnGenerateBOMCompSubTreeOnBeforeLoopBOMComponents(ParentItem, IsHandled);
            if IsHandled then
                exit(true);
            repeat
                if (BOMComp."No." <> '') and ((BOMComp.Type = BOMComp.Type::Item) or (GlobalTreeType in [GlobalTreeType::" ", GlobalTreeType::Cost])) then begin
                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromBOMComp(
                      EntryNo, BOMComp, ParentBOMBuffer.Indentation + 1,
                      Round(
                        ParentBOMBuffer."Qty. per Top Item" *
                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                      Round(
                        ParentBOMBuffer."Scrap Qty. per Top Item" *
                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                      CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, BOMComp."Lead-Time Offset"),
                      ParentBOMBuffer."Location Code");
                    if BOMComp.Type = BOMComp.Type::Item then
                        GenerateItemSubTree(BOMComp."No.", BOMBuffer);
                end;
            until BOMComp.Next() = 0;
            BOMBuffer := ParentBOMBuffer;
            exit(true);
        end;
    end;

    local procedure UpdateMinAbleToMake(var BOMBuffer: Record "BOM Buffer"; AvailToUse2: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail): Decimal
    var
        AvailQty: Decimal;
    begin
        TempItemAvailByDate.SetRange("Item No.", BOMBuffer."No.");
        TempItemAvailByDate.SetRange("Variant Code", BOMBuffer."Variant Code");
        if LocationSpecific then
            TempItemAvailByDate.SetRange("Location Code", BOMBuffer."Location Code");
        TempItemAvailByDate.SetRange(Date, BOMBuffer."Needed by Date");
        TempItemAvailByDate.FindFirst();

        case AvailToUse2 of
            AvailToUse2::UpdatedQtyOnItemAvail:
                AvailQty := TempItemAvailByDate."Updated Available Qty";
            AvailToUse2::QtyOnItemAvail:
                AvailQty := TempItemAvailByDate."Available Qty";
            AvailToUse2::QtyAvail:
                AvailQty := BOMBuffer."Available Quantity";
        end;

        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then
            exit(MinAbleToMakeWithFixedQuantity(BOMBuffer, AvailQty))
        else begin
            BOMBuffer.UpdateAbleToMake(AvailQty);
            BOMBuffer.Modify();
            exit(BOMBuffer."Able to Make Top Item");
        end;
    end;

    local procedure MinAbleToMakeWithFixedQuantity(var BOMBuffer: Record "BOM Buffer"; AvailableQty: Decimal): Decimal
    begin
        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
            UpdateAvailabilityForFixedQty(BOMBuffer, AvailableQty);
            if AvailableQty < BOMBuffer."Qty. per Parent" then
                exit(0)
            else
                exit(999999999);
        end;
    end;

    local procedure UpdateAvailabilityForFixedQty(var BOMBuffer: Record "BOM Buffer"; AvailableQty: Decimal)
    begin
        if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
            BOMBuffer."Available Quantity" := AvailableQty;
            BOMBuffer.Modify();
        end;
    end;

    local procedure CalcMinAbleToMake(IsFirst: Boolean; OldMin: Decimal; NewMin: Decimal): Decimal
    begin
        if NewMin <= 0 then
            exit(0);
        if IsFirst then
            exit(NewMin);
        if NewMin < OldMin then
            exit(NewMin);
        exit(OldMin);
    end;

    local procedure InitItemAvailDates(var BOMBuffer: Record "BOM Buffer")
    var
        BOMItem: Record Item;
        ParentBOMBuffer: Record "BOM Buffer";
        ZeroDF: DateFormula;
    begin
        ParentBOMBuffer := BOMBuffer;
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.DeleteAll();
        Evaluate(ZeroDF, '<0D>');

        repeat
            if not AvailByDateExists(BOMBuffer) then begin
                BOMItem.CopyFilters(ItemFilter);
                BOMItem.Get(BOMBuffer."No.");
                BOMItem.SetRange("Date Filter", 0D, BOMBuffer."Needed by Date");
                if BOMBuffer.Indentation = 0 then begin
                    BOMItem.SetFilter("Variant Filter", ItemFilter.GetFilter("Variant Filter"));
                    BOMItem.SetFilter("Location Filter", ItemFilter.GetFilter("Location Filter"));
                end else
                    BOMItem.SetRange("Variant Filter", BOMBuffer."Variant Code");

                TempItemAvailByDate.Init();
                TempItemAvailByDate."Item No." := BOMBuffer."No.";
                TempItemAvailByDate.Date := BOMBuffer."Needed by Date";
                TempItemAvailByDate."Variant Code" := BOMBuffer."Variant Code";
                if LocationSpecific then
                    TempItemAvailByDate."Location Code" := BOMBuffer."Location Code";

                Clear(AvailableToPromise);
                OnInitItemAvailDatesOnBeforeCalcAvailableQty(BOMItem);
                TempItemAvailByDate."Available Qty" :=
                  AvailableToPromise.CalcQtyAvailabletoPromise(
                      BOMItem, BOMBuffer."Gross Requirement", BOMBuffer."Scheduled Receipts", BOMBuffer."Needed by Date", "Analysis Period Type"::Day, ZeroDF);
                TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Available Qty";
                TempItemAvailByDate.Insert();

                BOMBuffer.Modify();
            end;
        until (BOMBuffer.Next() = 0) or (BOMBuffer.Indentation <= ParentBOMBuffer.Indentation);
        BOMBuffer := ParentBOMBuffer;
        BOMBuffer.Find();
    end;

    local procedure UpdateAvailability(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability2: Boolean)
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
        SubOptimalQty: Decimal;
        OptimalQty: Decimal;
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        BOMBuffer.SetRange("Inventoriable", true);
        if BOMBuffer.Find() then
            repeat
                if BOMBuffer.Indentation = 0 then begin
                    InitItemAvailDates(BOMBuffer);
                    SubOptimalQty := TraverseTree(BOMBuffer, AvailToUse::QtyOnItemAvail);
                    TempMemoizedResult.DeleteAll();
                    OptimalQty := BinarySearchOptimal(BOMBuffer, UOMMgt.QtyRndPrecision(), SubOptimalQty);
                    MarkBottlenecks(BOMBuffer, OptimalQty);
                    CalcAvailability(BOMBuffer, OptimalQty, false);
                    if ShowTotalAvailability2 then
                        DistributeRemainingAvail(BOMBuffer);
                    TraverseTree(BOMBuffer, AvailToUse::QtyAvail);
                end;
            until BOMBuffer.Next() = 0;
        BOMBuffer.SetRange("Inventoriable");
        BOMBuffer.Copy(CopyOfBOMBuffer);
    end;

    local procedure TraverseTree(var BOMBuffer: Record "BOM Buffer"; AvailToUse2: Option UpdatedQtyOnItemAvail,QtyOnItemAvail,QtyAvail): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
        IsFirst: Boolean;
        MinAbleToMakeQty: Decimal;
        MinAbleToMakeTopItem: Decimal;
        IsHandled: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        IsFirst := true;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation then begin
                if not BOMBuffer."Is Leaf" then
                    TraverseTree(BOMBuffer, AvailToUse2)
                else begin
                    MinAbleToMakeQty := UpdateMinAbleToMake(BOMBuffer, AvailToUse2);
                    MinAbleToMakeTopItem := CalcMinAbleToMake(IsFirst, MinAbleToMakeTopItem, MinAbleToMakeQty);
                end;

                IsHandled := false;
                OnTraverseTreeOnBeforeCalcAbleToMakeParentAndTopItem(BOMBuffer, ParentBOMBuffer, IsHandled);
                if not IsHandled then
                    if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                        ParentBOMBuffer."Able to Make Parent" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Parent", MinAbleToMakeTopItem);
                        ParentBOMBuffer."Able to Make Top Item" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Top Item", MinAbleToMakeTopItem);
                    end
                    else begin
                        ParentBOMBuffer."Able to Make Parent" := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Parent", BOMBuffer."Able to Make Parent");
                        MinAbleToMakeTopItem := CalcMinAbleToMake(IsFirst, ParentBOMBuffer."Able to Make Top Item", BOMBuffer."Able to Make Top Item");
                        ParentBOMBuffer."Able to Make Top Item" := MinAbleToMakeTopItem;
                    end;
                IsFirst := false;
            end;

        BOMBuffer := ParentBOMBuffer;
        UpdateMinAbleToMake(BOMBuffer, AvailToUse2);
        exit(MinAbleToMakeTopItem);
    end;

    local procedure UpdateCost(var BOMBuffer: Record "BOM Buffer")
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        if BOMBuffer.Find() then
            repeat
                if BOMBuffer.Indentation = 0 then
                    TraverseCostTree(BOMBuffer);
            until BOMBuffer.Next() = 0;
        BOMBuffer.Copy(CopyOfBOMBuffer);
    end;

    local procedure TraverseCostTree(var BOMBuffer: Record "BOM Buffer"): Decimal
    var
        ParentBOMBuffer: Record "BOM Buffer";
    begin
        ParentBOMBuffer := BOMBuffer;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if (ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation) and
               ((BOMBuffer."Qty. per Top Item" <> 0) or (BOMBuffer.Type in [BOMBuffer.Type::"Machine Center", BOMBuffer.Type::"Work Center"]))
            then begin
                if not BOMBuffer."Is Leaf" then
                    TraverseCostTree(BOMBuffer)
                else
                    if (BOMBuffer.Type = BOMBuffer.Type::Resource) and (BOMBuffer."Resource Usage Type" = BOMBuffer."Resource Usage Type"::Fixed) then
                        UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size" / ParentBOMBuffer."Qty. per Top Item")
                    else
                        UpdateNodeCosts(BOMBuffer, 1);

                if BOMBuffer."Is Leaf" then begin
                    ParentBOMBuffer.AddMaterialCost(BOMBuffer."Single-Level Material Cost", BOMBuffer."Rolled-up Material Cost");
                    ParentBOMBuffer.AddNonInvMaterialCost(BOMBuffer."Single-Lvl Mat. Non-Invt. Cost", BOMBuffer."Rolled-up Mat. Non-Invt. Cost");
                    ParentBOMBuffer.AddCapacityCost(BOMBuffer."Single-Level Capacity Cost", BOMBuffer."Rolled-up Capacity Cost");
                    ParentBOMBuffer.AddSubcontrdCost(BOMBuffer."Single-Level Subcontrd. Cost", BOMBuffer."Rolled-up Subcontracted Cost");
                    ParentBOMBuffer.AddCapOvhdCost(BOMBuffer."Single-Level Cap. Ovhd Cost", BOMBuffer."Rolled-up Capacity Ovhd. Cost");
                    ParentBOMBuffer.AddMfgOvhdCost(BOMBuffer."Single-Level Mfg. Ovhd Cost", BOMBuffer."Rolled-up Mfg. Ovhd Cost");
                    ParentBOMBuffer.AddScrapCost(BOMBuffer."Single-Level Scrap Cost", BOMBuffer."Rolled-up Scrap Cost");
                end else begin
                    ParentBOMBuffer.AddMaterialCost(
                      BOMBuffer."Single-Level Material Cost" +
                      BOMBuffer."Single-Lvl Mat. Non-Invt. Cost" +
                      BOMBuffer."Single-Level Capacity Cost" +
                      BOMBuffer."Single-Level Subcontrd. Cost" +
                      BOMBuffer."Single-Level Cap. Ovhd Cost" +
                      BOMBuffer."Single-Level Mfg. Ovhd Cost",
                      BOMBuffer."Rolled-up Material Cost");
                    ParentBOMBuffer.AddNonInvMaterialCost(0, BOMBuffer."Rolled-up Mat. Non-Invt. Cost");
                    ParentBOMBuffer.AddCapacityCost(0, BOMBuffer."Rolled-up Capacity Cost");
                    ParentBOMBuffer.AddSubcontrdCost(0, BOMBuffer."Rolled-up Subcontracted Cost");
                    ParentBOMBuffer.AddCapOvhdCost(0, BOMBuffer."Rolled-up Capacity Ovhd. Cost");
                    ParentBOMBuffer.AddMfgOvhdCost(0, BOMBuffer."Rolled-up Mfg. Ovhd Cost");
                    ParentBOMBuffer.AddScrapCost(0, BOMBuffer."Rolled-up Scrap Cost");
                end;
                OnTraverseCostTreeOnAfterAddCosts(ParentBOMBuffer, BOMBuffer);
            end;

        BOMBuffer := ParentBOMBuffer;
        UpdateNodeCosts(BOMBuffer, ParentBOMBuffer."Lot Size");
        exit(BOMBuffer."Able to Make Top Item");
    end;

    local procedure UpdateNodeCosts(var BOMBuffer: Record "BOM Buffer"; LotSize: Decimal)
    begin
        if LotSize = 0 then
            LotSize := 1;
        BOMBuffer.RoundCosts(LotSize);

        if BOMBuffer."Is Leaf" then begin
            case BOMBuffer.Type of
                BOMBuffer.Type::Item:
                    BOMBuffer.GetItemCosts();
                BOMBuffer.Type::Resource:
                    BOMBuffer.GetResCosts();
            end;
            BOMBuffer.RoundCosts(1 / LotSize);
        end else
            if IsProductionOrAssemblyItem(BOMBuffer."No.") then begin
                BOMBuffer.CalcOvhdCost();
                BOMBuffer.RoundCosts(1 / LotSize);
                if not HasBomStructure(BOMBuffer."No.") then
                    BOMBuffer.GetItemUnitCost();
            end else
                if BOMBuffer.Type = BOMBuffer.Type::Item then begin
                    BOMBuffer.RoundCosts(1 / LotSize);
                    BOMBuffer.GetItemCosts();
                end;

        BOMBuffer.CalcUnitCost();
        BOMBuffer.Modify();
    end;

    local procedure BinarySearchOptimal(var BOMBuffer: Record "BOM Buffer"; InputLow: Decimal; InputHigh: Decimal): Decimal
    var
        InputMid: Decimal;
    begin
        if InputHigh <= 0 then
            exit(0);
        if CalcAvailability(BOMBuffer, InputHigh, true) then begin
            TempMemoizedResult.DeleteAll();
            exit(InputHigh);
        end;
        if InputHigh - InputLow = UOMMgt.QtyRndPrecision() then begin
            TempMemoizedResult.DeleteAll();
            exit(InputLow);
        end;
        InputMid := Round((InputLow + InputHigh) / 2, UOMMgt.QtyRndPrecision());
        if not CalcAvailability(BOMBuffer, InputMid, true) then
            exit(BinarySearchOptimal(BOMBuffer, InputLow, InputMid));
        exit(BinarySearchOptimal(BOMBuffer, InputMid, InputHigh));
    end;

    local procedure CalcAvailability(var BOMBuffer: Record "BOM Buffer"; Input: Decimal; IsTest: Boolean): Boolean
    var
        ParentBOMBuffer: Record "BOM Buffer";
        ExpectedQty: Decimal;
        AvailQty: Decimal;
        MaxTime: Integer;
        AvailableVsExpectedCondition: Boolean;
    begin
        if BOMBuffer.Indentation = 0 then begin
            if IsTest then
                if TempMemoizedResult.Get(Input) then
                    exit(TempMemoizedResult.Output);

            ResetUpdatedAvailability();
        end;

        MaxTime := 0;
        ParentBOMBuffer := BOMBuffer;
        while (BOMBuffer.Next() <> 0) and (ParentBOMBuffer.Indentation < BOMBuffer.Indentation) do
            if ParentBOMBuffer.Indentation + 1 = BOMBuffer.Indentation then begin
                TempItemAvailByDate.SetRange("Item No.", BOMBuffer."No.");
                TempItemAvailByDate.SetRange(Date, BOMBuffer."Needed by Date");
                TempItemAvailByDate.SetRange("Variant Code", BOMBuffer."Variant Code");
                if LocationSpecific then
                    TempItemAvailByDate.SetRange("Location Code", BOMBuffer."Location Code");
                TempItemAvailByDate.FindFirst();
                if BOMBuffer."Calculation Formula" = BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                    ExpectedQty := Round(BOMBuffer."Qty. per Parent", UOMMgt.QtyRndPrecision());
                    AvailQty := TempItemAvailByDate."Available Qty"
                end
                else begin
                    ExpectedQty := Round(BOMBuffer."Qty. per Parent" * Input, UOMMgt.QtyRndPrecision());
                    AvailQty := TempItemAvailByDate."Updated Available Qty";
                end;

                AvailableVsExpectedCondition := AvailQty < ExpectedQty;
                OnCalcAvailabilityOnBeforeUpdateAvailableQty(BOMBuffer, ExpectedQty, AvailQty, AvailableVsExpectedCondition);
                if AvailableVsExpectedCondition then begin
                    if BOMBuffer."Is Leaf" then begin
                        if MarkBottleneck then begin
                            BOMBuffer.Bottleneck := true;
                            BOMBuffer.Modify(true);
                        end;
                        BOMBuffer := ParentBOMBuffer;
                        if (BOMBuffer.Indentation = 0) and IsTest then
                            AddMemoizedResult(Input, false);
                        exit(false);
                    end;
                    if AvailQty <> 0 then
                        ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", AvailQty, BOMBuffer."Calculation Formula");
                    if not IsTest then begin
                        BOMBuffer."Available Quantity" := AvailQty;
                        BOMBuffer.Modify();
                    end;
                    if not CalcAvailability(BOMBuffer, ExpectedQty - AvailQty, IsTest) then begin
                        if MarkBottleneck then begin
                            BOMBuffer.Bottleneck := true;
                            BOMBuffer.Modify(true);
                        end;
                        BOMBuffer := ParentBOMBuffer;
                        if (BOMBuffer.Indentation = 0) and IsTest then
                            AddMemoizedResult(Input, false);
                        exit(false);
                    end;
                    if not IsTest then
                        if MaxTime < (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset" then
                            MaxTime := (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset";
                end else begin
                    if not IsTest then begin
                        if BOMBuffer."Calculation Formula" <> BOMBuffer."Calculation Formula"::"Fixed Quantity" then begin
                            BOMBuffer."Available Quantity" := ExpectedQty;
                            BOMBuffer.Modify();
                        end;
                        if MaxTime < (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset" then
                            MaxTime := (ParentBOMBuffer."Needed by Date" - BOMBuffer."Needed by Date") + BOMBuffer."Rolled-up Lead-Time Offset";
                    end;
                    ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", ExpectedQty, BOMBuffer."Calculation Formula");
                end;
            end;
        BOMBuffer := ParentBOMBuffer;
        BOMBuffer."Rolled-up Lead-Time Offset" := MaxTime;
        BOMBuffer.Modify(true);
        if (BOMBuffer.Indentation = 0) and IsTest then
            AddMemoizedResult(Input, true);
        exit(true);
    end;

    local procedure AddMemoizedResult(NewInput: Decimal; NewOutput: Boolean)
    begin
        TempMemoizedResult.Input := NewInput;
        TempMemoizedResult.Output := NewOutput;
        TempMemoizedResult.Insert();
    end;

    local procedure ResetUpdatedAvailability()
    begin
        TempItemAvailByDate.Reset();
        if TempItemAvailByDate.Find('-') then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> TempItemAvailByDate."Available Qty" then begin
                    TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Available Qty";
                    TempItemAvailByDate.Modify();
                end;
            until TempItemAvailByDate.Next() = 0;
    end;

    local procedure ReduceAvailability(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ToDate: Date; Qty: Decimal; BOMLineCalcFormula: Enum "Quantity Calculation Formula")
    begin
        if BOMLineCalcFormula = BOMLineCalcFormula::"Fixed Quantity" then
            exit;
        TempItemAvailByDate.Reset();
        TempItemAvailByDate.SetRange("Item No.", ItemNo);
        TempItemAvailByDate.SetRange("Variant Code", VariantCode);
        if LocationSpecific then
            TempItemAvailByDate.SetRange("Location Code", LocationCode);
        TempItemAvailByDate.SetRange(Date, 0D, ToDate);
        if TempItemAvailByDate.FindSet() then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> 0 then begin
                    if TempItemAvailByDate."Updated Available Qty" > Qty then
                        TempItemAvailByDate."Updated Available Qty" := TempItemAvailByDate."Updated Available Qty" - Qty
                    else
                        TempItemAvailByDate."Updated Available Qty" := 0;
                    TempItemAvailByDate.Modify();
                end;
            until TempItemAvailByDate.Next() = 0;
        TempItemAvailByDate.SetRange("Item No.");
        TempItemAvailByDate.SetRange("Variant Code");
        TempItemAvailByDate.SetRange("Location Code");
        TempItemAvailByDate.SetRange(Date);
    end;

    local procedure DistributeRemainingAvail(var BOMBuffer: Record "BOM Buffer")
    var
        CurrItemAvailByDate: Record "Item Availability by Date";
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        CopyOfBOMBuffer.Copy(BOMBuffer);
        BOMBuffer.Reset();
        BOMBuffer.SetCurrentKey(Type, "No.", Indentation);
        BOMBuffer.SetFilter("Entry No.", '>=%1', BOMBuffer."Entry No.");
        BOMBuffer.SetFilter("Calculation Formula", '<>%1', BOMBuffer."Calculation Formula"::"Fixed Quantity");
        TempItemAvailByDate.Reset();
        if TempItemAvailByDate.FindSet() then
            repeat
                if TempItemAvailByDate."Updated Available Qty" <> 0 then begin
                    CurrItemAvailByDate := TempItemAvailByDate;

                    BOMBuffer.SetRange(Type, BOMBuffer.Type);
                    BOMBuffer.SetRange("No.", TempItemAvailByDate."Item No.");
                    BOMBuffer.SetRange("Variant Code", TempItemAvailByDate."Variant Code");
                    if LocationSpecific then
                        BOMBuffer.SetRange("Location Code", TempItemAvailByDate."Location Code");
                    BOMBuffer.SetRange("Needed by Date", TempItemAvailByDate.Date);
                    if BOMBuffer.FindFirst() then begin
                        BOMBuffer."Available Quantity" += TempItemAvailByDate."Updated Available Qty";
                        BOMBuffer."Unused Quantity" += TempItemAvailByDate."Updated Available Qty";
                        BOMBuffer.Modify();

                        ReduceAvailability(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date", TempItemAvailByDate."Updated Available Qty", BOMBuffer."Calculation Formula");
                    end;

                    TempItemAvailByDate := CurrItemAvailByDate;
                end;
            until TempItemAvailByDate.Next() = 0;
        BOMBuffer.Copy(CopyOfBOMBuffer);
        BOMBuffer.Find();
    end;

    local procedure MarkBottlenecks(var BOMBuffer: Record "BOM Buffer"; Input: Decimal)
    begin
        MarkBottleneck := true;
        CalcAvailability(BOMBuffer, Input + UOMMgt.QtyRndPrecision(), true);
        MarkBottleneck := false;
    end;

    procedure CalcCompDueDate(DemandDate: Date; ParentItem: Record Item; LeadTimeOffset: DateFormula) DueDate: Date
    var
        InventorySetup: Record "Inventory Setup";
        EndDate: Date;
        StartDate: Date;
    begin
        if DemandDate = 0D then
            exit;

        EndDate := DemandDate;
        if Format(ParentItem."Safety Lead Time") <> '' then
            EndDate := DemandDate - (CalcDate(ParentItem."Safety Lead Time", DemandDate) - DemandDate)
        else
            if InventorySetup.Get() and (Format(InventorySetup."Default Safety Lead Time") <> '') then
                EndDate := DemandDate - (CalcDate(InventorySetup."Default Safety Lead Time", DemandDate) - DemandDate);

        if Format(ParentItem."Lead Time Calculation") = '' then
            StartDate := EndDate
        else
            StartDate := EndDate - (CalcDate(ParentItem."Lead Time Calculation", EndDate) - EndDate);

        if Format(LeadTimeOffset) = '' then
            DueDate := StartDate
        else
            DueDate := StartDate - (CalcDate(LeadTimeOffset, StartDate) - StartDate);
    end;

    local procedure AvailByDateExists(BOMBuffer: Record "BOM Buffer"): Boolean
    begin
        if LocationSpecific then
            exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", BOMBuffer."Location Code", BOMBuffer."Needed by Date"));
        exit(TempItemAvailByDate.Get(BOMBuffer."No.", BOMBuffer."Variant Code", '', BOMBuffer."Needed by Date"));
    end;

    procedure SetShowTotalAvailability(NewShowTotalAvailability: Boolean)
    begin
        ShowTotalAvailability := NewShowTotalAvailability;
    end;

    local procedure HasBomStructure(ItemNo: Code[20]) Result: Boolean
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    Item.CalcFields("Assembly BOM");
                    if Item."Assembly BOM" then
                        exit(true);
                end;
            Item."Replenishment System"::"Prod. Order":
                if Item.IsProductionBOM() then
                    exit(true);
        end;

        OnHasBOMStructure(Item, Result);
    end;

    local procedure IsProductionOrAssemblyItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        exit(Item.IsMfgItem() or Item.IsAssemblyItem());
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        ItemFilter.CopyFilters(Item);
    end;

    procedure SetLocationSpecific(NewLocationSpecific: Boolean)
    begin
        LocationSpecific := NewLocationSpecific;
    end;

    procedure GetShowTotalAvailability(): Boolean
    begin
        exit(ShowTotalAvailability);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterGenerateProdCompSubTree(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer")
    begin
        OnAfterGenerateProdCompSubTree(ParentItem, BOMBuffer, ParentBOMBuffer);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateProdCompSubTree(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterTransferFromProdItem(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var EntryNo: Integer)
    begin
        OnAfterTransferFromProdItem(BOMBuffer, ProdBOMLine, EntryNo);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdItem(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var EntryNo: Integer)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line")
    begin
        OnAfterTransferFromProdBOM(BOMBuffer, ProdBOMLine);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterTransferFromProdRouting(var BOMBuffer: Record "BOM Buffer"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line")
    begin
        OnAfterTransferFromProdRouting(BOMBuffer, RoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdRouting(var BOMBuffer: Record "BOM Buffer"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeCalcRoutingLineCosts(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    begin
        OnBeforeCalcRoutingLineCosts(RoutingLine, LotSize, ScrapPct, ParentItem);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineCosts(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterBOMBuffer(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; DemandDate: Date; TreeType: Option; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeFilterByQuantityPer(var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var IsHandled: Boolean; BOMBuffer: Record "BOM Buffer")
    begin
        OnBeforeFilterByQuantityPer(ProductionBOMLine, IsHandled, BOMBuffer);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterByQuantityPer(var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var IsHandled: Boolean; BOMBuffer: Record "BOM Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateTreeForItems(var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateTreeForItemLocal(var ParentItem: Record Item; DemandDate: Date; TreeType: Option; var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo2: Integer; TreeType: Option " ",Availability,Cost)
    begin
        OnBeforeTransferFromProdBOM(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo2, TreeType);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeTransferProdBOMLine(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo2: Integer; TreeType: Option " ",Availability,Cost; var IsHandled: Boolean)
    begin
        OnBeforeTransferProdBOMLine(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo2, TreeType, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferProdBOMLine(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
        OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(ParentBOMBuffer, BOMBuffer);
    end;

    [Obsolete('Moved to codeunit AsmCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateAsmHeaderSubTreeOnAfterAsmLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var FoundSubTree: Boolean)
    begin
        OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem, BOMBuffer, FoundSubTree);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var FoundSubTree: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
        OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(ParentBOMBuffer, BOMBuffer);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
        OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(ParentBOMBuffer, BOMBuffer);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGenerateItemSubTreeOnAfterParentItemGet(var ParentItem: Record Item)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnBeforeBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    begin
        OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(BOMBuffer, ParentBOMBuffer, ParentItem);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTraverseCostTreeOnAfterAddCosts(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTraverseTreeOnBeforeCalcAbleToMakeParentAndTopItem(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var CapCost: Decimal; var SubcontractedCapCost: Decimal; var CapOverhead: Decimal; var BOMBuffer: Record "BOM Buffer");
    begin
        OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine, LotSize, ScrapPct, CapCost, SubcontractedCapCost, CapOverhead, BOMBuffer);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var CapCost: Decimal; var SubcontractedCapCost: Decimal; var CapOverhead: Decimal; var BOMBuffer: Record "BOM Buffer");
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnAfterBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ParentItem: Record Item; ParentBOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
        OnGenerateProdCompSubTreeOnAfterBOMBufferModify(BOMBuffer, RoutingLine, LotSize, ParentItem, ParentBOMBuffer, TreeType);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ParentItem: Record Item; ParentBOMBuffer: Record "BOM Buffer"; TreeType: Option)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var BOMBuffer: Record "BOM Buffer"; var RunIteration: Boolean)
    begin
        OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(RoutingLine, BOMBuffer, RunIteration);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var BOMBuffer: Record "BOM Buffer"; var RunIteration: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGenerateTreeForItemLocalOnBeforeCalculateTreeType(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var TreeType: Option; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemAvailDatesOnBeforeCalcAvailableQty(var BOMItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateBOMCompSubTreeOnBeforeLoopBOMComponents(ParentItem: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBOMBuffer(var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailabilityOnBeforeUpdateAvailableQty(var BOMBuffer: Record "BOM Buffer"; ExpectedQty: Decimal; AvailQty: Decimal; var AvailableVsExpectedCondition: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeGenerateProdOrderLineSubTree(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeGenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer, ParentBOMBuffer, Result, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgCalculateBOMTree', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateProdOrderLineSubTree(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    procedure OnGenerateTreeForSource(SourceRecordVar: Variant; var BOMBuffer: Record "BOM Buffer"; BOMTreeType: Enum "BOM Tree Type"; ShowBy: Enum "BOM Structure Show By"; DemandDate: Date; var ItemFilter: Record Item; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGenerateItemSubTreeOnSetIsLeaf(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ItemFilter: Record Item; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasBOMStructure(var Item: Record Item; var Result: Boolean)
    begin
    end;
}

