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
                AccessByPermission = TableData "Installed Application" = i;
                Visible = false;

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
        PurchaseLicensesElsewhereLbl: Label 'Installing this app may lead to an undesired if licenses are not purchaed before use. You must purchase licenses through Microsoft AppSource.\Do you want to continue with the installation?';

    procedure SetProduct(var ToProductObject: JsonObject)
    var
        ProductPlansToken: JsonToken;
    begin
        ProductObject := ToProductObject;
        UniqueProductID := AppSourceProductManager.GetStringValue(ProductObject, 'uniqueProductId');
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
        PlansOverviewBuilder: TextBuilder;
        PlanItem: JsonToken;
        PlanItemObject: JsonObject;
        PlanItemArray: JsonArray;
        i, availabilitiesAdded : Integer;
    begin
        availabilitiesAdded := 0;
        PlansOverviewBuilder.Clear();

        AllPlans := PlansObject.AsArray();
        PlansOverviewBuilder.Append('<table width="100%" padding="2" style="border-collapse:collapse;text-align:left;vertical-align:top;">');
        PlansOverviewBuilder.Append('<tr style="border-bottom: 1pt solid black;"><td>Plan</td><td>Description</td><td>Monthly Price</td><td>Annual Price</td></tr>');
        for i := 0 to AllPlans.Count() do
            if AllPlans.Get(i, PlanItem) then begin
                PlanItemObject := PlanItem.AsObject();
                if PlanItem.SelectToken('availabilities', PlanItem) then begin
                    PlanItemArray := PlanItem.AsArray();
                    if PlanItemArray.Count() > 0 then begin
                        PlansOverviewBuilder.Append('<tr style="text-align:left;vertical-align:top;">');
                        PlansOverviewBuilder.Append('<td>');
                        PlansOverviewBuilder.Append(GetStringValue(PlanItemObject, 'displayName'));
                        PlansOverviewBuilder.Append('</td>');
                        PlansOverviewBuilder.Append('<td>');
                        PlansOverviewBuilder.Append(GetStringValue(PlanItemObject, 'description'));
                        PlansOverviewBuilder.Append('</td>');
                        if RenderAvailabilities(PlanItemArray, PlansOverviewBuilder) then
                            availabilitiesAdded += 1;

                    end;

                    PlansOverviewBuilder.AppendLine('</tr>');
                end;
            end;
        PlansOverviewBuilder.Append('</table>');

        if (availabilitiesAdded > 0) then begin
            PlansAreVisible := true;
            PlansOverview := PlansOverviewBuilder.ToText();
            CurrentRecordCanBeInstalled := true;
        end else begin
            PlansAreVisible := false;
            PlansOverview := '';
        end;
    end;

    local procedure RenderAvailabilities(Availabilities: JsonArray; var Builder: TextBuilder): Boolean
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

        Builder.Append('<td>');
        if freeTrial then
            Builder.Append('First month free');

        if (monthly > 0) or freeTrial then begin
            if freeTrial then
                Builder.Append(', then ');
            Builder.Append(currency);
            builder.Append(' ');
            Builder.Append(FORMAT(monthly, 12, 2));
            Builder.Append(' user/month');
        end else
            if freeTrial then
                Builder.Append('Varies');

        Builder.Append('</td><td>');
        if freeTrial then
            Builder.Append('First month free');
        if (yearly > 0) or freeTrial then begin
            if freeTrial then
                Builder.Append(', then ');
            Builder.Append(currency);
            builder.Append(' ');
            Builder.Append(FORMAT(yearly, 12, 2));
            Builder.Append(' user/year');
        end else
            Builder.Append('Varies');

        exit((monthly <> 0) or (yearly <> 0) or freeTrial);
    end;

    local procedure GetTerms(Terms: JsonArray; var Monthly: decimal; var Yearly: decimal; Currency: Text)
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