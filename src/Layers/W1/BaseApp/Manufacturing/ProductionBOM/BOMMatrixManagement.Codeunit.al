// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;

codeunit 99000771 "BOM Matrix Management"
{
    Permissions = TableData Item = r,
                  TableData "Production BOM Header" = r,
                  TableData "Production BOM Version" = r,
                  TableData "Production Matrix BOM Line" = rimd,
                  TableData "Production Matrix  BOM Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        ItemAssembly: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProdBOMVersion2: Record "Production BOM Version";
        TempComponentList: Record "Production Matrix BOM Line" temporary;
        TempComponentEntry: Record "Production Matrix  BOM Entry" temporary;
        ComponentEntry2: Record "Production Matrix  BOM Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        GlobalCalcDate: Date;
        MatrixType: Option Version,Item;
        MultiLevel: Boolean;

    procedure FindRecord(Which: Text[30]; var ComponentList2: Record "Production Matrix BOM Line"): Boolean
    begin
        TempComponentList := ComponentList2;
        if not TempComponentList.Find(Which) then
            exit(false);
        ComponentList2 := TempComponentList;
        exit(true);
    end;

    procedure NextRecord(Steps: Integer; var ComponentList2: Record "Production Matrix BOM Line"): Integer
    var
        CurrentSteps: Integer;
    begin
        TempComponentList := ComponentList2;
        CurrentSteps := TempComponentList.Next(Steps);
        if CurrentSteps <> 0 then
            ComponentList2 := TempComponentList;
        exit(CurrentSteps);
    end;

    procedure GetComponentNeed(No: Code[20]; VariantCode: Code[10]; ID: Code[20]): Decimal
    begin
        TempComponentEntry.SetRange("Item No.", No);
        TempComponentEntry.SetRange("Variant Code", VariantCode);
        TempComponentEntry.SetRange(ID, ID);
        if not TempComponentEntry.FindFirst() then
            Clear(TempComponentEntry);

        exit(TempComponentEntry.Quantity);
    end;

    procedure CompareTwoItems(Item1: Record Item; Item2: Record Item; CalcDate: Date; NewMultiLevel: Boolean; var VersionCode1: Code[20]; var VersionCode2: Code[20]; var UnitOfMeasureCode1: Code[10]; var UnitOfMeasureCode2: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCompareTwoItems(Item1, Item2, CalcDate, NewMultiLevel, VersionCode1, VersionCode2, UnitOfMeasureCode1, UnitOfMeasureCode2, IsHandled);
        if IsHandled then
            exit;

        GlobalCalcDate := CalcDate;

        TempComponentList.DeleteAll();
        TempComponentEntry.Reset();
        TempComponentEntry.DeleteAll();

        MultiLevel := NewMultiLevel;
        MatrixType := MatrixType::Item;

        VersionCode1 :=
          VersionMgt.GetBOMVersion(
            Item1."Production BOM No.",
            GlobalCalcDate, false);
        UnitOfMeasureCode1 :=
          VersionMgt.GetBOMUnitOfMeasure(
            Item1."Production BOM No.", VersionCode1);

        ItemAssembly := Item1;
        BuildMatrix(
          Item1."Production BOM No.",
          VersionCode1, 1,
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item1, UnitOfMeasureCode1) /
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item1, Item1."Base Unit of Measure"));

        VersionCode2 :=
          VersionMgt.GetBOMVersion(
            Item2."Production BOM No.",
            GlobalCalcDate, false);
        UnitOfMeasureCode2 :=
          VersionMgt.GetBOMUnitOfMeasure(
            Item2."Production BOM No.", VersionCode2);

        ItemAssembly := Item2;
        BuildMatrix(
          Item2."Production BOM No.",
          VersionCode2, 1,
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item2, UnitOfMeasureCode2) /
          UOMMgt.GetQtyPerUnitOfMeasure(
            Item2, Item2."Base Unit of Measure"));
    end;

    procedure BOMMatrixFromBOM(ProductionBOMHeader: Record "Production BOM Header"; NewMultiLevel: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBOMMatrixFromBOM(ProductionBOMHeader, NewMultiLevel, IsHandled);
        if IsHandled then
            exit;

        TempComponentList.DeleteAll();
        TempComponentEntry.Reset();
        TempComponentEntry.DeleteAll();

        MultiLevel := NewMultiLevel;
        MatrixType := MatrixType::Version;
        BuildMatrix(ProductionBOMHeader."No.", '', 1, 1);
        ProdBOMVersion.SetRange("Production BOM No.", ProductionBOMHeader."No.");

        if ProdBOMVersion.Find('-') then
            repeat
                GlobalCalcDate := ProdBOMVersion."Starting Date";
                BuildMatrix(ProductionBOMHeader."No.", ProdBOMVersion."Version Code", 1, 1);
            until ProdBOMVersion.Next() = 0;
    end;

    local procedure BuildMatrix(ProductionBOMNo: Code[20]; VersionCode: Code[20]; Level: Integer; Quantity: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBuildMatrix(ProductionBOMNo, VersionCode, Level, Quantity, IsHandled);
        if IsHandled then
            exit;

        if Level > 20 then
            exit;

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        if GlobalCalcDate <> 0D then begin
            ProductionBOMLine.SetFilter("Starting Date", '%1|..%2', 0D, GlobalCalcDate);
            ProductionBOMLine.SetFilter("Ending Date", '%1|%2..', 0D, GlobalCalcDate);
        end;

        if ProductionBOMLine.Find('-') then
            repeat
                case ProductionBOMLine.Type of
                    ProductionBOMLine.Type::Item:
                        if Item.Get(ProductionBOMLine."No.") then begin
                            OnBuildMatrixForItemOnAfterGetItem(ProductionBOMLine);
                            if MultiLevel and (Item."Production BOM No." <> '') then begin
                                VersionCode :=
                                  VersionMgt.GetBOMVersion(Item."Production BOM No.", GlobalCalcDate, false);
                                OnBuildMatrixForItemOnBeforeRecursion(ProductionBOMLine);
                                BuildMatrix(
                                  Item."Production BOM No.", VersionCode, Level + 1,
                                  Quantity *
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, ProductionBOMLine."Unit of Measure Code") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(
                                    Item, VersionMgt.GetBOMUnitOfMeasure(Item."Production BOM No.", VersionCode)) *
                                  ProductionBOMLine.Quantity);
                            end else begin
                                TempComponentList."Item No." := ProductionBOMLine."No.";
                                TempComponentList."Variant Code" := ProductionBOMLine."Variant Code";
                                TempComponentList.Description := ProductionBOMLine.Description;
                                TempComponentList."Unit of Measure Code" := Item."Base Unit of Measure";
                                OnBuildMatrixForItemOnBeforeComponentListFind(ProductionBOMLine, TempComponentList);
                                if not TempComponentList.Find() then
                                    TempComponentList.Insert();
                                ComponentEntry2.Init();
                                ComponentEntry2."Item No." := ProductionBOMLine."No.";
                                ComponentEntry2."Variant Code" := ProductionBOMLine."Variant Code";
                                case MatrixType of
                                    MatrixType::Version:
                                        ComponentEntry2.ID := ProdBOMVersion."Version Code";
                                    MatrixType::Item:
                                        ComponentEntry2.ID := ItemAssembly."No.";
                                end;
                                ComponentEntry2.Quantity :=
                                  ProductionBOMLine.Quantity *
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, ProductionBOMLine."Unit of Measure Code") /
                                  UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure") *
                                  Quantity;
                                TempComponentEntry := ComponentEntry2;
                                TempComponentEntry.SetRange("Item No.", ComponentEntry2."Item No.");
                                TempComponentEntry.SetRange("Variant Code", ComponentEntry2."Variant Code");
                                TempComponentEntry.SetRange(ID, ComponentEntry2.ID);
                                if TempComponentEntry.FindFirst() then begin
                                    TempComponentEntry.Quantity :=
                                      TempComponentEntry.Quantity + ComponentEntry2.Quantity;
                                    TempComponentEntry.Modify();
                                end else
                                    TempComponentEntry.Insert();
                            end;
                        end;
                    ProductionBOMLine.Type::"Production BOM":
                        if ProdBOMHeader.Get(ProductionBOMLine."No.") then
                            BuildMatrix(
                                ProdBOMHeader."No.",
                                GetVersion(ProdBOMHeader."No."),
                                Level + 1,
                                Quantity * ProductionBOMLine.Quantity);
                end;
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure GetVersion(ProdBOMNo: Code[20]): Code[20]
    begin
        ProdBOMVersion2.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMVersion2.SetFilter("Starting Date", '%1|..%2', 0D, GlobalCalcDate);
        if ProdBOMVersion2.FindLast() then
            exit(ProdBOMVersion2."Version Code");

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnAfterGetItem(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnBeforeRecursion(var ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildMatrixForItemOnBeforeComponentListFind(var ProductionBOMLine: Record "Production BOM Line"; var ProductionMatrixBOMLine: Record "Production Matrix BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompareTwoItems(Item1: Record Item; Item2: Record Item; CalcDate: Date; NewMultiLevel: Boolean; var VersionCode1: Code[20]; var VersionCode2: Code[20]; var UnitOfMeasureCode1: Code[10]; var UnitOfMeasureCode2: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBOMMatrixFromBOM(ProductionBOMHeader: Record "Production BOM Header"; NewMultiLevel: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBuildMatrix(ProductionBOMNo: Code[20]; VersionCode: Code[20]; Level: Integer; Quantity: Decimal; var IsHandled: Boolean)
    begin
    end;
}

