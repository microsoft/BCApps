// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.Apps.AppSource;

using System.Apps.AppSource;

/// <summary>
/// Library for mocking AppSource product retrieval and usage.
/// </summary>
codeunit 132935 "AppSrc Product Mgr. Test Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAppSourceProduct: Record "AppSource Product" temporary;
        AppSourceProductManager: Codeunit "AppSource Product Manager";

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
    /// Extracts the AppID from the Unique Product ID.
    /// </summary>
    /// <param name="UniqueProductIDValue">The Unique Product ID of the product as defined in MicrosoftAppSource</param>
    /// <returns>AppID found in the Product ID</returns>
    /// <remarks>The AppSource unique product ID is specific to AppSource and combines different features while always ending with PAPID. and extension app id. Example: PUBID.mdcc1667400477212|AID.bc_converttemp_sample|PAPPID.9d314b3e-ffd3-41fd-8755-7744a6a790df</remarks>
    procedure ExtractAppIDFromUniqueProductID(UniqueProductIDValue: Text): Guid
    begin
        exit(AppSourceProductManager.ExtractAppIDFromUniqueProductID(UniqueProductIDValue))
    end;

    procedure CanInstallProductWithPlans(Plans: JsonArray): Boolean
    begin
        exit(AppSourceProductManager.CanInstallProductWithPlans(Plans));
    end;

    #region Record handling functions

    /// <summary>
    /// Get all products from a remote server and adds them to the AppSource Product table.
    /// </summary>
    procedure GetProductsAndPopulateRecord(): Text
    begin
        exit(AppSourceProductManager.GetProductsAndPopulateRecord(TempAppSourceProduct));
    end;

    /// <summary>
    /// Returns true if a product with the given display name is present in the AppSource Product table.
    /// </summary>
    procedure IsRecordWithDisplayNameinProductTable(DisplayName: Text): Boolean
    begin
        TempAppSourceProduct.Reset();
        TempAppSourceProduct.SetRange(DisplayName, DisplayName);
        exit(TempAppSourceProduct.FindFirst());
    end;

    /// <summary>
    /// Gets the number of records in the AppSource Product table.
    /// </summary>
    procedure GetProductTableCount(): Integer
    begin
        TempAppSourceProduct.Reset();
        exit(TempAppSourceProduct.Count());
    end;
    #endregion

    // Dependencies
    procedure SetDependencies(AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider")
    begin
        AppSourceProductManager.SetDependencies(AppSourceMockDepsProvider);
    end;

    procedure ResetDependencies()
    var
        AppSourceMockDepsProvider: Codeunit "AppSource Mock Deps. Provider";
    begin
        AppSourceProductManager.SetDependencies(AppSourceMockDepsProvider);
        TempAppSourceProduct.DeleteAll();
    end;
}