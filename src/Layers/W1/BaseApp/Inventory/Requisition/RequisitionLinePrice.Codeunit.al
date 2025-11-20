// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

codeunit 7025 "Requisition Line - Price" implements "Line With Price"
{
    var
        RequisitionLine: Record "Requisition Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Requisition Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        RequisitionLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        if RequisitionLine.Type = RequisitionLine.Type::Item then
            IsSKU := StockkeepingUnit.Get(RequisitionLine."Location Code", RequisitionLine."No.", RequisitionLine."Variant Code");
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        Setline(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := RequisitionLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Clear(Header);
        GetLine(Line);
    end;

    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    procedure IsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if FoundPrice then
            Result := true
        else
            Result :=
                Result or
                not ((CalledByFieldNo = RequisitionLine.FieldNo(Quantity)) or
                    ((CalledByFieldNo = RequisitionLine.FieldNo("Variant Code")) and not IsSKU));
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, RequisitionLine, Result, IsSKU);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerify(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.TestField("Qty. per Unit of Measure");
        if RequisitionLine."Currency Code" <> '' then
            RequisitionLine.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := RequisitionLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := RequisitionLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := RequisitionLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case RequisitionLine.Type of
            RequisitionLine.Type::Item:
                AssetType := AssetType::Item;
            RequisitionLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(RequisitionLine, AssetType);
    end;

    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."): Boolean
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
    begin
        PriceCalculationBuffer.Init();
        if not SetAssetSource(PriceCalculationBuffer) then
            exit(false);

        FillBuffer(PriceCalculationBuffer);
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, PriceSourceList);
        exit(true);
    end;

    local procedure FillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer")
    var
        Item: Record Item;
    begin
        PriceCalculationBuffer."Price Calculation Method" := RequisitionLine."Price Calculation Method";
        PriceCalculationBuffer."Variant Code" := RequisitionLine."Variant Code";
        PriceCalculationBuffer."Location Code" := RequisitionLine."Location Code";
        PriceCalculationBuffer."Is SKU" := IsSKU;

        if PriceCalculationBuffer."Asset Type" = PriceCalculationBuffer."Asset Type"::Item then
            if not PriceCalculationBuffer."Is SKU" then begin
                Item.SetLoadFields("VAT Prod. Posting Group", "Last Direct Cost");
                Item.Get(PriceCalculationBuffer."Asset No.");
                PriceCalculationBuffer."Unit Price" := Item."Last Direct Cost";
                if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
            end;

        PriceCalculationBuffer."Document Date" := RequisitionLine."Order Date";
        if PriceCalculationBuffer."Document Date" = 0D then
            PriceCalculationBuffer."Document Date" := WorkDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", RequisitionLine."Currency Code");
        PriceCalculationBuffer."Currency Factor" := RequisitionLine."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(RequisitionLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := RequisitionLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := RequisitionLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
        OnAfterFillBuffer(PriceCalculationBuffer, RequisitionLine);
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        PriceSourceList.Add(SourceType::"All Vendors");
        if RequisitionLine."Vendor No." <> '' then
            PriceSourceList.Add(SourceType::Vendor, RequisitionLine."Vendor No.");

        OnAfterAddSources(RequisitionLine, CurrPriceType, PriceSourceList);
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(RequisitionLine, PriceListLine, AmountType, IsHandled, CurrPriceType);
        if IsHandled then
            exit;

        if AmountType = AmountType::Discount then
            RequisitionLine."Line Discount %" := PriceListLine."Line Discount %"
        else begin
            RequisitionLine."Direct Unit Cost" := PriceListLine."Direct Unit Cost";
            if PriceListLine.IsRealLine() then
                DiscountIsAllowed := PriceListLine."Allow Line Disc.";
            PriceCalculated := true;
        end;
        OnAfterSetPrice(RequisitionLine, PriceListLine, AmountType);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType = AmountType::Discount then
            RequisitionLine.Validate("Line Discount %")
        else
            RequisitionLine.Validate("Direct Unit Cost");
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not DiscountIsAllowed then
            RequisitionLine."Line Discount %" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(RequisitionLine: Record "Requisition Line"; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(RequisitionLine: Record "Requisition Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; RequisitionLine: Record "Requisition Line"; var Result: Boolean; IsSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var RequisitionLine: Record "Requisition Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerify(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var RequisitionLine: Record "Requisition Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; CurrPriceType: Enum "Price Type")
    begin
    end;
}
