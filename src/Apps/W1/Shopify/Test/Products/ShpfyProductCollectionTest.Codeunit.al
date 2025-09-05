// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139542 "Shpfy Product Collection Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProdCollectionHelper: Codeunit "Shpfy Prod. Collection Helper";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        this.IsInitialized := false;
    end;

    [Test]
    procedure UnitTestImportProductCollectionsTest()
    var
        ProductCollection: Record "Shpfy Product Collection";
        JPublications: JsonArray;
    begin
        // [SCENARIO] Importing product collection from Shopify to Business Central.
        this.Initialize();

        // [GIVEN] Shopify response with product collection data.
        JPublications := this.ProdCollectionHelper.GetProductCollectionResponse(this.Any.IntegerInRange(10000, 99999));

        // [WHEN] Invoking the procedure: ShpfyProductCollectionAPI.RetrieveProductCollectionsFromShopify
        this.InvokeRetrieveCustomProductCollectionsFromShopify(JPublications);

        // [THEN] The product collection is imported to Business Central.
        ProductCollection.SetRange("Shop Code", this.Shop.Code);
        this.LibraryAssert.IsFalse(ProductCollection.IsEmpty(), 'Product Collection not created');
        this.LibraryAssert.AreEqual(1, ProductCollection.Count(), 'Product Collection count is not equal to 1');
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
        this.Initialize();

        // [GIVEN] Product collection imported.
        CollectionId := this.Any.IntegerInRange(10000, 99999);
        this.CreateProductCollection(CollectionId, this.Any.AlphabeticText(20), false);
        // [GIVEN] Additional product collection imported.
        AdditionalCollectionId := CollectionId + 1;
        this.CreateProductCollection(AdditionalCollectionId, this.Any.AlphabeticText(20), false);
        // [GIVEN] Shopify response with initial product collection data.
        JPublications := this.ProdCollectionHelper.GetProductCollectionResponse(CollectionId);

        // [WHEN] Invoking the procedure: ShpfyProductCollectionAPI.RetrieveProductCollectionsFromShopify
        this.InvokeRetrieveCustomProductCollectionsFromShopify(JPublications);

        // [THEN] The additional product collection is removed from Business Central.
        ProductCollection.SetRange("Shop Code", this.Shop.Code);
        ProductCollection.SetRange("Id", AdditionalCollectionId);
        this.LibraryAssert.IsTrue(ProductCollection.IsEmpty(), 'Product Collection not removed');

        // [THEN] The initial product collection is in the Business Central.
        this.LibraryAssert.IsTrue(ProductCollection.Get(CollectionId), 'Product Collection not created');
    end;

    [Test]
    procedure UnitTestPublishProductWithDefaultProductCollectionsTest()
    var
        TempProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ShopifyTag: Record "Shpfy Tag";
        ProductAPI: Codeunit "Shpfy Product API";
        ProductCollectionSubs: Codeunit "Shpfy Product Collection Subs.";
        DefaultProductCollection1Id: BigInteger;
        DefaultProductCollection2Id: BigInteger;
        NonDefaultProductCollectionId: BigInteger;
        ActualQuery: Text;
        ProductId: BigInteger;
        ProductPublishQueryTok: Label 'id: \"gid://shopify/Product/%1\"', Locked = true;
        AddProductToCollectionQueryTok: Label '\"gid://shopify/Collection/%1\"', Locked = true;
    begin
        // [SCENARIO] Publishing product to Shopify with default Product Collections.
        this.Initialize();

        // [GIVEN] Product.
        this.CreateProduct(TempProduct, this.Any.IntegerInRange(10000, 99999));
        // [GIVEN] Shopify Variant.
        this.CreateShopifyVariant(TempProduct, TempShopifyVariant, this.Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default Product Collection.
        DefaultProductCollection1Id := this.Any.IntegerInRange(10000, 99999);
        this.CreateProductCollection(DefaultProductCollection1Id, this.Any.AlphabeticText(20), true);
        DefaultProductCollection2Id := DefaultProductCollection1Id + 1;
        this.CreateProductCollection(DefaultProductCollection2Id, this.Any.AlphabeticText(20), true);
        // [GIVEN] Non-Default Product Collection.
        NonDefaultProductCollectionId := DefaultProductCollection2Id + 1;
        this.CreateProductCollection(NonDefaultProductCollectionId, this.Any.AlphabeticText(20), false);

        // [WHEN] Invoking the procedure: ProductAPI.CreateProduct.
        BindSubscription(ProductCollectionSubs);
        ProductId := ProductAPI.CreateProduct(TempProduct, TempShopifyVariant, ShopifyTag);
        UnbindSubscription(ProductCollectionSubs);

        // [THEN] Query for publishing the product is generated.
        ActualQuery := ProductCollectionSubs.GetPublishProductGraphQueryTxt();
        this.LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(ProductPublishQueryTok, ProductId)), 'Product Id is not in the query');
        // [THEN] Query for adding product contains default Product Collections.
        ActualQuery := ProductCollectionSubs.GetProductCreateGraphQueryTxt();
        this.LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, DefaultProductCollection1Id)), 'Product Collection Id is not in the query');
        this.LibraryAssert.IsTrue(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, DefaultProductCollection2Id)), 'Product Collection Id is not in the query');
        // [THEN] Query does not contain non-default Product Collection Id.
        this.LibraryAssert.IsFalse(ActualQuery.Contains(StrSubstNo(AddProductToCollectionQueryTok, NonDefaultProductCollectionId)), 'Non-default Product Collection Id is in the query')

    end;

    local procedure Initialize()
    begin
        this.Any.SetDefaultSeed();
        if this.IsInitialized then
            exit;
        this.Shop := this.InitializeTest.CreateShop();
        this.CreateDefaultSalesChannel();
        this.IsInitialized := true;
        Commit();
    end;

    local procedure CreateDefaultSalesChannel()
    var
        SalesChannel: Record "Shpfy Sales Channel";
    begin
        SalesChannel.Init();
        SalesChannel.Id := this.Any.IntegerInRange(10000, 99999);
        SalesChannel."Shop Code" := this.Shop.Code;
        SalesChannel.Name := this.Any.AlphabeticText(20);
        SalesChannel.Default := true;
        SalesChannel.Insert(false);
    end;

    local procedure CreateProductCollection(CollectionId: BigInteger; CollectionName: Text; IsDefault: Boolean)
    var
        ProductCollection: Record "Shpfy Product Collection";
    begin
        ProductCollection.Init();
        ProductCollection.Id := CollectionId;
        ProductCollection."Shop Code" := this.Shop.Code;
        ProductCollection.Name := CollectionName;
        ProductCollection.Default := IsDefault;
        ProductCollection.Insert(false);
    end;

    local procedure CreateProduct(var Product: Record "Shpfy Product"; Id: BigInteger)
    begin
        Product.Init();
        Product.Id := Id;
        Product."Shop Code" := this.Shop.Code;
        Product.Insert(false);
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
        ProductCollectionAPI.RetrieveCustomProductCollectionsFromShopify(this.Shop.Code);
        UnbindSubscription(ProductCollectionSubs);
    end;
}