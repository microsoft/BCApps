codeunit 135409 "Item Costing Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Item Costing Method] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        WrongAccountBalanceErr: Label 'The account balance is wrong.';

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsBusinessManager()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
        InventoryAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta1: Decimal;
        COGSAccountBalanceDelta2: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as Business Manager
        Initialize();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        InventoryAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] The inventory account balance is updated with the cost of all the items
        Assert.AreEqual(3200, InventoryAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta1 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 10, COGSGLAccount);
        COGSAccountBalanceDelta2 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to LIFO order
        Assert.AreEqual(800, COGSAccountBalanceDelta1, WrongAccountBalanceErr);
        Assert.AreEqual(300, COGSAccountBalanceDelta2, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsExternalAccountant()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
        InventoryAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta1: Decimal;
        COGSAccountBalanceDelta2: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as External Accountant
        Initialize();

        // [GIVEN] The External Accountant plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        InventoryAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] The inventory account balance is updated with the cost of all the items
        Assert.AreEqual(3200, InventoryAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta1 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 10, COGSGLAccount);
        COGSAccountBalanceDelta2 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to LIFO order
        Assert.AreEqual(800, COGSAccountBalanceDelta1, WrongAccountBalanceErr);
        Assert.AreEqual(300, COGSAccountBalanceDelta2, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsTeamMember()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as Team Member
        Initialize();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders as team member
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] An error is raised
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsEssentialISVEmbUser()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
        InventoryAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta1: Decimal;
        COGSAccountBalanceDelta2: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as Essential ISV Emb User
        Initialize();

        // [GIVEN] The Essential ISV Emb Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        InventoryAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] The inventory account balance is updated with the cost of all the items
        Assert.AreEqual(3200, InventoryAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta1 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 10, COGSGLAccount);
        COGSAccountBalanceDelta2 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to LIFO order
        Assert.AreEqual(800, COGSAccountBalanceDelta1, WrongAccountBalanceErr);
        Assert.AreEqual(300, COGSAccountBalanceDelta2, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsTeamMemberISVEmb()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as Team Member ISV Emb
        Initialize();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders as team member ISV Emb
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] An error is raised
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodLIFOAsDeviceISVEmbUser()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InventoryGLAccount: Code[20];
        COGSGLAccount: Code[20];
        VarianceGLAccount: Code[20];
        InventoryAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta1: Decimal;
        COGSAccountBalanceDelta2: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with LIFO Costing Method as Device ISV Emb User
        Initialize();

        // [GIVEN] The Device ISV Emb Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with LIFO costing
        CreateVendorCustomerAndItemWithLIFOCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        InventoryAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, InventoryGLAccount);

        // [THEN] The inventory account balance is updated with the cost of all the items
        Assert.AreEqual(3200, InventoryAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta1 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 10, COGSGLAccount);
        COGSAccountBalanceDelta2 := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to LIFO order
        Assert.AreEqual(800, COGSAccountBalanceDelta1, WrongAccountBalanceErr);
        Assert.AreEqual(300, COGSAccountBalanceDelta2, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsBusinessManager()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
        VarianceAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as Business Manager
        Initialize();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        VarianceAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] The purchase variance account balance is updated with difference between the standard cost and the purchase price
        Assert.AreEqual(400, VarianceAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to the Standard Cost
        Assert.AreEqual(350, COGSAccountBalanceDelta, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsExternalAccountant()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
        VarianceAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as External Accountant
        Initialize();

        // [GIVEN] The External Accountant plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        VarianceAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] The purchase variance account balance is updated with difference between the standard cost and the purchase price
        Assert.AreEqual(400, VarianceAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to the Standard Cost
        Assert.AreEqual(350, COGSAccountBalanceDelta, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsTeamMember()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as Team Member
        Initialize();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders as team member
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        asserterror CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] A permission error is raised
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsEssentialISVEmbUser()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
        VarianceAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as Essential ISV Emb User
        Initialize();

        // [GIVEN] The Essential ISV Emb Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        VarianceAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] The purchase variance account balance is updated with difference between the standard cost and the purchase price
        Assert.AreEqual(400, VarianceAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to the Standard Cost
        Assert.AreEqual(350, COGSAccountBalanceDelta, WrongAccountBalanceErr);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsTeamMemberISVEmb()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as Team Member ISV Emb
        Initialize();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders as team member ISV Emb
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        asserterror CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] A permission error is raised
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,PostedSalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure ItemCostingMethodStandardAsDeviceISVEmbUser()
    var
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        VarianceGLAccount: Code[20];
        COGSGLAccount: Code[20];
        InventoryGLAccount: Code[20];
        VarianceAccountBalanceDelta: Decimal;
        COGSAccountBalanceDelta: Decimal;
    begin
        // [SCENARIO] Purchasing and selling items with Standard Costing Method as Device ISV Emb User
        Initialize();

        // [GIVEN] The Device ISV Emb Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [GIVEN] An inventory, cogs and variance account
        SetupVarianceInventoryAndCOGSAccount(InventoryGLAccount, COGSGLAccount, VarianceGLAccount);

        // [GIVEN] A vendor, customer and an item with Standard costing
        CreateVendorCustomerAndItemWithStandardCosting(VendorNo, CustomerNo, ItemNo);

        // [WHEN] Creating and posting purchase orders
        VarianceAccountBalanceDelta := CreateAndPostPurchaseInvoices(VendorNo, ItemNo, VarianceGLAccount);

        // [THEN] The purchase variance account balance is updated with difference between the standard cost and the purchase price
        Assert.AreEqual(400, VarianceAccountBalanceDelta, WrongAccountBalanceErr);

        // [WHEN] Creating and posting sales invoices
        COGSAccountBalanceDelta := CreateAndPostSalesInvoice(CustomerNo, ItemNo, 5, COGSGLAccount);

        // [THEN] the COGS account is updated with the cost of the items according to the Standard Cost
        Assert.AreEqual(350, COGSAccountBalanceDelta, WrongAccountBalanceErr);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Item Costing Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Item Costing Plan-based E2E");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryTemplates.UpdateTemplatesVATGroups();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Item Costing Plan-based E2E");
    end;

    local procedure CreateVendorCustomerAndItemWithLIFOCosting(var VendorNo: Code[20]; var CustomerNo: Code[20]; var ItemNo: Code[20])
    begin
        VendorNo := CreateVendor();
        CustomerNo := CreateCustomer();
        ItemNo := CreateItemLIFOCosting(200);
    end;

    local procedure CreateVendorCustomerAndItemWithStandardCosting(var VendorNo: Code[20]; var CustomerNo: Code[20]; var ItemNo: Code[20])
    begin
        VendorNo := CreateVendor();
        CustomerNo := CreateCustomer();
        ItemNo := CreateItemStandardCosting(200, 70);
    end;

    local procedure CreateAndPostPurchaseInvoices(VendorNo: Code[20]; ItemNo: Code[20]; AccountNo: Code[20]) AccountBalanceDelta: Decimal
    var
        PurchaseInvoiceNos: array[3] of Code[20];
        I: Integer;
    begin
        AccountBalanceDelta := GetAccountBalance(AccountNo);

        PurchaseInvoiceNos[1] := CreatePurchaseInvoice(VendorNo, ItemNo, 20, 90, CalcDate('<-4W>', WorkDate()));
        PurchaseInvoiceNos[2] := CreatePurchaseInvoice(VendorNo, ItemNo, 10, 60, CalcDate('<-3W>', WorkDate()));
        PurchaseInvoiceNos[3] := CreatePurchaseInvoice(VendorNo, ItemNo, 10, 80, CalcDate('<-2W>', WorkDate()));

        for I := 1 to 3 do
            PostPurchaseInvoice(PurchaseInvoiceNos[I]);

        AccountBalanceDelta := GetAccountBalance(AccountNo) - AccountBalanceDelta;
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; AccountNo: Code[20]) AccountBalanceDelta: Decimal
    var
        SalesInvoiceNo: Code[20];
    begin
        SalesInvoiceNo := CreateSalesInvoice(CustomerNo, ItemNo, Quantity);
        AccountBalanceDelta := PostSalesInvoice(SalesInvoiceNo, AccountNo);
    end;

    local procedure GetAccountBalance(AccountNo: Code[20]): Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        GLAccount.CalcFields(Balance);
        exit(GLAccount.Balance);
    end;

    local procedure SetupVarianceInventoryAndCOGSAccount(var InventoryAccount: Code[20]; var COGSAccount: Code[20]; var VarianceAccount: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        InventoryAccount := LibraryERM.CreateGLAccountNo();
        VarianceAccount := LibraryERM.CreateGLAccountNo();
        COGSAccount := LibraryERM.CreateGLAccountNo();

        InventoryPostingSetup.FindSet();
        repeat
            InventoryPostingSetup.Validate("Inventory Account", InventoryAccount);
            InventoryPostingSetup.Modify(true);
        until InventoryPostingSetup.Next() = 0;

        GeneralPostingSetup.FindSet();
        repeat
            GeneralPostingSetup.Validate("Purchase Variance Account", VarianceAccount);
            GeneralPostingSetup.Validate("COGS Account", COGSAccount);
            GeneralPostingSetup.Modify(true);
        until GeneralPostingSetup.Next() = 0;
    end;

    local procedure CreatePurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; DirectUnitCost: Decimal; Date: Date) PurchaseInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(VendorNo);
        PurchaseInvoice."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        PurchaseInvoice."Posting Date".SetValue(Date);

        CreatePurchaseInvoiceLine(PurchaseInvoice, Format(PurchaseLine.Type::Item), ItemNo, Quantity, DirectUnitCost);

        PurchaseInvoiceNo := PurchaseInvoice."No.".Value();
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure CreatePurchaseInvoiceLine(var PurchaseInvoice: TestPage "Purchase Invoice"; Type: Text; No: Code[20]; Quantity: Integer; DirectUnitCost: Decimal)
    begin
        PurchaseInvoice.PurchLines.New();
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Type);
        PurchaseInvoice.PurchLines."No.".SetValue(No);
        PurchaseInvoice.PurchLines.Quantity.SetValue(Quantity);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(DirectUnitCost);
    end;

    local procedure PostPurchaseInvoice(PurchaseInvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoKey(PurchaseHeader."Document Type"::Invoice, PurchaseInvoiceNo);
        PurchaseInvoice.Post.Invoke();
    end;

    local procedure CreateSalesInvoice(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer) SalesInvoiceNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerNo);

        CreateSalesInvoiceLine(
          SalesInvoice, Format(SalesLine.Type::Item), ItemNo, Quantity, LibraryRandom.RandDecInRange(10, 100, 2));

        SalesInvoiceNo := SalesInvoice."No.".Value();
        SalesInvoice.OK().Invoke();
    end;

    local procedure CreateSalesInvoiceLine(var SalesInvoice: TestPage "Sales Invoice"; Type: Text; No: Code[20]; Quantity: Integer; UnitPrice: Decimal)
    begin
        SalesInvoice.SalesLines.New();
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(Type);
        SalesInvoice.SalesLines."No.".SetValue(No);
        SalesInvoice.SalesLines.Quantity.SetValue(Quantity);
        SalesInvoice.SalesLines."Unit Price".SetValue(UnitPrice);
    end;

    local procedure PostSalesInvoice(SalesInvoiceNo: Code[20]; AccountNo: Code[20]) AccountBalanceDelta: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        AccountBalanceDelta := GetAccountBalance(AccountNo);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoKey(SalesHeader."Document Type"::Invoice, SalesInvoiceNo);
        SalesInvoice.Post.Invoke();

        AccountBalanceDelta := GetAccountBalance(AccountNo) - AccountBalanceDelta;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        PostedSalesInvoice.Close();
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        VendorName: Text[100];
    begin
        VendorName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(VendorName);
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerName: Text[100];
    begin
        CustomerName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(CustomerName);
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
    end;

    local procedure CreateItemLIFOCosting(UnitPrice: Decimal) ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        Description: Text[100];
    begin
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description));
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(Description);
        ItemCard."Costing Method".SetValue(Item."Costing Method"::LIFO);
        ItemCard."Unit Price".SetValue(UnitPrice);
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
    end;

    local procedure CreateItemStandardCosting(UnitPrice: Decimal; StandardCost: Decimal) ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        Description: Text[100];
    begin
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description));
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(Description);
        ItemCard."Costing Method".SetValue(Item."Costing Method"::Standard);
        ItemCard."Standard Cost".SetValue(StandardCost);
        ItemCard."Unit Price".SetValue(UnitPrice);
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

