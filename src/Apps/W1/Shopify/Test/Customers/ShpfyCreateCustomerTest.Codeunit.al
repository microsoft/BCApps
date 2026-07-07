// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

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

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        Shop."Name Source" := "Shpfy Name Source"::CompanyName;
        Shop."Name 2 Source" := "Shpfy Name Source"::FirstAndLastName;
        Shop.Modify(false);
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
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
