// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139645 "Shpfy Catalog API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        Any: Codeunit Any;
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestExtractShopifyCatalogs()
    var
        ShopifyCompany: Record "Shpfy Company";
        Catalog: Record "Shpfy Catalog";
        CatalogAPI: Codeunit "Shpfy Catalog API";
        CatalogInitialize: Codeunit "Shpfy Catalog Initialize";
        CompanyInitialize: Codeunit "Shpfy Company Initialize";
        JResponse: JsonObject;
        Result: Boolean;
        Cursor: Text;
    begin
        Initialize();

        // Creating Test data.
        CompanyInitialize.CreateShopifyCompany(ShopifyCompany);
        JResponse := CatalogInitialize.CatalogResponse();

        // [SCENARIO] Extracting the Catalogs from the Shopify response.
        // [GIVEN] JResponse with Catalogs

        // [WHEN] Invoke CatalogAPI.ExtractShopifyCatalogs
        Result := CatalogAPI.ExtractShopifyCatalogs(ShopifyCompany, JResponse, Cursor);

        // [THEN] Result = true and Catalog prices are created.
        LibraryAssert.IsTrue(Result, 'ExtractShopifyCatalogs');
        LibraryAssert.RecordIsNotEmpty(Catalog);
    end;

    [Test]
    procedure UnitTestExtractShopifyCatalogPrices()
    var
        TempCatalogPrice: Record "Shpfy Catalog Price" temporary;
        CatalogAPI: Codeunit "Shpfy Catalog API";
        CatalogInitialize: Codeunit "Shpfy Catalog Initialize";
        JResponse: JsonObject;
        Result: Boolean;
        Cursor: Text;
        ProductId: BigInteger;
        ProductsList: List of [BigInteger];
    begin
        Initialize();

        // Creating Test data.
        ProductId := LibraryRandom.RandIntInRange(100000, 999999);
        ProductsList.Add(ProductId);
        JResponse := CatalogInitialize.CatalogPriceResponse(ProductId);

        // [SCENARIO] Extracting the Catalog Prices from the Shopify response.
        // [GIVEN] JResponse with Catalog Prices

        // [WHEN] Invoke CatalogAPI.ExtractShopifyCatalogPrices
        Result := CatalogAPI.ExtractShopifyCatalogPrices(TempCatalogPrice, ProductsList, JResponse, Cursor);

        // [THEN] Result = true and Catalog prices are created.
        LibraryAssert.IsTrue(Result, 'ExtractShopifyCatalogPrices');
        LibraryAssert.RecordIsNotEmpty(TempCatalogPrice);
    end;

    [Test]
    [HandlerFunctions('CreateCatalogHandler')]
    procedure UnitTestCreateCatalog()
    var
        Customer: Record Customer;
        ShopifyCompany: Record "Shpfy Company";
        Catalog: Record "Shpfy Catalog";
        CatalogAPI: Codeunit "Shpfy Catalog API";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();

        // [SCENARIO] Create a catalog for a company.

        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] A company record.
        CreateCompany(ShopifyCompany, Customer.SystemId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('CreateCatalog');
        OutboundHttpRequests.Enqueue('CreatePublication');
        OutboundHttpRequests.Enqueue('CreatePriceList');

        // [WHEN] Invoke CatalogAPI.CreateCatalog
        CatalogAPI.CreateCatalog(ShopifyCompany, Customer);

        // [THEN] A catalog is created.
        Catalog.SetRange("Company SystemId", ShopifyCompany.SystemId);
        Catalog.FindFirst();
        LibraryAssert.AreEqual(Customer."No.", Catalog."Customer No.", 'Customer No. is not transferred to catalog');
    end;

    [HttpClientHandler]
    internal procedure CreateCatalogHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Body: Text;
        ResponseKey: Text;
        CatalogResultLbl: Label '{"data": {"catalogCreate": {"catalog": {"id": %1}}}}', Comment = '%1 - catalogId', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        ResponseKey := OutboundHttpRequests.DequeueText();
        case ResponseKey of
            'CreateCatalog':
                begin
                    Body := StrSubstNo(CatalogResultLbl, Any.IntegerInRange(100000, 999999));
                    Response.Content.WriteFrom(Body);
                end;
            'CreatePublication':
                Response.Content.WriteFrom('{}');
            'CreatePriceList':
                Response.Content.WriteFrom('{}');
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Commit();
    end;

    local procedure CreateCompany(var ShopifyCompany: Record "Shpfy Company"; CustomerSystemId: Guid)
    var
        ShopifyCompanyInitialize: Codeunit "Shpfy Company Initialize";
    begin
        ShopifyCompanyInitialize.CreateShopifyCompany(ShopifyCompany);
        ShopifyCompany."Customer SystemId" := CustomerSystemId;
        ShopifyCompany.Modify(false);
    end;
}
