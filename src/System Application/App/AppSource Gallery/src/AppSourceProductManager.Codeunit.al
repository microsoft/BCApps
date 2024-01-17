
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;
using System.Azure.IDentity;
using System.Utilities;
using System.Environment;
using System.Azure.KeyVault;
using System.RestClient;
using System.Apps;

/// <summary>
/// Library for managing AppSource product retrival and usage.
/// </summary>
codeunit 2515 "AppSource Product Manager"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Product helpers 
    /// <summary>
    /// Opens Microsoft AppSource web page.
    /// </summary>
    procedure OpenAppSource()
    begin
        Hyperlink(StrSubstNo(AppSourceUriLbl, GetCurrentUserFormatRegion()));
    end;


    /// <summary>
    /// Opens the AppSource product page in Microsoft AppSource, for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product to show in MicrosoftAppSource</param>
    procedure OpenInAppSource(UniqueProductIDValue: Text)
    begin
        Hyperlink(StrSubstNo(AppSourceListingUriLbl, GetCurrentUserFormatRegion(), UniqueProductIDValue));
    end;

    /// <summary>
    /// Opens the AppSource product details page for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue"></param>
    procedure OpenProductDetailsPage(UniqueProductIDValue: Text)
    var
        ProductDetailsPage: Page "AppSource Product Details";
        ProductObject: JsonObject;
    begin
        ProductObject := GetProductDetails(UniqueProductIDValue);
        ProductDetailsPage.SetProduct(ProductObject);
        ProductDetailsPage.RunModal();
    end;

    /// <summary>
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Text[36]
    var
        AppIDPos: Integer;
    begin
        AppIDPos := StrPos(UniqueProductIDValue, 'PAPPID.');
        if (AppIDPos > 0) then
            exit(CopyStr(UniqueProductIDValue, AppIDPos + 7, 36));
        exit('');
    end;

    /// <summary>
    /// Installs the product with the specified AppID.
    /// </summary>
    procedure InstallProduct(AppIDToInstall: Guid)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        ExtensionManagement.InstallMarketplaceExtension(AppIDToInstall);
    end;
    #endregion

    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    procedure GetProductsAndPopulateRecord(var AppSourceProductRec: record "AppSource Product"): Text
    var
        NextPageLink: text;
    begin
        NextPageLink := ConstructProductListUri();

        repeat
            NextPageLink := DownloadAndAddNextPageProducts(NextPageLink, AppSourceProductRec);
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
        ClientRequestID := CreateGuid();
        PopulateTelemetryDictionary(ClientRequestID, UniqueProductIDValue, TelemetryDictionary);
        Session.LogMessage('AL:AppSource-GetProduct', 'Requesting product data for', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);

        RequestUri := ConstructProductUri(UniqueProductIDValue);
        RestClient.Initialize();
        SetCommonHeaders(RestClient, ClientRequestID);

        exit(restClient.GetAsJson(requestUri).AsObject());
    end;

    local procedure DownloadAndAddNextPageProducts(NextPageLink: Text; var AppSourceProductRec: record "AppSource Product"): Text
    var
        RestClient: Codeunit "Rest Client";
        ResponseObject: JsonObject;
        ProductArray: JsonArray;
        ProductArrayToken: JsonToken;
        ProductToken: JsonToken;
        I: Integer;
        ClientRequestID: Guid;
        TelemetryDictionary: Dictionary of [Text, Text];
    begin
        ClientRequestID := CreateGuid();
        PopulateTelemetryDictionary(ClientRequestID, '', TelemetryDictionary);
        Session.LogMessage('AL:AppSource-NextPageProducts', 'Requesting product data for', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDictionary);

        RestClient.Initialize();
        SetCommonHeaders(RestClient, ClientRequestID);
        ResponseObject := RestClient.GetAsJson(NextPageLink).AsObject();
        if (ResponseObject.Get('items', ProductArrayToken)) then begin
            ProductArray := ProductArrayToken.AsArray();
            for i := 0 to ProductArray.Count() do
                if (ProductArray.Get(i, ProductToken)) then
                    InsertProductFromObject(ProductToken.AsObject(), AppSourceProductRec);
        end;
        exit(GetStringValue(ResponseObject, 'nextPageLink'));
    end;

    local procedure SetCommonHeaders(var RestClient: Codeunit "Rest Client"; ClientRequestID: Guid)
    var
        AzureADTenant: codeunit "Azure AD Tenant";
    begin
        RestClient.SetDefaultRequestHeader('X-API-Key', GetAPIKey());
        RestClient.SetDefaultRequestHeader('x-ms-client-tenant-id', AzureADTenant.GetAadTenantID());
        RestClient.SetDefaultRequestHeader('x-ms-app', 'Dynamics 365 Business Central');
        RestClient.SetDefaultRequestHeader('x-ms-client-request-id', ClientRequestID);
    end;

    local procedure ConstructProductListUri(): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        QueryPart: Text;
        Language: Text[2];
        Market: Text[2];
    begin
        ResolveMarketAndLanguage(Market, Language);

        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);

        // UriBuilder always encodes the $ in the $filter and $select parameters, so we need to add them manually
        QueryPart := UriBuilder.GetQuery();
        QueryPart := QueryPart + '&' + CatalogApiFilterQueryParamNameLbl + '=productType eq ''DynamicsBC''';
        QueryPart := QueryPart + '&' + CatalogApiSelectQueryParamNameLbl + '=uniqueProductID,displayName,publisherID,publisherDisplayName,publisherType,ratingAverage,ratingCount,productType,popularity,privacyPolicyUri,lastModifiedDateTime';
        QueryPart := QueryPart + '&' + CatalogApiOrderByQueryParamNameLbl + '=displayName asc';
        UriBuilder.SetQuery(QueryPart);

        UriBuilder.GetUri(Uri);
        exit(Uri.GetAbsoluteUri());
    end;

    local procedure ConstructProductUri(UniqueIdentifier: Text): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        Language: Text[2];
        Market: Text[2];
    begin
        ResolveMarketAndLanguage(Market, Language);
        UriBuilder.Init(CatalogProductsUriLbl);
        UriBuilder.SetPath('products/' + UniqueIdentifier);
        UriBuilder.AddQueryParameter(CatalogApiVersionQueryParamNameLbl, CatalogApiVersionQueryParamValueLbl);
        UriBuilder.AddQueryParameter(CatalogMarketQueryParamNameLbl, Market);
        UriBuilder.AddQueryParameter(CatalogLanguageQueryParamNameLbl, Language);
        UriBuilder.GetUri(Uri);
        Message(Uri.GetAbsoluteUri());
        exit(Uri.GetAbsoluteUri());
    end;


    #region Telemetry helpers
    local procedure PopulateTelemetryDictionary(RequestID: Text; UniqueIdentifier: text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        PopulateTelemetryDictionary(RequestID, telemetryDictionary);
        TelemetryDictionary.Add('UniqueIdentifier', UniqueIdentifier);
    end;

    local procedure PopulateTelemetryDictionary(RequestID: Text; var TelemetryDictionary: Dictionary of [Text, Text])
    begin
        TelemetryDictionary.Add('RequestID', RequestID);
    end;
    #endregion

    #region JSon Helper Functions
    procedure GetDecimalValue(var JsonObject: JsonObject; PropertyName: Text): Decimal
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsDecimal());
        exit(0);
    end;

    procedure GetIntegerValue(var JsonObject: JsonObject; PropertyName: Text): Integer
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsInteger());
        exit(0);
    end;

    procedure GetDateTimeValue(var JsonObject: JsonObject; PropertyName: Text): DateTime
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsDateTime());
        exit(0DT);
    end;

    procedure GetStringValue(var JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsText());
        exit('');
    end;

    procedure GetBooleanValue(var JsonObject: JsonObject; PropertyName: Text): Boolean
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsBoolean());
        exit(false);
    end;

    procedure GetJsonValue(var JsonObject: JsonObject; PropertyName: Text; var ReturnValue: JsonValue): Boolean
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
    #endregion

    #region Market and language helper functions
    local procedure ResolveMarketAndLanguage(var Market: Text[2]; var Language: Text[2])
    begin
        Language := GetCurrentUserIso369_1Language();

        Market := CopyStr(EnvironmentInformation.GetApplicationFamily(), 1, 2);

        if (Market = '') or (Market = 'W1') then
            if not TryGetEnvirnmentCountryLetterCode(Market) then
                Market := 'us';

        if Language = '' then
            if not TryGetEnvironmentPreferredLanguage(Language) then
                Language := 'en';

        Market := EnsureValidMarket(Market);
        Language := EnsureValidLanguage(Language);
    end;

    local procedure GetCurrentUserFormatRegion(): Text
    var
        Language: Codeunit Language;
        FormatRegion: text[80];
    begin
        FormatRegion := Language.GetFormatRegionOrDefault('');
        exit(FormatRegion);
    end;

    local procedure GetCurrentUserIso369_1Language(): Text[2]
    var
        TempUserSettingsRecord: record "User Settings" temporary;
        UserSettings: Codeunit "User Settings";
        Language: Codeunit Language;
        LanguageName: Text;
    begin
        UserSettings.GetUserSettings(Database.UserSecurityID(), TempUserSettingsRecord);
        LanguageName := Language.GetLanguageCode(tempUserSettingsRecord."Language ID");
        exit(ConvertIso369_3_ToIso369_1(LanguageName));
    end;

    [TryFunction]
    local procedure TryGetEnvirnmentCountryLetterCode(var CountryLetterCode: Text[2])
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        CountryLetterCode := entraTenant.GetCountryLetterCode();
    end;

    [TryFunction]
    local procedure TryGetEnvironmentPreferredLanguage(var PreferredLanguage: Text[2])
    var
        entraTenant: Codeunit "Azure AD Tenant";
    begin
        PreferredLanguage := entraTenant.GetPreferredLanguage();
    end;

    /// <summary>
    /// Ensures that the market is valid for AppSource.
    /// </summary>
    /// <param name="market">Market requested</param>
    /// <returns>The requested market if supported, otherwise us</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/partner-center/marketplace/marketplace-geo-availability-currencies for supported markets</remarks>
    local procedure EnsureValidMarket(market: Text[2]): Text[2]
    begin
        case LowerCase(market) of
            'af', 'al', 'dz', 'ad', 'ao', 'ar', 'am', 'au', 'at', 'az', 'bh', 'bd', 'bb', 'by', 'be', 'bz', 'bm', 'bo', 'ba', 'bw'
        , 'br', 'bn', 'bg', 'cv', 'cm', 'ca', 'ky', 'cl', 'cn', 'co', 'cr', 'ci', 'hr', 'cw', 'cy', 'cz', 'dk', 'do', 'ec', 'eg'
        , 'sv', 'ee', 'et', 'fo', 'fj', 'fi', 'fr', 'ge', 'de', 'gh', 'gr', 'gt', 'hn', 'hk', 'hu', 'is', 'in', 'id', 'iq', 'ie'
        , 'il', 'it', 'jm', 'jp', 'jo', 'kz', 'ke', 'kr', 'kw', 'kg', 'lv', 'lb', 'ly', 'li', 'lt', 'lu', 'mo', 'my', 'mt', 'mu'
        , 'mx', 'md', 'mc', 'mn', 'me', 'ma', 'na', 'np', 'nl', 'nz', 'ni', 'ng', 'mk', 'no', 'om', 'pk', 'ps', 'pa', 'py', 'pe'
        , 'ph', 'pl', 'pt', 'pr', 'qa', 'ro', 'ru', 'rw', 'kn', 'sa', 'sn', 'rs', 'sg', 'sk', 'si', 'za', 'es', 'lk', 'se', 'ch'
        , 'tw', 'tj', 'tz', 'th', 'tt', 'tn', 'tr', 'tm', 'ug', 'ua', 'ae', 'gb', 'us', 'vi', 'uy', 'uz', 'va', 've', 'vn', 'ye'
        , 'zm', 'zw':
                exit(market);
            else
                exit('us');
        end;
    end;
    /// <summary>
    /// Ensures that the language is valid for AppSource.
    /// </summary>
    /// <param name="language">Language requested</param>
    /// <returns>The requested language if supported otherwise en</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/rest/api/marketplacecatalog/dataplane/products/list?view=rest-marketplacecatalog-dataplane-2023-05-01-preview&amp;tabs=HTTP for supported languages</remarks>
    local procedure EnsureValidLanguage(language: Text[2]): Text[2]
    begin
        case LowerCase(language) of
            'en', 'cs', 'de', 'es', 'fr', 'hu', 'it', 'ja', 'ko', 'nl', 'pl', 'pt-br', 'pt-pt', 'ru', 'sv', 'tr', 'zh-hans', 'zh-hant':
                exit(language);
            else
                exit('en');
        end;
    end;

    local procedure ConvertIso369_3_ToIso369_1(Iso369_3: Text): Text[2]
    var
    begin
        case LowerCase(Iso369_3) of
            'afr':
                exit('af');
            'amh':
                exit('am');
            'ara':
                exit('ar');
            'asm':
                exit('as');
            'aze':
                exit('az');
            'bak':
                exit('ba');
            'bel':
                exit('be');
            'ben':
                exit('bn');
            'bod':
                exit('bo');
            'bos':
                exit('bs');
            'bre':
                exit('br');
            'bul':
                exit('bg');
            'cat':
                exit('ca');
            'ces':
                exit('cs');
            'cos':
                exit('co');
            'cym':
                exit('cy');
            'dan':
                exit('da');
            'deu':
                exit('de');
            'div':
                exit('dv');
            'dzo':
                exit('dz');
            'ell':
                exit('el');
            'eng':
                exit('en');
            'est':
                exit('et');
            'eus':
                exit('eu');
            'fao':
                exit('fo');
            'fas':
                exit('fa');
            'fin':
                exit('fi');
            'fra':
                exit('fr');
            'fry':
                exit('fy');
            'ful':
                exit('ff');
            'gla':
                exit('gd');
            'gle':
                exit('ga');
            'glg':
                exit('gl');
            'grn':
                exit('gn');
            'guj':
                exit('gu');
            'heb':
                exit('he');
            'hin':
                exit('hi');
            'hrv':
                exit('hr');
            'hun':
                exit('hu');
            'hye':
                exit('hy');
            'ibo':
                exit('ig');
            'iii':
                exit('ii');
            'iku':
                exit('iu');
            'ind':
                exit('id');
            'isl':
                exit('is');
            'ita':
                exit('it');
            'jpn':
                exit('ja');
            'kal':
                exit('kl');
            'kan':
                exit('kn');
            'kas':
                exit('ks');
            'kat':
                exit('ka');
            'kaz':
                exit('kk');
            'khm':
                exit('km');
            'kin':
                exit('rw');
            'kir':
                exit('ky');
            'kor':
                exit('ko');
            'lao':
                exit('lo');
            'lav':
                exit('lv');
            'lit':
                exit('lt');
            'ltz':
                exit('lb');
            'mal':
                exit('ml');
            'mar':
                exit('mr');
            'mkd':
                exit('mk');
            'mlt':
                exit('mt');
            'mon':
                exit('mn');
            'mri':
                exit('mi');
            'msa':
                exit('ms');
            'mya':
                exit('my');
            'nep':
                exit('ne');
            'nld':
                exit('nl');
            'nno':
                exit('nn');
            'nob':
                exit('nb');
            'oci':
                exit('oc');
            'ori':
                exit('or');
            'orm':
                exit('om');
            'pan':
                exit('pa');
            'pol':
                exit('pl');
            'por':
                exit('pt');
            'pus':
                exit('ps');
            'roh':
                exit('rm');
            'ron':
                exit('ro');
            'rus':
                exit('ru');
            'san':
                exit('sa');
            'sin':
                exit('si');
            'slk':
                exit('sk');
            'slv':
                exit('sl');
            'sme':
                exit('se');
            'snd':
                exit('sd');
            'som':
                exit('so');
            'sot':
                exit('st');
            'spa':
                exit('es');
            'sqi':
                exit('sq');
            'srp':
                exit('sr');
            'swa':
                exit('sw');
            'swe':
                exit('sv');
            'tam':
                exit('ta');
            'tat':
                exit('tt');
            'tel':
                exit('te');
            'tha':
                exit('th');
            'tir':
                exit('ti');
            'tsn':
                exit('tn');
            'tso':
                exit('ts');
            'tuk':
                exit('tk');
            'tur':
                exit('tr');
            'uig':
                exit('ug');
            'ukr':
                exit('uk');
            'urd':
                exit('ur');
            'uzb':
                exit('uz');
            'ven':
                exit('ve');
            'vie':
                exit('vi');
            'wol':
                exit('wo');
            'xho':
                exit('xh');
            'yid':
                exit('yi');
            'yor':
                exit('yo');
            'zul':
                exit('zu');
        end;

        exit('');
    end;
    #endregion

    local procedure InsertProductFromObject(offer: JsonObject; var Product: Record "AppSource Product")
    begin
        Product.Init();
        Product.UniqueProductID := CopyStr(GetStringValue(offer, 'uniqueProductId'), 1, MaxStrLen(Product.UniqueProductID));
        Product.DisplayName := CopyStr(GetStringValue(offer, 'displayName'), 1, MaxStrLen(Product.DisplayName));
        Product.PublisherID := CopyStr(GetStringValue(offer, 'publisherId'), 1, MaxStrLen(Product.PublisherID));
        Product.PublisherDisplayName := CopyStr(GetStringValue(offer, 'publisherDisplayName'), 1, MaxStrLen(Product.PublisherDisplayName));
        Product.PublisherType := CopyStr(GetStringValue(offer, 'publisherType'), 1, MaxStrLen(Product.PublisherType));
        Product.RatingAverage := GetDecimalValue(offer, 'ratingAverage');
        Product.RatingCount := GetIntegerValue(offer, 'ratingCount');
        Product.ProductType := CopyStr(GetStringValue(offer, 'productType'), 1, MaxStrLen(Product.ProductType));
        Product.Popularity := GetDecimalValue(offer, 'popularity');
        Product.LastModifiedDateTime := GetDateTimeValue(offer, 'lastModifiedDateTime');

        Product.AppID := ExtractAppIDFromUniqueProductID(Product.UniqueProductID);

        // Insert, if it fails to insert due to the data (ex duplicate ids), ignore the error
        if not Product.Insert() then;
    end;

    [NonDebuggable]
    local procedure GetAPIKey(): SecretText
    var
        KeyVault: codeunit "Azure Key Vault";
        TextValue: text;
        ApiKey: SecretText;
    begin
        if not EnvironmentInformation.IsSaaS() then
            Error('Not Supported On Premises');

        keyVault.GetAzureKeyVaultSecret('MS-AppSource-ApiKey', TextValue);
        ApiKey := TextValue;
        exit(ApiKey);
    end;

    var
        EnvironmentInformation: Codeunit "Environment Information";
        CatalogProductsUriLbl: label 'https://catalogapi.azure.com/products', Locked = true;
        CatalogApiVersionQueryParamNameLbl: label 'api-version', Locked = true;
        CatalogApiVersionQueryParamValueLbl: label '2023-05-01-preview', Locked = true;
        CatalogApiOrderByQueryParamNameLbl: label '$orderby', Locked = true;
        CatalogMarketQueryParamNameLbl: label 'market', Locked = true;
        CatalogLanguageQueryParamNameLbl: label 'language', Locked = true;
        CatalogApiFilterQueryParamNameLbl: Label '$filter', Locked = true;
        CatalogApiSelectQueryParamNameLbl: Label '$select', Locked = true;
        AppSourceListingUriLbl: Label 'https://appsource.microsoft.com/%1/product/dynamics-365-business-central/%2', Comment = '%1=Language, %2=Url Query Content', Locked = true;
        AppSourceUriLbl: Label 'https://appsource.microsoft.com/%1/marketplace/apps?product=dynamics-365-business-central', Comment = '%=Language', Locked = true;
}