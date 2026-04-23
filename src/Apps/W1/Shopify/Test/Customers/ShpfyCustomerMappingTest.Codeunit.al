// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Customer Mapping Test (ID 139569).
/// </summary>
codeunit 139569 "Shpfy Customer Mapping Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var

        LibraryAssert: Codeunit "Library Assert";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";

    [Test]
    procedure TestCustomerMapping()
    var
        Customer: Record Customer;
        Shop: Record "Shpfy Shop";
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerId: BigInteger;
        ResultCode: Code[20];
        ShopCode: Code[20];
        ICustomerMapping: Interface "Shpfy ICustomer Mapping";
        JCustomerInfo: JsonObject;
    begin
        Init(Customer);

        // Creating Test data.
        JCustomerInfo := CreateJsonCustomerInfo();
        Shop := CommunicationMgt.GetShopRecord();
        ShopCode := Shop.Code;

        CustomerId := CreateShopifyCustomer(Customer, ShopifyCustomer);
        CreateShopifyCustomerAddress(Customer, ShopifyCustomer);

        // [SCENARIO] Map the received customer data to an existing customer.

        // [GIVEN] CustomerId
        // [GIVEN] JCustomerInfo
        // [GIVEN] ShopCode

        // [WHEN] ICustomerMapping = "Shpfy Customer Mapping"::DefaultCustomer
        ICustomerMapping := "Shpfy Customer Mapping"::DefaultCustomer;
        // [THEN] Shop."Default Customer" = ResultCode
        ResultCode := ICustomerMapping.DoMapping(CustomerId, JCustomerInfo, ShopCode);
        LibraryAssert.AreEqual(Shop."Default Customer No.", ResultCode, 'Mapping to Default Customer');

        // [WHEN] ICustomerMapping = "Shpfy Customer Mapping"::"By EMail/Phone"
        ICustomerMapping := "Shpfy Customer Mapping"::"By EMail/Phone";
        // [THEN] Customer."No."" = ResultCode
        ResultCode := ICustomerMapping.DoMapping(CustomerId, JCustomerInfo, ShopCode);
        LibraryAssert.AreEqual(Customer."No.", ResultCode, 'Mapping By EMail/Phone');

        // [WHEN] ICustomerMapping = "Shpfy Customer Mapping"::"By Bill-to Info"
        ICustomerMapping := "Shpfy Customer Mapping"::"By Bill-to Info";
        // [THEN] Customer."No."" = ResultCode
        ResultCode := ICustomerMapping.DoMapping(CustomerId, JCustomerInfo, ShopCode);
        LibraryAssert.AreEqual(Customer."No.", ResultCode, 'Mapping By Bill-to Info');
    end;

    [Test]
    procedure TestFindMappingRespectsCustomerFilters()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerMapping: Codeunit "Shpfy Customer Mapping";
        FilterSub: Codeunit "Shpfy Cust. Mapping Filter Sub";
        SharedEmail: Text[80];
    begin
        // [SCENARIO] FindMapping respects Customer filters applied via OnBeforeFindMapping
        Init(Customer1);
        SharedEmail := 'filtertest@domain.com';

        // [GIVEN] Two customers sharing the same email address
        Customer1.Init();
        Customer1."No." := 'SHPFY-F-01';
        Customer1."E-Mail" := SharedEmail;
        Customer1.Insert(false);

        Customer2.Init();
        Customer2."No." := 'SHPFY-F-02';
        Customer2."E-Mail" := SharedEmail;
        Customer2.Insert(false);

        // [GIVEN] A Shopify customer whose email matches both BC customers
        ShopifyCustomer.DeleteAll();
        ShopifyCustomer.Init();
        ShopifyCustomer.Id := 99700;
        ShopifyCustomer.Email := SharedEmail;
        ShopifyCustomer.Insert();

        // [GIVEN] A subscriber that restricts the Customer view to Customer2 only
        FilterSub.SetCustomerNoFilter(Customer2."No.");
        BindSubscription(FilterSub);

        // [WHEN] FindMapping is executed
        CustomerMapping.FindMapping(ShopifyCustomer);
        UnbindSubscription(FilterSub);

        // [THEN] The Shopify customer is mapped to Customer2, not Customer1
        LibraryAssert.AreEqual(
            Customer2.SystemId,
            ShopifyCustomer."Customer SystemId",
            'FindMapping must honour the Customer filters set via OnBeforeFindMapping.');
    end;

    [Test]
    procedure TestFindMappingRespectsPhoneFilter()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerMapping: Codeunit "Shpfy Customer Mapping";
        FilterSub: Codeunit "Shpfy Cust. Mapping Filter Sub";
    begin
        // [SCENARIO] FindMapping phone-number path also respects Customer filters
        Init(Customer1);

        // [GIVEN] Two customers sharing the same phone number
        Customer1.Init();
        Customer1."No." := 'SHPFY-P-01';
        Customer1."Phone No." := '123456789';
        Customer1.Insert(false);

        Customer2.Init();
        Customer2."No." := 'SHPFY-P-02';
        Customer2."Phone No." := '123456789';
        Customer2.Insert(false);

        // [GIVEN] A Shopify customer whose phone matches both BC customers (no email)
        ShopifyCustomer.DeleteAll();
        ShopifyCustomer.Init();
        ShopifyCustomer.Id := 99701;
        ShopifyCustomer."Phone No." := '+1 234 56789';
        ShopifyCustomer.Insert();

        // [GIVEN] A subscriber that restricts the Customer view to Customer2 only
        FilterSub.SetCustomerNoFilter(Customer2."No.");
        BindSubscription(FilterSub);

        // [WHEN] FindMapping is executed
        CustomerMapping.FindMapping(ShopifyCustomer);
        UnbindSubscription(FilterSub);

        // [THEN] The Shopify customer is mapped to Customer2, not Customer1
        LibraryAssert.AreEqual(
            Customer2.SystemId,
            ShopifyCustomer."Customer SystemId",
            'FindMapping phone path must honour the Customer filters set via OnBeforeFindMapping.');
    end;


    local procedure CreateShopifyCustomerAddress(var Customer: Record Customer; var ShopifyCustomer: Record "Shpfy Customer")
    var
        CustomerAddress: Record "Shpfy Customer Address";
    begin
        CustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);

        CustomerAddress.CustomerSystemId := Customer.SystemId;
        CustomerAddress.Modify();
    end;

    local procedure CreateShopifyCustomer(var Customer: Record Customer; var ShopifyCustomer: Record "Shpfy Customer"): BigInteger
    var
        CustomerId: BigInteger;
    begin
        Customer.Init();
        Customer."No." := 'YYYY';
        Customer.Insert(false);

        CustomerId := CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer.Modify();
        ShopifyCustomer.CalcFields("Customer No.");
        exit(CustomerId);
    end;

    local procedure CreateJsonCustomerInfo(): JsonObject
    var
        Shop: Record "Shpfy Shop";
    begin

        Shop := CommunicationMgt.GetShopRecord();
        exit(CustomerInitTest.CreateJsonCustomerInfo(Shop."Name Source", Shop."Name 2 Source"));
    end;

    local procedure Init(var Customer: Record Customer)
    var
        Shop: Record "Shpfy Shop";
    begin
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();
        if Shop."Default Customer No." = '' then begin
            if Customer.FindFirst() then
                Shop."Default Customer No." := Customer."No."
            else
                Shop."Default Customer No." := 'XXXX';
            Shop."Name Source" := "Shpfy Name Source"::CompanyName;
            Shop."Name 2 Source" := "Shpfy Name Source"::FirstAndLastName;
            if not Shop.Modify(false) then
                Shop.Insert();
            CommunicationMgt.SetShop(Shop);
        end;
    end;
}
