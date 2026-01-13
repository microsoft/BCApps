// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139636 "Shpfy Company Export Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        CompanyExport: Codeunit "Shpfy Company Export";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerData()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        ShopifyShop: Record "Shpfy Shop";
        Result: Boolean;
        ShopifyPaymentTermsId: BigInteger;
        ExpectedCountryCode: Code[10];
    begin
        // [SCENARIO] Convert an existing company record to a "Shpfy Company" and "Shpfy Company Location" record.

        // [GIVEN] Customer record
        Customer.FindFirst();

        // [GIVEN] Ensure the customer's country has an ISO code set
        if CountryRegion.Get(Customer."Country/Region Code") then begin
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := CopyStr(Customer."Country/Region Code", 1, MaxStrLen(CountryRegion."ISO Code"));
                CountryRegion.Modify();
            end;
            ExpectedCountryCode := CountryRegion."ISO Code";
        end else
            ExpectedCountryCode := CopyStr(Customer."Country/Region Code", 1, MaxStrLen(ExpectedCountryCode));

        ShopifyShop := InitializeTest.CreateShop();
        ShopifyShop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        ShopifyShop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."Contact Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyShop."B2B Enabled" := true;
        ShopifyCompany.Init();
        CompanyLocation.Init();
        ShopifyPaymentTermsId := 0;

        // [GIVEN] Shop
        CompanyExport.SetShop(ShopifyShop);

        // [WHEN] Invoke ShpfyCustomerExport.FillInShopifyCompany(Customer, ShopifyCompany) and ShpfyCustomerExport.FillInShopifyCompanyLocation(Customer, CompanyLocation)
        Result := CompanyExport.FillInShopifyCompany(Customer, ShopifyCompany) and
                  CompanyExport.FillInShopifyCompanyLocation(Customer, CompanyLocation);

        // [THEN] The result is true and the content of address fields can be found in the shpfy records.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.AreEqual(Customer.Name, ShopifyCompany.Name, 'Name');
        LibraryAssert.AreEqual(Customer."Phone No.", CompanyLocation."Phone No.", 'Phone No.');
        LibraryAssert.AreEqual(Customer.Address, CompanyLocation.Address, 'Address 1');
        LibraryAssert.AreEqual(Customer."Address 2", CompanyLocation."Address 2", 'Address 2');
        LibraryAssert.AreEqual(Customer."Post Code", CompanyLocation.Zip, 'Post Code');
        LibraryAssert.AreEqual(Customer.City, CompanyLocation.City, 'City');
        LibraryAssert.AreEqual(ExpectedCountryCode, CompanyLocation."Country/Region Code", 'Country should be ISO code');
        LibraryAssert.AreEqual(Customer.Name, CompanyLocation.Recipient, 'Recipient');
        LibraryAssert.AreEqual(ShopifyPaymentTermsId, CompanyLocation."Shpfy Payment Terms Id", 'Payment Terms Id should be 0');
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerDataWithLocationPaymentTerm()
    var
        Customer: Record Customer;
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        PaymentTermsCode: Code[10];
        ShopifyPaymentTermsId: BigInteger;
    begin
        // [SCENARIO] Export company with payment terms.
        Initialize();

        // [GIVEN] Payment terms
        PaymentTermsCode := CreatePaymentTerms();
        // [GIVEN] Shopify payment terms
        ShopifyPaymentTermsId := CreateShopifyPaymentTerms(PaymentTermsCode);
        // [GIVEN] Customer record with payment terms
        CreateCustomer(Customer, PaymentTermsCode);
        // [GIVEN] Shopify Company 
        CreateCompany(ShopifyCompany, Customer.SystemId);
        // [GIVEN] Company Location
        CreateCompanyLocation(CompanyLocation, ShopifyCompany.SystemId, ShopifyPaymentTermsId);

        // [WHEN] Invoke FillInShopifyCompany and FillInShopifyCompanyLocation
        CompanyExport.FillInShopifyCompany(Customer, ShopifyCompany);
        CompanyExport.FillInShopifyCompanyLocation(Customer, CompanyLocation);

        // [THEN] The payment terms id is set in the company location record.
        LibraryAssert.AreEqual(ShopifyPaymentTermsId, CompanyLocation."Shpfy Payment Terms Id", 'Payment Terms Id');
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerDataCounty()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        CompanyLocation: Record "Shpfy Company Location";
        ShopifyShop: Record "Shpfy Shop";
        TaxArea: Record "Shpfy Tax Area";
        Result: Boolean;
    begin
        // [SCENARIO] County information is only sent to Shopify if the country has any provinces

        // [GIVEN] Customer record with country code 'US' that has ISO code 'US'
        Customer.FindFirst();
        Customer."Country/Region Code" := 'US';
        Customer."County" := 'CA';
        Customer.Modify();

        // Ensure the US country has ISO code set
        if not CountryRegion.Get('US') then begin
            CountryRegion.Init();
            CountryRegion.Code := 'US';
            CountryRegion."ISO Code" := 'US';
            CountryRegion.Insert();
        end else begin
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := 'US';
                CountryRegion.Modify();
            end;
        end;

        TaxArea."Country/Region Code" := 'US';
        TaxArea.County := 'CA';
        TaxArea."County Code" := 'CA';
        if not TaxArea.Insert() then
            TaxArea.Modify();

        ShopifyShop := InitializeTest.CreateShop();
        ShopifyShop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        ShopifyShop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."Contact Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyShop."B2B Enabled" := true;
        CompanyLocation.Init();

        // [GIVEN] Shop
        CompanyExport.SetShop(ShopifyShop);

        // [GIVEN] Customer record
        // [WHEN] Invoke ShpfyCustomerExport.FillInShopifyCompanyLocation(Customer, CompanyLocation)
        Result := CompanyExport.FillInShopifyCompanyLocation(Customer, CompanyLocation);

        // [THEN] The result is true and the content of address fields can be found in the shpfy records.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.IsTrue(CompanyLocation."Province Code" <> '', 'Province Code');
        LibraryAssert.IsTrue(CompanyLocation."Province Name" <> '', 'Province Name');

        // [WHEN] Change the county to a country without provinces
        Customer."Country/Region Code" := 'DE';
        Customer.Modify();

        // Ensure the DE country has ISO code set
        if not CountryRegion.Get('DE') then begin
            CountryRegion.Init();
            CountryRegion.Code := 'DE';
            CountryRegion."ISO Code" := 'DE';
            CountryRegion.Insert();
        end else begin
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := 'DE';
                CountryRegion.Modify();
            end;
        end;

        Clear(CompanyLocation);
        Result := CompanyExport.FillInShopifyCompanyLocation(Customer, CompanyLocation);

        // [THEN] The result is true and the province fields are empty.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.IsTrue(CompanyLocation."Province Code" = '', 'Province Code');
        LibraryAssert.IsTrue(CompanyLocation."Province Name" = '', 'Province Name');
    end;

    [Test]
    procedure UnitTestFillInShopifyCompanyLocationISOCountryCodeMapping()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        CompanyLocation: Record "Shpfy Company Location";
        ShopifyShop: Record "Shpfy Shop";
        TaxArea: Record "Shpfy Tax Area";
        Result: Boolean;
        BCCountryCode: Code[10];
        ISOCountryCode: Code[10];
    begin
        // [SCENARIO] When BC uses a different country code than the ISO standard (e.g., "EL" for Greece instead of "GR"),
        // the Shopify connector should correctly map to the ISO code for Shopify API and Tax Area lookups.

        // [GIVEN] A country with BC code "EL" and ISO code "GR" (like Greece in EU/VIES context)
        BCCountryCode := 'EL';
        ISOCountryCode := 'GR';

        if not CountryRegion.Get(BCCountryCode) then begin
            CountryRegion.Init();
            CountryRegion.Code := BCCountryCode;
            CountryRegion.Name := 'Greece';
            CountryRegion."ISO Code" := ISOCountryCode;
            CountryRegion.Insert();
        end else begin
            CountryRegion."ISO Code" := ISOCountryCode;
            CountryRegion.Modify();
        end;

        // [GIVEN] A Tax Area with country code "GR" (Shopify's ISO code) and province info
        TaxArea.Init();
        TaxArea."Country/Region Code" := ISOCountryCode;
        TaxArea.County := 'Attica';
        TaxArea."County Code" := 'I';
        if not TaxArea.Insert() then
            TaxArea.Modify();

        // [GIVEN] A customer with country code "EL" (BC code) and matching county
        Customer.FindFirst();
        Customer."Country/Region Code" := BCCountryCode;
        Customer.County := 'Attica';
        Customer.Modify();

        // [GIVEN] Shop with County Source = Name
        ShopifyShop := InitializeTest.CreateShop();
        ShopifyShop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        ShopifyShop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."Contact Source" := Enum::"Shpfy Name Source"::None;
        ShopifyShop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyShop."B2B Enabled" := true;
        CompanyLocation.Init();

        CompanyExport.SetShop(ShopifyShop);

        // [WHEN] Invoke FillInShopifyCompanyLocation
        Result := CompanyExport.FillInShopifyCompanyLocation(Customer, CompanyLocation);

        // [THEN] The result is true
        LibraryAssert.IsTrue(Result, 'Result should be true');

        // [THEN] The country code is mapped to the ISO code "GR" (not the BC code "EL")
        LibraryAssert.AreEqual(ISOCountryCode, CompanyLocation."Country/Region Code", 'Country/Region Code should be ISO code GR, not BC code EL');

        // [THEN] The province information is correctly retrieved using the ISO country code
        LibraryAssert.AreEqual('I', CompanyLocation."Province Code", 'Province Code should be found using ISO country code');
        LibraryAssert.AreEqual('Attica', CompanyLocation."Province Name", 'Province Name should be found using ISO country code');

        // Cleanup
        TaxArea.Delete();
    end;


    local procedure Initialize()
    begin
        Any.SetDefaultSeed();

        if IsInitialized then
            exit;
        Shop := InitializeTest.CreateShop();

        IsInitialized := true;

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

    local procedure CreateCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10])
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
        ShopifyCompany.Insert(false);
    end;

    local procedure CreateCompanyLocation(var CompanyLocation: Record "Shpfy Company Location"; ShopifyCompanySystemId: Guid; PaymentTermsId: BigInteger)
    begin
        CompanyLocation.Init();
        CompanyLocation."Company SystemId" := ShopifyCompanySystemId;
        CompanyLocation.Id := Any.IntegerInRange(10000, 99999);
        CompanyLocation."Shpfy Payment Terms Id" := PaymentTermsId;
        CompanyLocation.Insert(false);
    end;
}
