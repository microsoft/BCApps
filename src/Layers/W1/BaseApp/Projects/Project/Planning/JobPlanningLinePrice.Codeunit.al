// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

codeunit 7024 "Job Planning Line - Price" implements "Line With Price"
{
    var
        JobPlanningLine: Record "Job Planning Line";
        PriceSourceList: Codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;
        DiscountIsAllowed: Boolean;
        IsSKU: Boolean;

    procedure GetTableNo(): Integer
    begin
        exit(Database::"Job Planning Line")
    end;

    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        ClearAll();
        JobPlanningLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        DiscountIsAllowed := true;
        if JobPlanningLine.Type = JobPlanningLine.Type::Item then
            IsSKU := StockkeepingUnit.Get(JobPlanningLine."Location Code", JobPlanningLine."No.", JobPlanningLine."Variant Code");
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
        Line := JobPlanningLine;
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
                            not (CalledByFieldNo in [JobPlanningLine.FieldNo(Quantity), JobPlanningLine.FieldNo("Location Code"), JobPlanningLine.FieldNo("Variant Code")]);
                    CurrPriceType::Purchase:
                        Result :=
                            Result or
                            not ((CalledByFieldNo = JobPlanningLine.FieldNo(Quantity)) or
                                ((CalledByFieldNo = JobPlanningLine.FieldNo("Variant Code")) and not IsSKU))
                end;
        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, JobPlanningLine, Result);
    end;

    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := DiscountIsAllowed or not PriceCalculated;
    end;

    procedure Verify()
    begin
        JobPlanningLine.TestField("Qty. per Unit of Measure");
        if JobPlanningLine."Currency Code" <> '' then
            JobPlanningLine.TestField("Currency Factor");
    end;

    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := JobPlanningLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := JobPlanningLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean;
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := JobPlanningLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case JobPlanningLine.Type of
            JobPlanningLine.Type::Item:
                AssetType := AssetType::Item;
            JobPlanningLine.Type::Resource:
                AssetType := AssetType::Resource;
            JobPlanningLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(JobPlanningLine, AssetType);
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
        PriceCalculationBuffer."Price Calculation Method" := JobPlanningLine."Price Calculation Method";
        PriceCalculationBuffer."Cost Calculation Method" := JobPlanningLine."Cost Calculation Method";
        PriceCalculationBuffer."Location Code" := JobPlanningLine."Location Code";
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                    PriceCalculationBuffer."Variant Code" := JobPlanningLine."Variant Code";
                    PriceCalculationBuffer."Is SKU" := IsSKU;
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                    PriceCalculationBuffer."Work Type Code" := JobPlanningLine."Work Type Code";
                end;
        end;
        PriceCalculationBuffer."Document Date" := JobPlanningLine."Planning Date";
        if PriceCalculationBuffer."Document Date" = 0D then
            PriceCalculationBuffer."Document Date" := WorkDate();
        PriceCalculationBuffer.Validate("Currency Code", JobPlanningLine."Currency Code");
        PriceCalculationBuffer."Currency Factor" := JobPlanningLine."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := false;
        // UoM
        PriceCalculationBuffer.Quantity := Abs(JobPlanningLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := false;
        OnAfterFillBuffer(PriceCalculationBuffer, JobPlanningLine);
    end;

    local procedure AddSources()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SourceType: Enum "Price Source Type";
    begin
        Job.Get(JobPlanningLine."Job No.");
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                begin
                    PriceSourceList.Add(SourceType::"All Customers");
                    if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then begin
                        PriceSourceList.Add(SourceType::Customer, Job."Bill-to Customer No.");
                        PriceSourceList.Add(SourceType::Contact, Job."Bill-to Contact No.");
                    end else begin
                        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                        PriceSourceList.Add(SourceType::Customer, JobTask."Bill-to Customer No.");
                        PriceSourceList.Add(SourceType::Contact, JobTask."Bill-to Contact No.");
                    end;
                    PriceSourceList.Add(SourceType::"Customer Price Group", JobPlanningLine."Customer Price Group");
                    PriceSourceList.Add(SourceType::"Customer Disc. Group", Job."Customer Disc. Group");
                end;
            CurrPriceType::Purchase:
                PriceSourceList.Add(SourceType::"All Vendors");
        end;
        PriceSourceList.AddJobAsSources(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        OnAfterAddSources(JobPlanningLine, CurrPriceType, PriceSourceList, Job)
    end;

    procedure SetPrice(AmountType: enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(JobPlanningLine, PriceListLine, AmountType, IsHandled, CurrPriceType);
        if IsHandled then
            exit;

        if AmountType = AmountType::Discount then
            JobPlanningLine."Line Discount %" := PriceListLine."Line Discount %"
        else
            case CurrPriceType of
                CurrPriceType::Sale:
                    begin
                        JobPlanningLine."Unit Price" := PriceListLine."Unit Price";
                        JobPlanningLine."Cost Factor" := PriceListLine."Cost Factor";
                        if PriceListLine.IsRealLine() then
                            DiscountIsAllowed := PriceListLine."Allow Line Disc.";
                        PriceCalculated := true;
                    end;
                CurrPriceType::Purchase:
                    case JobPlanningLine.Type of
                        JobPlanningLine.Type::Item:
                            JobPlanningLine."Direct Unit Cost (LCY)" := PriceListLine."Direct Unit Cost";
                        JobPlanningLine.Type::Resource:
                            begin
                                JobPlanningLine."Unit Cost" := PriceListLine."Unit Cost";
                                JobPlanningLine."Direct Unit Cost (LCY)" := PriceListLine."Direct Unit Cost";
                            end;
                        JobPlanningLine.Type::"G/L Account":
                            if PriceListLine."Unit Cost" <> 0 then
                                JobPlanningLine."Unit Cost" := PriceListLine."Unit Cost"
                            else
                                if PriceListLine."Direct Unit Cost" <> 0 then
                                    JobPlanningLine."Unit Cost" := PriceListLine."Direct Unit Cost";
                    end;
            end;
        OnAfterSetPrice(JobPlanningLine, PriceListLine, AmountType, CurrPriceType);
    end;

    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        if AmountType = AmountType::Discount then
            JobPlanningLine.Validate("Line Discount %")
        else
            case CurrPriceType of
                CurrPriceType::Sale:
                    JobPlanningLine.Validate("Unit Price");
                CurrPriceType::Purchase:
                    case JobPlanningLine.Type of
                        JobPlanningLine.Type::Item:
                            JobPlanningLine.Validate("Direct Unit Cost (LCY)");
                        JobPlanningLine.Type::Resource:
                            begin
                                JobPlanningLine.Validate("Direct Unit Cost (LCY)");
                                JobPlanningLine.Validate("Unit Cost (LCY)");
                            end;
                        JobPlanningLine.Type::"G/L Account":
                            JobPlanningLine.Validate("Unit Cost");
                    end;
            end;
    end;

    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not DiscountIsAllowed then
            JobPlanningLine."Line Discount %" := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(JobPlanningLine: Record "Job Planning Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; JobPlanningLine: Record "Job Planning Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var JobPlanningLine: Record "Job Planning Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; CurrPriceType: Enum "Price Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var JobPlanningLine: Record "Job Planning Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; CurrPriceType: Enum "Price Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(var JobPlanningLine: Record "Job Planning Line"; CurrPriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List"; Job: Record Job)
    begin
    end;
}
