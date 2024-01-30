// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Apps;

/// <summary>
/// Single AppSource Product Details Page
/// </summary>
page 2516 "AppSource Product Details"
{
    PageType = Card;
    ApplicationArea = All;
    Editable = false;
    Caption = 'App Overview';
    DataCaptionExpression = AppSourceProductManager.GetStringValue(ProductObject, 'displayName');

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(OfferGroup)
            {
                Caption = 'Offer';

                field(Offer_UniqueID; UniqueProductID)
                {
                    Caption = 'Unique Product ID';
                    ToolTip = 'Specifies the Unique Product ID';
                    Visible = false;
                }
                field(Offer_ProductType; AppSourceProductManager.GetStringValue(ProductObject, 'productType'))
                {
                    Caption = 'Product Type';
                    ToolTip = 'Specifies the Product Type';
                    Visible = false;
                }
                field(Offer_DisplayName; AppSourceProductManager.GetStringValue(ProductObject, 'displayName'))
                {
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the Display Name';
                }
                field(Offer_PublisherID; AppSourceProductManager.GetStringValue(ProductObject, 'publisherId'))
                {
                    Caption = 'Publisher ID';
                    ToolTip = 'Specifies the Publisher ID';
                    Visible = false;
                }
                field(Offer_PublisherDisplayName; AppSourceProductManager.GetStringValue(ProductObject, 'publisherDisplayName'))
                {
                    Caption = 'Publisher Display Name';
                    ToolTip = 'Specifies the Publisher Display Name';
                }
                field(Offer_PublisherType; AppSourceProductManager.GetStringValue(ProductObject, 'publisherType'))
                {
                    Caption = 'Publisher Type';
                    ToolTip = 'Specifies the Publisher Type';
                }
                field(Offer_LastModifiedDateTime; AppSourceProductManager.GetStringValue(ProductObject, 'lastModifiedDateTime'))
                {
                    Caption = 'Last Modified Date Time';
                    ToolTip = 'Specifies the Last Modified Date Time';
                }
            }
            group(DescriptionGroup)
            {
                ShowCaption = false;

                field(Description_Description; AppSourceProductManager.GetStringValue(ProductObject, 'description'))
                {
                    Caption = 'Description';
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Description';
                }
            }
            group(PlansGroup)
            {
                Caption = 'Plans';
                Visible = PlansAreVisible;

                field("PlansOverview"; PlansOverview)
                {
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    Caption = 'Plans Overview';
                    ToolTip = 'Specifies the overview of all plans';
                }
            }


            group(RatingGroup)
            {
                Caption = 'Rating';

                field(Rating_Popularity; AppSourceProductManager.GetStringValue(ProductObject, 'popularity'))
                {
                    Caption = 'Popularity';
                    ToolTip = 'Specifies the Popularity';
                }
                field(Rating_RatingAverage; AppSourceProductManager.GetStringValue(ProductObject, 'ratingAverage'))
                {
                    Caption = 'Rating Average';
                    ToolTip = 'Specifies the Rating Average';
                }
                field(Rating_RatingCount; AppSourceProductManager.GetStringValue(ProductObject, 'ratingCount'))
                {
                    Caption = 'Rating Count';
                    ToolTip = 'Specifies the Rating Count';
                }
            }


            group(LinksGroup)
            {
                Caption = 'Links';

                field(Links_LegalTermsUri; AppSourceProductManager.GetStringValue(ProductObject, 'legalTermsUri'))
                {
                    Caption = 'Legal Terms Uri';
                    ToolTip = 'Specifies the Legal Terms Uri';
                    ExtendedDatatype = Url;
                }
                field(Links_PrivacyPolicyUri; AppSourceProductManager.GetStringValue(ProductObject, 'privacyPolicyUri'))
                {
                    Caption = 'Privacy Policy Uri';
                    ToolTip = 'Specifies the Privacy Policy Uri';
                    ExtendedDatatype = Url;
                }
                field(Links_SupportUri; AppSourceProductManager.GetStringValue(ProductObject, 'supportUri'))
                {
                    Caption = 'Support Uri';
                    ToolTip = 'Specifies the Support Uri';
                    ExtendedDatatype = Url;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(Open_Promoted; OpenInAppSource) { }
            actionref(Install_Promoted; Install) { }
            actionref(Uninstall_Promoted; Uninstall) { }
        }

        area(Processing)
        {
            action(OpenInAppSource)
            {
                Caption = 'View in AppSource';
                Scope = Page;
                Image = Open;
                ToolTip = 'View app in AppSource';

                trigger OnAction()
                begin
                    AppSourceProductManager.OpenInAppSource(UniqueProductID);
                end;
            }

            action(Install)
            {
                Caption = 'Install App';
                Scope = Page;
                Enabled = CurrentRecordCanBeInstalled;
                Image = Insert;
                ToolTip = 'Install App';

                trigger OnAction()
                var
                    ExtensionManagement: Codeunit "Extension Management";
                begin
                    if not (CurrentRecordCanBeInstalled) then
                        exit;

                    if (PlansAreVisible) then
                        if not Confirm(PurchaseLicensesElsewhereLbl) then
                            exit;
                    ExtensionManagement.InstallMarketplaceExtension(AppID);
                end;
            }

            action(Uninstall)
            {
                Caption = 'Uninstall App';
                Scope = Page;
                Enabled = CurrentRecordCanBeUninstalled;
                Image = Delete;
                ToolTip = 'Uninstall App';
                AccessByPermission = TableData "Installed Application" = d;

                trigger OnAction()
                begin
                    ExtensionManagement.UninstallExtension(AppID, true);
                end;
            }
        }
    }

    var
        ExtensionManagement: Codeunit "Extension Management";
        AppSourceProductManager: Codeunit "AppSource Product Manager";
        ProductObject: JsonObject;
        UniqueProductID: Text;
        AppID: Text;
        CurrentRecordCanBeUninstalled: Boolean;
        CurrentRecordCanBeInstalled: Boolean;
        PlansOverview: Text;
        PlansAreVisible: Boolean;
        PurchaseLicensesElsewhereLbl: Label 'Installing this app may lead to undesired behavior if licenses are not purchaed before use. You must purchase licenses through Microsoft AppSource.\Do you want to continue with the installation?';
        PlanLinePrUserPrMonthLbl: Label '%1 %2 user/month', Comment = 'Price added a plan line, %1 is the currency, %2 is the price';
        PlanLinePrUserPrYearLbl: Label '%1 %2 user/year', Comment = 'Price added a plan line, %1 is the currency, %2 is the price';
        PlanLineFirstMonthIsFreeLbl: Label 'First month free', Comment = 'Added to the plan line when the first month is free.';
        PlanLinePostFillerIfFreeLbl: Label ', then ', Comment = 'Added to the plan line when the first month is free.';
        PlanLinePriceVariesLbl: Label 'Varies', Comment = 'Added to the plan line when the price varies.';
        PlanLinesTemplateLbl: Label '<table width="100%" padding="2" style="border-collapse:collapse;text-align:left;vertical-align:top;"><tr style="border-bottom: 1pt solid black;"><td>%1</td><td>%2</td><td>%3</td><td>%4</td></tr>%5</table>', Comment = 'Template for the plans section, %1 is the plans column header, %2 is the description column header, %3 is the monthly price column header, %4 is the yearly column header, %5 is the plan rows', Locked = true;
        PlanLineItemTemplateLbl: Label '<tr style="text-align:left;vertical-align:top;"><td>%1</td><td>%2</td><td>%3</td><td>%4</td></tr>', Comment = 'Template for a plan line item, %1 is the plan name, %2 is the plan description, %3 is the monthly price, %4 is the annual price', Locked = true;
        PlanLinesColumnPlansLbl: Label 'Plans', Comment = 'Column header for the plans section';
        PlanLinesColumnDescriptionLbl: Label 'Description', Comment = 'Column header for the plans section';
        PlanLinesColumnMonthlyPriceLbl: Label 'Monthly Price', Comment = 'Column header for the plans section';
        PlanLinesColumnAnnualPriceLbl: Label 'Annual Price', Comment = 'Column header for the plans section';

    procedure SetProduct(var ToProductObject: JsonObject)
    var
        ProductPlansToken: JsonToken;
    begin
        ProductObject := ToProductObject;
        UniqueProductID := AppSourceProductManager.GetStringValue(ProductObject, 'uniqueProductId');
        AppId := AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueProductID);
        CurrentRecordCanBeUninstalled := false;
        CurrentRecordCanBeInstalled := false;
        if (AppID <> '') then
            CurrentRecordCanBeUninstalled := ExtensionManagement.IsInstalledByAppID(AppID);

        if ProductObject.Get('plans', ProductPlansToken) then
            RenderPlans(ProductPlansToken);
    end;

    procedure RenderPlans(PlansObject: JsonToken)
    var
        AllPlans: JsonArray;
        PlanLinesBuilder: TextBuilder;
        PlanItem: JsonToken;
        PlanItemObject: JsonObject;
        PlanItemArray: JsonArray;
        MonthlyPriceText, YearlyPriceText : Text;
        i, availabilitiesAdded : Integer;
    begin
        availabilitiesAdded := 0;
        PlanLinesBuilder.Clear();

        AllPlans := PlansObject.AsArray();
        for i := 0 to AllPlans.Count() do
            if AllPlans.Get(i, PlanItem) then begin
                PlanItemObject := PlanItem.AsObject();
                if PlanItem.SelectToken('availabilities', PlanItem) then begin
                    PlanItemArray := PlanItem.AsArray();
                    if PlanItemArray.Count() > 0 then begin
                        if BuildPlanPriceText(PlanItemArray, MonthlyPriceText, YearlyPriceText) then
                            availabilitiesAdded += 1;
                        PlanLinesBuilder.Append(
                            StrSubstNo(
                                PlanLineItemTemplateLbl,
                                GetStringValue(PlanItemObject, 'displayName'),
                                GetStringValue(PlanItemObject, 'description'),
                                MonthlyPriceText,
                                YearlyPriceText));
                    end;
                end;
            end;

        if (availabilitiesAdded > 0) then begin
            PlansAreVisible := true;
            PlansOverview := StrSubstNo(
                PlanLinesTemplateLbl,
                PlanLinesColumnPlansLbl,
                PlanLinesColumnDescriptionLbl,
                PlanLinesColumnMonthlyPriceLbl,
                PlanLinesColumnAnnualPriceLbl,
                PlanLinesBuilder.ToText());
        end else begin
            PlansAreVisible := false;
            PlansOverview := '';
        end;

        CurrentRecordCanBeInstalled := (AppID <> '') and (not CurrentRecordCanBeUninstalled) and AppSourceProductManager.CanInstallProductWithPlans(AllPlans);
    end;

    local procedure BuildPlanPriceText(Availabilities: JsonArray; var MonthlyPriceText: Text; var YearlyPriceText: Text): Boolean
    var
        item: JsonToken;
        itemObject: JsonObject;
        item2: JsonToken;
        arrayItem: JsonArray;
        i: integer;
        currency: text;
        monthly, yearly : decimal;
        freeTrial: Boolean;
    begin
        freeTrial := false;
        for i := 0 to Availabilities.Count do
            if (Availabilities.Get(i, item)) then begin
                itemObject := item.AsObject();

                if (GetStringValue(itemObject, 'hasFreeTrials') = 'true') then
                    freeTrial := true;

                if (itemObject.Get('terms', item2)) then
                    if item2.IsArray then begin
                        arrayItem := item2.AsArray();
                        GetTerms(arrayItem, monthly, yearly, currency);
                    end;
            end;

        MonthlyPriceText := '';
        if freeTrial then begin
            MonthlyPriceText += PlanLineFirstMonthIsFreeLbl;
            MonthlyPriceText += PlanLinePostFillerIfFreeLbl;
            if (monthly <= 0) then
                MonthlyPriceText += PlanLinePriceVariesLbl;
        end;

        if (monthly > 0) then
            MonthlyPriceText += StrSubstNo(PlanLinePrUserPrMonthLbl, currency, FORMAT(monthly, 12, 2));

        YearlyPriceText := '';
        if freeTrial then begin
            YearlyPriceText += PlanLineFirstMonthIsFreeLbl;
            YearlyPriceText += PlanLinePostFillerIfFreeLbl;
            if (yearly <= 0) then
                YearlyPriceText += PlanLinePriceVariesLbl;
        end;

        if (yearly > 0) then
            YearlyPriceText += StrSubstNo(PlanLinePrUserPrYearLbl, currency, FORMAT(yearly, 12, 2));

        exit((monthly <> 0) or (yearly <> 0) or freeTrial);
    end;

    local procedure GetTerms(Terms: JsonArray; var Monthly: decimal; var Yearly: decimal; var Currency: Text)
    var
        item: JsonToken;
        priceToken: JsonToken;
        price: JsonObject;
        priceValue: Decimal;
        i: integer;
    begin
        for i := 0 to Terms.Count do
            if (Terms.Get(i, item)) then begin
                item.SelectToken('price', priceToken);
                price := priceToken.AsObject();
                Currency := GetStringValue(price, 'currencyCode');
                if not evaluate(priceValue, GetStringValue(price, 'listPrice')) then
                    priceValue := 0;

                case GetStringValue(item.AsObject(), 'termUnit') of
                    'P1Y':
                        Yearly := priceValue;
                    'P1M':
                        Monthly := priceValue;
                end;
            end;
    end;

    local procedure GetStringValue(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsText());
        exit('');
    end;

    procedure GetJsonValue(JsonObject: JsonObject; PropertyName: Text; var ReturnValue: JsonValue): Boolean
    var
        jsonToken: JsonToken;
    begin
        if jsonObject.Contains(PropertyName) then
            if jsonObject.Get(PropertyName, jsonToken) then
                if not jsonToken.AsValue().IsNull() then begin
                    ReturnValue := jsonToken.AsValue();
                    exit(true);
                end;
        exit(false);
    end;
}