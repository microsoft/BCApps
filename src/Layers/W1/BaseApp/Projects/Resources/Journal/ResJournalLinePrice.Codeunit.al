// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

codeunit 7028 "Res. Journal Line - Price" implements "Line With Price"
{
    var
        ResJournalLine: Record "Res. Journal Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        CostMethod: Enum "Price Calculation Method";
        PriceMethod: Enum "Price Calculation Method";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Res. Journal Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        Job: Record Job;
    begin
        ClearAll();
        ResJournalLine := Line;
        if ResJournalLine."Job No." <> '' then
            Job.Get(ResJournalLine."Job No.");
        PriceMethod := Job.GetPriceCalculationMethod();
        CostMethod := Job.GetCostCalculationMethod();
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := false;
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
        Line := ResJournalLine;
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

    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        Result := true
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        ResJournalLine.TestField("Qty. per Unit of Measure");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        case CurrPriceType of
            CurrPriceType::Sale:
                DtldPriceCalculationSetup.Method := PriceMethod;
            CurrPriceType::Purchase:
                DtldPriceCalculationSetup.Method := CostMethod;
        end;
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := ResJournalLine."Resource No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := ResJournalLine."Resource No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        exit(AssetType::Resource);
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
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Price Calculation Method" := PriceMethod;
        PriceCalculationBuffer."Cost Calculation Method" := CostMethod;
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                end;
        end;
        PriceCalculationBuffer."Work Type Code" := ResJournalLine."Work Type Code";
        if ResJournalLine."Time Sheet Date" <> 0D then
            PriceCalculationBuffer."Document Date" := ResJournalLine."Time Sheet Date"
        else
            PriceCalculationBuffer."Document Date" := ResJournalLine."Posting Date";
        if PriceCalculationBuffer."Document Date" = 0D then
            PriceCalculationBuffer."Document Date" := WorkDate();
        PriceCalculationBuffer.Validate("Currency Code", '');
        PriceCalculationBuffer."Currency Factor" := 1;

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(ResJournalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := ResJournalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := ResJournalLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
        OnAfterFillBuffer(PriceCalculationBuffer, ResJournalLine);
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
        PriceSourceList.AddJobAsSources(ResJournalLine."Job No.", '');
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(ResJournalLine, PriceListLine, AmountType, IsHandled, CurrPriceType);
        if IsHandled then
            exit;

        if AmountType <> AmountType::Discount then
            case CurrPriceType of
                CurrPriceType::Sale:
                    begin
                        ResJournalLine."Unit Price" := PriceListLine."Unit Price";
                        PriceCalculated := true;
                    end;
                CurrPriceType::Purchase:
                    begin
                        ResJournalLine."Direct Unit Cost" := PriceListLine."Direct Unit Cost";
                        ResJournalLine."Unit Cost" := PriceListLine."Unit Cost";
                    end;
            end;
        OnAfterSetPrice(ResJournalLine, PriceListLine, AmountType);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType <> AmountType::Discount then
            case CurrPriceType of
                CurrPriceType::Sale:
                    ResJournalLine.Validate("Unit Price");
                CurrPriceType::Purchase:
                    ResJournalLine.Validate("Unit Cost");
            end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var ResJournalLine: Record "Res. Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var ResJournalLine: Record "Res. Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; CurrPriceType: Enum "Price Type")
    begin
    end;
}
