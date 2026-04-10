codeunit 134232 "ERM Prepare Journal"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [Prepare Journal]
        IsInitialized := false;
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepare Journal");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepare Journal");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepare Journal");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PrepareGLAccountsOpeningBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare G/L Accounts Opening Balance generates Gen. Journal Line for G/L Account
        // [GIVEN] Direct Posting GL Account, General Journal Template and General Journal Batch
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > G/L Accounts Opening balance
        LibraryLowerPermissions.SetJournalsEdit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."G/L Accounts Opening balance ".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and generates General Journal Line
        GenJournalLine.SetFilter("Account No.", GLAccount."No.");
        GenJournalLine.FindFirst();
        GeneralJournal.GotoRecord(GenJournalLine);
        Assert.AreEqual(Format(GeneralJournal."Account No."), GLAccount."No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountNotDirectPostingOpeningBalanceNotCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare G/L Accounts Opening Balance
        // doesn't generate Gen. Journal Line for Not-Direct Posting G/L Account
        // [GIVEN] Not-Direct Posting GL Account, General Journal Template and Gen. Journal Batch
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > G/L Accounts Opening balance
        LibraryLowerPermissions.SetJournalsEdit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."G/L Accounts Opening balance ".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and General Journal Line is not generated
        GenJournalLine.SetFilter("Account No.", GLAccount."No.");
        Assert.IsFalse(GenJournalLine.FindFirst(), 'General Journal Line is prepared for Not-Direct Posting G/L Account.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PrepareCreateCustomerOpeningBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare Customers Opening Balance generates Gen. Journal Line for Customer
        // [GIVEN] Customer, General Journal Template and Gen Journal Batch
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Customers Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Customers Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and generates General Journal Line
        GenJournalLine.SetFilter("Account No.", Customer."No.");
        GenJournalLine.FindFirst();
        GeneralJournal.GotoRecord(GenJournalLine);
        Assert.AreEqual(Format(GeneralJournal."Account No."), Customer."No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBlockedOpeningBalanceNotCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare Customers Opening Balance
        // doesn't generate Gen. Journal Line for blocked Customer
        // [GIVEN] Blocked Customer, General Journal Template and Gen Journal Batch
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Customers Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Customers Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and General Journal Line is not generated
        GenJournalLine.SetFilter("Account No.", Customer."No.");
        Assert.IsFalse(GenJournalLine.FindFirst(), 'General Journal Line is prepared for blocked Customer.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PrepareCreateVendorOpeningBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare Vendor Opening Balance generates Gen. Journal Line for Vendor
        // [GIVEN] Vendor, General Journal Template and Gen Journal Batch
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Vendor Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Vendors Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and generates General Journal Line
        GenJournalLine.SetFilter("Account No.", Vendor."No.");
        GenJournalLine.FindFirst();
        GeneralJournal.GotoRecord(GenJournalLine);
        Assert.AreEqual(Format(GeneralJournal."Account No."), Vendor."No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorBlockedOpeningBalanceNotCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Test verifies that Prepare Vendor Opening Balance
        // doesn't generate Gen. Journal Line for blocked Vendor
        // [GIVEN] Blocked Vendor, General Journal Template and Gen Journal Batch
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Vendor Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Vendors Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and General Journal Line is not generated
        GenJournalLine.SetFilter("Account No.", Vendor."No.");
        Assert.IsFalse(GenJournalLine.FindFirst(), 'General Journal Line is prepared for blocked Vendor.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPrivacyBlockedAllOpeningBalanceNotCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        Initialize();
        // [SCENARIO] Test verifies that Prepare Customers Opening Balance
        // doesn't generate Gen. Journal Line for blocked Customer
        // [GIVEN] PrivacyBlocked Customer, General Journal Template and Gen Journal Batch
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Customers Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Customers Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and General Journal Line is not generated
        GenJournalLine.SetFilter("Account No.", Customer."No.");
        Assert.IsFalse(GenJournalLine.FindFirst(), 'General Journal Line is prepared for PrivacyBlocked Customer.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPrivacyBlockedAllOpeningBalanceNotCreated()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        Initialize();
        // [SCENARIO] Test verifies that Prepare Vendor Opening Balance
        // doesn't generate Gen. Journal Line for blocked Vendor
        // [GIVEN] PrivacyBlocked Vendor, General Journal Template and Gen Journal Batch
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify(true);
        CreateGeneralJournalBatch(GenJournalBatch);

        // [WHEN] Run Prepare Journal > Prepare Vendor Opening Balance
        LibraryLowerPermissions.SetOutsideO365Scope();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Vendors Opening balance".Invoke();

        // [THEN] System runs Create G/L Acc. Journal Lines report and General Journal Line is not generated
        GenJournalLine.SetFilter("Account No.", Vendor."No.");
        Assert.IsFalse(GenJournalLine.FindFirst(), 'General Journal Line is prepared for PrivacyBlocked Vendor.');
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOpeningBalanceUsesCorrectPostingDateInSimpleMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GenJournalTemplate: Record "Gen. Journal Template";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      CurrentPostingDate: Date;
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "G/L Accounts Opening balance " on General Journal page uses CurrentPostingDate in Simple mode.
      Initialize();

      // [GIVEN] General Journal in Simple mode.
      GenJnlManagement.SetJournalSimplePageModePreference(true,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
      LibraryERM.CreateGenJournalBatch(GenJournalBatch,GenJournalTemplate.Name);
      LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [GIVEN] Current Posting Date is set to "X".
      CurrentPostingDate := WorkDate() + LibraryRandom.RandInt(10);
      GeneralJournal."<CurrentPostingDate>".SetValue(CurrentPostingDate);

      // [WHEN] "G/L Accounts Opening balance " is invoked.
      GeneralJournal."G/L Accounts Opening balance ".Invoke();

      // [THEN] Created General journal line has Posting Date equal to "X".
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(CurrentPostingDate,PostingDate,'');
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLAccountsOpeningBalanceUsesCorrectPostingDateInClassicMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GenJournalTemplate: Record "Gen. Journal Template";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "G/L Accounts Opening balance " on General Journal page uses WorkDate() in Classic mode.
      Initialize();

      // [GIVEN] General Journal in Classic mode.
      GenJnlManagement.SetJournalSimplePageModePreference(false,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
      LibraryERM.CreateGenJournalBatch(GenJournalBatch,GenJournalTemplate.Name);
      LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [WHEN] "G/L Accounts Opening balance " is invoked.
      GeneralJournal."G/L Accounts Opening balance ".Invoke();

      // [THEN] Created General journal line has Posting Date equal to WorkDate().
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(WorkDate(),PostingDate,'');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomersOpeningBalanceUsesCorrectPostingDateInSimpleMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      CurrentPostingDate: Date;
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "Customers Opening balance " on General Journal page uses CurrentPostingDate in Simple mode.
      Initialize();

      // [GIVEN] General Journal in Simple mode.
      GenJnlManagement.SetJournalSimplePageModePreference(true,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      CreateGeneralJournalBatch(GenJournalBatch);
      LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [GIVEN] Current Posting Date is set to "X".
      CurrentPostingDate := WorkDate() + LibraryRandom.RandInt(10);
      GeneralJournal."<CurrentPostingDate>".SetValue(CurrentPostingDate);

      // [WHEN] "Customers Opening balance " is invoked.
      GeneralJournal."Customers Opening balance".Invoke();

      // [THEN] Created General journal line has Posting Date equal to "X".
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(CurrentPostingDate,PostingDate,'');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomersOpeningBalanceUsesCorrectPostingDateInClassicMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "Customers Opening balance " on General Journal page uses WorkDate() in Classic mode.
      Initialize();

      // [GIVEN] General Journal in Classic mode.
      GenJnlManagement.SetJournalSimplePageModePreference(false,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      CreateGeneralJournalBatch(GenJournalBatch);
      LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [WHEN] "Customers Opening balance " is invoked.
      GeneralJournal."Customers Opening balance".Invoke();

      // [THEN] Created General journal line has Posting Date equal to WorkDate().
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(WorkDate(),PostingDate,'');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorsOpeningBalanceUsesCorrectPostingDateInSimpleMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      CurrentPostingDate: Date;
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "Vendors Opening balance " on General Journal page uses CurrentPostingDate in Simple mode.
      Initialize();

      // [GIVEN] General Journal in Simple mode.
      GenJnlManagement.SetJournalSimplePageModePreference(true,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      CreateGeneralJournalBatch(GenJournalBatch);
      LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [GIVEN] Current Posting Date is set to "X".
      CurrentPostingDate := WorkDate() + LibraryRandom.RandInt(10);
      GeneralJournal."<CurrentPostingDate>".SetValue(CurrentPostingDate);

      // [WHEN] "Vendors Opening balance" is invoked.
      GeneralJournal."Vendors Opening balance".Invoke();

      // [THEN] Created General journal line has Posting Date equal to "X".
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(CurrentPostingDate,PostingDate,'');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorsOpeningBalanceUsesCorrectPostingDateInClassicMode()
    var
      GenJournalBatch: Record "Gen. Journal Batch";
      GeneralJournal: TestPage "General Journal";
      GenJnlManagement: Codeunit "GenJnlManagement";
      PostingDate: Date;
    begin
      // [SCENARIO 341562] Action "Vendors Opening balance " on General Journal page uses WorkDate() in Classic mode.
      Initialize();

      // [GIVEN] General Journal in Classic mode.
      GenJnlManagement.SetJournalSimplePageModePreference(false,PAGE::"General Journal");

      // [GIVEN] Empty journal opened on General Journal page.
      CreateGeneralJournalBatch(GenJournalBatch);
      LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
      GeneralJournal.OpenEdit();
      GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

      // [WHEN] "Vendors Opening balance" is invoked.
      GeneralJournal."Vendors Opening balance".Invoke();

      // [THEN] Created General journal line has Posting Date equal to WorkDate().
      GeneralJournal.First();
      EVALUATE(PostingDate,GeneralJournal."Posting Date".Value);
      Assert.AreEqual(WorkDate(),PostingDate,'');
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
      GeneralJournalTemplateList.FILTER.SetFilter(Name,LibraryVariableStorage.DequeueText());
      GeneralJournalTemplateList.OK().Invoke();
    end;
}

