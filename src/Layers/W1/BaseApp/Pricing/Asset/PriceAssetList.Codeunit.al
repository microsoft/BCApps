// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Pricing.Calculation;

codeunit 7007 "Price Asset List"
{
    var
        TempPriceAsset: Record "Price Asset" temporary;
        CurrentLevel: Integer;

    procedure Init()
    begin
        CurrentLevel := 0;
        TempPriceAsset.Reset();
        TempPriceAsset.DeleteAll();
    end;

    procedure Count(): Integer;
    begin
        TempPriceAsset.Reset();
        exit(TempPriceAsset.Count());
    end;

    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        TempPriceAssetLocal: Record "Price Asset" temporary;
    begin
        TempPriceAssetLocal.Copy(TempPriceAsset, true);
        TempPriceAssetLocal.Reset();
        if TempPriceAssetLocal.IsEmpty() then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        TempPriceAssetLocal.SetCurrentKey(Level);
        TempPriceAssetLocal.FindFirst();
        Level[1] := TempPriceAssetLocal.Level;
        TempPriceAssetLocal.FindLast();
        Level[2] := TempPriceAssetLocal.Level;
    end;

    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    procedure Add(AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    begin
        if AssetNo = '' then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset No.", AssetNo);
        if TempPriceAsset."Asset No." = '' then
            exit;
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(AssetType: Enum "Price Asset Type"; AssetId: Guid)
    begin
        if IsNullGuid(AssetId) then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset ID", AssetId);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(AssetType: Enum "Price Asset Type")
    begin
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Level := CurrentLevel;
        TempPriceAsset.TransferFields(PriceAsset);
        AppendRelatedAssets();
        InsertAsset();
    end;

    procedure Add(PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        TempPriceAsset.Level := CurrentLevel;
        TempPriceAsset.FillFromBuffer(PriceCalculationBuffer);
        AppendRelatedAssets();
        InsertAsset();
    end;

    local procedure AppendRelatedAssets()
    var
        PriceAssetList: Codeunit "Price Asset List";
    begin
        TempPriceAsset.PutRelatedAssetsToList(PriceAssetList);
        Append(PriceAssetList);
    end;

    local procedure InsertAsset()
    begin
        OnAddOnBeforeInsert(TempPriceAsset);
        TempPriceAsset.Insert(true);
    end;

    procedure GetValue(AssetType: Enum "Price Asset Type") Result: Code[20];
    var
        TempPriceAssetLocal: Record "Price Asset" temporary;
        PriceAssetInterface: Interface "Price Asset";
    begin
        TempPriceAssetLocal.Copy(TempPriceAsset, true);
        TempPriceAssetLocal.Reset();
        TempPriceAssetLocal.SetRange("Asset Type", AssetType);
        if TempPriceAssetLocal.FindFirst() then begin
            PriceAssetInterface := TempPriceAssetLocal."Asset Type";
            Result := TempPriceAssetLocal."Asset No.";
        end;
        OnAfterGetValue(AssetType, Result);
    end;

    procedure Copy(var FromPriceAssetList: Codeunit "Price Asset List")
    begin
        Init();
        FromPriceAssetList.GetList(TempPriceAsset);
    end;

    procedure Append(var FromPriceAssetList: Codeunit "Price Asset List")
    var
        TempPriceAssetFrom: Record "Price Asset" temporary;
        TempPriceAssetTo: Record "Price Asset" temporary;
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        TempPriceAssetTo.Copy(TempPriceAsset, true);
        FromPriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if FromPriceAssetList.First(TempPriceAssetFrom, CurrLevel) then
                repeat
                    TempPriceAssetTo.TransferFields(TempPriceAssetFrom, false);
                    TempPriceAssetTo.Insert(true);
                until not FromPriceAssetList.Next(TempPriceAssetFrom);
    end;

    procedure GetList(var ToTempPriceAsset: Record "Price Asset" temporary): Boolean
    begin
        if ToTempPriceAsset.IsTemporary then
            ToTempPriceAsset.Copy(TempPriceAsset, true);
        exit(ToTempPriceAsset.FindSet())
    end;

    procedure First(var PriceAsset: Record "Price Asset"; AtLevel: Integer): Boolean;
    begin
        TempPriceAsset.Reset();
        TempPriceAsset.SetCurrentKey(Level);
        TempPriceAsset.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceAsset.FindSet(), PriceAsset))
    end;

    procedure Next(var PriceAsset: Record "Price Asset"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceAsset.Next() > 0, PriceAsset))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceAsset: Record "Price Asset"): Boolean
    begin
        if Found then begin
            PriceAsset := TempPriceAsset;
            CurrentLevel := TempPriceAsset.Level;
        end else
            Clear(PriceAsset);
        exit(Found)
    end;

    procedure Remove(AssetType: Enum "Price Asset Type"): Boolean;
    var
        PriceAsset: Record "Price Asset";
    begin
        PriceAsset.SetRange("Asset Type", AssetType);
        exit(Remove(PriceAsset));
    end;

    procedure RemoveAtLevel(AssetType: Enum "Price Asset Type"; Level: Integer): Boolean;
    var
        PriceAsset: Record "Price Asset";
    begin
        PriceAsset.SetRange(Level, Level);
        PriceAsset.SetRange("Asset Type", AssetType);
        exit(Remove(PriceAsset));
    end;

    local procedure Remove(var PriceAsset: Record "Price Asset"): Boolean
    var
        TempPriceAssetLocal: Record "Price Asset" temporary;
    begin
        TempPriceAssetLocal.Copy(TempPriceAsset, true);
        TempPriceAssetLocal.CopyFilters(PriceAsset);
        if not TempPriceAssetLocal.IsEmpty() then begin
            TempPriceAssetLocal.DeleteAll();
            exit(true);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(AssetType: Enum "Price Asset Type"; var Result: Code[20])
    begin
    end;
}