// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;

codeunit 7021 "Purchase Line - Price" implements "Line With Price"
{
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Purchase Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        PurchaseLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        IsSKU := StockkeepingUnit.Get(PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine."Variant Code");
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        PurchaseHeader := Header;
        SetLine(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure SetPurchaseQtyInvoice(ErrorInfo: ErrorInfo)
    var
        CurrPurchaseLine: Record "Purchase Line";
    begin
        CurrPurchaseLine.Get(ErrorInfo.RecordId);
        CurrPurchaseLine.Validate("Qty. to Invoice", CurrPurchaseLine.MaxQtyToInvoice());
        CurrPurchaseLine.Modify(true);
    end;

    procedure SetPurchaseReceiveQty(ErrorInfo: ErrorInfo)
    var
        CurrPurchaseLine: Record "Purchase Line";
    begin
        CurrPurchaseLine.Get(ErrorInfo.RecordId);
        CurrPurchaseLine.Validate("Qty. to Receive", CurrPurchaseLine."Outstanding Quantity");
        CurrPurchaseLine.Modify(true);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := PurchaseLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := PurchaseHeader;
        Line := PurchaseLine;
    end;

    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    procedure IsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if PurchaseLine."Prepmt. Amt. Inv." <> 0 then
            Result := false
        else
            if FoundPrice then
                Result := true
            else
                Result :=
                    Result or
                    not ((CalledByFieldNo = PurchaseLine.FieldNo("Job No.")) or (CalledByFieldNo = PurchaseLine.FieldNo("Job Task No.")) or
                         (CalledByFieldNo = PurchaseLine.FieldNo(Quantity)) or
                        ((CalledByFieldNo = PurchaseLine.FieldNo("Variant Code")) and not IsSKU));
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, PurchaseLine, Result, IsSKU);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
        OnAfterIsDiscountAllowed(PurchaseLine, PriceCalculated, Result);
    end;

    procedure Verify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerify(PurchaseHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if not PurchaseLine.IsProdOrder() then
            PurchaseLine.TestField("Qty. per Unit of Measure");

        if PurchaseHeader."Currency Code" <> '' then
            PurchaseHeader.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := PurchaseLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := PurchaseLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := PurchaseLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case PurchaseLine.Type of
            PurchaseLine.Type::Item:
                AssetType := AssetType::Item;
            PurchaseLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            PurchaseLine.Type::Resource:
                AssetType := AssetType::Resource;
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(PurchaseLine, AssetType);
    end;

    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."): Boolean
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
    begin
        OnBeforeCopyToBuffer(PurchaseHeader, PurchaseLine);

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
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Price Calculation Method" := PurchaseLine."Price Calculation Method";
        // Tax
        PriceCalculationBuffer."Prices Including Tax" := PurchaseHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := PurchaseLine.GetVATPct();
        PriceCalculationBuffer."VAT Calculation Type" := PurchaseLine."VAT Calculation Type".AsInteger();
        PriceCalculationBuffer."VAT Bus. Posting Group" := PurchaseLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";

        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    PriceCalculationBuffer."Variant Code" := PurchaseLine."Variant Code";
                    PriceCalculationBuffer."Is SKU" := IsSKU;
                    if PriceCalculationBuffer."Is SKU" then
                        PriceCalculationBuffer."Unit Price" := StockkeepingUnit."Last Direct Cost"
                    else begin
                        Item.Get(PriceCalculationBuffer."Asset No.");
                        PriceCalculationBuffer."Unit Price" := Item."Last Direct Cost";
                        if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                            PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                    end;
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Direct Unit Cost";
                    if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                        PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                end;
        end;
        PriceCalculationBuffer."Location Code" := PurchaseLine."Location Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", PurchaseHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := PurchaseHeader."Currency Factor";

        // UoM
        PriceCalculationBuffer.Quantity := Abs(PurchaseLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := PurchaseLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := PurchaseLine."Allow Invoice Disc.";
        OnAfterFillBuffer(PriceCalculationBuffer, PurchaseHeader, PurchaseLine);
    end;

    local procedure AddSources()
    begin
        PriceSourceList.Init();
        AddVendorSources();
        PriceSourceList.AddJobAsSources(PurchaseLine."Job No.", PurchaseLine."Job Task No.");
        OnAfterAddSources(PurchaseHeader, PurchaseLine, CurrPriceType, PriceSourceList);
    end;

    local procedure AddVendorSources()
    begin
        PriceSourceList.Add("Price Source Type"::"All Vendors");
        PriceSourceList.Add("Price Source Type"::Vendor, PurchaseHeader."Buy-from Vendor No.");
        PriceSourceList.Add("Price Source Type"::Contact, PurchaseHeader."Buy-from Contact No.");
        PriceSourceList.Add("Price Source Type"::Campaign, PurchaseHeader."Campaign No.");
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        DocumentDate := PurchaseLine.GetDateForCalculations(PurchaseHeader);
        OnAfterGetDocumentDate(DocumentDate, PurchaseHeader, PurchaseLine);
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(PurchaseLine, PriceListLine, AmountType, IsHandled, CurrPriceType, PurchaseHeader);
        if IsHandled then
            exit;

        case AmountType of
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Purchase:
                        begin
                            PurchaseLine."Direct Unit Cost" := PriceListLine."Direct Unit Cost";
                            PurchaseLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                            if PriceListLine.IsRealLine() then
                                DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                            PriceCalculated := true;
                        end;
                end;
            AmountType::Discount:
                PurchaseLine."Line Discount %" := PriceListLine."Line Discount %"
        end;

        OnAfterSetPrice(PurchaseLine, PriceListLine, AmountType, CurrPriceType, PurchaseHeader);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType = AmountType::Discount then
            PurchaseLine.Validate("Line Discount %")
        else
            PurchaseLine.Validate("Direct Unit Cost");

        OnAfterValidatePrice(PurchaseLine, CurrPriceType, AmountType, PurchaseHeader);
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not DiscountIsAllowed then
            PurchaseLine."Line Discount %" := 0;

        OnAfterUpdate(PurchaseLine, CurrPriceType, AmountType, PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(
        PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line";
        PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(
        var PriceCalculationBuffer: Record "Price Calculation Buffer"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDiscountAllowed(PurchaseLine: Record "Purchase Line"; PriceCalculated: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(PurchaseLine: Record "Purchase Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; PurchaseLine: Record "Purchase Line"; var Result: Boolean; IsSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var PurchaseLine: Record "Purchase Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; CurrPriceType: Enum "Price Type"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdate(var PurchaseLine: Record "Purchase Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePrice(var PurchaseLine: Record "Purchase Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerify(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var PurchaseLine: Record "Purchase Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; CurrPriceType: Enum "Price Type"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyToBuffer(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}
