
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

using System.Environment.Configuration;
using System.Globalization;

/// <summary>
/// Library for managing AppSource product retrival and usage.
/// </summary>
codeunit 2517 "AppSource Market Locale Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

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
        GetCurrentUserLanguageAnLocaleID(LanguageID, LocalID);

        // Marketplace API only supports two letter languages.
        LanguageName := Language.GetTwoLetterISOLanguageName(LanguageID);

        Market := '';
        if LocalID <> 0 then
            Market := ResolveMarketFromLanguageID(LocalID);
        if Market = '' then
            Market := CopyStr(Dependencies.GetApplicationFamily(), 1, 2);
        if (Market = '') or (Market = 'W1') then
            if not TryGetEnvironmentCountryLetterCode(Market) then
                Market := 'us';

        Market := EnsureValidMarket(Market);
        LanguageName := EnsureValidLanguage(LanguageName);
    end;

    procedure GetCurrentUserLanguageID(): Integer
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
        LanguageID: Integer;
    begin
        Dependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(Dependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US
        exit(LanguageID);
    end;

    local procedure GetCurrentUserLanguageAnLocaleID(var LanguageID: Integer; var LocaleID: Integer)
    var
        TempUserSettings: Record "User Settings" temporary;
        Language: Codeunit Language;
    begin
        Dependencies.GetUserSettings(Database.UserSecurityID(), TempUserSettings);
        LanguageID := TempUserSettings."Language ID";
        if (LanguageID = 0) then
            LanguageID := Language.GetLanguageIdFromCultureName(Dependencies.GetPreferredLanguage());
        if (LanguageID = 0) then
            LanguageID := 1033; // Default to EN-US

        LocaleID := TempUserSettings."Locale ID";
    end;

    [TryFunction]
    local procedure TryGetEnvironmentCountryLetterCode(var CountryLetterCode: Text)
    begin
        CountryLetterCode := Dependencies.GetCountryLetterCode();
    end;

    local procedure ResolveMarketFromLanguageID(LanguageID: Integer): Text
    var
        Language: Codeunit Language;
        SeperatorPos: Integer;
        LanguageAndRequestRegion: Text;
    begin
        LanguageAndRequestRegion := 'en';
        LanguageAndRequestRegion := Language.GetCultureName(LanguageID);
        SeperatorPos := StrPos(LanguageAndRequestRegion, '-');
        if SeperatorPos > 1 then
            exit(CopyStr(LanguageAndRequestRegion, SeperatorPos + 1, 2));

        exit('');
    end;

    /// <summary>
    /// Ensures that the market is valid for AppSource.
    /// </summary>
    /// <param name="Market">Market requested</param>
    /// <returns>The requested market if supported, otherwise us</returns>
    /// <remarks>See https://learn.microsoft.com/en-us/partner-center/marketplace/marketplace-geo-availability-currencies for supported markets</remarks>
    local procedure EnsureValidMarket(Market: Text): Text
    var
        NotSupportedNotification: Notification;
    begin
        case LowerCase(Market) of
            'af', 'al', 'dz', 'ad', 'ao', 'ar', 'am', 'au', 'at', 'az', 'bh', 'bd', 'bb', 'by', 'be', 'bz', 'bm', 'bo', 'ba', 'bw'
        , 'br', 'bn', 'bg', 'cv', 'cm', 'ca', 'ky', 'cl', 'cn', 'co', 'cr', 'ci', 'hr', 'cw', 'cy', 'cz', 'dk', 'do', 'ec', 'eg'
        , 'sv', 'ee', 'et', 'fo', 'fj', 'fi', 'fr', 'ge', 'de', 'gh', 'gr', 'gt', 'hn', 'hk', 'hu', 'is', 'in', 'id', 'iq', 'ie'
        , 'il', 'it', 'jm', 'jp', 'jo', 'kz', 'ke', 'kr', 'kw', 'kg', 'lv', 'lb', 'ly', 'li', 'lt', 'lu', 'mo', 'my', 'mt', 'mu'
        , 'mx', 'md', 'mc', 'mn', 'me', 'ma', 'na', 'np', 'nl', 'nz', 'ni', 'ng', 'mk', 'no', 'om', 'pk', 'ps', 'pa', 'py', 'pe'
        , 'ph', 'pl', 'pt', 'pr', 'qa', 'ro', 'ru', 'rw', 'kn', 'sa', 'sn', 'rs', 'sg', 'sk', 'si', 'za', 'es', 'lk', 'se', 'ch'
        , 'tw', 'tj', 'tz', 'th', 'tt', 'tn', 'tr', 'tm', 'ug', 'ua', 'ae', 'gb', 'us', 'vi', 'uy', 'uz', 'va', 've', 'vn', 'ye'
        , 'zm', 'zw':
                exit(LowerCase(Market));
            else begin
                NotSupportedNotification.Id := '0c0f2e34-e72f-4da4-a7d5-80b33653d13d';
                NotSupportedNotification.Message(StrSubstNo(UnsupportedMarketNotificationLbl, Market));
                NotSupportedNotification.Send();
                exit('us');
            end;
        end;
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

    procedure SetDependencies(DependencyInstance: Interface "AppSource Product Manager Dependencies")
    begin
        Dependencies := DependencyInstance;
    end;

    var
        Dependencies: Interface "AppSource Product Manager Dependencies";
        UnsupportedLanguageNotificationLbl: Label 'Language %1 is not supported by AppSource. Defaulting to "en". Change the language in the user profile to use another language.', Comment = '%1=Language ID, such as en';
        UnsupportedMarketNotificationLbl: Label 'Market %1 is not supported by AppSource. Defaulting to "us". Change the region in the user profile to use another market.', Comment = '%1=Market ID, such as "us"';
}