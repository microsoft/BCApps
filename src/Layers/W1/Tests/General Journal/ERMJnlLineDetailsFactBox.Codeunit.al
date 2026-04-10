codeunit 134925 "ERM Jnl. Line Details Factbox"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Details Factbox]
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSetupFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] Journal details factbox shows general and VAT posting setup for account on General Journal Page
        Initialize();

        // [GIVEN] G/L account "A" with VAT posting setup "VATSETUP" and name = "AAA"
        CreateGLAccountWithVATPostingSetup(GLAccount, VATPostingSetup);

        // [GIVEN] Create journal line for new batch "XXX" with G/L account = "A"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              GLAccount."No.", 0);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Account related fields enabled
        Assert.IsTrue(GeneralJournal.JournalLineDetails.AccountName.Enabled(), 'Account Name must be enabled');
        Assert.IsTrue(GeneralJournal.JournalLineDetails.GenPostingSetup.Enabled(), 'General Posting Setup must be enabled');
        Assert.IsTrue(GeneralJournal.JournalLineDetails.VATPostingSetup.Enabled(), 'VAT Posting Setup must be enabled');

        // [THEN] Journal details factbox has Account Name = "AAA", VAT Posting Setup
        GeneralJournal.JournalLineDetails.AccountName.AssertEquals(GLAccount.Name);
        GeneralJournal.JournalLineDetails.GenPostingSetup.AssertEquals(
             GLAccount."Gen. Bus. Posting Group" + ', ' + GLAccount."Gen. Prod. Posting Group");
        GeneralJournal.JournalLineDetails.VATPostingSetup.AssertEquals(
             GLAccount."VAT Bus. Posting Group" + ', ' + GLAccount."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalAccountSetupFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] Journal details factbox shows general and VAT posting setup for balance account on General Journal Page
        Initialize();

        // [GIVEN] G/L account "A" with VAT posting setup "VATSETUP" and name = "AAA"
        CreateGLAccountWithVATPostingSetup(GLAccount, VATPostingSetup);

        // [GIVEN] Create journal line for new batch "XXX" with balance G/L account = "A"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", 0);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Bal. Account related fields enabled
        Assert.IsTrue(GeneralJournal.JournalLineDetails.BalAccountName.Enabled(), 'Bal. Account Name must be enabled');
        Assert.IsTrue(GeneralJournal.JournalLineDetails.BalGenPostingSetup.Enabled(), 'Bal. General Posting Setup must be enabled');
        Assert.IsTrue(GeneralJournal.JournalLineDetails.BalVATPostingSetup.Enabled(), 'Bal. VAT Posting Setup must be enabled');

        // [THEN] Journal details factbox has Account Name = "AAA", VAT Posting Setup
        GeneralJournal.JournalLineDetails.BalAccountName.AssertEquals(GLAccount.Name);
        GeneralJournal.JournalLineDetails.BalGenPostingSetup.AssertEquals(
             GLAccount."Gen. Bus. Posting Group" + ', ' + GLAccount."Gen. Prod. Posting Group");
        GeneralJournal.JournalLineDetails.BalVATPostingSetup.AssertEquals(
             GLAccount."VAT Bus. Posting Group" + ', ' + GLAccount."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountPostingGroup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] Journal details factbox shows Posting Group for account on General Journal Page
        Initialize();

        // [GIVEN] Customer "CUST" with customer posting group "CPG"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create journal line for new batch "XXX" with customer account = "CUST"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
              Customer."No.", 0);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Journal details factbox has Posting Group = "CPG"
        GeneralJournal.JournalLineDetails.PostingGroup.AssertEquals(Customer."Customer Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalAccountPostingGroup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] Journal details factbox shows Posting Group for balance account on General Journal Page
        Initialize();

        // [GIVEN] Vendor "VEND" with vendor posting group "VPG"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create journal line for new batch "XXX" with Vendor balance account = "VEND"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Account Type"::Vendor, Vendor."No.", 0);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Journal details factbox has Posting Group = "VPG"
        GeneralJournal.JournalLineDetails.PostingGroup.AssertEquals(Vendor."Vendor Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownAccountName()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GeneralJournal: TestPage "General Journal";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] DrillDown from account name opens account card
        Initialize();

        // [GIVEN] Customer "CUST" 
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create journal line for new batch "XXX" with customer account = "CUST"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
              Customer."No.", 0);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [WHEN] DrillDown for account name
        CustomerCard.Trap();
        GeneralJournal.JournalLineDetails.AccountName.Drilldown();

        // [THEN] Customer card page opened with customer "CUST"
        CustomerCard."No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownBalanceAccountName()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        GeneralJournal: TestPage "General Journal";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] DrillDown from balance account name opens account card
        Initialize();

        // [GIVEN] Vendor "VEND" 
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create journal line for new batch "XXX" with Vendor balance account = "VEND"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Account Type"::Vendor, Vendor."No.", 0);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [WHEN] DrillDown for balance account name
        VendorCard.Trap();
        GeneralJournal.JournalLineDetails.BalAccountName.Drilldown();

        // [THEN] Vendor card page opened with vendor "VEND"
        VendorCard."No.".AssertEquals(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownAccountSetupFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
        GeneralPostingSetupCard: TestPage "General Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] DrillDown for account General/VAT posting setup fields opens appropriate setup card page 
        Initialize();

        // [GIVEN] G/L account "A" with VAT posting setup "VATSETUP" and name = "AAA"
        CreateGLAccountWithVATPostingSetup(GLAccount, VATPostingSetup);

        // [GIVEN] Create journal line for new batch "XXX" with G/L account = "A"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              GLAccount."No.", 0);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [WHEN] DrillDown for General Posting Setup for account part
        GeneralPostingSetupCard.Trap();
        GeneralJournal.JournalLineDetails.GenPostingSetup.Drilldown();
        // [THEN] General Posting Setup page opened with posting setup for acctoun "A"
        GeneralPostingSetupCard."Gen. Bus. Posting Group".AssertEquals(GLAccount."Gen. Bus. Posting Group");
        GeneralPostingSetupCard."Gen. Prod. Posting Group".AssertEquals(GLAccount."Gen. Prod. Posting Group");

        // [WHEN] DrillDown for VAT Posting Setup for account part
        VATPostingSetupCard.Trap();
        GeneralJournal.JournalLineDetails.VATPostingSetup.Drilldown();
        // [THEN] VAT Posting Setup page opened with VAT setup "VATSETUP"
        VATPostingSetupCard."VAT Bus. Posting Group".AssertEquals(GLAccount."VAT Bus. Posting Group");
        VATPostingSetupCard."VAT Prod. Posting Group".AssertEquals(GLAccount."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownBalanceAccountSetupFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
        GeneralPostingSetupCard: TestPage "General Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup";
    begin
        // [FEATURE] 
        // [SCENARIO 355640] DrillDown for balance account General/VAT posting setup fields opens appropriate setup card page 
        Initialize();

        // [GIVEN] G/L account "A" with VAT posting setup "VATSETUP" and name = "AAA"
        CreateGLAccountWithVATPostingSetup(GLAccount, VATPostingSetup);

        // [GIVEN] Create journal line for new batch "XXX" with balance G/L account = "A"
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", 0);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [WHEN] DrillDown for General Posting Setup of balance account part
        GeneralPostingSetupCard.Trap();
        GeneralJournal.JournalLineDetails.BalGenPostingSetup.Drilldown();
        // [THEN] General Posting Setup page opened with posting setup for acctoun "A"
        GeneralPostingSetupCard."Gen. Bus. Posting Group".AssertEquals(GLAccount."Gen. Bus. Posting Group");
        GeneralPostingSetupCard."Gen. Prod. Posting Group".AssertEquals(GLAccount."Gen. Prod. Posting Group");

        // [WHEN] DrillDown for VAT Posting Setup of balance account part
        VATPostingSetupCard.Trap();
        GeneralJournal.JournalLineDetails.BalVATPostingSetup.Drilldown();
        // [THEN] VAT Posting Setup page opened with VAT setup "VATSETUP"
        VATPostingSetupCard."VAT Bus. Posting Group".AssertEquals(GLAccount."VAT Bus. Posting Group");
        VATPostingSetupCard."VAT Prod. Posting Group".AssertEquals(GLAccount."VAT Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalAccountSetupFieldsDisabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 364032] Bal. Account related factbox fields are disabled in case of empty Bal. Account No.
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty Bal. Account
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNo(), 0);
        GenJournalLine.TestField("Bal. Account No.", '');
        GenJournalLine.TestField("Bal. Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Bal. Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("Bal. VAT Bus. Posting Group", '');
        GenJournalLine.TestField("Bal. VAT Prod. Posting Group", '');

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Bal. Account related fields disabled
        Assert.IsFalse(GeneralJournal.JournalLineDetails.BalAccountName.Enabled(), 'Bal. Account Name must be disabled');
        Assert.IsFalse(GeneralJournal.JournalLineDetails.BalGenPostingSetup.Enabled(), 'Bal. General Posting Setup must be disabled');
        Assert.IsFalse(GeneralJournal.JournalLineDetails.BalVATPostingSetup.Enabled(), 'Bal. VAT Posting Setup must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountSetupFieldsDisabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] 
        // [SCENARIO 364032] Account related factbox fields are disabled in case of empty Account No.
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty Account No.
        PrepareJournalBatch(GenJournalLine);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
              GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", '',
              GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
        GenJournalLine.TestField("Account No.", '');
        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] Account related fields disabled
        Assert.IsFalse(GeneralJournal.JournalLineDetails.AccountName.Enabled(), 'Account Name must be disabled');
        Assert.IsFalse(GeneralJournal.JournalLineDetails.GenPostingSetup.Enabled(), 'General Posting Setup must be disabled');
        Assert.IsFalse(GeneralJournal.JournalLineDetails.VATPostingSetup.Enabled(), 'VAT Posting Setup must be disabled');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    local procedure PrepareJournalBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var GLAccount: Record "G/L Account"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;
}