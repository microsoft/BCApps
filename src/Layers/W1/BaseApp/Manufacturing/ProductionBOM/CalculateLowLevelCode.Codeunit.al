// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;

codeunit 99000793 "Calculate Low-Level Code"
{
    Permissions = TableData Item = rm,
                  TableData "Manufacturing Setup" = r;
    TableNo = Item;

    trigger OnRun()
    var
        ProdBOM: Record "Production BOM Header";
        Item2: Record Item;
    begin
        Item2.Copy(Rec);
        Item := Item2; // to store the last item- used in RecalcLowerLevels
        Item2."Low-Level Code" := CalcLevels(1, Item2."No.", 0, 0);
        if ProdBOM.Get(Item."Production BOM No.") then
            SetRecursiveLevelsOnBOM(ProdBOM, Item2."Low-Level Code" + 1, false);
        OnBeforeItemModify(Item2);
        Item2.Modify();
        Rec.Copy(Item2);
    end;

    var
        Item: Record Item;
        ActualProdBOM: Record "Production BOM Header";

#pragma warning disable AA0470
        ProdBomErr: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.';
#pragma warning restore AA0470

    procedure CalcLevels(Type: Option " ",Item,"Production BOM",Assembly; No: Code[20]; Level: Integer; LevelDepth: Integer) Result: Integer
    var
        Item2: Record Item;
        ProdBOMLine: Record "Production BOM Line";
        AsmBOMComp: Record "BOM Component";
        ActLevel: Integer;
        TotalLevels: Integer;
        CalculateDeeperLevel: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLevels(Type, No, Level, LevelDepth, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if LevelDepth > 50 then
            Error(ProdBomErr, 50, Item."No.", No, Level);

        TotalLevels := Level;

        case Type of
            Type::"Production BOM":
                begin
                    Item2.SetCurrentKey("Production BOM No.");
                    Item2.SetRange("Production BOM No.", No);
                    if Item2.FindSet() then
                        repeat
                            ActLevel := CalcLevels(Type::Item, Item2."No.", Level + 1, LevelDepth + 1);
                            if ActLevel > TotalLevels then
                                TotalLevels := ActLevel;
                        until Item2.Next() = 0;
                    OnCalcLevelsForProdBOM(Item2, No, Level, LevelDepth, TotalLevels);
                end;
            Type::Assembly:
                begin
                    Item2.Get(No);
                    ActLevel := CalcLevels(Type::Item, Item2."No.", Level + 1, LevelDepth + 1);
                    if ActLevel > TotalLevels then
                        TotalLevels := ActLevel;
                end;
            else
                Item2.Get(No);
        end;

        AsmBOMComp.SetCurrentKey(Type, "No.");
        AsmBOMComp.SetRange(Type, Type);
        AsmBOMComp.SetRange("No.", No);
        if AsmBOMComp.FindSet() then
            repeat
                ActLevel := CalcLevels(Type::Assembly, AsmBOMComp."Parent Item No.", Level, LevelDepth + 1);
                if ActLevel > TotalLevels then
                    TotalLevels := ActLevel;
            until AsmBOMComp.Next() = 0;

        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, Type);
        ProdBOMLine.SetRange("No.", No);
        if ProdBOMLine.FindSet() then
            repeat
                CalculateDeeperLevel := CalcDeeperLevel(ProdBOMLine, No, Level);
                if CalculateDeeperLevel then begin
                    ActLevel := CalcLevels(Type::"Production BOM", ProdBOMLine."Production BOM No.", Level, LevelDepth + 1);
                    if ActLevel > TotalLevels then
                        TotalLevels := ActLevel;
                end;
            until ProdBOMLine.Next() = 0;

        OnAfterCalcLevels(Type, No, TotalLevels, Level, LevelDepth);
        exit(TotalLevels);
    end;

    procedure RecalcLowerLevels(ProdBOMNo: Code[20]; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean)
    var
        CompItem: Record Item;
        CompBOM: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        EntityPresent: Boolean;
        CalculateDeeperLevel: Boolean;
    begin
        if LowLevelCode > 50 then
            Error(ProdBomErr, 50, Item."No.", ProdBOMNo, LowLevelCode);

        ProdBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine.SetFilter("No.", '<>%1', '');

        if ProdBOMLine.FindSet() then
            repeat
                if ProdBOMLine."Version Code" <> '' then begin
                    ProductionBOMVersion.Get(ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code");
                    CalculateDeeperLevel := ProductionBOMVersion.Status <> ProductionBOMVersion.Status::Closed;
                end else begin
                    CompBOM.Get(ProdBOMLine."Production BOM No.");
                    CalculateDeeperLevel := CompBOM.Status <> CompBOM.Status::Closed;
                end;

                // closed BOMs are skipped
                if CalculateDeeperLevel then
                    case ProdBOMLine.Type of
                        ProdBOMLine.Type::Item:
                            begin
                                EntityPresent := CompItem.Get(ProdBOMLine."No.");
                                if EntityPresent or (not IgnoreMissingItemsOrBOMs) then
                                    SetRecursiveLevelsOnItem(CompItem, LowLevelCode, IgnoreMissingItemsOrBOMs);
                            end;
                        ProdBOMLine.Type::"Production BOM":
                            begin
                                EntityPresent := CompBOM.Get(ProdBOMLine."No.");
                                if EntityPresent or (not IgnoreMissingItemsOrBOMs) then
                                    SetRecursiveLevelsOnBOM(CompBOM, LowLevelCode, IgnoreMissingItemsOrBOMs);
                            end
                    end;
            until ProdBOMLine.Next() = 0;
    end;

    procedure RecalcAsmLowerLevels(ParentItemNo: Code[20]; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean)
    var
        CompItem: Record Item;
        BOMComp: Record "BOM Component";
        EntityPresent: Boolean;
    begin
        if LowLevelCode > 50 then
            Error(ProdBomErr, 50, Item."No.", Item."No.", LowLevelCode);

        BOMComp.SetRange("Parent Item No.", ParentItemNo);
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetFilter("No.", '<>%1', '');
        if BOMComp.FindSet() then
            repeat
                EntityPresent := CompItem.Get(BOMComp."No.");
                if EntityPresent or not IgnoreMissingItemsOrBOMs then
                    SetRecursiveLevelsOnItem(CompItem, LowLevelCode, IgnoreMissingItemsOrBOMs);
            until BOMComp.Next() = 0;
    end;

    procedure SetRecursiveLevelsOnItem(var CompItem: Record Item; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean)
    var
        CompBOM: Record "Production BOM Header";
        xLowLevelCode: Integer;
        EntityPresent: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeSetRecursiveLevelsOnItem(CompItem, LowLevelCode, IgnoreMissingItemsOrBOMs, IsHandled);
        if IsHandled then
            exit;

        Item := CompItem; // to store the last item- used in RecalcLowerLevels
        xLowLevelCode := CompItem."Low-Level Code";
        CompItem."Low-Level Code" := GetMax(Item."Low-Level Code", LowLevelCode);
        if xLowLevelCode <> CompItem."Low-Level Code" then begin
            CompItem.CalcFields("Assembly BOM");
            if CompItem."Assembly BOM" then
                RecalcAsmLowerLevels(CompItem."No.", CompItem."Low-Level Code" + 1, IgnoreMissingItemsOrBOMs);
            if CompItem."Production BOM No." <> '' then begin
                // calc low level code for BOM set in the item
                EntityPresent := CompBOM.Get(CompItem."Production BOM No.");
                if EntityPresent or (not IgnoreMissingItemsOrBOMs) then
                    SetRecursiveLevelsOnBOM(CompBOM, CompItem."Low-Level Code" + 1, IgnoreMissingItemsOrBOMs);
            end;
            OnSetRecursiveLevelsOnItemOnBeforeCompItemModify(CompItem, IgnoreMissingItemsOrBOMs);
            CompItem.Modify();
        end;
    end;

    procedure SetRecursiveLevelsOnBOM(var CompBOM: Record "Production BOM Header"; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean)
    var
        xLowLevelCode: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetRecursiveLevelsOnBOM(CompBOM, LowLevelCode, IgnoreMissingItemsOrBOMs, IsHandled);
        if IsHandled then
            exit;

        xLowLevelCode := CompBOM."Low-Level Code";
        if CompBOM.Status = CompBOM.Status::Certified then begin
            // set low level on this BOM
            CompBOM."Low-Level Code" := GetMax(CompBOM."Low-Level Code", LowLevelCode);
            if xLowLevelCode <> CompBOM."Low-Level Code" then begin
                RecalcLowerLevels(CompBOM."No.", LowLevelCode, IgnoreMissingItemsOrBOMs);
                CompBOM.Modify();
            end;
        end;
    end;

    procedure GetMax(Level1: Integer; Level2: Integer) Result: Integer
    begin
        if Level1 > Level2 then
            Result := Level1
        else
            Result := Level2;
    end;

    procedure SetActualProdBOM(ActualProdBOM2: Record "Production BOM Header")
    begin
        ActualProdBOM := ActualProdBOM2;
    end;

    local procedure CalcDeeperLevel(ProdBOMLine: Record "Production BOM Line"; No: Code[20]; Level: Integer): Boolean
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProdBOMHeader.SetLoadFields(Status);
        if not ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") then
            exit(false);

        if ProdBOMLine."Version Code" <> '' then begin
            ProductionBOMVersion.SetLoadFields(Status);
            ProductionBOMVersion.Get(ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code");

            if ProductionBOMVersion.Status = ProductionBOMVersion.Status::Closed then
                exit(false);
        end;

        if ProdBOMHeader."No." = ActualProdBOM."No." then
            Error(ProdBomErr, 50, Item."No.", No, Level);

        if ProdBOMLine."Version Code" <> '' then
            exit(ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified)
        else
            exit(ProdBOMHeader.Status = ProdBOMHeader.Status::Certified);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLevels(Type: Option " ",Item,"Production BOM",Assembly; No: Code[20]; var TotalLevels: Integer; Level: Integer; LevelDepth: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLevels(Type: Option; No: Code[20]; Level: Integer; LevelDepth: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemModify(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRecursiveLevelsOnBOM(var ProductionBOMHeader: Record "Production BOM Header"; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLevelsForProdBOM(var Item: Record Item; No: Code[20]; Level: Integer; LevelDepth: Integer; var TotalLevels: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetRecursiveLevelsOnItemOnBeforeCompItemModify(var CompItem: Record Item; IgnoreMissingItemsOrBOMs: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRecursiveLevelsOnItem(var CompItem: Record Item; LowLevelCode: Integer; IgnoreMissingItemsOrBOMs: Boolean; var IsHandled: Boolean)
    begin
    end;
}

