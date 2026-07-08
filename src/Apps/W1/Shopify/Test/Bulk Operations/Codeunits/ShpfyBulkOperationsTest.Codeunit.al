// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139633 "Shpfy Bulk Operations Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    trigger OnRun()
    begin
        // [FEATURE] [Shopify]
        IsInitialized := false;
    end;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryRandom: Codeunit "Library - Random";
        GraphQLResponses: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        BulkOperationId1: BigInteger;
        BulkOperationId2: BigInteger;
        BulkOperationIdCurrent: BigInteger;
        BulkOperationRunning: Boolean;
        BulkUploadFail: Boolean;
        BulkOperationUrl: Text;
        VariantId1: BigInteger;
        VariantId2: BigInteger;
        UploadUrlLbl: Label 'https://shopify-staged-uploads.storage.googleapis.com', Locked = true;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        BulkOperationId1 := Any.IntegerInRange(100000, 555555);
        BulkOperationId2 := Any.IntegerInRange(555555, 999999);
    end;

    local procedure ClearSetup()
    var
        BulkOperation: Record "Shpfy Bulk Operation";
        ShopifyVariant: Record "Shpfy Variant";
        SkippedRecord: Record "Shpfy Skipped Record";
    begin
        BulkOperation.DeleteAll();
        BulkOperationRunning := false;
        BulkUploadFail := false;
        ShopifyVariant.DeleteAll();
        SkippedRecord.DeleteAll();
        GraphQLResponses.Clear();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler,BulkOperationHttpHandler')]
    procedure TestSendBulkOperation()
    var
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation creates a bulk operation record

        // [GIVEN] A Shop record
        Initialize();

        // [WHEN] A bulk operation is sent
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        EnqueueGraphQLResponsesForSendBulkMutation();
        LibraryAssert.IsTrue(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is created
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.AreEqual(BulkOperation.Status, BulkOperation.Status::Created, 'Bulk operation should be created.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler,BulkOperationHttpHandler')]
    procedure TestSendBulkOperationAfterPreviousCompleted()
    var
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation after previous one completed creates a bulk operation record

        // [GIVEN] A Shop record
        Initialize();

        // [WHEN] A bulk operation is sent and completed
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        EnqueueGraphQLResponsesForSendBulkMutation();
        BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData);
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        BulkOperation.Status := BulkOperation.Status::Completed;
        BulkOperation.Modify();
        // [WHEN] A second bulk operation is sent
        BulkOperationIdCurrent := BulkOperationId2;
        tb.Clear();
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 4", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 5", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 6", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        EnqueueGraphQLResponsesForSendBulkMutation();
        LibraryAssert.IsTrue(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is created
        BulkOperation.Get(BulkOperationId2, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.AreEqual(BulkOperation.Status, BulkOperation.Status::Created, 'Bulk operation should be created.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler,BulkOperationHttpHandler')]
    procedure TestSendBulkOperationBeforePreviousCompleted()
    var
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a bulk operation after previous one has not complete does not create a bulk operation record

        // [GIVEN] A Shop record
        Initialize();

        // [WHEN] A bulk operation is sent and not completed
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        EnqueueGraphQLResponsesForSendBulkMutation();
        BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData);
        // [WHEN] A second bulk operation is sent
        BulkOperationRunning := true;
        BulkOperationIdCurrent := BulkOperationId2;
        tb.Clear();
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 4", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 5", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        tb.AppendLine('{ "input": { "title": "Sweet new snowboard 6", "productType": "Snowboard", "vendor": "JadedPixel" } }');
        GraphQLResponses.Enqueue('CurrentOperation');
        LibraryAssert.IsFalse(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');

        // [THEN] A bulk operation record is not created
        LibraryAssert.RecordCount(BulkOperation, 1);
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkOperationHttpHandler')]
    procedure TestBulkOperationUploadFailSilent()
    var
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Sending a faulty bulk operation fails silently

        // [GIVEN] A Shop record
        Initialize();

        // [WHEN] A bulk operation is sent with upload failure
        BulkUploadFail := true;
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 3', 'Snowboard', 'JadedPixel'));
        GraphQLResponses.Enqueue('StagedUpload');

        // [THEN] A bulk operation fails silently
        LibraryAssert.IsFalse(BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::AddProduct, tb.ToText(), RequestData), 'Bulk operation should be sent.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkOperationHttpHandler')]
    procedure TestBulkOperationRevertFailed()
    var
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
    begin
        // [SCENARIO] A bulk operation completes but some operations failed and they are reverted

        // [GIVEN] A bulk operation record and four variants
        Initialize();
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
        BulkOperationUrl := 'https://storage.googleapis.com/shopify-bulk-result/' + Any.AlphabeticText(20);
        BulkOperation := CreateBulkOperation(BulkOperationId1, BulkOperationType::UpdateProductPrice, Shop.Code, BulkOperationUrl, GenerateRequestData(VariantIds, 100, 150, 50));

        // [WHEN] Bulk operation is completed
        BulkOperationIdCurrent := BulkOperationId1;
        VariantId1 := VariantIds.Get(1);
        VariantId2 := VariantIds.Get(4);
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
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
    begin
        // [SCENARIO] A bulk operation fails and all operations are reverted

        // [GIVEN] A bulk operation record and two variants
        Initialize();
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
        BulkOperationUrl := 'https://storage.googleapis.com/shopify-bulk-result/' + Any.AlphabeticText(20);
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
    [HandlerFunctions('BulkOperationHttpHandler')]
    procedure TestBulkOperationRevertFailedWithLegacyRequestDataMissingUnitCost()
    var
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
    begin
        // [SCENARIO] A bulk operation persisted before the unitCost key was added still
        // completes its revert without throwing, leaving Unit Cost untouched.
        // Regression for bug 637250.

        // [GIVEN] A bulk operation whose request data was written by the pre-unitCost code
        // (i.e. the JSON objects only contain id/price/compareAtPrice/updatedAt) and four variants
        Initialize();
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
        BulkOperationUrl := 'https://storage.googleapis.com/shopify-bulk-result/' + Any.AlphabeticText(20);
        BulkOperation := CreateBulkOperation(BulkOperationId1, BulkOperationType::UpdateProductPrice, Shop.Code, BulkOperationUrl, GenerateLegacyRequestDataWithoutUnitCost(VariantIds, 100, 150));

        // [WHEN] Bulk operation is completed
        BulkOperationIdCurrent := BulkOperationId1;
        VariantId1 := VariantIds.Get(1);
        VariantId2 := VariantIds.Get(4);
        BulkOperation.Status := BulkOperation.Status::Completed;
        BulkOperation.Modify(true);

        // [THEN] The bulk operation is processed without throwing on the missing unitCost key,
        // failed variants have their Price/Compare at Price reverted, and Unit Cost is left
        // untouched on every variant (since the legacy blob doesn't know the pre-update value).
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.IsTrue(BulkOperation.Processed, 'Bulk operation should be processed.');
        ShopifyVariant.Get(VariantIds.Get(1));
        LibraryAssert.AreEqual(200, ShopifyVariant.Price, 'Variant price should not be reverted.');
        LibraryAssert.AreEqual(250, ShopifyVariant."Compare at Price", 'Variant compare at price should not be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should be left untouched when legacy blob lacks unitCost.');
        ShopifyVariant.Get(VariantIds.Get(2));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should be left untouched when legacy blob lacks unitCost.');
        ShopifyVariant.Get(VariantIds.Get(3));
        LibraryAssert.AreEqual(100, ShopifyVariant.Price, 'Variant price should be reverted.');
        LibraryAssert.AreEqual(150, ShopifyVariant."Compare at Price", 'Variant compare at price should be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should be left untouched when legacy blob lacks unitCost.');
        ShopifyVariant.Get(VariantIds.Get(4));
        LibraryAssert.AreEqual(200, ShopifyVariant.Price, 'Variant price should not be reverted.');
        LibraryAssert.AreEqual(250, ShopifyVariant."Compare at Price", 'Variant compare at price should not be reverted.');
        LibraryAssert.AreEqual(75, ShopifyVariant."Unit Cost", 'Variant unit cost should be left untouched when legacy blob lacks unitCost.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkOperationHttpHandler')]
    procedure TestBulkOperationRevertFailedLogsSkippedRecords()
    var
        ShopifyVariant: Record "Shpfy Variant";
        BulkOperation: Record "Shpfy Bulk Operation";
        SkippedRecord: Record "Shpfy Skipped Record";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        ProductId: BigInteger;
        VariantId: BigInteger;
        VariantIds: List of [BigInteger];
        Index: Integer;
        RevertedWithUserErrorLbl: Label 'The product price update was reverted because Shopify returned an error: Product variant does not exist', Locked = true;
        RevertedWithTopErrorLbl: Label 'The product price update was reverted because Shopify returned an error: This product is currently being modified. Please try again later.', Locked = true;
    begin
        // [SCENARIO] Bug 641615: when a bulk price sync reverts a variant because Shopify returned an
        // error, a Shopify Skipped Record is created with the error details and the linked BC record so
        // the user sees which item failed and why.

        // [GIVEN] Four Shopify variants (1 and 4 succeed, 2 and 3 fail). The failed variants are linked
        // to BC records: variant 2 to an Item, variant 3 to an Item Variant.
        Initialize();
        ClearSetup();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        for Index := 1 to 4 do begin
            ProductId := Any.IntegerInRange(100000, 555555);
            VariantId := Any.IntegerInRange(100000, 555555);
            VariantIds.Add(VariantId);
            ShopifyVariant.Init();
            ShopifyVariant."Product Id" := ProductId;
            ShopifyVariant.Id := VariantId;
            ShopifyVariant.Price := 200;
            ShopifyVariant."Compare at Price" := 250;
            ShopifyVariant."Unit Cost" := 75;
            case Index of
                2:
                    ShopifyVariant."Item SystemId" := Item.SystemId;
                3:
                    begin
                        ShopifyVariant."Item SystemId" := Item.SystemId;
                        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
                    end;
            end;
            ShopifyVariant.Insert();
        end;
        BulkOperationUrl := 'https://storage.googleapis.com/shopify-bulk-result/' + Any.AlphabeticText(20);
        BulkOperation := CreateBulkOperation(BulkOperationId1, BulkOperationType::UpdateProductPrice, Shop.Code, BulkOperationUrl, GenerateRequestData(VariantIds, 100, 150, 50));

        // [WHEN] Bulk operation is completed
        BulkOperationIdCurrent := BulkOperationId1;
        VariantId1 := VariantIds.Get(1);
        VariantId2 := VariantIds.Get(4);
        BulkOperation.Status := BulkOperation.Status::Completed;
        BulkOperation.Modify(true);

        // [THEN] A skipped record is logged for the item-linked failed variant, pointing at the BC Item
        SkippedRecord.SetRange("Shopify Id", VariantIds.Get(2));
        LibraryAssert.IsTrue(SkippedRecord.FindFirst(), 'Skipped record should be created for the first failed variant.');
        LibraryAssert.AreEqual(RevertedWithUserErrorLbl, SkippedRecord."Skipped Reason", 'Skipped reason should contain the Shopify user error.');
        LibraryAssert.AreEqual(Database::Item, SkippedRecord."Table ID", 'Skipped record should reference the BC Item table.');
        LibraryAssert.AreEqual(Format(Item.RecordId()), Format(SkippedRecord."Record ID"), 'Skipped record should reference the BC Item record.');

        // [THEN] A skipped record is logged for the variant-linked failed variant, pointing at the BC Item Variant
        SkippedRecord.SetRange("Shopify Id", VariantIds.Get(3));
        LibraryAssert.IsTrue(SkippedRecord.FindFirst(), 'Skipped record should be created for the second failed variant.');
        LibraryAssert.AreEqual(RevertedWithTopErrorLbl, SkippedRecord."Skipped Reason", 'Skipped reason should contain the Shopify top-level error.');
        LibraryAssert.AreEqual(Database::"Item Variant", SkippedRecord."Table ID", 'Skipped record should reference the BC Item Variant table.');
        LibraryAssert.AreEqual(Format(ItemVariant.RecordId()), Format(SkippedRecord."Record ID"), 'Skipped record should reference the BC Item Variant record.');

        // [THEN] No skipped record is logged for the variants that succeeded
        SkippedRecord.SetRange("Shopify Id", VariantIds.Get(1));
        LibraryAssert.IsTrue(SkippedRecord.IsEmpty(), 'No skipped record should be created for a variant that succeeded.');
        SkippedRecord.SetRange("Shopify Id", VariantIds.Get(4));
        LibraryAssert.IsTrue(SkippedRecord.IsEmpty(), 'No skipped record should be created for a variant that succeeded.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler,BulkOperationHttpHandler')]
    procedure TestSendBulkOperationStoresSentJsonl()
    var
        LoggingShop: Record "Shpfy Shop";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
        StoredJsonl: Text;
    begin
        // [SCENARIO] Bug 641615: when the shop's Logging Mode is All, the JSONL input sent to
        // Shopify is stored on the bulk operation record so it can be downloaded for troubleshooting.
        Initialize();
        ClearSetup();

        // [GIVEN] A shop with Logging Mode = All and a bulk operation input
        LoggingShop := Shop;
        LoggingShop."Logging Mode" := Enum::"Shpfy Logging Mode"::All;
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 2', 'Snowboard', 'JadedPixel'));

        // [WHEN] The bulk operation is sent
        EnqueueGraphQLResponsesForSendBulkMutation();
        BulkOperationMgt.SendBulkMutation(LoggingShop, BulkOperationType::AddProduct, tb.ToText(), RequestData);

        // [THEN] The sent JSONL is stored on the bulk operation record
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        StoredJsonl := BulkOperation.GetSentJsonl();
        LibraryAssert.IsTrue(StoredJsonl.Contains('Sweet new snowboard 1'), 'Stored JSONL should contain the first sent line.');
        LibraryAssert.IsTrue(StoredJsonl.Contains('Sweet new snowboard 2'), 'Stored JSONL should contain the second sent line.');
        ClearSetup();
    end;

    [Test]
    [HandlerFunctions('BulkMessageHandler,BulkOperationHttpHandler')]
    procedure TestSendBulkOperationDoesNotStoreSentJsonlWhenNotLoggingAll()
    var
        LoggingShop: Record "Shpfy Shop";
        BulkOperation: Record "Shpfy Bulk Operation";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        tb: TextBuilder;
        RequestData: JsonArray;
    begin
        // [SCENARIO] Bug 641615: the sent JSONL is only stored when Logging Mode is All, so the
        // bulk operation table does not grow with a payload blob on every price sync.
        Initialize();
        ClearSetup();

        // [GIVEN] A shop with Logging Mode = Error Only and a bulk operation input
        LoggingShop := Shop;
        LoggingShop."Logging Mode" := Enum::"Shpfy Logging Mode"::"Error Only";
        BulkOperationIdCurrent := BulkOperationId1;
        IBulkOperation := BulkOperationType::AddProduct;
        tb.AppendLine(StrSubstNo(IBulkOperation.GetInput(), 'Sweet new snowboard 1', 'Snowboard', 'JadedPixel'));

        // [WHEN] The bulk operation is sent
        EnqueueGraphQLResponsesForSendBulkMutation();
        BulkOperationMgt.SendBulkMutation(LoggingShop, BulkOperationType::AddProduct, tb.ToText(), RequestData);

        // [THEN] The sent JSONL is not stored on the bulk operation record
        BulkOperation.Get(BulkOperationId1, Shop.Code, BulkOperation.Type::mutation);
        LibraryAssert.AreEqual('', BulkOperation.GetSentJsonl(), 'Sent JSONL should not be stored when Logging Mode is not All.');
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

    local procedure CreateBulkOperation(BulkOperationId: BigInteger; BulkOperationType: Enum "Shpfy Bulk Operation Type"; ShopCode: Code[20]; BulkOpUrl: Text; RequestData: JsonArray): Record "Shpfy Bulk Operation"
    var
        BulkOperation: Record "Shpfy Bulk Operation";
    begin
        BulkOperation."Bulk Operation Id" := BulkOperationId;
        BulkOperation.Type := BulkOperation.Type::mutation;
        BulkOperation."Shop Code" := ShopCode;
        BulkOperation."Bulk Operation Type" := BulkOperationType;
        BulkOperation.Processed := false;
        BulkOperation.Url := CopyStr(BulkOpUrl, 1, MaxStrLen(BulkOperation.Url));
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

    local procedure GenerateLegacyRequestDataWithoutUnitCost(VariantIds: List of [BigInteger]; Price: Decimal; CompareAtPrice: Decimal): JsonArray
    var
        RequestData: JsonArray;
        VariantId: BigInteger;
        Data: JsonObject;
    begin
        // Simulates the request-data layout written by the connector before the unitCost key
        // was added to the bulk-operation rollback bookkeeping. Used to test that the revert
        // tolerates legacy blobs persisted before the upgrade.
        foreach VariantId in VariantIds do begin
            Clear(Data);
            Data.Add('id', VariantId);
            Data.Add('price', Price);
            Data.Add('compareAtPrice', CompareAtPrice);
            Data.Add('updatedAt', '2025-02-25T13:40:15.6530000Z');
            RequestData.Add(Data);
        end;
        exit(RequestData);
    end;

    local procedure EnqueueGraphQLResponsesForSendBulkMutation()
    begin
        GraphQLResponses.Enqueue('StagedUpload');
        GraphQLResponses.Enqueue('BulkMutation');
    end;

    [HttpClientHandler]
    internal procedure BulkOperationHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Body: Text;
        BodyBuilder: TextBuilder;
        BodyLine: Text;
        ResInStream: InStream;
        ResponseType: Text;
    begin
        // Handle POST to staged upload URL (file upload)
        if Request.Path.Contains(UploadUrlLbl) then
            exit(false);

        // Handle GET for bulk operation result download
        if (BulkOperationUrl <> '') and (Request.Path = BulkOperationUrl) then begin
            NavApp.GetResource('Bulk Operations/BulkOperationResult.txt', ResInStream, TextEncoding::UTF8);
            while not ResInStream.EOS do begin
                ResInStream.ReadText(BodyLine);
                BodyBuilder.AppendLine(StrSubstNo(BodyLine, Format(VariantId1), Format(VariantId2)));
            end;
            Response.Content.WriteFrom(BodyBuilder.ToText());
            exit(false);
        end;

        // Handle GraphQL POST requests to the Shopify API
        if InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then begin
            ResponseType := GraphQLResponses.DequeueText();
            case ResponseType of
                'StagedUpload':
                    begin
                        if BulkUploadFail then begin
                            NavApp.GetResource('Bulk Operations/StagedUploadFailedResult.txt', ResInStream, TextEncoding::UTF8);
                            ResInStream.ReadText(Body);
                        end else begin
                            NavApp.GetResource('Bulk Operations/StagedUploadResult.txt', ResInStream, TextEncoding::UTF8);
                            ResInStream.ReadText(Body);
                            Body := StrSubstNo(Body, UploadUrlLbl);
                        end;
                        Response.Content.WriteFrom(Body);
                    end;
                'BulkMutation':
                    begin
                        NavApp.GetResource('Bulk Operations/BulkMutationResponse.txt', ResInStream, TextEncoding::UTF8);
                        ResInStream.ReadText(Body);
                        Response.Content.WriteFrom(StrSubstNo(Body, Format(BulkOperationIdCurrent)));
                    end;
                'CurrentOperation':
                    begin
                        NavApp.GetResource('Bulk Operations/BulkOperationCompletedResult.txt', ResInStream, TextEncoding::UTF8);
                        ResInStream.ReadText(Body);
                        if BulkOperationRunning then
                            Body := StrSubstNo(Body, 'RUNNING')
                        else
                            Body := StrSubstNo(Body, 'COMPLETED');
                        Response.Content.WriteFrom(Body);
                    end;
            end;
            exit(false);
        end;

        exit(true);
    end;

    [MessageHandler]
    procedure BulkMessageHandler(Message: Text[1024])
    var
        BulkOperationMsg: Label 'A bulk request was sent to Shopify. You can check the status of the synchronization in the Shopify Bulk Operations page.', Locked = true;
    begin
        LibraryAssert.ExpectedMessage(BulkOperationMsg, Message);
    end;
}
