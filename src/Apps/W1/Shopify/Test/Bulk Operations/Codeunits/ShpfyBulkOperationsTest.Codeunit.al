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
    begin
        BulkOperation.DeleteAll();
        BulkOperationRunning := false;
        BulkUploadFail := false;
        ShopifyVariant.DeleteAll();
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
