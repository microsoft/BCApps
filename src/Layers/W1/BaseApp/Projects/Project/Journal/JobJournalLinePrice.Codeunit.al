// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

codeunit 7023 "Job Journal Line - Price" implements "Line With Price"
{
    var
        JobJournalLine: Record "Job Journal Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Job Journal Line");
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        JobJournalLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        if JobJournalLine.Type = JobJournalLine.Type::Item then
            IsSKU := StockkeepingUnit.Get(JobJournalLine."Location Code", JobJournalLine."No.", JobJournalLine."Variant Code");
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
        Line := JobJournalLine;
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
                            not (CalledByFieldNo in [JobJournalLine.FieldNo(Quantity), JobJournalLine.FieldNo("Variant Code")]);
                    CurrPriceType::Purchase:
                        Result :=
                            Result or
                            not ((CalledByFieldNo = JobJournalLine.FieldNo(Quantity)) or
                                ((CalledByFieldNo = JobJournalLine.FieldNo("Variant Code")) and not IsSKU))
                end;
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, JobJournalLine, Result);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        JobJournalLine.TestField("Qty. per Unit of Measure");
        if JobJournalLine."Currency Code" <> '' then
            JobJournalLine.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        case CurrPriceType of
            CurrPriceType::Sale:
                DtldPriceCalculationSetup.Method := JobJournalLine."Price Calculation Method";
            CurrPriceType::Purchase:
                DtldPriceCalculationSetup.Method := JobJournalLine."Cost Calculation Method";
        end;
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := JobJournalLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := JobJournalLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case JobJournalLine.Type of
            JobJournalLine.Type::Item:
                AssetType := AssetType::Item;
            JobJournalLine.Type::Resource:
                AssetType := AssetType::Resource;
            JobJournalLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(JobJournalLine, AssetType);
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
    begin
        PriceCalculationBuffer."Price Calculation Method" := JobJournalLine."Price Calculation Method";
        PriceCalculationBuffer."Cost Calculation Method" := JobJournalLine."Cost Calculation Method";
        PriceCalculationBuffer."Location Code" := JobJournalLine."Location Code";
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Variant Code" := JobJournalLine."Variant Code";
                    PriceCalculationBuffer."Is SKU" := IsSKU;
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Work Type Code" := JobJournalLine."Work Type Code";
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                end;
        end;
        if JobJournalLine."Time Sheet Date" <> 0D then
            PriceCalculationBuffer."Document Date" := JobJournalLine."Time Sheet Date"
        else
            PriceCalculationBuffer."Document Date" := JobJournalLine."Posting Date";
        if PriceCalculationBuffer."Document Date" = 0D then
            PriceCalculationBuffer."Document Date" := WorkDate();
        PriceCalculationBuffer.Validate("Currency Code", JobJournalLine."Currency Code");
        PriceCalculationBuffer."Currency Factor" := JobJournalLine."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(JobJournalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := JobJournalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := JobJournalLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
        OnAfterFillBuffer(PriceCalculationBuffer, JobJournalLine);
    end;

    local procedure AddSources()
    var
        Job: Record Job;
        SourceType: Enum "Price Source Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddSources(PriceSourceList, JobJournalLine, CurrPriceType, IsHandled);
        if IsHandled then
            exit;

        Job.Get(JobJournalLine."Job No.");
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                begin
                    PriceSourceList.Add(SourceType::"All Customers");
                    PriceSourceList.Add(SourceType::Customer, Job."Bill-to Customer No.");
                    PriceSourceList.Add(SourceType::Contact, Job."Bill-to Contact No.");
                    PriceSourceList.Add(SourceType::"Customer Price Group", JobJournalLine."Customer Price Group");
                    PriceSourceList.Add(SourceType::"Customer Disc. Group", Job."Customer Disc. Group");
                end;
            CurrPriceType::Purchase:
                PriceSourceList.Add(SourceType::"All Vendors");
        end;
        PriceSourceList.AddJobAsSources(JobJournalLine."Job No.", JobJournalLine."Job Task No.");
    end;

    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(JobJournalLine, PriceListLine, AmountType, IsHandled, CurrPriceType);
        if IsHandled then
            exit;

        if AmountType = AmountType::Discount then
            JobJournalLine."Line Discount %" := PriceListLine."Line Discount %"
        else
            case CurrPriceType of
                CurrPriceType::Sale:
                    begin
                        JobJournalLine."Unit Price" := PriceListLine."Unit Price";
                        JobJournalLine."Cost Factor" := PriceListLine."Cost Factor";
                        if PriceListLine.IsRealLine() then
                            DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                        PriceCalculated := true;
                    end;
                CurrPriceType::Purchase:
                    case JobJournalLine.Type of
                        JobJournalLine.Type::Item:
                            JobJournalLine."Direct Unit Cost (LCY)" := PriceListLine."Direct Unit Cost";
                        JobJournalLine.Type::Resource:
                            begin
                                JobJournalLine."Unit Cost" := PriceListLine."Unit Cost";
                                JobJournalLine."Direct Unit Cost (LCY)" := PriceListLine."Direct Unit Cost";
                            end;
                        JobJournalLine.Type::"G/L Account":
                            if PriceListLine."Unit Cost" <> 0 then
                                JobJournalLine."Unit Cost" := PriceListLine."Unit Cost"
                            else
                                JobJournalLine."Unit Cost" := PriceListLine."Direct Unit Cost";
                    end;
            end;
        OnAfterSetPrice(JobJournalLine, PriceListLine, AmountType);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType = AmountType::Discount then
            JobJournalLine.Validate("Line Discount %")
        else
            case CurrPriceType of
                CurrPriceType::Sale:
                    JobJournalLine.Validate("Unit Price");
                CurrPriceType::Purchase:
                    case JobJournalLine.Type of
                        JobJournalLine.Type::Item:
                            JobJournalLine.Validate("Direct Unit Cost (LCY)");
                        JobJournalLine.Type::Resource:
                            begin
                                JobJournalLine.Validate("Direct Unit Cost (LCY)");
                                JobJournalLine.Validate("Unit Cost (LCY)");
                            end;
                        JobJournalLine.Type::"G/L Account":
                            JobJournalLine.Validate("Unit Cost");
                    end;
            end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not DiscountIsAllowed then
            JobJournalLine."Line Discount %" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(JobJournalLine: Record "Job Journal Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; JobJournalLine: Record "Job Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var JobJournalLine: Record "Job Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSources(var PriceSourceList: Codeunit "Price Source List"; JobJournalLine: Record "Job Journal Line"; CurrPriceType: Enum "Price Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var JobJournalLine: Record "Job Journal Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; CurrPriceType: Enum "Price Type")
    begin
    end;
}
