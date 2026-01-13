// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139538 "Shpfy Sync Variant Images Test"
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
        RequestVariantId, RequestProductId : BigInteger;
        Initialized: Boolean;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';

    trigger OnRun()
    begin
        Initialized := false;
    end;

    local procedure Initialize()
    var
        Product: Record "Shpfy Product";
        Variant: Record "Shpfy Variant";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if Initialized then begin
            Product.SetRange("Shop Code", Shop.Code);
            Product.DeleteAll(false);
            Variant.SetRange("Shop Code", Shop.Code);
            Variant.DeleteAll(false);
            exit;
        end;
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
        LibraryInventory: Codeunit "Library - Inventory";
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
        RequestProductId := CreateProduct(Item);
        // [GIVEN] Shopify variant
        RequestVariantId := CreateVariant(Item, ItemVariant, RequestProductId, 12345);

        // [WHEN] Execute sync product image
        SyncProductImage.Run(Shop);

        // [THEN] Image is imported to variant
        ItemVariant.GetBySystemId(ItemVariant.SystemId);
        LibraryAssert.AreEqual(1, ItemVariant.Picture.Count, 'Image was not imported to variant.');
    end;

    [Test]
    [HandlerFunctions('HandleShopifyUploadRequest')]
    procedure UnitTestSetVariantImageInShopify()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Variant: Record "Shpfy Variant";
        LibraryInventory: Codeunit "Library - Inventory";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
        SyncVariantImgHelper: Codeunit "Shpfy Sync Variant Img Helper";
        ImageId, ProductId, VariantId : BigInteger;
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
        ProductId := CreateProduct(Item);
        // [GIVEN] Shopify variant
        VariantId := CreateVariant(Item, ItemVariant, ProductId);

        // [WHEN] Execute sync product image
        BindSubscription(SyncVariantImgHelper);
        SyncProductImage.Run(Shop);
        UnbindSubscription(SyncVariantImgHelper);

        // [THEN] Variant image is updated in Shopify
        Variant.Get(VariantId);
        Evaluate(ImageId, '1234567891011');
        LibraryAssert.AreEqual(ImageId, Variant."Image Id", 'Variant image was not updated in Shopify.');
        LibraryAssert.AreNotEqual(0, Variant."Image Hash", 'Variant image hash was not updated.');
    end;

    [Test]
    [HandlerFunctions('HandleShopifyUpdateVariantPictureRequests')]
    procedure UnitTestUpdateVariantPictureInShopify()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Variant: Record "Shpfy Variant";
        LibraryInventory: Codeunit "Library - Inventory";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
        SyncVariantImgHelper: Codeunit "Shpfy Sync Variant Img Helper";
        ImageId, ImageHash, ProductId : BigInteger;
    begin
        // [SCENARIO] Update variant picture in Shopify
        Initialize();

        // [GIVEN] Register Expected Outbound API Requests
        RegExpectedOutboundHttpRequestsForUpdateVariantPicture();
        // [GIVEN] Shop with setting to sync image to shopify
        Shop."Sync Item Images" := Shop."Sync Item Images"::"To Shopify";
        Shop.Modify(false);
        // [GIVEN] Item with variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Item variant has image
        ImportImageToItemVariant(ItemVariant);
        // [GIVEN] Shopify product
        ProductId := CreateProduct(Item);
        // [GIVEN] Shopify variant with existing image
        Variant.Get(CreateVariant(Item, ItemVariant, ProductId));
        ImageHash := SetVariantImageFields(Variant);

        // [WHEN] Execute sync product image
        BindSubscription(SyncVariantImgHelper);
        SyncProductImage.Run(Shop);
        UnbindSubscription(SyncVariantImgHelper);

        // [THEN] Variant image is updated in Shopify
        Variant.GetBySystemId(Variant.SystemId);
        Evaluate(ImageId, '1234567891011');
        LibraryAssert.AreEqual(ImageId, Variant."Image Id", 'Variant image was not updated in Shopify.');
        LibraryAssert.AreNotEqual(ImageHash, Variant."Image Hash", 'Variant image hash was not updated.');
    end;

    [HttpClientHandler]
    procedure HandleShopifyImportRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
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
        UploadVariantImageResponseTok: Label 'Products/UploadVariantImageResponse.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            2:
                LoadResourceIntoHttpResponse(CreateUploadUrlTok, Response);
            1:
                LoadResourceIntoHttpResponse(UploadVariantImageResponseTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
    end;

    [HttpClientHandler]
    procedure HandleShopifyUpdateVariantPictureRequests(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        GetVariantImageResponseTok: Label 'Products/GetVariantImageResponse.txt', Locked = true;
        CreateUploadUrlTok: Label 'Products/CreateUploadUrl.txt', Locked = true;
        UploadImageTok: Label 'Products/UploadImageToProductResponse.txt', Locked = true;
        UploadVariantImageResponseTok: Label 'Products/UploadVariantImageResponse.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            4:
                LoadVariantResourceIntoHttpResponse(GetVariantImageResponseTok, Response);
            3:
                LoadResourceIntoHttpResponse(CreateUploadUrlTok, Response);
            2:
                LoadResourceIntoHttpResponse(UploadImageTok, Response);
            1:
                LoadResourceIntoHttpResponse(UploadVariantImageResponseTok, Response);
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
        OutboundHttpRequests.Enqueue('GQL Create Upload URL');
        OutboundHttpRequests.Enqueue('GQL Upload Image to Variant');
    end;

    local procedure RegExpectedOutboundHttpRequestsForUpdateVariantPicture()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Variant Image');
        OutboundHttpRequests.Enqueue('GQL Create Upload URL');
        OutboundHttpRequests.Enqueue('GQL Upload Product Image');
        OutboundHttpRequests.Enqueue('GQL Set Image to Variant');
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
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        ImageResponseTok: Label 'Products/ImageResponse.txt', Locked = true;
    begin
        TempBlob.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(NavApp.GetResourceAsText(ImageResponseTok, TextEncoding::UTF8));
        ItemVariant.Picture.ImportStream(InStr, 'test');
        ItemVariant.Modify(false);
    end;

    local procedure CreateProduct(Item: Record Item): BigInteger
    var
        Product: Record "Shpfy Product";
    begin
        Product.Init();
        Product.Id := Any.IntegerInRange(1000000, 9999999);
        Product."Item No." := Item."No.";
        Product."Item SystemId" := Item.SystemId;
        Product."Shop Code" := Shop."Code";
        Product.Insert(false);
        exit(Product.Id);
    end;

    local procedure CreateVariant(Item: Record Item; ItemVariant: Record "Item Variant"; ProductId: BigInteger): BigInteger
    begin
        exit(CreateVariant(Item, ItemVariant, ProductId, 0));
    end;

    local procedure CreateVariant(Item: Record Item; ItemVariant: Record "Item Variant"; ProductId: BigInteger; VariantId: BigInteger): BigInteger
    var
        Variant: Record "Shpfy Variant";
    begin
        Variant.Init();
        if VariantId <> 0 then
            Variant.Id := VariantId
        else
            Variant.Id := Any.IntegerInRange(1000000, 9999999);
        Variant."Product Id" := ProductId;
        Variant."Item No." := Item."No.";
        Variant."Item SystemId" := Item.SystemId;
        Variant."Item Variant SystemId" := ItemVariant.SystemId;
        Variant."Shop Code" := Shop."Code";
        Variant.Insert(false);
        exit(Variant.Id);
    end;

    local procedure SetVariantImageFields(Variant: Record "Shpfy Variant"): BigInteger
    begin
        Variant."Image Id" := Any.IntegerInRange(1000000, 9999999);
        Variant."Image Hash" := Any.IntegerInRange(1000000, 9999999);
        Variant.Modify(false);
        exit(Variant."Image Hash");
    end;
}
