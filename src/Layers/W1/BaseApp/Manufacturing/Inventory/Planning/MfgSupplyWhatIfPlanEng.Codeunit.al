// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Planning;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Utilities;

codeunit 99000848 "Mfg. Supply What-If Plan. Eng."
{
    var
        ProdOrderScenarioLbl: Label 'Production %1 %2 - %3 - %4', Comment = '%1 - Status, %2 - Prod. Order No., %3 - Item No., %4 - Line No.';

    [EventSubscriber(ObjectType::Table, Database::"Supply What-If Scenario", OnUpdateBySourceRecordOnElseCase, '', false, false)]
    local procedure OnUpdateBySourceRecordOnElseCase(var WhatIfScenario: Record "Supply What-If Scenario"; RecRef: RecordRef; var IsHandled: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if RecRef.Number <> Database::"Prod. Order Line" then
            exit;

        RecRef.SetTable(ProdOrderLine);
        UpdateFromProdOrderLine(WhatIfScenario, ProdOrderLine);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"What-If Impacts", OnEnum2StrOnElseCase, '', false, false)]
    local procedure OnEnum2StrOnElseCase(TableId: Integer; Status: Integer; var Result: Text)
    begin
        if TableId <> Database::"Prod. Order Line" then
            exit;

        Result := Format(Enum::"Production Order Status".FromInteger(Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"What-If Impacts", OnShowDocumentOnElseCase, '', false, false)]
    local procedure OnShowDocumentOnElseCase(var WhatIfImpact: Record "What-If Impact")
    var
        ProductionOrder: Record "Production Order";
        PageManagement: Codeunit "Page Management";
    begin
        if WhatIfImpact."Impact Table Id" <> Database::"Prod. Order Line" then
            exit;

        ProductionOrder.Get(Enum::"Production Order Status".FromInteger(WhatIfImpact."Document Status"), WhatIfImpact."Document No.");
        Page.Run(PageManagement.GetPageId(ProductionOrder), ProductionOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnRunWhatIfAnalysisOnAfterSetFilters, '', false, false)]
    local procedure OnRunWhatIfAnalysisOnAfterSetFilters(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var FindReservationEntry: Record "Reservation Entry")
    begin
        if TempWhatIfScenario."Document Table No." <> Database::"Prod. Order Line" then
            exit;

        FindReservationEntry.SetRange("Source Ref. No.");
        FindReservationEntry.SetRange("Source Prod. Order Line", TempWhatIfScenario."Document Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnSimulatePlanningAndFindReservationsOnAfterSetFilters, '', false, false)]
    local procedure OnSimulatePlanningAndFindReservationsOnAfterSetFilters(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var FindReservationEntry: Record "Reservation Entry")
    begin
        if TempWhatIfScenario."Document Table No." <> Database::"Prod. Order Line" then
            exit;

        FindReservationEntry.SetRange("Source Ref. No.");
        FindReservationEntry.SetRange("Source Prod. Order Line", TempWhatIfScenario."Document Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnBeforeInsertWhatIfImpact, '', false, false)]
    local procedure OnBeforeInsertWhatIfImpact(ReservationEntry: Record "Reservation Entry"; var TableId: Integer; var DocumentLineNo: Integer; var ImpactedItemNo: Code[20]; var IsHandled: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if IsHandled then
            exit;

        if ReservationEntry."Source Type" <> Database::"Prod. Order Component" then
            exit;

        ProdOrderLine.SetLoadFields("Item No.");
        ProdOrderLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        TableId := Database::"Prod. Order Line";
        DocumentLineNo := ProdOrderLine."Line No.";
        ImpactedItemNo := ProdOrderLine."Item No.";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnBeforeUpdateTableRecord, '', false, false)]
    local procedure OnBeforeUpdateTableRecord(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var IsHandled: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if IsHandled then
            exit;

        if TempWhatIfScenario."Document Table No." <> Database::"Prod. Order Line" then
            exit;

        ProdOrderLine.Get(Enum::"Production Order Status".FromInteger(TempWhatIfScenario."Document Type"), TempWhatIfScenario."Document No.", TempWhatIfScenario."Document Line No.");
        if TempWhatIfScenario."What-If Quantity" <> ProdOrderLine.Quantity then
            ProdOrderLine.Quantity := TempWhatIfScenario."What-If Quantity";

        if TempWhatIfScenario."What-If Date" <> ProdOrderLine."Due Date" then
            ProdOrderLine."Due Date" := TempWhatIfScenario."What-If Date";

        ProdOrderLine.Modify();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnAddItemToListOnAfterAddItem, '', false, false)]
    local procedure OnAddItemToListOnAfterAddItem(ItemNo: Code[20]; var Item: Record Item; var ItemsToAnalyze: List of [Code[20]])
    begin
        if Item."Production BOM No." <> '' then
            GetBOMItems(Item."Production BOM No.", ItemsToAnalyze);

        AddParentItems(ItemNo, ItemsToAnalyze);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Supply What-If Planning Engine", OnSimulatePlanningOnRunCalcItemPlan, '', false, false)]
    local procedure OnSimulatePlanningOnRunCalcItemPlan(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var Item: Record Item; WorksheetTemplateName: Code[10])
    var
        CalcItemPlan: Codeunit "Calc. Item Plan - Plan Wksh.";
    begin
        CalcItemPlan.SetSimulationMode(true);
        CalcItemPlan.SetTemplAndWorksheet(WorksheetTemplateName, '', false);
        CalcItemPlan.SetParm('', 0D, Item);
        CalcItemPlan.Initialize(TempWhatIfScenario."Original Date", CalcDate('<1M>', TempWhatIfScenario."Original Date"), true, true, false);
        CalcItemPlan.Run(Item);
    end;

    local procedure UpdateFromProdOrderLine(var WhatIfScenario: Record "Supply What-If Scenario"; ProdOrderLine: Record "Prod. Order Line")
    begin
        WhatIfScenario."Document Table No." := Database::"Prod. Order Line";
        WhatIfScenario."Scenario Name" := StrSubstNo(ProdOrderScenarioLbl, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Item No.", ProdOrderLine."Line No.");
        WhatIfScenario."Document Type" := ProdOrderLine.Status.AsInteger();
        WhatIfScenario."Document No." := ProdOrderLine."Prod. Order No.";
        WhatIfScenario."Document Line No." := ProdOrderLine."Line No.";
        WhatIfScenario."Item No." := ProdOrderLine."Item No.";
        WhatIfScenario."Location Code" := ProdOrderLine."Location Code";
        WhatIfScenario."Original Quantity" := ProdOrderLine.Quantity;
        WhatIfScenario."What-If Quantity" := ProdOrderLine.Quantity;
        WhatIfScenario."Original Date" := ProdOrderLine."Due Date";
        WhatIfScenario."What-If Date" := ProdOrderLine."Due Date";
    end;

    local procedure GetBOMItems(BOMNo: Code[20]; var ItemsToAnalyze: List of [Code[20]])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ActiveVersion: Code[20];
    begin
        if not ShouldTrackThisBom(BOMNo, ActiveVersion) then
            exit;

        ProductionBOMLine.SetLoadFields(Type, "No.");
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        if ActiveVersion <> '' then
            ProductionBOMLine.SetRange("Version Code", ActiveVersion);

        ProductionBOMLine.SetFilter(Type, '<>%1', ProductionBOMLine.Type::" ");
        if ProductionBOMLine.FindSet() then
            repeat
                if ProductionBOMLine.Type = ProductionBOMLine.Type::Item then
                    AddItemToListFromBOM(ProductionBOMLine."No.", ItemsToAnalyze)
                else
                    GetBOMItems(ProductionBOMLine."No.", ItemsToAnalyze);
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure AddItemToListFromBOM(ItemNo: Code[20]; var ItemsToAnalyze: List of [Code[20]])
    var
        Item: Record Item;
    begin
        if ItemsToAnalyze.Contains(ItemNo) then
            exit;

        Item.SetLoadFields("Production BOM No.");
        Item.Get(ItemNo);
        ItemsToAnalyze.Add(ItemNo);

        if Item."Production BOM No." <> '' then
            GetBOMItems(Item."Production BOM No.", ItemsToAnalyze);

        AddParentItems(ItemNo, ItemsToAnalyze);
    end;

    local procedure AddParentItems(ItemNo: Code[20]; var ItemsToAnalyze: List of [Code[20]])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ActiveVersion: Code[20];
    begin
        ProductionBOMLine.SetLoadFields("Production BOM No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        if ProductionBOMLine.FindSet() then
            repeat
                if ShouldTrackThisBom(ProductionBOMLine."Production BOM No.", ActiveVersion) then
                    AddItemsUsingThisBOM(ProductionBOMLine."Production BOM No.", ItemsToAnalyze);
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure AddItemsUsingThisBOM(BOMNo: Code[20]; var ItemsToAnalyze: List of [Code[20]])
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.");
        Item.SetRange("Production BOM No.", BOMNo);
        if Item.FindSet() then
            repeat
                AddItemToListFromBOM(Item."No.", ItemsToAnalyze);
            until Item.Next() = 0;
    end;

    local procedure ShouldTrackThisBom(BomNo: Code[20]; var ActiveVersion: Code[20]): Boolean
    var
        ProductionBOMHeader: Record "Production BOM Header";
        VersionManagement: Codeunit VersionManagement;
    begin
        ActiveVersion := VersionManagement.GetBOMVersion(BomNo, WorkDate(), true);
        ProductionBOMHeader.SetLoadFields(Status);
        ProductionBOMHeader.Get(BomNo);

        if ActiveVersion = '' then
            if ProductionBOMHeader.Status <> ProductionBOMHeader.Status::Certified then
                exit(false);

        exit(true);
    end;
}