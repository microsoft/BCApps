// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM.Tree;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.StandardCost;

codeunit 99000781 "Mfg. Calculate BOM Tree"
{
    var
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate BOM Tree", 'OnGenerateTreeForSource', '', false, false)]
    local procedure ProdOrderLineOnGenerateTreeForSource(SourceRecordVar: Variant; var BOMBuffer: Record "BOM Buffer"; BOMTreeType: Enum "BOM Tree Type"; ShowBy: Enum Microsoft.Inventory.BOM."BOM Structure Show By"; DemandDate: Date; var ItemFilter: Record Item; var EntryNo: Integer; sender: Codeunit "Calculate BOM Tree")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case ShowBy of
            ShowBy::Production:
                begin
                    ProdOrderLine := SourceRecordVar;
                    ProdOrderLine."Due Date" := DemandDate;
                    GenerateTreeForProdOrderLine(ProdOrderLine, BOMBuffer, BOMTreeType, ItemFilter, EntryNo, sender);
                end;
        end;
    end;

    procedure GenerateTreeForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type"; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree")
    begin
        sender.InitBOMBuffer(BOMBuffer);
        sender.InitTreeType(TreeType);
        sender.InitVars();
        sender.SetLocationSpecific(true);
        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
        BOMBuffer.TransferFromProdOrderLine(EntryNo, ProdOrderLine);
        if not GenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer, ItemFilter, EntryNo, sender) then
            sender.GenerateItemSubTree(ProdOrderLine."Item No.", BOMBuffer);

        sender.CalculateTreeType(BOMBuffer, sender.GetShowTotalAvailability(), TreeType);
    end;

    local procedure GenerateProdCompSubTree(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree") FoundSubTree: Boolean
    var
        CopyOfParentItem: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
        ParentBOMBuffer: Record "BOM Buffer";
        VersionMgt: Codeunit VersionManagement;
        TreeType: Enum "BOM Tree Type";
        LotSize: Decimal;
        BomQtyPerUom: Decimal;
        IsHandled: Boolean;
        RunIteration: Boolean;
    begin
        ParentBOMBuffer := BOMBuffer;
        if not ProdBOMLine.ReadPermission then
            exit;

        TreeType := sender.GetTreeType();
        ProdBOMLine.SetRange("Production BOM No.", ParentItem."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionMgt.GetBOMVersion(ParentItem."Production BOM No.", WorkDate(), true));
        ProdBOMLine.SetFilter("Starting Date", '%1|..%2', 0D, ParentBOMBuffer."Needed by Date");
        ProdBOMLine.SetFilter("Ending Date", '%1|%2..', 0D, ParentBOMBuffer."Needed by Date");
        IsHandled := false;
        OnBeforeFilterByQuantityPer(ProdBOMLine, IsHandled, ParentBOMBuffer);
#if not CLEAN27
        sender.RunOnBeforeFilterByQuantityPer(ProdBOMLine, IsHandled, ParentBOMBuffer);
#endif
        if not IsHandled then
            if TreeType = "BOM Tree Type"::Availability then
                ProdBOMLine.SetFilter("Quantity per", '>%1', 0);
        if ProdBOMLine.FindSet() then begin
            if not ParentItem.IsMfgItem() then begin
                FoundSubTree := true;
                OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem, BOMBuffer, FoundSubTree);
#if not CLEAN27
                sender.RunOnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem, BOMBuffer, FoundSubTree);
#endif
                exit(FoundSubTree);
            end;
            repeat
                IsHandled := false;
                OnBeforeTransferProdBOMLine(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType.AsInteger(), IsHandled);
#if not CLEAN27
                sender.RunOnBeforeTransferProdBOMLine(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType.AsInteger(), IsHandled);
