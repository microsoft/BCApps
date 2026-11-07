// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139613 "Shpfy Variant API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantResponseMode: Option Existing,Missing;
        FutureUpdatedAt: DateTime;

    [Test]
    [HandlerFunctions('GetVariantHttpHandler')]
    procedure UnitTestRetrieveShopifyVariantKeepsVariantWhenLocalUpdatedAtIsAhead()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyInventoryItem: Record "Shpfy Inventory Item";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        VariantApi: Codeunit "Shpfy Variant API";
        Result: Boolean;
    begin
        Initialize();

        // [SCENARIO] When a variant's local "Updated At" is ahead of Shopify's updatedAt (e.g. after a bulk price
        // [SCENARIO] export stamps CurrentDateTime), RetrieveShopifyVariant must still report the variant as existing
        // [SCENARIO] so the caller does not delete it. The timestamp guard only skips the field update.

        // [GIVEN] A standard Shopify product with a variant whose local "Updated At" is set into the future.
        VariantResponseMode := VariantResponseMode::Existing;
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant.Id;
        FutureUpdatedAt := CurrentDateTime() + 86400000; // one day ahead of any Shopify updatedAt
        ShopifyVariant."Updated At" := FutureUpdatedAt;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ProductId);

        // [WHEN] Retrieve the variant while Shopify returns an older updatedAt.
        VariantApi.SetShop(Shop);
        Result := VariantApi.RetrieveShopifyVariant(ShopifyProduct, ShopifyVariant, ShopifyInventoryItem);

        // [THEN] The variant is reported as existing (the caller must not delete it).
        LibraryAssert.IsTrue(Result, 'RetrieveShopifyVariant should return true when the variant still exists on Shopify.');

        // [THEN] The timestamp guard skipped the field update, so the local "Updated At" is untouched.
        ShopifyVariant.Get(VariantId);
        LibraryAssert.AreEqual(FutureUpdatedAt, ShopifyVariant."Updated At", 'The local "Updated At" should be preserved when the guard skips the update.');
    end;

    [Test]
    [HandlerFunctions('GetVariantHttpHandler')]
    procedure UnitTestRetrieveShopifyVariantReportsMissingWhenDeletedOnShopify()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyInventoryItem: Record "Shpfy Inventory Item";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        VariantApi: Codeunit "Shpfy Variant API";
        Result: Boolean;
    begin
        Initialize();

        // [SCENARIO] When Shopify no longer returns the productVariant node, the variant is genuinely deleted and
        // [SCENARIO] RetrieveShopifyVariant must return false so the caller can delete the local record.

        // [GIVEN] A standard Shopify product with a variant.
        VariantResponseMode := VariantResponseMode::Missing;
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant.Id;
        ShopifyProduct.Get(ProductId);

        // [WHEN] Retrieve the variant while Shopify returns an empty productVariant node.
        VariantApi.SetShop(Shop);
        Result := VariantApi.RetrieveShopifyVariant(ShopifyProduct, ShopifyVariant, ShopifyInventoryItem);

        // [THEN] The variant is reported as missing (the caller may delete it).
        LibraryAssert.IsFalse(Result, 'RetrieveShopifyVariant should return false when the variant no longer exists on Shopify.');
    end;

    [HttpClientHandler]
    internal procedure GetVariantHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        VariantResponseTok: Label 'Products/ProductVariantDetailsResponse.txt', Locked = true;
        MissingVariantResponseTok: Label '{"data":{"productVariant":null},"extensions":{}}', Locked = true;
        ResultTxt: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case VariantResponseMode of
            VariantResponseMode::Existing:
                begin
                    ResultTxt := NavApp.GetResourceAsText(VariantResponseTok, TextEncoding::UTF8);
                    ResultTxt := ResultTxt.Replace('{{ProductId}}', ProductId.ToText());
                    ResultTxt := ResultTxt.Replace('{{VariantId}}', VariantId.ToText());
                end;
            VariantResponseMode::Missing:
                ResultTxt := MissingVariantResponseTok;
        end;
        Response.Content.WriteFrom(ResultTxt);
        exit(false);
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Variant API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Variant API Test");

        LibraryRandom.Init();
        IsInitialized := true;
        Commit();

        Shop := InitializeTest.CreateShop();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Variant API Test");
    end;
}
