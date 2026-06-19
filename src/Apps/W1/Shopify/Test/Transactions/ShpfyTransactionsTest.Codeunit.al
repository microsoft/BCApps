// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139700 "Shpfy Transactions Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        ShpfyInitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        if IsInitialized then
            exit;

        Shop := ShpfyInitializeTest.CreateShop();
        IsInitialized := true;
    end;

    [Test]
    procedure ImportTransactionSetsShopCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Currency: Record Currency;
        Transactions: Codeunit "Shpfy Transactions";
        LibraryERM: Codeunit "Library - ERM";
        JTransaction: JsonObject;
        TransactionId: BigInteger;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, the Currency field is populated from shopMoney.currencyCode
        Initialize();

        // [GIVEN] A foreign currency with ISO Code
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := CopyStr(CurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] An order header
        TransactionId := Any.IntegerInRange(100000, 999999);
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(100000, 999999);
        OrderHeader."Shop Code" := Shop.Code;
        if not OrderHeader.Insert() then
            OrderHeader.Modify();

        // [GIVEN] A transaction JSON with shopMoney.currencyCode set to the foreign currency
        JTransaction := CreateTransactionJson(TransactionId, 100.00, CurrencyCode, 120.00, 'AUD');

        // [WHEN] The transaction is extracted
        Transactions.ExtractShopifyOrderTransactionFromMock(JTransaction.AsToken(), OrderHeader);

        // [THEN] OrderTransaction.Currency is set to the translated currency code
        OrderTransaction.Get(TransactionId);
        LibraryAssert.AreEqual(CurrencyCode, OrderTransaction.Currency, 'Currency should be set from shopMoney.currencyCode');
    end;

    [Test]
    procedure ImportTransactionWithLCYCurrencyReturnsEmpty()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Transactions: Codeunit "Shpfy Transactions";
        JTransaction: JsonObject;
        TransactionId: BigInteger;
        LCYCode: Code[10];
    begin
        // [SCENARIO] When the shop currency matches LCY, the Currency field should be empty
        Initialize();

        // [GIVEN] The LCY code
        GeneralLedgerSetup.Get();
        LCYCode := GeneralLedgerSetup."LCY Code";

        // [GIVEN] An order header
        TransactionId := Any.IntegerInRange(100000, 999999);
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(100000, 999999);
        OrderHeader."Shop Code" := Shop.Code;
        if not OrderHeader.Insert() then
            OrderHeader.Modify();

        // [GIVEN] A transaction JSON with shopMoney.currencyCode = LCY
        JTransaction := CreateTransactionJson(TransactionId, 100.00, LCYCode, 100.00, LCYCode);

        // [WHEN] The transaction is extracted
        Transactions.ExtractShopifyOrderTransactionFromMock(JTransaction.AsToken(), OrderHeader);

        // [THEN] OrderTransaction.Currency is empty (LCY is represented as blank in BC)
        OrderTransaction.Get(TransactionId);
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY');
    end;

    [Test]
    procedure ImportTransactionSetsPresentmentCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Transactions: Codeunit "Shpfy Transactions";
        LibraryERM: Codeunit "Library - ERM";
        JTransaction: JsonObject;
        TransactionId: BigInteger;
        ShopCurrencyCode: Code[10];
        PresentmentCurrencyCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, Presentment Currency is populated from presentmentMoney.currencyCode
        Initialize();

        // [GIVEN] A shop currency (LCY)
        GeneralLedgerSetup.Get();
        ShopCurrencyCode := GeneralLedgerSetup."LCY Code";

        // [GIVEN] A foreign presentment currency
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(PresentmentCurrencyCode);
        Currency."ISO Code" := CopyStr(PresentmentCurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] An order header
        TransactionId := Any.IntegerInRange(100000, 999999);
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(100000, 999999);
        OrderHeader."Shop Code" := Shop.Code;
        if not OrderHeader.Insert() then
            OrderHeader.Modify();

        // [GIVEN] A transaction JSON with different shop and presentment currencies
        JTransaction := CreateTransactionJson(TransactionId, 100.00, ShopCurrencyCode, 150.00, PresentmentCurrencyCode);

        // [WHEN] The transaction is extracted
        Transactions.ExtractShopifyOrderTransactionFromMock(JTransaction.AsToken(), OrderHeader);

        // [THEN] Presentment Currency is set correctly
        OrderTransaction.Get(TransactionId);
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY shop currency');
        LibraryAssert.AreEqual(PresentmentCurrencyCode, OrderTransaction."Presentment Currency", 'Presentment Currency should be set from presentmentMoney.currencyCode');
    end;

    [Test]
    procedure ImportTransactionAmountMatchesShopMoney()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Transactions: Codeunit "Shpfy Transactions";
        LibraryERM: Codeunit "Library - ERM";
        JTransaction: JsonObject;
        TransactionId: BigInteger;
        ShopAmount: Decimal;
        PresentmentAmount: Decimal;
        PresentmentCurrencyCode: Code[10];
    begin
        // [SCENARIO] Amount field contains shopMoney.amount and Presentment Amount contains presentmentMoney.amount
        Initialize();

        // [GIVEN] A foreign presentment currency
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(PresentmentCurrencyCode);
        Currency."ISO Code" := CopyStr(PresentmentCurrencyCode, 1, MaxStrLen(Currency."ISO Code"));
        Currency.Modify();

        // [GIVEN] An order header
        GeneralLedgerSetup.Get();
        TransactionId := Any.IntegerInRange(100000, 999999);
        ShopAmount := 85.50;
        PresentmentAmount := 120.75;
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(100000, 999999);
        OrderHeader."Shop Code" := Shop.Code;
        if not OrderHeader.Insert() then
            OrderHeader.Modify();

        // [GIVEN] A transaction JSON with specific amounts
        JTransaction := CreateTransactionJson(TransactionId, ShopAmount, GeneralLedgerSetup."LCY Code", PresentmentAmount, PresentmentCurrencyCode);

        // [WHEN] The transaction is extracted
        Transactions.ExtractShopifyOrderTransactionFromMock(JTransaction.AsToken(), OrderHeader);

        // [THEN] Amounts are correctly mapped
        OrderTransaction.Get(TransactionId);
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

    local procedure CreateTransactionJson(TransactionId: BigInteger; ShopAmount: Decimal; ShopCurrencyCode: Code[10]; PresentmentAmount: Decimal; PresentmentCurrencyCode: Code[10]) JTransaction: JsonObject
    var
        JAmountSet: JsonObject;
        JShopMoney: JsonObject;
        JPresentmentMoney: JsonObject;
        JAmountRoundingSet: JsonObject;
        JRoundingShopMoney: JsonObject;
        JRoundingPresentmentMoney: JsonObject;
        TransactionGidLbl: Label 'gid://shopify/OrderTransaction/%1', Comment = '%1 = id', Locked = true;
    begin
        JTransaction.Add('id', StrSubstNo(TransactionGidLbl, TransactionId));
        JTransaction.Add('gateway', 'shopify_payments');
        JTransaction.Add('formattedGateway', 'Shopify Payments');
        JTransaction.Add('manualPaymentGateway', '');
        JTransaction.Add('createdAt', Format(CurrentDateTime(), 0, 9));
        JTransaction.Add('test', false);
        JTransaction.Add('authorizationCode', '');
        JTransaction.Add('errorCode', '');
        JTransaction.Add('paymentId', StrSubstNo(TransactionGidLbl, Any.IntegerInRange(100000, 999999)));
        JTransaction.Add('status', 'SUCCESS');
        JTransaction.Add('kind', 'SALE');

        JShopMoney.Add('amount', ShopAmount);
        JShopMoney.Add('currencyCode', ShopCurrencyCode);
        JPresentmentMoney.Add('amount', PresentmentAmount);
        JPresentmentMoney.Add('currencyCode', PresentmentCurrencyCode);
        JAmountSet.Add('shopMoney', JShopMoney);
        JAmountSet.Add('presentmentMoney', JPresentmentMoney);
        JTransaction.Add('amountSet', JAmountSet);

        JRoundingShopMoney.Add('amount', 0);
        JRoundingShopMoney.Add('currencyCode', ShopCurrencyCode);
        JRoundingPresentmentMoney.Add('amount', 0);
        JRoundingPresentmentMoney.Add('currencyCode', PresentmentCurrencyCode);
        JAmountRoundingSet.Add('shopMoney', JRoundingShopMoney);
        JAmountRoundingSet.Add('presentmentMoney', JRoundingPresentmentMoney);
        JTransaction.Add('amountRoundingSet', JAmountRoundingSet);

        JTransaction.Add('receiptJson', '{}');
    end;
}