#endif
                if not IsHandled then
                    if ProdBOMLine."No." <> '' then
                        case ProdBOMLine.Type of
                            ProdBOMLine.Type::Item:
                                begin
                                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                                    BomQtyPerUom :=
                                    GetQtyPerBOMHeaderUnitOfMeasure(
                                        ParentItem, ParentBOMBuffer."Production BOM No.",
                                        VersionMgt.GetBOMVersion(ParentBOMBuffer."Production BOM No.", WorkDate(), true));
                                    BOMBuffer.TransferFromProdComp(
                                    EntryNo, ProdBOMLine, ParentBOMBuffer.Indentation + 1,
                                    Round(
                                        ParentBOMBuffer."Qty. per Top Item" *
                                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                                    Round(
                                        ParentBOMBuffer."Scrap Qty. per Top Item" *
                                        UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision()),
                                    ParentBOMBuffer."Scrap %",
                                    sender.CalcCompDueDate(ParentBOMBuffer."Needed by Date", ParentItem, ProdBOMLine."Lead-Time Offset"),
                                    ParentBOMBuffer."Location Code",
                                    ParentItem, BomQtyPerUom);

                                    if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then begin
                                        BOMBuffer."Qty. per Parent" := BOMBuffer."Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                        BOMBuffer."Scrap Qty. per Parent" := BOMBuffer."Scrap Qty. per Parent" * ParentBOMBuffer."Qty. per Parent";
                                        BOMBuffer."Qty. per BOM Line" := BOMBuffer."Qty. per BOM Line" * ParentBOMBuffer."Qty. per Parent";
                                    end;
                                    OnAfterTransferFromProdItem(BOMBuffer, ProdBOMLine, EntryNo);
#if not CLEAN27
                                    sender.RunOnAfterTransferFromProdItem(BOMBuffer, ProdBOMLine, EntryNo);
#endif
                                    sender.GenerateItemSubTree(ProdBOMLine."No.", BOMBuffer);
                                    OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(ParentBOMBuffer, BOMBuffer);
#if not CLEAN27
                                    sender.RunOnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(ParentBOMBuffer, BOMBuffer);
#endif
                                end;
                            ProdBOMLine.Type::"Production BOM":
                                begin
                                    OnBeforeTransferFromProdBOM(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType);
#if not CLEAN27
                                    sender.RunOnBeforeTransferFromProdBOM(BOMBuffer, ProdBOMLine, ParentItem, ParentBOMBuffer, EntryNo, TreeType.AsInteger());
#endif
                                    BOMBuffer := ParentBOMBuffer;
                                    BOMBuffer."Qty. per Top Item" := Round(BOMBuffer."Qty. per Top Item" * ProdBOMLine."Quantity per", UOMMgt.QtyRndPrecision());
                                    if ParentItem."Production BOM No." <> ParentBOMBuffer."Production BOM No." then
                                        BOMBuffer."Qty. per Parent" := ParentBOMBuffer."Qty. per Parent" * ProdBOMLine."Quantity per"
                                    else
                                        BOMBuffer."Qty. per Parent" := ProdBOMLine."Quantity per";

                                    BOMBuffer."Scrap %" := CombineScrapFactors(BOMBuffer."Scrap %", ProdBOMLine."Scrap %");
                                    BOMBuffer."Scrap %" := Round(BOMBuffer."Scrap %", 0.00001);

                                    OnAfterTransferFromProdBOM(BOMBuffer, ProdBOMLine);
#if not CLEAN27
                                    sender.RunOnAfterTransferFromProdBOM(BOMBuffer, ProdBOMLine);
#endif

                                    CopyOfParentItem := ParentItem;
                                    ParentItem."Routing No." := '';
                                    ParentItem."Production BOM No." := ProdBOMLine."No.";
                                    GenerateProdCompSubTree(ParentItem, BOMBuffer, ItemFilter, EntryNo, sender);
                                    ParentItem := CopyOfParentItem;

                                    OnAfterGenerateProdCompSubTree(ParentItem, BOMBuffer, ParentBOMBuffer);
#if not CLEAN27
                                    sender.RunOnAfterGenerateProdCompSubTree(ParentItem, BOMBuffer, ParentBOMBuffer);
#endif
                                end;
                        end;
                OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(ParentBOMBuffer, BOMBuffer);
#if not CLEAN27
                sender.RunOnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(ParentBOMBuffer, BOMBuffer);
#endif
            until ProdBOMLine.Next() = 0;
            FoundSubTree := true;
        end;

        if RoutingLine.ReadPermission then
            if (TreeType in ["BOM Tree Type"::" ", "BOM Tree Type"::Cost]) and
                   RoutingLine.CertifiedRoutingVersionExists(ParentItem."Routing No.", WorkDate())
            then begin
                repeat
                    RunIteration := RoutingLine."No." <> '';
                    OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(RoutingLine, BOMBuffer, RunIteration);
#if not CLEAN27
                    sender.RunOnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(RoutingLine, BOMBuffer, RunIteration);
#endif
                    if RunIteration then begin
                        BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                        BOMBuffer.TransferFromProdRouting(
                          EntryNo, RoutingLine, ParentBOMBuffer.Indentation + 1,
                          ParentBOMBuffer."Qty. per Top Item" *
                          UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code"),
                          ParentBOMBuffer."Needed by Date",
                          ParentBOMBuffer."Location Code");
                        OnAfterTransferFromProdRouting(BOMBuffer, RoutingLine);
#if not CLEAN27
                        sender.RunOnAfterTransferFromProdRouting(BOMBuffer, RoutingLine);
#endif
                        if TreeType = "BOM Tree Type"::Cost then begin
                            LotSize := ParentBOMBuffer."Lot Size";
                            if LotSize = 0 then
                                if ParentBOMBuffer."Qty. per Top Item" <> 0 then
                                    LotSize := ParentBOMBuffer."Qty. per Top Item"
                                else
                                    LotSize := 1;
#if not CLEAN27
                            CalcRoutingLineCosts(RoutingLine, LotSize, ParentBOMBuffer."Scrap %", BOMBuffer, ParentItem, sender);
#else
                            CalcRoutingLineCosts(RoutingLine, LotSize, ParentBOMBuffer."Scrap %", BOMBuffer, ParentItem);
#endif
                            BOMBuffer.RoundCosts(
                              ParentBOMBuffer."Qty. per Top Item" *
                              UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ParentBOMBuffer."Unit of Measure Code") / LotSize);
                            OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(BOMBuffer, ParentBOMBuffer, ParentItem);
