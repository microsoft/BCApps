// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139633 "Shpfy Bulk Operations Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Shopify]
        IsInitialized := false;
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;

        BulkOpSubscriber: Codeunit "Shpfy Bulk Op. Subscriber";
        IsInitialized: Boolean;
        BulkOperationId1: BigInteger;
        BulkOperationId2: BigInteger;

    local procedure Initialize()

    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        BulkOperationId1 := Any.IntegerInRange(100000, 555555);
        BulkOperationId2 := Any.IntegerInRange(555555, 999999);
        if BindSubscription(BulkOpSubscriber) then;
    end;

    local procedure ClearSetup()
    var
        BulkOperation: Record "Shpfy Bulk Operation";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        BulkOperation.DeleteAll();
        BulkOpSubscriber.SetBulkOperationRunning(false);
        BulkOpSubscriber.SetBulkUploadFail(false);
        ShopifyVariant.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler')]
    procedure TestSendBulkOperation()
    var
        Shop: Record "Shpfy Shop";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation creates a bulk operation record

        // [GIVEN] A Shop record
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();

        // [WHEN] A bulk operation is sent
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId1);
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        LibraryAssert.IsTrue(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is created
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.AreEqual(BulkOperation.Status, BulkOperation.Status::Created, 'Bulk operation should be created.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler')]
    procedure TestSendBulkOperationAfterPreviousCompleted()
    var
        Shop: Record "Shpfy Shop";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation after previous one completed creates a bulk operation record

        // [GIVEN] A Shop record
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();

        // [WHEN] A bulk operation is sent and completed
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId1);
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData);
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        BulkOperation.Status := BulkOperation.Status::Completed;
        BulkOperation.Modify();
        // [WHEN] A second bulk operation is sent
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId2);
        tb.Clear();
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 4", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 5", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 6", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        LibraryAssert.IsTrue(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is created
        BulkOperation.Get(BulkOperationId2, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.AreEqual(BulkOperation.Status, BulkOperation.Status::Created, 'Bulk operation should be created.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler')]
    procedure TestSendBulkOperationBeforePreviousCompleted()
    var
        Shop: Record "Shpfy Shop";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation after previous one has not complete does not create a bulk operation record

        // [GIVEN] A Shop record
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();

        // [WHEN] A bulk operation is sent and not completed
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId1);
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData);
        // [WHEN] A second bulk operation is sent
        BulkOpSubscriber.SetBulkOperationRunning(true);
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId2);
        tb.Clear();
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 4", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 5", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 6", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        LibraryAssert.IsFalse(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is not created
        LibraryAssert.RecordCount(BulkOperation, 1);
        ClearSetup();
    end;

    [Test]
    procedure TestBulkOperationUploadFailSilent()
    var
        Shop: Record "Shpfy Shop";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a faulty bulk operation fails silently

        // [GIVEN] A Shop record
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();

        // [WHEN] A bulk operation is sent with upload failure
        BulkOpSubscriber.SetBulkUploadFail(true);
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId1);
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));

        // [THEN] A bulk operation fails silently
        LibraryAssert.IsFalse(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');
        ClearSetup();
    end;

    [Test]
    procedure TestBulkOperationRevertFailed()
    var
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
        BulkOperationUrl: Text;
    begin
        // [SCENARIO] A bulk operation completes but some operations failed and they are reverted

        // [GIVEN] A bulk operation record and four variants
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        for Index := 1 to 4 do begin
            ProductId := Any.IntegerInRange(100000, 555555);
            VariantId := Any.IntegerInRange(100000, 555555);
            VariantIds.Add(VariantId);
            ShopifyVariant."Product Id" := ProductId;
            ShopifyVariant.Id := VariantId;
            ShopifyVariant.Price := 200;
            ShopifyVariant."Compare at Price" := 250;
            ShopifyVariant."Unit Cost" := 75;
            ShopifyVariant.Insert();
        end;
        BulkOperationUrl := Any.AlphabeticText(50);
        BulkOperation := CreateBulkOperation(BulkOperationId1, BulkOperationType::UpdateProductPrice, Shop.Code, BulkOperationUrl, GenerateRequestData(VariantIds, 100, 150, 50));

        // [WHEN] Bulk operation is completed
        BulkOpSubscriber.SetBulkOperationId(BulkOperationId1);
        BulkOpSubscriber.SetBulkOperationUrl(BulkOperationUrl);
        BulkOpSubscriber.SetVariantIds(VariantIds.Get(1), VariantIds.Get(4));
        BulkOperation.Status := BulkOperation.Status::Completed;
        BulkOperation.Modify(true);

        // [THEN] The bulk operation is processed and failed variants are reverted
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.IsTrue(BulkOperation.Processed, 'Bulk operation should be processed.');
        ShopifyVariant.Get(VariantIds.Get(1));
        LibraryAssert.AreEqual(200, ShopifyVariant.Price, 'Variant price should not be reverted.');
        LibraryAssert.AreEqual(250, ShopifyVariant."Compare at Price", 'Variant compare at price should not be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should not be reverted.');
        ShopifyVariant.Get(VariantIds.Get(2));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(50, ShopifyVariant."Unit Cost", 'Variant unit cost should be reverted.');
        ShopifyVariant.Get(VariantIds.Get(3));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(50, ShopifyVariant."Unit Cost", 'Variant unit cost should be reverted.');
        ShopifyVariant.Get(VariantIds.Get(4));
        LibraryAssert.AreEqual(200, ShopifyVariant.Price, 'Variant price should not be reverted.');
        LibraryAssert.AreEqual(250, ShopifyVariant."Compare at Price", 'Variant compare at price should not be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should not be reverted.');
        ClearSetup();
    end;

    [Test]
    procedure TestBulkOperationRevertAll()
    var
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
        BulkOperationUrl: Text;
    begin
        // [SCENARIO] A bulk operation fails and all operations are reverted

        // [GIVEN] A bulk operation record and two variants
        Initialize();
        Shop := CommunicationMgt.GetShopRecord();
        for Index := 1 to 2 do begin
            ProductId := Any.IntegerInRange(100000, 555555);
            VariantId := Any.IntegerInRange(100000, 555555);
            VariantIds.Add(VariantId);
            ShopifyVariant."Product Id" := ProductId;
            ShopifyVariant.Id := VariantId;
            ShopifyVariant.Price := 200;
            ShopifyVariant."Compare at Price" := 250;
            ShopifyVariant."Unit Cost" := 75;
            ShopifyVariant.Insert();
        end;
        BulkOperationUrl := Any.AlphabeticText(50);
        BulkOperation := CreateBulkOperation(BulkOperationId1, BulkOperationType::UpdateProductPrice, Shop.Code, BulkOperationUrl, GenerateRequestData(VariantIds, 100, 150, 50));

        // [WHEN] Bulk operation is failed
        BulkOperation.Status := BulkOperation.Status::Failed;
        BulkOperation.Modify(true);

        // [THEN] The bulk operation is processed and all variants are reverted
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.IsTrue(BulkOperation.Processed, 'Bulk operation should be processed.');
        ShopifyVariant.Get(VariantIds.Get(1));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(50, ShopifyVariant."Unit Cost", 'Variant unit cost should be reverted.');
        ShopifyVariant.Get(VariantIds.Get(2));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(50, ShopifyVariant."Unit Cost", 'Variant unit cost should be reverted.');
        ClearSetup();
    end;

    [Test]
    procedure TestBulkUpdateProductPriceClearsCompareAtPriceAsNull()
    var
        ShopifyVariant: Record "Shpfy Variant";
        xShopifyVariant: Record "Shpfy Variant";
        VariantApi: Codeunit "Shpfy Variant API";
        BulkOperationInput: TextBuilder;
        GraphQueryList: Dictionary of [BigInteger, TextBuilder];
        JRequestData: JsonArray;
        Jsonl: Text;
    begin
        // [SCENARIO] Bug fix for ICM 21000001004461: when Compare at Price is cleared (set to 0)
        // on the bulk path, the JSONL must contain "compareAtPrice": null, not "compareAtPrice": "0".
        Initialize();
        ClearSetup();

        // [GIVEN] A Shopify variant whose Compare at Price has just been cleared (200 -> 0)
        ShopifyVariant.Init();
        ShopifyVariant."Product Id" := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Id := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Price := 100;
        ShopifyVariant."Compare at Price" := 0;
        ShopifyVariant."Unit Cost" := 50;
        ShopifyVariant.Insert();
        xShopifyVariant := ShopifyVariant;
        xShopifyVariant."Compare at Price" := 200;

        // [WHEN] UpdateProductPrice runs on the bulk path (RecordCount >= 100)
        VariantApi.UpdateProductPrice(ShopifyVariant, xShopifyVariant, BulkOperationInput, GraphQueryList, 100, JRequestData);

        // [THEN] The JSONL line clears Compare at Price with the literal token null, not the string "0"
        Jsonl := BulkOperationInput.ToText();
        LibraryAssert.IsTrue(Jsonl.Contains('"compareAtPrice": null'), 'JSONL must clear Compare at Price with null. Was: ' + Jsonl);
        LibraryAssert.IsFalse(Jsonl.Contains('"compareAtPrice": "0"'), 'JSONL must not send Compare at Price as the string "0". Was: ' + Jsonl);
        LibraryAssert.IsFalse(Jsonl.Contains('"compareAtPrice": "null"'), 'JSONL must not quote the null token. Was: ' + Jsonl);
        ClearSetup();
    end;

    [Test]
    procedure TestBulkUpdateProductPriceOmitsUnchangedCompareAtPrice()
    var
        ShopifyVariant: Record "Shpfy Variant";
        xShopifyVariant: Record "Shpfy Variant";
        VariantApi: Codeunit "Shpfy Variant API";
        BulkOperationInput: TextBuilder;
        GraphQueryList: Dictionary of [BigInteger, TextBuilder];
        JRequestData: JsonArray;
        Jsonl: Text;
    begin
        // [SCENARIO] Bug fix for ICM 21000001004461: when only Price changes and Compare at Price
        // is unchanged in BC, the bulk path must omit compareAtPrice from the JSONL so that
        // Shopify preserves whatever value is currently set on the variant.
        Initialize();
        ClearSetup();

        // [GIVEN] A Shopify variant with Compare at Price = 0 (unchanged), Price changing 80 -> 100
        ShopifyVariant.Init();
        ShopifyVariant."Product Id" := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Id := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Price := 100;
        ShopifyVariant."Compare at Price" := 0;
        ShopifyVariant."Unit Cost" := 50;
        ShopifyVariant.Insert();
        xShopifyVariant := ShopifyVariant;
        xShopifyVariant.Price := 80;

        // [WHEN] UpdateProductPrice runs on the bulk path
        VariantApi.UpdateProductPrice(ShopifyVariant, xShopifyVariant, BulkOperationInput, GraphQueryList, 100, JRequestData);

        // [THEN] compareAtPrice is not in the JSONL at all - Shopify preserves its existing value
        Jsonl := BulkOperationInput.ToText();
        LibraryAssert.IsFalse(Jsonl.Contains('compareAtPrice'), 'JSONL must omit compareAtPrice when unchanged in BC. Was: ' + Jsonl);
        ClearSetup();
    end;

    [Test]
    procedure TestBulkUpdateProductPriceSendsValidCompareAtPriceAsQuoted()
    var
        ShopifyVariant: Record "Shpfy Variant";
        xShopifyVariant: Record "Shpfy Variant";
        VariantApi: Codeunit "Shpfy Variant API";
        BulkOperationInput: TextBuilder;
        GraphQueryList: Dictionary of [BigInteger, TextBuilder];
        JRequestData: JsonArray;
        Jsonl: Text;
    begin
        // [SCENARIO] When Compare at Price is set above Price (a valid sale price), the bulk path
        // must send the value as a quoted decimal string, matching the non-bulk GraphQL path.
        Initialize();
        ClearSetup();

        // [GIVEN] Variant going on sale: Price 100, Compare at Price changing 0 -> 200
        ShopifyVariant.Init();
        ShopifyVariant."Product Id" := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Id := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Price := 100;
        ShopifyVariant."Compare at Price" := 200;
        ShopifyVariant."Unit Cost" := 50;
        ShopifyVariant.Insert();
        xShopifyVariant := ShopifyVariant;
        xShopifyVariant."Compare at Price" := 0;

        // [WHEN] UpdateProductPrice runs on the bulk path
        VariantApi.UpdateProductPrice(ShopifyVariant, xShopifyVariant, BulkOperationInput, GraphQueryList, 100, JRequestData);

        // [THEN] Compare at Price is sent as a quoted decimal string
        Jsonl := BulkOperationInput.ToText();
        LibraryAssert.IsTrue(Jsonl.Contains('"compareAtPrice": "200'), 'JSONL must send positive Compare at Price as a quoted decimal. Was: ' + Jsonl);
        LibraryAssert.IsFalse(Jsonl.Contains('"compareAtPrice": null'), 'JSONL must not null out a valid Compare at Price. Was: ' + Jsonl);
        ClearSetup();
    end;

    [Test]
    procedure TestBulkUpdateProductPriceOmitsUnchangedPositiveCompareAtPrice()
    var
        ShopifyVariant: Record "Shpfy Variant";
        xShopifyVariant: Record "Shpfy Variant";
        VariantApi: Codeunit "Shpfy Variant API";
        BulkOperationInput: TextBuilder;
        GraphQueryList: Dictionary of [BigInteger, TextBuilder];
        JRequestData: JsonArray;
        Jsonl: Text;
    begin
        // [SCENARIO] When only Unit Cost changes and Compare at Price is unchanged (even if
        // currently > Price), the bulk path must omit compareAtPrice so Shopify preserves it.
        Initialize();
        ClearSetup();

        // [GIVEN] Variant with valid sale (Compare 200 > Price 100); only Unit Cost changes
        ShopifyVariant.Init();
        ShopifyVariant."Product Id" := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Id := Any.IntegerInRange(100000, 555555);
        ShopifyVariant.Price := 100;
        ShopifyVariant."Compare at Price" := 200;
        ShopifyVariant."Unit Cost" := 75;
        ShopifyVariant.Insert();
        xShopifyVariant := ShopifyVariant;
        xShopifyVariant."Unit Cost" := 50;

        // [WHEN] UpdateProductPrice runs on the bulk path
        VariantApi.UpdateProductPrice(ShopifyVariant, xShopifyVariant, BulkOperationInput, GraphQueryList, 100, JRequestData);

        // [THEN] compareAtPrice is omitted entirely - Shopify keeps its current value
        Jsonl := BulkOperationInput.ToText();
        LibraryAssert.IsFalse(Jsonl.Contains('compareAtPrice'), 'JSONL must omit unchanged compareAtPrice. Was: ' + Jsonl);
        ClearSetup();
    end;

    local procedure CreateBulkOperation(BulkOperationId: BigInteger; BulkOperationType: Enum "Shpfy Bulk Operation Type"; ShopCode: Code[20]; BulkOperationUrl: Text; RequestData: JsonArray): Record "Shpfy Bulk Operation"
    var
        BulkOperation: Record "Shpfy Bulk Operation";
    begin
        BulkOperation."Bulk Operation Id" := BulkOperationId;
        BulkOperation.Type := BulkOperation.Type::mutation;
        BulkOperation."Shop Code" := ShopCode;
        BulkOperation."Bulk Operation Type" := BulkOperationType;
        BulkOperation.Processed := false;
        BulkOperation.Url := CopyStr(BulkOperationUrl, 1, MaxStrLen(BulkOperation.Url));
        BulkOperation.Insert();
        BulkOperation.SetRequestData(RequestData);
        exit(BulkOperation);
    end;

    local procedure GenerateRequestData(VariantIds: List of [BigInteger]; Price: Decimal; CompareAtPrice: Decimal; UnitCost: Decimal): JsonArray
    var
        RequestData: JsonArray;
        VariantId: BigInteger;
        Data: JsonObject;
    begin
        foreach VariantId in VariantIds do begin
            Clear(Data);
            Data.Add('id', VariantId);
            Data.Add('price', Price);
            Data.Add('compareAtPrice', CompareAtPrice);
            Data.Add('unitCost', UnitCost);
            Data.Add('updatedAt', '2025-02-25T13:40:15.6530000Z');
            RequestData.Add(Data);
        end;
        exit(RequestData);
    end;

    [MessageHandler]
    procedure BulkMessageHandler(Message: Text[1024])
    var
        BulkOperationMsg: Label 'A bulk request was sent to Shopify. You can check the status of the synchronization in the Shopify Bulk Operations page.', Locked = true;
    begin
        LibraryAssert.ExpectedMessage(BulkOperationMsg, Message);
    end;
}
