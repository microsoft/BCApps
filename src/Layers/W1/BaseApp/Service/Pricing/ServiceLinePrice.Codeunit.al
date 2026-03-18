// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;

codeunit 7026 "Service Line - Price" implements "Line With Price"
{
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Service Line");
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        ServiceLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        AddSources();
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        ServiceHeader := Header;
        SetLine(PriceType, Line);
    end;

    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure GetLine(var Line: Variant)
    begin
        Line := ServiceLine;
    end;

    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := ServiceHeader;
        Line := ServiceLine;
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
                not (CalledByFieldNo in [ServiceLine.FieldNo(Quantity), ServiceLine.FieldNo("Variant Code")]);
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, ServiceLine, Result);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := ServiceLine."Allow Line Disc." or not PriceCalculated;
        OnAfterIsDiscountAllowed(ServiceLine, PriceCalculated, Result, ServiceHeader);
    end;

    procedure Verify()
    begin
        ServiceLine.TestField("Qty. per Unit of Measure");
        if ServiceHeader."Currency Code" <> '' then
            ServiceHeader.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := ServiceLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := ServiceLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := ServiceLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case ServiceLine.Type of
            ServiceLine.Type::Item:
                AssetType := AssetType::Item;
            ServiceLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            ServiceLine.Type::Resource:
                AssetType := AssetType::Resource;
            ServiceLine.Type::Cost:
                AssetType := AssetType::"Service Cost";
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(ServiceLine, AssetType);
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
        Resource: Record Resource;
        ServCost: Record "Service Cost";
    begin
        PriceCalculationBuffer."Price Calculation Method" := ServiceLine."Price Calculation Method";
        // Tax
        PriceCalculationBuffer."Prices Including Tax" := ServiceHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := ServiceLine.GetVATPct();
        PriceCalculationBuffer."VAT Calculation Type" := ServiceLine."VAT Calculation Type".AsInteger();
        PriceCalculationBuffer."VAT Bus. Posting Group" := ServiceLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := ServiceLine."VAT Prod. Posting Group";

        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    PriceCalculationBuffer."Variant Code" := ServiceLine."Variant Code";
                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Item."Unit Price";
                    PriceCalculationBuffer."Item Disc. Group" := Item."Item Disc. Group";
                    if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                        PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    PriceCalculationBuffer."Work Type Code" := ServiceLine."Work Type Code";
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Unit Price";
                    if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                        PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                end;
            PriceCalculationBuffer."Asset Type"::"Service Cost":
                begin
                    ServCost.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := ServCost."Default Unit Price";
                end;
        end;
        PriceCalculationBuffer."Location Code" := ServiceLine."Location Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", ServiceHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := ServiceHeader."Currency Factor";
        if (PriceCalculationBuffer."Price Type" = PriceCalculationBuffer."Price Type"::Purchase) and
           (PriceCalculationBuffer."Asset Type" = PriceCalculationBuffer."Asset Type"::Resource)
        then
            PriceCalculationBuffer."Calculation in LCY" := true;

        // UoM
        PriceCalculationBuffer.Quantity := Abs(ServiceLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := ServiceLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := ServiceLine."Allow Invoice Disc.";
        OnAfterFillBuffer(PriceCalculationBuffer, ServiceHeader, ServiceLine);
    end;

    local procedure AddSources()
    begin
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                AddCustomerSources();
            CurrPriceType::Purchase:
                PriceSourceList.Add("Price Source Type"::"All Vendors");
        end;
        PriceSourceList.AddJobAsSources(ServiceLine."Job No.", ServiceLine."Job Task No.");
        OnAfterAddSources(ServiceHeader, ServiceLine, CurrPriceType, PriceSourceList);
    end;

    local procedure AddCustomerSources()
    begin
        PriceSourceList.Add("Price Source Type"::"All Customers");
        PriceSourceList.Add("Price Source Type"::Customer, ServiceHeader."Bill-to Customer No.");
        PriceSourceList.Add("Price Source Type"::Contact, ServiceHeader."Bill-to Contact No.");
        PriceSourceList.Add("Price Source Type"::"Customer Price Group", ServiceLine."Customer Price Group");
        PriceSourceList.Add("Price Source Type"::"Customer Disc. Group", ServiceLine."Customer Disc. Group");
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        if ServiceHeader."No." = '' then
            DocumentDate := ServiceLine."Posting Date"
        else
            if ServiceHeader."Document Type" in
                [ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::"Credit Memo"]
            then
                DocumentDate := ServiceHeader."Posting Date"
            else
                DocumentDate := ServiceHeader."Order Date";
        if DocumentDate = 0D then
            DocumentDate := WorkDate();
        OnAfterGetDocumentDate(DocumentDate, ServiceHeader, ServiceLine);
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(ServiceLine, PriceListLine, AmountType, IsHandled, ServiceHeader, CurrPriceType);
        if IsHandled then
            exit;

        case AmountType of
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Sale:
                        begin
                            ServiceLine."Unit Price" := PriceListLine."Unit Price";
                            if PriceListLine.IsRealLine() then
                                ServiceLine."Allow Line Disc." := PriceListLine."Allow Line Disc.";
                            ServiceLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                            PriceCalculated := true;
                        end;
                    CurrPriceType::Purchase:
                        ServiceLine."Unit Cost (LCY)" := PriceListLine."Unit Cost";
                end;
            AmountType::Discount:
                case ServiceLine.Type of
                    ServiceLine.Type::Item, ServiceLine.Type::Resource, ServiceLine.Type::Cost:
                        ServiceLine."Line Discount %" := PriceListLine."Line Discount %";
                    ServiceLine.Type::"G/L Account":
                        begin
                            ServiceLine."Line Discount %" := 0;
                            ServiceLine."Line Discount Amount" := 0;
                            ServiceLine."Inv. Discount Amount" := 0;
                            ServiceLine."Inv. Disc. Amount to Invoice" := 0;
                        end;
                end;
        end;
        OnAfterSetPrice(ServiceLine, PriceListLine, AmountType, ServiceHeader);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                begin
                    ServiceLine.TestField("Allow Line Disc.");
                    ServiceLine.Validate("Line Discount %");
                end;
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Sale:
                        ServiceLine.Validate("Unit Price");
                    CurrPriceType::Purchase:
                        ServiceLine.Validate("Unit Cost (LCY)");
                end;
        end;

        OnAfterValidatePrice(ServiceLine, CurrPriceType, AmountType, ServiceHeader);
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not ServiceLine."Allow Line Disc." then
            ServiceLine."Line Discount %" := 0;

        OnAfterUpdate(ServiceLine, CurrPriceType, AmountType, ServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(
        ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line";
        PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(
        var PriceCalculationBuffer: Record "Price Calculation Buffer"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(ServiceLine: Record "Service Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; ServiceLine: Record "Service Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var ServiceLine: Record "Service Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var ServiceLine: Record "Service Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; var ServiceHeader: Record "Service Header"; CurrPriceType: Enum "Price Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePrice(var ServiceLine: Record "Service Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdate(var ServiceLine: Record "Service Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDiscountAllowed(ServiceLine: Record "Service Line"; PriceCalculated: Boolean; var Result: Boolean; var ServiceHeader: Record "Service Header")
    begin
    end;
}
