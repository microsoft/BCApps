codeunit 134226 "ERM TestMultipleGenJnlLines"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        GenJournalTemplateErr: Label 'Gen. Journal Template name is blank.';
        GenJournalBatchErr: Label 'Gen. Journal Batch name is blank.';
        OutOfBalanceErr: Label 'is out of balance';
        ConfirmManualCheckTxt: Label 'A balancing account is not specified for one or more lines. If you print checks without specifying balancing accounts you will not be able to void the checks, if needed. Do you want to continue?';
        WrongDocNoErr: Label 'Document should be other than old document no. : %1', Comment = '%1 - Document no.';
        LastDocNoAndLastNoUsedMustMatchErr: Label 'Last Document No and Last No Used must match.';
        GLEntryMustBeFoundErr: Label 'GL Entry must be found.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGLAccounts()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        NoOfDrLines: Integer;
        NoOfCrLines: Integer;
        DebitAmt: Decimal;
        CreditAmt: Decimal;
    begin
        // Test Covers TFS_TS_ID: 111510:Test suite: Create and post a G/L Journal.
        // 1. Create multiple General Journal Lines for debit and credit amounts, Add boundary value two to make sure that the number of
        // lines generated are always greater than two.
        // 2. Post the General Journal Lines.
        // 3. Verify that the count of posted entries is equal to the sum of debit and credit lines.

        // Setup: Create Multiple General Journal Lines of Debit and Credit Amounts. Taking Random Amount in multiplication of 4 to generate even amount and avoid rounding issue.
        Initialize();
        DebitAmt := LibraryRandom.RandInt(1000) * 4;
        NoOfDrLines := 2 * LibraryRandom.RandInt(3);
        SelectAndClearGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, NoOfDrLines, DebitAmt);

        NoOfCrLines := 2 * LibraryRandom.RandInt(3);
        CreditAmt := -DebitAmt * NoOfDrLines / NoOfCrLines;
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, NoOfCrLines, CreditAmt);

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify the count of posted GL Entries with total number of lines entered for debit and credit amount.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        Assert.AreEqual(GLEntry.Count, NoOfDrLines + NoOfCrLines, 'An incorrect number of lines was posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
    begin
        // Test error occurs on running Create Customer Journal Lines Report without General Journal Template.

        // 1. Setup: Create General Journal Batch and Find Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // 2. Exercise: Run Create Customer Journal Lines Report without General Journal Template.
        asserterror RunCreateCustomerJournalLines(Customer, '', GenJournalBatch.Name, StandardGeneralJournal.Code, '');

        // 3. Verify: Verify error occurs on running Create Customer Journal Lines Report without General Journal Template.
        Assert.ExpectedError(StrSubstNo(GenJournalTemplateErr));

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
    begin
        // Test error occurs on running Create Customer Journal Lines Report without General Batch Name.

        // 1. Setup: Create General Journal Batch and Find Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // 2. Exercise: Run Create Customer Journal Lines Report without General Batch Name.
        asserterror RunCreateCustomerJournalLines(Customer, GenJournalBatch."Journal Template Name", '', StandardGeneralJournal.Code, '');

        // 3. Verify: Verify error occurs on running Create Customer Journal Lines Report without General Batch Name.
        Assert.ExpectedError(StrSubstNo(GenJournalBatchErr));

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLineBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test General Journal Lines are created for Customer after running Create Customer Journal Lines Report.

        // 1. Setup: Create Customer and General Journal Batch. Find Standard General Journal.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // Use Random Values for number of lines and amount.
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(5), LibraryRandom.RandDec(100, 2));
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // 2. Exercise: Run Create Customer Journal Lines Report.
        Customer.SetRange("No.", Customer."No.");
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, StandardGeneralJournal.Code, '');

        // 3. Verify: Verify General Journal Lines are created for Customer after running Create Customer Journal Lines Report.
        VerifyCustomerJournalLines(GenJournalBatch, StandardGeneralJournal.Code, Customer."No.");

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,GeneralJournalTemplateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalPostWithNo()
    var
        GLEntry: Record "G/L Entry";
        GeneralJournal: TestPage "General Journal";
        LastGLEntryNo: Integer;
    begin
        // Create General Journal line, Post with NO and Verify Entry No of G/L Entry has not increased.

        // 1. Setup: Find Last G/L Entry No.
        Initialize();
        LastGLEntryNo := GetLastGLEntryNumber();

        // Create General Journal Line.
        CreateGeneralJournalLineByPage(GeneralJournal);

        // 2. Exercise: Post General Journal Line.
        GeneralJournal.Post.Invoke();

        // 3. Verify: Check Entry No. of G/L Entry must not be increased.
        GLEntry.FindLast();
        GLEntry.TestField("Entry No.", LastGLEntryNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalPostWithYes()
    var
        GLEntry: Record "G/L Entry";
        GeneralJournal: TestPage "General Journal";
        LastGLEntryNo: Integer;
    begin
        // Create General Journal line, Post with YES and Verify Entry No of G/L Entry has increased.

        // 1. Setup: Find Last G/L Entry No.
        Initialize();
        LastGLEntryNo := GetLastGLEntryNumber();

        // Create General Journal Line.
        CreateGeneralJournalLineByPage(GeneralJournal);

        // 2. Exercise: Post General Journal Line.
        GeneralJournal.Post.Invoke();

        // 3. Verify: Check Entry No. of G/L Entry must not be increased.
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        GLEntry.FindFirst();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalWithBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        // Verify General Journal Batch Name on General Journal Page with Number Series.

        // 1. Setup: Create General Journal Batch with Number Series.
        Initialize();
        CreateGeneralBatchWithNoSeries(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        // 2. Exercise: Open General Journal Page with new Template.
        Commit();  // COMMIT needs before create General Journal.
        GeneralJournal.OpenEdit();  // Template selection performed in General Journal Template Handler.

        // 3. Verify: Verify General Journal Batch Name on General Journal Page
        GeneralJournal.CurrentJnlBatchName.AssertEquals(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalWithBalAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        DocumentNo: Code[20];
    begin
        // Verify Balance Account on General Journal Page with Number Series.

        // 1. Setup: Create General Journal Batch with Number Series.
        Initialize();
        CreateGeneralBatchWithNoSeries(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        // 2. Exercise: Create and post General Line with Account Type as G/L Account and Random Amount.
        Commit();  // COMMIT needs before create General Journal.
        GeneralJournal.OpenEdit();  // Template selection performed in General Journal Template Handler.
        DocumentNo := GeneralJournal."Document No.".Value();
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Account No.".SetValue(LibraryERM.CreateGLAccountNo());
        UpdateAmountOnGenJournalLine(GenJournalBatch, GeneralJournal);
        GeneralJournal.Post.Invoke();

        // 3. Verify: Verify Balance Account on General Journal Page.
        VerifyBalanceAccountOnGLEntry(DocumentNo, GenJournalBatch."Bal. Account No.");

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithBalance()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post General Journal Line having Customer with Balance Account number and verify Customer number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Line and LibraryRandom used for generating Random Amount.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Purchase);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(10, 2));
        UpdateBalanceGLAccount(GenJournalLine, GLAccount."No.");

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry and G/L Register.
        VerifyVendorLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Vendor."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Vendor."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithoutBalance()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post General Journal Line having Customer without Balance Account number and verify Customer number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Lines and LibraryRandom used for generating Random Amount.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Purchase);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(10, 2));
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -GenJournalLine.Amount);

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry and G/L Register.
        VerifyVendorLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Vendor."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Vendor."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerWithBalance()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post General Journal Line having Vendor with Balance Account number and verify Vendor number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Lines and LibraryRandom used for generating Random Amount.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Sale);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(10, 2));
        UpdateBalanceGLAccount(GenJournalLine, GLAccount."No.");

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry and G/L Register.
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Customer."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Customer."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerWithoutBalance()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post General Journal Line having Vendor without Balance Account number and verify Vendor number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Lines and LibraryRandom used for generating Random Amount.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Sale);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(10, 2));
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -GenJournalLine.Amount);

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry and G/L Register.
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Customer."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Customer."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleVendor()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post multiple General Journal Lines including Customer withhout having Balance Account number and verify Vendor number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Lines and LibraryRandom used for generating Random Amount.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(Vendor2);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Purchase);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(10, 2));
        CreateGeneralJournal(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor2."No.", GenJournalLine.Amount);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -(2 * GenJournalLine.Amount));

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry and G/L Register.
        VerifyVendorLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Vendor."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Vendor."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and post multiple General Journal Lines including Customer withhout having Balance Account number and verify Customer number and G/L Entry after posting.

        // Setup: Create Customer, G/L Account and  General Journal Lines and LibraryRandom used for generating Random Amount.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);
        CreateAndUpdateGLAccount(GLAccount, GLAccount."Gen. Posting Type"::Sale);
        CreateBatchAndUpdateTemplate(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(10, 2));
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer2."No.", GenJournalLine.Amount);
        CreateGeneralJournal(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -(2 * GenJournalLine.Amount));

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry and G/L Register.
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", Customer."No.");
        VerifyVATEntries(GenJournalLine."Document No.", Customer."No.");
        VerifyGLRegister(GenJournalBatch.Name);

        // 4. Tear Down: Delete earlier created General Journal Template.
        DeleteGeneralJournalTemplate(GenJournalBatch."Journal Template Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalLineWithPostingNoSeriesError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Test that error occurs when General Journal Lines are posted with and without Posting No. Series.

        // Setup: Create two General Journal Lines with and without Posting No Series and Random Amount.
        Initialize();
        SelectAndClearGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithPostingNoSeries(
          GenJournalLine, GenJournalBatch, LibraryUtility.GetGlobalNoSeriesCode(), LibraryRandom.RandDec(100, 2));  // General Journal Line with Posting No Series.
        CreateGeneralJournalLineWithPostingNoSeries(GenJournalLine, GenJournalBatch, '', -GenJournalLine.Amount);  // General Journal Line without Posting No Series.

        // Exercise: Post General Journal Line. It should generate error.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Error Message.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Posting No. Series"), '''');
    end;

    [Test]
    [HandlerFunctions('StandardGeneralJournalHandler')]
    [Scope('OnPrem')]
    procedure CheckSourceCodeOnStandardGeneralJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Test that Source Code is automatically filled when Standard General Journal page is opened.

        // Setup: Create a new General Journal Batch and standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");

        // Exercise: Run Page Standard General Journal.
        PAGE.Run(PAGE::"Standard General Journal", StandardGeneralJournal);

        // Verify: Verify that the Source Code is filled same as in General Journal Batch created.
        FindStandardGeneralJournalLine(StandardGeneralJournalLine, GenJournalBatch."Journal Template Name", StandardGeneralJournal.Code);
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        StandardGeneralJournalLine.TestField("Source Code", GenJournalTemplate."Source Code");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLinesUsingNoSeries()
    var
        JournalBatchName: Code[10];
    begin
        // Test that General Journal Lines created using No. Series (contain different number of digits) can be posted successfully.

        // Setup: Create General Journal Lines using No. Series by General Journal Page."Document No." of the Journal Lines will contain different number of digits.
        // Exercise: Post General Journal.
        Initialize();
        JournalBatchName := CreateAndPostGeneralJournalLinesUsingNoSeriesByPage(LibraryRandom.RandIntInRange(10, 20));

        // Verify: Verify the General Journal had posted successfully to G/L Register.
        VerifyGLRegister(JournalBatchName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLinesBalancedByDateForceDocBalFalse()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNos: array[4] of Code[20];
    begin
        // [FEATURE] [Force Doc. Balance]
        // [SCENARIO 363317] Journal lines balanced by Posting Date but not balanced by Document No. can be posted when "Force Doc. Balance" is off.
        Initialize();

        // [GIVEN] Gen. Journal Batch/Template with "Force Doc. Balance" = FALSE.
        CreateGeneralJournalBatchTemplateForceDocBalance(GenJournalBatch, false);

        // [GIVEN] Gen. Journal Line: Document No. = DOC1, Posting Date = D, Amount = 100,
        // [GIVEN] Gen. Journal Line: Document No. = DOC4, Posting Date = D, Amount = -100,
        // [GIVEN] Gen. Journal Line: Document No. = DOC2, Posting Date = D + 1, Amount = 200,
        // [GIVEN] Gen. Journal Line: Document No. = DOC3, Posting Date = D + 1, Amount = -200,
        DocumentNos[1] := LibraryUtility.GenerateGUID();
        DocumentNos[3] := LibraryUtility.GenerateGUID();
        DocumentNos[4] := LibraryUtility.GenerateGUID();
        DocumentNos[2] := LibraryUtility.GenerateGUID();
        CreateGeneralJournalLineWithBalanceLine(
          GenJournalBatch, GenJournalLine, DocumentNos[1], DocumentNos[2], WorkDate());
        CreateGeneralJournalLineWithBalanceLine(
          GenJournalBatch, GenJournalLine, DocumentNos[3], DocumentNos[4], WorkDate() + 1);

        // [WHEN] General Journal Lines posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Gen. Journal Lines successfully posted
        VerifyGLRegister(GenJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLinesBalancedByDateForceDocBalTrue()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNos: array[4] of Code[20];
    begin
        // [FEATURE] [Force Doc. Balance]
        // [SCENARIO 363317] Journal lines balanced by Posting Date but not balanced by Document No. cannot be posted when "Force Doc. Balance" is on.
        Initialize();

        // [GIVEN] Gen. Journal Batch/Template with "Force Doc. Balance" = TRUE.
        CreateGeneralJournalBatchTemplateForceDocBalance(GenJournalBatch, true);

        // [GIVEN] Gen. Journal Line: Document No. = DOC1, Posting Date = D, Amount = 100,
        // [GIVEN] Gen. Journal Line: Document No. = DOC4, Posting Date = D, Amount = -100,
        // [GIVEN] Gen. Journal Line: Document No. = DOC2, Posting Date = D + 1, Amount = 200,
        // [GIVEN] Gen. Journal Line: Document No. = DOC3, Posting Date = D + 1, Amount = -200,
        DocumentNos[1] := LibraryUtility.GenerateGUID();
        DocumentNos[3] := LibraryUtility.GenerateGUID();
        DocumentNos[4] := LibraryUtility.GenerateGUID();
        DocumentNos[2] := LibraryUtility.GenerateGUID();
        CreateGeneralJournalLineWithBalanceLine(
          GenJournalBatch, GenJournalLine, DocumentNos[1], DocumentNos[2], WorkDate());
        CreateGeneralJournalLineWithBalanceLine(
          GenJournalBatch, GenJournalLine, DocumentNos[3], DocumentNos[4], WorkDate() + 1);

        // [WHEN] General Journal Lines posted
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "Document is out of balance" error message appears.
        Assert.ExpectedError(OutOfBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountChangeFieldOnGenJnlBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalTemplates: TestPage "General Journal Templates";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [FEATURE] [Suggest Balancing Amount] [UI]
        // [SCENARIO 167318] User should be able to set Suggest Balancing Amount on General Journal Batches page.
        Initialize();

        // [GIVEN] General Journal Batch "N"
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, false);

        GeneralJournalTemplates.OpenView();
        GeneralJournalTemplates.FILTER.SetFilter(Name, GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.Trap();
        GeneralJournalTemplates.Batches.Invoke();

        // [WHEN] Set "Suggest Balancing Amount" = TRUE on General Journal Batch "N" page
        GeneralJournalBatches."Suggest Balancing Amount".SetValue(true);
        GeneralJournalBatches.Close();
        GeneralJournalTemplates.Close();

        // [THEN] General Journal Batch "N" has "Suggest Balancing Amount" = TRUE
        GenJournalBatch.Find();
        GenJournalBatch.TestField("Suggest Balancing Amount", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountSequentialNosBelowLastLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        BalDocNo: Code[20];
        BalAmt1: Decimal;
        BalAmt2: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount for new line below Gen.Jnl.Lines where Document No. comes sequentially
        Initialize();

        // [GIVEN] "Suggest balancing amount" is TRUE on Journal Template
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10
        CreateSimpleGenJnlLine(
          GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2),
          LibraryUtility.GenerateGUID());

        // [GIVEN] Gen. Jnl. Line G0002 with Amount 20
        // [GIVEN] Gen. Jnl. Line G0002 with Amount 30
        BalAmt1 := LibraryRandom.RandDec(100, 2);
        BalAmt2 := LibraryRandom.RandDec(100, 2);
        BalDocNo := LibraryUtility.GenerateGUID();
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, BalAmt1, BalDocNo);
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, BalAmt2, BalDocNo);

        // [WHEN] SetupNewLine with BottomLine = True (below last line)
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        // [THEN] New line has initial Document No. = G0002 with Amount = -50.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt1 - BalAmt2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountMixedNosBelowLastLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
        BalDocNo: Code[20];
        BalAmt1: Decimal;
        BalAmt2: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount for new line below Gen.Jnl.Lines where Document No. is mixed between lines.
        Initialize();

        // [GIVEN] "Suggest balancing amount" is TRUE on Journal Template
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        DocNo := LibraryUtility.GenerateGUID();
        BalDocNo := LibraryUtility.GenerateGUID();
        BalAmt1 := LibraryRandom.RandDec(100, 2);
        BalAmt2 := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, BalAmt1, BalDocNo);
        // [GIVEN] Gen. Jnl. Line G0002 with Amount 20
        // [GIVEN] Gen. Jnl. Line G0002 with Amount 30
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), DocNo);
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), DocNo);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 40
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, BalAmt2, BalDocNo);

        // [WHEN] SetupNewLine with BottomLine = True (below last line)
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        // [THEN] New line has initial Document No. = G0002 with Amount = -50.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt1 - BalAmt2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountSequentialNosAboveLastLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        BalDocNo: Code[20];
        BalAmt: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount for new line above last line of Gen.Jnl.Lines where Document No. comes sequentially
        Initialize();

        // [GIVEN] "Suggest balancing amount" is TRUE on Journal Template
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10
        CreateSimpleGenJnlLine(
          GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2),
          LibraryUtility.GenerateGUID());

        // [GIVEN] Gen. Jnl. Line G0002 with Amount 20
        // [GIVEN] Gen. Jnl. Line G0002 with Amount 30
        BalAmt := LibraryRandom.RandDec(100, 2);
        BalDocNo := LibraryUtility.GenerateGUID();
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, BalAmt, BalDocNo);
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), BalDocNo);

        // [WHEN] SetupNewLine with BottomLine = False (above last line)
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, false);

        // [THEN] New line has initial Document No. = G0002 with Amount = -20.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountBetweenLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        BalDocNo: Code[20];
        BalAmt: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount between Gen.Jnl.Lines with different Document Nos
        Initialize();

        // [GIVEN] "Suggest balancing amount" is TRUE on Gen.Journal Batch
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        BalDocNo := LibraryUtility.GenerateGUID();
        BalAmt := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, BalAmt, BalDocNo);
        // [GIVEN] Gen. Jnl. Line G0002 with Amount 20
        // [GIVEN] Gen. Jnl. Line G0003 with Amount 30
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), LibraryUtility.GenerateGUID());
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), LibraryUtility.GenerateGUID());

        // [WHEN] SetupNewLine with BottomLine = False on G0002 (between G0001 and G0002)
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, false);

        // [THEN] New line has initial Document No. = G0001 with Amount = -10.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountWithAlreadyBalancedLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        BalDocNo: Code[20];
        BalAmt: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount for Gen.Jnl.Lines with already balanced line
        // [GIVEN] "Suggest balancing amount" is TRUE on Gen.Journal Batch
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        BalDocNo := LibraryUtility.GenerateGUID();
        BalAmt := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10 with "Bal. Account No." = 2910
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), BalDocNo);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        // [GIVEN] Gen. Jnl. Line G0001 with Amount 20
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, BalAmt, BalDocNo);

        // [WHEN] Add new line below last line
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        // [THEN] New line has initial Document No. = G0001 with Amount = -20.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountWithDifferentPostingDates()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        BalDocNo: Code[20];
        BalAmt1: Decimal;
        BalAmt2: Decimal;
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount for Gen.Jnl.Lines with different Posting Dates
        // [GIVEN] "Suggest balancing amount" is TRUE on Gen.Journal Batch
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        BalDocNo := LibraryUtility.GenerateGUID();
        BalAmt1 := LibraryRandom.RandDec(100, 2);
        BalAmt2 := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Gen. Jnl. Line G0001 with Amount 10 on 01-01-2018
        CreateSimpleGenJnlLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), BalDocNo);
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(5));
        GenJournalLine.Modify(true);
        // [GIVEN] Gen. Jnl. Line G0001 with Amount 20 on 25-01-2018
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, BalAmt1, BalDocNo);
        // [GIVEN] Gen. Jnl. Line G0001 with Amount 30 on 25-01-2018
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, BalAmt2, BalDocNo);

        // [WHEN] Add new line below last line
        GenJournalLine.Init();
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        // [THEN] New line has initial Document No. = G0001 with Amount = -50.
        VerifyGenJnlLineSuggestBalAmt(GenJournalLine, BalDocNo, -BalAmt1 - BalAmt2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalAmountWhenGenJournalLinesWithCustomFilter()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Suggest Balancing Amount]
        // [SCENARIO 167318] Suggest balancing Amount when Gen.Journal Line has custom filter
        // [GIVEN] "Suggest balancing amount" is TRUE on Gen.Journal Batch
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        // [GIVEN] Not balanced Gen. Jnl. Line G0001 with Amount 10
        CreateSimpleGenJnlLine(LastGenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), LibraryUtility.GenerateGUID());

        // [GIVEN] User has set a filter on "Posting Date"
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");

        // [WHEN] Add new line below
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);

        // [THEN] Gen.Journal Line is not balanced for G0001, Amount = 0
        GenJournalLine.TestField(Amount, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLinesSourceCode()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SourceCode: Record "Source Code";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Create Customer Journal Lines]
        // [SCENARIO 278125] Source code is copied from journal template by report Create Customer Journal Lines
        Initialize();

        // [GIVEN] Create new source code SC
        LibraryERM.CreateSourceCode(SourceCode);

        // [GIVEN] Create general journal template with source code SC
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateJnlTemplateSourceCode(GenJournalBatch."Journal Template Name", SourceCode);

        // [GIVEN] Create new customer CUST
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Report Create Customer Journal Lines is being run for customer CUST
        Customer.SetRecFilter();
        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', '');

        // [THEN] Created journal line has Source Code = SC
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Source Code", SourceCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesSourceCode()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SourceCode: Record "Source Code";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Create Vendor Journal Lines]
        // [SCENARIO 278125] Source code is copied from journal template by report Create Vendor Journal Lines
        Initialize();

        // [GIVEN] Create new source code SC
        LibraryERM.CreateSourceCode(SourceCode);

        // [GIVEN] Create general journal template with source code SC
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateJnlTemplateSourceCode(GenJournalBatch."Journal Template Name", SourceCode);

        // [GIVEN] Create new vendor VEND
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Report Create Vendor Journal Lines is being run for vendor VEND
        Vendor.SetRecFilter();

        RunCreateVendorJournalLines(
          Vendor, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', '');

        // [THEN] Created journal line has Source Code = SC
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Source Code", SourceCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLAccountJournalLinesSourceCode()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SourceCode: Record "Source Code";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Create G/L Account Journal Lines]
        // [SCENARIO 278125] Source code is copied from journal template by report Create G/L Account Journal Lines
        Initialize();

        // [GIVEN] Create new source code SC
        LibraryERM.CreateSourceCode(SourceCode);

        // [GIVEN] Create general journal template with source code SC
        CreateGeneralJournalBatch(GenJournalBatch);
        UpdateJnlTemplateSourceCode(GenJournalBatch."Journal Template Name", SourceCode);

        // [GIVEN] Create new G/L account ACC
        LibraryERM.CreateGLAccount(GLAccount);

        // [WHEN] Report Create G/L Account Journal Lines is being run for G/L account ACC
        GLAccount.SetRecFilter();
        RunCreateGLAccountJournalLines(
          GLAccount, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', '');

        // [THEN] Created journal line has Source Code = SC
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Source Code", SourceCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLinesDocumentNoWithoutRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Customer Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Customer Journal Lines" report called from C/AL code without request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        RunCreateCustomerJournalLines(
          Customer, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesDocumentNoWithoutRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Vendor Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Vendor Journal Lines" report called from C/AL code without request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        RunCreateVendorJournalLines(
          Vendor, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLAccountJournalLinesDocumentNoWithoutRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create G/L Account Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create G/L Account Journal Lines" report called from C/AL code without request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRecFilter();

        RunCreateGLAccountJournalLines(
          GLAccount, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemJournalLinesDocumentNoWithoutRequestPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Item Journal Lines]
        // [SCENARIO 299575] Stan can create item journal lines with the specified document number via "Create Item Journal Lines" report called from C/AL code without request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItem(Item);
        Item.SetRecFilter();

        RunCreateItemJournalLines(
          Item, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, '', DocumentNo);

        LibraryInventory.FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Document No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCustomerJournalLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLinesDocumentNoWithRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Customer Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Customer Journal Lines" report called with request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        RunCreateCustomerJournalLinesWithRequestPage(
          Customer, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateVendorJournalLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesDocumentNoWithRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Vendor Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Vendor Journal Lines" report called with request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        RunCreateVendorJournalLinesWithRequestPage(
          Vendor, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateGLAccJournalLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLAccountJournalLinesDocumentNoWithRequestPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create G/L Account Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create G/L Account Journal Lines" report called with request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRecFilter();

        RunCreateGLAccountJournalLinesWithRequestPage(
          GLAccount, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, '', DocumentNo);

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.TestField("Document No.", DocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateItemJournalLinesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemJournalLinesDocumentNoWithRequestPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Create Item Journal Lines]
        // [SCENARIO 299575] Stan can create item journal lines with the specified document number via "Create Item Journal Lines" report called with request page.
        Initialize();

        DocumentNo := LibraryUtility.GenerateGUID();
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItem(Item);
        Item.SetRecFilter();

        RunCreateItemJournalLinesWithRequestPage(
          Item, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, '', DocumentNo);

        LibraryInventory.FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Document No.", DocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLinesDocumentNoFromGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTestPage: TestPage "General Journal";
        DocumentNo: Code[20];
        LineCount: Integer;
        Index: Integer;
    begin
        // [FEATURE] [Create Customer Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Customer Journal Lines" report called from General Journal page.
        Initialize();

        Customer.ModifyAll(Blocked, Customer.Blocked::All);
        LineCount := 3;
        DocumentNo := LibraryUtility.GenerateGUID();

        CreateGeneralJournalBatch(GenJournalBatch);

        for Index := 1 to LineCount do
            LibrarySales.CreateCustomer(Customer);

        GenJournalLine.Init();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        GeneralJournalTestPage.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        GeneralJournalTestPage."<Document No. Simple Page>".SetValue(DocumentNo);
        GeneralJournalTestPage."Customers Opening balance".Invoke();

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GenJournalLine, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesDocumentNoFromGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTestPage: TestPage "General Journal";
        DocumentNo: Code[20];
        LineCount: Integer;
        Index: Integer;
    begin
        // [FEATURE] [Create Vendor Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create Vendor Journal Lines" report called from General Journal page.
        Initialize();

        Vendor.ModifyAll(Blocked, Vendor.Blocked::All);
        LineCount := 3;
        DocumentNo := LibraryUtility.GenerateGUID();

        CreateGeneralJournalBatch(GenJournalBatch);

        for Index := 1 to LineCount do
            LibraryPurchase.CreateVendor(Vendor);

        GenJournalLine.Init();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        GeneralJournalTestPage.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        GeneralJournalTestPage."<Document No. Simple Page>".SetValue(DocumentNo);
        GeneralJournalTestPage."Vendors Opening balance".Invoke();

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GenJournalLine, LineCount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateGLAccountJournalLinesDocumentNoFromGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTestPage: TestPage "General Journal";
        DocumentNo: Code[20];
        LineCount: Integer;
        Index: Integer;
    begin
        // [FEATURE] [Create G/L Account Journal Lines]
        // [SCENARIO 299575] Stan can create gen. journal lines with the specified document number via "Create G/L Account Journal Lines" report called from General Journal page.
        Initialize();

        GLAccount.ModifyAll(Blocked, true);
        LineCount := 3;
        DocumentNo := LibraryUtility.GenerateGUID();

        CreateGeneralJournalBatch(GenJournalBatch);

        for Index := 1 to LineCount do begin
            LibraryERM.CreateGLAccount(GLAccount);
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
            GLAccount.Modify(true);
        end;

        GenJournalLine.Init();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        GeneralJournalTestPage.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        GeneralJournalTestPage."<Document No. Simple Page>".SetValue(DocumentNo);
        GeneralJournalTestPage."G/L Accounts Opening balance ".Invoke();

        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GenJournalLine, LineCount);

        GLAccount.ModifyAll(Blocked, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarningPostWithEmptyBalAccountNoAndManualCheckAccept()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Manual Check]
        // [SCENARIO 356131] When trying to post Gen. Journal lines with empty "Bal. Account No." and "Manual Check", warning is shown. Accepting resumes posting.
        Initialize();

        // [GIVEN] Pair of Gen. Journal Lines with "Document Type" = "Payment", "Account Type" = "Vendor" / "Bank Account", "Amount" = 100 / -100,
        // [GIVEN] "Bal. Account Type" = "G/L Account", "Bal. Account No." is empty, "Bank Payment Type" = blank / "Manual Check", same "Document No".
        CreateGeneralJournalLinesForManualCheck(
            GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), GenJnlLine."Bal. Account Type"::"G/L Account", LibraryRandom.RandDec(100, 1));
        DocumentNo := GenJnlLine."Document No.";

        // [WHEN] "Gen. Jnl.-Post" codeunit is run for Gen. Journal Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        GenJnlLine.SetRange("Document No.", DocumentNo);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);

        // [THEN] Warning with text "When printing checks from lines with Bal. Acc. No blank you will not be able to void the check. Do you want to continue?".
        LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ConfirmManualCheckTxt, LibraryVariableStorage.DequeueText());

        // [THEN] When accepted, Gen. Journal Lines are posted.
        VerifyGLEntriesCount(DocumentNo, 2);
        VerifyGenJournalLinesCount(DocumentNo, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure WarningPostWithEmptyBalAccountNoAndManualCheckCancel()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Manual Check]
        // [SCENARIO 356131] When trying to post Gen. Journal lines with empty "Bal. Account No." and "Manual Check", warning is shown. Canceling stops posting.
        Initialize();

        // [GIVEN] Pair of Gen. Journal Lines with "Document Type" = "Payment", "Account Type" = "Vendor" / "Bank Account", "Amount" = 100 / -100,
        // [GIVEN] "Bal. Account Type" = "G/L Account", "Bal. Account No." is empty, "Bank Payment Type" = blank / "Manual Check", same "Document No".
        CreateGeneralJournalLinesForManualCheck(
            GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), GenJnlLine."Bal. Account Type"::"G/L Account", LibraryRandom.RandDec(100, 1));
        DocumentNo := GenJnlLine."Document No.";

        // [WHEN] "Gen. Jnl.-Post" codeunit is run for Gen. Journal Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        GenJnlLine.SetRange("Document No.", DocumentNo);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);

        // [THEN] Warning with text "When printing checks from lines with Bal. Acc. No blank you will not be able to void the check. Do you want to continue?".
        LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ConfirmManualCheckTxt, LibraryVariableStorage.DequeueText());

        // [THEN] When canceled, Gen. Journal Lines are not posted.
        VerifyGLEntriesCount(DocumentNo, 0);
        VerifyGenJournalLinesCount(DocumentNo, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,GLRegisterReportHandler')]
    [Scope('OnPrem')]
    procedure WarningPostAndPrintWithEmptyBalAccountNoAndManualCheckAccept()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Manual Check]
        // [SCENARIO 356131] When trying to post and print Gen. Journal lines with empty "Bal. Account No." and "Manual Check", warning is shown. Accepting resumes posting.
        Initialize();

        // [GIVEN] Pair of Gen. Journal Lines with "Document Type" = "Payment", "Account Type" = "Vendor" / "Bank Account", "Amount" = 100 / -100,
        // [GIVEN] "Bal. Account Type" = "G/L Account", "Bal. Account No." is empty, "Bank Payment Type" = blank / "Manual Check", same "Document No".
        CreateGeneralJournalLinesForManualCheck(
            GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), GenJnlLine."Bal. Account Type"::"G/L Account", LibraryRandom.RandDec(100, 1));
        DocumentNo := GenJnlLine."Document No.";

        // [WHEN] "Gen. Jnl.-Post+Print" codeunit is run for Gen. Journal Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        GenJnlLine.SetRange("Document No.", DocumentNo);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJnlLine);

        // [THEN] Warning with text "When printing checks from lines with Bal. Acc. No blank you will not be able to void the check. Do you want to continue?".
        LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ConfirmManualCheckTxt, LibraryVariableStorage.DequeueText());

        // [THEN] When accepted, Gen. Journal Lines are posted.
        VerifyGLEntriesCount(DocumentNo, 2);
        VerifyGenJournalLinesCount(DocumentNo, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure WarningPostAndPrintWithEmptyBalAccountNoAndManualCheckCancel()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Manual Check]
        // [SCENARIO 356131] When trying to post and print Gen. Journal lines with empty "Bal. Account No." and "Manual Check", warning is shown. Canceling stops posting.
        Initialize();

        // [GIVEN] Pair of Gen. Journal Lines with "Document Type" = "Payment", "Account Type" = "Vendor" / "Bank Account", "Amount" = 100 / -100,
        // [GIVEN] "Bal. Account Type" = "G/L Account", "Bal. Account No." is empty, "Bank Payment Type" = blank / "Manual Check", same "Document No".
        CreateGeneralJournalLinesForManualCheck(
            GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), GenJnlLine."Bal. Account Type"::"G/L Account", LibraryRandom.RandDec(100, 1));
        DocumentNo := GenJnlLine."Document No.";

        // [WHEN] "Gen. Jnl.-Post+Print" codeunit is run for Gen. Journal Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        GenJnlLine.SetRange("Document No.", DocumentNo);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJnlLine);

        // [THEN] Warning with text "When printing checks from lines with Bal. Acc. No blank you will not be able to void the check. Do you want to continue?".
        LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ConfirmManualCheckTxt, LibraryVariableStorage.DequeueText());

        // [THEN] When canceled, Gen. Journal Lines are not posted.
        VerifyGLEntriesCount(DocumentNo, 0);
        VerifyGenJournalLinesCount(DocumentNo, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBalDocumentNoSequentialNosBelowLastLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 441143] Suggest balancing Amount Function should not use the old document no. if total balance of last lines is zero.
        Initialize();

        // [GIVEN] "Suggest balancing amount" is True on Journal Template
        CreateGeneralJournalBatchSuggestBalAmount(GenJournalBatch, true);

        // [GIVEN] Create Gen. Jnl. Line 1
        CreateSimpleGenJnlLine(
          GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2),
          LibraryUtility.GenerateGUID());
        LastGenJournalLine := GenJournalLine;

        // [GIVEN] Create Gen. Jnl. Line 2 which will balance it with the previouse Journal line
        InitializeGenJournalLine(GenJournalLine, LastGenJournalLine, GenJournalBatch);
        LastGenJournalLine := GenJournalLine;
        LastGenJournalLine."Account No." := LibraryUtility.GenerateGUID();

        // [WHEN] 3rd Gen. Jnl. Line is created
        InitializeGenJournalLine(GenJournalLine, LastGenJournalLine, GenJournalBatch);

        // [WHEN] It should have new document no.
        Assert.AreNotEqual(
            LastGenJournalLine."Document No.",
            GenJournalLine."Document No.",
            StrSubstNo(WrongDocNoErr, LastGenJournalLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure LastNoUsedInNoSeriesMustBeUpdatedWhenPostGenJnlLineWithForceDocBalFalse()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        StartingNo: Integer;
        GLAccountNo: Code[20];
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
        LastDocumentNo: Code[20];
    begin
        // [SCENARIO 483548] The "Last no. used" gets not updated under No. Series page if you Edit in Excel some lines to a General Journal, renumber the lines and post them.
        Initialize();

        // [GIVEN] Create a No Series.
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);

        // [GIVEN] Generate & save Starting No in a Variable.
        StartingNo := LibraryRandom.RandInt(5);

        // [GIVEN] Create a No Series Line with Last No Used & Increment by 1.
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, Format(StartingNo), Format(StartingNo + 10));
        NoSeriesLine."Last No. Used" := Format(StartingNo + 1);
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Modify(true);

        // [GIVEN] Generate & Save Document No in a Variable.
        DocumentNo := Format(LibraryRandom.RandInt(15));

        // [GIVEN] Create a General Journal Batch & Validate No Series Code.
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);

        // [GIVEN] Create a GL Account & save GL Account No in a Variable.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccountNo := GLAccount."No.";

        // [GIVEN] Create a Bank Account & save Bank Account No in a Variable.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";

        // [GIVEN] Find & Validate Force Doc Balance as False in General Journal Template.
        GenJournalTemplate.SetRange(Name, GenJournalBatch."Journal Template Name");
        GenJournalTemplate.FindFirst();
        GenJournalTemplate.Validate("Force Doc. Balance", false);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Create General Journal Lines for Vendor 1.
        CreateGeneralJournalLineWithBalAccountNo(
            GenJournalLine,
            GenJournalBatch,
            LibraryERM.CreateGLAccountNo(),
            DocumentNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            GLAccountNo);

        // [GIVEN] Create General Journal Lines for Vendor 2.
        CreateGeneralJournalLineWithBalAccountNo(
            GenJournalLine,
            GenJournalBatch,
            LibraryERM.CreateGLAccountNo(),
            DocumentNo,
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccountNo);

        // [GIVEN] Create General Journal Lines for Vendor 3.
        CreateGeneralJournalLineWithBalAccountNo(
            GenJournalLine,
            GenJournalBatch,
            LibraryERM.CreateGLAccountNo(),
            DocumentNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            GLAccountNo);

        // [GIVEN] Create General Journal Lines for Vendor 4.
        CreateGeneralJournalLineWithBalAccountNo(
            GenJournalLine,
            GenJournalBatch,
            LibraryERM.CreateGLAccountNo(),
            DocumentNo,
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccountNo);

        // [GIVEN] Run Renumber Document No.
        Commit();
        GenJournalLine.SetRange("Line No.", 10000, 40000);
        GenJournalLine.RenumberDocumentNo();

        // [GIVEN] Find Last Document No populated in General Journal Lines & save it in a Variable.
        GenJournalLine1.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine1.SetCurrentKey("Bal. Account No.");
        GenJournalLine1.FindLast();
        LastDocumentNo := GenJournalLine1."Document No.";

        // [GIVEN] Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Get No Series Line.
        NoSeriesLine.Get(NoSeries.Code, NoSeriesLine."Line No.");

        // [VERIFY] Verify Last Document No of General Journal Lines & Last No Used in No Series Line are same.
        Assert.AreEqual(LastDocumentNo, NoSeriesLine."Last No. Used", LastDocNoAndLastNoUsedMustMatchErr);
    end;

    [Test]
    procedure GenJnlLinesArePostedIfHaveSamePostingDatesAndForceDocBalanceIsFalse()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        GLEntry: Record "G/L Entry";
        StartingNo: Integer;
        GLAccountNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 505001] Gen. Journal Lines having same Posting Date and Force Doc. Balance set to false in Gen. Journal Template are posted without any error.
        Initialize();

        // [GIVEN] Create a No. Series.
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);

        // [GIVEN] Generate & save Starting No in a Variable.
        StartingNo := LibraryRandom.RandInt(5);

        // [GIVEN] Create a No. Series Line.
        LibraryUtility.CreateNoSeriesLine(
            NoSeriesLine,
            NoSeries.Code,
            Format(StartingNo),
            Format(StartingNo + LibraryRandom.RandIntInRange(10, 10)));

        // [GIVEN] Validate Last No. Used and Increment-by No in No. Series Line.
        NoSeriesLine."Last No. Used" := Format(StartingNo);
        NoSeriesLine."Increment-by No." := LibraryRandom.RandInt(0);
        NoSeriesLine.Modify(true);

        // [GIVEN] Create a General Journal Batch & Validate No. Series.
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);

        // [GIVEN] Create a GL Account & save GL Account No in a Variable.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccountNo := GLAccount."No.";

        // [GIVEN] Create a Bank Account & save Bank Account No in a Variable.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";

        // [GIVEN] Find & Validate Force Doc. Balance as false in General Journal Template.
        GenJournalTemplate.SetRange(Name, GenJournalBatch."Journal Template Name");
        GenJournalTemplate.FindFirst();
        GenJournalTemplate.Validate("Force Doc. Balance", false);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Create General Journal Line with GL Account No.
        CreateGeneralJournalLineWithGLAccountNo(
            GenJournalLine,
            GenJournalBatch,
            Format(StartingNo + LibraryRandom.RandInt(0)),
            GLAccountNo,
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccountNo);

        // [GIVEN] Create General Journal Line 2 with GL Account No.
        CreateGeneralJournalLineWithGLAccountNo(
            GenJournalLine,
            GenJournalBatch,
            Format(StartingNo + LibraryRandom.RandIntInRange(2, 2)),
            GLAccountNo,
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccountNo);

        // [GIVEN] Create General Journal Line 3 with GL Account No.
        CreateGeneralJournalLineWithGLAccountNo(
            GenJournalLine,
            GenJournalBatch,
            Format(StartingNo + LibraryRandom.RandIntInRange(3, 3)),
            GLAccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account",
            GLAccountNo);

        // [GIVEN] Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);

        // [VERIFY] GL Entry is found.
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustBeFoundErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        GenJnlManagement: Codeunit "GenJnlManagement";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM TestMultipleGenJnlLines");
        LibraryApplicationArea.EnableFoundationSetup();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM TestMultipleGenJnlLines");
        GenJnlManagement.SetJournalSimplePageModePreference(true, Page::"General Journal");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM TestMultipleGenJnlLines");
    end;

    local procedure CreateAndUpdateGLAccount(var GLAccount: Record "G/L Account"; GenPostingType: Enum "General Posting Type")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateGLAccount(GLAccount, GenPostingType);
    end;

    local procedure CreateBatchAndUpdateTemplate(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        // Create General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch."Journal Template Name");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Modify(true);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        UpdateGeneralBatchNoSeriesAndBalAccount(GenJournalBatch);
    end;

    local procedure UpdateGeneralBatchNoSeriesAndBalAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch.Validate(Description, GenJournalBatch.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", CreateNoSeries());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchTemplateForceDocBalance(var GenJournalBatch: Record "Gen. Journal Batch"; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalBatchSuggestBalAmount(var GenJournalBatch: Record "Gen. Journal Batch"; SuggestBalAmount: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Suggest Balancing Amount", SuggestBalAmount);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NoOfLines: Integer; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        for Counter := 1 to NoOfLines do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount);
            GenJournalLine.Validate("Bal. Account No.", '');
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateGeneralJournalLineByPage(var GeneralJournal: TestPage "General Journal")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        // Find General Journal Template and Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch);

        // Create General Journal Line.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Account No.".SetValue(GLAccount."No.");
        UpdateAmountOnGenJournalLine(GenJournalBatch, GeneralJournal);
        GeneralJournal."Document No.".SetValue(GenJournalBatch.Name);

        // Find G/L Account No for Bal. Account No.
        GLAccount.SetFilter("No.", '<>%1', GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralJournal."Bal. Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Bal. Account No.".SetValue(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLineWithBalanceLine(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; BalDocumentNo: Code[20]; PostingDate: Date)
    var
        Amount: Integer;
    begin
        Amount := LibraryRandom.RandInt(100);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, 1, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, 1, -Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", BalDocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLinesForManualCheck(var GenJnlLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; LineAmount: Decimal)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        DocumentNo: Code[20];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, DocumentType,
          AccountType, AccountNo, BalAccountType, '', LineAmount);
        DocumentNo := GenJnlLine."Document No.";
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, DocumentType,
          GenJnlLine."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), BalAccountType, '', -LineAmount);
        GenJnlLine.Validate("Document No.", DocumentNo);
        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.Modify(true);
    end;

    local procedure CreateAndPostGeneralJournalLinesUsingNoSeriesByPage(LineCount: Integer): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
        i: Integer;
    begin
        // Create General Journal Template, General Journal Batch and G/L Account.
        CreateGeneralJournalBatchWithNoSeries(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);

        // Open General Journal Page and create General Journal Lines.
        Commit(); // As there is a RUNMODAL inside the following call: GeneralJournal.OPENEDIT.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GeneralJournal.OpenEdit();
        for i := 1 to LineCount do begin
            GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
            GeneralJournal."Account No.".SetValue(GLAccount."No.");
            GeneralJournal.Next();
        end;
        UpdateAmountOnGenJournalLines(GenJournalBatch, GeneralJournal);
        GeneralJournal.Post.Invoke();
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGeneralJournalLineWithPostingNoSeries(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingNoSeries: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Posting No. Series", PostingNoSeries);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateSimpleGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAmount: Decimal; DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), GLAmount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure DeleteGeneralJournalTemplate(Name: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(Name);
        GenJournalTemplate.Delete(true);
    end;

    local procedure FindGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
    end;

    local procedure FindVATSetupWithZeroVATPct(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);  // Taking Zero VAT Percent to Create a VAT Entry Without Amount. Value important for Test.
        VATPostingSetup.FindFirst();
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        NoSeriesLine.Modify(true);
        exit(NoSeries.Code);
    end;

    local procedure FindStandardGeneralJournalLine(var StandardGeneralJournalLine: Record "Standard General Journal Line"; JournalTemplateName: Code[10]; StandardJournalCode: Code[10])
    begin
        StandardGeneralJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindSet();
    end;

    local procedure GetLastGLEntryNumber(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure RunCreateCustomerJournalLines(var Customer: Record Customer; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateCustomerJournalLines: Report "Create Customer Journal Lines";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        Clear(CreateCustomerJournalLines);
        CreateCustomerJournalLines.UseRequestPage(false);
        CreateCustomerJournalLines.SetTableView(Customer);
        CreateCustomerJournalLines.InitializeRequest(GenJournalLine."Document Type"::Invoice.AsInteger(), WorkDate(), WorkDate());
        CreateCustomerJournalLines.InitializeRequestTemplate(JournalTemplate, BatchName, TemplateCode);
        CreateCustomerJournalLines.SetDefaultDocumentNo(DocumentNo);
        CreateCustomerJournalLines.Run();
    end;

    local procedure RunCreateVendorJournalLines(var Vendor: Record Vendor; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateVendorJournalLines: Report "Create Vendor Journal Lines";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        Clear(CreateVendorJournalLines);
        CreateVendorJournalLines.UseRequestPage(false);
        CreateVendorJournalLines.SetTableView(Vendor);
        CreateVendorJournalLines.InitializeRequest(GenJournalLine."Document Type"::Invoice.AsInteger(), WorkDate(), WorkDate());
        CreateVendorJournalLines.InitializeRequestTemplate(JournalTemplate, BatchName, TemplateCode);
        CreateVendorJournalLines.SetDefaultDocumentNo(DocumentNo);
        CreateVendorJournalLines.Run();
    end;

    local procedure RunCreateGLAccountJournalLines(var GLAccount: Record "G/L Account"; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateGLAccJournalLines: Report "Create G/L Acc. Journal Lines";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        Clear(CreateGLAccJournalLines);
        CreateGLAccJournalLines.UseRequestPage(false);
        CreateGLAccJournalLines.SetTableView(GLAccount);
        CreateGLAccJournalLines.InitializeRequest(
            GenJournalLine."Document Type"::Invoice.AsInteger(), WorkDate(), JournalTemplate, BatchName, TemplateCode);
        CreateGLAccJournalLines.SetDefaultDocumentNo(DocumentNo);
        CreateGLAccJournalLines.Run();
    end;

    local procedure RunCreateItemJournalLines(var Item: Record Item; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        CreateItemJournalLines: Report "Create Item Journal Lines";
    begin
        Commit();
        CreateItemJournalLines.UseRequestPage(false);
        CreateItemJournalLines.SetTableView(Item);
        CreateItemJournalLines.InitializeRequest(ItemJournalLine."Document Type"::"Sales Invoice".AsInteger(), WorkDate(), WorkDate());
        CreateItemJournalLines.InitializeRequestTemplate(JournalTemplate, BatchName, TemplateCode);
        CreateItemJournalLines.SetDefaultDocumentNo(DocumentNo);
        CreateItemJournalLines.Run();
    end;

    local procedure RunCreateCustomerJournalLinesWithRequestPage(var Customer: Record Customer; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateCustomerJournalLines: Report "Create Customer Journal Lines";
    begin
        Commit();
        CreateCustomerJournalLines.UseRequestPage(true);
        CreateCustomerJournalLines.SetTableView(Customer);
        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(JournalTemplate);
        LibraryVariableStorage.Enqueue(BatchName);
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateCustomerJournalLines.Run();
    end;

    local procedure RunCreateVendorJournalLinesWithRequestPage(var Vendor: Record Vendor; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateVendorJournalLines: Report "Create Vendor Journal Lines";
    begin
        Commit();
        CreateVendorJournalLines.UseRequestPage(true);
        CreateVendorJournalLines.SetTableView(Vendor);
        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(JournalTemplate);
        LibraryVariableStorage.Enqueue(BatchName);
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateVendorJournalLines.Run();
    end;

    local procedure RunCreateGLAccountJournalLinesWithRequestPage(var GLAccount: Record "G/L Account"; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateGLAccJournalLines: Report "Create G/L Acc. Journal Lines";
    begin
        Commit();
        CreateGLAccJournalLines.UseRequestPage(true);
        CreateGLAccJournalLines.SetTableView(GLAccount);
        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(JournalTemplate);
        LibraryVariableStorage.Enqueue(BatchName);
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateGLAccJournalLines.Run();
    end;

    local procedure RunCreateItemJournalLinesWithRequestPage(var Item: Record Item; JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10]; DocumentNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        CreateItemJournalLines: Report "Create Item Journal Lines";
    begin
        Commit();
        CreateItemJournalLines.UseRequestPage(true);
        CreateItemJournalLines.SetTableView(Item);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Document Type"::"Sales Invoice");
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(JournalTemplate);
        LibraryVariableStorage.Enqueue(BatchName);
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreateItemJournalLines.Run();
    end;

    local procedure SaveAsStandardJournal(GenJournalBatch: Record "Gen. Journal Batch"; "Code": Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SaveAsStandardGenJournal: Report "Save as Standard Gen. Journal";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Clear(SaveAsStandardGenJournal);
        SaveAsStandardGenJournal.Initialise(GenJournalLine, GenJournalBatch);
        SaveAsStandardGenJournal.InitializeRequest(Code, '', true);
        SaveAsStandardGenJournal.UseRequestPage(false);
        SaveAsStandardGenJournal.RunModal();
    end;

    local procedure SelectAndClearGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateBalanceGLAccount(GenJournalLine: Record "Gen. Journal Line"; BalanceAccountNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalanceAccountNo);
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Vendor:
                GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
            GenJournalLine."Account Type"::Customer:
                GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        end;
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGLAccount(var GLAccount: Record "G/L Account"; GenPostingType: Enum "General Posting Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATSetupWithZeroVATPct(VATPostingSetup);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UpdateAmountOnGenJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; var GeneralJournal: TestPage "General Journal")
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryERM.UpdateAmountOnGenJournalLine(GenJournalBatch, GeneralJournal);
    end;

    local procedure UpdateAmountOnGenJournalLines(GenJournalBatch: Record "Gen. Journal Batch"; var GeneralJournal: TestPage "General Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GeneralJournal.OK().Invoke(); // Need to close the Page to ensure changes are reflected on Record Variable.
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        repeat
            GenJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
            // Update Random Amount.
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
    end;

    local procedure UpdateJnlTemplateSourceCode(TemplateName: Code[10]; SourceCode: Record "Source Code")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(TemplateName);
        GenJournalTemplate.Validate("Source Code", SourceCode.Code);
        GenJournalTemplate.Modify(true);
    end;

    local procedure VerifyCustomerJournalLines(GenJournalBatch: Record "Gen. Journal Batch"; StandardJournalCode: Code[10]; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        FindStandardGeneralJournalLine(StandardGeneralJournalLine, GenJournalBatch."Journal Template Name", StandardJournalCode);
        FindGeneralJournalLine(GenJournalLine, GenJournalBatch);
        repeat
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
            GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Customer);
            GenJournalLine.TestField("Account No.", AccountNo);
            GenJournalLine.TestField(Amount, StandardGeneralJournalLine.Amount);
            GenJournalLine.Next();
        until StandardGeneralJournalLine.Next() = 0;
    end;

    local procedure VerifyBalanceAccountOnGLEntry(DocumentNo: Code[20]; BalAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.TestField("Sell-to Customer No.", CustomerNo);
    end;

    local procedure VerifyGenJournalLinesCount(DocumentNo: Code[20]; LineCount: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GenJnlLine, LineCount);
    end;

    local procedure VerifyGLEntriesCount(DocumentNo: Code[20]; LineCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, LineCount);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.TestField("Buy-from Vendor No.", VendorNo);
    end;

    local procedure VerifyVATEntries(DocumentNo: Code[20]; BilltoPaytoNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Bill-to/Pay-to No.", BilltoPaytoNo);
    end;

    local procedure VerifyGLRegister(GenJournalBatchName: Code[10])
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLRegister.TestField("Journal Batch Name", GenJournalBatchName);
    end;

    local procedure VerifyGenJnlLineSuggestBalAmt(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; GLAmount: Decimal)
    begin
        GenJournalLine.TestField("Document No.", DocumentNo);
        GenJournalLine.TestField(Amount, GLAmount);
    end;

    local procedure InitializeGenJournalLine(
        var GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch")
    var
        RecRef: RecordRef;
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine."Line No." := 0;
        RecRef.GetTable(GenJournalLine);
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, GenJournalLine.FieldNo("Line No.")));

        GenJournalLine.SetUpNewLine(LastGenJournalLine, LastGenJournalLine."Balance (LCY)", true);
        GenJournalLine.Insert(true);
    end;

    local procedure CreateGeneralJournalLineWithBalAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; GLAccNo: Code[20]; DocNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::"G/L Account",
            GLAccNo,
            LibraryRandom.RandInt(20));

        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLineWithGLAccountNo(
        var GenJournalLine: Record "Gen. Journal Line";
        var GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
        GLAccountNo: Code[20];
        BalAccountType: Enum "Gen. Journal Account Type";
        BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            GLAccountNo,
            LibraryRandom.RandInt(20));

        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateHandler(var GeneralJournalTemplateHandler: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateHandler.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateHandler.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure StandardGeneralJournalHandler(var StandardGeneralJournal: TestPage "Standard General Journal")
    begin
        StandardGeneralJournal.StdGenJnlLines.Amount.SetValue(LibraryRandom.RandDec(100, 2));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateGLAccJournalLinesRequestPageHandler(var CreateGLAccJournalLines: TestRequestPage "Create G/L Acc. Journal Lines")
    begin
        CreateGLAccJournalLines.DocumentTypes.SetValue(LibraryVariableStorage.DequeueInteger()); // Document Type
        CreateGLAccJournalLines.PostingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Posting Date
        CreateGLAccJournalLines.JournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Journal Template
        CreateGLAccJournalLines.BatchName.SetValue(LibraryVariableStorage.DequeueText()); // Batch Name
        CreateGLAccJournalLines.TemplateCode.SetValue(LibraryVariableStorage.DequeueText()); // Std. Template Code
        CreateGLAccJournalLines.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CreateGLAccJournalLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateCustomerJournalLinesRequestPageHandler(var CreateCustomerJournalLines: TestRequestPage "Create Customer Journal Lines")
    begin
        CreateCustomerJournalLines.DocumentTypes.SetValue(LibraryVariableStorage.DequeueInteger()); // Document Type
        CreateCustomerJournalLines.PostingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Posting Date
        CreateCustomerJournalLines.DocumentDate.SetValue(LibraryVariableStorage.DequeueDate()); // Document Date
        CreateCustomerJournalLines.JournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Template Name
        CreateCustomerJournalLines.BatchName.SetValue(LibraryVariableStorage.DequeueText()); // Batch Name
        CreateCustomerJournalLines.TemplateCode.SetValue(LibraryVariableStorage.DequeueText()); // Std. Template Code
        CreateCustomerJournalLines.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CreateCustomerJournalLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesRequestPageHandler(var CreateVendorJournalLines: TestRequestPage "Create Vendor Journal Lines")
    begin
        CreateVendorJournalLines.DocumentTypes.SetValue(LibraryVariableStorage.DequeueInteger()); // Document Type
        CreateVendorJournalLines.PostingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Posting Date
        CreateVendorJournalLines.DocumentDate.SetValue(LibraryVariableStorage.DequeueDate()); // Document Date
        CreateVendorJournalLines.JournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Template Name
        CreateVendorJournalLines.BatchName.SetValue(LibraryVariableStorage.DequeueText()); // Batch Name
        CreateVendorJournalLines.TemplateCode.SetValue(LibraryVariableStorage.DequeueText()); // Std. Template Code
        CreateVendorJournalLines.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CreateVendorJournalLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateItemJournalLinesRequestPageHandler(var CreateItemJournalLines: TestRequestPage "Create Item Journal Lines")
    begin
        CreateItemJournalLines.EntryTypes.SetValue(LibraryVariableStorage.DequeueInteger()); // Document Type
        CreateItemJournalLines.PostingDate.SetValue(LibraryVariableStorage.DequeueDate()); // Posting Date
        CreateItemJournalLines.DocumentDate.SetValue(LibraryVariableStorage.DequeueDate()); // Document Date
        CreateItemJournalLines.JournalTemplate.SetValue(LibraryVariableStorage.DequeueText()); // Template Name
        CreateItemJournalLines.BatchName.SetValue(LibraryVariableStorage.DequeueText()); // Batch Name
        CreateItemJournalLines.TemplateCode.SetValue(LibraryVariableStorage.DequeueText()); // Std. Template Code
        CreateItemJournalLines.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CreateItemJournalLines.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure GLRegisterReportHandler(var GLRegister: Report "G/L Register")
    begin
    end;
}
