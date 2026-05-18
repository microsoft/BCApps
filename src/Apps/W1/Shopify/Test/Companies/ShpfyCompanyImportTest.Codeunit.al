// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

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

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        Any: Codeunit Any;
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        LocationValues: Dictionary of [Text, Text];

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
        CreateCustomer.SetShop(Shop);
        CreateCustomer.SetTemplateCode(Shop."Customer Templ. Code");
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
        Shop."Shpfy Comp. Tax Id Mapping" := Enum::"Shpfy Comp. Tax Id Mapping"::"Registration No.";
        Shop.Modify(false);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company Location with Tax Registration Id
        CreateCompanyLocationWithTaxId(CompanyLocation, ShopifyCompany, TaxRegistrationId);
        // [GIVEN] TempShopifyCustomer
        CreateTempShopifyCustomer(TempShopifyCustomer);

        // [WHEN] Invoke CreateCustomerFromCompany
        CreateCustomer.SetShop(Shop);
        CreateCustomer.SetTemplateCode(Shop."Customer Templ. Code");
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
        Shop."Shpfy Comp. Tax Id Mapping" := Enum::"Shpfy Comp. Tax Id Mapping"::"VAT Registration No.";
        Shop.Modify(false);
        // [GIVEN] Shopify Company
        CreateCompany(ShopifyCompany, EmptyGuid);
        // [GIVEN] Company Location with Tax Registration Id
        CreateCompanyLocationWithTaxId(CompanyLocation, ShopifyCompany, TaxRegistrationId);
        // [GIVEN] TempShopifyCustomer
        CreateTempShopifyCustomer(TempShopifyCustomer);

        // [WHEN] Invoke CreateCustomerFromCompany
        CreateCustomer.SetShop(Shop);
        CreateCustomer.SetTemplateCode(Shop."Customer Templ. Code");
        CreateCustomer.CreateCustomerFromCompany(ShopifyCompany, TempShopifyCustomer);

        // [THEN] Customer record is created with the correct VAT Registration No.
        Customer.GetBySystemId(ShopifyCompany."Customer SystemId");
        LibraryAssert.AreEqual(TaxRegistrationId, Customer."VAT Registration No.", 'VAT Registration No.');
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Commit();
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
        ShopifyCompany."Shop Id" := Shop."Shop Id";
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
        CompanyImport.SetShop(Shop);
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
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
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
}
