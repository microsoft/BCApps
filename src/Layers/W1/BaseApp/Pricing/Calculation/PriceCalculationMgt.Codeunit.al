// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Foundation.Company;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using System.Environment;
using System.Telemetry;

codeunit 7001 "Price Calculation Mgt."
{
    trigger OnRun()
    begin
        RefreshSetup();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ManualLbl: Label 'Manual', Locked = true;
        TwoPlacesTxt: Label '%1-%2;', Locked = true;
        UseCustomizedLookupTxt: Label 'Use Customized Lookup', Locked = true;
        SubscriptionsTxt: Label 'Subscriptions', Locked = true;
        ExtendedPriceFeatureIdTok: Label 'SalesPrices', Locked = true;
        ExtendedPriceFeatureTelemetryNameLbl: Label 'New Sales Pricing', Locked = true;
        UsedCustomLookupTxt: Label 'Used custom lookup in table %1.', Comment = '%1 = table id', Locked = true;
        NotImplementedMethodErr: Label 'Method %1 does not have active implementations for %2 price type.', Comment = '%1 - method name, %2 - price type name';
        FeatureIsOffErr: Label 'Extended price calculation feature is not enabled.';

    procedure RefreshSetup() Updated: Boolean;
    var
        TempPriceCalculationSetup: Record "Price Calculation Setup" temporary;
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if not IsExtendedPriceCalculationEnabled() then
            exit(false);

        OnFindSupportedSetup(TempPriceCalculationSetup);
        if PriceCalculationSetup.FindSet() then
            repeat
                if TempPriceCalculationSetup.Get(PriceCalculationSetup.Code) then
                    TempPriceCalculationSetup.Delete()
                else begin
                    PriceCalculationSetup.Delete();
                    Updated := true;
                end;
            until PriceCalculationSetup.Next() = 0;
        if PriceCalculationSetup.MoveFrom(TempPriceCalculationSetup) then
            Updated := true;
    end;

    procedure GetHandler(LineWithPrice: Interface "Line With Price"; var PriceCalculation: Interface "Price Calculation") Result: Boolean;
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        Result := FindSetup(LineWithPrice, PriceCalculationSetup);
        OnGetHandlerOnAfterFindSetup(LineWithPrice, PriceCalculation, Result, PriceCalculationSetup);
        PriceCalculation := PriceCalculationSetup.Implementation;
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
    end;

    procedure VerifyMethodImplemented(Method: Enum "Price Calculation Method"; PriceType: Enum "Price Type")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if PriceType = PriceType::Any then
            PriceCalculationSetup.SetFilter(Type, '>%1', PriceType)
        else
            PriceCalculationSetup.SetRange(Type, PriceType);
        PriceCalculationSetup.SetRange(Method, Method);
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.IsEmpty() then
            Error(NotImplementedMethodErr, Method, PriceType);
    end;

    procedure FindActiveSubscriptions() Found: Text
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetFilter(
            "Publisher Object ID", '%1..%2|%3..%4',
            Codeunit::"Sales Line - Price", Codeunit::"Price List Line - Price",
            Codeunit::"Price Asset - Item", Codeunit::"Price Asset - G/L Account");
        EventSubscription.SetRange(Active, true);
        if EventSubscription.IsEmpty() then
            exit('');
        if EventSubscription.FindSet() then
            repeat
                Found +=
                    StrSubstNo(
                        TwoPlacesTxt,
                        EventSubscription."Publisher Object ID",
                        EventSubscription."Subscriber Function");
                if EventSubscription."Subscriber Instance" = ManualLbl then
                    Found +=
                        StrSubstNo(
                            TwoPlacesTxt,
                            EventSubscription."Subscriber Instance",
                            EventSubscription."Active Manual Instances");
            until EventSubscription.Next() = 0;
    end;

    procedure FindSetup(LineWithPrice: Interface "Line With Price"; var PriceCalculationSetup: Record "Price Calculation Setup"): Boolean;
    var
        DtldPriceCalcSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
    begin
        PriceCalculationSetup.Method := PriceCalculationSetup.Method::"Lowest Price";
        if not IsExtendedPriceCalculationEnabled() then
            PriceCalculationSetup.Implementation := PriceCalculationSetup.Implementation::"Business Central (Version 15.0)"
        else
            PriceCalculationSetup.Implementation := PriceCalculationSetup.Implementation::"Business Central (Version 16.0)";

        if not LineWithPrice.SetAssetSourceForSetup(DtldPriceCalcSetup) then
            exit(false);

        if DtldPriceCalcSetup.Method = DtldPriceCalcSetup.Method::" " then
            DtldPriceCalcSetup.Method := DtldPriceCalcSetup.Method::"Lowest Price";

        if PriceCalculationDtldSetup.FindSetup(DtldPriceCalcSetup) then
            if PriceCalculationSetup.Get(DtldPriceCalcSetup."Setup Code") then
                exit(true);

        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Enabled, true);
        PriceCalculationSetup.SetRange(Default, true);
        PriceCalculationSetup.SetRange(Method, DtldPriceCalcSetup.Method);
        PriceCalculationSetup.SetRange(Type, DtldPriceCalcSetup.Type);
        PriceCalculationSetup.SetRange("Asset Type", DtldPriceCalcSetup."Asset Type");
        if PriceCalculationSetup.FindFirst() then
            exit(true);
        PriceCalculationSetup.SetRange("Asset Type", PriceCalculationSetup."Asset Type"::" ");
        if PriceCalculationSetup.FindFirst() then
            exit(true);

        Clear(PriceCalculationSetup);
        exit(false);
    end;

    procedure IsExtendedPriceCalculationEnabled() FeatureEnabled: Boolean;
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        FeatureEnabled := CompanyInfo."Pricing Implementation" = CompanyInfo."Pricing Implementation"::"Extended Pricing";
        OnIsExtendedPriceCalculationEnabled(FeatureEnabled);
    end;

    procedure GetFeatureKey(): Text[50]
    begin
        exit(ExtendedPriceFeatureIdTok);
    end;

    procedure GetFeatureTelemetryName(): Text[50]
    begin
        exit(ExtendedPriceFeatureTelemetryNameLbl);
    end;

    procedure TestIsEnabled()
    begin
        if not IsExtendedPriceCalculationEnabled() then
            Error(FeatureIsOffErr);
    end;

    internal procedure FeatureCustomizedLookupUsage(TableId: Integer)
    begin
        FeatureTelemetry.LogUptake('0000HMI', UseCustomizedLookupTxt, "Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000HMK', UseCustomizedLookupTxt, StrSubstNo(UsedCustomLookupTxt, TableId));
    end;

    internal procedure FeatureCustomizedLookupDiscovered()
    begin
        FeatureTelemetry.LogUptake('0000HMJ', UseCustomizedLookupTxt, "Feature Uptake Status"::Discovered)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnAfterValidateEvent', 'Use Customized Lookup', false, false)]
    local procedure AfterValidateUseCustomizedLookup(var Rec: Record "Sales & Receivables Setup"; var xRec: Record "Sales & Receivables Setup"; CurrFieldNo: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if Rec."Use Customized Lookup" then begin
            CustomDimensions.Add(SubscriptionsTxt, FindActiveSubscriptions());
            FeatureTelemetry.LogUptake('0000HBY', UseCustomizedLookupTxt, "Feature Uptake Status"::"Set up", CustomDimensions)
        end else
            FeatureTelemetry.LogUptake('0000HBZ', UseCustomizedLookupTxt, "Feature Uptake Status"::Undiscovered)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsExtendedPriceCalculationEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSupportedSetup(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetHandlerOnAfterFindSetup(LineWithPrice: Interface "Line With Price"; var PriceCalculation: Interface "Price Calculation"; var Result: Boolean; var PriceCalculationSetup: Record "Price Calculation Setup")
    begin
    end;
}