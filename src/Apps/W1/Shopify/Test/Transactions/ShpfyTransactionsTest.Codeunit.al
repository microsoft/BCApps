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
    EventSubscriberInstance = Manual;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        TransactionData: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        IsoCodeCounter: Integer;
        DiscoveryResponse: Text;
        FailOnPaymentMethodMappingInsert: Boolean;
        PaymentMethodMappingInsertFailureGateway: Code[30];

    #region Initialize
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
    #endregion

    #region Tests
    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionSetsShopCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        Transactions: Codeunit "Shpfy Transactions";
        IsoCode: Code[3];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, the Currency field is populated from shopMoney.currencyCode
        Initialize();

        // [GIVEN] A foreign shop currency with a distinct ISO Code
        IsoCode := GetUniqueIsoCode();
        CurrencyCode := CreateCurrencyWithIsoCode(IsoCode);

        // [GIVEN] A mock transaction response in that shop currency
        EnqueueTransaction(IsoCode, 100.00, IsoCode, 120.00);

        // [WHEN] Transactions are imported for an order
        CreateOrderHeader(OrderHeader);
        Transactions.UpdateTransactionInfos(OrderHeader);

        // [THEN] The transaction is created with the resolved BC currency code
        FindSuccessTransaction(OrderHeader, OrderTransaction);
        LibraryAssert.AreEqual(CurrencyCode, OrderTransaction.Currency, 'Currency should be set from shopMoney.currencyCode');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionWithLCYCurrencyReturnsEmpty()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Transactions: Codeunit "Shpfy Transactions";
        LCYCode: Code[10];
    begin
        // [SCENARIO] When the shop currency matches LCY, the Currency field should be empty
        Initialize();

        // [GIVEN] The LCY code
        GeneralLedgerSetup.Get();
        LCYCode := GeneralLedgerSetup."LCY Code";

        // [GIVEN] A mock transaction response with LCY as shop currency
        EnqueueTransaction(LCYCode, 100.00, LCYCode, 100.00);

        // [WHEN] Transactions are imported for an order
        CreateOrderHeader(OrderHeader);
        Transactions.UpdateTransactionInfos(OrderHeader);

        // [THEN] OrderTransaction.Currency is empty (LCY is represented as blank in BC)
        FindSuccessTransaction(OrderHeader, OrderTransaction);
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionSetsPresentmentCurrencyFromJson()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Transactions: Codeunit "Shpfy Transactions";
        PresentmentIsoCode: Code[3];
        PresentmentCurrencyCode: Code[10];
        LCYCode: Code[10];
    begin
        // [SCENARIO] When importing a transaction, Presentment Currency is populated from presentmentMoney.currencyCode
        Initialize();

        // [GIVEN] LCY shop currency and a foreign presentment currency
        GeneralLedgerSetup.Get();
        LCYCode := GeneralLedgerSetup."LCY Code";
        PresentmentIsoCode := GetUniqueIsoCode();
        PresentmentCurrencyCode := CreateCurrencyWithIsoCode(PresentmentIsoCode);

        // [GIVEN] A mock transaction response with LCY shop currency and foreign presentment
        EnqueueTransaction(LCYCode, 100.00, PresentmentIsoCode, 150.00);

        // [WHEN] Transactions are imported for an order
        CreateOrderHeader(OrderHeader);
        Transactions.UpdateTransactionInfos(OrderHeader);

        // [THEN] Presentment Currency is set correctly
        FindSuccessTransaction(OrderHeader, OrderTransaction);
        LibraryAssert.AreEqual('', OrderTransaction.Currency, 'Currency should be empty for LCY shop currency');
        LibraryAssert.AreEqual(PresentmentCurrencyCode, OrderTransaction."Presentment Currency", 'Presentment Currency should be set from presentmentMoney.currencyCode');
    end;

    [Test]
    [HandlerFunctions('TransactionHttpHandler')]
    procedure ImportTransactionAmountMatchesShopMoney()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTransaction: Record "Shpfy Order Transaction";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Transactions: Codeunit "Shpfy Transactions";
        PresentmentIsoCode: Code[3];
        ShopAmount: Decimal;
        PresentmentAmount: Decimal;
    begin
        // [SCENARIO] Amount field contains shopMoney.amount and Presentment Amount contains presentmentMoney.amount
        Initialize();

        // [GIVEN] LCY shop currency and a foreign presentment currency
        GeneralLedgerSetup.Get();
        PresentmentIsoCode := GetUniqueIsoCode();
        CreateCurrencyWithIsoCode(PresentmentIsoCode);

        // [GIVEN] A mock transaction response with specific amounts
        ShopAmount := 85.50;
        PresentmentAmount := 120.75;
        EnqueueTransaction(GeneralLedgerSetup."LCY Code", ShopAmount, PresentmentIsoCode, PresentmentAmount);

        // [WHEN] Transactions are imported for an order
        CreateOrderHeader(OrderHeader);
        Transactions.UpdateTransactionInfos(OrderHeader);

        // [THEN] Amounts are correctly mapped
        FindSuccessTransaction(OrderHeader, OrderTransaction);
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

    [Test]
    [HandlerFunctions('PaymentMethodDiscoveryHttpHandler')]
    procedure RepeatedDiscoveryDoesNotDuplicateNormalizedMappings()
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
        Gateway: Text[30];
        ExistingGateway: Text[30];
        FifthGateway: Text[30];
        IgnoredGateway: Text[30];
        SecondOrderGateway: Text[30];
        CardCompanyFirst: Text[50];
        CardCompanySecond: Text[50];
        ExistingCardCompany: Code[30];
        HasOrders: Boolean;
        CreatedMappingCount: Integer;
    begin
        //[SCENARIO] Repeated discovery does not duplicate normalized mapping combinations.

        //[GIVEN] The test infrastructure is initialized.
        //[GIVEN] The Shopify shop record is available.
        //[GIVEN] An access token is generated.
        //[GIVEN] The access token is registered for the shop.
        //[GIVEN] The test setup is committed.
        //[GIVEN] Shared initialization is marked complete.
        Initialize();

        //[GIVEN] A unique transaction gateway is prepared.
        Gateway := CopyStr('f11-' + Any.AlphanumericText(12), 1, MaxStrLen(Gateway));
        //[GIVEN] An existing gateway is prepared.
        ExistingGateway := CopyStr('existing-' + Any.AlphanumericText(8), 1, MaxStrLen(ExistingGateway));
        //[GIVEN] A fifth transaction gateway is prepared.
        FifthGateway := CopyStr('fifth-' + Any.AlphanumericText(8), 1, MaxStrLen(FifthGateway));
        //[GIVEN] A sixth transaction gateway is prepared.
        IgnoredGateway := CopyStr('sixth-' + Any.AlphanumericText(8), 1, MaxStrLen(IgnoredGateway));
        //[GIVEN] A gateway from a subsequent order is prepared.
        SecondOrderGateway := CopyStr('second-' + Any.AlphanumericText(8), 1, MaxStrLen(SecondOrderGateway));
        //[GIVEN] The first long card-company identity is prepared.
        CardCompanyFirst := 'F11-Credit-Card-Company-12345678901234567890-A';
        //[GIVEN] A distinct long card-company identity with the same normalized key is prepared.
        CardCompanySecond := 'F11-Credit-Card-Company-12345678901234567890-B';
        //[GIVEN] An existing card-company identity is prepared.
        ExistingCardCompany := 'Existing Card';
        //[GIVEN] The existing mapping retains its configured payment method.
        CreateExistingPaymentMethodMapping(ExistingGateway, ExistingCardCompany);
        //[GIVEN] Shopify returns transactions covering normalized identities, blank gateways, and order boundaries.
        DiscoveryResponse := CreateNormalizedMappingDiscoveryResponse(Gateway, CardCompanyFirst, CardCompanySecond, FifthGateway, IgnoredGateway, ExistingGateway, ExistingCardCompany, SecondOrderGateway);

        //[WHEN] Payment method discovery runs twice for the shop.
        DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);
        DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);

        //[THEN] Repeated discovery does not duplicate normalized mapping combinations.
        PaymentMethodMapping.SetRange("Shop Code", Shop.Code);
        PaymentMethodMapping.SetRange("Gateway", Gateway);
        LibraryAssert.AreEqual(2, PaymentMethodMapping.Count(), 'Repeat discovery should not duplicate normalized mapping combinations');
    end;

    [Test]
    [HandlerFunctions('PaymentMethodDiscoveryHttpHandler')]
    procedure DiscoverPaymentMethodsRollsBackWritesWhenMappingInsertFails()
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
        ShpfyTransactionsTest: Codeunit "Shpfy Transactions Test";
        FirstGateway: Code[30];
        FailingGateway: Code[30];
        HasOrders: Boolean;
        CreatedMappingCount: Integer;
        ErrorText: Text;
    begin
        //[SCENARIO] Discovery rolls back new mappings when a mapping insert fails.

        //[GIVEN] The test infrastructure is initialized.
        //[GIVEN] The Shopify shop record is available.
        //[GIVEN] An access token is generated.
        //[GIVEN] The access token is registered for the shop.
        //[GIVEN] The test setup is committed.
        //[GIVEN] Shared initialization is marked complete.
        Initialize();
        //[GIVEN] A gateway preceding the injected failure is prepared.
        FirstGateway := CopyStr('rollback-first-' + Any.AlphanumericText(8), 1, MaxStrLen(FirstGateway));
        //[GIVEN] A gateway that triggers the injected failure is prepared.
        FailingGateway := CopyStr('rollback-fail-' + Any.AlphanumericText(8), 1, MaxStrLen(FailingGateway));
        //[GIVEN] Shopify returns two transactions before the second mapping insert fails.
        DiscoveryResponse := CreateRollbackDiscoveryResponse(FirstGateway, FailingGateway);
        //[GIVEN] The manually bound subscriber is configured to fail on the selected gateway.
        ShpfyTransactionsTest.SetPaymentMethodMappingInsertFailure(FailingGateway);
        //[GIVEN] The failure subscriber is bound.
        BindSubscription(ShpfyTransactionsTest);
        //[GIVEN] The mapping query is restricted to the shop.
        PaymentMethodMapping.SetRange("Shop Code", Shop.Code);
        //[GIVEN] The mapping query includes both transaction gateways.
        PaymentMethodMapping.SetFilter(Gateway, '%1|%2', FirstGateway, FailingGateway);

        //[WHEN] Discovery encounters the injected mapping-insert failure.
        asserterror DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);
        ErrorText := GetLastErrorText();

        UnbindSubscription(ShpfyTransactionsTest);
        ShpfyTransactionsTest.ClearPaymentMethodMappingInsertFailure();

        //[THEN] Discovery reports the injected mapping-insert failure.
        LibraryAssert.IsTrue(StrPos(ErrorText, 'Injected payment-method mapping insert failure.') > 0, 'Discovery should fail on the selected mapping insert');

        //[THEN] Neither new mapping remains after the mapping-insert failure.
        LibraryAssert.IsTrue(PaymentMethodMapping.IsEmpty(), 'All new mappings should roll back after a mapping insert fails');
    end;

    [Test]
    procedure PaymentMethodMappingResolutionUsesExactNormalizedKeys()
    var
        Gateway: Text[30];
        LongCardCompany: Text[50];
        NormalizedCardCompany: Text[30];
        MappingsResolvedExactly: Boolean;
    begin
        //[SCENARIO] Payment method mapping resolution uses exact normalized keys and treats blank card companies literally.

        //[GIVEN] The test infrastructure is initialized.
        //[GIVEN] The Shopify shop record is available.
        //[GIVEN] An access token is generated.
        //[GIVEN] The access token is registered for the shop.
        //[GIVEN] The test setup is committed.
        //[GIVEN] Shared initialization is marked complete.
        Initialize();
        //[GIVEN] A transaction gateway is prepared.
        Gateway := CopyStr('resolve-' + Any.AlphanumericText(8), 1, MaxStrLen(Gateway));
        //[GIVEN] A card-company identity longer than the normalized key is prepared.
        LongCardCompany := 'A card company value longer than thirty characters';
        //[GIVEN] The card-company identity is normalized to the mapping key length.
        NormalizedCardCompany := CopyStr(LongCardCompany, 1, MaxStrLen(NormalizedCardCompany));
        //[GIVEN] A mapping exists for the normalized long card-company identity.
        CreatePaymentMethodMapping(Gateway, NormalizedCardCompany, 'LONG');
        //[GIVEN] A mapping exists for a blank card-company identity.
        CreatePaymentMethodMapping(Gateway, '', 'BLANK');

        //[WHEN] Long, blank, and unmatched card-company identities are resolved.
        MappingsResolvedExactly := ResolvePaymentMethodMappingKeys(Gateway, LongCardCompany);

        //[THEN] Resolution selects exact normalized mappings without treating a blank card company as a wildcard.
        LibraryAssert.IsTrue(MappingsResolvedExactly, 'Long and blank card-company identities must select their exact mappings, and an unmatched identity must not use the blank mapping');
    end;

    [Test]
    [HandlerFunctions('PaymentMethodDiscoveryHttpHandler')]
    procedure DiscoverPaymentMethodsDoesNotWriteAfterShopifyReadFailure()
    var
        TransactionGateway: Record "Shpfy Transaction Gateway";
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
        Gateway: Text[30];
        HasOrders: Boolean;
        CreatedMappingCount: Integer;
        ErrorText: Text;
    begin
        //[SCENARIO] Discovery does not write lookups or mappings after a Shopify read failure.

        //[GIVEN] The test infrastructure is initialized.
        //[GIVEN] The Shopify shop record is available.
        //[GIVEN] An access token is generated.
        //[GIVEN] The access token is registered for the shop.
        //[GIVEN] The test setup is committed.
        //[GIVEN] Shared initialization is marked complete.
        Initialize();
        //[GIVEN] A transaction gateway is prepared.
        Gateway := CopyStr('error-' + Any.AlphanumericText(8), 1, MaxStrLen(Gateway));
        //[GIVEN] Shopify returns a read error with the transaction response.
        DiscoveryResponse := CreateReadFailureDiscoveryResponse(Gateway);
        //[GIVEN] The gateway lookup query is restricted to the transaction gateway.
        TransactionGateway.SetRange(Name, Gateway);
        //[GIVEN] The mapping query is restricted to the shop.
        PaymentMethodMapping.SetRange("Shop Code", Shop.Code);
        //[GIVEN] The mapping query is restricted to the transaction gateway.
        PaymentMethodMapping.SetRange(Gateway, Gateway);

        //[WHEN] Discovery reads the failed Shopify response.
        asserterror DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);
        ErrorText := GetLastErrorText();

        //[THEN] Discovery surfaces the Shopify error message.
        LibraryAssert.IsTrue(StrPos(ErrorText, 'discovery read failed') > 0, 'Discovery should report the Shopify read failure');

        //[THEN] The failed Shopify read creates neither a gateway lookup nor a mapping.
        LibraryAssert.IsTrue(TransactionGateway.IsEmpty() and PaymentMethodMapping.IsEmpty(), 'A failed Shopify read must not create local gateway lookups or mappings');
    end;

    [Test]
    [HandlerFunctions('PaymentMethodDiscoveryHttpHandler')]
    procedure DiscoverPaymentMethodsReportsNoOrders()
    var
        DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
        HasOrders: Boolean;
        CreatedMappingCount: Integer;
    begin
        //[SCENARIO] Discovery distinguishes a shop with no orders from one whose orders add no mappings.

        //[GIVEN] The test infrastructure is initialized.
        Initialize();

        //[GIVEN] Shopify returns no orders.
        DiscoveryResponse := NavApp.GetResourceAsText('Transactions/NoOrdersDiscoveryResponse.txt', TextEncoding::UTF8);

        //[WHEN] Payment method discovery runs.
        DiscoverPaymentMethods.Discover(Shop.Code, HasOrders, CreatedMappingCount);

        //[THEN] Discovery reports no orders and creates no mappings.
        LibraryAssert.IsFalse(HasOrders, 'Discovery should report when Shopify returns no orders');
        LibraryAssert.AreEqual(0, CreatedMappingCount, 'No mappings should be created when Shopify returns no orders');
    end;
    #endregion

    #region Given
    local procedure CreateOrderHeader(var OrderHeader: Record "Shpfy Order Header")
    var
        ExistingOrderHeader: Record "Shpfy Order Header";
        NextOrderId: BigInteger;
    begin
        // Use an id above any existing order header so it can't collide with data committed by
        // other Shopify test codeunits sharing the same test database.
        if ExistingOrderHeader.FindLast() then
            NextOrderId := ExistingOrderHeader."Shopify Order Id" + 1
        else
            NextOrderId := 1;

        Clear(OrderHeader);
        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := NextOrderId;
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader.Insert();
    end;

    local procedure CreateCurrencyWithIsoCode(IsoCode: Code[3]): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Currency.Get(CurrencyCode);
        Currency."ISO Code" := IsoCode;
        Currency.Modify();
        exit(CurrencyCode);
    end;

    local procedure GetUniqueIsoCode(): Code[3]
    var
        Currency: Record Currency;
        Candidate: Code[3];
    begin
        // Pick a non-standard ISO code (Z01..Z99) that is not already used by any currency in the
        // shared test database, so the ISO-code lookup in TranslateCurrencyCode resolves to exactly one row.
        repeat
            IsoCodeCounter += 1;
            if IsoCodeCounter < 10 then
                Candidate := CopyStr('Z0' + Format(IsoCodeCounter), 1, 3)
            else
                Candidate := CopyStr('Z' + Format(IsoCodeCounter), 1, 3);
            Currency.SetRange("ISO Code", Candidate);
        until Currency.IsEmpty() or (IsoCodeCounter >= 99);
        exit(Candidate);
    end;

    local procedure EnqueueTransaction(ShopCurrencyCode: Text; ShopAmount: Decimal; PresentmentCurrencyCode: Text; PresentmentAmount: Decimal)
    begin
        TransactionData.Clear();
        TransactionData.Enqueue(ShopCurrencyCode);
        TransactionData.Enqueue(ShopAmount);
        TransactionData.Enqueue(PresentmentCurrencyCode);
        TransactionData.Enqueue(PresentmentAmount);
    end;

    local procedure CreateExistingPaymentMethodMapping(Gateway: Text[30]; CardCompany: Code[30])
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        PaymentMethodMapping.Init();
        PaymentMethodMapping."Shop Code" := Shop.Code;
        PaymentMethodMapping.Gateway := Gateway;
        PaymentMethodMapping."Credit Card Company" := CardCompany;
        PaymentMethodMapping."Payment Method Code" := 'KEEP';
        PaymentMethodMapping."Manual Payment Gateway" := false;
        PaymentMethodMapping.Insert();
    end;

    local procedure CreatePaymentMethodMapping(Gateway: Text[30]; CardCompany: Text[30]; PaymentMethodCode: Code[10])
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        PaymentMethodMapping.Init();
        PaymentMethodMapping."Shop Code" := Shop.Code;
        PaymentMethodMapping.Gateway := Gateway;
        PaymentMethodMapping."Credit Card Company" := CardCompany;
        PaymentMethodMapping."Payment Method Code" := PaymentMethodCode;
        PaymentMethodMapping.Insert();
    end;

    local procedure CreateNormalizedMappingDiscoveryResponse(Gateway: Text[30]; CardCompanyFirst: Text[50]; CardCompanySecond: Text[50]; FifthGateway: Text[30]; IgnoredGateway: Text[30]; ExistingGateway: Text[30]; ExistingCardCompany: Text[50]; SecondOrderGateway: Text[30]): Text
    begin
        exit(StrSubstNo(NavApp.GetResourceAsText('Transactions/NormalizedMappingDiscoveryResponse.txt', TextEncoding::UTF8), Gateway, CardCompanyFirst, CardCompanySecond, FifthGateway, IgnoredGateway, ExistingGateway, ExistingCardCompany, SecondOrderGateway));
    end;

    local procedure CreateRollbackDiscoveryResponse(FirstGateway: Text[30]; FailingGateway: Text[30]): Text
    begin
        exit(StrSubstNo(NavApp.GetResourceAsText('Transactions/RollbackDiscoveryResponse.txt', TextEncoding::UTF8), FirstGateway, FailingGateway));
    end;

    local procedure CreateReadFailureDiscoveryResponse(Gateway: Text[30]): Text
    begin
        exit(StrSubstNo(NavApp.GetResourceAsText('Transactions/ReadFailureDiscoveryResponse.txt', TextEncoding::UTF8), Gateway));
    end;

    local procedure GetNextTransactionId(): BigInteger
    var
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        // Use an id above any existing transaction so the mock response can't collide with data
        // committed by other Shopify test codeunits sharing the same test database.
        if OrderTransaction.FindLast() then
            exit(OrderTransaction."Shopify Transaction Id" + 1);
        exit(1);
    end;

    internal procedure SetPaymentMethodMappingInsertFailure(Gateway: Code[30])
    begin
        PaymentMethodMappingInsertFailureGateway := Gateway;
        FailOnPaymentMethodMappingInsert := true;
    end;

    internal procedure ClearPaymentMethodMappingInsertFailure()
    begin
        FailOnPaymentMethodMappingInsert := false;
        PaymentMethodMappingInsertFailureGateway := '';
    end;
    #endregion

    #region When
    local procedure ResolvePaymentMethodMappingKeys(Gateway: Text[30]; LongCardCompany: Text[50]): Boolean
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        PaymentMethodMappingMgt: Codeunit "Shpfy Pay. Method Mapp. Mgt.";
    begin
        if not PaymentMethodMappingMgt.FindMapping(Shop.Code, Gateway, LongCardCompany, PaymentMethodMapping) then
            exit(false);
        if PaymentMethodMapping."Payment Method Code" <> 'LONG' then
            exit(false);
        if not PaymentMethodMappingMgt.FindMapping(Shop.Code, Gateway, '', PaymentMethodMapping) then
            exit(false);
        if PaymentMethodMapping."Payment Method Code" <> 'BLANK' then
            exit(false);
        exit(not PaymentMethodMappingMgt.FindMapping(Shop.Code, Gateway, 'Unmatched company', PaymentMethodMapping));
    end;

    [HttpClientHandler]
    internal procedure PaymentMethodDiscoveryHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        Response.Content.WriteFrom(DiscoveryResponse);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shpfy Payment Method Mapping", 'OnBeforeInsertEvent', '', false, false)]
    local procedure FailSelectedPaymentMethodMappingInsert(var Rec: Record "Shpfy Payment Method Mapping"; RunTrigger: Boolean)
    begin
        if FailOnPaymentMethodMappingInsert and (Rec.Gateway = PaymentMethodMappingInsertFailureGateway) then
            Error('Injected payment-method mapping insert failure.');
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
            TransactionId := GetNextTransactionId();
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
    #endregion

    #region Then
    local procedure FindSuccessTransaction(OrderHeader: Record "Shpfy Order Header"; var OrderTransaction: Record "Shpfy Order Transaction")
    begin
        OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
        LibraryAssert.IsTrue(OrderTransaction.FindFirst(), 'Transaction should be created');
    end;
    #endregion
}
