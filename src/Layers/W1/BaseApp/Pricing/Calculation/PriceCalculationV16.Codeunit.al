// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Foundation.Company;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;

codeunit 7002 "Price Calculation - V16" implements "Price Calculation"
{
    trigger OnRun()
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange(Implementation, PriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        PriceCalculationSetup.DeleteAll();
        AddSupportedSetup(PriceCalculationSetup);
        PriceCalculationSetup.ModifyAll(Default, true);
    end;

    var
        CurrPriceCalculationSetup: Record "Price Calculation Setup";
        CurrLineWithPrice: Interface "Line With Price";
        TempTableErr: Label 'The table passed as a parameter must be temporary.';
        PickedWrongMinQtyErr: Label 'The quantity in the line is below the minimum quantity of the picked price list line.';
        NoSpecificReadPermissionAccessErr: Label 'Sorry, the current permissions prevented the action. (TableData %1 Read: %2)', Comment = '%1 - TableData Name, %2 - App Name';

    procedure GetLine(var Line: Variant)
    begin
        CurrLineWithPrice.GetLine(Line);
    end;

    procedure Init(NewLineWithPrice: Interface "Line With Price"; PriceCalculationSetup: Record "Price Calculation Setup")
    begin
        CurrLineWithPrice := NewLineWithPrice;
        CurrPriceCalculationSetup := PriceCalculationSetup;
    end;

    procedure ApplyDiscount()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundPrice: Boolean;
    begin
        CheckSpecificReadPermissionAccess(CurrLineWithPrice.GetPriceType(), AmountType::Discount);
        if not CurrLineWithPrice.IsDiscountAllowed() then
            exit;
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        if FindLines(AmountType::Discount, TempPriceListLine, PriceCalculationBufferMgt, false) then
            FoundPrice := CalcBestAmount(AmountType::Discount, PriceCalculationBufferMgt, TempPriceListLine);
        if not FoundPrice then begin
            OnApplyDiscountOnBeforeFillBestLine(TempPriceListLine, PriceCalculationBufferMgt);
            PriceCalculationBufferMgt.FillBestLine(AmountType::Discount, TempPriceListLine);
        end;
        CurrLineWithPrice.SetPrice(AmountType::Discount, TempPriceListLine);
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer)
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        AmountType: Enum "Price Amount Type";
        FoundLines: Boolean;
        FoundPrice: Boolean;
    begin
        CheckSpecificReadPermissionAccess(CurrLineWithPrice.GetPriceType(), AmountType::Price);
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        FoundLines := FindLines(AmountType::Price, TempPriceListLine, PriceCalculationBufferMgt, false);
        if FoundLines then
            FoundPrice := CalcBestAmount(AmountType::Price, PriceCalculationBufferMgt, TempPriceListLine);
        if not FoundPrice then
            PriceCalculationBufferMgt.FillBestLine(AmountType::Price, TempPriceListLine);
        if CurrLineWithPrice.IsPriceUpdateNeeded(AmountType::Price, FoundLines, CalledByFieldNo) then
            CurrLineWithPrice.SetPrice(AmountType::Price, TempPriceListLine);
        CurrLineWithPrice.Update(AmountType::Price);
    end;

    procedure CountDiscount(ShowAll: Boolean) Result: Integer;
    var
        TempPriceListLine: Record "Price List Line" temporary;
        AmountType: Enum "Price Amount Type";
    begin
        if FindPriceLines(AmountType::Discount, ShowAll, TempPriceListLine) then
            Result := TempPriceListLine.Count()
    end;

    procedure CountPrice(ShowAll: Boolean) Result: Integer;
    var
        TempPriceListLine: Record "Price List Line" temporary;
        AmountType: Enum "Price Amount Type";
    begin
        if FindPriceLines(AmountType::Price, ShowAll, TempPriceListLine) then
            Result := TempPriceListLine.Count()
    end;

    local procedure FindPriceLines(AmountType: Enum "Price Amount Type"; ShowAll: Boolean; var TempPriceListLine: Record "Price List Line" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        if CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit(FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll));
    end;

    procedure FindDiscount(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        AmountType: Enum "Price Amount Type";
    begin
        Found := FindPriceLines(AmountType::Discount, ShowAll, TempPriceListLine);
    end;

    procedure FindPrice(var TempPriceListLine: Record "Price List Line"; ShowAll: Boolean) Found: Boolean;
    var
        AmountType: Enum "Price Amount Type";
    begin
        Found := FindPriceLines(AmountType::Price, ShowAll, TempPriceListLine);
    end;

    local procedure CheckSpecificReadPermissionAccess(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PurchaseDiscountAccess: Record "Purchase Discount Access";
        PurchasePriceAccess: Record "Purchase Price Access";
        SalesDiscountAccess: Record "Sales Discount Access";
        SalesPriceAccess: Record "Sales Price Access";
    begin
        case PriceType of
            "Price Type"::Purchase:
                case AmountType of
                    "Price Amount Type"::Discount:
                        if not PurchaseDiscountAccess.ReadPermission() then
                            Error(NoSpecificReadPermissionAccessErr, PurchaseDiscountAccess.TableCaption(), GetAppName());
                    "Price Amount Type"::Price:
                        if not PurchasePriceAccess.ReadPermission() then
                            Error(NoSpecificReadPermissionAccessErr, PurchasePriceAccess.TableCaption(), GetAppName());
                end;
            "Price Type"::Sale:
                case AmountType of
                    "Price Amount Type"::Discount:
                        if not SalesDiscountAccess.ReadPermission() then
                            Error(NoSpecificReadPermissionAccessErr, SalesDiscountAccess.TableCaption(), GetAppName());
                    "Price Amount Type"::Price:
                        if not SalesPriceAccess.ReadPermission() then
                            Error(NoSpecificReadPermissionAccessErr, SalesPriceAccess.TableCaption(), GetAppName());
                end;
        end;
    end;

    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;
    var
        TempPriceListLine: Record "Price List Line" temporary;
    begin
        Result := FindDiscount(TempPriceListLine, ShowAll);
    end;

    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;
    var
        TempPriceListLine: Record "Price List Line" temporary;
    begin
        Result := FindPrice(TempPriceListLine, ShowAll);
    end;

    procedure PickDiscount()
    var
        AmountType: enum "Price Amount Type";
    begin
        Pick(AmountType::Discount, true);
    end;

    procedure PickPrice()
    var
        AmountType: enum "Price Amount Type";
    begin
        Pick(AmountType::Price, true);
    end;

    local procedure Pick(AmountType: enum "Price Amount Type"; ShowAll: Boolean)
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceAssetList: Codeunit "Price Asset List";
        GetPriceLine: Page "Get Price Line";
    begin
        CheckSpecificReadPermissionAccess(CurrLineWithPrice.GetPriceType(), AmountType);
        CurrLineWithPrice.Verify();
        if not CurrLineWithPrice.CopyToBuffer(PriceCalculationBufferMgt) then
            exit;
        if FindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll) then begin
            PriceCalculationBufferMgt.GetAssets(PriceAssetList);
            GetPriceLine.SetDataCaptionExpr(PriceAssetList);
            GetPriceLine.SetForLookup(CurrLineWithPrice, AmountType, TempPriceListLine);
            if GetPriceLine.RunModal() = ACTION::LookupOK then begin
                GetPriceLine.GetRecord(TempPriceListLine);
                if not PriceCalculationBufferMgt.IsInMinQty(TempPriceListLine) then
                    Error(PickedWrongMinQtyErr);
                PriceCalculationBufferMgt.VerifySelectedLine(TempPriceListLine);
                PriceCalculationBufferMgt.ConvertAmount(AmountType, TempPriceListLine);
                CurrLineWithPrice.SetPrice(AmountType, TempPriceListLine);
                CurrLineWithPrice.Update(AmountType);
                CurrLineWithPrice.ValidatePrice(AmountType);
            end;
        end;
    end;

    procedure ShowPrices(var TempPriceListLine: Record "Price List Line")
    var
        GetPriceLine: Page "Get Price Line";
        AmountType: Enum "Price Amount Type";
    begin
        OnBeforeShowPrices(TempPriceListLine, CurrLineWithPrice);

        if not TempPriceListLine.IsEmpty() then begin
            GetPriceLine.SetForLookup(CurrLineWithPrice, AmountType::Price, TempPriceListLine);
            GetPriceLine.RunModal();
        end;
    end;

    local procedure AddSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        TempPriceCalculationSetup.Init();
        TempPriceCalculationSetup.Validate(Implementation, TempPriceCalculationSetup.Implementation::"Business Central (Version 16.0)");
        TempPriceCalculationSetup.Method := TempPriceCalculationSetup.Method::"Lowest Price";
        TempPriceCalculationSetup.Enabled := not IsDisabled();
        TempPriceCalculationSetup.Default := true;
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Purchase;
        TempPriceCalculationSetup.Insert(true);
        TempPriceCalculationSetup.Type := TempPriceCalculationSetup.Type::Sale;
        TempPriceCalculationSetup.Insert(true);
    end;

    local procedure IsDisabled() Result: Boolean;
    begin
        OnIsDisabled(Result);
    end;

    local procedure PickBestLine(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line"; var BestPriceListLine: Record "Price List Line"; var FoundBestLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickBestLine(AmountType, PriceListLine, BestPriceListLine, FoundBestLine, IsHandled);
        if IsHandled then
            exit;

        if IsImprovedLine(PriceListLine, BestPriceListLine) or not IsDegradedLine(PriceListLine, BestPriceListLine) then begin
            if IsImprovedLine(PriceListLine, BestPriceListLine) and not IsDegradedLine(PriceListLine, BestPriceListLine) then
                Clear(BestPriceListLine);
            if IsBetterLine(PriceListLine, AmountType, BestPriceListLine) then begin
                BestPriceListLine := PriceListLine;
                FoundBestLine := true;
            end;
        end;
        OnAfterPickBestLine(AmountType, PriceListLine, BestPriceListLine, FoundBestLine);
    end;

    procedure IsDegradedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line") Result: Boolean
    begin
        Result :=
            IsBlankedValue(PriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsBlankedValue(PriceListLine."Variant Code", BestPriceListLine."Variant Code");

        OnAfterIsDegradedLine(PriceListLine, BestPriceListLine, Result);
    end;

    local procedure IsBlankedValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue <> '') and (LineValue = ''));
    end;

    procedure IsImprovedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line") Result: Boolean
    begin
        Result :=
            IsSetValue(PriceListLine."Currency Code", BestPriceListLine."Currency Code") or
            IsSetValue(PriceListLine."Variant Code", BestPriceListLine."Variant Code");

        OnAfterIsImprovedLine(PriceListLine, BestPriceListLine, Result);
    end;

    local procedure IsSetValue(LineValue: Text; BestLineValue: Text): Boolean
    begin
        exit((BestLineValue = '') and (LineValue <> ''));
    end;

    procedure IsBetterLine(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; BestPriceListLine: Record "Price List Line") Result: Boolean;
    begin
        if AmountType = AmountType::Discount then
            Result := PriceListLine."Line Discount %" > BestPriceListLine."Line Discount %"
        else
            case PriceListLine."Price Type" of
                PriceListLine."Price Type"::Sale:
                    Result := IsBetterPrice(PriceListLine, PriceListLine."Unit Price", BestPriceListLine);
                PriceListLine."Price Type"::Purchase:
                    Result := IsBetterPrice(PriceListLine, PriceListLine."Direct Unit Cost", BestPriceListLine);
            end;
        OnAfterIsBetterLine(PriceListLine, AmountType, BestPriceListLine, Result);
    end;

    local procedure IsBetterPrice(var PriceListLine: Record "Price List Line"; Price: Decimal; BestPriceListLine: Record "Price List Line"): Boolean;
    begin
        PriceListLine."Line Amount" := Price * (1 - PriceListLine."Line Discount %" / 100);
        if not BestPriceListLine.IsRealLine() then
            exit(true);
        exit(PriceListLine."Line Amount" < BestPriceListLine."Line Amount");
    end;

    procedure FindLines(
        AmountType: Enum "Price Amount Type";
        var TempPriceListLine: Record "Price List Line" temporary;
        var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        ShowAll: Boolean) FoundLines: Boolean;
    var
        PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        PriceAssetList: Codeunit "Price Asset List";
        PriceSourceList: Codeunit "Price Source List";
        Level: array[2] of Integer;
        CurrLevel: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll, FoundLines, IsHandled);
        if IsHandled then
            exit(FoundLines);


        if not TempPriceListLine.IsTemporary() then
            Error(TempTableErr);

        TempPriceListLine.Reset();
        TempPriceListLine.DeleteAll();

        PriceCalculationBufferMgt.SetFiltersOnPriceListLine(PriceListLine, AmountType, ShowAll);
        PriceCalculationBufferMgt.GetAssets(PriceAssetList);
        PriceCalculationBufferMgt.GetSources(PriceSourceList);
        OnFindLinesOnBefoerPriceSourceListGetMinMaxLevel(PriceAssetList, PriceSourceList, AmountType, PriceCalculationBufferMgt, ShowAll);
        PriceSourceList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if PriceSourceList.First(PriceSource, CurrLevel) then
                    repeat
                        if PriceSource.IsForAmountType(AmountType) then begin
                            FoundLines :=
                                FoundLines or CopyLinesBySource(PriceListLine, PriceSource, PriceAssetList, TempPriceListLine);
                            PriceCalculationBufferMgt.RestoreFilters(PriceListLine);
                        end;
                    until not PriceSourceList.Next(PriceSource);

        FoundLines := not TempPriceListLine.IsEmpty();
        if not FoundLines then
            PriceCalculationBufferMgt.FillBestLine(AmountType, TempPriceListLine);

        OnAfterFindLines(AmountType, TempPriceListLine, PriceCalculationBufferMgt, ShowAll, FoundLines);
    end;

    procedure CopyLinesBySource(
        var PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        var PriceAssetList: Codeunit "Price Asset List";
        var TempPriceListLine: Record "Price List Line" temporary) FoundLines: Boolean;
    var
        PriceAsset: Record "Price Asset";
        Level: array[2] of Integer;
        CurrLevel: Integer;
    begin
        PriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if not FoundLines then
                if PriceAssetList.First(PriceAsset, CurrLevel) then
                    repeat
                        FoundLines :=
                            FoundLines or CopyLinesBySource(PriceListLine, PriceSource, PriceAsset, TempPriceListLine);
                    until not PriceAssetList.Next(PriceAsset);
    end;

    procedure CopyLinesBySource(
        var PriceListLine: Record "Price List Line";
        PriceSource: Record "Price Source";
        PriceAsset: Record "Price Asset";
        var TempPriceListLine: Record "Price List Line" temporary) FoundLines: Boolean;
    var
        PriceListLineFilters: Record "Price List Line";
    begin
        PriceListLineFilters.CopyFilters(PriceListLine);

        PriceSource.FilterPriceLines(PriceListLine);
        PriceAsset.FilterPriceLines(PriceListLine);
        FoundLines := PriceListLine.CopyFilteredLinesToTemporaryBuffer(TempPriceListLine);

        PriceListLine.Reset();
        PriceListLine.CopyFilters(PriceListLineFilters);
    end;

    procedure CalcBestAmount(AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; var PriceListLine: Record "Price List Line") FoundBestPrice: Boolean;
    var
        BestPriceListLine: Record "Price List Line";
    begin
        OnBeforeCalcBestAmount(AmountType, PriceCalculationBufferMgt, PriceListLine);
        PriceListLine.SetRange(Status, PriceListLine.Status::Active);
        if PriceListLine.FindSet() then
            repeat
                if PriceCalculationBufferMgt.IsInMinQty(PriceListLine) then begin
                    PriceCalculationBufferMgt.ConvertAmount(AmountType, PriceListLine);
                    PickBestLine(AmountType, PriceListLine, BestPriceListLine, FoundBestPrice);
                end;
            until PriceListLine.Next() = 0;
        if FoundBestPrice then
            PriceListLine := BestPriceListLine;

        OnAfterCalcBestAmount(AmountType, PriceCalculationBufferMgt, PriceListLine, FoundBestPrice);
    end;

    local procedure GetAppName(): Text
    var
        ModuleInfo: ModuleInfo;
    begin
        NAVApp.GetCurrentModuleInfo(ModuleInfo);
        exit(ModuleInfo.Name());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation Mgt.", 'OnFindSupportedSetup', '', false, false)]
    local procedure OnFindImplementationHandler(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
        AddSupportedSetup(TempPriceCalculationSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitializeHandler()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        // New company gets "Best Price" calculation by default.
        /*
        AddSupportedSetup(TempPriceCalculationSetup);
        PriceCalculationSetup.DeleteAll();
        if TempPriceCalculationSetup.FindSet() then
            repeat
                PriceCalculationSetup := TempPriceCalculationSetup;
                PriceCalculationSetup.Default := true;
                PriceCalculationSetup.Insert();
            until TempPriceCalculationSetup.Next() = 0;
        */
        PriceCalculationMgt.Run();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsBetterLine(PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsDegradedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsImprovedLine(PriceListLine: Record "Price List Line"; BestPriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickBestLine(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line"; var BestPriceListLine: Record "Price List Line"; var FoundBestLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLines(AmountType: Enum "Price Amount Type"; var TempPriceListLine: Record "Price List Line" temporary; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; ShowAll: Boolean; var FoundLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickBestLine(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line"; var BestPriceListLine: Record "Price List Line"; var FoundBestLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestAmount(AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsDisabled(var Disabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindLinesOnBefoerPriceSourceListGetMinMaxLevel(var PriceAssetList: Codeunit "Price Asset List"; var PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcBestAmount(AmountType: Enum "Price Amount Type"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; var PriceListLine: Record "Price List Line"; var FoundBestPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLines(AmountType: Enum "Price Amount Type"; var TempPriceListLine: Record "Price List Line" temporary; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; ShowAll: Boolean; var FoundLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPrices(var TempPriceListLine: Record "Price List Line"; LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyDiscountOnBeforeFillBestLine(var TempPriceListLine: Record "Price List Line" temporary; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.")
    begin
    end;
}
