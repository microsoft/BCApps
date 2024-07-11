// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Azure.Identity;
using System.Utilities;
using System.Azure.KeyVault;
using System.RestClient;
using System.Environment;

/// <summary>
/// Library for managing AppSource product retrieval and usage.
/// </summary>
codeunit 2515 "AppSource Product Manager"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AppSourceJsonUtilities: Codeunit "AppSource Json Utilities";
        AppSourceProductManagerDependencies: Interface "AppSource Product Manager Dependencies";
        IsDependenciesInterfaceSet: Boolean;
        CatalogProductsUriLbl: Label 'https://catalogapi.azure.com/products', Locked = true;
        CatalogApiVersionQueryParamNameLbl: Label 'api-version', Locked = true;
        CatalogApiVersionQueryParamValueLbl: Label '2023-05-01-preview', Locked = true;
        CatalogApiOrderByQueryParamNameLbl: Label '$orderby', Locked = true;
        CatalogMarketQueryParamNameLbl: Label 'market', Locked = true;
        CatalogLanguageQueryParamNameLbl: Label 'language', Locked = true;
        CatalogApiFilterQueryParamNameLbl: Label '$filter', Locked = true;
        CatalogApiSelectQueryParamNameLbl: Label '$select', Locked = true;
        AppSourceListingUriLbl: Label 'https://appsource.microsoft.com/%1/product/dynamics-365-business-central/%2', Comment = '%1=Language ID, such as en-US, %2=Url Query Content', Locked = true;
        AppSourceUriLbl: Label 'https://appsource.microsoft.com/%1/marketplace/apps?product=dynamics-365-business-central', Comment = '1%=Language ID, such as en-US', Locked = true;
        NotSupportedOnPremisesErrorLbl: Label 'Not supported on premises.';
        UnsupportedLanguageNotificationLbl: Label 'Language %1 is not supported by AppSource. Defaulting to "en". Change the language in the user profile to use another language.', Comment = '%1=Language ID, such as en';

    #region Product helpers
    /// <summary>
    /// Opens Microsoft AppSource web page for the region is specified in the UserSessionSettings or 'en-us' by default.
    /// </summary>
    procedure OpenAppSource()
    begin
        Init();
        Hyperlink(StrSubstNo(AppSourceUriLbl, AppSourceProductManagerDependencies.GetFormatRegionOrDefault('')));
    end;

    /// <summary>
    /// Opens the AppSource product page in Microsoft AppSource, for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product to show in MicrosoftAppSource</param>
    procedure OpenAppInAppSource(UniqueProductIDValue: Text)
    begin
        Init();
        Hyperlink(StrSubstNo(AppSourceListingUriLbl, GetCurrentLanguageCultureName(), UniqueProductIDValue));
    end;

    /// <summary>
    /// Opens the AppSource product details page for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue"></param>
    internal procedure OpenProductDetailsPage(UniqueProductIDValue: Text)
    var
        AppSourceProductDetailsPage: Page "AppSource Product Details";
        ProductObject: JsonObject;
    begin
        ProductObject := GetProductDetails(UniqueProductIDValue);
        AppSourceProductDetailsPage.SetProduct(ProductObject);
        AppSourceProductDetailsPage.RunModal();
    end;

    /// <summary>
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    internal procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Guid
    var
        AppIDPos: Integer;
        EmptyGuid: Guid;
    begin
        AppIDPos := StrPos(UniqueProductIDValue, 'PAPPID.');
        if (AppIDPos > 0) then
            exit(CopyStr(UniqueProductIDValue, AppIDPos + 7, 36));
        exit(EmptyGuid);
    end;

    /// <summary>
    /// Checks if the product can be installed or your are required to perform operations on AppSource before you can install the product.
    /// </summary>
    /// <param name="Plans">JSonArray representing the product plans</param>
    /// <returns>True if the product can be installed, otherwise false</returns>
    internal procedure CanInstallProductWithPlans(Plans: JsonArray): Boolean
    var
        PlanToken: JsonToken;
        PlanObject: JsonObject;
        PricingTypesToken: JsonToken;
        PricingTypes: JsonArray;
        PricingType: JsonToken;
    begin
        foreach PlanToken in Plans do begin
            PlanObject := PlanToken.AsObject();

            if PlanObject.Get('pricingTypes', PricingTypesToken) then
                if (PricingTypesToken.IsArray()) then begin
                    PricingTypes := PricingTypesToken.AsArray();
                    if PricingTypes.Count() = 0 then
                        exit(false); // No price structure, you need to contact the publisher

                    foreach PricingType in PricingTypes do
                        case LowerCase(PricingType.AsValue().AsText()) of
                            'free', // Free
                            'freetrial', // Free trial
                            'payg', // Pay as you go
                            'byol': // Bring your own license
                                exit(true);
                        end;
                end;
        end;

        exit(false);
    end;
    #endregion

    #region Market and language helper functions
    procedure GetCurrentLanguageCultureName(): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetCultureName(GetCurrentUserLanguageID()));
    end;

    procedure ResolveMarketAndLanguage(var Market: Code[2]; var LanguageName: Text)
    var
        Language: Codeunit Language;
        LanguageID: Integer;
    begin
        GetCurrentUserLanguageAndLocaleID(LanguageID, Market);

        // Marketplace API only supports two letter languages.
        LanguageName := Language.GetTwoLetterISOLanguageName(LanguageID);
        LanguageName := EnsureValidLanguage(LanguageName);
    end;

    procedure GetCurrentUserLanguageID(): Integer
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
        LanguageID: Integer;
    begin
        AppSourceProductManagerDependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(AppSourceProductManagerDependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US
        exit(LanguageID);
    end;

    local procedure GetCurrentUserLanguageAndLocaleID(var LanguageID: Integer; var LocaleID: Code[2])
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
    begin
        AppSourceProductManagerDependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(AppSourceProductManagerDependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US

        LocaleID := AppSourceProductManagerDependencies.GetCountryLetterCode();
    end;

    /// <summary>
    /// Ensures that the language is valid for AppSource.
    /// </summary>
    /// <param name="Language">Language requested</param>
    /// <returns>The requested language if supported otherwise en</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/rest/api/marketplacecatalog/dataplane/products/list?view=rest-marketplacecatalog-dataplane-2023-05-01-preview&amp;tabs=HTTP for supported languages</remarks>
    local procedure EnsureValidLanguage(Language: Text): Text
    var
        NotSupportedNotification: Notification;
    begin
        case LowerCase(Language) of
            'en', 'cs', 'de', 'es', 'fr', 'hu', 'it', 'ja', 'ko', 'nl', 'pl', 'pt-br', 'pt-pt', 'ru', 'sv', 'tr', 'zh-hans', 'zh-hant':
                exit(LowerCase(Language));
            else begin
                NotSupportedNotification.Id := '0664870f-bd05-46cc-9e98-cc338d7fdc64';
                NotSupportedNotification.Message(StrSubstNo(UnsupportedLanguageNotificationLbl, Language));
                NotSupportedNotification.Send();

                exit('en');
            end;
        end;
    end;
    #endregion

    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    internal procedure GetProductsAndPopulateRecord(var AppSourceProductRec: Record "AppSource Product"): Text
    var
        RestClient: Codeunit "Rest Client";
        NextPageLink: Text;
    begin
        Init();
        NextPageLink := ConstructProductListUri();

        RestClient.Initialize();
        if not AppSourceProductManagerDependencies.IsSaas() then
            Error(NotSupportedOnPremisesErrorLbl);

        if AppSourceProductManagerDependencies.ShouldSetCommonHeaders() then
            SetCommonHeaders(RestClient);

        repeat
            NextPageLink := DownloadAndAddNextPageProducts(NextPageLink, AppSourceProductRec, RestClient);
        until NextPageLink = '';
    end;

    /// <summary>
    /// Get specific product details from.
    /// </summary>
    local procedure GetProductDetails(UniqueProductIDValue: Text): JsonObject
    var
        RestClient: Codeunit "Rest Client";
        RequestUri: Text;
        ClientRequestID: Guid;
        TelemetryDictionary: Dictionary of [Text, Text];
    begin
        Init();
        ClientRequestID := CreateGuid();
        RequestUri := ConstructProductUri(UniqueProductIDValue);

        PopulateTelemetryDictionary(ClientRequestID, UniqueProductIDValue, RequestUri, TelemetryDictionary);
        Session.LogMessage('AL:AppSource-GetProduct', 'Requesting product details.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);

        RestClient.Initialize();
        if not AppSourceProductManagerDependencies.IsSaas() then
            Error(NotSupportedOnPremisesErrorLbl);

        if AppSourceProductManagerDependencies.ShouldSetCommonHeaders() then
            SetCommonHeaders(RestClient);

        RestClient.SetDefaultRequestHeader('client-request-id', ClientRequestID);

        exit(AppSourceProductManagerDependencies.GetAsJSon(RestClient, RequestUri).AsObject());
    end;

    local procedure DownloadAndAddNextPageProducts(NextPageLink: Text; var AppSourceProductRec: Record "AppSource Product"; var RestClient: Codeunit "Rest Client"): Text
    var
        ResponseObject: JsonObject;
        ProductArray: JsonArray;
        ProductArrayToken: JsonToken;
        ProductToken: JsonToken;
        I: Integer;
        ClientRequestID: Guid;
        TelemetryDictionary: Dictionary of [Text, Text];
    begin
        ClientRequestID := CreateGuid();
        PopulateTelemetryDictionary(ClientRequestID, '', NextPageLink, TelemetryDictionary);
        Session.LogMessage('AL:AppSource-NextPageProducts', 'Requesting product list data', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);
        RestClient.SetDefaultRequestHeader('client-request-id', ClientRequestID);

        ResponseObject := AppSourceProductManagerDependencies.GetAsJSon(RestClient, NextPageLink).AsObject();
        if (ResponseObject.Get('items', ProductArrayToken)) then begin
            ProductArray := ProductArrayToken.AsArray();
            for i := 0 to (ProductArray.Count() - 1) do
                if (ProductArray.Get(i, ProductToken)) then
                    InsertProductFromObject(ProductToken.AsObject(), AppSourceProductRec);
        end;
        exit(AppSourceJsonUtilities.GetStringValue(ResponseObject, 'nextPageLink'));
    end;

    [NonDebuggable]
    internal procedure SetCommonHeaders(var RestClient: Codeunit "Rest Client")
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        ApiKey: SecretText;
    begin
        AzureKeyVault.GetAzureKeyVaultSecret('MS-AppSource-ApiKey', ApiKey);

        RestClient.SetDefaultRequestHeader('X-API-Key', ApiKey);
        RestClient.SetDefaultRequestHeader('x-ms-client-tenant-id', AzureAdTenant.GetAadTenantID());
        RestClient.SetDefaultRequestHeader('x-ms-app', 'Dynamics 365 Business Central');
    end;

    local procedure ConstructProductListUri(): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        Language: Text;
        Market: Code[2];
    begin
        ResolveMarketAndLanguage(Market, Language);

        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);

        UriBuilder.AddODataQueryParameter(CatalogApiFilterQueryParamNameLbl, 'productType eq ''DynamicsBC''');
        UriBuilder.AddODataQueryParameter(CatalogApiSelectQueryParamNameLbl, 'uniqueProductID,displayName,publisherID,publisherDisplayName,publisherType,ratingAverage,ratingCount,productType,popularity,privacyPolicyUri,lastModifiedDateTime');
        UriBuilder.AddODataQueryParameter(CatalogApiOrderByQueryParamNameLbl, 'displayName asc');

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    local procedure ConstructProductUri(UniqueIdentifier: Text): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        Language: Text;
        Market: Code[2];
    begin
        ResolveMarketAndLanguage(Market, Language);
        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.SetPath('products/' + UniqueIdentifier);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);
        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    #region Telemetry helpers
    local procedure PopulateTelemetryDictionary(RequestID: Text; UniqueIdentifier: Text; Uri: Text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        PopulateTelemetryDictionary(RequestID, telemetryDictionary);
        TelemetryDictionary.Add('UniqueIdentifier', UniqueIdentifier);
        TelemetryDictionary.Add('Uri', Uri);
    end;

    local procedure PopulateTelemetryDictionary(RequestID: Text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        TelemetryDictionary.Add('client-request-id', RequestID);
    end;
    #endregion

    local procedure InsertProductFromObject(Offer: JsonObject; var AppSourceProduct: Record "AppSource Product")
    begin
        AppSourceProduct.Init();
        AppSourceProduct.UniqueProductID := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'uniqueProductId'), 1, MaxStrLen(AppSourceProduct.UniqueProductID));
        AppSourceProduct.DisplayName := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'displayName'), 1, MaxStrLen(AppSourceProduct.DisplayName));
        AppSourceProduct.PublisherID := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherId'), 1, MaxStrLen(AppSourceProduct.PublisherID));
        AppSourceProduct.PublisherDisplayName := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherDisplayName'), 1, MaxStrLen(AppSourceProduct.PublisherDisplayName));
        AppSourceProduct.PublisherType := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'publisherType'), 1, MaxStrLen(AppSourceProduct.PublisherType));
        AppSourceProduct.RatingAverage := AppSourceJsonUtilities.GetDecimalValue(Offer, 'ratingAverage');
        AppSourceProduct.RatingCount := AppSourceJsonUtilities.GetIntegerValue(Offer, 'ratingCount');
        AppSourceProduct.ProductType := CopyStr(AppSourceJsonUtilities.GetStringValue(Offer, 'productType'), 1, MaxStrLen(AppSourceProduct.ProductType));
        AppSourceProduct.Popularity := AppSourceJsonUtilities.GetDecimalValue(Offer, 'popularity');
        AppSourceProduct.LastModifiedDateTime := AppSourceJsonUtilities.GetDateTimeValue(Offer, 'lastModifiedDateTime');

        AppSourceProduct.AppID := ExtractAppIDFromUniqueProductID(AppSourceProduct.UniqueProductID);

        // Insert, if it fails to insert due to the data (ex duplicate ids), ignore the error
        if not AppSourceProduct.Insert() then;
    end;

    local procedure Init()
    begin
        if not IsDependenciesInterfaceSet then
            SetDefaultDependencyImplementation();
    end;

    local procedure SetDefaultDependencyImplementation()
    var
        AppSrcProductDepsProvider: Codeunit "AppSrc Product Deps. Provider";
    begin
        SetDependencies(AppSrcProductDepsProvider);
    end;

    internal procedure SetDependencies(AppSourceProductManagerDependencyProvider: Interface "AppSource Product Manager Dependencies")
    begin
        AppSourceProductManagerDependencies := AppSourceProductManagerDependencyProvider;
        IsDependenciesInterfaceSet := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", OpenAppSourceMarket, '', false, false)]
    local procedure OpenAppSourceMarket()
    begin
        Page.Run(Page::"AppSource Product List");
    end;
}
