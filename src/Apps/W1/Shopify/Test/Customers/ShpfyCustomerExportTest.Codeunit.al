// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Foundation.Address;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139568 "Shpfy Customer Export Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        CustomerExport: Codeunit "Shpfy Customer Export";
        Any: Codeunit Any;

    [Test]
    procedure UnitTestSpiltNameIntoFirstAndLastName()
    var
        Name: Text;
        FirstName: Text[100];
        LastName: Text[100];
        NameSource: Enum "Shpfy Name Source";
    begin
        // [SCENARIO] Splitting a full name into first name and last name.
        // [GIVEN] Name := 'Firstname Last name'
        Name := 'Firstname Last name';
        // [GIVEN] NameSource::FirstAndLastName

        // [WHEN] Invoke ShpfyCustomerExport.SpiltNameIntoFirstAndLastName(Name, FirstName, LastName, NameSource::FirstAndLastName)
        CustomerExport.SpiltNameIntoFirstAndLastName(Name, FirstName, LastName, NameSource::FirstAndLastName);

        // [THEN] FirstName = 'Firstname' and LastName = 'Last name'
        LibraryAssert.AreEqual('Firstname', FirstName, 'NameSource::FirstAndLastName');
        LibraryAssert.AreEqual('Last name', LastName, 'NameSource::FirstAndLastName');

        // [GIVEN] Name := 'Last name Firstname'
        Name := 'Last name Firstname';
        // [GIVEN] NameSource::LastAndFirstName

        // [WHEN] Invoke ShpfyCustomerExport.SpiltNameIntoFirstAndLastName(Name, FirstName, LastName, NameSource::LastAndFirstName)
        CustomerExport.SpiltNameIntoFirstAndLastName(Name, FirstName, LastName, NameSource::LastAndFirstName);

        // [THEN] FirstName = 'Firstname' and LastName = 'Last name'
        LibraryAssert.AreEqual('Firstname', FirstName, 'NameSource::LastAndFirstName');
        LibraryAssert.AreEqual('Last name', LastName, 'NameSource::LastAndFirstName');
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerData()
    var
        Customer: Record Customer;
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        Shop: Record "Shpfy Shop";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        Result: boolean;
    begin
        // [SCENARIO] Convert an existing customer record to a "Shpfy Customer" and "Shpfy Customer Address" record.

        // [GIVEN] Customer record
        Customer.FindFirst();
        Shop := InitializeTest.CreateShop();
        Shop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        Shop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        Shop."Contact Source" := Enum::"Shpfy Name Source"::None;
        Shop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyCustomer.Init();
        CustomerAddress.Init();

        // [GIVEN] Shop
        CustomerExport.SetShop(Shop);

        // [WHEN] Invoke ShpfyCustomerExport.FillInShopifyCustomerData(Customer, ShpfyCustomer, ShpfyCustomerAddres)
        Result := CustomerExport.FillInShopifyCustomerData(Customer, ShopifyCustomer, CustomerAddress);

        // [THEN] The result is true and the content of address fields can be found in the shpfy records.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.AreEqual('', ShopifyCustomer."First Name", 'Firstname');
        LibraryAssert.AreEqual('', ShopifyCustomer."Last Name", 'Last name');
        LibraryAssert.IsTrue(Customer."E-Mail".StartsWith(ShopifyCustomer.Email), 'E-Mail');
        LibraryAssert.AreEqual(Customer."Phone No.", ShopifyCustomer."Phone No.", 'Phone No.');
        LibraryAssert.AreEqual(Customer.Name, CustomerAddress.Company, 'Company');
        LibraryAssert.AreEqual(Customer.Address, CustomerAddress."Address 1", 'Address 1');
        LibraryAssert.AreEqual(Customer."Address 2", CustomerAddress."Address 2", 'Address 2');
        LibraryAssert.AreEqual(Customer."Post Code", CustomerAddress.Zip, 'Post Code');
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerDataCounty()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        Shop: Record "Shpfy Shop";
        TaxArea: Record "Shpfy Tax Area";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        Result: boolean;
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

        Shop := InitializeTest.CreateShop();
        Shop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        Shop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        Shop."Contact Source" := Enum::"Shpfy Name Source"::None;
        Shop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyCustomer.Init();
        CustomerAddress.Init();

        // [GIVEN] Shop
        CustomerExport.SetShop(Shop);

        // [WHEN] Invoke ShpfyCustomerExport.FillInShopifyCustomerData(Customer, ShpfyCustomer, ShpfyCustomerAddres)
        Result := CustomerExport.FillInShopifyCustomerData(Customer, ShopifyCustomer, CustomerAddress);

        // [THEN] The result is true and the content of address fields can be found in the shpfy records.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.IsTrue(CustomerAddress."Province Code" <> '', 'Province Code');
        LibraryAssert.IsTrue(CustomerAddress."Province Name" <> '', 'Province Name');

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

        Clear(CustomerAddress);
        Clear(ShopifyCustomer);
        Result := CustomerExport.FillInShopifyCustomerData(Customer, ShopifyCustomer, CustomerAddress);

        // [THEN] The result is true and the province fields are empty.
        LibraryAssert.IsTrue(Result, 'Result');
        LibraryAssert.IsTrue(CustomerAddress."Province Code" = '', 'Province Code');
        LibraryAssert.IsTrue(CustomerAddress."Province Name" = '', 'Province Name');
    end;

    [Test]
    procedure UnitTestFillInShopifyCustomerDataISOCountryCodeMapping()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        Shop: Record "Shpfy Shop";
        TaxArea: Record "Shpfy Tax Area";
        InitializeTest: Codeunit "Shpfy Initialize Test";
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
        Shop := InitializeTest.CreateShop();
        Shop."Name Source" := Enum::"Shpfy Name Source"::CompanyName;
        Shop."Name 2 Source" := Enum::"Shpfy Name Source"::None;
        Shop."Contact Source" := Enum::"Shpfy Name Source"::None;
        Shop."County Source" := Enum::"Shpfy County Source"::Name;
        ShopifyCustomer.Init();
        CustomerAddress.Init();

        CustomerExport.SetShop(Shop);

        // [WHEN] Invoke FillInShopifyCustomerData
        Result := CustomerExport.FillInShopifyCustomerData(Customer, ShopifyCustomer, CustomerAddress);

        // [THEN] The result is true
        LibraryAssert.IsTrue(Result, 'Result should be true');

        // [THEN] The country code is mapped to the ISO code "GR" (not the BC code "EL")
        LibraryAssert.AreEqual(ISOCountryCode, CustomerAddress."Country/Region Code", 'Country/Region Code should be ISO code GR, not BC code EL');

        // [THEN] The province information is correctly retrieved using the ISO country code
        LibraryAssert.AreEqual('I', CustomerAddress."Province Code", 'Province Code should be found using ISO country code');
        LibraryAssert.AreEqual('Attica', CustomerAddress."Province Name", 'Province Name should be found using ISO country code');

        // Cleanup
        TaxArea.Delete();
    end;
}
