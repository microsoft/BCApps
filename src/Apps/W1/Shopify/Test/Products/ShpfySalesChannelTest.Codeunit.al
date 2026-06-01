// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139698 "Shpfy Sales Channel Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        SalesChannelHelper: Codeunit "Shpfy Sales Channel Helper";
        IsInitialized: Boolean;
        GraphQueryTxt: Text;
        JEdges: JsonArray;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestImportSalesChannelTest()
    var
        SalesChannel: Record "Shpfy Sales Channel";
        JPublications: JsonArray;
    begin
        // [SCENARIO] Importing sales channel from Shopify to Business Central.
        Initialize();

        // [GIVEN] Shopify response with sales channel data.
        JPublications := SalesChannelHelper.GetDefaultShopifySalesChannelResponse(Any.IntegerInRange(10000, 99999), Any.IntegerInRange(10000, 99999));

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetSalesChannels');

        // [WHEN] Invoking the procedure: SalesChannelAPI.RetrieveSalesChannelsFromShopify
        InvokeRetrieveSalesChannelsFromShopify(JPublications);

        // [THEN] The sales channels are imported to Business Central.
        SalesChannel.SetRange("Shop Code", Shop.Code);
        LibraryAssert.IsFalse(SalesChannel.IsEmpty(), 'Sales Channel not created');
        LibraryAssert.AreEqual(2, SalesChannel.Count(), 'Sales Channel count is not equal to 2');
        SalesChannel.SetRange("Default", true);
        LibraryAssert.IsFalse(SalesChannel.IsEmpty(), 'Default Sales Channel not created');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestRemoveNotExistingChannelsTest()
    var
        SalesChannel: Record "Shpfy Sales Channel";
        JPublications: JsonArray;
        OnlineStoreId, POSId, AdditionalChannelId : BigInteger;
    begin
        // [SCENARIO] Removing not existing sales channels from Business Central.
        Initialize();

        // [GIVEN] Defult sales channels impported
        OnlineStoreId := Any.IntegerInRange(10000, 99999);
        POSId := Any.IntegerInRange(10000, 99999);
        CreateDefaultSalesChannels(OnlineStoreId, POSId);
        // [GIVEN] Additional sales channel
        AdditionalChannelId := Any.IntegerInRange(10000, 99999);
        CreateSalesChannel(Shop.Code, 'Additional Sales Channel', AdditionalChannelId, false);
        // [GIVEN] Shopify response with default sales channel data.
        JPublications := SalesChannelHelper.GetDefaultShopifySalesChannelResponse(OnlineStoreId, POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetSalesChannels');

        // [WHEN] Invoking the procedure: SalesChannelAPI.InvokeRetreiveSalesChannelsFromShopify
        InvokeRetrieveSalesChannelsFromShopify(JPublications);

        // [THEN] The additional sales channel is removed from Business Central.
        SalesChannel.SetRange("Shop Code", Shop.Code);
        SalesChannel.SetRange("Id", AdditionalChannelId);
        LibraryAssert.IsTrue(SalesChannel.IsEmpty(), 'Sales Channel not removed');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestPublishProductWitArchivedStatusTest()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyProductAPI: Codeunit "Shpfy Product API";
        OnlineShopId, POSId : BigInteger;
    begin
        // [SCENARIO] Publishing not active product to Shopify Sales Channel.
        Initialize();

        // [GIVEN] Product with archived status.
        CreateProductWithStatus(ShopifyProduct, Enum::"Shpfy Product Status"::Archived, Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default sales channels.
        OnlineShopId := Any.IntegerInRange(10000, 99999);
        POSId := OnlineShopId + 1;
        CreateDefaultSalesChannels(OnlineShopId, POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('PublishProduct');

        // [WHEN] Invoking the procedure: ShopifyProductAPI.PublishProduct(ShopifyProduct)
        GraphQueryTxt := '';
        ShopifyProductAPI.PublishProduct(ShopifyProduct);

        // [THEN] Publish product query was executed.
        LibraryAssert.AreNotEqual('', GraphQueryTxt, 'Publish product query was not executed');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestPublishProductWithDraftStatusTest()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyProductAPI: Codeunit "Shpfy Product API";
        OnlineShopId, POSId : BigInteger;
    begin
        // [SCENARIO] Publishing draft product to Shopify Sales Channel.
        Initialize();

        // [GIVEN] Product with draft status.
        CreateProductWithStatus(ShopifyProduct, Enum::"Shpfy Product Status"::Draft, Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default sales channels.
        OnlineShopId := Any.IntegerInRange(10000, 99999);
        POSId := OnlineShopId + 1;
        CreateDefaultSalesChannels(OnlineShopId, POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('PublishProduct');

        // [WHEN] Invoking the procedure: ShopifyProductAPI.PublishProduct(ShopifyProduct)
        GraphQueryTxt := '';
        ShopifyProductAPI.PublishProduct(ShopifyProduct);

        // [THEN] Publish product query was executed.
        LibraryAssert.AreNotEqual('', GraphQueryTxt, 'Publish product query was not executed');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestPublishProductToDefaultSalesChannelTest()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyProductAPI: Codeunit "Shpfy Product API";
        OnlineShopId: BigInteger;
        POSId: BigInteger;
        ActualQuery: Text;
    begin
        // [SCENARIO] Publishing active product to Shopify Sales Channel.
        Initialize();

        // [GIVEN] Product with active status.
        CreateProductWithStatus(ShopifyProduct, Enum::"Shpfy Product Status"::Active, Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default sales channels.
        OnlineShopId := Any.IntegerInRange(10000, 99999);
        POSId := OnlineShopId + 1;
        CreateDefaultSalesChannels(OnlineShopId, POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('PublishProduct');

        // [WHEN] Invoking the procedure: ShopifyProductAPI.PublishProduct(ShopifyProduct)
        GraphQueryTxt := '';
        ShopifyProductAPI.PublishProduct(ShopifyProduct);
        ActualQuery := GraphQueryTxt;

        // [THEN] Publish product query was executed.
        LibraryAssert.AreNotEqual('', ActualQuery, 'Publish product query was not executed');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestPublishProductToMultipleSalesChannelsTest()
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyProductAPI: Codeunit "Shpfy Product API";
        OnlineShopId, POSId : BigInteger;
        ActualQuery: Text;
    begin
        // [SCENARIO] Publishing active product to multiple Shopify Sales Channels.
        Initialize();

        // [GIVEN] Product with active status.
        CreateProductWithStatus(ShopifyProduct, Enum::"Shpfy Product Status"::Active, Any.IntegerInRange(10000, 99999));
        // [GIVEN] Default sales channels.
        OnlineShopId := Any.IntegerInRange(10000, 99999);
        POSId := OnlineShopId + 1;
        CreateDefaultSalesChannels(OnlineShopId, POSId);
        // [GIVEN] Online Shop used for publication
        SetPublicationForSalesChannel(OnlineShopId);
        // [GIVEN] POS used for publication
        SetPublicationForSalesChannel(POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('PublishProduct');

        // [WHEN] Invoking the procedure: ShopifyProductAPI.PublishProduct(ShopifyProduct)
        GraphQueryTxt := '';
        ShopifyProductAPI.PublishProduct(ShopifyProduct);
        ActualQuery := GraphQueryTxt;

        // [THEN] Publish product query was executed.
        LibraryAssert.AreNotEqual('', ActualQuery, 'Publish product query was not executed');
    end;

    [Test]
    [HandlerFunctions('SalesChannelHttpHandler')]
    procedure UnitTestPublishProductOnCreateProductTest()
    var
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ShopifyTag: Record "Shpfy Tag";
        ShopifyProductAPI: Codeunit "Shpfy Product API";
        OnlineShopId, POSId : BigInteger;
        ActualQuery: Text;
    begin
        // [SCENARIO] Publishing active product to Shopify Sales Channel on product creation.
        Initialize();

        // [GIVEN] Product with active status.
        CreateProductWithStatus(TempShopifyProduct, Enum::"Shpfy Product Status"::Active, 0);
        // [GIVEN] Shopify Variant
        CreateShopifyVariant(TempShopifyProduct, TempShopifyVariant, 0);
        // [GIVEN] Default sales channels.
        OnlineShopId := Any.IntegerInRange(10000, 99999);
        POSId := OnlineShopId + 1;
        CreateDefaultSalesChannels(OnlineShopId, POSId);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('ProductCreate');
        OutboundHttpRequests.Enqueue('VariantCreate');
        OutboundHttpRequests.Enqueue('PublishProduct');

        // [WHEN] Invoke Product API
        GraphQueryTxt := '';
        ShopifyProductAPI.CreateProduct(TempShopifyProduct, TempShopifyVariant, ShopifyTag);
        ActualQuery := GraphQueryTxt;

        // [THEN] Publish product query was executed.
        LibraryAssert.AreNotEqual('', ActualQuery, 'Publish product query was not executed');
    end;

    [HttpClientHandler]
    internal procedure SalesChannelHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RequestType: Text;
        BodyTxt: Text;
        EdgesTxt: Text;
        ResponseLbl: Label '{ "data": { "publications": { "edges": %1 } }}', Comment = '%1 - edges', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        if OutboundHttpRequests.Length() = 0 then
            exit(false);

        RequestType := OutboundHttpRequests.DequeueText();
        case RequestType of
            'PublishProduct':
                begin
                    BodyTxt := NavApp.GetResourceAsText('Products/EmptyPublishResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(BodyTxt);
                    GraphQueryTxt := 'PublishProduct';
                end;
            'ProductCreate':
                begin
                    BodyTxt := NavApp.GetResourceAsText('Products/CreatedProductResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(BodyTxt);
                end;
            'GetSalesChannels':
                begin
                    JEdges.WriteTo(EdgesTxt);
                    BodyTxt := StrSubstNo(ResponseLbl, EdgesTxt);
                    Response.Content.WriteFrom(BodyTxt);
                end;
            'VariantCreate':
                begin
                    Any.SetDefaultSeed();
                    BodyTxt := NavApp.GetResourceAsText('Products/CreatedVariantResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(StrSubstNo(BodyTxt, Any.IntegerInRange(100000, 999999)));
                end;
            'InventoryActivation':
                Response.Content.WriteFrom('{}');
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        Shop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateSalesChannel(ShopCode: Code[20]; ChannelName: Text[100]; ChannelId: BigInteger; IsDefault: Boolean)
    var
        SalesChannel: Record "Shpfy Sales Channel";
    begin
        SalesChannel.Init();
        SalesChannel.Id := ChannelId;
        SalesChannel."Shop Code" := ShopCode;
        SalesChannel.Name := ChannelName;
        SalesChannel.Default := IsDefault;
        SalesChannel.Insert(true);
    end;

    local procedure CreateDefaultSalesChannels(OnlineStoreId: BigInteger; POSId: BigInteger)
    var
        SalesChannel: Record "Shpfy Sales Channel";
    begin
        SalesChannel.DeleteAll(false);
        CreateSalesChannel(Shop.Code, 'Online Store', OnlineStoreId, true);
        CreateSalesChannel(Shop.Code, 'Point of Sale', POSId, false);
    end;

    local procedure CreateProductWithStatus(var ShopifyProduct: Record "Shpfy Product"; ShpfyProductStatus: Enum Microsoft.Integration.Shopify."Shpfy Product Status"; Id: BigInteger)
    begin
        ShopifyProduct.Init();
        ShopifyProduct.Id := Id;
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct.Status := ShpfyProductStatus;
        ShopifyProduct.Insert(true);
    end;

    local procedure SetPublicationForSalesChannel(SalesChannelId: BigInteger)
    var
        SalesChannel: Record "Shpfy Sales Channel";
    begin
        SalesChannel.Get(SalesChannelId);
        SalesChannel."Use for publication" := true;
        SalesChannel.Modify(false);
    end;

    local procedure CreateShopifyVariant(ShopifyProduct: Record "Shpfy Product"; var ShpfyVariant: Record "Shpfy Variant"; Id: BigInteger)
    begin
        ShpfyVariant.Init();
        ShpfyVariant.Id := Id;
        ShpfyVariant."Product Id" := ShopifyProduct.Id;
        ShpfyVariant.Insert(false);
    end;

    local procedure InvokeRetrieveSalesChannelsFromShopify(var JPublications: JsonArray)
    var
        SalesChannelAPI: Codeunit "Shpfy Sales Channel API";
    begin
        JEdges := JPublications;
        SalesChannelAPI.RetrieveSalesChannelsFromShopify(Shop.Code);
    end;
}
