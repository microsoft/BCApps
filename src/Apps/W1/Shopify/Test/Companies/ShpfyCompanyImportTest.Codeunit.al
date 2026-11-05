// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139647 "Shpfy Company Import Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    EventSubscriberInstance = Manual;

    var
        InitializedShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        Any: Codeunit Any;
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        LocationValues: Dictionary of [Text, Text];
        ExpectedEventShopCode: Code[20];
        ExpectedEventCountryCode: Code[20];
        BeforeTemplateOverride: Code[20];
        AfterTemplateOverride: Code[20];
        ObservedTemplateCode: Code[20];
        HandleTemplateSelection: Boolean;
        CustomerEventOrder: Text;

    [Test]
    procedure UnitTestFindMappingBetweenCompanyAndCustomer()
    var
        Customer: Record Customer;
        ShopifyCompany: Record "Shpfy Company";
        ShopifyCustomer: Record "Shpfy Customer";
        ShopifyShop: Record "Shpfy Shop";
        CompanyMapping: Codeunit "Shpfy Company Mapping";
        Result: Boolean;
    begin
        // [SCENARIO] Importing a company record that is already mapped to a customer record via email.
        Initialize();
        ShopifyShop := InitializeTest.CreateShop();

        // [GIVEN] Shop, Shopify company and Shopify customer
        CompanyMapping.SetShop(ShopifyShop);
        ShopifyCompany.Insert();
#pragma warning disable AA0210
        Customer.SetFilter("E-Mail", '<>%1', '');
