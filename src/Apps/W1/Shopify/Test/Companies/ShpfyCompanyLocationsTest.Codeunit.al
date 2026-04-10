// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139539 "Shpfy Company Locations Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        Customer: Record Customer;
        InitializeTest: Codeunit "Shpfy Initialize Test";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;
        ResponseResourceUrl: Text;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestCreateCompanyLocationSuccess()
    var
        ShopifyCustomer: Record "Shpfy Customer";
        CompanyAPI: Codeunit "Shpfy Company API";
        ShopifyCompanies: TestPage "Shpfy Companies";
    begin
        // [GIVEN] A valid customer and company location setup
        RegExpectedOutboundHttpRequests();
        Initialize();
        ShopifyCompany.GetBySystemId(CompanyLocation."Company SystemId");
        // [WHEN] CreateCompanyLocation is called
        CompanyAPI.SetCompany(ShopifyCompany);
        CompanyAPI.SetShop(Shop);
        CompanyAPI.CreateCustomerAsCompanyLocation(Customer, ShopifyCompany, ShopifyCustomer);

        // [THEN] Company location should be created successfully
#pragma warning disable AA0210
        CompanyLocation.SetRange("Customer Id", Customer.SystemId);
#pragma warning restore AA0210
        CompanyLocation.FindFirst();
        ShopifyCompanies.OpenEdit();
        ShopifyCompanies.GoToRecord(ShopifyCompany);
        ShopifyCompanies.Locations.GoToRecord(CompanyLocation);

        // Cleanup
        CompanyLocation.Delete();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestCreateCompanyLocationSellToBillTo()
    var
        ShopifyCustomer: Record "Shpfy Customer";
        CompanyAPI: Codeunit "Shpfy Company API";
    begin
        // [GIVEN] A valid customer and company location setup
        RegExpectedOutboundHttpRequests();
        Initialize();
        ShopifyCompany.GetBySystemId(CompanyLocation."Company SystemId");
        Customer."Bill-to Customer No." := 'BILLTO';
        Customer.Modify(true);

        // [WHEN] CreateCompanyLocation is called
        CompanyAPI.SetCompany(ShopifyCompany);
        CompanyAPI.SetShop(Shop);
        CompanyAPI.CreateCustomerAsCompanyLocation(Customer, ShopifyCompany, ShopifyCustomer);

        // [THEN] Company location should be created successfully
#pragma warning disable AA0210
        CompanyLocation.SetRange("Customer Id", Customer.SystemId);
