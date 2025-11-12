// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Finance.Currency;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Threading;
using System.Upgrade;
using System.Telemetry;
using Microsoft.Pricing.Calculation;

codeunit 7017 "Price List Management"
{
    var
        PriceIsFound: Boolean;
        SearchIfPriceExists: Boolean;
        AllLinesVerifiedMsg: Label 'All price list lines which were modified by you were verified.';
        EmptyPriceSourceErr: Label 'You must specify what the price applies to.';
        ImplementPricesMsg: Label 'Implementing price changes: inserted - %1, modified - %2, skipped - %3', Comment = '%1, %2, %3 are numbers';
        VerifyLinesLbl: Label 'Verify lines';
        VerifyLinesMsg: Label 'You must verify and activate modified lines to include them in price calculations.';
        VerifyLinesActionMsg: Label 'Prices that have been changed but not verified will not be included in price calculations. Use the Verify Lines action to verify and activate the changed lines.';
        VerifyLinesNotificationIdTxt: Label '0CDA03EA-8E9F-45BF-B2D7-0F9FADF5F966', Locked = true;
        ImplementedPriceNotificationIdTxt: Label '2BD32F12-A55D-4527-B885-ED881CC61D24', Locked = true;
        UpgradeNotificationGuidTok: Label '40BEF749-FD08-4355-B4AE-AC3423A82006', Locked = true;
        SourceGroupUpdateMsg: Label 'There are price list line records with not defined Source Group field. You are not allowed to copy the lines from the existing price lists.';
        CompleteSourceGroupUpgradeLbl: Label 'Complete the upgrade process for setting the Source Group field in price list lines.';
        DefaultPriceListTok: Label 'Default price list.';
        FixTok: Label 'Fix';
        PriceListHeaderHasToExistErr: Label 'Lines cannot be added because the price list header does not exist.';

    procedure AddLines(var PriceListHeader: Record "Price List Header")
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Worksheet := PriceListHeader.IsTemporary();
        if PriceLineFilters.Worksheet then
            SuggestPriceLine.SetDefaults(PriceListHeader)
        else begin
            if IsNullGuid(PriceListHeader.SystemId) then
                Error(PriceListHeaderHasToExistErr);
            PriceListHeader.TestField(Code);
        end;
        PriceLineFilters.Initialize(PriceListHeader, false);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            SuggestPriceLine.GetDefaults(PriceListHeader);
            AddLines(PriceListHeader, PriceLineFilters);
        end;
    end;

    procedure AddLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        PriceAsset: Record "Price Asset";
        RecRef: RecordRef;
    begin
        RecRef.Open(PriceLineFilters."Table Id");
        if PriceLineFilters."Asset Filter" <> '' then
            RecRef.SetView(PriceLineFilters."Asset Filter");
        if RecRef.FindSet() then begin
            PriceAsset."Price Type" := ToPriceListHeader."Price Type";
            PriceAsset.Validate("Asset Type", PriceLineFilters."Asset Type");
            repeat
                PriceAsset.Validate("Asset ID", RecRef.Field(RecRef.SystemIdNo()).Value());
                if PriceAsset."Asset No." <> '' then
                    AddLine(ToPriceListHeader, PriceAsset, PriceLineFilters);
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
    end;

    local procedure AddLine(ToPriceListHeader: Record "Price List Header"; PriceAsset: Record "Price Asset"; PriceLineFilters: Record "Price Line Filters")
    var
        ExistingPriceListLine: Record "Price List Line";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine."Price List Code" := ToPriceListHeader.Code;
        PriceListLine.SetNextLineNo();
        PriceListLine.CopyFrom(ToPriceListHeader, true);
        PriceListLine.CopyFrom(PriceAsset);
        ExistingPriceListLine.CopyPriceFrom(PriceAsset);
        AdjustAmount(PriceAsset."Unit Price", PriceLineFilters);
        AdjustAmount(PriceAsset."Unit Price 2", PriceLineFilters);
        PriceListLine.CopyPriceFrom(PriceAsset);
        PriceListLine.Validate("Minimum Quantity", PriceLineFilters."Minimum Quantity");
        OnAddLineOnAfterPopulatePriceListLineFields(PriceListLine, ToPriceListHeader, PriceAsset, PriceLineFilters);

        if PriceLineFilters.Worksheet then
            InsertWorksheetLine(ToPriceListHeader, PriceListLine, ExistingPriceListLine)
        else
            PriceListLine.Insert(true);
    end;

    procedure AdjustAmount(var Price: Decimal; PriceLineFilters: Record "Price Line Filters")
    var
        NewPrice: Decimal;
    begin
        if Price = 0 then
            exit;

        NewPrice := ConvertCurrency(Price, PriceLineFilters);
        NewPrice := NewPrice * PriceLineFilters."Adjustment Factor";

        if not ApplyRoundingMethod(PriceLineFilters."Rounding Method Code", NewPrice) then
            NewPrice := Round(NewPrice, PriceLineFilters."Amount Rounding Precision");

        Price := NewPrice;
    end;

    local procedure ConvertCurrency(Price: Decimal; PriceLineFilters: Record "Price Line Filters") NewPrice: Decimal;
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        NewPrice := Price;
        if PriceLineFilters."From Currency Code" <> PriceLineFilters."To Currency Code" then
            if PriceLineFilters."From Currency Code" = '' then
                NewPrice :=
                    Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code", Price,
                            CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."To Currency Code")),
                        PriceLineFilters."Amount Rounding Precision")
            else
                if PriceLineFilters."To Currency Code" = '' then
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                                PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code", Price,
                                CurrExchRate.ExchangeRate(PriceLineFilters."Exchange Rate Date", PriceLineFilters."From Currency Code")),
                            PriceLineFilters."Amount Rounding Precision")
                else
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                                PriceLineFilters."Exchange Rate Date",
                                PriceLineFilters."From Currency Code", PriceLineFilters."To Currency Code",
                                Price),
                            PriceLineFilters."Amount Rounding Precision");
    end;

    local procedure ApplyRoundingMethod(RoundingMethodCode: Code[10]; var Price: Decimal) Rounded: Boolean;
    var
        RoundingMethod: Record "Rounding Method";
    begin
        if Price <= 0 then
            exit(false);

        if RoundingMethodCode <> '' then begin
            RoundingMethod.SetRange(Code, RoundingMethodCode);
            RoundingMethod.SetFilter("Minimum Amount", '<=%1', Price);
            if RoundingMethod.FindLast() then begin
                Price := Price + RoundingMethod."Amount Added Before";
                if RoundingMethod.Precision > 0 then
                    Price :=
                      Round(
                        Price,
                        RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                Price := Price + RoundingMethod."Amount Added After";
                Rounded := true;
            end;
        end;
        if Price < 0 then
            Price := 0;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header")
    begin
        if IsNullGuid(ToPriceListHeader.SystemId) then
            Error(PriceListHeaderHasToExistErr);
        ToPriceListHeader.TestField(Code);
        CopyLines(ToPriceListHeader, true)
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header"; UpdateMultiplePriceLists: Boolean)
    var
        PriceLineFilters: Record "Price Line Filters";
        SuggestPriceLines: Page "Suggest Price Lines";
    begin
        PriceLineFilters."Update Multiple Price Lists" := UpdateMultiplePriceLists;
        PriceLineFilters.Worksheet := ToPriceListHeader.IsTemporary();
        if PriceLineFilters.Worksheet then
            SuggestPriceLines.SetDefaults(ToPriceListHeader);
        PriceLineFilters.Initialize(ToPriceListHeader, true);
        SuggestPriceLines.SetRecord(PriceLineFilters);
        if SuggestPriceLines.RunModal() = Action::OK then begin
            SuggestPriceLines.GetRecord(PriceLineFilters);
            if PriceLineFilters."Copy As New Lines" then
                SuggestPriceLines.GetDefaults(ToPriceListHeader);
            CopyLines(ToPriceListHeader, PriceLineFilters);
        end;
    end;

    procedure CopyLines(var ToPriceListHeader: Record "Price List Header"; PriceLineFilters: Record "Price Line Filters")
    var
        FromPriceListHeader: Record "Price List Header";
        FromPriceListLine: Record "Price List Line";
    begin
        if PriceLineFilters."Price Line Filter" <> '' then
            FromPriceListLine.SetView(PriceLineFilters."Price Line Filter");
        if PriceLineFilters."From Price List Code" <> '' then begin
            FromPriceListHeader.Get(PriceLineFilters."From Price List Code");
            FromPriceListLine.SetRange("Price List Code", PriceLineFilters."From Price List Code");
        end else
            if not PriceLineFilters.Worksheet then
                FromPriceListLine.SetFilter("Price List Code", '<>%1', ToPriceListHeader.Code);
        FromPriceListLine.SetRange("Price Type", ToPriceListHeader."Price Type");
        FromPriceListLine.SetRange("Source Group", ToPriceListHeader."Source Group");
        OnCopyLinesOnAfterFromPriceListLineSetFilters(FromPriceListLine, PriceLineFilters);
        if FromPriceListLine.FindSet() then
            repeat
                CopyLine(PriceLineFilters, FromPriceListLine, ToPriceListHeader);
            until FromPriceListLine.Next() = 0;
    end;

    local procedure CopyLine(PriceLineFilters: Record "Price Line Filters"; FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header")
    var
        ToPriceListLine: Record "Price List Line";
    begin
        ToPriceListLine := FromPriceListLine;
        if not PriceLineFilters.Worksheet or PriceLineFilters."Force Defaults" then begin
            ToPriceListLine."Price List Code" := PriceLineFilters."To Price List Code";
            ToPriceListLine.CopyFrom(ToPriceListHeader, PriceLineFilters."Force Defaults");
        end;
        SetCurrencyCodes(FromPriceListLine, ToPriceListHeader, PriceLineFilters);
        AdjustAmount(ToPriceListLine."Unit Price", PriceLineFilters);
        AdjustAmount(ToPriceListLine."Direct Unit Cost", PriceLineFilters);
        AdjustAmount(ToPriceListLine."Unit Cost", PriceLineFilters);
        OnCopyLineOnAfterAdjustAmounts(ToPriceListLine, PriceLineFilters, FromPriceListLine, ToPriceListHeader);

        if PriceLineFilters.Worksheet then
            CopyToWorksheetLine(ToPriceListLine, FromPriceListLine, PriceLineFilters."Copy As New Lines")
        else begin
            ToPriceListLine.SetNextLineNo();
            ToPriceListLine.Insert(true);
            OnCopyLineOnAfterInsertFromPriceListLine(FromPriceListLine, ToPriceListLine);
        end;
    end;

    local procedure SetCurrencyCodes(FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header"; var PriceLineFilters: Record "Price Line Filters")
    begin
        PriceLineFilters."From Currency Code" := FromPriceListLine."Currency Code";
        if PriceLineFilters."Force Defaults" then
            PriceLineFilters."To Currency Code" := ToPriceListHeader."Currency Code"
        else
            PriceLineFilters."To Currency Code" := PriceLineFilters."From Currency Code";
    end;

    procedure FindDuplicatePrice(PriceListLine: Record "Price List Line"): Boolean;
    var
        PriceListHeader: Record "Price List Header";
        DuplicatePriceLine: Record "Duplicate Price Line";
        DuplicatePriceListLine: Record "Price List Line";
        LineNo: Integer;
    begin
        if PriceListHeader.Get(PriceListLine."Price List Code") then;
        if FindDuplicatePrice(
            PriceListLine, PriceListHeader."Allow Updating Defaults", true,
            DuplicatePriceLine, LineNo, DuplicatePriceListLine)
        then
            exit(true);
        exit(
            FindDuplicatePrice(
                PriceListLine, PriceListHeader."Allow Updating Defaults", false,
                DuplicatePriceLine, LineNo, DuplicatePriceListLine));
    end;

    procedure FindDuplicatePrices(PriceListHeader: Record "Price List Header"; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line") Found: Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        exit(FindDuplicatePrices(PriceListHeader, PriceListLine, SearchInside, DuplicatePriceLine));
    end;

    procedure FindDuplicatePrices(PriceListHeader: Record "Price List Header"; var PriceListLine: Record "Price List Line"; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line") Found: Boolean;
    var
        DuplicatePriceListLine: Record "Price List Line";
        LineNo: Integer;
    begin
        DuplicatePriceLine.Reset();
        DuplicatePriceLine.DeleteAll();

        if PriceListLine.FindSet() then
            repeat
                FindDuplicatePrice(
                    PriceListLine, PriceListHeader."Allow Updating Defaults", SearchInside,
                    DuplicatePriceLine, LineNo, DuplicatePriceListLine);
            until PriceListLine.Next() = 0;
        Found := LineNo > 0;
    end;

    local procedure FindDuplicatePrice(PriceListLine: Record "Price List Line"; AsLineDefaults: Boolean; SearchInside: Boolean; var DuplicatePriceLine: Record "Duplicate Price Line"; var LineNo: Integer; var DuplicatePriceListLine: Record "Price List Line") Found: Boolean;
    begin
        if not DuplicatePriceLine.Get(PriceListLine."Price List Code", PriceListLine."Line No.") then
            if FindDuplicatePrice(PriceListLine, AsLineDefaults, SearchInside, DuplicatePriceListLine) then
                if DuplicatePriceLine.Get(DuplicatePriceListLine."Price List Code", DuplicatePriceListLine."Line No.") then
                    DuplicatePriceLine.Add(LineNo, DuplicatePriceLine."Duplicate To Line No.", PriceListLine)
                else
                    DuplicatePriceLine.Add(LineNo, PriceListLine, DuplicatePriceListLine);
        Found := LineNo > 0;
    end;

    local procedure FindDuplicatePrice(PriceListLine: Record "Price List Line"; AsLineDefaults: Boolean; SearchInside: Boolean; var DuplicatePriceListLine: Record "Price List Line"): Boolean;
    begin
        DuplicatePriceListLine.Reset();
        if SearchInside then begin
            DuplicatePriceListLine.SetRange("Price List Code", PriceListLine."Price List Code");
            DuplicatePriceListLine.SetFilter("Line No.", '<>%1', PriceListLine."Line No.");
            if AsLineDefaults then
                SetHeadersFilters(PriceListLine, DuplicatePriceListLine);
        end else begin
            DuplicatePriceListLine.SetFilter("Price List Code", '<>%1', PriceListLine."Price List Code");
            SetHeadersFilters(PriceListLine, DuplicatePriceListLine);
        end;
        SetAssetFilters(PriceListLine, DuplicatePriceListLine);
        OnBeforeFindDuplicatePriceListLine(PriceListLine, DuplicatePriceListLine);
        exit(DuplicatePriceListLine.FindFirst());
    end;

    procedure GetDefaultPriceListCode(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group"; FailIfBlank: Boolean): Code[20];
    var
        JobsSetup: Record "Jobs Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if SourceGroup = SourceGroup::Job then begin
            JobsSetup.Get();
            case PriceType of
                "Price Type"::Sale:
                    begin
                        if FailIfBlank then
                            JobsSetup.TestField("Default Sales Price List Code");
                        exit(JobsSetup."Default Sales Price List Code");
                    end;
                "Price Type"::Purchase:
                    begin
                        if FailIfBlank then
                            JobsSetup.TestField("Default Purch Price List Code");
                        exit(JobsSetup."Default Purch Price List Code");
                    end;
            end;
        end else
            case PriceType of
                "Price Type"::Sale:
                    begin
                        SalesReceivablesSetup.Get();
                        if FailIfBlank then
                            SalesReceivablesSetup.TestField("Default Price List Code");
                        exit(SalesReceivablesSetup."Default Price List Code");
                    end;
                "Price Type"::Purchase:
                    begin
                        PurchasesPayablesSetup.Get();
                        if FailIfBlank then
                            PurchasesPayablesSetup.TestField("Default Price List Code");
                        exit(PurchasesPayablesSetup."Default Price List Code");
                    end;
            end;
    end;

    procedure DefineDefaultPriceList(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group") DefaultPriceListCode: Code[20];
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        case SourceGroup of
            SourceGroup::Customer:
                DefaultPriceListCode := DefineSalesDefaultPriceList();
            SourceGroup::Vendor:
                DefaultPriceListCode := DefinePurchDefaultPriceList();
            SourceGroup::Job:
                DefaultPriceListCode := DefineJobDefaultPriceList(PriceType);
        end
    end;

    local procedure DefineJobDefaultPriceList(PriceType: Enum "Price Type") DefaultPriceListCode: Code[20];
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        DefaultPriceListCode := CreateDefaultPriceList(PriceType, "Price Source Group"::Job);
        case PriceType of
            PriceType::Purchase:
                JobsSetup."Default Purch Price List Code" := DefaultPriceListCode;
            PriceType::Sale:
                JobsSetup."Default Sales Price List Code" := DefaultPriceListCode;
        end;
        JobsSetup.Modify();
    end;

    local procedure DefinePurchDefaultPriceList() DefaultPriceListCode: Code[20];
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        DefaultPriceListCode := CreateDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Vendor);
        PurchasesPayablesSetup."Default Price List Code" := DefaultPriceListCode;
        PurchasesPayablesSetup."Allow Editing Active Price" := true;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure DefineSalesDefaultPriceList() DefaultPriceListCode: Code[20];
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        DefaultPriceListCode := CreateDefaultPriceList("Price Type"::Sale, "Price Source Group"::Customer);
        SalesReceivablesSetup."Default Price List Code" := DefaultPriceListCode;
        SalesReceivablesSetup."Allow Editing Active Price" := true;
        SalesReceivablesSetup.Modify();
        exit(SalesReceivablesSetup."Default Price List Code");
    end;

    local procedure CreateDefaultPriceList(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group"): Code[20]
    var
        PriceListHeader: Record "Price List Header";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Used");

        PriceListHeader.Validate("Price Type", PriceType);
        PriceListHeader.Validate("Source Group", SourceGroup);
        PriceListHeader.Description := DefaultPriceListTok;
        case SourceGroup of
            SourceGroup::Customer:
                PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"All Customers");
            SourceGroup::Vendor:
                PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"All Vendors");
            SourceGroup::Job:
                PriceListHeader.Validate("Source Type", PriceListHeader."Source Type"::"All Jobs");
        end;
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader."Amount Type" := "Price Amount Type"::Any;
        PriceListHeader.Status := "Price Status"::Active;
        if PriceListHeader.Insert(true) then begin
            FeatureTelemetry.LogUsage('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), 'Price List automatically activated');
            exit(PriceListHeader.Code);
        end;
    end;

    procedure IsAllowedEditingActivePrice(PriceType: Enum "Price Type") Result: Boolean;
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case PriceType of
            "Price Type"::Sale:
                if SalesReceivablesSetup.Get() then
                    Result := SalesReceivablesSetup."Allow Editing Active Price";
            "Price Type"::Purchase:
                if PurchasesPayablesSetup.Get() then
                    Result := PurchasesPayablesSetup."Allow Editing Active Price";
        end;
        OnAfterIsAllowedEditingActivePrice(PriceType, Result);
    end;

    procedure SendVerifyLinesNotification()
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetVerifyLinesNotificationId();
        VerifyLinesNotification.Message := VerifyLinesActionMsg;
        VerifyLinesNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        VerifyLinesNotification.Send();
    end;

    local procedure SendNotificationNewPriceImplementation(InsertedUpdatedLeft: array[3] of Integer)
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetImplementedPriceNotificationId();
        VerifyLinesNotification.Message :=
            StrSubstNo(ImplementPricesMsg, InsertedUpdatedLeft[1], InsertedUpdatedLeft[2], InsertedUpdatedLeft[3]);
        VerifyLinesNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        VerifyLinesNotification.Send();
    end;

    procedure SendVerifyLinesNotification(PriceListHeader: Record "Price List Header")
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetVerifyLinesNotificationId();
        VerifyLinesNotification.Message := VerifyLinesMsg;
        VerifyLinesNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        VerifyLinesNotification.SetData(PriceListHeader.FieldName(Code), PriceListHeader.Code);
        VerifyLinesNotification.AddAction(VerifyLinesLbl, CODEUNIT::"Price List Management", 'ActivateDraftLines');
        VerifyLinesNotification.Send();
    end;

    local procedure RecallVerifyLinesNotification()
    var
        VerifyLinesNotification: Notification;
    begin
        VerifyLinesNotification.Id := GetVerifyLinesNotificationId();
        VerifyLinesNotification.Recall();
    end;

    local procedure GetImplementedPriceNotificationId() Id: Guid;
    begin
        Evaluate(Id, ImplementedPriceNotificationIdTxt);
    end;

    local procedure GetVerifyLinesNotificationId() Id: Guid;
    begin
        Evaluate(Id, VerifyLinesNotificationIdTxt);
    end;

    procedure ActivateDraftLines(VerifyLinesNotification: Notification)
    begin
        ActivateDraftLines(VerifyLinesNotification, false)
    end;

    procedure ActivateDraftLines(VerifyLinesNotification: Notification; SkipMessage: Boolean)
    var
        PriceListHeader: Record "Price List Header";
    begin
        if VerifyLinesNotification.HasData(PriceListHeader.FieldName(Code)) then
            if PriceListHeader.Get(VerifyLinesNotification.GetData(PriceListHeader.FieldName(Code))) then
                ActivateDraftLines(PriceListHeader, SkipMessage);
    end;

    procedure ActivateDraftLines(PriceListHeader: Record "Price List Header"): Boolean;
    begin
        exit(ActivateDraftLines(PriceListHeader, false));
    end;

    procedure ActivateDraftLines(PriceListHeader: Record "Price List Header"; SkipMessage: Boolean): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        RecallVerifyLinesNotification();
        if not PriceListHeader.HasDraftLines(PriceListLine) then
            exit;

        VerifyLines(PriceListLine);
        if not ResolveDuplicatePrices(PriceListHeader) then
            exit(false);

        PriceListLine.ModifyAll(Status, "Price Status"::Active);
        OnActivateDraftLinesOnAfterPriceListLineModifyAll(PriceListHeader, SkipMessage);
        if not SkipMessage then
            Message(AllLinesVerifiedMsg);
        exit(true);
    end;

    procedure ActivateDraftLines(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if PriceListLine.IsEmpty() then
            exit;
        VerifyLines(PriceListLine);
        ResolveDuplicatePrices(PriceListLine);
        OnAfterActivateDraftLines(PriceListLine);
    end;

    procedure VerifyLines(var PriceListLine: Record "Price List Line")
    begin
        if PriceListLine.FindSet() then
            repeat
                PriceListLine.Verify();
            until PriceListLine.Next() = 0;
    end;

    procedure ResolveDuplicatePrices(PriceListHeader: Record "Price List Header") Resolved: Boolean
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResolveDuplicatePrices(PriceListHeader, Resolved, IsHandled);
        if IsHandled then
            exit(Resolved);

        if PriceListHeader.Status <> PriceListHeader.Status::Active then
            exit(false);

        if FindDuplicatePrices(PriceListHeader, true, DuplicatePriceLine) then
            if not ResolveDuplicatePrices(PriceListHeader, DuplicatePriceLine) then
                exit(false);

        if FindDuplicatePrices(PriceListHeader, false, DuplicatePriceLine) then
            if not ResolveDuplicatePrices(PriceListHeader, DuplicatePriceLine) then
                exit(false);
        exit(true);
    end;

    procedure ResolveDuplicatePrices(var PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
        PriceListLineLocal: Record "Price List Line";
    begin
        if PriceListLine.FindSet() then
            repeat
                if PriceListHeader.Code <> PriceListLine."Price List Code" then begin
                    if not PriceListHeader.Get(PriceListLine."Price List Code") then
                        PriceListHeader.Code := PriceListLine."Price List Code";
                    if ResolveDuplicatePrices(PriceListHeader) then begin
                        PriceListLineLocal.SetRange("Price List Code", PriceListHeader.Code);
                        PriceListLineLocal.SetRange(Status, "Price Status"::Draft);
                        if not PriceListLineLocal.IsEmpty() then begin
                            PriceListLineLocal.ModifyAll(Status, "Price Status"::Active);
                            Commit();
                        end
                    end;
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure SetPriceListsFilters(var PriceListHeader: Record "Price List Header"; PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        SetSourceFilters(PriceSourceList, PriceListHeader);
        PriceListHeader.FilterGroup(0);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange(Status, "Price Status"::Draft, "Price Status"::Active);
        PriceListLine.SetRange("Price Type", PriceSourceList.GetPriceType());
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        BuildSourceFilters(PriceListLine, PriceSourceList);
        PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    procedure SetPriceListLineFilters(var PriceListLine: Record "Price List Line"; PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List"; AmountType: Enum "Price Amount Type"): Boolean;
    var
        MarkingIsUsed: Boolean;
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange(Status, "Price Status"::Draft, "Price Status"::Active);
        PriceListLine.SetRange("Price Type", PriceSource."Price Type");
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then begin
            PriceListLine.SetRange("Source Type", PriceSource."Source Type");
            PriceListLine.SetRange("Source No.", PriceSource."Source No.");
        end;
        BuildAssetFilters(PriceListLine, PriceAssetList, MarkingIsUsed);
        if MarkingIsUsed then
            PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    local procedure BuildAssetFilters(var PriceListLine: Record "Price List Line"; PriceAssetList: Codeunit "Price Asset List"; var MarkingIsUsed: Boolean)
    var
        PriceAsset: Record "Price Asset";
    begin
        MarkingIsUsed := true;
        if not SearchIfPriceExists then
            MarkingIsUsed := CheckIfPriceListLineMarkingIsNeeded(PriceListLine, PriceAssetList);

        if PriceAssetList.First(PriceAsset, 0) then
            repeat
                PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
                if PriceAsset."Asset No." <> '' then
                    PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.")
                else
                    PriceListLine.SetRange("Asset No.");
                if PriceAsset."Variant Code" <> '' then
                    PriceListLine.SetRange("Variant Code", PriceAsset."Variant Code")
                else
                    PriceListLine.SetRange("Variant Code");
                OnBuildAssetFiltersOnBeforeFindLines(PriceListLine, PriceAsset);
                if not PriceListLine.IsEmpty() then begin
                    if SearchIfPriceExists then begin
                        ClearAssetFilters(PriceListLine);
                        PriceIsFound := true;
                        exit;
                    end;

                    PriceListLine.FindSet();
                    if not MarkingIsUsed then
                        exit;

                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
                end;
            until not PriceAssetList.Next(PriceAsset);
        ClearAssetFilters(PriceListLine);
    end;

    local procedure CheckIfPriceListLineMarkingIsNeeded(var PriceListLine: Record "Price List Line"; PriceAssetList: Codeunit "Price Asset List"): Boolean;
    var
        PriceAsset: Record "Price Asset";
        RecordSetsCounter: Integer;
    begin
        if PriceAssetList.First(PriceAsset, 0) then
            repeat
                PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
                if PriceAsset."Asset No." <> '' then
                    PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.")
                else
                    PriceListLine.SetRange("Asset No.");
                if PriceAsset."Variant Code" <> '' then
                    PriceListLine.SetRange("Variant Code", PriceAsset."Variant Code")
                else
                    PriceListLine.SetRange("Variant Code");
                OnCheckIfPriceListLineMarkingIsNeededOnBeforeFindLines(PriceListLine, PriceAsset);
                if not PriceListLine.IsEmpty() then begin
                    RecordSetsCounter += 1;
                    if RecordSetsCounter > 1 then begin
                        ClearAssetFilters(PriceListLine);
                        exit(true);
                    end;
                end;
            until not PriceAssetList.Next(PriceAsset);
        ClearAssetFilters(PriceListLine);
        if RecordSetsCounter = 0 then
            exit(true);
    end;

    local procedure ClearAssetFilters(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetRange("Asset Type");
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange("Variant Code");

        OnAfterClearAssetFilters(PriceListLine);
    end;

    local procedure BuildSourceFilters(var PriceListLine: Record "Price List Line"; PriceSourceList: Codeunit "Price Source List")
    var
        PriceSource: Record "Price Source";
    begin
        if PriceSourceList.First(PriceSource, 0) then
            repeat
                PriceListLine.SetRange("Source Type", PriceSource."Source Type");
                PriceListLine.SetRange("Parent Source No.", PriceSource."Parent Source No.");
                PriceListLine.SetRange("Source No.", PriceSource."Source No.");
                OnBuildSourceFiltersOnBeforeFindLines(PriceListLine, PriceSource);
                if PriceListLine.FindSet() then begin
                    if SearchIfPriceExists then begin
                        ClearSourceFilters(PriceListLine);
                        PriceIsFound := true;
                        exit;
                    end;
                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
                end;
            until not PriceSourceList.Next(PriceSource);
        ClearSourceFilters(PriceListLine);
    end;

    local procedure ClearSourceFilters(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.SetRange("Source Type");
        PriceListLine.SetRange("Source No.");
        PriceListLine.SetRange("Parent Source No.");

        OnAfterClearSourceFilters(PriceListLine);
    end;

    procedure FindIfPriceExists()
    begin
        SearchIfPriceExists := true;
        PriceIsFound := false;
    end;

    procedure IsPriceFound(): Boolean;
    begin
        SearchIfPriceExists := false;
        exit(PriceIsFound);
    end;

    local procedure SetSourceFilters(PriceSourceList: Codeunit "Price Source List"; var PriceListHeader: Record "Price List Header")
    var
        PriceSource: Record "Price Source";
        SourceFilter: array[3] of Text;
    begin
        PriceSourceList.GetList(PriceSource);
        if not PriceSource.FindSet() then
            Error(EmptyPriceSourceErr);

        PriceListHeader.SetRange("Price Type", PriceSource."Price Type");
        PriceListHeader.SetRange("Source Group", PriceSource."Source Group");

        BuildSourceFilters(PriceSource, SourceFilter);
        if SourceFilter[3] <> '' then
            PriceListHeader.SetFilter("Filter Source No.", SourceFilter[3])
        else begin
            PriceListHeader.SetFilter("Source Type", SourceFilter[1]);
            PriceListHeader.SetFilter("Source No.", SourceFilter[2]);
        end;
    end;

    local procedure BuildSourceFilters(var PriceSource: Record "Price Source"; var SourceFilter: array[3] of Text)
    var
        OrSeparator: Text[1];
    begin
        repeat
            if PriceSource."Source Group" = PriceSource."Source Group"::Job then
                SourceFilter[3] += OrSeparator + GetFilterText(PriceSource."Filter Source No.")
            else begin
                SourceFilter[1] += OrSeparator + Format(PriceSource."Source Type");
                SourceFilter[2] += OrSeparator + GetFilterText(PriceSource."Source No.");
            end;
            OrSeparator := '|';
        until PriceSource.Next() = 0;

        OnAfterBuildSourceFilters(PriceSource, SourceFilter);
    end;

    local procedure GetFilterText(SourceNo: Code[20]): Text;
    begin
        if SourceNo = '' then
            exit('''''');
        exit(SourceNo);
    end;

    procedure SetHeadersFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        DuplicatePriceListLine.SetRange("Price Type", PriceListLine."Price Type");
        DuplicatePriceListLine.SetRange("Source Type", PriceListLine."Source Type");
        DuplicatePriceListLine.SetRange("Parent Source No.", PriceListLine."Parent Source No.");
        DuplicatePriceListLine.SetRange("Source No.", PriceListLine."Source No.");
        DuplicatePriceListLine.SetRange("Currency Code", PriceListLine."Currency Code");
        DuplicatePriceListLine.SetRange("Starting Date", PriceListLine."Starting Date");
        OnAfterSetHeadersFilters(PriceListLine, DuplicatePriceListLine);
    end;

    procedure SetAssetFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
        if PriceListLine."Amount Type" in ["Price Amount Type"::Price, "Price Amount Type"::Discount] then
            DuplicatePriceListLine.SetFilter("Amount Type", '%1|%2', PriceListLine."Amount Type", "Price Amount Type"::Any);
        DuplicatePriceListLine.SetRange("Asset Type", PriceListLine."Asset Type");
        DuplicatePriceListLine.SetRange("Asset No.", PriceListLine."Asset No.");
        DuplicatePriceListLine.SetRange("Unit of Measure Code", PriceListLine."Unit of Measure Code");
        DuplicatePriceListLine.SetRange("Minimum Quantity", PriceListLine."Minimum Quantity");
        case PriceListLine."Asset Type" of
            "Price Asset Type"::Item:
                DuplicatePriceListLine.SetRange("Variant Code", PriceListLine."Variant Code");
            "Price Asset Type"::Resource, "Price Asset Type"::"Resource Group":
                DuplicatePriceListLine.SetRange("Work Type Code", PriceListLine."Work Type Code");
        end;
        OnAfterSetAssetFilters(PriceListLine, DuplicatePriceListLine);
    end;

    procedure ResolveDuplicatePrices(PriceListHeader: Record "Price List Header"; var DuplicatePriceLine: Record "Duplicate Price Line") Resolved: Boolean;
    var
        PriceListLine: Record "Price List Line";
        DuplicatePriceLines: Page "Duplicate Price Lines";
    begin
        DuplicatePriceLines.Set(PriceListHeader."Price Type", PriceListHeader."Amount Type", DuplicatePriceLine);
        DuplicatePriceLines.LookupMode(true);
        if DuplicatePriceLines.RunModal() = Action::LookupOK then begin
            DuplicatePriceLines.GetLines(DuplicatePriceLine);
            DuplicatePriceLine.SetRange(Remove, true);
            if DuplicatePriceLine.FindSet() then
                repeat
                    if PriceListLine.Get(DuplicatePriceLine."Price List Code", DuplicatePriceLine."Price List Line No.") then
                        PriceListLine.Delete();
                until DuplicatePriceLine.Next() = 0;
            Resolved := true;
            Commit();
        end;
    end;

    procedure ImplementNewPrices(var PriceWorksheetLine: Record "Price Worksheet Line")
    var
        PriceListLine: Record "Price List Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        InsertedUpdatedLeft: array[3] of Integer;
    begin
        FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Used");

        OnBeforeImplementNewPrices(PriceWorksheetLine);

        PriceWorksheetLine.SetFilter("Price List Code", '<>%1', '');
        if PriceWorksheetLine.FindSet(true) then begin
            repeat
                if not PriceWorksheetLine.TryVerify() then
                    InsertedUpdatedLeft[3] += 1
                else
                    if not ImplementNewPrice(PriceWorksheetLine, PriceListLine, InsertedUpdatedLeft) then
                        InsertedUpdatedLeft[3] += 1;
            until PriceWorksheetLine.Next() = 0;
            SendNotificationNewPriceImplementation(InsertedUpdatedLeft);
            if InsertedUpdatedLeft[1] + InsertedUpdatedLeft[2] > 0 then begin
                Commit();
                PriceListLine.MarkedOnly(true);
                ActivateDraftLines(PriceListLine);
            end;
        end;

        FeatureTelemetry.LogUsage('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), 'New prices implemented');
    end;

    local procedure ImplementNewPrice(var PriceWorksheetLine: Record "Price Worksheet Line"; var PriceListLine: Record "Price List Line"; var InsertedUpdatedLeft: array[3] of Integer) Implemented: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImplementNewPrice(PriceWorksheetLine, Implemented, IsHandled);
        if not IsHandled then begin
            Implemented := false;
            PriceListLine.TransferFields(PriceWorksheetLine);
            if PriceWorksheetLine."Existing Line" then begin
                PriceListLine.Status := PriceListLine.Status::Draft;
                if PriceListLine.Modify(true) then begin
                    InsertedUpdatedLeft[2] += 1;
                    Implemented := true;
                end;
            end else begin
                PriceListLine.SetNextLineNo();
                if PriceListLine.Insert(true) then begin
                    InsertedUpdatedLeft[1] += 1;
                    Implemented := true;
                end;
            end;
            if Implemented then begin
                PriceWorksheetLine.Delete();
                PriceListLine.Mark(true);
            end;
        end;
        OnAfterImplementNewPrice(PriceWorksheetLine, PriceListLine, Implemented);
    end;

    local procedure InsertWorksheetLine(var ToPriceListHeader: Record "Price List Header"; NewPriceListLine: Record "Price List Line"; ExistingPriceListLine: Record "Price List Line")
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.CopyExistingPrices(ExistingPriceListLine);
        PriceWorksheetLine.TransferFields(NewPriceListLine);
        PriceWorksheetLine."Line No." := 0;
        PriceWorksheetLine."Source Group" := ToPriceListHeader."Source Group";
        PriceWorksheetLine.Insert(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price List Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnAfterCopyToPriceSource(var Rec: Record "Price List Line"; var xRec: Record "Price List Line"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;
        if RunTrigger then
            MarkLineAsDraft(Rec, xRec);
    end;

    local procedure MarkLineAsDraft(var Rec: Record "Price List Line"; var xRec: Record "Price List Line")
    begin
        if Rec.Status = Rec.Status::Active then
            if xRec.Find() and (xRec.Status = Rec.Status) then
                if IsAllowedEditingActivePrice(Rec."Price Type") then
                    Rec.Status := Rec.Status::Draft;
    end;

    local procedure CopyToWorksheetLine(ToPriceListLine: Record "Price List Line"; FromPriceListLine: Record "Price List Line"; CreateNewLine: Boolean)
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceWorksheetLine.TransferFields(ToPriceListLine);
        PriceWorksheetLine."Existing Unit Price" := FromPriceListLine."Unit Price";
        PriceWorksheetLine."Existing Direct Unit Cost" := FromPriceListLine."Direct Unit Cost";
        PriceWorksheetLine."Existing Unit Cost" := FromPriceListLine."Unit Cost";
        PriceWorksheetLine.Validate("Existing Line", not CreateNewLine);
        OnCopyToWorksheetLineOnBeforeInsert(PriceWorksheetLine, FromPriceListLine);
        PriceWorksheetLine.Insert(true);
    end;


    procedure VerifySourceGroupInLines(): Boolean;
    var
        PriceListLine: Record "Price List Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeNotification: Notification;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag()) or
           UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSyncPriceListLineStatusUpgradeTag())
        then
            exit(true);

        UpgradeNotification.Id := UpgradeNotificationGuidTok;
        UpgradeNotification.Message(SourceGroupUpdateMsg);
        UpgradeNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        UpgradeNotification.AddAction(FixTok, Codeunit::"Price List Management", 'UpdateSourceGroupInLines');
        NotificationLifecycleMgt.SendNotification(UpgradeNotification, PriceListLine.RecordId());
    end;

    procedure UpdateSourceGroupInLines(UpgradeNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.Validate("Object ID to Run", Codeunit::"Set Price Line Source Group");
        JobQueueEntry.Description := CompleteSourceGroupUpgradeLbl;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        JobQueueEntry.Insert(true);

        Page.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddLineOnAfterPopulatePriceListLineFields(var PriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header"; PriceAsset: Record "Price Asset"; PriceLineFilters: Record "Price Line Filters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnActivateDraftLinesOnAfterPriceListLineModifyAll(var PriceListHeader: Record "Price List Header"; var SkipMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivateDraftLines(PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBuildSourceFilters(var PriceSource: Record "Price Source"; var SourceFilter: array[3] of Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImplementNewPrice(var PriceWorksheetLine: Record "Price Worksheet Line"; var PriceListLine: Record "Price List Line"; var Implemented: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAllowedEditingActivePrice(PriceType: Enum "Price Type"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDuplicatePriceListLine(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildAssetFiltersOnBeforeFindLines(var PriceListLine: Record "Price List Line"; PriceAsset: Record "Price Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildSourceFiltersOnBeforeFindLines(var PriceListLine: Record "Price List Line"; PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToWorksheetLineOnBeforeInsert(var PriceWorksheetLine: Record "Price Worksheet Line"; FromPriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLinesOnAfterFromPriceListLineSetFilters(var PriceListLine: Record "Price List Line"; PriceLineFilters: Record "Price Line Filters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyLineOnAfterAdjustAmounts(var ToPriceListLine: Record "Price List Line"; PriceLineFilters: Record "Price Line Filters"; var FromPriceListLine: Record "Price List Line"; ToPriceListHeader: Record "Price List Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImplementNewPrice(var PriceWorksheetLine: Record "Price Worksheet Line"; var Implemented: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLineOnAfterInsertFromPriceListLine(FromPriceListLine: Record "Price List Line"; var ToPriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImplementNewPrices(var PriceWorksheetLine: Record "Price Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHeadersFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssetFilters(PriceListLine: Record "Price List Line"; var DuplicatePriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResolveDuplicatePrices(PriceListHeader: Record "Price List Header"; var Resolved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearSourceFilters(var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearAssetFilters(var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfPriceListLineMarkingIsNeededOnBeforeFindLines(var PriceListLine: Record "Price List Line"; var PriceAsset: Record "Price Asset")
    begin
    end;
}