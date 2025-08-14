// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify.Test;
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
    EventSubscriberInstance = Manual;
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
        Product: Record "Shpfy Product";
        Variant: Record "Shpfy Variant";
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if Initialized then begin
            Product.SetRange("Shop Code", Shop.Code);
            Product.DeleteAll();
            Variant.SetRange("Shop Code", Shop.Code);
            Variant.DeleteAll();
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
        LibraryAssert.IsTrue(ItemVariant.Picture.Count = 1, 'Image was not imported to variant.');
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
        ShpfySyncVariantImgHelper: Codeunit "Shpfy Sync Variant Img Helper";
        ImageId: BigInteger;
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
        // [GIVEN] Shopify variant
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item No." := Item."No.";
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        ShopifyVariant."Shop Code" := Shop."Code";
        ShopifyVariant.Insert(false);

        // [WHEN] Execute sync product image
        BindSubscription(ShpfySyncVariantImgHelper);
        SyncProductImage.Run(Shop);
        UnbindSubscription(ShpfySyncVariantImgHelper);

        // [THEN] Variant image is updated in Shopify
        ShopifyVariant.GetBySystemId(ShopifyVariant.SystemId);
        Evaluate(ImageId, '1234567891011');
        LibraryAssert.IsTrue(ShopifyVariant."Image Id" = ImageId, 'Variant image was not updated in Shopify.');
        LibraryAssert.IsTrue(ShopifyVariant."Image Hash" <> 0, 'Variant image hash was not updated.');
    end;

    [Test]
    [HandlerFunctions('HandleShopifyUpdateVariantPictureRequests')]
    procedure UnitTestUpdateVariantPictureRequests()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyProduct: Record "Shpfy Product";
        LibraryInventory: Codeunit "Library - Inventory";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
        ShpfySyncVariantImgHelper: Codeunit "Shpfy Sync Variant Img Helper";
        ImageId, ImageHash : BigInteger;
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
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyProduct."Item No." := Item."No.";
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct."Shop Code" := Shop."Code";
        ShopifyProduct.Insert(false);
        // [GIVEN] Shopify variant
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item No." := Item."No.";
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        ShopifyVariant."Shop Code" := Shop."Code";
        ShopifyVariant.Insert(false);
        ShopifyVariant."Image Id" := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Image Hash" := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant.Modify(false);
        ImageHash := ShopifyVariant."Image Hash";

        // [WHEN] Execute sync product image
        BindSubscription(ShpfySyncVariantImgHelper);
        SyncProductImage.Run(Shop);
        UnbindSubscription(ShpfySyncVariantImgHelper);

        // [THEN] Variant image is updated in Shopify
        ShopifyVariant.GetBySystemId(ShopifyVariant.SystemId);
        Evaluate(ImageId, '1234567891011');
        LibraryAssert.IsTrue(ShopifyVariant."Image Id" = ImageId, 'Variant image was not updated in Shopify.');
        LibraryAssert.IsTrue(ShopifyVariant."Image Hash" <> ImageHash, 'Variant image hash was not updated.');
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
        UploadImageTok: Label 'Products/UploadImageToProductResponse.txt', Locked = true;
        VariantSuccessAttachResponseTok: Label 'Products/VariantSuccessAttachResponse.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            3:
                LoadResourceIntoHttpResponse(CreateUploadUrlTok, Response);
            2:
                LoadResourceIntoHttpResponse(UploadImageTok, Response);
            1:
                LoadResourceIntoHttpResponse(VariantSuccessAttachResponseTok, Response);
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
        VariantSuccessAttachResponseTok: Label 'Products/VariantSuccessAttachResponse.txt', Locked = true;
        VariantSuccessDetachResponseTok: Label 'Products/VariantSuccessDetachResponse.txt', Locked = true;
    begin
        case OutboundHttpRequests.Length() of
            5:
                LoadVariantResourceIntoHttpResponse(GetVariantImageResponseTok, Response);
            4:
                LoadResourceIntoHttpResponse(CreateUploadUrlTok, Response);
            3:
                LoadResourceIntoHttpResponse(UploadImageTok, Response);
            2:
                LoadResourceIntoHttpResponse(VariantSuccessDetachResponseTok, Response);
            1:
                LoadResourceIntoHttpResponse(VariantSuccessAttachResponseTok, Response);
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
        OutboundHttpRequests.Enqueue('GQL Upload Product Image');
        OutboundHttpRequests.Enqueue('GQL Attach Image to Variant');
    end;

    local procedure RegExpectedOutboundHttpRequestsForUpdateVariantPicture()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Variant Image');
        OutboundHttpRequests.Enqueue('GQL Create Upload URL');
        OutboundHttpRequests.Enqueue('GQL Upload Product Image');
        OutboundHttpRequests.Enqueue('GQL Detach Image from Variant');
        OutboundHttpRequests.Enqueue('GQL Attach Image to Variant');

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
        TempBlob.CreateInStream(InStr);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(NavApp.GetResourceAsText(ImageResponseTok, TextEncoding::UTF8));
        ItemVariant.Picture.ImportStream(InStr, 'test');
        ItemVariant.Modify(false);
    end;
}
