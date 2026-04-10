// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;

/// <summary>
/// Implements price calculation logic for sales lines, handling price sources, discounts, and campaign pricing.
/// </summary>
codeunit 7020 "Sales Line - Price" implements "Line With Price"
{
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceSourceList: codeunit "Price Source List";
        CurrPriceType: Enum "Price Type";
        PriceCalculated: Boolean;

    /// <summary>
    /// Returns the database table number for the Sales Line table.
    /// </summary>
    /// <returns>The table number of the Sales Line table.</returns>
    procedure GetTableNo(): Integer
    begin
        exit(Database::"Sales Line")
    end;

    /// <summary>
    /// Sets the sales line and price type for price calculation, initializing the price sources.
    /// </summary>
    /// <param name="PriceType">Specifies the type of price calculation (Sale or Purchase).</param>
    /// <param name="Line">Specifies the sales line record to set.</param>
    procedure SetLine(PriceType: Enum "Price Type"; Line: Variant)
    begin
        SalesLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        AddSources();
    end;

    /// <summary>
    /// Sets the sales header, sales line, and price type for price calculation, clearing existing data and initializing price sources.
    /// </summary>
    /// <param name="PriceType">Specifies the type of price calculation (Sale or Purchase).</param>
    /// <param name="Header">Specifies the sales header record to set.</param>
    /// <param name="Line">Specifies the sales line record to set.</param>
    procedure SetLine(PriceType: Enum "Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        SalesHeader := Header;
        SetLine(PriceType, Line);
    end;

    /// <summary>
    /// Copies the specified price source list to the internal price source list.
    /// </summary>
    /// <param name="NewPriceSourceList">Specifies the price source list to copy from.</param>
    procedure SetSources(var NewPriceSourceList: codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    /// <summary>
    /// Retrieves the current sales line record.
    /// </summary>
    /// <param name="Line">Returns the sales line record.</param>
    procedure GetLine(var Line: Variant)
    begin
        Line := SalesLine;
    end;

    /// <summary>
    /// Retrieves the current sales header and sales line records.
    /// </summary>
    /// <param name="Header">Returns the sales header record.</param>
    /// <param name="Line">Returns the sales line record.</param>
    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := SalesHeader;
        Line := SalesLine;
    end;

    /// <summary>
    /// Returns the current price type used for price calculation.
    /// </summary>
    /// <returns>The current price type (Sale or Purchase).</returns>
    procedure GetPriceType(): Enum "Price Type"
    begin
        exit(CurrPriceType);
    end;

    /// <summary>
    /// Determines whether a price update is needed based on the amount type, whether a price was found, and the field that triggered the calculation.
    /// </summary>
    /// <param name="AmountType">Specifies the type of amount (Price or Discount).</param>
    /// <param name="FoundPrice">Specifies whether a price was found during calculation.</param>
    /// <param name="CalledByFieldNo">Specifies the field number that triggered the price calculation.</param>
    /// <returns>True if the price needs to be updated; otherwise, false.</returns>
    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if FoundPrice then
            Result := true
        else
            Result :=
                Result or
                not (CalledByFieldNo in [SalesLine.FieldNo(Quantity), SalesLine.FieldNo("Variant Code")]);

        OnAfterIsPriceUpdateNeeded(AmountType, FoundPrice, CalledByFieldNo, Result, SalesLine);
    end;

    /// <summary>
    /// Determines whether a line discount is allowed for the sales line based on the line settings and whether a price has been calculated.
    /// </summary>
    /// <returns>True if a line discount is allowed; otherwise, false.</returns>
    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := SalesLine."Allow Line Disc." or not PriceCalculated;
        OnAfterIsDiscountAllowed(SalesLine, PriceCalculated, Result, SalesHeader);
    end;

    /// <summary>
    /// Verifies that the sales line has valid data for price calculation, including quantity per unit of measure and currency factor.
    /// </summary>
    procedure Verify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerify(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField("Qty. per Unit of Measure");
        if SalesHeader."Currency Code" <> '' then
            SalesHeader.TestField("Currency Factor");
    end;

    /// <summary>
    /// Initializes the detailed price calculation setup record with asset information from the sales line.
    /// </summary>
    /// <param name="DtldPriceCalculationSetup">Returns the initialized detailed price calculation setup record.</param>
    /// <returns>True if a source group was found for the setup; otherwise, false.</returns>
    procedure SetAssetSourceForSetup(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup"): Boolean
    begin
        DtldPriceCalculationSetup.Init();
        DtldPriceCalculationSetup.Type := CurrPriceType;
        DtldPriceCalculationSetup.Method := SalesLine."Price Calculation Method";
        DtldPriceCalculationSetup."Asset Type" := GetAssetType();
        DtldPriceCalculationSetup."Asset No." := SalesLine."No.";
        exit(PriceSourceList.GetSourceGroup(DtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var PriceCalculationBuffer: Record "Price Calculation Buffer"): Boolean
    begin
        PriceCalculationBuffer."Price Type" := CurrPriceType;
        PriceCalculationBuffer."Asset Type" := GetAssetType();
        PriceCalculationBuffer."Asset No." := SalesLine."No.";
        exit((PriceCalculationBuffer."Asset Type" <> PriceCalculationBuffer."Asset Type"::" ") and (PriceCalculationBuffer."Asset No." <> ''));
    end;

    /// <summary>
    /// Determines the price asset type based on the sales line type (Item, Resource, or G/L Account).
    /// </summary>
    /// <returns>The price asset type corresponding to the sales line type.</returns>
    procedure GetAssetType() AssetType: Enum "Price Asset Type";
    begin
        case SalesLine.Type of
            SalesLine.Type::Item:
                AssetType := AssetType::Item;
            SalesLine.Type::Resource:
                AssetType := AssetType::Resource;
            SalesLine.Type::"G/L Account":
                AssetType := AssetType::"G/L Account";
            else
                AssetType := AssetType::" ";
        end;
        OnAfterGetAssetType(SalesLine, AssetType);
    end;

    /// <summary>
    /// Copies the sales line data to the price calculation buffer for price calculation processing.
    /// </summary>
    /// <param name="PriceCalculationBufferMgt">Specifies the price calculation buffer management codeunit to populate.</param>
    /// <returns>True if the data was successfully copied to the buffer; otherwise, false.</returns>
    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."): Boolean
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
    begin
        PriceCalculationBuffer.Init();
        if not SetAssetSource(PriceCalculationBuffer) then
            exit(false);

        FillBuffer(PriceCalculationBuffer);
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, PriceSourceList);
        OnCopyToBufferOnAfterPriceCalculationBufferMgtSet(PriceCalculationBufferMgt, PriceCalculationBuffer, PriceSourceList);
        exit(true);
    end;

    local procedure FillBuffer(var PriceCalculationBuffer: Record "Price Calculation Buffer")
    var
        Item: Record Item;
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Price Calculation Method" := SalesLine."Price Calculation Method";
        // Tax
        PriceCalculationBuffer."Prices Including Tax" := SalesHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := SalesLine.GetVATPct();
        PriceCalculationBuffer."VAT Calculation Type" := SalesLine."VAT Calculation Type".AsInteger();
        PriceCalculationBuffer."VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";

        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::Item:
                begin
                    PriceCalculationBuffer."Variant Code" := SalesLine."Variant Code";
                    Item.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Item."Unit Price";
                    PriceCalculationBuffer."Item Disc. Group" := Item."Item Disc. Group";
                    if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                        PriceCalculationBuffer."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    PriceCalculationBuffer."Work Type Code" := SalesLine."Work Type Code";
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Unit Price";
                    if PriceCalculationBuffer."VAT Prod. Posting Group" = '' then
                        PriceCalculationBuffer."VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
                end;
        end;
        PriceCalculationBuffer."Location Code" := SalesLine."Location Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", SalesHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := SalesHeader."Currency Factor";
        if (PriceCalculationBuffer."Price Type" = PriceCalculationBuffer."Price Type"::Purchase) and
           (PriceCalculationBuffer."Asset Type" = PriceCalculationBuffer."Asset Type"::Resource)
        then
            PriceCalculationBuffer."Calculation in LCY" := true;

        // UoM
        PriceCalculationBuffer.Quantity := Abs(SalesLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := SalesLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := SalesLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := SalesLine."Allow Invoice Disc.";
        OnAfterFillBuffer(PriceCalculationBuffer, SalesHeader, SalesLine);
    end;

    local procedure AddSources()
    begin
        PriceSourceList.Init();
        case CurrPriceType of
            CurrPriceType::Sale:
                AddCustomerSources();
            CurrPriceType::Purchase:
                PriceSourceList.Add(Enum::"Price Source Type"::"All Vendors");
        end;
        if SalesLine."Document Type" = SalesLine."Document Type"::Invoice then
            PriceSourceList.AddJobAsSources(SalesLine."Job No.", SalesLine."Job Task No.");
        OnAfterAddSources(SalesHeader, SalesLine, CurrPriceType, PriceSourceList);
    end;

    local procedure AddCustomerSources()
    begin
        PriceSourceList.Add(Enum::"Price Source Type"::"All Customers");
        PriceSourceList.Add(Enum::"Price Source Type"::Customer, SalesHeader."Bill-to Customer No.");
        PriceSourceList.Add(Enum::"Price Source Type"::Contact, SalesHeader."Bill-to Contact No.");
        PriceSourceList.Add(Enum::"Price Source Type"::Campaign, SalesHeader."Campaign No.");
        AddActivatedCampaignsAsSource();
        PriceSourceList.Add(Enum::"Price Source Type"::"Customer Price Group", SalesLine."Customer Price Group");
        PriceSourceList.Add(Enum::"Price Source Type"::"Customer Disc. Group", SalesLine."Customer Disc. Group");
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        DocumentDate := SalesLine.GetDateForCalculations(SalesHeader);
        OnAfterGetDocumentDate(DocumentDate, SalesHeader, SalesLine);
    end;

    /// <summary>
    /// Applies the price or discount from the price list line to the sales line based on the amount type and price type.
    /// </summary>
    /// <param name="AmountType">Specifies whether to apply a price or discount.</param>
    /// <param name="PriceListLine">Specifies the price list line containing the price or discount to apply.</param>
    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPrice(SalesLine, PriceListLine, AmountType, IsHandled, SalesHeader, CurrPriceType);
        if IsHandled then
            exit;

        case AmountType of
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Sale:
                        begin
                            SalesLine."Unit Price" := PriceListLine."Unit Price";
                            if PriceListLine.IsRealLine() then
                                SalesLine."Allow Line Disc." := PriceListLine."Allow Line Disc.";
                            SalesLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                            PriceCalculated := true;
                        end;
                    CurrPriceType::Purchase:
                        SalesLine."Unit Cost (LCY)" := PriceListLine."Unit Cost";
                end;
            AmountType::Discount:
                SalesLine."Line Discount %" := PriceListLine."Line Discount %";
        end;
        OnAfterSetPrice(SalesLine, PriceListLine, AmountType, SalesHeader);
    end;

    /// <summary>
    /// Validates the price or discount on the sales line after it has been set, triggering field validation logic.
    /// </summary>
    /// <param name="AmountType">Specifies whether to validate a price or discount.</param>
    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                begin
                    SalesLine.TestField("Allow Line Disc.");
                    SalesLine.Validate("Line Discount %");
                end;
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Sale:
                        SalesLine.Validate("Unit Price");
                    CurrPriceType::Purchase:
                        SalesLine.Validate("Unit Cost (LCY)");
                end;
        end;

        OnAfterValidatePrice(SalesLine, CurrPriceType, AmountType, SalesHeader);
    end;

    /// <summary>
    /// Updates the sales line after price calculation, clearing the line discount if not allowed.
    /// </summary>
    /// <param name="AmountType">Specifies the type of amount that was updated (Price or Discount).</param>
    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not SalesLine."Allow Line Disc." then
            SalesLine."Line Discount %" := 0;

        OnAfterUpdate(SalesLine, CurrPriceType, AmountType, SalesHeader);
    end;

    /// <summary>
    /// Adds all activated campaigns associated with the customer or contact as price sources.
    /// </summary>
    procedure AddActivatedCampaignsAsSource()
    var
        TempTargetCampaignGr: Record "Campaign Target Group" temporary;
        SourceType: Enum "Price Source Type";
    begin
        if FindActivatedCampaign(TempTargetCampaignGr) then
            repeat
                PriceSourceList.Add(SourceType::Campaign, TempTargetCampaignGr."Campaign No.");
            until TempTargetCampaignGr.Next() = 0;
    end;

    local procedure FindActivatedCampaign(var TempCampaignTargetGr: Record "Campaign Target Group" temporary): Boolean
    var
        PriceSourceType: enum "Price Source Type";
    begin
        TempCampaignTargetGr.Reset();
        TempCampaignTargetGr.DeleteAll();

        if PriceSourceList.GetValue(PriceSourceType::Campaign) = '' then
            if not FindCustomerCampaigns(PriceSourceList.GetValue(PriceSourceType::Customer), TempCampaignTargetGr) then
                FindContactCompanyCampaigns(PriceSourceList.GetValue(PriceSourceType::Contact), TempCampaignTargetGr);

        exit(TempCampaignTargetGr.FindFirst());
    end;

    local procedure FindCustomerCampaigns(CustomerNo: Code[20]; var TempCampaignTargetGr: Record "Campaign Target Group" temporary) Found: Boolean;
    var
        CampaignTargetGr: Record "Campaign Target Group";
    begin
        CampaignTargetGr.SetRange(Type, CampaignTargetGr.Type::Customer);
        CampaignTargetGr.SetRange("No.", CustomerNo);
        Found := CampaignTargetGr.CopyTo(TempCampaignTargetGr);
        OnAfterFindCustomerCampaigns(CustomerNo, TempCampaignTargetGr, Found);
    end;

    local procedure FindContactCompanyCampaigns(ContactNo: Code[20]; var TempCampaignTargetGr: Record "Campaign Target Group" temporary) Found: Boolean
    var
        CampaignTargetGr: Record "Campaign Target Group";
        Contact: Record Contact;
    begin
        if Contact.Get(ContactNo) then begin
            CampaignTargetGr.SetRange(Type, CampaignTargetGr.Type::Contact);
            CampaignTargetGr.SetRange("No.", Contact."Company No.");
            Found := CampaignTargetGr.CopyTo(TempCampaignTargetGr);
            OnAfterFindContactCompanyCampaigns(ContactNo, TempCampaignTargetGr, Found);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssetType(SalesLine: Record "Sales Line"; var AssetType: Enum "Price Asset Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(
        SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line";
        PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(
        var PriceCalculationBuffer: Record "Price Calculation Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var SalesLine: Record "Sales Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdate(var SalesLine: Record "Sales Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrice(var SalesLine: Record "Sales Line"; PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header"; CurrPriceType: Enum "Price Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerify(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToBufferOnAfterPriceCalculationBufferMgtSet(var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; var PriceCalculationBuffer: Record "Price Calculation Buffer"; var PriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDiscountAllowed(SalesLine: Record "Sales Line"; PriceCalculated: Boolean; var Result: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePrice(var SalesLine: Record "Sales Line"; CurrPriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPriceUpdateNeeded(AmountType: Enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer; var Result: Boolean; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindContactCompanyCampaigns(ContactNo: Code[20]; var TempCampaignTargetGr: Record "Campaign Target Group" temporary; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindCustomerCampaigns(CustomerNo: Code[20]; var TempCampaignTargetGr: Record "Campaign Target Group" temporary; var Found: Boolean)
    begin
    end;
}