#if not CLEAN27
                            sender.RunOnGenerateProdCompSubTreeOnBeforeBOMBufferModify(BOMBuffer, ParentBOMBuffer, ParentItem);
#endif
                            BOMBuffer.Modify();
                        end;
                        OnGenerateProdCompSubTreeOnAfterBOMBufferModify(BOMBuffer, RoutingLine, LotSize, ParentItem, ParentBOMBuffer, TreeType);
#if not CLEAN27
                        sender.RunOnGenerateProdCompSubTreeOnAfterBOMBufferModify(BOMBuffer, RoutingLine, LotSize, ParentItem, ParentBOMBuffer, TreeType.AsInteger());
#endif
                    end;
                until RoutingLine.Next() = 0;
                FoundSubTree := true;
            end;

        BOMBuffer := ParentBOMBuffer;
    end;

    local procedure GenerateProdOrderLineSubTree(ProdOrderLine: Record "Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; var ItemFilter: Record Item; var EntryNo: Integer; var sender: Codeunit "Calculate BOM Tree") Result: Boolean
    var
        OldProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ParentBOMBuffer: Record "BOM Buffer";
        IsHandled: Boolean;
    begin
        OnBeforeGenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer, ParentBOMBuffer, Result, IsHandled);
#if not CLEAN27
        sender.RunOnBeforeGenerateProdOrderLineSubTree(ProdOrderLine, BOMBuffer, ParentBOMBuffer, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        ParentBOMBuffer := BOMBuffer;
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.FindSet() then begin
            repeat
                if ProdOrderComp."Item No." <> '' then begin
                    OldProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");
                    if ProdOrderLine."Due Date" <> OldProdOrderLine."Due Date" then
                        ProdOrderComp."Due Date" := ProdOrderComp."Due Date" - (OldProdOrderLine."Due Date" - ProdOrderLine."Due Date");

                    BOMBuffer.SetLocationVariantFiltersFrom(ItemFilter);
                    BOMBuffer.TransferFromProdOrderComp(EntryNo, ProdOrderComp);
                    sender.GenerateItemSubTree(ProdOrderComp."Item No.", BOMBuffer);
                end;
            until ProdOrderComp.Next() = 0;
            BOMBuffer := ParentBOMBuffer;

            exit(true);
        end;
    end;

#if not CLEAN27
    local procedure CalcRoutingLineCosts(RoutingLine: Record "Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var BOMBuffer: Record "BOM Buffer"; var ParentItem: Record Item; var sender: Codeunit "Calculate BOM Tree")
#else
    local procedure CalcRoutingLineCosts(RoutingLine: Record "Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var BOMBuffer: Record "BOM Buffer"; var ParentItem: Record Item)
#endif
    var
        CalcStdCost: Codeunit "Calculate Standard Cost";
        CapCost: Decimal;
        SubcontractedCapCost: Decimal;
        CapOverhead: Decimal;
    begin
        OnBeforeCalcRoutingLineCosts(RoutingLine, LotSize, ScrapPct, ParentItem);
#if not CLEAN27
        sender.RunOnBeforeCalcRoutingLineCosts(RoutingLine, LotSize, ScrapPct, ParentItem);
#endif

        CalcStdCost.SetProperties(WorkDate(), false, false, false, '', false);
        CalcStdCost.CalcRtngLineCost(
          RoutingLine, MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(LotSize, ScrapPct), CapCost, SubcontractedCapCost, CapOverhead, ParentItem);

        OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine, LotSize, ScrapPct, CapCost, SubcontractedCapCost, CapOverhead, BOMBuffer);
#if not CLEAN27
        sender.RunOnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine, LotSize, ScrapPct, CapCost, SubcontractedCapCost, CapOverhead, BOMBuffer);
#endif

        BOMBuffer.AddCapacityCost(CapCost, CapCost);
        BOMBuffer.AddSubcontrdCost(SubcontractedCapCost, SubcontractedCapCost);
        BOMBuffer.AddCapOvhdCost(CapOverhead, CapOverhead);
    end;

    local procedure GetBOMUnitOfMeasure(ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Code[10]
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if ProdBOMVersionNo <> '' then begin
            ProdBOMVersion.Get(ProdBOMNo, ProdBOMVersionNo);
            exit(ProdBOMVersion."Unit of Measure Code");
        end;

        ProdBOMHeader.Get(ProdBOMNo);
        exit(ProdBOMHeader."Unit of Measure Code");
    end;

    local procedure GetQtyPerBOMHeaderUnitOfMeasure(Item: Record Item; ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]): Decimal
    begin
        if ProdBOMNo = '' then
            exit(1);

        exit(UOMMgt.GetQtyPerUnitOfMeasure(Item, GetBOMUnitOfMeasure(ProdBOMNo, ProdBOMVersionNo)));
    end;

    local procedure CombineScrapFactors(LowLevelScrapPct: Decimal; HighLevelScrapPct: Decimal): Decimal
    begin
        exit(LowLevelScrapPct + HighLevelScrapPct + LowLevelScrapPct * HighLevelScrapPct / 100);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calculate BOM Tree", 'OnGenerateItemSubTreeOnSetIsLeaf', '', false, false)]
    local procedure OnGenerateItemSubTreeOnSetIsLeaf(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ItemFilter: Record Item; var EntryNo: Integer; sender: Codeunit "Calculate BOM Tree")
    begin
        BOMBuffer."Is Leaf" := not GenerateProdCompSubTree(ParentItem, BOMBuffer, ItemFilter, EntryNo, sender);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterByQuantityPer(var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var IsHandled: Boolean; BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeExitForNonProdOrder(ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var FoundSubTree: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdItem(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterGenerateItemSubTree(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Enum "BOM Tree Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdBOM(var BOMBuffer: Record "BOM Buffer"; ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateProdCompSubTree(var ParentItem: Record Item; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterProdBOMLineLoop(var ParentBOMBuffer: Record "BOM Buffer"; var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnAfterBOMBufferModify(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ParentItem: Record Item; ParentBOMBuffer: Record "BOM Buffer"; TreeType: Enum "BOM Tree Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateProdOrderLineSubTree(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var BOMBuffer: Record "BOM Buffer"; var ParentBOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineCosts(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var LotSize: Decimal; var ScrapPct: Decimal; ParentItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineCostsOnBeforeBOMBufferAdd(RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; LotSize: Decimal; ScrapPct: Decimal; var CapCost: Decimal; var SubcontractedCapCost: Decimal; var CapOverhead: Decimal; var BOMBuffer: Record "BOM Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferProdBOMLine(var BOMBuffer: Record "BOM Buffer"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var ParentItem: Record Item; var ParentBOMBuffer: Record "BOM Buffer"; var EntryNo: Integer; TreeType: Option " ",Availability,Cost; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateProdCompSubTreeOnBeforeRoutingLineLoop(var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var BOMBuffer: Record "BOM Buffer"; var RunIteration: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdRouting(var BOMBuffer: Record "BOM Buffer"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BOM Node", 'OnWriteToDatabaseOnProductionBOM', '', false, false)]
    local procedure OnWriteToDatabaseOnProductionBOM(BOMNo: Code[20]; CalculateLowLevelCode: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.SetRange("No.", BOMNo);
        ProductionBOMHeader.ModifyAll("Low-Level Code", CalculateLowLevelCode);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Component", 'OnCopyFromItemOnAfterGetParentItem', '', false, false)]
    local procedure OnCopyFromItemOnAfterGetParentItem(var Item: Record Item; ParentItem: Record Item)
    var
        CalcLowLevelCode: Codeunit Microsoft.Manufacturing.ProductionBOM."Calculate Low-Level Code";
    begin
        CalcLowLevelCode.SetRecursiveLevelsOnItem(Item, ParentItem."Low-Level Code" + 1, true);
    end;

}