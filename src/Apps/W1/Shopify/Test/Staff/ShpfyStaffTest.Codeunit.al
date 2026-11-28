// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.CRM.Team;
using Microsoft.Integration.Shopify;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 139551 "Shpfy Staff Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ShopSettingsResponses: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        ResponseResourceUrl: Text;
        ShopSettingsRequestCount: Integer;
        AdvancedPlanResponseTok: Label '{"data":{"shop":{"plan":{"publicDisplayName":"Advanced","shopifyPlus":false},"weightUnit":"KILOGRAMS"}}}', Locked = true;
        StaffAccessDeniedResponseTok: Label '{"errors":[{"message":"Access denied for staffMembers field.","extensions":{"code":"ACCESS_DENIED"},"path":["staffMembers"]}],"data":null}', Locked = true;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure TestStaffMembersActionVisibleOnlyForSupportedPlans()
    var
        LibraryAssert: Codeunit "Library Assert";
        ShpfyShopCard: TestPage "Shpfy Shop Card";
    begin
        // [Given] Shop exists
        Initialize();

        // [When] An Advanced store does not have staff access
        Shop."Advanced Shopify Plan" := true;
        Shop."Can Access Staff Members" := false;
        Shop.Modify(false);
        ShpfyShopCard.OpenView();
        ShpfyShopCard.GoToRecord(Shop);

        // [Then] The action should not be visible
        LibraryAssert.IsFalse(ShpfyShopCard.StaffMembers.Visible(), 'Staff Members action should not be visible without staff access.');
        ShpfyShopCard.Close();

        // [When] Staff access is available
        Shop."Can Access Staff Members" := true;
        Shop.Modify(false);
        ShpfyShopCard.OpenView();
        ShpfyShopCard.GoToRecord(Shop);

        // [Then] The action should be visible
        LibraryAssert.IsTrue(ShpfyShopCard.StaffMembers.Visible(), 'Staff Members action should be visible with staff access.');
        ShpfyShopCard.Close();
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestAdvancedPlanWithoutStaffAccessPreservesCatalogs()
    var
        LocalShop: Record "Shpfy Shop";
        StaffMemberAPI: Codeunit "Shpfy Staff Member API";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        LocalShop."Can Access Staff Members" := true;
        LocalShop."Auto Create Catalog" := true;
        ShopSettingsResponses.Enqueue(AdvancedPlanResponseTok);
        ShopSettingsResponses.Enqueue(StaffAccessDeniedResponseTok);

        LocalShop.GetShopSettings();

        LibraryAssert.IsTrue(LocalShop."Advanced Shopify Plan", 'Staff denial must not change the reported plan.');
        LibraryAssert.IsTrue(LocalShop."Auto Create Catalog", 'Staff denial must not disable catalog creation.');
        LibraryAssert.IsFalse(LocalShop."Can Access Staff Members", 'An Advanced plan without staff access must not request staff data.');
        LocalShop.Modify(false);
        StaffMemberAPI.GetStaffMembers(LocalShop.Code);
        LibraryAssert.AreEqual(2, ShopSettingsRequestCount, 'Staff synchronization must not request staff data after the access check fails.');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestStaffAccessGrantedWithNoStaffMembers()
    var
        LocalShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        LocalShop."Can Access Staff Members" := false;
        ShopSettingsResponses.Enqueue(AdvancedPlanResponseTok);
        ShopSettingsResponses.Enqueue('{"data":{"staffMembers":{"nodes":[]}}}');

        LocalShop.GetShopSettings();

        LibraryAssert.IsTrue(LocalShop."Can Access Staff Members", 'A successful empty staff query still grants staff access.');
        LibraryAssert.AreEqual(2, ShopSettingsRequestCount, 'An eligible plan must issue a staff-access check.');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestBasicPlanClearsStaffAccessWithoutProbe()
    var
        LocalShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        LocalShop."Can Access Staff Members" := true;
        ShopSettingsResponses.Enqueue('{"data":{"shop":{"plan":{"publicDisplayName":"Basic","shopifyPlus":false},"weightUnit":"KILOGRAMS"}}}');

        LocalShop.GetShopSettings();

        LibraryAssert.IsFalse(LocalShop."Can Access Staff Members", 'A Basic plan must clear cached staff access.');
        LibraryAssert.AreEqual(1, ShopSettingsRequestCount, 'An ineligible plan must not issue a staff-access check.');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestStaffAccessCheckDoesNotIgnoreOtherErrors()
    var
        LocalShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        ShopSettingsResponses.Enqueue(AdvancedPlanResponseTok);
        ShopSettingsResponses.Enqueue('{"errors":[{"message":"Access denied.","extensions":{"code":"ACCESS_DENIED"},"path":["staffMembers"]},{"message":"Unexpected failure.","extensions":{"code":"INTERNAL_SERVER_ERROR"}}],"data":null}');

        asserterror LocalShop.GetShopSettings();

        LibraryAssert.ExpectedError('INTERNAL_SERVER_ERROR');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestStaffAccessCheckDoesNotIgnoreOtherDenials()
    var
        LocalShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        ShopSettingsResponses.Enqueue(AdvancedPlanResponseTok);
        ShopSettingsResponses.Enqueue('{"errors":[{"message":"Access denied for another field.","extensions":{"code":"ACCESS_DENIED"},"path":["anotherField"]}],"data":null}');

        asserterror LocalShop.GetShopSettings();

        LibraryAssert.ExpectedError('anotherField');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestNormalGraphQLCallStillRaisesStaffAccessDenied()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        CommunicationMgt.SetShop(Shop);
        ShopSettingsResponses.Enqueue(StaffAccessDeniedResponseTok);

        asserterror CommunicationMgt.ExecuteGraphQL("Shpfy GraphQL Type"::Base_CheckStaffMemberAccess);

        LibraryAssert.ExpectedError('ACCESS_DENIED');
    end;

    [Test]
    [HandlerFunctions('ShopSettingsHttpHandler')]
    procedure TestStaffAccessCheckRejectsMissingData()
    var
        LocalShop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Initialize();
        LocalShop := Shop;
        ShopSettingsResponses.Enqueue(AdvancedPlanResponseTok);
        ShopSettingsResponses.Enqueue('{"data":{}}');

        asserterror LocalShop.GetShopSettings();

        LibraryAssert.ExpectedError('The response from Shopify did not contain the expected staffMembers data.');
    end;

    [Test]
    procedure TestAutoCreateCatalogRequiresAdvancedPlan()
    var
        LibraryAssert: Codeunit "Library Assert";
    begin
        // [Given] A shop on a plan that does not support B2B catalogs
        Initialize();
        Shop."Advanced Shopify Plan" := false;
        Shop."Auto Create Catalog" := false;
        Shop.Modify(false);

        // [When] The user tries to enable Auto Create Catalog
        // [Then] A field error is raised mentioning the field
        asserterror Shop.Validate("Auto Create Catalog", true);
        LibraryAssert.ExpectedError(Shop.FieldCaption("Auto Create Catalog"));

        // [Given] The shop is upgraded to a plan that supports B2B catalogs
        Shop."Advanced Shopify Plan" := true;
        Shop.Modify(false);

        // [When] The user enables Auto Create Catalog
        Shop.Validate("Auto Create Catalog", true);

        // [Then] The field is enabled successfully
        LibraryAssert.IsTrue(Shop."Auto Create Catalog", 'Auto Create Catalog should be enabled on an Advanced plan.');
    end;

    [Test]
    procedure TestAdvancedPlanDowngradeDisablesAutoCreateCatalog()
    var
        LibraryAssert: Codeunit "Library Assert";
    begin
        // [Given] A shop on an Advanced plan with Auto Create Catalog enabled
        Initialize();
        Shop."Advanced Shopify Plan" := true;
        Shop."Auto Create Catalog" := true;
        Shop.Modify(false);

        // [When] The shop's plan is downgraded (as happens during a plan sync from Shopify)
        Shop.Validate("Advanced Shopify Plan", false);

        // [Then] Auto Create Catalog is silently disabled
        LibraryAssert.IsFalse(Shop."Auto Create Catalog", 'Auto Create Catalog should be disabled after the plan is downgraded.');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestImportStaff()
    var
        StaffMember: Record "Shpfy Staff Member";
        ShpfyStaffMemberAPI: Codeunit "Shpfy Staff Member API";
        LibraryAssert: Codeunit "Library Assert";
    begin
        // [Given] Staff exists in Shopify and is available for import
        Initialize();

        // [When] Staff is imported into BC
        ShpfyStaffMemberAPI.GetStaffMembers(Shop.Code);

        // [Then] Staff exists in BC
        LibraryAssert.IsTrue(StaffMember.Count() = 2, 'There should be 2 staff members imported into BC.');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestImportDeletedStaffReflectsDeletion()
    var
        StaffMember: Record "Shpfy Staff Member";
        ShpfyStaffMemberAPI: Codeunit "Shpfy Staff Member API";
        LibraryAssert: Codeunit "Library Assert";
    begin
        // [Given] Staff was deleted in Shopify
        Initialize();

        CreateNewStaffMember(Shop.Code, StaffMember);

        // [When] Staff is imported into BC
        ShpfyStaffMemberAPI.GetStaffMembers(Shop.Code);

        // [Then] Staff is deleted in BC
        LibraryAssert.IsTrue(StaffMember.Count() = 2, 'There should be 2 staff members BC.');
    end;


    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestImportModifiedStaffReflectsChanges()
    var
        StaffMember: Record "Shpfy Staff Member";
        ShpfyStaffMemberAPI: Codeunit "Shpfy Staff Member API";
        LibraryAssert: Codeunit "Library Assert";
        OriginalName: Text;
    begin
        // [Given] Staff was modified in Shopify
        Initialize();

        CreateNewStaffMember(Shop.Code, StaffMember);
        OriginalName := StaffMember.Name;

        // [When] Staff is imported into BC
        ShpfyStaffMemberAPI.GetStaffMembers(Shop.Code);

        // [Then] Staff is modified in BC
        StaffMember.Get(Shop.Code, GetStaffIdToModify());
        LibraryAssert.IsFalse(StaffMember.Name = OriginalName, 'Staff name should be modified in BC.');
    end;

    [Test]
    procedure TestCannotAssignSameSalespersonToMultipleStaff()
    var
        StaffMember: Record "Shpfy Staff Member";
        Salesperson: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
        LibraryAssert: Codeunit "Library Assert";
        SalespersonPurchaserMappingErr: Label '%1 %2 already mapped to Shopify Staff Member %3.', Comment = '%1 = Salesperson/Purchaser table caption, %2 = Salesperson/Purchaser code, %3 = Shopify Staff Member name';
    begin
        Initialize();

        CreateNewStaffMember(Shop.Code, StaffMember);
        CreateNewStaffMember(Shop.Code, StaffMember);
        LibrarySales.CreateSalesperson(Salesperson);

        // [Given] A Salesperson Code is assigned to Staff A
        StaffMember.FindFirst();
        StaffMember.Validate("Salesperson Code", Salesperson.Code);
        StaffMember.Modify(false);
        Commit();

        // [When] The same Salesperson Code is assigned to Staff B
        StaffMember.FindLast();
        asserterror StaffMember.Validate("Salesperson Code", Salesperson.Code);

        // [Then] An error or validation prevents this assignment
        StaffMember.FindFirst();
        LibraryAssert.ExpectedError(
            StrSubstNo(SalespersonPurchaserMappingErr, Salesperson.TableCaption(), StaffMember."Salesperson Code", StaffMember.Name));
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestImportOrderToBCAssignSalesperson()
    var
        StaffMember: Record "Shpfy Staff Member";
        Salesperson: Record "Salesperson/Purchaser";
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderHeader: Record "Shpfy Order Header";
        LibrarySales: Codeunit "Library - Sales";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        ImportOrder: Codeunit "Shpfy Import Order";
        LibraryAssert: Codeunit "Library Assert";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        Initialize();

        CreateNewStaffMember(Shop.Code, StaffMember, GetStaffIdToModify());
        LibrarySales.CreateSalesperson(Salesperson);
        StaffMember.FindFirst();
        StaffMember.Validate("Salesperson Code", Salesperson.Code);
        StaffMember.Modify(false);

        // [Given] An order exists in Shopify
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, true);

        // [When] The order is imported into BC
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);

        // [Then] The Salesperson is assigned on the imported order
        LibraryAssert.IsTrue(OrderHeader."Salesperson Code" = StaffMember."Salesperson Code", 'Salesperson should be assigned on the imported order.');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestCreateSOFromImportedOrderSalespersonAssigned()
    var
        StaffMember: Record "Shpfy Staff Member";
        Salesperson: Record "Salesperson/Purchaser";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        LibraryAssert: Codeunit "Library Assert";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        Initialize();

        CreateNewStaffMember(Shop.Code, StaffMember, GetStaffIdToModify());
        LibrarySales.CreateSalesperson(Salesperson);
        StaffMember.FindFirst();
        StaffMember.Validate("Salesperson Code", Salesperson.Code);
        StaffMember.Modify(false);

        // [Given] A Shopify order has been imported into BC
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, true);
        Commit();

        // [When] A Sales Order is created in BC from the imported Shopify order
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.Get(OrderHeader."Shopify Order Id");

        // [Then] The Salesperson is assigned on the Sales Order
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderHeader."Sales Order No.");
        LibraryAssert.AreEqual(OrderHeader."Salesperson Code", SalesHeader."Salesperson Code", 'ShpfyOrderHeader."Salesperson Code" = SalesHeader."Salesperson Code"');
    end;

    local procedure Initialize()
    var
        ShpfyStaffMember: Record "Shpfy Staff Member";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Staff Test");
        ClearLastError();
        ResponseResourceUrl := 'Staff/StaffMembers.txt';
        ShopSettingsResponses.Clear();
        ShopSettingsRequestCount := 0;

        ShpfyStaffMember.DeleteAll(false);

        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Staff Test");

            LibraryRandom.Init();

            Any.SetDefaultSeed();

            IsInitialized := true;
            Commit();

            Shop := InitializeTest.CreateShop();

            AccessToken := LibraryRandom.RandText(20);
            InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Staff Test");
        end;

        Shop.Get(Shop.Code);
        Shop."Advanced Shopify Plan" := true;
        Shop."Can Access Staff Members" := true;
        Shop."Auto Create Catalog" := false;
        Shop.Modify(false);
    end;

    [HttpClientHandler]
    internal procedure ShopSettingsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        ShopSettingsRequestCount += 1;
        Response.Content.WriteFrom(ShopSettingsResponses.DequeueText());
        exit(false);
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        MakeResponse(Response);
        exit(false); // Prevents actual HTTP call
    end;

    local procedure MakeResponse(var HttpResponseMessage: TestHttpResponseMessage): Boolean
    begin
        LoadResourceIntoHttpResponse(ResponseResourceUrl, HttpResponseMessage);
    end;

    local procedure CreateNewStaffMember(ShopCode: Code[20]; StaffMember: Record "Shpfy Staff Member")
    begin
        CreateNewStaffMember(ShopCode, StaffMember, 0);
    end;

    local procedure CreateNewStaffMember(ShopCode: Code[20]; StaffMember: Record "Shpfy Staff Member"; StaffId: BigInteger)
    begin
        StaffMember.Init();
        StaffMember."Shop Code" := ShopCode;
        StaffMember.Id := StaffId;
        if StaffId = 0 then
            StaffMember.Id := Any.IntegerInRange(1, 99999);
        StaffMember.Name := CopyStr(Any.AlphabeticText(100), 1, MaxStrLen(StaffMember.Name));
        StaffMember.Insert(false);
    end;

    local procedure GetStaffIdToModify(): BigInteger
    begin
        // When changing this value make sure to also change the value in the test data file StaffMembers.txt
        exit(1234567890L);
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
    end;
}
