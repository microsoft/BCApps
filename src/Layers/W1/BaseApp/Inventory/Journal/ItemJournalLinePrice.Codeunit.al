// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

codeunit 7022 "Item Journal Line - Price" implements "Line With Price"
{
    var
        ItemJournalLine: Record "Item Journal Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Item Journal Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        ItemJournalLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        IsSKU := StockkeepingUnit.Get(ItemJournalLine."Location Code", ItemJournalLine."No.", ItemJournalLine."Variant Code");
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
        Line := ItemJournalLine;
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
            if AmountType <> AmountType::Discount then
                case CurrPriceType of
                    CurrPriceType::Sale:
                        Result :=
                            Result or
                            not (CalledByFieldNo in [ItemJournalLine.FieldNo(Quantity), ItemJournalLine.FieldNo("Variant Code")]);
                    CurrPriceType::Purchase:
                        Result :=
                            Result or
                            not ((CalledByFieldNo = ItemJournalLine.FieldNo(Quantity)) or
                                ((CalledByFieldNo = ItemJournalLine.FieldNo("Variant Code")) and not IsSKU))
                end;
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, ItemJournalLine, Result);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        ItemJournalLine.TestField("Qty. per Unit of Measure");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := ItemJournalLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := ItemJournalLine."Item No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := ItemJournalLine."Item No.";
        exit(PriceCalculationBuffer."Asset No." <> '');
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        exit(AssetType::Item);
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
        PriceCalculationBuffer."Price Calculation Method" := ItemJournalLine."Price Calculation Method";
        Item.Get(PriceCalculationBuffer."Asset No.");
        PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        PriceCalculationBuffer."Variant Code" := ItemJournalLine."Variant Code";
        PriceCalculationBuffer."Location Code" := ItemJournalLine."Location Code";
        PriceCalculationBuffer."Is SKU" := IsSKU;
        PriceCalculationBuffer."Document Date" := GetDocumentDate();
        PriceCalculationBuffer.Validate("Currency Code", '');

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(ItemJournalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := ItemJournalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := ItemJournalLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
        OnAfterFillBuffer(PriceCalculationBuffer, ItemJournalLine);
    end;

    local procedure AddSources()
    var
        SourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                PriceSourceList.Add(SourceType::"All Customers");
            CurrPriceType::Purchase:
                PriceSourceList.Add(SourceType::"All Vendors");
        end;

        OnAfterAddSources(ItemJournalLine, CurrPriceType, PriceSourceList);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType <> AmountType::Discount then
            ItemJournalLine.Validate("Unit Amount");
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        DocumentDate := ItemJournalLine.GetDateForCalculations();
        OnAfterGetDocumentDate(DocumentDate, ItemJournalLine);
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(ItemJournalLine, PriceListLine, AmountType, IsHandled);
        if IsHandled then
            exit;

        if AmountType <> AmountType::Discount then
            case CurrPriceType of
                CurrPriceType::Sale:
                    begin
                        ItemJournalLine."Unit Amount" := PriceListLine."Unit Price";
                        if PriceListLine.IsRealLine() then
                            DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                        PriceCalculated := true;
                    end;
                CurrPriceType::Purchase:
                    ItemJournalLine."Unit Amount" := PriceListLine."Direct Unit Cost";
            end;
        OnAfterSetPrice(ItemJournalLine, PriceListLine, AmountType);
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(ItemJournalLine: Record "Item Journal Line"; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var ItemJournalLine: Record "Item Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var ItemJournalLine: Record "Item Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}
