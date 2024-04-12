// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license inFormation.
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
    DataCaptionExpression = AppSourceJsonUtilities.GetStringValue(ProductObject, 'displayName');

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
                    ToolTip = 'Specifies the unique product identifier.';
                    Visible = false;
                }
                field(Offer_ProductType; AppSourceJsonUtilities.GetStringValue(ProductObject, 'productType'))
                {
                    Caption = 'Product Type';
                    ToolTip = 'Specifies the delivery method or deployment mode of the offer.';
                    Visible = false;
                }
                field(Offer_DisplayName; AppSourceJsonUtilities.GetStringValue(ProductObject, 'displayName'))
                {
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the display name of the offer.';
                }
                field(Offer_PublisherID; AppSourceJsonUtilities.GetStringValue(ProductObject, 'publisherId'))
                {
                    Caption = 'Publisher ID';
                    ToolTip = 'Specifies the ID of the publisher.';
                    Visible = false;
                }
                field(Offer_PublisherDisplayName; AppSourceJsonUtilities.GetStringValue(ProductObject, 'publisherDisplayName'))
                {
                    Caption = 'Publisher Display Name';
                    ToolTip = 'Specifies the display name of the publisher.';
                }
                field(Offer_PublisherType; AppSourceJsonUtilities.GetStringValue(ProductObject, 'publisherType'))
                {
                    Caption = 'Publisher Type';
                    ToolTip = 'Specifies whether the offer is a Microsoft or third party product.';
                }
                field(Offer_LastModifiedDateTime; AppSourceJsonUtilities.GetStringValue(ProductObject, 'lastModifiedDateTime'))
                {
                    Caption = 'Last Modified Date Time';
                    ToolTip = 'Specifies the date the offer was last updated.';
                }
            }
            group(DescriptionGroup)
            {
                ShowCaption = false;

                field(Description_Description; AppSourceJsonUtilities.GetStringValue(ProductObject, 'description'))
                {
                    Caption = 'Description';
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description text of the offer.';
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
                    ToolTip = 'Specifies the overview of all the plans available for the offer.';
                }
            }

            group(RatingGroup)
            {
                Caption = 'Rating';

                field(Rating_Popularity; AppSourceJsonUtilities.GetStringValue(ProductObject, 'popularity'))
                {
                    Caption = 'Popularity';
                    ToolTip = 'Specifies a value from 0-10 indicating the popularity of the offer.';
                }
                field(Rating_RatingAverage; AppSourceJsonUtilities.GetStringValue(ProductObject, 'ratingAverage'))
                {
                    Caption = 'Rating Average';
                    ToolTip = 'Specifies a value from 0-5 indicating the average user rating.';
                }
                field(Rating_RatingCount; AppSourceJsonUtilities.GetStringValue(ProductObject, 'ratingCount'))
                {
                    Caption = 'Rating Count';
                    ToolTip = 'Specifies the number of users that have rated the offer.';
                }
            }

            group(LinksGroup)
            {
                Caption = 'Links';

                field(Links_LegalTermsUri; AppSourceJsonUtilities.GetStringValue(ProductObject, 'legalTermsUri'))
                {
                    Caption = 'Legal Terms Uri';
                    ToolTip = 'Specifies the legal terms of the offer.';
                    ExtendedDatatype = URL;
                }
                field(Links_PrivacyPolicyUri; AppSourceJsonUtilities.GetStringValue(ProductObject, 'privacyPolicyUri'))
                {
                    Caption = 'Privacy Policy Uri';
                    ToolTip = 'Specifies the privacy policy of the offer.';
                    ExtendedDatatype = URL;
                }
                field(Links_SupportUri; AppSourceJsonUtilities.GetStringValue(ProductObject, 'supportUri'))
                {
                    Caption = 'Support Uri';
                    ToolTip = 'Specifies the support Uri of the offer.';
                    ExtendedDatatype = URL;
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
            actionref(InstallFromAppSource_Promoted; InstallFromAppSource) { }
            actionref(Uninstall_Promoted; Uninstall) { }
        }

        area(Processing)
        {
            action(OpenInAppSource)
            {
                Caption = 'View in AppSource';
                Scope = Page;
                Image = Open;
                ToolTip = 'Opens the app offer in the AppSource marketplace.';

                trigger OnAction()
                begin
                    AppSourceProductManager.OpenAppInAppSource(UniqueProductID);
                end;
            }

            action(Install)
            {
                Caption = 'Install App';
                Scope = Page;
                Enabled = (not CurrentRecordCanBeUninstalled) and CurrentRecordCanBeInstalled;
                Visible = (not CurrentRecordCanBeUninstalled) and CurrentRecordCanBeInstalled;
                Image = Insert;
                ToolTip = 'Installs the app.';

                trigger OnAction()
                var
                    ExtensionManagement: Codeunit "Extension Management";
                begin
                    if (PlansAreVisible) then
                        if not Confirm(PurchaseLicensesElsewhereLbl) then
                            exit;
                    ExtensionManagement.InstallMarketplaceExtension(AppID);
                end;
            }

            action(InstallFromAppSource)
            {
                Caption = 'Install From AppSource';
                Scope = Page;
                Image = Insert;
                ToolTip = 'Installs the app from Microsoft AppSource.';
                Enabled = (not CurrentRecordCanBeUninstalled) and (not CurrentRecordCanBeInstalled);
                Visible = (not CurrentRecordCanBeUninstalled) and (not CurrentRecordCanBeInstalled);

                trigger OnAction()
                begin
                    AppSourceProductManager.OpenAppInAppSource(UniqueProductID);
                end;
            }

            action(Uninstall)
            {
                Caption = 'Uninstall App';
                Scope = Page;
                Enabled = CurrentRecordCanBeUninstalled;
                Image = Delete;
                ToolTip = 'Uninstalls the app.';
                AccessByPermission = tabledata "Installed Application" = d;

                trigger OnAction()
                begin
                    ExtensionManagement.UninstallExtension(AppID, true);
                end;
            }
        }
    }

    var
        AppSourceJsonUtilities: Codeunit "AppSource Json Utilities";
        ExtensionManagement: Codeunit "Extension Management";
        AppSourceProductManager: Codeunit "AppSource Product Manager";
        ProductObject: JsonObject;
        UniqueProductID: Text;
        AppID: Text;
        CurrentRecordCanBeUninstalled: Boolean;
        CurrentRecordCanBeInstalled: Boolean;
        PlansOverview: Text;
        PlansAreVisible: Boolean;
        PurchaseLicensesElsewhereLbl: Label 'Installing this app might lead to undesired behavior if licenses are not purchased before use. You must purchase licenses through Microsoft AppSource.\Do you want to continue with the installation?';
        PlanLinePrUserPrMonthLbl: Label '%1 %2 user/month', Comment = 'Price added a plan line, %1 is the currency code, such as USD or IDR, %2 is the price';
        PlanLinePrUserPrYearLbl: Label '%1 %2 user/year', Comment = 'Price added a plan line, %1 is the currency code, such as USD or IDR, %2 is the price';
        PlanLineFirstMonthIsFreeLbl: Label 'First month free, then %1.', Comment = 'Added to the plan line when the first month is free, %1 is the plan after the trial period.';
        PlanLinePriceVariesLbl: Label 'varies', Comment = 'Added to the plan line when the price varies.';
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
        UniqueProductID := AppSourceJsonUtilities.GetStringValue(ProductObject, 'uniqueProductId');
        AppId := AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueProductID);
        CurrentRecordCanBeUninstalled := false;
        CurrentRecordCanBeInstalled := false;
        if (not IsNullGuid(AppID)) then
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
        i, AvailabilitiesAdded : Integer;
    begin
        AvailabilitiesAdded := 0;
        PlanLinesBuilder.Clear();

        AllPlans := PlansObject.AsArray();
        for i := 0 to AllPlans.Count() do
            if AllPlans.Get(i, PlanItem) then begin
                PlanItemObject := PlanItem.AsObject();
                if PlanItem.SelectToken('availabilities', PlanItem) then begin
                    PlanItemArray := PlanItem.AsArray();
                    if PlanItemArray.Count() > 0 then begin
                        if BuildPlanPriceText(PlanItemArray, MonthlyPriceText, YearlyPriceText) then
                            AvailabilitiesAdded += 1;
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

        if AvailabilitiesAdded > 0 then begin
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
        Availability: JsonToken;
        AvailabilityObject: JsonObject;
        TermItem: JsonToken;
        ArrayItem: JsonArray;
        i: Integer;
        Currency: Text;
        Monthly, Yearly : Decimal;
        FreeTrial: Boolean;
        PriceText: Text;
    begin
        FreeTrial := false;
        for i := 0 to Availabilities.Count do
            if Availabilities.Get(i, Availability) then begin
                AvailabilityObject := Availability.AsObject();

                if (GetStringValue(AvailabilityObject, 'hasFreeTrials') = 'true') then
                    FreeTrial := true;

                if (AvailabilityObject.Get('terms', TermItem)) then
                    if TermItem.IsArray then begin
                        ArrayItem := TermItem.AsArray();
                        GetTerms(ArrayItem, Monthly, Yearly, Currency);
                    end;
            end;

        YearlyPriceText := '';
        MonthlyPriceText := '';
        if (Monthly = 0) or (Yearly = 0) or not FreeTrial then
            exit(false);

        if FreeTrial then begin
            if Monthly > 0 then begin
                PriceText := StrSubstNo(PlanLinePrUserPrMonthLbl, Currency, Format(Monthly, 12, 2));
                MonthlyPriceText := StrSubstNo(PlanLineFirstMonthIsFreeLbl, PriceText)
            end
            else
                MonthlyPriceText := StrSubstNo(PlanLineFirstMonthIsFreeLbl, PlanLinePriceVariesLbl);
            if Yearly > 0 then begin
                PriceText := StrSubstNo(PlanLinePrUserPrYearLbl, Currency, Format(Yearly, 12, 2));
                YearlyPriceText := StrSubstNo(PlanLineFirstMonthIsFreeLbl, PriceText)
            end
            else
                YearlyPriceText := StrSubstNo(PlanLineFirstMonthIsFreeLbl, PlanLinePriceVariesLbl);
        end
        else begin
            if Monthly > 0 then
                MonthlyPriceText := StrSubstNo(PlanLinePrUserPrMonthLbl, Currency, Format(Monthly, 12, 2));
            if Yearly > 0 then
                YearlyPriceText := StrSubstNo(PlanLinePrUserPrYearLbl, Currency, Format(Yearly, 12, 2));
        end;

        exit(true);
    end;

    local procedure GetTerms(Terms: JsonArray; var Monthly: Decimal; var Yearly: Decimal; var Currency: Text)
    var
        Item: JsonToken;
        PriceToken: JsonToken;
        Price: JsonObject;
        PriceValue: Decimal;
        i: Integer;
    begin
        for i := 0 to Terms.Count() do
            if (Terms.Get(i, Item)) then begin
                Item.SelectToken('price', PriceToken);
                Price := PriceToken.AsObject();
                Currency := GetStringValue(Price, 'currencyCode');
                if not evaluate(PriceValue, GetStringValue(Price, 'listPrice')) then
                    PriceValue := 0;

                case GetStringValue(Item.AsObject(), 'termUnit') of
                    'P1Y':
                        Yearly := PriceValue;
                    'P1M':
                        Monthly := PriceValue;
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
        JsonToken: JsonToken;
    begin
        if JsonObject.Contains(PropertyName) then
            if JsonObject.Get(PropertyName, JsonToken) then
                if not JsonToken.AsValue().IsNull() then begin
                    ReturnValue := JsonToken.AsValue();
                    exit(true);
                end;
        exit(false);
    end;
}
