// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139548 "Shpfy Customer Metafields Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        ShpfyCustomer: Record "Shpfy Customer";
        ShpfyInitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestGetMetafieldOwnerTypeFromCustomerMetafield()
    var
        ShpfyMetafield: Record "Shpfy Metafield";
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
        ShpfyMetafieldOwnerType: Enum "Shpfy Metafield Owner Type";
    begin
        // [SCENARIO] Get Metafield Owner Type from Customer Metafield.

        // [GIVEN] Shopify Metafield created for Customer.
        ShpfyMetafieldsHelper.CreateMetafield(ShpfyMetafield, Database::"Shpfy Customer", Any.IntegerInRange(10000, 99999));

        // [WHEN] Invoke Metafield.GetOwnerType();
        ShpfyMetafieldOwnerType := ShpfyMetafield.GetOwnerType(Database::"Shpfy Customer");

        // [THEN] ShpfyMetafieldOwnerType = Enum::"Shpfy Metafield Owner Type"::Customer;
        LibraryAssert.AreEqual(ShpfyMetafieldOwnerType, Enum::"Shpfy Metafield Owner Type"::Customer, 'Metafield Owner Type is different than Customer');
    end;

    [Test]
    procedure UnitTestGetMetafieldOwnerTableId()
    var
        ShpfyMetafield: Record "Shpfy Metafield";
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
        IMetafieldOwnerType: Interface "Shpfy IMetafield Owner Type";
        TableId: Integer;
    begin
        // [SCENARIO] Get Metafield Owner Values from Metafield Owner Customer codeunit
        Initialize();

        // [GIVEN] Shopify Metafield created for Customer.
        ShpfyMetafieldsHelper.CreateMetafield(ShpfyMetafield, Any.IntegerInRange(100000, 99999), Database::"Shpfy Customer");
        // [GIVEN] IMetafieldOwnerType
        IMetafieldOwnerType := ShpfyMetafield.GetOwnerType(Database::"Shpfy Customer");

        // [WHEN] Invoke IMetafieldOwnerType.GetTableId
        TableId := IMetafieldOwnerType.GetTableId();

        // [THEN] TableId = Database::"Shpfy Customer";
        LibraryAssert.AreEqual(TableId, Database::"Shpfy Customer", 'Table Id is different than Customer');
    end;

    [Test]
    procedure UnitTestImportCustomerMetafieldFromShopify()
    var
        ShpfyMetafield: Record "Shpfy Metafield";
        MetafieldAPI: Codeunit "Shpfy Metafield API";
        MetafieldId: BigInteger;
        Namespace: Text;
        MetafieldKey: Text;
        MetafieldValue: Text;
        JMetafields: JsonArray;
    begin
        // [SCENARIO] Import Metafield from Shopify to Business Central
        Initialize();

        // [GIVEN] Response Json with metafield
        JMetafields := CreateCustomerMetafieldsResponse(MetafieldId, Namespace, MetafieldKey, MetafieldValue);

        // [WHEN] Invoke MetafieldAPI.UpdateMetafieldsFromShopify
        MetafieldAPI.UpdateMetafieldsFromShopify(JMetafields, Database::"Shpfy Customer", ShpfyCustomer.Id);

        // [THEN] Metafield with MetafieldId, Namespace, MetafieldKey, MetafieldValue is imported to Business Central
        ShpfyMetafield.Reset();
        ShpfyMetafield.SetRange("Owner Id", ShpfyCustomer.Id);
        ShpfyMetafield.SetRange("Parent Table No.", Database::"Shpfy Customer");

        LibraryAssert.IsTrue(ShpfyMetafield.FindFirst(), 'Metafield is not imported to Business Central');

        LibraryAssert.AreEqual(ShpfyMetafield.Id, MetafieldId, 'Metafield Id is different than imported');
        LibraryAssert.AreEqual(ShpfyMetafield.Namespace, Namespace, 'Namespace is different than imported');
        LibraryAssert.AreEqual(ShpfyMetafield.Name, MetafieldKey, 'Metafield Key is different than imported');
        LibraryAssert.AreEqual(ShpfyMetafield.Value, MetafieldValue, 'Metafield Value is different than imported');
    end;

    [Test]
    procedure UnitTestUpdateRemovedCustomerMetafieldFromShopify()
    var
        ShpfyMetafield: Record "Shpfy Metafield";
        MetafieldAPI: Codeunit "Shpfy Metafield API";
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
        MetafieldId: BigInteger;
        JMetafields: JsonArray;
    begin
        // [SCENARIO] Update Removed Metafield from Shopify to Business Central
        Initialize();

        // [GIVEN] Shopify Metafield created for Customer.
        MetafieldId := ShpfyMetafieldsHelper.CreateMetafield(ShpfyMetafield, ShpfyCustomer.Id, Database::"Shpfy Customer");

        // [WHEN] Invoke MetafieldAPI.UpdateMetafieldsFromShopify with empty JMetafields
        MetafieldAPI.UpdateMetafieldsFromShopify(JMetafields, Database::"Shpfy Customer", ShpfyCustomer.Id);

        // [THEN] Metafield is removed from Business Central
        ShpfyMetafield.Reset();
        ShpfyMetafield.SetRange(Id, MetafieldId);
        ShpfyMetafield.SetRange("Owner Id", ShpfyCustomer.Id);
        ShpfyMetafield.SetRange("Parent Table No.", Database::"Shpfy Customer");
        LibraryAssert.IsTrue(ShpfyMetafield.IsEmpty(), 'Metafield is not removed from Business Central');
    end;

    [Test]
    procedure UnitTestUpdateCustomerMetafieldFromShopify()
    var
        ShpfyMetafield: Record "Shpfy Metafield";
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
        MetafieldAPI: Codeunit "Shpfy Metafield API";
        MetafieldId: BigInteger;
        Namespace: Text[255];
        MetafieldKey: Text[64];
        MetafieldValue: Text[2048];
        JMetafields: JsonArray;
    begin
        // [SCENARIO] Update Metafield from Shopify to Business Central
        Initialize();

        // [GIVEN] Shopify Metafield with values created for Customer.
        Namespace := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Namespace));
        MetafieldKey := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Name));
        MetafieldValue := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Value));
        MetafieldId := ShpfyMetafieldsHelper.CreateMetafield(ShpfyMetafield, ShpfyCustomer.Id, Database::"Shpfy Customer", Namespace, MetafieldKey, MetafieldValue);
        // [GIVEN] Response Json with metafield updated value
        JMetafields := ShpfyMetafieldsHelper.CreateMetafieldsResult(MetafieldId, Namespace, 'CUSTOMER', MetafieldKey, Any.AlphabeticText(10));

        // [WHEN] Invoke MetafieldAPI.UpdateMetafieldsFromShopify
        MetafieldAPI.UpdateMetafieldsFromShopify(JMetafields, Database::"Shpfy Customer", ShpfyCustomer.Id);

        // [THEN] Metafield with MetafieldId, Namespace, MetafieldKey, MetafieldValue is updated in Business Central
        ShpfyMetafield.Reset();
        ShpfyMetafield.SetRange(Id, MetafieldId);
        ShpfyMetafield.SetRange("Owner Id", ShpfyCustomer.Id);
        ShpfyMetafield.SetRange("Parent Table No.", Database::"Shpfy Customer");
        LibraryAssert.IsTrue(ShpfyMetafield.FindFirst(), 'Metafield is not updated in Business Central');
        LibraryAssert.AreEqual(ShpfyMetafield.Id, MetafieldId, 'Metafield Id is different than updated');
        LibraryAssert.AreEqual(ShpfyMetafield.Namespace, Namespace, 'Namespace is different than updated');
        LibraryAssert.AreEqual(ShpfyMetafield.Name, MetafieldKey, 'Metafield Key is different than updated');
        LibraryAssert.AreNotEqual(ShpfyMetafield.Value, MetafieldValue, 'Metafield Value is different than updated');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure UnitTestUpdateCustomerMetafieldInShopfiy()
    var
        Customer: Record Customer;
        ShopifyCustomer: Record "Shpfy Customer";
        ShpfyMetafield: Record "Shpfy Metafield";
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
        CustomerInitTest: Codeunit "Shpfy Customer Init Test";
        Namespace: Text[255];
        MetafieldKey: Text[64];
        MetafieldValue: Text[2048];
    begin
        // [SCENARIO] Update Metafield from Business Central to Shopify
        Initialize();

        //[GIVEN] Shop with Can update Shopify Customer = true
        Shop."Can Update Shopify Customer" := true;
        Shop.Modify(false);
        // [GIVEN] Customer
        Customer := ShpfyInitializeTest.GetDummyCustomer();
        // [GIVEN] Shopify Customer
        CreateShopifyCustomer(Customer, ShopifyCustomer);
        // [GIVEN] Shopify Customer Address
        CustomerInitTest.CreateShopifyCustomerAddress(ShopifyCustomer);
        // [GIVEN] Shopify Metafield with values created for Customer.
        Namespace := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Namespace));
        MetafieldKey := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Name));
        MetafieldValue := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShpfyMetafield.Value));
        ShpfyMetafieldsHelper.CreateMetafield(ShpfyMetafield, ShopifyCustomer.Id, Database::"Shpfy Customer", Namespace, MetafieldKey, MetafieldValue);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetCustomers');
        OutboundHttpRequests.Enqueue('ModifyCustomer');
        OutboundHttpRequests.Enqueue('GetCustomerMetafields');
        OutboundHttpRequests.Enqueue('CreateMetafields');

        // [WHEN] Invoke ShopifyCustomerExport
        InvokeShopifyCustomerExport(Customer, ShopifyCustomer);

        // [THEN] Export completes without error (metafield data was sent to Shopify).
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();

        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := ShpfyInitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        ShpfyInitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        CreateShopifyCustomer(ShpfyCustomer, Shop."Shop Id");

        Commit();
    end;

    local procedure CreateCustomerMetafieldsResponse(var MetafieldId: BigInteger; var Namespace: Text; var MetafieldKey: Text; var MetafieldValue: Text): JsonArray
    var
        ShpfyMetafieldsHelper: Codeunit "Shpfy Metafields Helper";
    begin
        MetafieldId := Any.IntegerInRange(100000, 999999);
        Namespace := Any.AlphabeticText(10);
        MetafieldKey := Any.AlphabeticText(10);
        MetafieldValue := Any.AlphabeticText(10);
        exit(ShpfyMetafieldsHelper.CreateMetafieldsResult(MetafieldId, Namespace, 'CUSTOMER', MetafieldKey, MetafieldValue));
    end;

    local procedure CreateShopifyCustomer(var ShopifyCustomer: Record "Shpfy Customer"; ShopId: BigInteger)
    begin
        Any.SetDefaultSeed();
        ShopifyCustomer.Init();
        ShopifyCustomer.Id := Any.IntegerInRange(100000, 999999);
        ShopifyCustomer."Shop Id" := ShopId;
        ShopifyCustomer.Insert(false);
    end;

    local procedure CreateShopifyCustomer(var Customer: Record Customer; var ShopifyCustomer: Record "Shpfy Customer")
    begin
        ShopifyCustomer.Init();
        ShopifyCustomer.Id := Any.IntegerInRange(100000, 999999);
        ShopifyCustomer."Shop Id" := Shop."Shop Id";
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer."First Name" := CopyStr(Any.AlphabeticText(100), 1, MaxStrLen(ShopifyCustomer."First Name"));
        ShopifyCustomer."Last Name" := CopyStr(Any.AlphabeticText(100), 1, MaxStrLen(ShopifyCustomer."Last Name"));
        ShopifyCustomer.Email := Customer."E-Mail";
        ShopifyCustomer.Insert(false);
    end;

    local procedure InvokeShopifyCustomerExport(var Customer: Record Customer; var ShopifyCustomer: Record "Shpfy Customer")
    var
        ShpfyCustomerExport: Codeunit "Shpfy Customer Export";
        SkippedRecordLogSub: Codeunit "Shpfy Skipped Record Log Sub.";
    begin
        SkippedRecordLogSub.SetShopifyCustomerId(ShopifyCustomer.Id);
        BindSubscription(SkippedRecordLogSub);
        ShpfyCustomerExport.SetShop(Shop);
        Customer.SetRange("No.", Customer."No.");
        ShpfyCustomerExport.Run(Customer);
        UnbindSubscription(SkippedRecordLogSub);
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Body: Text;
        ResponseKey: Text;
    begin
        if not ShpfyInitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        Body := '{}';
        ResponseKey := OutboundHttpRequests.DequeueText();

        case ResponseKey of
            'GetCustomers':
                Response.Content.WriteFrom(NavApp.GetResourceAsText('Metafields/CustomersResult.txt', TextEncoding::UTF8));
            'ModifyCustomer':
                Response.Content.WriteFrom(Body);
            'GetCustomerMetafields':
                Response.Content.WriteFrom(Body);
            'CreateMetafields':
                Response.Content.WriteFrom(Body);
        end;
        exit(false);
    end;
}
