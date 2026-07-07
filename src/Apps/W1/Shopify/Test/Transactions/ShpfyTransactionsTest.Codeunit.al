// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139697 "Shpfy Transactions Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        TransactionData: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        Commit();
        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionSetsShopCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Currency: Record Currency;
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        LibraryERM: Codeunit "Library - ERM";
        OrdersToImport: Record "Shpfy Orders to Import";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, the Currency field is populated from shopMoney.currencyCode
        Initialize();

        // [GIVEN] A foreign currency with ISO Code
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := CopyStr(CurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] Set up mock transaction response with foreign shop currency
        TransactionData.Clear();
        TransactionData.Enqueue(CurrencyCode); // shopMoney.currencyCode
        TransactionData.Enqueue(100.00); // shopMoney.amount
        TransactionData.Enqueue('AUD'); // presentmentMoney.currencyCode
        TransactionData.Enqueue(120.00); // presentmentMoney.amount

        // [GIVEN] A Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        ImportOrder.ImportCreateAndUpdateOrderHeaderFromMock(Shop.Code, OrdersToImport.Id, JShopifyOrder);
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrdersToImport.Id, JShopifyLineItems);
        Commit();
        OrderHeader.Get(OrdersToImport.Id);

        // [THEN] OrderTransaction.Currency is set to the translated currency code
        OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
        LibraryAssert.IsTrue(OrderTransaction.FindFirst(), 'Transaction should be created');
        LibraryAssert.AreEqual(CurrencyCode, OrderTransaction.Currency, 'Currency should be set from shopMoney.currencyCode');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionWithLCYCurrencyReturnsEmpty()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersToImport: Record "Shpfy Orders to Import";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        LCYCode: Code[10];
    begin
        // [SCENARIO] When the shop currency matches LCY, the Currency field should be empty
        Initialize();

        // [GIVEN] The LCY code
        GeneralLedgerSetup.Get();
        LCYCode := GeneralLedgerSetup."LCY Code";

        // [GIVEN] Set up mock transaction response with LCY as shop currency
        TransactionData.Clear();
        TransactionData.Enqueue(LCYCode);
        TransactionData.Enqueue(100.00);
        TransactionData.Enqueue(LCYCode);
        TransactionData.Enqueue(100.00);

        // [GIVEN] A Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        ImportOrder.ImportCreateAndUpdateOrderHeaderFromMock(Shop.Code, OrdersToImport.Id, JShopifyOrder);
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrdersToImport.Id, JShopifyLineItems);
        Commit();
        OrderHeader.Get(OrdersToImport.Id);

        // [THEN] OrderTransaction.Currency is empty (LCY is represented as blank in BC)
        OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
        LibraryAssert.IsTrue(OrderTransaction.FindFirst(), 'Transaction should be created');
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionSetsPresentmentCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        LibraryERM: Codeunit "Library - ERM";
        OrdersToImport: Record "Shpfy Orders to Import";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        PresentmentCurrencyCode: Code[10];
        LCYCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, Presentment Currency is populated from presentmentMoney.currencyCode
        Initialize();

        // [GIVEN] LCY code and a foreign presentment currency
        GeneralLedgerSetup.Get();
        LCYCode := GeneralLedgerSetup."LCY Code";
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(PresentmentCurrencyCode);
        Currency."ISO Code" := CopyStr(PresentmentCurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] Set up mock transaction response with LCY shop currency and foreign presentment
        TransactionData.Clear();
        TransactionData.Enqueue(LCYCode);
        TransactionData.Enqueue(100.00);
        TransactionData.Enqueue(PresentmentCurrencyCode);
        TransactionData.Enqueue(150.00);

        // [GIVEN] A Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        ImportOrder.ImportCreateAndUpdateOrderHeaderFromMock(Shop.Code, OrdersToImport.Id, JShopifyOrder);
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrdersToImport.Id, JShopifyLineItems);
        Commit();
        OrderHeader.Get(OrdersToImport.Id);

        // [THEN] Presentment Currency is set correctly
        OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
        LibraryAssert.IsTrue(OrderTransaction.FindFirst(), 'Transaction should be created');
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY shop currency');
        LibraryAssert.AreEqual(PresentmentCurrencyCode, OrderTransaction."Presentment Currency", 'Presentment Currency should be set from presentmentMoney.currencyCode');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionAmountMatchesShopMoney()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        LibraryERM: Codeunit "Library - ERM";
        OrdersToImport: Record "Shpfy Orders to Import";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        PresentmentCurrencyCode: Code[10];
        ShopAmount: Decimal;
        PresentmentAmount: Decimal;
    begin
        // [SCENARIO] Amount field contains shopMoney.amount and Presentment Amount contains presentmentMoney.amount
        Initialize();

        // [GIVEN] A foreign presentment currency
        GeneralLedgerSetup.Get();
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(PresentmentCurrencyCode);
        Currency."ISO Code" := CopyStr(PresentmentCurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] Set up mock transaction response with specific amounts
        ShopAmount := 85.50;
        PresentmentAmount := 120.75;
        TransactionData.Clear();
        TransactionData.Enqueue(GeneralLedgerSetup."LCY Code");
        TransactionData.Enqueue(ShopAmount);
        TransactionData.Enqueue(PresentmentCurrencyCode);
        TransactionData.Enqueue(PresentmentAmount);

        // [GIVEN] A Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        ImportOrder.ImportCreateAndUpdateOrderHeaderFromMock(Shop.Code, OrdersToImport.Id, JShopifyOrder);
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrdersToImport.Id, JShopifyLineItems);
        Commit();
        OrderHeader.Get(OrdersToImport.Id);

        // [THEN] Amounts are correctly mapped
        OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
        LibraryAssert.IsTrue(OrderTransaction.FindFirst(), 'Transaction should be created');
        LibraryAssert.AreEqual(ShopAmount, OrderTransaction.Amount, 'Amount should match shopMoney.amount');
        LibraryAssert.AreEqual(PresentmentAmount, OrderTransaction."Presentment Amount", 'Presentment Amount should match presentmentMoney.amount');
    end;

    [Test]
    procedure TranslateCurrencyCodeWithISOCodeMatch()
    var
        Currency: Record Currency;
        ImportOrder: Codeunit "Shpfy Import Order";
        LibraryERM: Codeunit "Library - ERM";
        CurrencyCode: Code[10];
        Result: Code[10];
    begin
        // [SCENARIO] TranslateCurrencyCode finds currency by ISO Code when exactly one match exists
        Initialize();

        // [GIVEN] A currency with ISO Code set
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := 'ZZZ';
        Currency.Modify();

        // [WHEN] TranslateCurrencyCode is called with the ISO Code
        ImportOrder.SetShop(Shop.Code);
        Result := ImportOrder.TranslateCurrencyCode('ZZZ');

        // [THEN] The currency code is returned
        LibraryAssert.AreEqual(CurrencyCode, Result, 'Should return currency code matching ISO Code');
    end;

    [Test]
    procedure TranslateCurrencyCodeWithEmptyInput()
    var
        ImportOrder: Codeunit "Shpfy Import Order";
        Result: Code[10];
    begin
        // [SCENARIO] TranslateCurrencyCode returns empty for empty input
        Initialize();

        // [WHEN] TranslateCurrencyCode is called with empty string
        ImportOrder.SetShop(Shop.Code);
        Result := ImportOrder.TranslateCurrencyCode('');

        // [THEN] Returns empty
        LibraryAssert.AreEqual('', Result, 'Should return empty for empty input');
    end;

    [Test]
    procedure TranslateCurrencyCodeFallsBackToCodeMatch()
    var
        Currency: Record Currency;
        ImportOrder: Codeunit "Shpfy Import Order";
        LibraryERM: Codeunit "Library - ERM";
        CurrencyCode: Code[10];
        Result: Code[10];
    begin
        // [SCENARIO] When no currency matches by ISO Code, TranslateCurrencyCode falls back to Currency.Get(code)
        Initialize();

        // [GIVEN] A currency whose Code matches the input but ISO Code does not
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := 'XXX';
        Currency.Modify();

        // [WHEN] TranslateCurrencyCode is called with the currency code (not matching any ISO Code)
        ImportOrder.SetShop(Shop.Code);
        Result := ImportOrder.TranslateCurrencyCode(CurrencyCode);

        // [THEN] The currency code is returned via Get fallback
        LibraryAssert.AreEqual(CurrencyCode, Result, 'Should find currency by Code when ISO Code does not match');
    end;

    [Test]
    procedure TranslateCurrencyCodeReturnsEmptyWhenNotFound()
    var
        ImportOrder: Codeunit "Shpfy Import Order";
        Result: Code[10];
    begin
        // [SCENARIO] TranslateCurrencyCode returns empty when currency is not found by ISO Code or Code
        Initialize();

        // [WHEN] TranslateCurrencyCode is called with a non-existent currency code
        ImportOrder.SetShop(Shop.Code);
        Result := ImportOrder.TranslateCurrencyCode('QQQ');

        // [THEN] Returns empty
        LibraryAssert.AreEqual('', Result, 'Should return empty when currency not found');
    end;

    [Test]
    procedure TranslateCurrencyCodeReturnsEmptyWhenResolvedCodeIsLcy()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ImportOrder: Codeunit "Shpfy Import Order";
        LibraryERM: Codeunit "Library - ERM";
        CurrencyCode: Code[10];
        Result: Code[10];
    begin
        // [SCENARIO] When "LCY Code" is configured as a non-ISO currency code, a shop currency whose
        // ISO code resolves to that LCY currency must be treated as local currency and return blank.
        Initialize();

        // [GIVEN] A currency whose Code differs from its ISO Code, and "LCY Code" set to that Code
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := 'YYZ';
        Currency.Modify();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := CurrencyCode;
        GeneralLedgerSetup.Modify();

        // [WHEN] TranslateCurrencyCode is called with the ISO code (which differs from "LCY Code")
        ImportOrder.SetShop(Shop.Code);
        Result := ImportOrder.TranslateCurrencyCode('YYZ');

        // [THEN] Result is blank because the resolved BC currency code equals the LCY code
        LibraryAssert.AreEqual('', Result, 'Should return empty when the resolved currency code is the LCY code');
    end;

    [HttpClientHandler]
    internal procedure TransactionHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ShopCurrencyCode: Text;
        ShopAmount: Decimal;
        PresentmentCurrencyCode: Text;
        PresentmentAmount: Decimal;
        TransactionId: BigInteger;
        Body: Text;
        TransactionResponseLbl: Label '{"data":{"order":{"transactions":[{"authorizationCode":"","createdAt":"%1","errorCode":null,"formattedGateway":"Shopify Payments","gateway":"shopify_payments","id":"gid://shopify/OrderTransaction/%2","kind":"SALE","paymentId":"gid://shopify/Payment/%3","receiptJson":"{}","status":"SUCCESS","test":true,"amountSet":{"shopMoney":{"amount":"%4","currencyCode":"%5"},"presentmentMoney":{"amount":"%6","currencyCode":"%7"}},"amountRoundingSet":{"shopMoney":{"amount":"0","currencyCode":"%5"},"presentmentMoney":{"amount":"0","currencyCode":"%7"}},"paymentDetails":null}]}},"extensions":{"cost":{"requestedQueryCost":3,"actualQueryCost":3,"throttleStatus":{"maximumAvailable":2000.0,"currentlyAvailable":1997,"restoreRate":100.0}}}}', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        if TransactionData.Length() > 0 then begin
            ShopCurrencyCode := TransactionData.DequeueText();
            ShopAmount := TransactionData.DequeueDecimal();
            PresentmentCurrencyCode := TransactionData.DequeueText();
            PresentmentAmount := TransactionData.DequeueDecimal();
            TransactionId := Any.IntegerInRange(100000, 999999);
            Body := StrSubstNo(
                TransactionResponseLbl,
                Format(CurrentDateTime(), 0, 9),
                TransactionId,
                Any.IntegerInRange(100000, 999999),
                Format(ShopAmount, 0, 9),
                ShopCurrencyCode,
                Format(PresentmentAmount, 0, 9),
                PresentmentCurrencyCode
            );
            Response.Content.WriteFrom(Body);
        end else
            Response.Content.WriteFrom('{"data":{"order":{"transactions":[]}}}');
        exit(false);
    end;
}
