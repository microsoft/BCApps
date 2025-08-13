// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using System.Reflection;
using System.Text;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;
using Microsoft.Integration.Shopify;
using System.Utilities;

codeunit 139540 "Shpfy Sync Variant Images Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        RequestVariantId, RequestProductId : BigInteger;
        Initialized: Boolean;
        ShopifyShopUrlTok: Label 'admin\/api\/.+\/graphql.json', Locked = true;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';

    trigger OnRun()
    begin
        Initialized := false;
    end;

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if Initialized then
            exit;
        Shop := InitializeTest.CreateShop();

        // Disable Event Mocking 
        CommunicationMgt.SetTestInProgress(false);
        //Register Shopify Access Token
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Initialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('HandleShopifyImportRequest')]
    procedure UnitTestImportVariantImageFromShopify()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyProduct: Record "Shpfy Product";
        LibraryInventory: Codeunit "Library - Inventory";
        VariantAPI: Codeunit "Shpfy Variant API";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
    begin
        // [SCENARIO] Importing variant image from Shopify variant
        Initialize();

        // [GIVEN] Register Expected Outbound API Requests
        RegExpectedOutboundHttpRequestsForGetVariantImages();
        // [GIVEN] Shop with setting to import images from shopify
        Shop."Sync Item Images" := Shop."Sync Item Images"::"From Shopify";
        Shop.Modify(false);
        // [GIVEN] Item with variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Shopify product
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyProduct."Item No." := Item."No.";
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct."Shop Code" := Shop."Code";
        ShopifyProduct.Insert(false);
        RequestProductId := ShopifyProduct.Id;
        // [GIVEN] Shopify variant
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item No." := Item."No.";
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        ShopifyVariant."Shop Code" := Shop."Code";
        ShopifyVariant.Insert(false);
        RequestVariantId := ShopifyVariant.Id;

        // [WHEN] Execute sync product image
        SyncProductImage.Run(Shop);

        // [THEN] Image is imported to variant
        ItemVariant.GetBySystemId(ItemVariant.SystemId);
        LibraryAssert.IsTrue(ItemVariant.Picture.Count = 1, 'Image was not imported to variant');
    end;

    [Test]
    [HandlerFunctions('HandleShopifyUploadRequest')]
    procedure UnitTestSetVariantImageInShopify()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyProduct: Record "Shpfy Product";
        LibraryInventory: Codeunit "Library - Inventory";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
    begin
        // [SCENARIO] Set variant image in shopify when there is no image in shopify
        Initialize();

        // [GIVEN] Register Expected Outbound API Requests
        RegExpectedOutboundHttpRequestsForUploadVariantImage();
        // [GIVEN] Shop with setting to sync image to shopify
        Shop."Sync Item Images" := Shop."Sync Item Images"::"To Shopify";
        Shop.Modify(false);
        // [GIVEN] Item with variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Item variant has image
        ImportImageToItemVariant(ItemVariant);
        // [GIVEN] Shopify product
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyProduct."Item No." := Item."No.";
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct."Shop Code" := Shop."Code";
        ShopifyProduct.Insert(false);
        RequestProductId := ShopifyProduct.Id;
        // [GIVEN] Shopify variant
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item No." := Item."No.";
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        ShopifyVariant."Shop Code" := Shop."Code";
        ShopifyVariant.Insert(false);
        RequestVariantId := ShopifyVariant.Id;

        // [WHEN] Execute sync product image
        SyncProductImage.Run(Shop);


    end;


    [HttpClientHandler]
    procedure HandleShopifyImportRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        GetProductImagesResponseTok: Label 'Products/EmptyProdImagesResponse.txt', Locked = true;
        GetVariantImagesResponseTok: Label 'Products/GetVariantImagesResponse.txt', Locked = true;
        ImageResponseTok: Label 'Products/ImageResponse.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            3:
                LoadResourceIntoHttpResponse(GetProductImagesResponseTok, Response);
            2:
                LoadVariantResourceIntoHttpResponse(GetVariantImagesResponseTok, Response);
            1:
                LoadResourceIntoHttpResponse(ImageResponseTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
    end;

    [HttpClientHandler]
    procedure HandleShopifyUploadRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        CreateUploadUrlTok: Label 'Products/CreateUploadUrl.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            1:
                LoadResourceIntoHttpResponse(CreateUploadUrlTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
    end;


    local procedure RegExpectedOutboundHttpRequestsForGetVariantImages()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Product Images');
        OutboundHttpRequests.Enqueue('GQL Get Variant Images');
        OutboundHttpRequests.Enqueue('Get Image');
    end;

    local procedure RegExpectedOutboundHttpRequestsForUploadVariantImage()
    begin
        OutboundHttpRequests.Enqueue('GQL Upload Variant Image');

    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadVariantResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8).Replace('{{VariantId}}', Format(RequestVariantId)));
        OutboundHttpRequests.DequeueText();
    end;

    local procedure ImportImageToItemVariant(var ItemVariant: Record "Item Variant")
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        ImageResponseTok: Label 'Products/ImageResponse.txt', Locked = true;
    begin
        // Example Base64 image (replace with actual image data as needed)
        TempBlob.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(NavApp.GetResourceAsText(ImageResponseTok, TextEncoding::UTF8));
        ItemVariant.Picture.ImportStream(InStr, 'test');
        ItemVariant.Modify(false);
    end;
}
