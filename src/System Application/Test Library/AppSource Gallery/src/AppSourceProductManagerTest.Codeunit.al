// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Utilities;
using System.RestClient;
using System.Apps.AppSource;

/// <summary>
/// Library for managing AppSource product retrival and usage.
/// </summary>
codeunit 133920 "AppSource Product Manager Test"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AppSourceManagerTest: Codeunit "AppSource Product Manager";
        AppSourceJsonUtilities: Codeunit "AppSource Json Utilities";
        AppSourceUserSettingsHelper: Interface "Dependency Provider";
        IsUserSettingsProviderSet: boolean;
        CatalogProductsUriLbl: label 'https://catalogapi.azure.com/products', Locked = true;
        CatalogApiVersionQueryParamNameLbl: label 'api-version', Locked = true;
        CatalogApiVersionQueryParamValueLbl: label '2023-05-01-preview', Locked = true;
        CatalogApiOrderByQueryParamNameLbl: label '$orderby', Locked = true;
        CatalogMarketQueryParamNameLbl: label 'market', Locked = true;
        CatalogLanguageQueryParamNameLbl: label 'language', Locked = true;
        CatalogApiFilterQueryParamNameLbl: Label '$filter', Locked = true;
        CatalogApiSelectQueryParamNameLbl: Label '$select', Locked = true;
        AppSourceListingUriLbl: Label 'https://appsource.microsoft.com/%1/product/dynamics-365-business-central/%2', Comment = '%1=Language ID, such as en-US, %2=Url Query Content', Locked = true;
        AppSourceUriLbl: Label 'https://appsource.microsoft.com/%1/marketplace/apps?product=dynamics-365-business-central', Comment = '1%=Language ID, such as en-US', Locked = true;
        NotSupportedOnPremisesErrorLbl: Label 'Not supported on premises.';
        UnsupportedLanguageNotificationLbl: Label 'Language %1 is not supported by AppSource. Defaulting to "en". Change the language in the user profile to use another language.', Comment = '%1=Language ID, such as en';
        UnsupportedMarketNotificationLbl: Label 'Market %1 is not supported by AppSource. Defaulting to "us". Change the region in the user profile to use another market.', Comment = '%1=Market ID, such as "us"';

    #region Product helpers
    /// <summary>
    /// Opens Microsoft AppSource web page for the region is specified in the UserSessionSettings or 'en-us' by default.
    /// </summary>
    procedure OpenAppSource()
    begin
        AppSourceManagerTest.OpenAppSource();
    end;

    /// <summary>
    /// Opens the AppSource product page in Microsoft AppSource, for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product to show in MicrosoftAppSource</param>
    procedure OpenAppInAppSource(UniqueProductIDValue: Text)
    begin
        AppSourceManagerTest.OpenAppInAppSource(UniqueProductIDValue);
    end;

    /// <summary>
    /// Opens the AppSource product details page for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue"></param>
    procedure OpenProductDetailsPage(UniqueProductIDValue: Text)
    begin
        AppSourceManagerTest.OpenProductDetailsPage(UniqueProductIDValue);
    end;

    /// <summary>
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Guid
    begin
        AppSourceManagerTest.ExtractAppIDFromUniqueProductID(UniqueProductIDValue)
    end;
    #endregion

    #region Market and language helper functions
    procedure GetCurrentLanguageCultureName(): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetCultureName(GetCurrentUserLanguageID()));
    end;

    procedure ResolveMarketAndLanguage(var Market: Text; var LanguageName: Text)
    var
        Language: Codeunit Language;
        LanguageID, LocalID : integer;
    begin
        /*GetCurrentUserLanguageAnLocaleID(LanguageID, LocalID);

        // Marketplace API only supports two letter languages.
        LanguageName := Language.GetTwoLetterISOLanguageName(LanguageID);

        Market := '';
        if LocalID <> 0 then
            Market := ResolveMarketFromLanguageID(LocalID);
        if Market = '' then
            Market := CopyStr(AppSourceUserSettingsHelper.GetApplicationFamily(), 1, 2);
        if (Market = '') or (Market = 'W1') then
            if not TryGetEnvironmentCountryLetterCode(Market) then
                Market := 'us';

        Market := EnsureValidMarket(Market);
        LanguageName := EnsureValidLanguage(LanguageName);*/
    end;

    procedure GetCurrentUserLanguageID(): Integer
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
        LanguageID: Integer;
    begin
        AppSourceUserSettingsHelper.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(AppSourceUserSettingsHelper.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US
        exit(LanguageID);
    end;


    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    internal procedure GetProductsAndPopulateRecord(var AppSourceProductRec: record "AppSource Product"): Text
    var
        RestClient: Codeunit "Rest Client";
        NextPageLink: text;
    begin
        /*NextPageLink := ConstructProductListUri();

        RestClient.Initialize();
        SetCommonHeaders(RestClient);

        repeat
            NextPageLink := DownloadAndAddNextPageProducts(NextPageLink, AppSourceProductRec, RestClient);
        until NextPageLink = '';*/
    end;

    procedure InitDependencies(AppSourceDependencyProvider: Codeunit "Test Dependency Provider")
    var
    //AppSourceDependencyProvider: Codeunit "Test Dependency Provider";
    begin
        AppSourceManagerTest.SetDependencies(AppSourceDependencyProvider);
    end;
    #endregion

}