#pragma warning restore AA0210
        CompanyLocation.FindFirst();
        Assert.AreEqual(Customer."No.", CompanyLocation."Sell-to Customer No.", 'Sell-to Customer No. mismatch');
        Assert.AreEqual(Customer."Bill-to Customer No.", CompanyLocation."Bill-to Customer No.", 'Bill-to Customer No. mismatch');
    end;

    [Test]
    procedure TestCreateCompanyLocationCustomerAlreadyExportedAsCompany()
    var
        Company: Record "Shpfy Company";
        SkippedRecord: Record "Shpfy Skipped Record";
        LibraryAssert: Codeunit "Library Assert";
        CompanyAPI: Codeunit "Shpfy Company API";
    begin
        // [GIVEN] Customer already exported as a company
        Initialize();
        Company.GetBySystemId(CompanyLocation."Company SystemId");
        Company."Customer SystemId" := Customer.SystemId;
        Company.Modify(true);
        // [GIVEN] Ensure Shpfy Skipped Record is empty
        SkippedRecord.DeleteAll(false);

        // [WHEN] CreateCompanyLocation is called
        CompanyAPI.SetCompany(Company);
        CompanyAPI.SetShop(Shop);
        CompanyAPI.CreateCompanyLocation(Customer);

        // [THEN] Operation should be skipped and record should be logged as skipped
        SkippedRecord.SetRange("Table ID", Database::Customer);
        SkippedRecord.SetRange("Record ID", Customer.RecordId);
        LibraryAssert.IsTrue(SkippedRecord.FindFirst(), 'Expected skipped record to be logged');
        LibraryAssert.IsTrue(SkippedRecord."Skipped Reason".Contains('already exported as a company'), 'Expected reason to mention already exported as company');
    end;

    [Test]
    procedure TestCreateCompanyLocationCustomerAlreadyExportedAsLocation()
    var
        SkippedRecord: Record "Shpfy Skipped Record";
        LibraryAssert: Codeunit "Library Assert";
        CompanyAPI: Codeunit "Shpfy Company API";
    begin
        // [GIVEN] Customer already exported as a location
        Initialize();
        CompanyLocation."Customer Id" := Customer.SystemId;
        CompanyLocation.Modify(true);
        // [GIVEN] Ensure the customer was not previously exported as a company
        ShopifyCompany.GetBySystemId(CompanyLocation."Company SystemId");
        Clear(ShopifyCompany."Customer SystemId");
        ShopifyCompany.Modify(false);
        // [GIVEN] Ensure Shpfy Skipped Record is empty
        SkippedRecord.DeleteAll(false);

        // [WHEN] CreateCompanyLocation is called
        CompanyAPI.SetCompany(ShopifyCompany);
        CompanyAPI.SetShop(Shop);
        CompanyAPI.CreateCompanyLocation(Customer);

        // [THEN] Operation should be skipped and record should be logged as skipped
        SkippedRecord.SetRange("Table ID", Database::Customer);
        SkippedRecord.SetRange("Record ID", Customer.RecordId);
        LibraryAssert.IsTrue(SkippedRecord.FindFirst(), 'Expected skipped record to be logged');
        LibraryAssert.IsTrue(SkippedRecord."Skipped Reason".Contains('already exported as a location'), 'Expected reason to mention already exported as location');
    end;

    internal procedure Initialize()
    var
        CompanyInitialize: Codeunit "Shpfy Company Initialize";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Company Locations Test");
        ClearLastError();
        ResponseResourceUrl := 'Companies/CompanyLocations.txt';
        if IsInitialized then
            exit;

        LibraryRandom.Init();
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Company Locations Test");
        IsInitialized := true;
        Commit();

        Shop := InitializeTest.CreateShop();
        Shop."B2B Enabled" := true;
        Shop.Modify();

        CommunicationMgt.SetTestInProgress(false);
        CompanyLocation := CompanyInitialize.CreateShopifyCompanyLocation();
        ShopifyCompany.GetBySystemId(CompanyLocation."Company SystemId");
        ShopifyCompany."Shop Code" := Shop.Code;
        ShopifyCompany.Modify(false);

        LibrarySales.CreateCustomer(Customer);
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Company Locations Test");
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        CompanyLocationCreateResponseTok: Label 'Companies/CompanyLocations.txt', Locked = true;
        CompanyAssignContactResponseTok: Label 'Companies/CompanyAssignContact.txt', Locked = true;
        CompanyAssignContactRoleResponseTok: Label 'Companies/CompanyAssignContactRole.txt', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case OutboundHttpRequests.Length() of
            3:
                LoadResourceIntoHttpResponse(CompanyLocationCreateResponseTok, Response);
            2:
                LoadResourceIntoHttpResponse(CompanyAssignContactResponseTok, Response);
            1:
                LoadResourceIntoHttpResponse(CompanyAssignContactRoleResponseTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
        exit(false); // Prevents actual HTTP call
    end;

    local procedure RegExpectedOutboundHttpRequests()
    begin
        OutboundHttpRequests.Enqueue('GQL Create Company Location');
        OutboundHttpRequests.Enqueue('GQL Assign Company Contact');
        OutboundHttpRequests.Enqueue('GQL Assign Company Contact Role');
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        OutboundHttpRequests.DequeueText();
    end;
}
