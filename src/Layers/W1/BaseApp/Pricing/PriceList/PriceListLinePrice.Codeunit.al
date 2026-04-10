// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.Source;

codeunit 7029 "Price List Line - Price" implements "Line With Price"
{
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceSourceList: codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Price List Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        PriceListLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        PriceListHeader := Header;
        SetLine(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := PriceListLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := PriceListHeader;
        Line := PriceListLine;
    end;

    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        Result := true
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := false;
    end;

    procedure Verify()
    begin
        PriceListLine.TestField("Asset Type");
        PriceListLine.TestField("Asset No.");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := DtldPriceCalculationSetup.Method::"Lowest Price";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := PriceListLine."Asset No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := PriceListLine."Asset No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        exit(PriceListLine."Asset Type");
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
    begin
        PriceCalculationBuffer."Price Calculation Method" :=
            PriceCalculationBuffer."Price Calculation Method"::"Lowest Price";
        PriceCalculationBuffer."Variant Code" := PriceListLine."Variant Code";
        PriceCalculationBuffer."Work Type Code" := PriceListLine."Work Type Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", PriceListLine."Currency Code");

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := PriceListLine."Price Includes VAT";

        // UoM
        PriceCalculationBuffer.Quantity := 1;
        PriceCalculationBuffer."Unit of Measure Code" := PriceListLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := 1;
        // Discounts
        PriceCalculationBuffer."Line Discount %" := PriceListLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
        OnAfterFillBuffer(PriceCalculationBuffer, PriceListHeader, PriceListLine);
    end;

    local procedure AddSources()
    begin
        PriceSourceList.Init();
        PriceSourceList.Add(PriceListLine."Source Type");
        OnAfterAddSources(PriceListHeader, PriceListLine, CurrPriceType, PriceSourceList);
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        DocumentDate := WorkDate();
        OnAfterGetDocumentDate(DocumentDate, PriceListLine);
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; FromPriceListLine: Record "Price List Line")
    begin
        PriceListLine := FromPriceListLine;
        OnAfterSetPrice(PriceListLine, FromPriceListLine, AmountType);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not PriceListLine."Allow Line Disc." then
            PriceListLine."Line Discount %" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(
        PriceListHeader: Record "Price List Header"; PriceListLine: Record "Price List Line";
        PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(
        var PriceCalculationBuffer: Record "Price Calculation Buffer"; PriceListHeader: Record "Price List Header"; PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var ToPriceListLine: Record "Price List Line"; FromPriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;
}