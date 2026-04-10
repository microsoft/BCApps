codeunit 134048 "ERM Gen. Lines for Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal]
        isInitialized := false;
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountToApplyLargerError: Label '%1 must not be larger than %2 in %3 %4=''%5''.';
        ValidationError: Label 'Error must be same.';
        AmountEqualError: Label '%1 must be %2 to %3.';
        GenJournalTemplateError: Label 'Gen. Journal Template name is blank.';
        GenJournalBatchError: Label 'Gen. Journal Batch name is blank.';
        UnknownError: Label 'Unknown Error.';
        WrongPaymentMethodCodeErr: Label 'Field Payment Method Code should be updated.';
        NotLinearCalcErr: Label 'Computational complexity must be linear';

    [Test]
    [Scope('OnPrem')]
    procedure EqualAmountToApplyOnInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Amount to Apply on Vendor Ledger On Posting Vendor Invoice and Apply Payment.

        // Setup.
        Initialize();

        // Create Journal Line and Apply and check Ledger Entry.
        CreateAndCheckEqualAmount(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualAmountToApplyOnCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Amount to Apply on Vendor Ledger On Posting Vendor Credit Memo and Apply Refund.

        // Setup.
        Initialize();

        // Create Journal Line and Apply and check Ledger Entry.
        CreateAndCheckEqualAmount(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LargeAmountToApplyOnInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // Check Large Amount to Apply Error on Vendor Ledger On Posting Vendor Invoice and Apply Payment.

        // Setup: Create and Post General Line for Invoice and Payment.
        Initialize();
        Amount := -LibraryRandom.RandDec(100, 2);
        CreateGenAndFindVendorEntry(
          VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, Amount);

        // Exercise: Validate Large Amount to Apply on Vendor Ledger Entry.
        asserterror VendorLedgerEntry.Validate("Amount to Apply", Amount - LibraryRandom.RandDec(100, 2));

        // Verify: Verify Amount to Apply Error on Vendor Ledger Entry and Delete General Line.
        VerifyAmountToApplyError(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LargeAmountToApplyOnCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // Check Large Amount to Apply Error on Vendor Ledger On Posting Vendor Credit Memo and Apply Refund.

        // Setup: Create and Post Credit Memo and Refund General Line.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        CreateGenAndFindVendorEntry(
          VendorLedgerEntry, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, Amount);

        // Exercise: Validate Large Amount to Apply on Vendor Ledger Entry.
        asserterror VendorLedgerEntry.Validate("Amount to Apply", Amount + LibraryRandom.RandDec(100, 2));

        // Verify: Verify Amount to Apply Error on Vendor Ledger Entry and Delete General Line.
        VerifyAmountToApplyError(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessAmountToApplyOnInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Less Amount to Apply on Vendor Ledger On Posting Vendor Invoice and Apply Payment.
        Initialize();
        CreateAndCheckLessAmount(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessAmountToApplyOnCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Less Amount to Apply on Vendor Ledger On Posting Vendor Credit Memo and Apply Refund.
        Initialize();
        CreateAndCheckLessAmount(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAmountAfterAppliesID()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Amount to Apply on Vendor Ledger after Posting Vendor Invoice and Set Applies to ID.
        Initialize();
        CreateAndSetAppliesToIDOnGen(GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoAmountAfterAppliesID()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Amount to Apply on Vendor Ledger after Posting Vendor Credit Memo and Set Applies to ID.
        Initialize();
        CreateAndSetAppliesToIDOnGen(GenJournalLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAppliesToIDOnInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Applies to ID field on Vendor Ledger after Posting Vendor Invoice and Set Applies to ID.

        // Setup.
        Initialize();
        CreateAndPostGeneralLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2));

        // Exercise: Find Vendor Ledger Entry and Set Applies to ID.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // Verify: Verify Applies to ID field Not Blank after Set Applied to ID in Vendor Ledger Entry.
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>''''');
        Assert.IsTrue(VendorLedgerEntry.FindFirst(), 'Applies to ID field must not be blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // Test error occurs on running Create Vendor Journal Lines Report without General Journal Template.

        // 1. Setup: Create General Journal Batch and Find Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        StandardGeneralJournal.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournal.FindFirst();

        // 2. Exercise: Run Create Vendor Journal Lines Report without General Journal Template.
        asserterror RunCreateVendorJournalLines('', GenJournalBatch.Name, StandardGeneralJournal.Code);

        // 3. Verify: Verify error occurs on running Create Vendor Journal Lines Report without General Journal Template.
        Assert.AreEqual(StrSubstNo(GenJournalTemplateError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // Test error occurs on running Create Vendor Journal Lines Report without General Batch Name.

        // 1. Setup: Create General Journal Batch and Find Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        StandardGeneralJournal.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournal.FindFirst();

        // 2. Exercise: Run Create Vendor Journal Lines Report without General Batch Name.
        asserterror RunCreateVendorJournalLines(GenJournalBatch."Journal Template Name", '', StandardGeneralJournal.Code);

        // 3. Verify: Verify error occurs on running Create Vendor Journal Lines Report without General Batch Name.
        Assert.AreEqual(StrSubstNo(GenJournalBatchError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateVendorJournalLinesBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CreateVendorJournalLines: Report "Create Vendor Journal Lines";
    begin
        // Test General Journal Lines are created for Vendor after running Create Vendor Journal Lines Report.

        // 1. Setup: Create Vendor and General Journal Batch, Find Standard General Journal.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch);
        StandardGeneralJournal.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournal.FindFirst();

        // 2. Exercise: Run Create Vendor Journal Lines Report.
        Commit();  // COMMIT is required for Write Transaction Error.
        Clear(CreateVendorJournalLines);
        CreateVendorJournalLines.UseRequestPage(false);
        Vendor.SetRange("No.", Vendor."No.");
        CreateVendorJournalLines.SetTableView(Vendor);
        CreateVendorJournalLines.InitializeRequest(GenJournalLine."Document Type"::Invoice.AsInteger(), WorkDate(), WorkDate());
        CreateVendorJournalLines.InitializeRequestTemplate(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, StandardGeneralJournal.Code);
        CreateVendorJournalLines.Run();

        // 3. Verify: Verify General Journal Lines are created for vandor after running Create Vendor Journal Lines Report.
        VerifyVendorJournalLines(GenJournalBatch, StandardGeneralJournal.Code, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralLineWithCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that the application works properly when the Correction field is True in the General Journal line.

        // 1. Setup: Create General Journal line with Correction field is True.
        Initialize();
        CreateGeneralLineForCorrection(GenJournalLine);

        // 2. Exercise: Post General Journal Line with Correction check mark.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Debit amount for Correction in Vendor Ledger Entry.
        VerifyLedgerEntryForCorrection(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPaymentMethodCodeGeneralJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.");

        // Verify.
        Assert.AreEqual(Vendor."Payment Method Code", GenJournalLine."Payment Method Code", WrongPaymentMethodCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustPaymentMethodCodeGeneralJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // Exercise.
        CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalLine."Bal. Account Type"::Customer, Customer."No.");

        // Verify.
        Assert.AreEqual(Customer."Payment Method Code", GenJournalLine."Payment Method Code", WrongPaymentMethodCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalPostErrorWhenCustAndGLAccountWithPurchGenType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363478] Gen. Journal should not be posted where one transaction includes both Customer and G/L Account of Purchase Gen. Posting Type.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] General Journal Line1: "Account Type" = "G/L Account" (with "Gen. Posting Type" = Purchase)
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::"G/L Account",
          CreateGLAccountNoPurchase(), "Gen. Journal document Type"::" ", '', LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bill-to/Pay-to No.", '');
        GenJournalLine.Modify();
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line2: "Account Type" = "Customer"
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), "Gen. Journal document Type"::" ", '', -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify();

        // [WHEN] Post General Journal
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error occurs: "Gen. Posting Type must not be Purchase in Gen. Journal Line..."
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Posting Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalPostErrorWhenVendAndGLAccountWithSalesGenType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 363478] Gen. Journal should not be posted where one transaction includes both Vendor and G/L Account of Sale Gen. Posting Type.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] General Journal Line1: "Account Type" = "G/L Account" (with "Gen. Posting Type" = Sale)
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::"G/L Account",
          CreateGLAccountNoSales(), "Gen. Journal document Type"::" ", '', -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bill-to/Pay-to No.", '');
        GenJournalLine.Modify();
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line2: "Account Type" = "Vendor"
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), "Gen. Journal document Type"::" ", '', -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify();

        // [WHEN] Post General Journal
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error occurs: "Gen. Posting Type must not be Sale in Gen. Journal Line..."
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Posting Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinearComplexityCOD13_CheckAndCopyBalancingData()
    var
        NoOfLines: array[3] of Integer;
        NoOfHits: array[3] of Integer;
    begin
        // [FEATURE] [Performance]
        // [SCENARIO 277260] CheckAndCopyBalancingData function iterates Gen. Journal Lines with linear complexity
        Initialize();

        NoOfLines[1] := 1;
        NoOfLines[2] := LibraryRandom.RandIntInRange(5, 10);
        NoOfLines[3] := LibraryRandom.RandIntInRange(10, 15);

        NoOfHits[1] := PostMultilineGenJournal(NoOfLines[1]);
        NoOfHits[2] := PostMultilineGenJournal(NoOfLines[2]);
        NoOfHits[3] := PostMultilineGenJournal(NoOfLines[3]);

        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(NoOfLines[1], NoOfLines[2], NoOfLines[3], NoOfHits[1], NoOfHits[2], NoOfHits[3]),
          NotLinearCalcErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultipleLineGenPostingTypeFirst()
    var
        GLAccount: array[2] of Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        I: Integer;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 314432] General Journal posting displays error message when
        // [SCENARIO 314432] first balanced portion of the document has wrong Gen. Posting Type on balancing line, while the last has it correct
        Initialize();

        // [GIVEN] G/L Account "GL01" with "Gen. Posting Type"="Purchase" and non-zero VAT Setup
        // [GIVEN] G/L Account "GL02" with "Gen. Posting Type"="Sale" and non-zero VAT Setup
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[1], GLAccount[1]."Gen. Posting Type"::Purchase);
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[2], GLAccount[2]."Gen. Posting Type"::Sale);

        // [GIVEN] Gen. Journal Batch for Gen. Journal Template "GENERAL"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Gen. Journal Line 10000 for Customer "CU01" with Amount = -100
        // [GIVEN] Gen. Journal Line 20000 for G/L Account "GL01" with Amount = 100
        // [GIVEN] Gen. Journal Line 30000 for Customer "CU02" with Amount = -200
        // [GIVEN] Gen. Journal Line 40000 for G/L Account "GL02" with Amount = 200
        for I := 1 to ArrayLen(GLAccount) do begin
            CreateGeneralJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(10, 2));
            CreateGeneralJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount[I]."No.", -GenJournalLine.Amount);
        end;

        // [WHEN] Post Gen. Journal Batch
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posting fails with error on value "Purchase" of field "Gen. Posting Type" on Gen. Journal Line 20000
        Assert.ExpectedErrorCode('TableError');
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Posting Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultipleLineGenPostingTypeLast()
    var
        GLAccount: array[2] of Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        I: Integer;
    begin
        // [FEATURE] [Post]
        // [SCENARIO 314432] General Journal posting displays error message when
        // [SCENARIO 314432] first balanced portion of the document has correct Gen. Posting Type on balancing line, while the last has it wrong
        Initialize();

        // [GIVEN] G/L Account "GL01" with "Gen. Posting Type"="Sale" and non-zero VAT Setup
        // [GIVEN] G/L Account "GL02" with "Gen. Posting Type"="Purchase" and non-zero VAT Setup
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[1], GLAccount[1]."Gen. Posting Type"::Sale);
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[2], GLAccount[2]."Gen. Posting Type"::Purchase);

        // [GIVEN] Gen. Journal Batch for Gen. Journal Template "GENERAL"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Gen. Journal Line 10000 for Customer "CU01" with Amount = -100
        // [GIVEN] Gen. Journal Line 20000 for G/L Account "GL01" with Amount = 100
        // [GIVEN] Gen. Journal Line 30000 for Customer "CU02" with Amount = -200
        // [GIVEN] Gen. Journal Line 40000 for G/L Account "GL02" with Amount = 200
        for I := 1 to ArrayLen(GLAccount) do begin
            CreateGeneralJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(10, 2));
            CreateGeneralJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount[I]."No.", -GenJournalLine.Amount);
        end;

        // [WHEN] Post Gen. Journal Batch
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posting fails with error on value "Purchase" of field "Gen. Posting Type" on Gen. Journal Line 20000
        Assert.ExpectedErrorCode('TableError');
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Posting Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMultipleLineGenPostingTypeSwap()
    var
        GLAccount: array[2] of Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [FEATURE] [Post]
        // [SCENARIO 314432] General Journal posting displays error message when
        // [SCENARIO 314432] first balanced portion of the document has correct Gen. Posting Type on balancing line
        // [SCENARIO 314432] while the last has it wrong and second balancing line comes before the Customer line
        Initialize();

        // [GIVEN] G/L Account "GL01" with "Gen. Posting Type"="Sale" and non-zero VAT Setup
        // [GIVEN] G/L Account "GL02" with "Gen. Posting Type"="Purchase" and non-zero VAT Setup
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[1], GLAccount[1]."Gen. Posting Type"::Sale);
        CreateAndUpdateGLAccountWithVATPostingSetup(GLAccount[2], GLAccount[2]."Gen. Posting Type"::Purchase);

        // [GIVEN] Gen. Journal Batch for Gen. Journal Template "GENERAL"
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Gen. Journal Line 10000 for Customer "CU01" with Amount = -100
        // [GIVEN] Gen. Journal Line 20000 for G/L Account "GL01" with Amount = 100
        // [GIVEN] Gen. Journal Line 30000 for G/L Account "GL02" with Amount = 200
        // [GIVEN] Gen. Journal Line 40000 for Customer "CU02" with Amount = -200
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(10, 2));
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount[1]."No.", -GenJournalLine.Amount);
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount[2]."No.", LibraryRandom.RandDec(10, 2));
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -GenJournalLine.Amount);

        // [WHEN] Post Gen. Journal Batch
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posting fails with error on value "Purchase" of field "Gen. Posting Type" on Gen. Journal Line 30000
        Assert.ExpectedErrorCode('TableError');
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Posting Type"), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
    end;

    local procedure CreateAndCheckEqualAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Exercise: Create and Post Invoice and Payment General Line.
        DocumentNo := CreatePostAndApplyGeneralLine(GenJournalLine, DocumentType, DocumentType2, Amount);

        // Verify: Amount to Apply on Vendor Ledger Entry.
        VerifyAmountToApplyVendorEntry(DocumentNo, -GenJournalLine.Amount, DocumentType);

        // Roll Back.
        GenJournalLine.Delete(true);
    end;

    local procedure CreateAndCheckLessAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Invoice and Payment General Line.
        DocumentNo := CreatePostAndApplyGeneralLine(GenJournalLine, DocumentType, DocumentType2, Amount);

        // Exercise: Find Posted Vendor Ledger Entry and Modify Amount to Apply with Less Value.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.Validate("Amount to Apply", -GenJournalLine.Amount / 2);
        VendorLedgerEntry.Modify(true);

        // Verify: Verify Less Amount to Apply on Vendor Ledger Entry.
        VerifyAmountToApplyVendorEntry(DocumentNo, -GenJournalLine.Amount / 2, DocumentType);

        // Roll Back.
        GenJournalLine.Delete(true);
    end;

    local procedure CreatePostAndApplyGeneralLine(var GenJournalLine2: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Line and Post.
        CreateAndPostGeneralLine(GenJournalLine, GenJournalBatch, DocumentType, Amount);

        // Create and Apply Previous Posted Entry.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType2, GenJournalLine."Account Type",
          GenJournalLine."Account No.", -GenJournalLine.Amount);
        GenJournalLine2.Validate("Applies-to Doc. Type", DocumentType);
        GenJournalLine2.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");
        GenJournalLine2.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGenAndFindVendorEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := CreatePostAndApplyGeneralLine(GenJournalLine, DocumentType, DocumentType2, Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndSetAppliesToIDOnGen(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Setup: Create and Post General Line.
        CreateAndPostGeneralLine(GenJournalLine, GenJournalBatch, DocumentType, Amount);

        // Exercise: Find Vendor Ledger Entry and Set Applies to ID.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // Verify: Verify Amount to Apply field on Vendor Ledger Entry.
        VerifyAmountToApplyVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, DocumentType);
    end;

    local procedure CreateAndPostGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Vendor: Record Vendor;
    begin
        // Create General Line and Post it.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal);
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch."Journal Template Name");
        GenJournalLine.Modify(TRUE);
    end;

    local procedure CreateGeneralLineForCorrection(var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        // Random value is taken for Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJnlLineWithBalAcc(var GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          BalAccountType, BalAccountNo, LibraryRandom.RandInt(3000));
    end;

    local procedure CreateGLAccountNoSales(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountNoPurchase(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateAndUpdateGLAccountWithVATPostingSetup(var GLAccount: Record "G/L Account"; GenPostingType: Enum "General Posting Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure PostMultilineGenJournal(NoOfLines: Integer): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        Index: Integer;
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateGeneralJournalBatch(GenJournalBatch);
        CustomerNo := LibrarySales.CreateCustomerNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        for Index := 1 to NoOfLines do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::Customer, CustomerNo,
              "Gen. Journal account Type"::"G/L Account", '',
              LibraryRandom.RandDec(100, 2));

            GenJournalLine."Document No." := DocumentNo;
            GenJournalLine.Modify(true);

            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
              "Gen. Journal document Type"::" ", '', -GenJournalLine.Amount);

            GenJournalLine."Document No." := DocumentNo;
            GenJournalLine.Modify(true);
        end;

        CodeCoverageMgt.StopApplicationCoverage();
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CodeCoverageMgt.StopApplicationCoverage();

        exit(
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Gen. Jnl.-Post Batch",
            'AccountType ? AccountType::Customer'));
    end;

    local procedure RunCreateVendorJournalLines(JournalTemplate: Code[10]; BatchName: Code[10]; TemplateCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreateVendorJournalLines: Report "Create Vendor Journal Lines";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        Clear(CreateVendorJournalLines);
        CreateVendorJournalLines.UseRequestPage(false);
        CreateVendorJournalLines.InitializeRequest(GenJournalLine."Document Type"::Invoice.AsInteger(), WorkDate(), WorkDate());
        CreateVendorJournalLines.InitializeRequestTemplate(JournalTemplate, BatchName, TemplateCode);
        CreateVendorJournalLines.Run();
    end;

    local procedure VerifyAmountToApplyError(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        Assert.AreEqual(
          StrSubstNo(
            AmountToApplyLargerError, VendorLedgerEntry.FieldCaption("Amount to Apply"),
            VendorLedgerEntry.FieldCaption("Remaining Amount"), VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."), StrSubstNo(GetLastErrorText), ValidationError);
    end;

    local procedure VerifyAmountToApplyVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        Assert.AreEqual(
          AmountToApply, VendorLedgerEntry."Amount to Apply",
          StrSubstNo(AmountEqualError, VendorLedgerEntry.FieldCaption("Amount to Apply"), AmountToApply, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorJournalLines(GenJournalBatch: Record "Gen. Journal Batch"; StandardJournalCode: Code[10]; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindSet();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        repeat
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
            GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Vendor);
            GenJournalLine.TestField("Account No.", AccountNo);
            GenJournalLine.TestField(Amount, StandardGeneralJournalLine.Amount);
            GenJournalLine.Next();
        until StandardGeneralJournalLine.Next() = 0;
    end;

    local procedure VerifyLedgerEntryForCorrection(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Credit Amount");
        VendorLedgerEntry.TestField("Credit Amount", -GenJournalLine.Amount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