#pragma warning restore AA0210
        Customer.FindFirst();
        ShopifyCustomer.Email := Customer."E-Mail";


        // [WHEN] Invoke CompanyMapping.FindMapping(ShopifyCompany, ShopifyCustomer)
        Result := CompanyMapping.FindMapping(ShopifyCompany, ShopifyCustomer);

        // [THEN] The result is true and Shopify company has the correct customer id.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.AreEqual(ShopifyCompany."Customer SystemId", Customer.SystemId, 'Customer SystemId');
    end;

    [Test]
    [HandlerFunctions('CompanyImportHttpHandler')]
    procedure UnitTestImportCompanyWithLocation()
    var
        ShopifyCompany: Record "Shpfy Company";
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Importing a company with location with defined payment term.
        Initialize();

        // [GIVEN] Shopify company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company location values in Shopify
        CreateLocationValues(LocationValues);

        // [WHEN] Invoke CompanyImport
        InvokeCompanyImport(ShopifyCompany);

        // [THEN] Location is created with the correct payment term and all other .
        VerifyShopifyCompanyLocationValues(ShopifyCompany, LocationValues);
    end;

    [Test]
    procedure UnitTestUpdateCustomerFromCompanyWithPaymentTerms()
    var
        Customer: Record Customer;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        UpdateCustomer: Codeunit "Shpfy Update Customer";
        PaymentTermsCode: Code[10];
        ShopifyPaymentTermsId: BigInteger;
    begin
        // [SCENARIO] Update a customer from a company with location with defined payment term and existing payment terms in BC.
        Initialize();

        // [GIVEN] Payment terms
        PaymentTermsCode := CreatePaymentTerms();
        // [GIVEN] Shopify payment terms
        ShopifyPaymentTermsId := CreateShopifyPaymentTerms(PaymentTermsCode);
        // [GIVEN] Customer record with payment terms
        CreateCustomerWithPaymentTerms(Customer, PaymentTermsCode);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, Customer.SystemId);
        // [GIVEN] Company Location
        CreateCompanyLocation(CompanyLocation, ShopifyCompany, ShopifyPaymentTermsId);

        // [WHEN] Invoke UpdateCustomerFromCompany
        UpdateCustomer.UpdateCustomerFromCompany(ShopifyCompany);

        // [THEN] Customer record is updated with the correct payment terms.
        Customer.GetBySystemId(Customer.SystemId);
        LibraryAssert.AreEqual(Customer."Payment Terms Code", PaymentTermsCode, 'Payment Terms Code');
    end;

    [Test]
    procedure UnitTestCreateCustomerFromCompanyWithPaymentTerms()
    var
        Customer: Record Customer;
        TempShopifyCustomer: Record "Shpfy Customer" temporary;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        CreateCustomer: Codeunit "Shpfy Create Customer";
        PaymentTermsCode: Code[10];
        ShopifyPaymentTermsId: BigInteger;
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Create a customer from a company with location with defined payment term.
        Initialize();

        // [GIVEN] Payment terms
        PaymentTermsCode := CreatePaymentTerms();
        // [GIVEN] Shopify payment terms
        ShopifyPaymentTermsId := CreateShopifyPaymentTerms(PaymentTermsCode);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company Location
        CreateCompanyLocation(CompanyLocation, ShopifyCompany, ShopifyPaymentTermsId);
        // [GIVEN] TempShopifyCustomer
        CreateTempShopifyCustomer(TempShopifyCustomer);

        // [WHEN] Invoke CreateCustomerFromCompany
        CreateCustomer.SetShop(InitializedShop);
        CreateCustomer.SetTemplateCode(InitializedShop."Customer Templ. Code");
        CreateCustomer.CreateCustomerFromCompany(ShopifyCompany, TempShopifyCustomer);

        // [THEN] Customer record is created with the correct payment terms.
        Customer.GetBySystemId(ShopifyCompany."Customer SystemId");
        LibraryAssert.AreEqual(Customer."Payment Terms Code", PaymentTermsCode, 'Payment Terms Code');
    end;

    [Test]
    procedure UnitTestCreateCustomerFromCompanyWithRegistrationNo()
    var
        Customer: Record Customer;
        TempShopifyCustomer: Record "Shpfy Customer" temporary;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        CreateCustomer: Codeunit "Shpfy Create Customer";
        TaxRegistrationId: Text[150];
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Create a customer from a company with location with Tax Registration Id using Registration No. mapping.
        Initialize();

        // [GIVEN] Tax Registration Id
        TaxRegistrationId := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(TaxRegistrationId));
        // [GIVEN] Shop with Tax Id Mapping set to "Registration No."
        InitializedShop."Shpfy Comp. Tax Id Mapping" := Enum::"Shpfy Comp. Tax Id Mapping"::"Registration No.";
        InitializedShop.Modify(false);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company Location with Tax Registration Id
        CreateCompanyLocationWithTaxId(CompanyLocation, ShopifyCompany, TaxRegistrationId);
        // [GIVEN] TempShopifyCustomer
        CreateTempShopifyCustomer(TempShopifyCustomer);

        // [WHEN] Invoke CreateCustomerFromCompany
        CreateCustomer.SetShop(InitializedShop);
        CreateCustomer.SetTemplateCode(InitializedShop."Customer Templ. Code");
        CreateCustomer.CreateCustomerFromCompany(ShopifyCompany, TempShopifyCustomer);

        // [THEN] Customer record is created with the correct Registration Number.
        Customer.GetBySystemId(ShopifyCompany."Customer SystemId");
        LibraryAssert.AreEqual(TaxRegistrationId, Customer."Registration Number", 'Registration Number');
    end;

    [Test]
    procedure UnitTestCreateCustomerFromCompanyWithVATRegistrationNo()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        TempShopifyCustomer: Record "Shpfy Customer" temporary;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        CreateCustomer: Codeunit "Shpfy Create Customer";
        TaxRegistrationId: Text[150];
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Create a customer from a company with location with Tax Registration Id using VAT Registration No. mapping.
        Initialize();

        // [GIVEN] Tax Registration Id
        CompanyInformation.Get();
        TaxRegistrationId := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        // [GIVEN] Shop with Tax Id Mapping set to "VAT Registration No."
        InitializedShop."Shpfy Comp. Tax Id Mapping" := Enum::"Shpfy Comp. Tax Id Mapping"::"VAT Registration No.";
        InitializedShop.Modify(false);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company Location with Tax Registration Id
        CreateCompanyLocationWithTaxId(CompanyLocation, ShopifyCompany, TaxRegistrationId);
        // [GIVEN] TempShopifyCustomer
        CreateTempShopifyCustomer(TempShopifyCustomer);

        // [WHEN] Invoke CreateCustomerFromCompany
        CreateCustomer.SetShop(InitializedShop);
        CreateCustomer.SetTemplateCode(InitializedShop."Customer Templ. Code");
        CreateCustomer.CreateCustomerFromCompany(ShopifyCompany, TempShopifyCustomer);

        // [THEN] Customer record is created with the correct VAT Registration No.
        Customer.GetBySystemId(ShopifyCompany."Customer SystemId");
        LibraryAssert.AreEqual(TaxRegistrationId, Customer."VAT Registration No.", 'VAT Registration No.');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesExplicitTemplateBeforeConfiguredTemplates()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        CountryTemplateCode: Code[20];
        ExplicitTemplateCode: Code[20];
        ShopCompanyTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
        ExplicitPaymentTermsCode: Code[10];
        ShopCompanyPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An explicit order template overrides all configured B2B and customer templates.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A country customer template exists.
        CountryTemplateCode := CreateCustomerTemplate(InitializedShop, CountryPaymentTermsCode);
        //[GIVEN] The country row uses the customer and company templates.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode, CountryTemplateCode);
        //[GIVEN] A shop-level company template exists.
        ShopCompanyTemplateCode := CreateCustomerTemplate(InitializedShop, ShopCompanyPaymentTermsCode);
        //[GIVEN] A test shop copy is used.
        TestShop := InitializedShop;
        //[GIVEN] The test shop copy has the company template.
        TestShop."Company Templ. Code" := ShopCompanyTemplateCode;
        //[GIVEN] An explicit order template exists.
        ExplicitTemplateCode := CreateCustomerTemplate(InitializedShop, ExplicitPaymentTermsCode);

        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, '', '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created with the explicit template.
        Customer := CreateCustomerFromCompany(TestShop, 'US', ExplicitTemplateCode);
        UnbindSubscription(TemplateEvents);

        //[THEN] The created customer uses the explicit template.
        LibraryAssert.AreEqual(ExplicitPaymentTermsCode, Customer."Payment Terms Code", 'Explicit template should be selected.');
        //[THEN] Template selection events are not raised.
        TemplateEvents.VerifyTemplateEvents('', '');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesIsoCompanyTemplateBeforeMappedCountryAndShopTemplates()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        IsoTemplateCode: Code[20];
        MappedTemplateCode: Code[20];
        ShopTemplateCode: Code[20];
        IsoPaymentTermsCode: Code[10];
        MappedPaymentTermsCode: Code[10];
        ShopPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The Shopify ISO country company template takes precedence over the mapped country and shop templates.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A Shopify ISO code is mapped to a different Business Central country code.
        CreateCountryRegionMapping(CountryRegion, 'QZ');
        //[GIVEN] A company template exists for the Shopify ISO country.
        IsoTemplateCode := CreateCustomerTemplate(InitializedShop, IsoPaymentTermsCode);
        //[GIVEN] A distinct company template exists for the mapped country.
        MappedTemplateCode := CreateCustomerTemplate(InitializedShop, MappedPaymentTermsCode);
        //[GIVEN] The ISO row uses its company template.
        CreateShopifyCustomerTemplate('QZ', '', IsoTemplateCode);
        //[GIVEN] The mapped-country row uses its company template.
        CreateShopifyCustomerTemplate(CountryRegion.Code, '', MappedTemplateCode);
        //[GIVEN] A shop-level company template exists.
        ShopTemplateCode := CreateCustomerTemplate(InitializedShop, ShopPaymentTermsCode);
        //[GIVEN] A test shop copy is used.
        TestShop := InitializedShop;
        //[GIVEN] The test shop copy has its own company template.
        TestShop."Company Templ. Code" := ShopTemplateCode;
        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created from the Shopify ISO country.
        Customer := CreateCustomerFromCompany(TestShop, 'QZ', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The ISO-country company template is applied.
        LibraryAssert.AreEqual(IsoPaymentTermsCode, Customer."Payment Terms Code", 'The ISO-country template should win.');
        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(IsoTemplateCode, 'BeforeTemplate;AfterTemplate;');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesMappedCountryTemplateWhenIsoTemplateIsBlank()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        MappedTemplateCode: Code[20];
        ShopTemplateCode: Code[20];
        MappedPaymentTermsCode: Code[10];
        ShopPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The mapped country company template is used when the Shopify ISO row has no company template.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A Shopify ISO code is mapped to a different Business Central country code.
        CreateCountryRegionMapping(CountryRegion, 'QY');
        //[GIVEN] The ISO country row has no company template.
        CreateShopifyCustomerTemplate('QY', '', '');
        //[GIVEN] A company template exists for the mapped country.
        MappedTemplateCode := CreateCustomerTemplate(InitializedShop, MappedPaymentTermsCode);
        //[GIVEN] The mapped-country row uses its company template.
        CreateShopifyCustomerTemplate(CountryRegion.Code, '', MappedTemplateCode);
        //[GIVEN] A shop-level company template exists.
        ShopTemplateCode := CreateCustomerTemplate(InitializedShop, ShopPaymentTermsCode);
        //[GIVEN] A test shop copy is used.
        TestShop := InitializedShop;
        //[GIVEN] The test shop copy has its own company template.
        TestShop."Company Templ. Code" := ShopTemplateCode;
        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created from the Shopify ISO country.
        Customer := CreateCustomerFromCompany(TestShop, 'QY', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The mapped-country company template is applied.
        LibraryAssert.AreEqual(MappedPaymentTermsCode, Customer."Payment Terms Code", 'The mapped-country template should be selected.');
        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(MappedTemplateCode, 'BeforeTemplate;AfterTemplate;');
    end;

    [Test]
    procedure UnitTestCompanyCustomerCreatesMissingMappedCountryTemplateRow()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
    begin
        //[SCENARIO] B2B template selection creates only the missing mapped-country setup row.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a distinct BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QK');
        //[GIVEN] The mapped-country template row does not exist.
        LibraryAssert.IsFalse(ShopifyCustomerTemplate.Get(InitializedShop.Code, CountryRegion.Code), 'The mapped-country row should be missing before customer creation.');
        //[GIVEN] The Shopify ISO template row does not exist.
        LibraryAssert.IsFalse(ShopifyCustomerTemplate.Get(InitializedShop.Code, 'QK'), 'The ISO row should be missing before customer creation.');

        //[WHEN] A B2B customer is created from the Shopify ISO country.
        Customer := CreateCustomerFromCompany(InitializedShop, 'QK', '');

        //[THEN] The mapped-country template row is created.
        LibraryAssert.IsTrue(ShopifyCustomerTemplate.Get(InitializedShop.Code, CountryRegion.Code), 'The mapped-country row should be created.');
        //[THEN] The new row has blank customer and company templates.
        LibraryAssert.AreEqual('', ShopifyCustomerTemplate."Customer Templ. Code", 'The inserted row should keep the customer template blank.');
        //[THEN] The inserted company template remains blank.
        LibraryAssert.AreEqual('', ShopifyCustomerTemplate."Company Templ. Code", 'The inserted row should keep the company template blank.');
        //[THEN] No additional ISO template row is created.
        LibraryAssert.IsFalse(ShopifyCustomerTemplate.Get(InitializedShop.Code, 'QK'), 'Template selection should create only the mapped-country row.');
        //[THEN] The customer was created using the shop fallback template.
        LibraryAssert.IsTrue(Customer."No." <> '', 'The shop customer template should allow customer creation.');
    end;

    [Test]
    procedure UnitTestCompanyCustomerPreservesExistingMappedCountryTemplateRow()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
        CustomerTemplateCode: Code[20];
        CompanyTemplateCode: Code[20];
        CustomerPaymentTermsCode: Code[10];
        CompanyPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] B2B template selection preserves both codes on an existing mapped-country row.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a distinct BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QJ');
        //[GIVEN] A customer template exists for the mapped country row.
        CustomerTemplateCode := CreateCustomerTemplate(InitializedShop, CustomerPaymentTermsCode);
        //[GIVEN] A distinct company template exists for the mapped country row.
        CompanyTemplateCode := CreateCustomerTemplate(InitializedShop, CompanyPaymentTermsCode);
        //[GIVEN] The mapped-country row contains both template codes.
        CreateShopifyCustomerTemplate(CountryRegion.Code, CustomerTemplateCode, CompanyTemplateCode);

        //[WHEN] A B2B customer is created from the Shopify ISO country.
        Customer := CreateCustomerFromCompany(InitializedShop, 'QJ', '');

        //[THEN] The company template is selected.
        LibraryAssert.AreEqual(CompanyPaymentTermsCode, Customer."Payment Terms Code", 'The mapped-country company template should be selected.');
        //[THEN] The existing mapped-country row is retrieved.
        LibraryAssert.IsTrue(ShopifyCustomerTemplate.Get(InitializedShop.Code, CountryRegion.Code), 'The mapped-country row should remain available.');
        //[THEN] The customer template code is preserved.
        LibraryAssert.AreEqual(CustomerTemplateCode, ShopifyCustomerTemplate."Customer Templ. Code", 'The existing customer template code must not be overwritten.');
        //[THEN] The company template code is preserved.
        LibraryAssert.AreEqual(CompanyTemplateCode, ShopifyCustomerTemplate."Company Templ. Code", 'The existing company template code must not be overwritten.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateBeforeEventHandlesSelectionWithoutDefaultTemplate()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        OverrideTemplateCode: Code[20];
        OverridePaymentTermsCode: Code[10];
    begin
        //[SCENARIO] A handled before event selects a template without a shop default.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QT');
        //[GIVEN] A test shop copy has no company or customer template.
        TestShop := InitializedShop;
        //[GIVEN] The test shop company template is blank.
        TestShop."Company Templ. Code" := '';
        //[GIVEN] The test shop customer template is blank.
        TestShop."Customer Templ. Code" := '';
        //[GIVEN] An override customer template exists.
        OverrideTemplateCode := CreateCustomerTemplate(InitializedShop, OverridePaymentTermsCode);
        //[GIVEN] The template event handles selection and returns the override template.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, OverrideTemplateCode, true, '');
        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created.
        Customer := CreateCustomerFromCompany(TestShop, 'QT', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(OverrideTemplateCode, 'BeforeTemplate;AfterTemplate;');
        //[THEN] The handled override template is applied.
        LibraryAssert.AreEqual(OverridePaymentTermsCode, Customer."Payment Terms Code", 'Handled selection should bypass automatic selection and missing-template validation.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateBeforeEventWithoutHandledUsesAutomaticSelection()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        OverrideTemplateCode: Code[20];
        CompanyTemplateCode: Code[20];
        OverridePaymentTermsCode: Code[10];
        CompanyPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An unhandled before event preserves automatic company template precedence.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QS');
        //[GIVEN] A company template is configured for the Shopify ISO country.
        CompanyTemplateCode := CreateCustomerTemplate(InitializedShop, CompanyPaymentTermsCode);
        //[GIVEN] The Shopify ISO country row uses the company template.
        CreateShopifyCustomerTemplate('QS', '', CompanyTemplateCode);
        //[GIVEN] A different template is supplied by the unhandled before event.
        OverrideTemplateCode := CreateCustomerTemplate(InitializedShop, OverridePaymentTermsCode);
        //[GIVEN] The test shop is copied for this selection.
        TestShop := InitializedShop;
        //[GIVEN] The template event is configured as unhandled.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, OverrideTemplateCode, false, '');
        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created.
        Customer := CreateCustomerFromCompany(TestShop, 'QS', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(CompanyTemplateCode, 'BeforeTemplate;AfterTemplate;');
        //[THEN] The automatic company template is applied.
        LibraryAssert.AreEqual(CompanyPaymentTermsCode, Customer."Payment Terms Code", 'An unhandled before event must not bypass company-first selection.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateAfterEventOverridesAutomaticSelection()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        OverrideTemplateCode: Code[20];
        CompanyTemplateCode: Code[20];
        OverridePaymentTermsCode: Code[10];
        CompanyPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An after event overrides the automatically selected company template.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QR');
        //[GIVEN] A company template is configured for the Shopify ISO country.
        CompanyTemplateCode := CreateCustomerTemplate(InitializedShop, CompanyPaymentTermsCode);
        //[GIVEN] The Shopify ISO country row uses the company template.
        CreateShopifyCustomerTemplate('QR', '', CompanyTemplateCode);
        //[GIVEN] An after-event override template exists.
        OverrideTemplateCode := CreateCustomerTemplate(InitializedShop, OverridePaymentTermsCode);
        //[GIVEN] The test shop is copied for this selection.
        TestShop := InitializedShop;
        //[GIVEN] The after event is configured to return the override template.
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, '', false, OverrideTemplateCode);
        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created.
        Customer := CreateCustomerFromCompany(TestShop, 'QR', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(CompanyTemplateCode, 'BeforeTemplate;AfterTemplate;');
        //[THEN] The after-event override template is applied.
        LibraryAssert.AreEqual(OverridePaymentTermsCode, Customer."Payment Terms Code", 'The after event should override the automatically selected company template.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateUnhandledBeforeEventPreservesFallbackOverride()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TestShop: Record "Shpfy Shop";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        OverrideTemplateCode: Code[20];
        OverridePaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An unhandled before-event template is preserved when country templates are blank.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QQ');
        //[GIVEN] The Shopify ISO and mapped-country rows have no templates.
        CreateShopifyCustomerTemplate('QQ', '', '');
        //[GIVEN] The mapped-country row has no customer or company template.
        CreateShopifyCustomerTemplate(CountryRegion.Code, '', '');
        //[GIVEN] The test shop has no company or customer template.
        TestShop := InitializedShop;
        //[GIVEN] The test shop company template is blank.
        TestShop."Company Templ. Code" := '';
        //[GIVEN] The test shop customer template is blank.
        TestShop."Customer Templ. Code" := '';
        //[GIVEN] The before event supplies an override template without handling selection.
        OverrideTemplateCode := CreateCustomerTemplate(InitializedShop, OverridePaymentTermsCode);
        TemplateEvents.ConfigureTemplateEvents(TestShop.Code, CountryRegion.Code, OverrideTemplateCode, false, '');
        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created.
        Customer := CreateCustomerFromCompany(TestShop, 'QQ', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(OverrideTemplateCode, 'BeforeTemplate;AfterTemplate;');
        //[THEN] The before-event template is applied.
        LibraryAssert.AreEqual(OverridePaymentTermsCode, Customer."Payment Terms Code", 'An unhandled before-event template should survive blank country templates as on main.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateAfterEventOverridesHandledSelection()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        BeforeTemplateCode: Code[20];
        AfterTemplateCode: Code[20];
        BeforePaymentTermsCode: Code[10];
        AfterPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] An after event overrides a handled before-event template selection.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A Shopify ISO code is mapped to a BC country code.
        CreateCountryRegionMapping(CountryRegion, 'QP');
        //[GIVEN] The before-event template exists.
        BeforeTemplateCode := CreateCustomerTemplate(InitializedShop, BeforePaymentTermsCode);
        //[GIVEN] The after-event template exists.
        AfterTemplateCode := CreateCustomerTemplate(InitializedShop, AfterPaymentTermsCode);
        //[GIVEN] The before event handles selection and the after event supplies another template.
        TemplateEvents.ConfigureTemplateEvents(InitializedShop.Code, CountryRegion.Code, BeforeTemplateCode, true, AfterTemplateCode);
        //[GIVEN] The template event subscriber is bound.
        BindSubscription(TemplateEvents);

        //[WHEN] A B2B customer is created.
        Customer := CreateCustomerFromCompany(InitializedShop, 'QP', '');
        UnbindSubscription(TemplateEvents);

        //[THEN] The original template events run once in order.
        TemplateEvents.VerifyTemplateEvents(BeforeTemplateCode, 'BeforeTemplate;AfterTemplate;');
        //[THEN] The after-event template is applied.
        LibraryAssert.AreEqual(AfterPaymentTermsCode, Customer."Payment Terms Code", 'The after event should also override a handled before-event selection.');
    end;

    [Test]
    procedure UnitTestMappedCompanyBypassesCreationAndTemplateEvents()
    var
        Customer: Record Customer;
        ShopifyCompany: Record "Shpfy Company";
        CompanyMapping: Codeunit "Shpfy Company Mapping";
        TemplateEvents: Codeunit "Shpfy Company Import Test";
        CustomerCount: Integer;
        CustomerNo: Code[20];
    begin
        //[SCENARIO] An existing company mapping returns its customer without raising creation or template events.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] Customer number series exist.
        //[GIVEN] The Shopify shop exists.
        //[GIVEN] An access token is generated for the shop.
        //[GIVEN] The shop access token is registered.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();
        //[GIVEN] A BC customer exists.
        CreateCustomerWithPaymentTerms(Customer, '');
        //[GIVEN] The Shopify company is linked to the BC customer.
        CreateCompany(ShopifyCompany, Customer.SystemId);
        //[GIVEN] The current customer count is recorded.
        CustomerCount := Customer.Count();
        //[GIVEN] Company mapping uses the initialized shop.
        CompanyMapping.SetShop(InitializedShop);
        //[GIVEN] Template event subscribers are configured.
        TemplateEvents.ConfigureTemplateEvents(InitializedShop.Code, '', '', false, '');
        //[GIVEN] Template event subscribers are bound.
        BindSubscription(TemplateEvents);

        //[WHEN] The existing company mapping is resolved.
        CustomerNo := CompanyMapping.DoMapping(ShopifyCompany.Id, '', true);
        UnbindSubscription(TemplateEvents);

        //[THEN] The mapped customer number is returned.
        LibraryAssert.AreEqual(Customer."No.", CustomerNo, 'An existing company mapping should return the linked customer.');
        //[THEN] No customer is created.
        LibraryAssert.AreEqual(CustomerCount, Customer.Count(), 'An existing mapping must not create another customer.');
        //[THEN] Creation and template events are not raised.
        TemplateEvents.VerifyTemplateEvents('', '');
    end;

    internal procedure ConfigureTemplateEvents(ShopCode: Code[20]; CountryCode: Code[20]; BeforeOverride: Code[20]; Handled: Boolean; AfterOverride: Code[20])
    begin
        ExpectedEventShopCode := ShopCode;
        ExpectedEventCountryCode := CountryCode;
        BeforeTemplateOverride := BeforeOverride;
        HandleTemplateSelection := Handled;
        AfterTemplateOverride := AfterOverride;
        Clear(ObservedTemplateCode);
        Clear(CustomerEventOrder);
    end;

    internal procedure VerifyTemplateEvents(ExpectedTemplateCode: Code[20]; ExpectedOrder: Text)
    begin
        LibraryAssert.AreEqual(ExpectedOrder, CustomerEventOrder, 'Customer events should execute exactly once in the original order.');
        LibraryAssert.AreEqual(ExpectedTemplateCode, ObservedTemplateCode, 'The after event should receive the selected template.');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnBeforeFindCustomerTemplate', '', false, false)]
    local procedure OnBeforeFindCustomerTemplate(Shop: Record "Shpfy Shop"; CountryCode: Code[20]; var TemplateCode: Code[20]; var Handled: Boolean)
    begin
        LibraryAssert.AreEqual(ExpectedEventShopCode, Shop.Code, 'The before event should receive the original shop.');
        LibraryAssert.AreEqual(ExpectedEventCountryCode, CountryCode, 'The before event should receive the BC country code.');
        LibraryAssert.AreEqual('', TemplateCode, 'The before event should receive an empty template.');
        LibraryAssert.IsFalse(Handled, 'Template selection should initially be unhandled.');
        CustomerEventOrder += 'BeforeTemplate;';
        TemplateCode := BeforeTemplateOverride;
        Handled := HandleTemplateSelection;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnAfterFindCustomerTemplate', '', false, false)]
    local procedure OnAfterFindCustomerTemplate(Shop: Record "Shpfy Shop"; CountryCode: Code[20]; var TemplateCode: Code[20])
    begin
        LibraryAssert.AreEqual(ExpectedEventShopCode, Shop.Code, 'The after event should receive the original shop.');
        LibraryAssert.AreEqual(ExpectedEventCountryCode, CountryCode, 'The after event should receive the BC country code.');
        CustomerEventOrder += 'AfterTemplate;';
        ObservedTemplateCode := TemplateCode;
        if AfterTemplateOverride <> '' then
            TemplateCode := AfterTemplateOverride;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnBeforeCreateCustomer', '', false, false)]
    local procedure OnBeforeCreateCustomer()
    begin
        CustomerEventOrder += 'BeforeCreate;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnAfterCreateCustomer', '', false, false)]
    local procedure OnAfterCreateCustomer()
    begin
        CustomerEventOrder += 'AfterCreate;';
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesShopCompanyTemplateBeforeCountryCustomerTemplate()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        CountryTemplateCode: Code[20];
        ShopTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
        ShopPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The shop company template takes precedence over a country customer template.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A country customer template is configured.
        CountryTemplateCode := CreateCustomerTemplate(InitializedShop, CountryPaymentTermsCode);
        //[GIVEN] The country row is configured with its customer template.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode, '');
        //[GIVEN] A shop company template is created.
        ShopTemplateCode := CreateCustomerTemplate(InitializedShop, ShopPaymentTermsCode);
        //[GIVEN] The test shop is copied for this selection.
        TestShop := InitializedShop;
        //[GIVEN] The test shop has its own company template.
        TestShop."Company Templ. Code" := ShopTemplateCode;

        //[WHEN] A B2B customer is created from the country.
        Customer := CreateCustomerFromCompany(TestShop, 'US', '');

        //[THEN] The shop company template is applied.
        LibraryAssert.AreEqual(ShopPaymentTermsCode, Customer."Payment Terms Code", 'The shop company template should win.');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesCountryCustomerTemplateBeforeShopCustomerTemplate()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        CountryTemplateCode: Code[20];
        CountryPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The country customer template is used before the shop customer template when no company template is configured.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A country customer template is configured.
        CountryTemplateCode := CreateCustomerTemplate(InitializedShop, CountryPaymentTermsCode);
        //[GIVEN] The country row is configured with its customer template.
        CreateShopifyCustomerTemplate('US', CountryTemplateCode, '');
        //[GIVEN] No company-specific template is configured.
        TestShop := InitializedShop;
        //[GIVEN] The test shop company template is blank.
        TestShop."Company Templ. Code" := '';

        //[WHEN] A B2B customer is created from the country.
        Customer := CreateCustomerFromCompany(TestShop, 'US', '');

        //[THEN] The country customer template is applied.
        LibraryAssert.AreEqual(CountryPaymentTermsCode, Customer."Payment Terms Code", 'The country customer template should be selected.');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesShopCustomerTemplateWhenCountryTemplateIsNotConfigured()
    var
        Customer: Record Customer;
        TestShop: Record "Shpfy Shop";
        CustomerTemplateCode: Code[20];
        PaymentTermsCode: Code[10];
    begin
        //[SCENARIO] The shop customer template is used when no country or company template is configured.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A shop customer template is created.
        CustomerTemplateCode := CreateCustomerTemplate(InitializedShop, PaymentTermsCode);
        //[GIVEN] The test shop is copied for this selection.
        TestShop := InitializedShop;
        //[GIVEN] The test shop company template is blank.
        TestShop."Company Templ. Code" := '';
        //[GIVEN] The test shop customer template is configured.
        TestShop."Customer Templ. Code" := CustomerTemplateCode;

        //[WHEN] A B2B customer is created without a country template.
        Customer := CreateCustomerFromCompany(TestShop, 'QX', '');

        //[THEN] The shop customer template is applied.
        LibraryAssert.AreEqual(PaymentTermsCode, Customer."Payment Terms Code", 'The shop customer template should be selected.');
    end;

    [Test]
    procedure UnitTestCompanyCustomerUsesMappedCountryCustomerTemplateWhenIsoTemplateIsBlank()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
        TestShop: Record "Shpfy Shop";
        MappedTemplateCode: Code[20];
        MappedPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] A blank Shopify ISO customer template falls back to the mapped BC country customer template.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A Shopify ISO code is mapped to a different Business Central country code.
        CreateCountryRegionMapping(CountryRegion, 'QW');
        //[GIVEN] The Shopify ISO row has no customer template.
        CreateShopifyCustomerTemplate('QW', '', '');
        //[GIVEN] A customer template is created for the mapped country.
        MappedTemplateCode := CreateCustomerTemplate(InitializedShop, MappedPaymentTermsCode);
        //[GIVEN] The mapped-country row is configured with that customer template.
        CreateShopifyCustomerTemplate(CountryRegion.Code, MappedTemplateCode, '');
        //[GIVEN] The test shop is copied for this selection.
        TestShop := InitializedShop;
        //[GIVEN] The test shop has no company template that could take precedence.
        TestShop."Company Templ. Code" := '';
        //[GIVEN] The Shopify ISO row is retrieved.
        ShopifyCustomerTemplate.Get(InitializedShop.Code, 'QW');
        //[GIVEN] The Shopify ISO row has no customer template.
        LibraryAssert.AreEqual('', ShopifyCustomerTemplate."Customer Templ. Code", 'The Shopify ISO row should have no customer template.');

        //[WHEN] A B2B customer is created from the Shopify ISO country.
        Customer := CreateCustomerFromCompany(TestShop, 'QW', '');

        //[THEN] The mapped BC country customer template is applied.
        LibraryAssert.AreEqual(MappedPaymentTermsCode, Customer."Payment Terms Code", 'The mapped-country customer template should be selected.');
    end;

    [Test]
    procedure UnitTestCompanyTemplateFieldsDefaultBlank()
    var
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
    begin
        //[SCENARIO] New shops and country-template rows have no company template configured by default.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A new country-template row is created without setting its company template.
        CreateShopifyCustomerTemplate('QV', '', '');

        //[WHEN] The new country-template row is retrieved.
        ShopifyCustomerTemplate.Get(InitializedShop.Code, 'QV');

        //[THEN] The new shop company template is blank.
        LibraryAssert.AreEqual('', InitializedShop."Company Templ. Code", 'A new shop should have no company template by default.');
        //[THEN] The new country-template company template is blank.
        LibraryAssert.AreEqual('', ShopifyCustomerTemplate."Company Templ. Code", 'A new country-template row should have no company template by default.');
    end;

    [Test]
    [HandlerFunctions('SyncCountriesHttpHandler')]
    procedure UnitTestSyncCountriesPreservesCountryTemplateCodes()
    var
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
        SyncCountries: Codeunit "Shpfy Sync Countries";
        CustomerTemplateCode: Code[20];
        CompanyTemplateCode: Code[20];
        CustomerPaymentTermsCode: Code[10];
        CompanyPaymentTermsCode: Code[10];
    begin
        //[SCENARIO] Synchronizing Shopify countries preserves existing customer and company template codes.

        //[GIVEN] Random test data uses a stable seed.
        //[GIVEN] The shop and posting setup are created.
        //[GIVEN] An access token is registered for the shop.
        //[GIVEN] The initialized shop setup is committed.
        Initialize();

        //[GIVEN] A customer template is created for the US country row.
        CustomerTemplateCode := CreateCustomerTemplate(InitializedShop, CustomerPaymentTermsCode);
        //[GIVEN] A distinct company template is created for the US country row.
        CompanyTemplateCode := CreateCustomerTemplate(InitializedShop, CompanyPaymentTermsCode);
        //[GIVEN] The US country row is configured with both template codes.
        CreateShopifyCustomerTemplate('US', CustomerTemplateCode, CompanyTemplateCode);

        //[WHEN] The shop's country synchronization runs.
        SyncCountries.Run(InitializedShop);

        //[THEN] The existing country-template row can still be found.
        ShopifyCustomerTemplate.Get(InitializedShop.Code, 'US');
        //[THEN] The customer template code is preserved.
        LibraryAssert.AreEqual(CustomerTemplateCode, ShopifyCustomerTemplate."Customer Templ. Code", 'Country synchronization should preserve the customer template.');
        //[THEN] The company template code is preserved.
        LibraryAssert.AreEqual(CompanyTemplateCode, ShopifyCustomerTemplate."Company Templ. Code", 'Country synchronization should preserve the company template.');
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        IsInitialized := true;
        InitializeTest.EnsureCustomerNoSeries();
        InitializedShop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(InitializedShop.GetStoreName(), AccessToken);
        Commit();
    end;

    local procedure CreateCountryRegionMapping(var CountryRegion: Record "Country/Region"; ISOCode: Code[2])
    begin
        CountryRegion.Code := LibraryERM.CreateCountryRegion();
        CountryRegion.Get(CountryRegion.Code);
        CountryRegion."ISO Code" := ISOCode;
        CountryRegion.Modify(false);
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


    local procedure CreateShopifyCustomerTemplate(CountryCode: Code[20]; CustomerTemplateCode: Code[20]; CompanyTemplateCode: Code[20])
    begin
        InitializeTest.SetShopifyCustomerTemplate(InitializedShop.Code, CountryCode, CustomerTemplateCode, CompanyTemplateCode);
    end;

    local procedure CreateCustomerFromCompany(ShopifyShop: Record "Shpfy Shop"; ShopifyCountryCode: Code[2]; ExplicitTemplateCode: Code[20]) Customer: Record Customer
    var
        TempShopifyCustomer: Record "Shpfy Customer" temporary;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        CreateCustomer: Codeunit "Shpfy Create Customer";
        EmptyGuid: Guid;
    begin
        InitializeTest.EnsureCountryRegion(ShopifyCountryCode);
        CreateCompany(ShopifyCompany, EmptyGuid);
        CreateCompanyLocation(CompanyLocation, ShopifyCompany, 0);
        CompanyLocation."Country/Region Code" := ShopifyCountryCode;
        CompanyLocation.Modify(false);
        CreateTempShopifyCustomer(TempShopifyCustomer);

        CreateCustomer.SetShop(ShopifyShop);
        if ExplicitTemplateCode <> '' then
            CreateCustomer.SetTemplateCode(ExplicitTemplateCode);
        CreateCustomer.CreateCustomerFromCompany(ShopifyCompany, TempShopifyCustomer);
        Customer.GetBySystemId(ShopifyCompany."Customer SystemId");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := CopyStr(Any.AlphanumericText(10), 1, MaxStrLen(PaymentTerms.Code));
        PaymentTerms.Insert(false);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateShopifyPaymentTerms(PaymentTermsCode: Code[10]): BigInteger
    var
        ShopifyPaymentTerms: Record "Shpfy Payment Terms";
    begin
        ShopifyPaymentTerms.Init();
        ShopifyPaymentTerms.Id := Any.IntegerInRange(10000, 99999);
        ShopifyPaymentTerms."Payment Terms Code" := PaymentTermsCode;
        ShopifyPaymentTerms.Insert(false);
        exit(ShopifyPaymentTerms.Id);
    end;

    local procedure CreateCustomerWithPaymentTerms(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        Customer.Init();
        Customer."No." := CopyStr(Any.AlphanumericText(20), 1, MaxStrLen(Customer."No."));
        Customer."Payment Terms Code" := PaymentTermsCode;
        Customer.Insert(false);
    end;

    local procedure CreateCompany(var ShopifyCompany: Record "Shpfy Company"; CustomerSystemId: Guid)
    begin
        ShopifyCompany.Init();
        ShopifyCompany.Id := Any.IntegerInRange(10000, 99999);
        ShopifyCompany."Customer SystemId" := CustomerSystemId;
        ShopifyCompany."Shop Id" := InitializedShop."Shop Id";
        ShopifyCompany.Insert(false);
    end;

    local procedure CreateCompanyLocation(var CompanyLocation: Record "Shpfy Company Location"; var ShopifyCompany: Record "Shpfy Company"; PaymentTermsId: BigInteger)
    begin
        CompanyLocation.Init();
        CompanyLocation."Company SystemId" := ShopifyCompany.SystemId;
        CompanyLocation.Id := Any.IntegerInRange(10000, 99999);
        CompanyLocation."Shpfy Payment Terms Id" := PaymentTermsId;
        CompanyLocation.Insert(false);

        ShopifyCompany."Location Id" := CompanyLocation.Id;
        ShopifyCompany.Modify(false);
    end;

    local procedure CreateCompanyLocationWithTaxId(var CompanyLocation: Record "Shpfy Company Location"; var ShopifyCompany: Record "Shpfy Company"; TaxRegistrationId: Text[150])
    begin
        CompanyLocation.Init();
        CompanyLocation."Company SystemId" := ShopifyCompany.SystemId;
        CompanyLocation.Id := Any.IntegerInRange(10000, 99999);
        CompanyLocation."Tax Registration Id" := TaxRegistrationId;
        CompanyLocation.Insert(false);

        ShopifyCompany."Location Id" := CompanyLocation.Id;
        ShopifyCompany.Modify(false);
    end;

    local procedure CreateTempShopifyCustomer(var TempShopifyCustomer: Record "Shpfy Customer" temporary)
    begin
        TempShopifyCustomer.Init();
        TempShopifyCustomer.Id := Any.IntegerInRange(10000, 99999);
        TempShopifyCustomer.Insert(false);
    end;

    local procedure InvokeCompanyImport(var ShopifyCompany: Record "Shpfy Company")
    var
        CompanyImport: Codeunit "Shpfy Company Import";
    begin
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetCompany');
        OutboundHttpRequests.Enqueue('GetLocations');
        CompanyImport.SetShop(InitializedShop);
        ShopifyCompany.SetRange("Id", ShopifyCompany.Id);
        CompanyImport.Run(ShopifyCompany);
    end;

    local procedure VerifyShopifyCompanyLocationValues(var ShopifyCompany: Record "Shpfy Company"; LocValues: Dictionary of [Text, Text])
    var
        CompanyLocation: Record "Shpfy Company Location";
        Id, PaymentTermsId : BigInteger;
    begin
        Evaluate(Id, LocValues.Get('id'));
        Evaluate(PaymentTermsId, LocValues.Get('paymentTermsTemplateId'));
        CompanyLocation.SetRange("Company SystemId", ShopifyCompany.SystemId);
        LibraryAssert.IsTrue(CompanyLocation.FindFirst(), 'Company location does not exist');
        LibraryAssert.AreEqual(Id, CompanyLocation.Id, 'Id not imported');
        LibraryAssert.AreEqual(LocValues.Get('address1'), CompanyLocation.Address, 'Address not imported');
        LibraryAssert.AreEqual(LocValues.Get('address2'), CompanyLocation."Address 2", 'Address 2 not imported');
        LibraryAssert.AreEqual(LocValues.Get('phone'), CompanyLocation."Phone No.", 'Phone No. not imported');
        LibraryAssert.AreEqual(LocValues.Get('zip'), CompanyLocation.Zip, 'Zip not imported');
        LibraryAssert.AreEqual(LocValues.Get('city'), CompanyLocation.City, 'City not imported');
        LibraryAssert.AreEqual(LocValues.Get('countryCode').ToUpper(), CompanyLocation."Country/Region Code", 'Country/Region Code not imported');
        LibraryAssert.AreEqual(LocValues.Get('zoneCode').ToUpper(), CompanyLocation."Province Code", 'Province Code not imported');
        LibraryAssert.AreEqual(LocValues.Get('province'), CompanyLocation."Province Name", 'Province Name not imported');
        LibraryAssert.AreEqual(PaymentTermsId, CompanyLocation."Shpfy Payment Terms Id", 'Payment Terms Id not imported');
        LibraryAssert.AreEqual(LocValues.Get('taxRegistrationId'), CompanyLocation."Tax Registration Id", 'Tax Registration id not imported');
    end;

    local procedure CreateLocationValues(var LocValues: Dictionary of [Text, Text])
    begin
        Clear(LocValues);
        LocValues.Add('id', Format(Any.IntegerInRange(10000, 99999)));
        LocValues.Add('address1', Any.AlphanumericText(20));
        LocValues.Add('address2', Any.AlphanumericText(20));
        LocValues.Add('phone', Format(Any.IntegerInRange(1000, 9999)));
        LocValues.Add('zip', Format(Any.IntegerInRange(1000, 9999)));
        LocValues.Add('city', Any.AlphanumericText(20));
        LocValues.Add('countryCode', Any.AlphanumericText(2));
        LocValues.Add('zoneCode', Any.AlphanumericText(2));
        LocValues.Add('province', Any.AlphanumericText(20));
        LocValues.Add('paymentTermsTemplateId', Format(Any.IntegerInRange(10000, 99999)));
        LocValues.Add('taxRegistrationId', Any.AlphanumericText(50));
    end;

    [HttpClientHandler]
    internal procedure CompanyImportHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        CompanyInitialize: Codeunit "Shpfy Company Initialize";
        RequestType: Text;
        ResponseBody: Text;
        CompanyResponseLbl: Label '{ "data": { "company" :{ "mainContact" : {}, "updatedAt" : "%1" } }}', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, InitializedShop."Shopify URL") then
            exit(true);
        if OutboundHttpRequests.Length() = 0 then
            exit(true);

        RequestType := OutboundHttpRequests.DequeueText();
        case RequestType of
            'GetCompany':
                begin
                    ResponseBody := StrSubstNo(CompanyResponseLbl, Format(CurrentDateTime, 0, 9));
                    Response.Content.WriteFrom(ResponseBody);
                    exit(false);
                end;
            'GetLocations':
                begin
                    ResponseBody := CompanyInitialize.CreateLocationResponse(LocationValues);
                    Response.Content.WriteFrom(ResponseBody);
                    exit(false);
                end;
        end;

        exit(true);
    end;

    [HttpClientHandler]
    internal procedure SyncCountriesHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        CountriesResponseLbl: Label '{"data":{"shop":{"shipsToCountries":["US"]}}}', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, InitializedShop."Shopify URL") then
            exit(true);

        Response.Content.WriteFrom(CountriesResponseLbl);
        exit(false);
    end;
}
