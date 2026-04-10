codeunit 135404 "Sales Document Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Sales] [Purchase] [Order]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        NoPermissionOnCountryRegionInsertErr: Label 'Sorry, the current permissions prevented the action. (TableData';
        IsInitialized: Boolean;

    [Scope('OnPrem')]
    procedure TestTeamMemberDoesNotHaveBasicPermissionSet()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO] The test framework does NOT add D365 BASIC to TEAMMEMBER
        Initialize();

        // [Given] A user with BASIC permission
        // LibraryLowerPermissions.SetO365Basic(); TODO: Uncomment this when fixing the test

        // [WHEN] The user creates a new Country/Region
        CountryRegion.Code := CopyStr(DelChr(CreateGuid(), '=', '{}-'), 1, MaxStrLen(CountryRegion.Code));
        CountryRegion.Insert();

        // [THEN] No error occurs
        asserterror Assert.ExpectedError('');

        // [Given] A user with TEAMMEMBER plan
        // LibraryLowerPermissions.SetOutsideO365Scope(); TODO: Uncomment this when fixing the test
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] The user creates a new Country/Region
        CountryRegion.Code := CopyStr(DelChr(CreateGuid(), '=', '{}-'), 1, MaxStrLen(CountryRegion.Code));
        asserterror CountryRegion.Insert();

        // [THEN]
        Assert.ExpectedError(NoPermissionOnCountryRegionInsertErr);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,DummyNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderBusinessManager()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as business manager
        Initialize();
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] A sales order
        CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);

        // [THEN] The purchase order contains the same lines as the sales order
        VerifyPurchaseOrderCreatedFromSalesOrder(SalesOrder, PurchaseOrder);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderTeamMember()
    var
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as team member
        Initialize();

        // [GIVEN] The user has the team member plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] User tries to create a sales order
        asserterror CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        asserterror CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,DummyNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderExternalAccountant()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as external accountant
        Initialize();
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] A sales order
        CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);

        // [THEN] The purchase order contains the same lines as the sales order
        VerifyPurchaseOrderCreatedFromSalesOrder(SalesOrder, PurchaseOrder);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,SelectVendorTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderEssentialISVEmbUser()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as Essential ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] A sales order
        CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);

        // [THEN] The purchase order contains the same lines as the sales order
        VerifyPurchaseOrderCreatedFromSalesOrder(SalesOrder, PurchaseOrder);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderTeamMemberISVEmb()
    var
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as team member ISV Emb
        Initialize();

        // [GIVEN] The user has the team member plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] User tries to create a sales order
        asserterror CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        asserterror CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,SelectVendorTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseOrderFromSalesOrderDeviceISVEmbUser()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create a purchase order from a sales order as Device ISV Emb User
        Initialize();
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] A sales order
        CreateSalesOrder(SalesOrder);

        // [WHEN] A purchase order is created from the sales order
        CreatePurchaseOrderFromSalesOrder(SalesOrder, PurchaseOrder);

        // [THEN] The purchase order contains the same lines as the sales order
        VerifyPurchaseOrderCreatedFromSalesOrder(SalesOrder, PurchaseOrder);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerOnSalesQuoteWithAssemblyItemTeamMember()
    var
        SalesQuote: TestPage "Sales Quote";
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Change customer on sales quote with assembly-to-order items work
        Initialize();

        // [GIVEN] Sales quote with a sales line with Assemble-to-Order item
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        LibrarySales.CreateCustomer(Customer);
        CreateAssemblyItem(Item);
        CreateSalesQuote(SalesQuote, Customer, Item);
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuote."No.".Value);
        SalesQuote.Close();
        CustomerNo := LibrarySales.CreateCustomerNo();


        // [WHEN] Change the sell-to customer 
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        SalesQuote.OpenEdit();
        SalesQuote.GoToRecord(SalesHeader);
        SalesQuote."Sell-to Customer No.".SetValue(CustomerNo);

        // [THEN] No errors are thrown
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestValidateQuantityOnSalesOrderWithNonEmptyReOrderingPolicyItemTeamMember()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Change quantity on sales orderline with order - reordering policy items works
        Initialize();

        // [GIVEN] Sales Order with a sales line for item whose reordering policy is not ''
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        LibrarySales.CreateCustomer(Customer);
        Item.Get(CreateItem());
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
        CreateSalesOrder(SalesOrder, Item."No.");
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrder."No.".Value);
        SalesOrder.Close();

        // [WHEN] Change the quantity
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(100));

        // [THEN] No errors are thrown
        SalesOrder.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        RoutingLine: Record "Routing Line";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Document Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        RoutingLine.DeleteAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Document Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.DisableWarningOnCloseUnreleasedDoc();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Document Plan-based E2E");
    end;

    local procedure CreatePurchaseOrderFromSalesOrder(var SalesOrder: TestPage "Sales Order"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.Trap();
        SalesOrder.CreatePurchaseOrder.Invoke();
    end;

    local procedure CreateSalesOrder(var SalesOrder: TestPage "Sales Order")
    begin
        CreateSalesOrder(SalesOrder, '');
    end;

    local procedure CreateSalesOrder(var SalesOrder: TestPage "Sales Order"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(CreateCustomer());
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        if ItemNo = '' then
            SalesOrder.SalesLines."No.".SetValue(CreateItem())
        else
            SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 1));
    end;

    local procedure CreateSalesQuote(var SalesQuote: TestPage "Sales Quote"; Customer: Record Customer; Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer No.".SetValue(Customer."No.");
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(100));
        SalesQuote.SalesLines."Qty. to Assemble to Order".SetValue(SalesQuote.SalesLines.Quantity.Value);
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateAssemblyItem(var Item: Record Item)
    begin
        LibraryAssembly.SetupAssemblyItem(
          Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', false,
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    local procedure VerifyPurchaseOrderCreatedFromSalesOrder(var SalesOrder: TestPage "Sales Order"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.PurchLines.First();
        SalesOrder.SalesLines.First();

        repeat
            PurchaseOrder.PurchLines."No.".AssertEquals(SalesOrder.SalesLines."No.".Value);
            PurchaseOrder.PurchLines.Quantity.AssertEquals(SalesOrder.SalesLines.Quantity.Value);
        until not SalesOrder.SalesLines.Next() and not PurchaseOrder.PurchLines.Next();

        PurchaseOrder.OK().Invoke();
        SalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DummyNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.First();
        PurchOrderFromSalesOrder.Vendor.SetValue(CreateVendor());
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var NotificationToRecall: Notification): Boolean
    begin
        exit(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

