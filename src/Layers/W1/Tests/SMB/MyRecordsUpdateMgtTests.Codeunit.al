codeunit 138076 "My Records Update Mgt. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [My]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateOnCustomerNameSetsReferencedFields()
    var
        Customer: Record Customer;
        MyCustomer: Record "My Customer";
    begin
        // [FEATURE] [Customer]
        // [GIVEN] We have a customer in the system
        // [WHEN] A User Creates a New My Customer Record
        // [THEN] Changes are propagated to My Customer table

        // Setup
        Initialize();
        CreateTestCustomer(Customer);
        MyCustomer.Init();

        // Execute
        MyCustomer.Validate("Customer No.", Customer."No.");

        // Verify
        VerifyCustomerMatchesMyCustomer(Customer, MyCustomer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingACustomerWithTriggerUpdatesMyCustomer()
    var
        Customer: Record Customer;
        OldCustomer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] We have a customer in the system belonging to different users
        // [WHEN] A User Modifies name and description
        // [THEN] Changes are propagated to My Customer table

        // Setup
        Initialize();
        CreateTestCustomer(Customer);
        CreateMyCustomer(Customer, GetCurrentUserID());
        CreateMyCustomer(Customer, 'Test');
        OldCustomer := Customer;

        // Execute
        Customer.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name)));
        Customer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Customer.Modify(true);

        // Verify
        VerifyCustomerChangesPropagatedToMyCustomers(Customer);
        Assert.AreNotEqual(Customer.Name, OldCustomer.Name, 'Different Name should have been generated');
        Assert.AreNotEqual(Customer."Phone No.", OldCustomer."Phone No.", 'Different "Phone No." should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingACustomerWithoutTriggerUpdatesMyCustomer()
    var
        Customer: Record Customer;
        OldCustomer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] We have a customer in the system belonging to different users
        // [WHEN] NAV Modifies name and description through code without ruinning a trigger
        // [THEN] Changes are propagated to My Customer table

        // Setup
        Initialize();
        CreateTestCustomer(Customer);
        CreateMyCustomer(Customer, GetCurrentUserID());
        CreateMyCustomer(Customer, '');
        OldCustomer := Customer;

        // Execute
        Customer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Customer.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name)));
        Customer.Modify();

        // Verify
        VerifyCustomerChangesPropagatedToMyCustomers(Customer);
        Assert.AreNotEqual(Customer.Name, OldCustomer.Name, 'Different Name should have been generated');
        Assert.AreNotEqual(Customer."Phone No.", OldCustomer."Phone No.", 'Different "Phone No." should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingMultipleCustomers()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        OldCustomer: Record Customer;
        OldCustomer2: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [GIVEN] We have two customers in the system belonging to different users
        // [WHEN] NAV Modifies name and description through code without running a trigger on a single field
        // [THEN] Changes are propagated to My Customer records leaving the old values as they were

        // Setup
        Initialize();
        CreateTestCustomer(Customer);
        CreateTestCustomer(Customer2);

        CreateMyCustomer(Customer, GetCurrentUserID());

        CreateMyCustomer(Customer2, GetCurrentUserID());
        CreateMyCustomer(Customer2, '');

        OldCustomer := Customer;
        OldCustomer2 := Customer2;

        // Execute
        Customer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Customer.Modify();

        Customer2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name)));
        Customer2.Modify();

        // Verify
        VerifyCustomerChangesPropagatedToMyCustomers(Customer);
        VerifyCustomerChangesPropagatedToMyCustomers(Customer2);

        Assert.AreNotEqual(Customer."Phone No.", OldCustomer."Phone No.", 'Different "Phone No." should have been generated');
        Assert.AreNotEqual(Customer2.Name, OldCustomer2.Name, 'Different Name should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingCustomerWithoutMyCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        MyCustomer: Record "My Customer";
    begin
        // [FEATURE] [Customer]
        // [GIVEN] We have two customers in the system belonging to different users
        // [WHEN] NAV code modifies a customer without My Customer record
        // [THEN] My Customer record was not modified

        // Setup
        Initialize();
        CreateTestCustomer(Customer);
        CreateTestCustomer(Customer2);

        CreateMyCustomer(Customer, GetCurrentUserID());

        // Execute
        Customer2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name)));
        Customer2.Modify();

        // Verify
        VerifyCustomerChangesPropagatedToMyCustomers(Customer);
        Assert.IsFalse(MyCustomer.Get(Customer2."No."), 'There should be no my customers assigned to customer 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingTempCustomerDoesNotUpdateMyCustomer()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 231207] My Customer record isn't changed if Stan change corresponding Customer Temporary record
        Initialize();

        // [GIVEN] Create Customer, create My Customer linked to this Customer
        CreateTestCustomer(Customer);
        CreateMyCustomer(Customer, GetCurrentUserID());

        // [GIVEN] Create Customer Temporary record from Customer record mentioned above
        TempCustomer := Customer;
        TempCustomer.Insert();

        // [WHEN] Modify "Name" and "Phone No." fields of Customer Temporary record
        TempCustomer.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(TempCustomer.Name)));
        TempCustomer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        TempCustomer.Modify();

        // [THEN] My Customer record wasn't changed
        VerifyCustomerChangesPropagatedToMyCustomers(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateOnVendorNameSetsReferencedFields()
    var
        Vendor: Record Vendor;
        MyVendor: Record "My Vendor";
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] We have a Vendor in the system
        // [WHEN] A User Creates a New My Vendor Record
        // [THEN] Changes are propagated to My Vendor table

        // Setup
        Initialize();
        CreateTestVendor(Vendor);
        MyVendor.Init();

        // Execute
        MyVendor.Validate("Vendor No.", Vendor."No.");

        // Verify
        VerifyVendorMatchesMyVendor(Vendor, MyVendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAVendorWithTriggerUpdatesMyVendor()
    var
        Vendor: Record Vendor;
        OldVendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] We have a Vendor in the system belonging to different users
        // [WHEN] A User Modifies name and description
        // [THEN] Changes are propagated to My Vendor table

        // Setup
        Initialize();
        CreateTestVendor(Vendor);
        CreateMyVendor(Vendor, GetCurrentUserID());
        CreateMyVendor(Vendor, 'Test');
        OldVendor := Vendor;

        // Execute
        Vendor.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name)));
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Modify(true);

        // Verify
        VerifyVendorChangesPropagatedToMyVendors(Vendor);
        Assert.AreNotEqual(Vendor.Name, OldVendor.Name, 'Different Name should have been generated');
        Assert.AreNotEqual(Vendor."Phone No.", OldVendor."Phone No.", 'Different "Phone No." should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAVendorWithoutTriggerUpdatesMyVendor()
    var
        Vendor: Record Vendor;
        OldVendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] We have a Vendor in the system belonging to different users
        // [WHEN] NAV Modifies name and description through code without running a trigger
        // [THEN] Changes are propagated to My Vendor table

        // Setup
        Initialize();
        CreateTestVendor(Vendor);
        CreateMyVendor(Vendor, GetCurrentUserID());
        CreateMyVendor(Vendor, '');
        OldVendor := Vendor;

        // Execute
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name)));
        Vendor.Modify();

        // Verify
        VerifyVendorChangesPropagatedToMyVendors(Vendor);
        Assert.AreNotEqual(Vendor.Name, OldVendor.Name, 'Different Name should have been generated');
        Assert.AreNotEqual(Vendor."Phone No.", OldVendor."Phone No.", 'Different "Phone No." should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingMultipleVendors()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        OldVendor: Record Vendor;
        OldVendor2: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] We have two Vendors in the system belonging to different users
        // [WHEN] NAV Modifies name and description through code without ruinning a trigger on a single field
        // [THEN] Changes are propagated to My Vendor records leaving the old values as they were

        // Setup
        Initialize();
        CreateTestVendor(Vendor);
        CreateTestVendor(Vendor2);

        CreateMyVendor(Vendor, GetCurrentUserID());

        CreateMyVendor(Vendor2, GetCurrentUserID());
        CreateMyVendor(Vendor2, '');

        OldVendor := Vendor;
        OldVendor2 := Vendor2;

        // Execute
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Modify();

        Vendor2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name)));
        Vendor2.Modify();

        // Verify
        VerifyVendorChangesPropagatedToMyVendors(Vendor);
        VerifyVendorChangesPropagatedToMyVendors(Vendor2);

        Assert.AreNotEqual(Vendor."Phone No.", OldVendor."Phone No.", 'Different "Phone No." should have been generated');
        Assert.AreNotEqual(Vendor2.Name, OldVendor2.Name, 'Different Name should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingVendorWithoutMyVendor()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        MyVendor: Record "My Vendor";
    begin
        // [FEATURE] [Vendor]
        // [GIVEN] We have two Vendors in the system belonging to different users
        // [WHEN] NAV code modifies a Vendor without My Vendor record
        // [THEN] My Vendor record was not modified

        // Setup
        Initialize();
        CreateTestVendor(Vendor);
        CreateTestVendor(Vendor2);

        CreateMyVendor(Vendor, GetCurrentUserID());

        // Execute
        Vendor2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name)));
        Vendor2.Modify();

        // Verify
        VerifyVendorChangesPropagatedToMyVendors(Vendor);
        Assert.IsFalse(MyVendor.Get(Vendor2."No."), 'There should be no My Vendors assigned to Vendor 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingTempVendorDoesNotUpdateMyVendor()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 231207] My Vendor record isn't changed if Stan change corresponding Vendor Temporary record
        Initialize();

        // [GIVEN] Create Vendor, create My Vendor linked to this Vendor
        CreateTestVendor(Vendor);
        CreateMyVendor(Vendor, GetCurrentUserID());

        // [GIVEN] Create Vendor Temporary record from Vendor record mentioned above
        TempVendor := Vendor;
        TempVendor.Insert();

        // [WHEN] Modify "Name" and "Phone No." fields of Vendor Temporary record
        TempVendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(TempVendor.Name)));
        TempVendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        TempVendor.Modify(true);

        // [THEN] My Vendor record wasn't changed
        VerifyVendorChangesPropagatedToMyVendors(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateOnItemNameSetsReferencedFields()
    var
        Item: Record Item;
        MyItem: Record "My Item";
    begin
        // [FEATURE] [Item]
        // [GIVEN] We have a Item in the system
        // [WHEN] A User Creates a New My Item Record
        // [THEN] Changes are propagated to My Item table

        // Setup
        Initialize();
        CreateTestItem(Item);
        MyItem.Init();

        // Execute
        MyItem.Validate("Item No.", Item."No.");

        // Verify
        VerifyItemMatchesMyItem(Item, MyItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAItemWithTriggerUpdatesMyItem()
    var
        Item: Record Item;
        OldItem: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] We have a Item in the system belonging to different users
        // [WHEN] A User Modifies Description and description
        // [THEN] Changes are propagated to My Item table

        // Setup
        Initialize();
        CreateTestItem(Item);
        CreateMyItem(Item, GetCurrentUserID());
        CreateMyItem(Item, 'Test');
        OldItem := Item;

        // Execute
        Item.Validate(Description, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description)));
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        Item.Modify(true);

        // Verify
        VerifyItemChangesPropagatedToMyItems(Item);
        Assert.AreNotEqual(Item.Description, OldItem.Description, 'Different Description should have been generated');
        Assert.AreNotEqual(Item."Unit Price", OldItem."Unit Price", 'Different "Unit Price" should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAItemWithoutTriggerUpdatesMyItem()
    var
        Item: Record Item;
        OldItem: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] We have a Item in the system belonging to different users
        // [WHEN] NAV Modifies Unit Price and description through code without ruinning a trigger
        // [THEN] Changes are propagated to My Item table

        // Setup
        Initialize();
        CreateTestItem(Item);
        CreateMyItem(Item, GetCurrentUserID());
        CreateMyItem(Item, '');
        OldItem := Item;

        // Execute
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        Item.Validate(Description, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description)));
        Item.Modify();

        // Verify
        VerifyItemChangesPropagatedToMyItems(Item);
        Assert.AreNotEqual(Item.Description, OldItem.Description, 'Different Description should have been generated');
        Assert.AreNotEqual(Item."Unit Price", OldItem."Unit Price", 'Different "Unit Price" should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingMultipleItems()
    var
        Item: Record Item;
        Item2: Record Item;
        OldItem: Record Item;
        OldItem2: Record Item;
    begin
        // [FEATURE] [Item]
        // [GIVEN] We have two Items in the system belonging to different users
        // [WHEN] NAV Modifies Description and description through code without ruinning a trigger on a single field
        // [THEN] Changes are propagated to My Item records leaving the old values as they were

        // Setup
        Initialize();
        CreateTestItem(Item);
        CreateTestItem(Item2);

        CreateMyItem(Item, GetCurrentUserID());

        CreateMyItem(Item2, GetCurrentUserID());
        CreateMyItem(Item2, '');

        OldItem := Item;
        OldItem2 := Item2;

        // Execute
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        Item.Modify();

        Item2.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description)));
        Item2.Modify();

        // Verify
        VerifyItemChangesPropagatedToMyItems(Item);
        VerifyItemChangesPropagatedToMyItems(Item2);

        Assert.AreNotEqual(Item."Unit Price", OldItem."Unit Price", 'Different "Unit Price" should have been generated');
        Assert.AreNotEqual(Item2.Description, OldItem2.Description, 'Different Description should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingItemWithoutMyItem()
    var
        Item: Record Item;
        Item2: Record Item;
        MyItem: Record "My Item";
    begin
        // [FEATURE] [Item]
        // [GIVEN] We have two Items in the system belonging to different users
        // [WHEN] NAV code modifies a Item without My Item record
        // [THEN] My Item record was not modified

        // Setup
        Initialize();
        CreateTestItem(Item);
        CreateTestItem(Item2);

        CreateMyItem(Item, GetCurrentUserID());

        // Execute
        Item2.Validate(
          Description, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description)));
        Item2.Modify();

        // Verify
        VerifyItemChangesPropagatedToMyItems(Item);
        Assert.IsFalse(MyItem.Get(Item2."No."), 'There should be no my Items assigned to Item 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingTempItemDoesNotUpdateMyItem()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
    begin
        // [FEATURE] [Item]
        // [SCENARIO 231207] My Item record isn't changed if Stan change corresponding Item Temporary record
        Initialize();

        // [GIVEN] Create Item, create My Item linked to this Item
        CreateTestItem(Item);
        CreateMyItem(Item, GetCurrentUserID());

        // [GIVEN] Create Item Temporary record from Item record mentioned above
        TempItem := Item;
        TempItem.Insert();

        // [WHEN] Modify "Description" and "Unit Price" fields of Item Temporary record
        TempItem.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(TempItem.Description)));
        TempItem.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        TempItem.Modify(true);

        // [THEN] My Item record wasn't changed
        VerifyItemChangesPropagatedToMyItems(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateOnAccountNameSetsReferencedFields()
    var
        GLAccount: Record "G/L Account";
        MyAccount: Record "My Account";
    begin
        // [FEATURE] [G/L Account]
        // [GIVEN] We have a GLAccount in the system
        // [WHEN] A User Creates a New My Account Record
        // [THEN] Changes are propagated to My Account table

        // Setup
        Initialize();
        CreateTestAccount(GLAccount);
        MyAccount.Init();

        // Execute
        MyAccount.Validate("Account No.", GLAccount."No.");

        // Verify
        VerifyAccountMatchesMyAccount(GLAccount, MyAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAnAccountWithTriggerUpdatesMyAccount()
    var
        GLAccount: Record "G/L Account";
        OldGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        // [GIVEN] We have a Account in the system belonging to different users
        // [WHEN] A User Modifies Description and description
        // [THEN] Changes are propagated to My Account table

        // Setup
        Initialize();
        CreateTestAccount(GLAccount);
        OldGLAccount := GLAccount;
        CreateMyAccount(GLAccount, 'Test');
        CreateMyAccount(GLAccount, GetCurrentUserID());

        // Execute
        GLAccount.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name)));
        GLAccount.Modify(true);

        // Verify
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount);
        Assert.AreNotEqual(GLAccount.Name, OldGLAccount.Name, 'Different Name should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAnAccountWithoutTriggerUpdatesMyAccount()
    var
        GLAccount: Record "G/L Account";
        OldGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        // [GIVEN] We have a Account in the system belonging to different users
        // [WHEN] NAV Modifies Unit Price and description through code without ruinning a trigger
        // [THEN] Changes are propagated to My Account table

        // Setup
        Initialize();
        CreateTestAccount(GLAccount);
        CreateMyAccount(GLAccount, GetCurrentUserID());
        CreateMyAccount(GLAccount, '');
        OldGLAccount := GLAccount;

        // Execute
        GLAccount.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name)));
        GLAccount.Modify();

        // Verify
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount);
        Assert.AreNotEqual(GLAccount.Name, OldGLAccount.Name, 'Different Name should have been generated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingMultipleAccounts()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        // [GIVEN] We have two Accounts in the system belonging to different users
        // [WHEN] NAV Modifies Description and description through code without ruinning a trigger on a single field
        // [THEN] Changes are propagated to My Account records leaving the old values as they were

        // Setup
        Initialize();
        CreateTestAccount(GLAccount);
        CreateTestAccount(GLAccount2);

        CreateMyAccount(GLAccount, GetCurrentUserID());

        CreateMyAccount(GLAccount2, GetCurrentUserID());
        CreateMyAccount(GLAccount2, '');

        // Execute
        GLAccount.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name)));
        GLAccount.Modify();

        GLAccount2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name)));
        GLAccount2.Modify();

        // Verify
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount);
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingAccountWithoutMyAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        MyAccount: Record "My Account";
    begin
        // [FEATURE] [G/L Account]
        // [GIVEN] We have two Accounts in the system belonging to different users
        // [WHEN] NAV code modifies a Account without My Account record
        // [THEN] My Account record was not modified

        // Setup
        Initialize();
        CreateTestAccount(GLAccount);
        CreateTestAccount(GLAccount2);

        CreateMyAccount(GLAccount, GetCurrentUserID());

        // Execute
        GLAccount2.Validate(Name, CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name)));
        GLAccount2.Modify();

        // Verify
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount);
        Assert.IsFalse(MyAccount.Get(GLAccount2."No."), 'There should be no my Accounts assigned to Account 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingTempAccountDoesNotUpdateMyAccount()
    var
        GLAccount: Record "G/L Account";
        TempGLAccount: Record "G/L Account" temporary;
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO 231207] My Account record isn't changed if Stan change corresponding G/L Account Temporary record
        Initialize();

        // [GIVEN] Create G/L Account, create My Account linked to this G/L Account
        CreateTestAccount(GLAccount);
        CreateMyAccount(GLAccount, GetCurrentUserID());

        // [GIVEN] Create G/L Account Temporary record from G/L Account record mentioned above
        TempGLAccount := GLAccount;
        TempGLAccount.Insert();

        // [WHEN] Modify "Name" field of G/L Account Temporary record
        TempGLAccount.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(TempGLAccount.Name)));
        TempGLAccount.Modify(true);

        // [THEN] My Account record wasn't changed
        VerifyAccountChangesPropagatedToMyAccounts(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateBalancyLCYInMyCustomerUT()
    var
        Customer: Record Customer;
        MyCustomer: Record "My Customer";
        AmountLCY: Decimal;
    begin
        // [FEATURE] [My Customer] [UT]
        // [SCENARIO 211359] "Balance" in My Customer should be calculated in local currency
        Initialize();

        // [GIVEN] Customer "CCC"
        CreateTestCustomer(Customer);
        CreateMyCustomer(Customer, GetCurrentUserID());

        // [GIVEN] Detailed Customer Ledger Entry for Customer "CCC" having 100 "Amount" and 200 "Amount LCY"
        AmountLCY := CreateDetailedCustLedgEntry(Customer."No.");

        // [WHEN] Calculate "Balance" of My Customer for Customer "CCC"
        MyCustomer.Get(GetCurrentUserID(), Customer."No.");
        MyCustomer.CalcFields("Balance (LCY)");

        // [THEN] "Balance" is 200
        MyCustomer.TestField("Balance (LCY)", AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateBalancyLCYInMyVendorUT()
    var
        Vendor: Record Vendor;
        MyVendor: Record "My Vendor";
        AmountLCY: Decimal;
    begin
        // [FEATURE] [My Vendor] [UT]
        // [SCENARIO 211359] "Balance" in My Vendor should be calculated in local currency and have the opposite sign to the sum of detailed vendor ledger entries.
        Initialize();

        // [GIVEN] Vendor "VVV"
        CreateTestVendor(Vendor);
        CreateMyVendor(Vendor, GetCurrentUserID());

        // [GIVEN] Detailed Vendor Ledger Entry for Vendor "VVV" having -200 "Amount LCY" (negative).
        AmountLCY := -CreateDetailedVendorLedgEntry(Vendor."No.");

        // [WHEN] Calculate "Balance" of My Vendor for Vendor "VVV"
        MyVendor.Get(GetCurrentUserID(), Vendor."No.");
        MyVendor.CalcFields("Balance (LCY)");

        // [THEN] "Balance" shown on My Vendor page is 200 (positive sign, same as on Vendor List page).
        MyVendor.TestField("Balance (LCY)", AmountLCY);
    end;

    local procedure Initialize()
    var
        MyCustomer: Record "My Customer";
        MyItem: Record "My Item";
        MyVendor: Record "My Vendor";
        MyAccount: Record "My Account";
    begin
        MyCustomer.DeleteAll();
        MyVendor.DeleteAll();
        MyItem.DeleteAll();
        MyAccount.DeleteAll();

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateDetailedCustLedgEntry(CustomerNo: Code[20]): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    local procedure CreateDetailedVendorLedgEntry(VendorNo: Code[20]): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Amount (LCY)" := -LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry.Insert();
        exit(DetailedVendorLedgEntry."Amount (LCY)");
    end;

    [Scope('OnPrem')]
    procedure CreateTestCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)), 1, MaxStrLen(Customer.Name));
        Customer."Phone No." :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer."Phone No.")), 1,
            LibraryRandom.RandIntInRange(100000000, 999999999));
        Customer.Insert(true);
    end;

    local procedure CreateMyCustomer(Customer: Record Customer; UserID: Text)
    var
        MyCustomer: Record "My Customer";
    begin
        MyCustomer.Init();
        MyCustomer.Validate("Customer No.", Customer."No.");
        MyCustomer."User ID" := CopyStr(UserID, 1, MaxStrLen(MyCustomer."User ID"));
        MyCustomer.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTestVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        Vendor."Phone No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."Phone No.")), 1,
            LibraryRandom.RandIntInRange(100000000, 999999999));
        Vendor.Insert(true);
    end;

    local procedure CreateMyVendor(Vendor: Record Vendor; UserID: Text)
    var
        MyVendor: Record "My Vendor";
    begin
        MyVendor.Init();
        MyVendor.Validate("Vendor No.", Vendor."No.");
        MyVendor."User ID" := CopyStr(UserID, 1, MaxStrLen(MyVendor."User ID"));
        MyVendor.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTestItem(var Item: Record Item)
    begin
        Item.Init();
        Item.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)), 1, MaxStrLen(Item.Description));
        Item."Unit Price" := LibraryRandom.RandDec(100, 1);
        Item.Insert(true);
    end;

    local procedure CreateMyItem(Item: Record Item; UserID: Text)
    var
        MyItem: Record "My Item";
    begin
        MyItem.Init();
        MyItem.Validate("Item No.", Item."No.");
        MyItem."User ID" := CopyStr(UserID, 1, MaxStrLen(MyItem."User ID"));
        MyItem.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateTestAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLAccount.Name)), 1, MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
    end;

    local procedure CreateMyAccount(GLAccount: Record "G/L Account"; UserID: Text)
    var
        MyAccount: Record "My Account";
    begin
        MyAccount.Init();
        MyAccount.Validate("Account No.", GLAccount."No.");
        MyAccount."User ID" := CopyStr(UserID, 1, MaxStrLen(MyAccount."User ID"));
        MyAccount.Insert(true);
    end;

    local procedure GetCurrentUserID(): Text
    var
        MyItem: Record "My Item";
    begin
        exit(CopyStr(UserId, 1, MaxStrLen(MyItem."User ID")));
    end;

    local procedure VerifyCustomerChangesPropagatedToMyCustomers(var Customer: Record Customer)
    var
        MyCustomer: Record "My Customer";
    begin
        MyCustomer.SetRange("Customer No.", Customer."No.");
        MyCustomer.SetRange("User ID", UserId);
        MyCustomer.FindSet();

        repeat
            VerifyCustomerMatchesMyCustomerOnPage(Customer, MyCustomer);
        until MyCustomer.Next() = 0;
    end;

    local procedure VerifyVendorChangesPropagatedToMyVendors(var Vendor: Record Vendor)
    var
        MyVendor: Record "My Vendor";
    begin
        MyVendor.SetRange("Vendor No.", Vendor."No.");
        MyVendor.SetRange("User ID", UserId);
        MyVendor.FindSet();

        repeat
            VerifyVendorMatchesMyVendorOnPage(Vendor, MyVendor);
        until MyVendor.Next() = 0;
    end;

    local procedure VerifyItemChangesPropagatedToMyItems(var Item: Record Item)
    var
        MyItem: Record "My Item";
    begin
        MyItem.SetRange("Item No.", Item."No.");
        MyItem.SetRange("User ID", UserId);
        MyItem.FindSet();

        repeat
            VerifyItemMatchesMyItemOnPage(Item, MyItem);
        until MyItem.Next() = 0;
    end;

    local procedure VerifyAccountChangesPropagatedToMyAccounts(var GLAccount: Record "G/L Account")
    var
        MyAccount: Record "My Account";
    begin
        MyAccount.SetRange("Account No.", GLAccount."No.");
        MyAccount.SetRange("User ID", UserId);
        MyAccount.FindSet();

        repeat
            VerifyAccountMatchesMyAccountOnPage(GLAccount, MyAccount);
        until MyAccount.Next() = 0;
    end;

    local procedure VerifyCustomerMatchesMyCustomer(var Customer: Record Customer; var MyCustomer: Record "My Customer")
    begin
        Assert.AreEqual(Customer."No.", MyCustomer."Customer No.", '"No." does not match');
        Assert.AreEqual(Customer.Name, MyCustomer.Name, 'Name does not match');
        Assert.AreEqual(Customer."Phone No.", MyCustomer."Phone No.", '"Phone No." does not match');
    end;

    local procedure VerifyCustomerMatchesMyCustomerOnPage(var Customer: Record Customer; var MyCustomer: Record "My Customer")
    var
        MyCustomers: TestPage "My Customers";
    begin
        MyCustomers.OpenView();
        MyCustomers.GotoRecord(MyCustomer);
        MyCustomers."Customer No.".AssertEquals(Customer."No.");
        MyCustomers.Name.AssertEquals(Customer.Name);
        MyCustomers."Phone No.".AssertEquals(Customer."Phone No.");
    end;

    local procedure VerifyVendorMatchesMyVendor(var Vendor: Record Vendor; var MyVendor: Record "My Vendor")
    begin
        Assert.AreEqual(Vendor."No.", MyVendor."Vendor No.", '"No." does not match');
        Assert.AreEqual(Vendor.Name, MyVendor.Name, 'Name does not match');
        Assert.AreEqual(Vendor."Phone No.", MyVendor."Phone No.", '"Phone No." does not match');
    end;

    local procedure VerifyVendorMatchesMyVendorOnPage(var Vendor: Record Vendor; var MyVendor: Record "My Vendor")
    var
        MyVendors: TestPage "My Vendors";
    begin
        MyVendors.OpenView();
        MyVendors.GotoRecord(MyVendor);
        MyVendors."Vendor No.".AssertEquals(Vendor."No.");
        MyVendors.Name.AssertEquals(Vendor.Name);
        MyVendors."Phone No.".AssertEquals(Vendor."Phone No.");
    end;

    local procedure VerifyItemMatchesMyItem(var Item: Record Item; var MyItem: Record "My Item")
    begin
        Assert.AreEqual(Item."No.", MyItem."Item No.", '"No." does not match');
        Assert.AreEqual(Item.Description, MyItem.Description, 'Description does not match');
        Assert.AreEqual(Item."Unit Price", MyItem."Unit Price", '"Unit Price" does not match');
    end;

    local procedure VerifyItemMatchesMyItemOnPage(var Item: Record Item; var MyItem: Record "My Item")
    var
        MyItems: TestPage "My Items";
    begin
        MyItems.OpenView();
        MyItems.GotoRecord(MyItem);
        MyItems."Item No.".AssertEquals(Item."No.");
        MyItems.Description.AssertEquals(Item.Description);
        MyItems."Unit Price".AssertEquals(Item."Unit Price");
    end;

    local procedure VerifyAccountMatchesMyAccount(var GLAccount: Record "G/L Account"; var MyAccount: Record "My Account")
    begin
        Assert.AreEqual(GLAccount."No.", MyAccount."Account No.", '"No." does not match');
        Assert.AreEqual(GLAccount.Name, MyAccount.Name, 'Name does not match');
    end;

    local procedure VerifyAccountMatchesMyAccountOnPage(var GLAccount: Record "G/L Account"; var MyAccount: Record "My Account")
    var
        MyAccounts: TestPage "My Accounts";
    begin
        MyAccounts.OpenView();
        MyAccounts.GotoRecord(MyAccount);
        MyAccounts."Account No.".AssertEquals(GLAccount."No.");
        MyAccounts.Name.AssertEquals(GLAccount.Name);
    end;
}

