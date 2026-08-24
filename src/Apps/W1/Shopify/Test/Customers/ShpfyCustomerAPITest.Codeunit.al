// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Customer API Test (ID 139589).
/// </summary>
codeunit 139589 "Shpfy Customer API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        Any: Codeunit Any;
        ResponseContent: Text;
        IsInitialized: Boolean;
        CustomerSearchResponseTok: Label '{"data":{"customers":{"edges":[{"node":{"id":"gid://shopify/Customer/%1",%2}}]}},"extensions":{"cost":{"requestedQueryCost":4,"actualQueryCost":4,"throttleStatus":{"maximumAvailable":20000.0,"currentlyAvailable":19996,"restoreRate":1000.0}}}}', Locked = true;
        DefaultPhoneNumberNodeTok: Label '"defaultPhoneNumber":{"phoneNumber":"%1"}', Locked = true;
        DefaultEMailAddressNodeTok: Label '"defaultEmailAddress":{"emailAddress":"%1"}', Locked = true;

    [Test]
    procedure UnitTestCreateCustomerGraphQuery()
    var
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";
        GraphQL: Text;
    begin
        // Creating Test data.
        CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        CustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);

        // [SCENARIO] Creating the GrapghQL query to create a new customer in Shopify
        // [GIVEN] ShpfyCustomer
        // [GIVEN] ShpfyCustomerAddress

        // [WHEN] Invoke CustomerApi.CreateCustomerGraphQLQuery
        GraphQL := CustomerApi.CreateCustomerGraphQLQuery(ShopifyCustomer, CustomerAddress);

        // [THEN] CustomerInitTest.CreateCustomerGraphQLResult() = GraphQL.
        LibraryAssert.AreEqual(CustomerInitTest.CreateCustomerGraphQLResult(), GraphQL, 'CreateCustomerGraphQuery');
    end;

    [Test]
    procedure UnitTestCreateGraphQueryUpdateCustomer()
    var
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";
        GraphQL: Text;
    begin
        // Creating Test data.
        CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        CustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);

        // [SCENARIO] Changing the date of an Shopify Customer and the default address.
        // [GIVEN] ShpfyCustomer with change fields
        ShopifyCustomer := CustomerInitTest.ModifyFields(ShopifyCustomer);
        // [GIVEN] ShpfyCustomerAddress with change fields
        CustomerAddress := CustomerInitTest.ModifyFields(CustomerAddress);

        // [WHEN] Invoke ShpfyCustomerApi.CreateGraphQueryUpdateCustomer(ShpfyCustomer, ShpfyCustomerAddress)
        GraphQL := CustomerApi.CreateGraphQueryUpdateCustomer(ShopifyCustomer, CustomerAddress);

        // [THEN] CustomerInitTest.CreateCustomerGraphQLResult() = GraphQL.
        LibraryAssert.AreEqual(CustomerInitTest.CreateGraphQueryUpdateCustomerResult(ShopifyCustomer.Id, CustomerAddress.Id), GraphQL, 'CreateGraphQueryUpdateCustomer');
    end;

    [Test]
    procedure UnitTestUpdateShopifyCustomerFields()
    var
        ShopifyCustomer: Record "Shpfy Customer";
        CustomerAddress: Record "Shpfy Customer Address";
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";
        Result: Boolean;
        JCustomer: JsonObject;
    begin
        // Creating Test data.
        CustomerInitTest.CreateShopifyCustomer(ShopifyCustomer);
        CustomerAddress := CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);
        JCustomer := CustomerInitTest.DummyJsonCustomerObjectFromShopify(ShopifyCustomer.Id, CustomerAddress.Id);

        // [SCENARIO] Changing the date of an Shopify Customer and the default address.
        // [GIVEN] ShpfyCustomer to update
        // [GIVEN] JCustomer with the updated data (Text fields will get the name of the field.)

        // [WHEN] Invoke ShpfyCustomerApi.UpdateShopifyCustomerFields(ShpfyCustomer, JCustomer)
        Result := CustomerApi.UpdateShopifyCustomerFields(ShopifyCustomer, JCustomer);

        // [THEN] Result = true
        LibraryAssert.IsTrue(Result, 'UpdateShopifyCustomerFields = true');

        //[THEN] Test if the value of Text fields equals of the field name.
        CustomerInitTest.TextFieldsContainsFieldName(ShopifyCustomer);
        CustomerAddress.Get(CustomerAddress.Id);
        CustomerInitTest.TextFieldsContainsFieldName(CustomerAddress);
    end;

    [Test]
    procedure UnitTestFormatPhoneNoStripsSpacesAndSeparators()
    var
        CustomerApi: Codeunit "Shpfy Customer API";
    begin
        // [SCENARIO] A formatted phone number is reduced to a comparable form of '+' and digits only,
        // so it can be sent to Shopify as a single, whitespace-free search term.

        // [THEN] Spaces are removed.
        LibraryAssert.AreEqual('+4545454545', CustomerApi.FormatPhoneNo('+45 4545 4545'), 'Spaces should be removed.');
        // [THEN] Other formatting characters are removed as well.
        LibraryAssert.AreEqual('+4545454545', CustomerApi.FormatPhoneNo('+45 (45) 45.45/45'), 'Separators should be removed.');
    end;

    [Test]
    [HandlerFunctions('HttpClientHandler')]
    procedure UnitTestFindIdByPhoneIgnoresTokenizedPartialMatch()
    var
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerId: BigInteger;
        NoCustomerId: BigInteger;
    begin
        // [SCENARIO] A spaced phone number must not match an unrelated Shopify customer that is only returned
        // because Shopify's search syntax tokenizes '+45 4545 4545' into 'phone:+45' plus loose '4545' terms.
        Initialize();
        CustomerApi.SetShop(Shop);

        // [GIVEN] Shopify returns a customer whose phone number differs from the requested one.
        ResponseContent := CustomerPhoneSearchResponse(ShopifyCustomerId(), '+4545455555');

        // [WHEN] Searching by the spaced phone number '+45 4545 4545'.
        CustomerId := CustomerApi.FindIdByPhone('+45 4545 4545');

        // [THEN] No customer id is returned because the phone numbers are not an exact match.
        NoCustomerId := 0;
        LibraryAssert.AreEqual(NoCustomerId, CustomerId, 'A non-exact phone match must not be treated as an existing customer.');
    end;

    [Test]
    [HandlerFunctions('HttpClientHandler')]
    procedure UnitTestFindIdByPhoneReturnsIdForExactMatch()
    var
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerId: BigInteger;
    begin
        // [SCENARIO] A spaced phone number matches a Shopify customer whose normalized phone number is identical.
        Initialize();
        CustomerApi.SetShop(Shop);

        // [GIVEN] Shopify returns a customer whose normalized phone equals the requested one.
        ResponseContent := CustomerPhoneSearchResponse(ShopifyCustomerId(), '+4545454545');

        // [WHEN] Searching by the spaced phone number '+45 4545 4545'.
        CustomerId := CustomerApi.FindIdByPhone('+45 4545 4545');

        // [THEN] The matching customer id is returned.
        LibraryAssert.AreEqual(ShopifyCustomerId(), CustomerId, 'An exact phone match should return the customer id.');
    end;

    [Test]
    [HandlerFunctions('HttpClientHandler')]
    procedure UnitTestFindIdByEmailIgnoresNonExactMatch()
    var
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerId: BigInteger;
        NoCustomerId: BigInteger;
    begin
        // [SCENARIO] An e-mail search must not accept a Shopify customer whose e-mail differs from the requested one.
        Initialize();
        CustomerApi.SetShop(Shop);

        // [GIVEN] Shopify returns a customer with a different e-mail address.
        ResponseContent := CustomerEMailSearchResponse(ShopifyCustomerId(), 'other@contoso.com');

        // [WHEN] Searching by e-mail 'p1@contoso.com'.
        CustomerId := CustomerApi.FindIdByEmail('p1@contoso.com');

        // [THEN] No customer id is returned because the e-mail addresses are not an exact match.
        NoCustomerId := 0;
        LibraryAssert.AreEqual(NoCustomerId, CustomerId, 'A non-exact e-mail match must not be treated as an existing customer.');
    end;

    [Test]
    [HandlerFunctions('HttpClientHandler')]
    procedure UnitTestFindIdByEmailReturnsIdForExactMatch()
    var
        CustomerApi: Codeunit "Shpfy Customer API";
        CustomerId: BigInteger;
    begin
        // [SCENARIO] An e-mail search matches a Shopify customer with the same e-mail address, ignoring casing.
        Initialize();
        CustomerApi.SetShop(Shop);

        // [GIVEN] Shopify returns a customer with the same e-mail address in a different casing.
        ResponseContent := CustomerEMailSearchResponse(ShopifyCustomerId(), 'P1@Contoso.com');

        // [WHEN] Searching by e-mail 'p1@contoso.com'.
        CustomerId := CustomerApi.FindIdByEmail('p1@contoso.com');

        // [THEN] The matching customer id is returned.
        LibraryAssert.AreEqual(ShopifyCustomerId(), CustomerId, 'An exact e-mail match should return the customer id.');
    end;

    local procedure CustomerPhoneSearchResponse(Id: BigInteger; PhoneNo: Text): Text
    begin
        exit(StrSubstNo(CustomerSearchResponseTok, Id, StrSubstNo(DefaultPhoneNumberNodeTok, PhoneNo)));
    end;

    local procedure ShopifyCustomerId(): BigInteger
    var
        Id: BigInteger;
    begin
        // A realistic Shopify customer id does not fit in an Integer, so it is parsed into a BigInteger.
        Evaluate(Id, '9324520669439');
        exit(Id);
    end;

    local procedure CustomerEMailSearchResponse(Id: BigInteger; EMail: Text): Text
    begin
        exit(StrSubstNo(CustomerSearchResponseTok, Id, StrSubstNo(DefaultEMailAddressNodeTok, EMail)));
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Commit();
    end;

    [HttpClientHandler]
    internal procedure HttpClientHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        Response.Content.WriteFrom(ResponseContent);
        exit(false);
    end;
}