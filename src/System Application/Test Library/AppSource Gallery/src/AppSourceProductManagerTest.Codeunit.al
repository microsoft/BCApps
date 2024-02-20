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
codeunit 132910 "AppSource Product Manager Test" implements "AppSource Product Manager Dependencies"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAppSourceProduct: Record "AppSource Product" temporary;
        AppSourceProductManager: Codeunit "AppSource Product Manager";
        FormatRegionStore: Text[80];
        CountryLetterCode: Code[2];
        PreferredLanguage: Text;
        LanguageID: Variant;
        IsInSaas: Boolean;
        Json: JsonToken;
        ApplicationFamily: Text;

    /// <summary>
    /// Opens Microsoft AppSource web page for the region is specified in the UserSessionSettings or 'en-us' by default.
    /// </summary>
    procedure OpenAppSource()
    begin
        AppSourceProductManager.OpenAppSource();
    end;

    /// <summary>
    /// Opens the AppSource product page in Microsoft AppSource, for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product to show in MicrosoftAppSource</param>
    procedure OpenAppInAppSource(UniqueProductIDValue: Text)
    begin
        AppSourceProductManager.OpenAppInAppSource(UniqueProductIDValue);
    end;

    /// <summary>
    /// Opens the AppSource product details page for the specified unique product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue"></param>
    procedure OpenProductDetailsPage(UniqueProductIDValue: Text)
    begin
        AppSourceProductManager.OpenProductDetailsPage(UniqueProductIDValue);
    end;

    /// <summary>
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Guid
    begin
        AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueProductIDValue)
    end;

    procedure CanInstallProductWithPlans(Plans: JsonArray): Boolean
    begin
        exit(AppSourceProductManager.CanInstallProductWithPlans(Plans));
    end;

    #region Market and language helper functions

    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    internal procedure GetProductsAndPopulateRecord(): Text
    begin
        AppSourceProductManager.GetProductsAndPopulateRecord(TempAppSourceProduct);
    end;

    internal procedure GetRecordAtPosDisplayName(Position: Integer): Text
    var
        i : Integer;
    begin
        for i := 1 to Position do
            TempAppSourceProduct.Next();
        exit(TempAppSourceProduct.DisplayName);
    end;

    internal procedure GetRecordCount(): Integer
    begin
        exit(TempAppSourceProduct.Count());
    end;
    #endregion

    // Dependency to Azure AD Tenant
    procedure GetCountryLetterCode(): Code[2]
    begin
        exit(CountryLetterCode)
    end;

    procedure SetCountryLetterCode(InputCountryLetterCode: Code[2])
    begin
        CountryLetterCode := InputCountryLetterCode;
    end;

    procedure GetPreferredLanguage(): Text
    begin
        exit(PreferredLanguage);
    end;

    procedure SetPreferredLanguage(InputPreferredLanguage: Text)
    begin
        PreferredLanguage := InputPreferredLanguage;
    end;

    // Dependency to Environment Information 
    procedure GetApplicationFamily(): Text
    begin
        exit(ApplicationFamily);
    end;

    procedure SetApplicationFamily(InputApplicationFamily: Text)
    begin
        ApplicationFamily := InputApplicationFamily;
    end;

    procedure IsSaas(): Boolean
    begin
        exit(IsInSaas);
    end;

    procedure SetIsSaas(InputIsSaas: Boolean)
    begin
        IsInSaas := InputIsSaas;
    end;

    // Dependency to Language 
    procedure GetFormatRegionOrDefault(InputFormatRegion: Text[80]): Text
    begin
        if (InputFormatRegion <> '') then
            exit(InputFormatRegion);
        exit(FormatRegionStore);
    end;

    procedure SetFormatRegionStore(InputFormatRegion: Text[80])
    begin
        FormatRegionStore := InputFormatRegion;
    end;

    // Rest client override
    procedure GetAsJSon(var RestClient: Codeunit "Rest Client"; RequestUri: Text): JsonToken
    begin
        exit(Json);
    end;

    procedure SetJSon(JsonText: Text)
    begin
        Json.ReadFrom(JsonText);
    end;

    // Dependency to User Settings
    procedure GetUserSettings(UserSecurityID: Guid; var TempUserSettingsRecord: Record "User Settings" temporary)
    begin
        TempUserSettingsRecord.Init();
        TempUserSettingsRecord."User Security ID" := UserSecurityID;
        TempUserSettingsRecord."Language ID" := LanguageID;
    end;

    procedure SetUserSettings(InputLanguageId: Variant)
    begin
        LanguageID := InputLanguageId;
    end;

    internal procedure SetDependencies(AppSourceProductManagerDependencies: Interface "AppSource Product Manager Dependencies")
    begin
        AppSourceProductManager.SetDependencies(AppSourceProductManagerDependencies);
    end;

    procedure ShouldSetCommonHeaders(): Boolean
    begin
        exit(false);
    end;
}