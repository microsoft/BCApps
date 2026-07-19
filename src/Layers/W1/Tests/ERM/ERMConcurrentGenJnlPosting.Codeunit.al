// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134080 "ERM Concurrent Gen.Jnl.Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Posting] [Concurrent Posting]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineWithConcurrentPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        LastGLEntryNo: Integer;
        LastGLRegisterNo: Integer;
    begin
        // [FEATURE] [Gen. Journal] [Concurrent Posting]
        // [SCENARIO] Posting a G/L journal line with "Use Concurrent Posting" = TRUE creates G/L entries and a G/L Register.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is enabled
        EnableConcurrentPosting(true);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if GLRegister.FindLast() then
            LastGLRegisterNo := GLRegister."No.";

        // [GIVEN] A balanced Gen. Journal Line
        CreateSimpleGLJournalLine(GenJournalLine);
        Commit();

        // [WHEN] The journal line is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting');

        // [THEN] The G/L entry has a SIFT Bucket No. equal to Entry No. mod 5
        Assert.AreEqual(GLEntry."Entry No." mod 5, GLEntry."SIFT Bucket No.", 'SIFT Bucket No. must equal Entry No. mod 5');

        // [THEN] A new G/L Register is created
        GLRegister.SetFilter("No.", '>%1', LastGLRegisterNo);
        Assert.IsTrue(GLRegister.FindFirst(), 'A G/L Register should have been created after posting');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineWithLegacyPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        LastGLEntryNo: Integer;
        LastGLRegisterNo: Integer;
    begin
        // [FEATURE] [Gen. Journal] [Legacy Posting]
        // [SCENARIO] Posting a G/L journal line with "Use Concurrent Posting" = FALSE creates G/L entries and a G/L Register.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is disabled (legacy)
        EnableConcurrentPosting(false);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if GLRegister.FindLast() then
            LastGLRegisterNo := GLRegister."No.";

        // [GIVEN] A balanced Gen. Journal Line
        CreateSimpleGLJournalLine(GenJournalLine);
        Commit();

        // [WHEN] The journal line is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting');

        // [THEN] The G/L entry has a SIFT Bucket No. equal to Entry No. mod 5
        Assert.AreEqual(GLEntry."Entry No." mod 5, GLEntry."SIFT Bucket No.", 'SIFT Bucket No. must equal Entry No. mod 5');

        // [THEN] A new G/L Register is created
        GLRegister.SetFilter("No.", '>%1', LastGLRegisterNo);
        Assert.IsTrue(GLRegister.FindFirst(), 'A G/L Register should have been created after posting');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithConcurrentPosting()
    var
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastGLEntryNo: Integer;
        LastDtldEntryNo: Integer;
    begin
        // [FEATURE] [Sales] [Concurrent Posting]
        // [SCENARIO] Posting a Sales Invoice with "Use Concurrent Posting" = TRUE creates G/L entries and Detailed Cust. Ledg. entries.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is enabled
        EnableConcurrentPosting(true);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if DetailedCustLedgEntry.FindLast() then
            LastDtldEntryNo := DetailedCustLedgEntry."Entry No.";

        // [GIVEN] A Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        Commit();

        // [WHEN] The Sales Invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting the Sales Invoice');

        // [THEN] Each new G/L entry has SIFT Bucket No. = Entry No. mod 5
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5 for all new G/L entries');
        until GLEntry.Next() = 0;

        // [THEN] New Detailed Cust. Ledg. entries are created
        DetailedCustLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(DetailedCustLedgEntry.FindFirst(), 'Detailed Cust. Ledg. entries should have been created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithConcurrentPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastGLEntryNo: Integer;
        LastDtldEntryNo: Integer;
    begin
        // [FEATURE] [Purchase] [Concurrent Posting]
        // [SCENARIO] Posting a Purchase Invoice with "Use Concurrent Posting" = TRUE creates G/L entries and Detailed Vendor Ledg. entries.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is enabled
        EnableConcurrentPosting(true);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if DetailedVendorLedgEntry.FindLast() then
            LastDtldEntryNo := DetailedVendorLedgEntry."Entry No.";

        // [GIVEN] A Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        Commit();

        // [WHEN] The Purchase Invoice is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting the Purchase Invoice');

        // [THEN] Each new G/L entry has SIFT Bucket No. = Entry No. mod 5
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5 for all new G/L entries');
        until GLEntry.Next() = 0;

        // [THEN] New Detailed Vendor Ledg. entries are created
        DetailedVendorLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(DetailedVendorLedgEntry.FindFirst(), 'Detailed Vendor Ledg. entries should have been created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGetNextEntryNoReturnsPositiveValue()
    var
        VATEntry: Record "VAT Entry";
        NextNo: Integer;
    begin
        // [FEATURE] [VAT Entry] [Sequence]
        // [SCENARIO] VATEntry.GetNextEntryNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextEntryNo is called
        NextNo := VATEntry.GetNextEntryNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'VATEntry.GetNextEntryNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedCustLedgEntryGetNextEntryNoReturnsPositiveValue()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NextNo: Integer;
    begin
        // [FEATURE] [Detailed Cust. Ledg. Entry] [Sequence]
        // [SCENARIO] DetailedCustLedgEntry.GetNextEntryNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextEntryNo is called
        NextNo := DetailedCustLedgEntry.GetNextEntryNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'DetailedCustLedgEntry.GetNextEntryNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedVendLedgEntryGetNextEntryNoReturnsPositiveValue()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        NextNo: Integer;
    begin
        // [FEATURE] [Detailed Vendor Ledg. Entry] [Sequence]
        // [SCENARIO] DetailedVendorLedgEntry.GetNextEntryNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextEntryNo is called
        NextNo := DetailedVendorLedgEntry.GetNextEntryNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'DetailedVendorLedgEntry.GetNextEntryNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedEmplLedgEntryGetNextEntryNoReturnsPositiveValue()
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        NextNo: Integer;
    begin
        // [FEATURE] [Detailed Employee Ledger Entry] [Sequence]
        // [SCENARIO] DetailedEmployeeLedgerEntry.GetNextEntryNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextEntryNo is called
        NextNo := DetailedEmployeeLedgerEntry.GetNextEntryNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'DetailedEmployeeLedgerEntry.GetNextEntryNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegisterGetNextRegisterNoReturnsPositiveValue()
    var
        GLRegister: Record "G/L Register";
        NextNo: Integer;
    begin
        // [FEATURE] [G/L Register] [Sequence]
        // [SCENARIO] GLRegister.GetNextRegisterNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextRegisterNo is called
        NextNo := GLRegister.GetNextRegisterNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'GLRegister.GetNextRegisterNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegisterGetNextRegisterNoIsMonotonicallyIncreasing()
    var
        GLRegister: Record "G/L Register";
        FirstNo: Integer;
        SecondNo: Integer;
    begin
        // [FEATURE] [G/L Register] [Sequence]
        // [SCENARIO] Successive calls to GLRegister.GetNextRegisterNo() return strictly increasing values.
        Initialize();

        // [WHEN] GetNextRegisterNo is called twice
        FirstNo := GLRegister.GetNextRegisterNo();
        SecondNo := GLRegister.GetNextRegisterNo();

        // [THEN] The second value is strictly greater than the first
        Assert.IsTrue(SecondNo > FirstNo, 'Successive calls to GLRegister.GetNextRegisterNo() must return increasing values');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineWithVATConcurrentPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        LastGLEntryNo: Integer;
        LastVATEntryNo: Integer;
    begin
        // [FEATURE] [VAT] [Concurrent Posting]
        // [SCENARIO] Posting a journal line with VAT with "Use Concurrent Posting" = TRUE creates both G/L entries and VAT entries.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is enabled
        EnableConcurrentPosting(true);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if VATEntry.FindLast() then
            LastVATEntryNo := VATEntry."Entry No.";

        // [GIVEN] A journal line posted to a VAT-enabled account
        CreateVATJournalLine(GenJournalLine, GenJournalBatch);
        Commit();

        // [WHEN] The journal is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created');

        // [THEN] New VAT entries are created
        VATEntry.SetFilter("Entry No.", '>%1', LastVATEntryNo);
        Assert.IsTrue(VATEntry.FindFirst(), 'VAT entries should have been created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleGenJnlLinesWithConcurrentPosting()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        LastGLEntryNo: Integer;
        LastGLRegisterNo: Integer;
        EntryCount: Integer;
    begin
        // [FEATURE] [Gen. Journal] [Concurrent Posting]
        // [SCENARIO] Posting multiple journal lines with "Use Concurrent Posting" = TRUE creates sequential G/L entries in a single register.
        Initialize();

        // [GIVEN] "Use Concurrent Posting" is enabled
        EnableConcurrentPosting(true);

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";
        if GLRegister.FindLast() then
            LastGLRegisterNo := GLRegister."No.";

        // [GIVEN] A batch with multiple balanced journal lines
        CreateGenJnlBatch(GenJournalBatch);
        CreateBalancedGLJournalLine(GenJournalBatch, GenJournalLine);
        CreateBalancedGLJournalLine(GenJournalBatch, GenJournalLine);
        CreateBalancedGLJournalLine(GenJournalBatch, GenJournalLine);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Commit();

        // [WHEN] The batch is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        EntryCount := GLEntry.Count();
        Assert.IsTrue(EntryCount > 0, 'G/L entries should have been created for each journal line');

        // [THEN] All new G/L entries have SIFT Bucket No. = Entry No. mod 5
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(
                GLEntry."Entry No." mod 5,
                GLEntry."SIFT Bucket No.",
                'SIFT Bucket No. must equal Entry No. mod 5');
        until GLEntry.Next() = 0;

        // [THEN] Exactly one new G/L Register is created for the batch
        GLRegister.SetFilter("No.", '>%1', LastGLRegisterNo);
        Assert.AreEqual(1, GLRegister.Count(), 'Exactly one G/L Register should be created per batch posting');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Concurrent Gen.Jnl.Posting");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Concurrent Gen.Jnl.Posting");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Concurrent Gen.Jnl.Posting");
    end;

    local procedure EnableConcurrentPosting(Enable: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use Concurrent Posting" := Enable;
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreateGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateSimpleGLJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatch(GenJournalBatch);
        CreateBalancedGLJournalLine(GenJournalBatch, GenJournalLine);
    end;

    local procedure CreateBalancedGLJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryRandom.RandDecInRange(1000, 10000, 2));
    end;

    local procedure CreateVATJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Modify(true);

        CreateGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            GLAccount."No.",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryRandom.RandDecInRange(1000, 10000, 2));
    end;
}
