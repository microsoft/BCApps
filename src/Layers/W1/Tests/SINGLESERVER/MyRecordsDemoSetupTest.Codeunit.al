codeunit 138090 "My Records Demo Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Detailed Cust. Ledg. Entry" = i,
                  tabledata "Detailed Vendor Ledg. Entry" = i;

    trigger OnRun()
    begin
        PrimaryKeyNo := 1000000;
    end;

    var
        Assert: Codeunit Assert;
        CompanyTriggers: Codeunit "Company Triggers";
        LogInManagement: Codeunit LogInManagement;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PrimaryKeyNo: Integer;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyRecordsSetupWithNonDemoDataCompany()
    var
        MyCustomer: Record "My Customer";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(false);

        // [GIVEN] The My Customer table is empty
        MyCustomer.DeleteAll();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] The My Customer table should remain empty
        Assert.AreEqual(0, MyCustomer.Count, 'The My Customer table should be empty');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyCustomerSetupWhenMyCustomerIsNotEmpty()
    var
        MyCustomer: Record "My Customer";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer table is not empty for the current user
        MyCustomer.DeleteAll();
        CreateMyCustomerForCurrentUser();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] No record should be inserted in the My Customer table
        Assert.AreEqual(1, MyCustomer.Count, 'There should only be one entry in the My Customer table');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestMyCustomerSetupWhenMyCustomerIsEmpty()
    var
        MyCustomer: Record "My Customer";
        Customer: Record Customer;
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer and Customer tables are empty
        MyCustomer.DeleteAll();
        Customer.DeleteAll();

        // [GIVEN] Six customers with a balance that is not 0
        CreateCustomerWithBalance(3);
        CreateCustomerWithBalance(17);
        CreateCustomerWithBalance(20);
        CreateCustomerWithBalance(0);
        CreateCustomerWithBalance(21);
        CreateCustomerWithBalance(19);
        CreateCustomerWithBalance(0);
        CreateCustomerWithBalance(17);

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] The My Customer table should contain 5 entries
        Assert.AreEqual(5, MyCustomer.Count, 'There should be 5 entries in the My Customer table');

        // [WHEN] Filtering the My Customer table for records with the User ID of the current user
        MyCustomer.SetRange("User ID", UserId);

        // [THEN] There should still be 5 entries in the My Customer table
        Assert.AreEqual(5, MyCustomer.Count,
          'There should be 5 entries in the My Customer table with the current user ID');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyItemSetupWhenMyCustomerIsNotEmpty()
    var
        MyItem: Record "My Item";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer table is not empty for the current user
        CreateMyCustomerForCurrentUser();

        // [GIVEN] The My Item table is empty
        MyItem.DeleteAll();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] There are no entries in the My Item table
        Assert.AreEqual(0, MyItem.Count, 'The My Item table should not contain any entries');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyItemSetupWhenMyItemIsNotEmpty()
    var
        MyItem: Record "My Item";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer and My Item tables are not empty for the current user
        CreateMyCustomerForCurrentUser();

        MyItem.DeleteAll();
        CreateMyItemForCurrentUser();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] No record should be inserted in the My Item table
        Assert.AreEqual(1, MyItem.Count, 'There should only be one entry in the My Item table');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestMyItemSetupWhenMyItemIsEmpty()
    var
        MyCustomer: Record "My Customer";
        Customer: Record Customer;
        MyItem: Record "My Item";
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer, Customer, My Item and Item tables are empty
        MyCustomer.DeleteAll();
        Customer.DeleteAll();
        MyItem.DeleteAll();
        Item.DeleteAll();

        // [GIVEN] Seven items with a unit price that is not 0
        CreateItemWithUnitPrice(4);
        ItemNo := CreateItemWithUnitPrice(9);
        CreateItemWithUnitPrice(0);
        CreateItemWithUnitPrice(56);
        CreateItemWithUnitPrice(20);
        CreateItemWithUnitPrice(30);
        CreateItemWithUnitPrice(70);
        CreateItemWithUnitPrice(0);
        CreateItemWithUnitPrice(120);

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] The My Item table should contain 5 entries
        Assert.AreEqual(5, MyItem.Count, 'There should be 5 entries in the My Item table');

        // [WHEN] Filtering the My Item table for records where the User ID is the current user's ID
        MyItem.SetRange("User ID", UserId);

        // [THEN] There should still be 5 entries in the My Item table
        Assert.AreEqual(5, MyItem.Count,
          'There should be 5 entries in the My Item table with the current user ID');

        // [WHEN] Filtering the My Item table for ItemNo
        MyItem.SetRange("Item No.", ItemNo);

        // [THEN] There should be exactly one entry in the My Item table
        Assert.AreEqual(1, MyItem.Count,
          'There should be exactly one entry in the My Item table for this Item No.');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyVendorSetupWhenMyItemIsNotEmpty()
    var
        MyVendor: Record "My Vendor";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Item table is not empty for the current user
        CreateMyItemForCurrentUser();

        // [GIVEN] The My Vendor table is empty
        MyVendor.DeleteAll();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] There are no entries in the My Vendor table
        Assert.AreEqual(0, MyVendor.Count, 'The My Vendor table should not contain any entries');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyVendorSetupWhenMyVendorIsNotEmpty()
    var
        MyVendor: Record "My Vendor";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer, My Item and My Vendor tables are not empty for the current user
        CreateMyCustomerForCurrentUser();
        CreateMyItemForCurrentUser();

        MyVendor.DeleteAll();
        CreateMyVendorForCurrentUser();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] No record should be inserted in the My Vendor table
        Assert.AreEqual(1, MyVendor.Count, 'There should only be one entry in the My Vendor table');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestMyVendorSetupWhenMyVendorIsEmpty()
    var
        MyCustomer: Record "My Customer";
        Customer: Record Customer;
        MyItem: Record "My Item";
        Item: Record Item;
        MyVendor: Record "My Vendor";
        Vendor: Record Vendor;
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer, Customer, My Item, Item, My Vendor and Vendor tables are empty
        MyCustomer.DeleteAll();
        Customer.DeleteAll();
        MyItem.DeleteAll();
        Item.DeleteAll();
        MyVendor.DeleteAll();
        Vendor.DeleteAll();

        // [GIVEN] Seven vendors with a balance that is not 0
        CreateVendorWithBalance(4);
        CreateVendorWithBalance(9);
        CreateVendorWithBalance(0);
        CreateVendorWithBalance(56);
        CreateVendorWithBalance(20);
        CreateVendorWithBalance(30);
        CreateVendorWithBalance(70);
        CreateVendorWithBalance(0);
        CreateVendorWithBalance(120);

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleteds
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] The My Vendor table should contain 5 entries
        Assert.AreEqual(5, MyVendor.Count, 'There should be 5 entries in the My Vendor table');

        // [WHEN] Filtering the My Vendor table for records where the User ID is the current user's ID
        MyVendor.SetRange("User ID", UserId);

        // [THEN] There should still be 5 entries in the My Vendor table
        Assert.AreEqual(5, MyVendor.Count,
          'There should be 5 entries in the My Vendor table with the current user ID');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyAccountSetupWhenMyVendorIsNotEmpty()
    var
        MyAccount: Record "My Account";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Vendor table is not empty for the current user
        CreateMyVendorForCurrentUser();

        // [GIVEN] The My Account table is empty
        MyAccount.DeleteAll();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] There are no entries in the My Account table
        Assert.AreEqual(0, MyAccount.Count, 'The My Account table should not contain any entries');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [Scope('OnPrem')]
    procedure TestMyAccountSetupWhenMyAccountIsNotEmpty()
    var
        MyAccount: Record "My Account";
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer, My Item, My Vendor and My Account tables are not empty for the current user
        CreateMyCustomerForCurrentUser();
        CreateMyItemForCurrentUser();
        CreateMyVendorForCurrentUser();

        MyAccount.DeleteAll();
        CreateMyAccountForCurrentUser();

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] No record should be inserted in the My Account table
        Assert.AreEqual(1, MyAccount.Count, 'There should only be one entry in the My Account table');
    end;

    [Test]
    [HandlerFunctions('ThirtyDayTrialDialogPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestMyAccountSetupWhenMyAccountIsEmpty()
    var
        MyCustomer: Record "My Customer";
        Customer: Record Customer;
        MyItem: Record "My Item";
        Item: Record Item;
        MyVendor: Record "My Vendor";
        Vendor: Record Vendor;
        MyAccount: Record "My Account";
        GLAccount: Record "G/L Account";
        AccountNo: Code[20];
    begin
        // [GIVEN] The current company is a demo company, but not an evaluation company
        Initialize(true);

        // [GIVEN] The My Customer, Customer, My Item, Item, My Vendor, Vendor, My Account and G/L Account tables are empty
        MyCustomer.DeleteAll();
        Customer.DeleteAll();
        MyItem.DeleteAll();
        Item.DeleteAll();
        MyVendor.DeleteAll();
        Vendor.DeleteAll();
        MyAccount.DeleteAll();
        GLAccount.DeleteAll();

        // [GIVEN] Seven G/L Accounts that have the Reconciliation Account flag activated
        CreateGLAccountWithReconciliationAccount(true);
        AccountNo := CreateGLAccountWithReconciliationAccount(true);
        CreateGLAccountWithReconciliationAccount(false);
        CreateGLAccountWithReconciliationAccount(true);
        CreateGLAccountWithReconciliationAccount(true);
        CreateGLAccountWithReconciliationAccount(true);
        CreateGLAccountWithReconciliationAccount(true);
        CreateGLAccountWithReconciliationAccount(false);
        CreateGLAccountWithReconciliationAccount(true);

        // [WHEN] Calling CompanyOpen
        LogInManagement.CompanyOpen();
        Commit(); // Need to commit before calling isolated event OnCompanyOpenCompleted
        CompanyTriggers.OnCompanyOpenCompleted();

        // [THEN] The My Account table should contain 5 entries
        Assert.AreEqual(5, MyAccount.Count, 'There should be 5 entries in the My Account table');

        // [WHEN] Filtering the My Account table for records where the User ID is the current user's ID
        MyAccount.SetRange("User ID", UserId);

        // [THEN] There should still be 5 entries in the My Account table
        Assert.AreEqual(5, MyAccount.Count,
          'There should be 5 entries in the My Account table with the current user ID');

        // [WHEN] Filtering the My Account table for AccountNo
        MyAccount.SetRange("Account No.", AccountNo);

        // [THEN] There should be exactly one entry in the My Account table
        Assert.AreEqual(1, MyAccount.Count,
          'There should be exactly one entry in the My Account table for this Account No.');
    end;

    local procedure Initialize(IsDemoCompany: Boolean)
    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CompanyInformation: Record "Company Information";
    begin
        LibraryLowerPermissions.SetO365BusFull();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        if CompanyInformation.Get() then;
        CompanyInformation."Demo Company" := IsDemoCompany;
        CompanyInformation.Modify();
    end;

    local procedure CreateMyCustomerForCurrentUser()
    var
        MyCustomer: Record "My Customer";
    begin
        MyCustomer.Init();
        MyCustomer."Customer No." := Format(PrimaryKeyNo);
        MyCustomer."User ID" := UserId;
        MyCustomer.Insert();

        PrimaryKeyNo += 1;
    end;

    local procedure CreateCustomerWithBalance(Balance: Decimal): Code[20]
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        Customer.Init();
        Customer.Insert(true);

        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := PrimaryKeyNo;
        DetailedCustLedgEntry.Amount := Balance;
        DetailedCustLedgEntry."Customer No." := Customer."No.";
        DetailedCustLedgEntry.Insert(true);

        PrimaryKeyNo += 1;

        exit(Customer."No.");
    end;

    local procedure CreateMyItemForCurrentUser()
    var
        MyItem: Record "My Item";
    begin
        MyItem.Init();
        MyItem."Item No." := Format(PrimaryKeyNo);
        MyItem."User ID" := UserId;
        MyItem.Insert();

        PrimaryKeyNo += 1;
    end;

    local procedure CreateItemWithUnitPrice(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."Unit Price" := UnitPrice;
        Item.Insert(true);

        exit(Item."No.");
    end;

    local procedure CreateMyVendorForCurrentUser()
    var
        MyVendor: Record "My Vendor";
    begin
        MyVendor.Init();
        MyVendor."Vendor No." := Format(PrimaryKeyNo);
        MyVendor."User ID" := UserId;
        MyVendor.Insert();

        PrimaryKeyNo += 1;
    end;

    local procedure CreateVendorWithBalance(Balance: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Vendor.Init();
        Vendor.Insert(true);

        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := PrimaryKeyNo;
        DetailedVendorLedgEntry.Amount := Balance;
        DetailedVendorLedgEntry."Vendor No." := Vendor."No.";
        DetailedVendorLedgEntry.Insert(true);

        PrimaryKeyNo += 1;

        exit(Vendor."No.");
    end;

    local procedure CreateMyAccountForCurrentUser()
    var
        MyAccount: Record "My Account";
    begin
        MyAccount.Init();
        MyAccount."Account No." := Format(PrimaryKeyNo);
        MyAccount."User ID" := UserId;
        MyAccount.Insert();

        PrimaryKeyNo += 1;
    end;

    local procedure CreateGLAccountWithReconciliationAccount(ReconciliationAccount: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := Format(PrimaryKeyNo);
        GLAccount."Reconciliation Account" := ReconciliationAccount;
        GLAccount.Insert();

        PrimaryKeyNo += 1;

        exit(GLAccount."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThirtyDayTrialDialogPageHandler(var ThirtyDayTrialDialog: TestPage "Thirty Day Trial Dialog")
    begin
        ThirtyDayTrialDialog.TermsAndConditionsCheckBox.Value(Format(true));
        ThirtyDayTrialDialog.ActionStartTrial.Invoke();
    end;
}

