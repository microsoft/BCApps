codeunit 135411 "Assembly Mgmt. Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly MGMT] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        MissingPermissionsErr: Label 'Sorry, the current permissions prevented the action.';

    [Scope('OnPrem')]
    procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Assembly Mgmt. Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        LibraryVariableStorage.Clear();

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Assembly Mgmt. Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        LibraryERMCountryData.CreateVATData();
        CreateManufacturingSetup();
        CreateAssemblySetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Assembly Mgmt. Plan-based E2E");
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsBusinessManager()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [WHEN] A sales order containing the above item is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] Inventory for the components is automatically adjusted
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsExternalAccountant()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [WHEN] A sales order containing the above item is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] Inventory for the components is automatically adjusted
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsTeamMember()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        asserterror CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateItemWithComponents(ItemNo, ComponentItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] A sales order containing the above item is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] A validation error is thrown
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] No changes has been done to the inventory
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsEssentialISVEmbUser()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Essential ISV Emb plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [WHEN] A sales order containing the above item is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] Inventory for the components is automatically adjusted
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsTeamMemberISVEmb()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Team Member ISV Emb plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        asserterror CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreateItemWithComponents(ItemNo, ComponentItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] A sales order containing the above item is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] A validation error is thrown
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] No changes has been done to the inventory
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,OrderPostActionHandler,PostedSalesInvoicePageHandler,PostedPurchaseInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyMgmtCreateAndPostSalesOrderAsDeviceISVEmbUser()
    var
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Setup and use Assembly Mgmt by creating a sales order with a BOM Item
        Initialize();

        // [GIVEN] A customer
        CustomerNo := CreateCustomer();

        // [GIVEN] The Device ISV Emb plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] An Item with BOM and Assemble to Order as Assembly Policy
        CreateItemWithComponents(ItemNo, ComponentItemNo);
        // [WHEN] A sales order containing the above item is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo);
        // [THEN] Inventory for the components is automatically adjusted
        VerifyItemInventory(ComponentItemNo, 9);
    end;

    local procedure CreateSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) SalesOrderNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(1);
        SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.OK().Invoke();
    end;

    local procedure PostSalesOrder(SalesOrderNo: Code[20]) PostedSalesOrderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.Post.Invoke();
        PostedSalesOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostedSalesOrderNo));
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) PostedSalesOrderNo: Code[20]
    var
        SalesOrderNo: Code[20];
    begin
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        PostedSalesOrderNo := PostSalesOrder(SalesOrderNo);
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20]) PostedPurchaseInvoiceNo: Code[20]
    var
        PurchaseInvoiceNo: Code[20];
    begin
        PurchaseInvoiceNo := CreatePurchaseInvoice(VendorNo, ItemNo);
        PostedPurchaseInvoiceNo := PostPurchaseInvoice(PurchaseInvoiceNo);
    end;

    local procedure CreatePurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20]) PurchaseInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(VendorNo);
        PurchaseInvoice."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseInvoice.PurchLines."No.".SetValue(ItemNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(10);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        PurchaseInvoiceNo := PurchaseInvoice."No.".Value();
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure PostPurchaseInvoice(PurchaseInvoiceNo: Code[20]) PostedPurchaseInvoiceNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoKey(PurchaseHeader."Document Type"::Invoice, PurchaseInvoiceNo);
        PurchaseInvoice.Post.Invoke();
        PostedPurchaseInvoiceNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostedPurchaseInvoiceNo));
    end;

    local procedure CreateItemWithComponents(var ItemNo: Code[20]; var ComponentItemNo: Code[20])
    var
        VendorNo: Code[20];
    begin
        VendorNo := CreateVendor();
        ItemNo := CreateItem(VendorNo);
        ComponentItemNo := CreateItem(VendorNo);
        CreateAndPostPurchaseInvoice(VendorNo, ComponentItemNo);
        AddBOMComponentToItem(ItemNo, ComponentItemNo);
    end;

    local procedure CreateItem(VendorNo: Code[20]) ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard."Vendor No.".SetValue(VendorNo);
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        VendorCard."Vendor Posting Group".SetValue(LibraryPurchase.FindVendorPostingGroup());
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        CustomerCard."Customer Posting Group".SetValue(LibrarySales.FindCustomerPostingGroup());
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateAssemblySetup()
    var
        AssemblySetup: TestPage "Assembly Setup";
    begin
        AssemblySetup.OpenEdit();
        AssemblySetup."Assembly Order Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        AssemblySetup."Assembly Quote Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        AssemblySetup."Blanket Assembly Order Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        AssemblySetup."Posted Assembly Order Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        AssemblySetup.OK().Invoke();
        Commit();
    end;

    local procedure CreateManufacturingSetup()
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryE2EPlanPermissions.SetViralSignupPlan();
        ManufacturingSetup.DeleteAll();
        ManufacturingSetup.Insert();
        InventorySetup.Get();
        Clear(InventorySetup."Default Safety Lead Time");
        InventorySetup."Combined MPS/MRP Calculation" := false;
        InventorySetup.Modify();
        Commit();
    end;

    local procedure AddBOMComponentToItem(ParentItemNo: Code[20]; ComponentItemNo: Code[20])
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyBOM: TestPage "Assembly BOM";
        ItemCard: TestPage "Item Card";
    begin
        AssemblyBOM.Trap();
        ItemCard.OpenEdit();
        ItemCard.GotoKey(ParentItemNo);
        ItemCard."Assembly BOM".Invoke();
        AssemblyBOM.Type.SetValue(BOMComponent.Type::Item);
        AssemblyBOM."No.".SetValue(ComponentItemNo);
        AssemblyBOM."Quantity per".SetValue(1);
        AssemblyBOM.OK().Invoke();
        ItemCard."Replenishment System".SetValue(Item."Replenishment System"::Assembly);
        ItemCard."Assembly Policy".SetValue(Item."Assembly Policy"::"Assemble-to-Order");
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure VerifyItemInventory(ItemNo: Code[20]; Quantity: Integer)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoKey(ItemNo);
        ItemCard.Inventory.AssertEquals(Quantity);
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
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OrderPostActionHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3 // Receive/Ship & Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value);
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedPurchaseInvoice."No.".Value);
        PostedPurchaseInvoice.Close();
    end;
}

