// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.CRM.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Create Customer Test (ID 139565).
/// </summary>
codeunit 139565 "Shpfy Create Customer Test"
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
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";
        IsInitialized: Boolean;
        OnCreateCustomerEventMsg: Label 'OnCreateCustomer', Locked = true;

    [Test]
    procedure UniTestCreateCustomerFromShopifyInfo()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        ShpfyCustomerAddress: Record "Shpfy Customer Address";
        ShpfyCreateCustomer: Codeunit "Shpfy Create Customer";
    begin
        // Creating Test data. The database must have a Config Template for creating a customer.
        Initialize();
        ShpfyCreateCustomer.SetShop(Shop);
        if not CustomerTempl.FindFirst() then
            exit;

        // [SCENARIO] Create a customer from an new Shopify Customer Address.
        ShpfyCustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress();
        ShpfyCustomerAddress.SetRecFilter();

        // [GIVEN] The shop
        ShpfyCreateCustomer.SetShop(Shop);
        // [GIVEN] The customer template code
        ShpfyCreateCustomer.SetTemplateCode(CustomerTempl.Code);
        // [GIVEN] The Shopify Customer Address record.
        ShpfyCreateCustomer.Run(ShpfyCustomerAddress);
        // [THEN] The customer record can be found by the link of CustomerSystemId.
        ShpfyCustomerAddress.Get(ShpfyCustomerAddress.Id);
        if not Customer.GetBySystemId(ShpfyCustomerAddress.CustomerSystemId) then
            LibraryAssert.AssertRecordNotFound();
    end;

    [Test]
    procedure UnitTestMapCustomerWithoutDefaultAddressStillCreatesCustomer()
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
        ShopifyCustomer: Record "Shpfy Customer";
        ShopifyCustomerAddress: Record "Shpfy Customer Address";
        ICustomerMapping: Interface "Shpfy ICustomer Mapping";
        JCustomerInfo: JsonObject;
        CustomerId: BigInteger;
        ResultCode: Code[20];
    begin
        // [SCENARIO] A staged Shopify customer that is not yet linked to a BC customer and whose address is not flagged
        // as default (Shopify defaultAddress = null) still gets a BC customer created when mapping allows creation.
        Initialize();
        if not CustomerTempl.FindFirst() then
            exit;

        // [GIVEN] A staged Shopify customer without a linked BC customer
        CustomerId := CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        // [GIVEN] The customer has an address that is not marked as default
        ShopifyCustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);
        ShopifyCustomerAddress.TestField(Default, false);

        // [WHEN] Mapping the customer by email/phone with customer creation allowed
        ICustomerMapping := "Shpfy Customer Mapping"::"By EMail/Phone";
        JCustomerInfo := CustomerInitTest.CreateJsonCustomerInfo(Shop."Name Source", Shop."Name 2 Source");
        ResultCode := ICustomerMapping.DoMapping(CustomerId, JCustomerInfo, Shop.Code, CustomerTempl.Code, true);

        // [THEN] A BC customer is created, linked to the Shopify customer, even though no default address existed
        LibraryAssert.AreNotEqual('', ResultCode, 'A customer should be created when the customer has no default address.');
        LibraryAssert.IsTrue(Customer.Get(ResultCode), 'The mapped BC customer should exist.');
        ShopifyCustomer.Get(CustomerId);
        ShopifyCustomer.CalcFields("Customer No.");
        LibraryAssert.AreEqual(ResultCode, ShopifyCustomer."Customer No.", 'The Shopify customer should be linked to the created BC customer.');
    end;

    [Test]
    procedure UnitTestUpdateCustomerWithoutDefaultAddressDoesNotError()
    var
        Customer: Record Customer;
        ShopifyCustomer: Record "Shpfy Customer";
        ShopifyCustomerAddress: Record "Shpfy Customer Address";
        UpdateCustomer: Codeunit "Shpfy Update Customer";
    begin
        // [SCENARIO] Updating a linked BC customer from a Shopify customer that has no default address
        // (Shopify defaultAddress = null) falls back to an available address instead of erroring.
        Initialize();

        // [GIVEN] A BC customer linked to a Shopify customer
        Customer.Init();
        Customer."No." := CopyStr(Any.AlphanumericText(10), 1, MaxStrLen(Customer."No."));
        Customer.Insert(true);
        CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer.Modify();

        // [GIVEN] The Shopify customer has an address that is not marked as default
        ShopifyCustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);
        ShopifyCustomerAddress.TestField(Default, false);

        // [WHEN] The customer is updated from Shopify
        UpdateCustomer.SetShop(Shop);
        UpdateCustomer.Run(ShopifyCustomer);

        // [THEN] No error is raised and the customer address is filled from the available (non-default) address
        Customer.Get(Customer."No.");
        LibraryAssert.AreEqual(ShopifyCustomerAddress."Address 1", Customer.Address, 'Customer address should be updated from the available address.');
    end;

    [Test]
    procedure UnitTestB2CCustomerCreationUsesExplicitTemplateBeforeCountryAndShopTemplates()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        CountryTemplateCode: Code[20];
        ExplicitTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
        ExplicitPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An explicit customer template overrides country and shop customer templates.

        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] The shop company name source is configured.
        //[GIVEN] The shop customer name source is configured.
        //[GIVEN] The shop name configuration is saved.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] Duplicate-contact auto-search is disabled.
        //[GIVEN] Duplicate search string maintenance is disabled.
        //[GIVEN] Marketing setup is saved.
        //[GIVEN] Initialized customer setup is committed.
        Initialize();

        //[GIVEN] A country customer template is configured.
        CountryTemplateCode := CreateCustomerTemplate(Shop, CountryPaymentTermsCode);
        //[GIVEN] The country row is configured with its customer template.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode);
        //[GIVEN] An explicit customer template is configured.
        ExplicitTemplateCode := CreateCustomerTemplate(Shop, ExplicitPaymentTermsCode);
        //[GIVEN] The shop is copied for this selection.
        TestShop := Shop;
        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, 'US', '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2C customer is created with the explicit template.
        Customer := CreateCustomerFromShopifyAddress(TestShop, ExplicitTemplateCode);
        UnbindSubscription(TemplateEvents);

        //[THEN] The created customer uses the explicit template.
        LibraryAssert.AreEqual(ExplicitPaymentTermsCode, Customer."Payment Terms Code", 'Explicit template should be selected.');
        //[THEN] Only the original create-customer events are raised.
        TemplateEvents.VerifyTemplateEvents('', 'BeforeCreate;AfterCreate;');
    end;

    [Test]
    procedure UnitTestB2CCustomerCreationUsesCountryTemplateBeforeShopTemplate()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        CountryTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The country customer template takes precedence over the shop customer template.

        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] The shop company name source is configured.
        //[GIVEN] The shop customer name source is configured.
        //[GIVEN] The shop name configuration is saved.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] Duplicate-contact auto-search is disabled.
        //[GIVEN] Duplicate search string maintenance is disabled.
        //[GIVEN] Marketing setup is saved.
        //[GIVEN] Initialized customer setup is committed.
        Initialize();

        //[GIVEN] A country customer template is configured.
        CountryTemplateCode := CreateCustomerTemplate(Shop, CountryPaymentTermsCode);
        //[GIVEN] The country row is configured with its customer template.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode);
        //[GIVEN] The shop customer template remains configured as a fallback.
        TestShop := Shop;
        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, 'US', '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2C customer is created without an explicit template.
        Customer := CreateCustomerFromShopifyAddress(TestShop, '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The country customer template is applied.
        LibraryAssert.AreEqual(CountryPaymentTermsCode, Customer."Payment Terms Code", 'The country customer template should be selected.');
        //[THEN] The original customer and template events run in order.
        TemplateEvents.VerifyTemplateEvents(CountryTemplateCode, 'BeforeCreate;BeforeTemplate;AfterTemplate;AfterCreate;');
    end;

    [Test]
    procedure UnitTestB2CTemplateBeforeEventHandlesSelectionWithoutDefaultTemplate()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        OverrideTemplateCode: Code[20];
        OverridePaymentTermsCode: Code[10];
    begin
        //[SCENARIO] A handled before event selects a B2C template without a shop default.

        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] The shop company name source is configured.
        //[GIVEN] The shop customer name source is configured.
        //[GIVEN] The shop name configuration is saved.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] Duplicate-contact auto-search is disabled.
        //[GIVEN] Duplicate search string maintenance is disabled.
        //[GIVEN] Marketing setup is saved.
        //[GIVEN] Initialized customer setup is committed.
        Initialize();
        //[GIVEN] The test shop has no customer template.
        TestShop := Shop;
        //[GIVEN] The test shop customer template is blank.
        TestShop."Customer Templ. Code" := '';
        //[GIVEN] An override customer template exists.
        OverrideTemplateCode := CreateCustomerTemplate(Shop, OverridePaymentTermsCode);
        //[GIVEN] The template event handles selection and returns the override template.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, 'US', OverrideTemplateCode, true, '');

        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2C customer is created.
        Customer := CreateCustomerFromShopifyAddress(TestShop, '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original customer and template events run in order.
        TemplateEvents.VerifyTemplateEvents(OverrideTemplateCode, 'BeforeCreate;BeforeTemplate;AfterTemplate;AfterCreate;');
        //[THEN] The handled override template is applied.
        LibraryAssert.AreEqual(OverridePaymentTermsCode, Customer."Payment Terms Code", 'The B2C before event should bypass automatic selection and validation when handled.');
    end;

    [Test]
    procedure UnitTestB2CTemplateAfterEventOverridesAutomaticSelection()
    var
        Customer: Record Customer;
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        CountryTemplateCode: Code[20];
        OverrideTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
        OverridePaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An after event overrides the automatically selected B2C country template.

        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] The shop company name source is configured.
        //[GIVEN] The shop customer name source is configured.
        //[GIVEN] The shop name configuration is saved.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] Duplicate-contact auto-search is disabled.
        //[GIVEN] Duplicate search string maintenance is disabled.
        //[GIVEN] Marketing setup is saved.
        //[GIVEN] Initialized customer setup is committed.
        Initialize();
        //[GIVEN] A country customer template exists.
        CountryTemplateCode := CreateCustomerTemplate(Shop, CountryPaymentTermsCode);
        //[GIVEN] The US country row uses the country customer template.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode);
        //[GIVEN] An after-event override template exists.
        OverrideTemplateCode := CreateCustomerTemplate(Shop, OverridePaymentTermsCode);
        //[GIVEN] The after event is configured to return the override template.
        TemplateEvents.ConfigureTemplateEvents(Shop.Code, 'US', '', false, OverrideTemplateCode);

        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2C customer is created.
        Customer := CreateCustomerFromShopifyAddress(Shop, '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original customer and template events run in order.
        TemplateEvents.VerifyTemplateEvents(CountryTemplateCode, 'BeforeCreate;BeforeTemplate;AfterTemplate;AfterCreate;');
        //[THEN] The after-event override template is applied.
        LibraryAssert.AreEqual(OverridePaymentTermsCode, Customer."Payment Terms Code", 'The B2C after event should override the selected country template.');
    end;

    [Test]
    procedure UnitTestB2CCustomerCreationUsesShopTemplateWhenCountryTemplateIsNotConfigured()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        ShopPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The shop customer template is used when no country customer template is configured.

        //[GIVEN] The shop is created and configured for customer names.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] Duplicate-contact search is disabled.
        //[GIVEN] Initialized customer setup is committed.
        Initialize();

        //[GIVEN] The US country customer template is not configured.
        CreateShopifyCustomerTemplate('US', '');

        //[GIVEN] The test shop is copied with its customer template.
        TestShop := Shop;
        //[GIVEN] The shop customer template code is set.
        TestShop."Customer Templ. Code" := CreateCustomerTemplate(Shop, ShopPaymentTermsCode);

        //[WHEN] A B2C customer is created without an explicit template.
        Customer := CreateCustomerFromShopifyAddress(TestShop, '');

        //[THEN] The shop customer template is applied.
        LibraryAssert.AreEqual(ShopPaymentTermsCode, Customer."Payment Terms Code", 'The shop customer template should be selected.');
    end;

    local procedure CreateShopifyCustomerTemplate(CountryCode: Code[20]; CustomerTemplateCode: Code[20])
    begin
        InitializeTest.SetShopifyCustomerTemplate(Shop.Code, CountryCode, CustomerTemplateCode, '');
    end;

    local procedure CreateCustomerFromShopifyAddress(ShopifyShop: Record "Shpfy Shop"; ExplicitTemplateCode: Code[20]) Customer: Record Customer
    var
        ShopifyCustomerAddress: Record "Shpfy Customer Address";
        CreateCustomer: Codeunit "Shpfy Create Customer";
    begin
        InitializeTest.EnsureCountryRegion('US');
        ShopifyCustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress();
        CreateCustomer.SetShop(ShopifyShop);
        if ExplicitTemplateCode <> '' then
            CreateCustomer.SetTemplateCode(ExplicitTemplateCode);
        CreateCustomer.Run(ShopifyCustomerAddress);
        Customer.GetBySystemId(ShopifyCustomerAddress.CustomerSystemId);
    end;

    internal procedure CreateCustomerTemplate(ShpfyShop: Record "Shpfy Shop"; var PaymentTermsCode: Code[10]) CustomerTemplateCode: Code[20]
    var
        CustomerTempl: Record "Customer Templ.";
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode = '' then
            repeat
                PaymentTermsCode := CopyStr(Any.AlphanumericText(MaxStrLen(PaymentTermsCode)), 1, MaxStrLen(PaymentTermsCode));
            until (PaymentTermsCode <> '') and not PaymentTerms.Get(PaymentTermsCode);
        if not PaymentTerms.Get(PaymentTermsCode) then begin
            PaymentTerms.Init();
            PaymentTerms.Code := PaymentTermsCode;
            PaymentTerms.Insert(false);
        end;
        repeat
            CustomerTemplateCode := CopyStr(Any.AlphanumericText(MaxStrLen(CustomerTemplateCode)), 1, MaxStrLen(CustomerTemplateCode));
        until (CustomerTemplateCode <> '') and not CustomerTempl.Get(CustomerTemplateCode);

        CustomerTempl.Init();
        CustomerTempl.Code := CustomerTemplateCode;
        CustomerTempl."Payment Terms Code" := PaymentTermsCode;
        CustomerTempl."Customer Posting Group" := ShpfyShop."Customer Posting Group";
        CustomerTempl."Gen. Bus. Posting Group" := ShpfyShop."Gen. Bus. Posting Group";
        CustomerTempl."VAT Bus. Posting Group" := ShpfyShop."VAT Bus. Posting Group";
        CustomerTempl.Insert(false);
    end;

    local procedure Initialize()
    var
        MarketingSetup: Record "Marketing Setup";
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        InitializeTest.EnsureCustomerNoSeries();
        Shop := InitializeTest.CreateShop();
        Shop."Name Source" := "Shpfy Name Source"::CompanyName;
        Shop."Name 2 Source" := "Shpfy Name Source"::FirstAndLastName;
        Shop.Modify(false);
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        // Disable duplicate-contact auto-search so creating/updating a customer (which cascades to
        // contact creation) does not raise an interactive "Duplicate Contacts were found" confirm
        // dialog during automated integration tests, where GuiAllowed is true and some localizations'
        // demo data enables this setting.
        if MarketingSetup.Get() then begin
            MarketingSetup."Autosearch for Duplicates" := false;
            MarketingSetup."Maintain Dupl. Search Strings" := false;
            MarketingSetup.Modify(false);
        end;

        Commit();
    end;

    [MessageHandler]
    procedure OnCreateCustomerHandler(Message: Text)
    begin
        LibraryAssert.ExpectedMessage(OnCreateCustomerEventMsg, Message);
    end;

    [HttpClientHandler]
    internal procedure HttpClientHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        exit(false);
    end;
}
