// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139556 "Shpfy Product Collection Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProdCollectionHelper: Codeunit "Shpfy Prod. Collection Helper";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestImportProductCollectionsTest()
    var
        ProductCollection: Record "Shpfy Product Collection";
        JPublications: JsonArray;
    begin
        // [SCENARIO] Importing product collection from Shopify to Business Central.
        Initialize();

        // [GIVEN] Shopify response with product collection data.
        JPublications := ProdCollectionHelper.GetProductCollectionResponse(Any.IntegerInRange(10000, 99999));

        // [WHEN] Invoking the procedure: ShpfyProductCollectionAPI.RetrieveProductCollectionsFromShopify
        InvokeRetrieveCustomProductCollectionsFromShopify(JPublications);

        // [THEN] The product collection is imported to Business Central.
        ProductCollection.SetRange("Shop Code", Shop.Code);
        LibraryAssert.IsFalse(ProductCollection.IsEmpty(), 'Product Collection not created');
        LibraryAssert.AreEqual(1, ProductCollection.Count(), 'Product Collection count is not equal to 1');
    end;

    [Test]
    procedure UnitTestRemoveNotExistingProductCollectionsTest()
    var
        ProductCollection: Record "Shpfy Product Collection";
        JPublications: JsonArray;
        CollectionId: BigInteger;
        AdditionalCollectionId: BigInteger;
    begin
        // [SCENARIO] Removing not existing product collections from Business Central.
        Initialize();

        // [GIVEN] Product collection imported.
        CollectionId := Any.IntegerInRange(10000, 99999);
        CreateProductCollection(CollectionId, Any.AlphabeticText(20), false);
        // [GIVEN] Additional product collection imported.
        AdditionalCollectionId := CollectionId + 1;
        CreateProductCollection(AdditionalCollectionId, Any.AlphabeticText(20), false);
        // [GIVEN] Shopify response with initial product collection data.
        JPublications := ProdCollectionHelper.GetProductCollectionResponse(CollectionId);

        // [WHEN] Invoking the procedure: ShpfyProductCollectionAPI.RetrieveProductCollectionsFromShopify
        InvokeRetrieveCustomProductCollectionsFromShopify(JPublications);

        // [THEN] The additional product collection is removed from Business Central.
        ProductCollection.SetRange("Shop Code", Shop.Code);
        ProductCollection.SetRange("Id", AdditionalCollectionId);
        LibraryAssert.IsTrue(ProductCollection.IsEmpty(), 'Product Collection not removed');

        // [THEN] The initial product collection is in the Business Central.
        LibraryAssert.IsTrue(ProductCollection.Get(CollectionId), 'Product Collection not created');
    end;

    [Test]
    procedure UnitTestPublishProductWithDefaultProductCollectionsTest()
    var
        Item: Record Item;
        TempProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ShopifyTag: Record "Shpfy Tag";
        ProductCollection: Record "Shpfy Product Collection";
        ProductAPI: Codeunit "Shpfy Product API";
        ProductCollectionSubs: Codeunit "Shpfy Product Collection Subs.";
        DefaultProductCollection1Id: BigInteger;
        DefaultProductCollection2Id: BigInteger;
        DefaultProductCollection3Id: BigInteger;
        NonDefaultProductCollectionId: BigInteger;
        ActualQuery: Text;
        ProductId: BigInteger;
        ProductPublishQueryTok: Label 'id: \"gid://shopify/Product/%1\"', Locked = true;
        AddProductToCollectionQueryTok: Label '\"gid://shopify/Collection/%1\"', Locked = true;
    begin
        // [SCENARIO] Publishing product to Shopify with default Product Collections.
        Initialize();

        // [GIVEN] Product.
        CreateProduct(TempProduct, Any.IntegerInRange(10000, 99999));
        CreateItem(Item, TempProduct);
        // [GIVEN] Shopify Variant.
        CreateShopifyVariant(TempProduct, TempShopifyVariant, Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default Product Collection.
        DefaultProductCollection1Id := Any.IntegerInRange(10000, 99999);
        ProductCollection := CreateProductCollection(DefaultProductCollection1Id, Any.AlphabeticText(20), true);
        Item.SetRange("No.", Item."No.");
        ProductCollection.SetItemFilter(Item.GetView());
#pragma warning disable AA0214
        ProductCollection.Modify(false);
#pragma warning restore AA0214

        DefaultProductCollection2Id := DefaultProductCollection1Id + 1;
        ProductCollection := CreateProductCollection(DefaultProductCollection2Id, Any.AlphabeticText(20), true);
        Item.SetRange("No.", '');
        ProductCollection.SetItemFilter(Item.GetView());
#pragma warning disable AA0214
        ProductCollection.Modify(false);
#pragma warning restore AA0214

        DefaultProductCollection3Id := DefaultProductCollection2Id + 1;
        CreateProductCollection(DefaultProductCollection3Id, Any.AlphabeticText(20), true);
        // [GIVEN] Non-Default Product Collection.
        NonDefaultProductCollectionId := DefaultProductCollection3Id + 1;
        CreateProductCollection(NonDefaultProductCollectionId, Any.AlphabeticText(20), false);

        // [WHEN] Invoking the procedure: ProductAPI.CreateProduct.
        BindSubscription(ProductCollectionSubs);
        ProductId := ProductAPI.CreateProduct(TempProduct, TempShopifyVariant, ShopifyTag);
        UnbindSubscription(ProductCollectionSubs);

        // [THEN] Query for publishing the product is generated.
        ActualQuery := ProductCollectionSubs.GetPublishProductGraphQueryTxt();
        LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(ProductPublishQueryTok, ProductId)), 'Product Id is not in the query');
        // [THEN] Query for adding product contains default Product Collections.
        ActualQuery := ProductCollectionSubs.GetProductCreateGraphQueryTxt();
        LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, DefaultProductCollection1Id)), 'Product Collection Id is not in the query');
        LibraryAssert.IsFalse(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, DefaultProductCollection2Id)), 'Product Collection Id is not in the query');
        LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, DefaultProductCollection3Id)), 'Product Collection Id is not in the query');
        // [THEN] Query does not contain non-default Product Collection Id.
        LibraryAssert.IsFalse(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, NonDefaultProductCollectionId)), 'Non-default Product Collection Id is in the query')
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        Shop := InitializeTest.CreateShop();
        CreateDefaultSalesChannel();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateDefaultSalesChannel()
    var
        SalesChannel: Record "Shpfy Sales Channel";
    begin
        SalesChannel.Init();
        SalesChannel.Id := Any.IntegerInRange(10000, 99999);
        SalesChannel."Shop Code" := Shop.Code;
        SalesChannel.Name := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(SalesChannel.Name));
        SalesChannel.Default := true;
        SalesChannel.Insert(false);
    end;

    local procedure CreateProductCollection(CollectionId: BigInteger; CollectionName: Text; IsDefault: Boolean): Record "Shpfy Product Collection"
    var
        ProductCollection: Record "Shpfy Product Collection";
    begin
        ProductCollection.Init();
        ProductCollection.Id := CollectionId;
        ProductCollection."Shop Code" := Shop.Code;
        ProductCollection.Name := CopyStr(CollectionName, 1, MaxStrLen(ProductCollection.Name));
        ProductCollection.Default := IsDefault;
        ProductCollection.Insert(false);
        exit(ProductCollection);
    end;

    local procedure CreateProduct(var Product: Record "Shpfy Product"; Id: BigInteger)
    begin
        Product.Init();
        Product.Id := Id;
        Product."Shop Code" := Shop.Code;
        Product.Insert(false);
    end;

    local procedure CreateItem(var Item: Record Item; var Product: Record "Shpfy Product")
    begin
        Item.Init();
        Item."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Item."No."));
        Item.Description := CopyStr(Any.AlphabeticText(30), 1, MaxStrLen(Item.Description));
        Item.Insert(false);
        Product."Item SystemId" := Item.SystemId;
        Product.Modify(false);
    end;

    local procedure CreateShopifyVariant(Product: Record "Shpfy Product"; var ShpfyVariant: Record "Shpfy Variant"; Id: BigInteger)
    begin
        ShpfyVariant.Init();
        ShpfyVariant.Id := Id;
        ShpfyVariant."Product Id" := Product.Id;
        ShpfyVariant.Insert(false);
    end;

    local procedure InvokeRetrieveCustomProductCollectionsFromShopify(var JPublications: JsonArray)
    var
        ProductCollectionAPI: Codeunit "Shpfy Product Collection API";
        ProductCollectionSubs: Codeunit "Shpfy Product Collection Subs.";
    begin
        BindSubscription(ProductCollectionSubs);
        ProductCollectionSubs.SetJEdges(JPublications);
        ProductCollectionAPI.RetrieveCustomProductCollectionsFromShopify(Shop.Code);
        UnbindSubscription(ProductCollectionSubs);
    end;
}