// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;

codeunit 99000770 "Where-Used Management"
{
    Permissions = TableData "Production BOM Header" = r,
                  TableData "Production BOM Version" = r,
                  TableData "Where-Used Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempWhereUsedList: Record "Where-Used Line" temporary;
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        MultiLevel: Boolean;
        NextWhereUsedEntryNo: Integer;

    procedure FindRecord(Which: Text[30]; var WhereUsedList2: Record "Where-Used Line"): Boolean
    begin
        TempWhereUsedList.Copy(WhereUsedList2);
        if not TempWhereUsedList.Find(Which) then
            exit(false);
        WhereUsedList2 := TempWhereUsedList;

        exit(true);
    end;

    procedure NextRecord(Steps: Integer; var WhereUsedList2: Record "Where-Used Line"): Integer
    var
        CurrentSteps: Integer;
    begin
        TempWhereUsedList.Copy(WhereUsedList2);
        CurrentSteps := TempWhereUsedList.Next(Steps);
        if CurrentSteps <> 0 then
            WhereUsedList2 := TempWhereUsedList;

        exit(CurrentSteps);
    end;

    procedure WhereUsedFromItem(Item: Record Item; CalcDate: Date; NewMultiLevel: Boolean)
    begin
        BuildWhereUsedListWithCheck(Enum::"Production BOM Line Type"::Item, Item."No.", CalcDate, NewMultiLevel);
    end;

    procedure WhereUsedFromProdBOM(ProdBOM: Record "Production BOM Header"; CalcDate: Date; NewMultiLevel: Boolean)
    begin
        BuildWhereUsedListWithCheck(Enum::"Production BOM Line Type"::"Production BOM", ProdBOM."No.", CalcDate, NewMultiLevel);
    end;

    local procedure BuildWhereUsedListWithCheck(BOMLineType: Enum "Production BOM Line Type"; No: Code[20]; CalcDate: Date; IsMultiLevel: Boolean)
    var
        ProdBOMCheck: Codeunit "Production BOM-Check";
        ProdBOMToCheck: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeBuildWhereUsedListWithCheck(BOMLineType, No, CalcDate, IsMultiLevel, TempWhereUsedList, IsHandled);
        if IsHandled then
            exit;

        if BOMLineType = BOMLineType::Item then
            ProdBOMToCheck := GetItemBOMNo(No)
        else
            ProdBOMToCheck := No;

        ProdBOMCheck.CheckBOM(ProdBOMToCheck, VersionMgt.GetBOMVersion(ProdBOMToCheck, CalcDate, false));

        TempWhereUsedList.DeleteAll();
        NextWhereUsedEntryNo := 1;
        MultiLevel := IsMultiLevel;

        BuildWhereUsedList(BOMLineType, No, CalcDate, 1, 1);
    end;

    local procedure BuildWhereUsedList(Type: Enum "Production BOM Line Type"; No: Code[20]; CalcDate: Date; Level: Integer; Quantity: Decimal)
    var
        ItemAssembly: Record Item;
        ProdBOMComponent: Record "Production BOM Line";
    begin
        OnBeforeBuildWhereUsedList(Type.AsInteger(), No, MultiLevel, CalcDate, Level, Quantity, NextWhereUsedEntryNo, TempWhereUsedList);
        if Level > 30 then
            exit;

        if Type = Type::"Production BOM" then begin
            ItemAssembly.SetCurrentKey("Production BOM No.");
            ItemAssembly.SetRange("Production BOM No.", No);
            OnBuildWhereUsedListOnAfterItemAssemblySetFilters(ItemAssembly, No);
            if ItemAssembly.FindSet() then
                repeat
                    TempWhereUsedList.Init();
                    TempWhereUsedList."Entry No." := NextWhereUsedEntryNo;
                    TempWhereUsedList."Item No." := ItemAssembly."No.";
                    TempWhereUsedList.Description := ItemAssembly.Description;
                    TempWhereUsedList."Level Code" := Level;
                    TempWhereUsedList."Quantity Needed" :=
                      Quantity *
                      (1 + ItemAssembly."Scrap %" / 100) *
                      UOMMgt.GetQtyPerUnitOfMeasure(ItemAssembly, ItemAssembly."Base Unit of Measure") /
                      UOMMgt.GetQtyPerUnitOfMeasure(
                        ItemAssembly,
                        VersionMgt.GetBOMUnitOfMeasure(
                          ItemAssembly."Production BOM No.",
                          VersionMgt.GetBOMVersion(ItemAssembly."Production BOM No.", CalcDate, false)));
                    TempWhereUsedList."Version Code" := VersionMgt.GetBOMVersion(No, CalcDate, true);
                    OnBeforeWhereUsedListInsert(TempWhereUsedList, ItemAssembly, CalcDate, Quantity);
                    TempWhereUsedList.Insert();
                    NextWhereUsedEntryNo := NextWhereUsedEntryNo + 1;
                    if MultiLevel then
                        BuildWhereUsedList(
                          Enum::"Production BOM Line Type"::Item,
                          ItemAssembly."No.",
                          CalcDate,
                          Level + 1,
                          TempWhereUsedList."Quantity Needed");
                until ItemAssembly.Next() = 0;
        end;

        ProdBOMComponent.SetCurrentKey(Type, "No.");
        ProdBOMComponent.SetRange(Type, Type);
        ProdBOMComponent.SetRange("No.", No);
        if CalcDate <> 0D then begin
            ProdBOMComponent.SetFilter("Starting Date", '%1|..%2', 0D, CalcDate);
            ProdBOMComponent.SetFilter("Ending Date", '%1|%2..', 0D, CalcDate);
        end;

        OnBuildWhereUsedListOnBeforeFindSetProdBOMComponent(ProdBOMComponent);

        if ProdBOMComponent.FindSet() then
            repeat
                if VersionMgt.GetBOMVersion(
                     ProdBOMComponent."Production BOM No.", CalcDate, true) =
                   ProdBOMComponent."Version Code"
                then begin
                    OnBuildWhereUsedListOnLoopProdBomComponent(ProdBOMComponent, TempWhereUsedList, NextWhereUsedEntryNo, No, CalcDate, Level);
                    if IsActiveProductionBOM(ProdBOMComponent) then
                        BuildWhereUsedList(
                          Enum::"Production BOM Line Type"::"Production BOM",
                          ProdBOMComponent."Production BOM No.",
                          CalcDate,
                          Level + 1,
                          MfgCostCalcMgt.CalcCompItemQtyBase(ProdBOMComponent, CalcDate, Quantity, '', false));
                end;
            until ProdBOMComponent.Next() = 0;

        OnAfterBuildWhereUsedList(Type.AsInteger(), No, CalcDate, TempWhereUsedList, NextWhereUsedEntryNo, Level, Quantity, MultiLevel);
    end;

    procedure IsActiveProductionBOM(ProductionBOMLine: Record "Production BOM Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsActiveProductionBOM(ProductionBOMLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProductionBOMLine."Version Code" = '' then
            exit(not IsProductionBOMClosed(ProductionBOMLine));

        exit(not IsProdBOMVersionClosed(ProductionBOMLine));
    end;

    local procedure IsProductionBOMClosed(ProductionBOMLine: Record "Production BOM Line"): Boolean
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        ProdBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        exit(ProdBOMHeader.Status = ProdBOMHeader.Status::Closed);
    end;

    local procedure IsProdBOMVersionClosed(ProductionBOMLine: Record "Production BOM Line"): Boolean
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.Get(ProductionBOMLine."Production BOM No.", ProductionBOMLine."Version Code");
        exit(ProductionBOMVersion.Status = ProductionBOMVersion.Status::Closed);
    end;

    local procedure GetItemBOMNo(ItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        OnBeforeGetItemBOMNo(ItemNo, Item, IsHandled);
        if IsHandled then
            exit(Item."Production BOM No.");

        Item.SetLoadFields("Production BOM No.");
        Item.Get(ItemNo);
        exit(Item."Production BOM No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildWhereUsedList(Type: Option " ",Item,"Production BOM"; No: Code[20]; CalcDate: Date; var WhereUsedList: Record "Where-Used Line" temporary; NextWhereUsedEntryNo: Integer; Level: Integer; Quantity: Decimal; MultiLevel: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsActiveProductionBOM(ProductionBOMLine: Record "Production BOM Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBuildWhereUsedList(Type: Option; No: Code[20]; var Multilevel: Boolean; var CalcDate: Date; var Level: Integer; var Quantity: Decimal; var NextWhereUsedEntryNo: Integer; var TempWhereUsedLine: Record "Where-Used Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhereUsedListInsert(var WhereUsedLine: Record "Where-Used Line"; var ItemAssembly: Record Item; var CalcDate: Date; var Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildWhereUsedListOnLoopProdBomComponent(var ProductionBOMLine: Record "Production BOM Line"; var TempWhereUsedLine: Record "Where-Used Line" temporary; var NextWhereUsedEntryNo: Integer; No: Code[20]; CalcDate: Date; var Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildWhereUsedListOnAfterItemAssemblySetFilters(var Item: Record Item; var No: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildWhereUsedListOnBeforeFindSetProdBOMComponent(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBuildWhereUsedListWithCheck(ProductionBOMLineType: Enum "Production BOM Line Type"; No: Code[20]; CalcDate: Date; IsMultiLevel: Boolean; var TempWhereUsedLine: Record "Where-Used Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemBOMNo(ItemNo: Code[20]; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
}

