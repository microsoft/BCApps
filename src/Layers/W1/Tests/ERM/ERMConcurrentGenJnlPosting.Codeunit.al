// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134080 "ERM Concurrent Gen.Jnl.Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

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
        CaptureNextVATEntryNo: Boolean;
        InsertedVATEntryNo: Integer;
        EventNextVATEntryNo: Integer;

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

        // [WHEN] The journal line is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting');

        // [THEN] The G/L entry has a SIFT Bucket No. equal to Entry No. mod 5
        Assert.AreEqual(GLEntry."Entry No." mod 5, GLEntry."SIFT Bucket No.", 'SIFT Bucket No. must equal Entry No. mod 5');

        // [THEN] A new G/L Register is created
        GLRegister.SetFilter("No.", '>%1', LastGLRegisterNo);
        Assert.IsTrue(not GLRegister.IsEmpty(), 'A G/L Register should have been created after posting');
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

        // [WHEN] The journal line is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst(), 'G/L entries should have been created after posting');

        // [THEN] The G/L entry has a SIFT Bucket No. equal to Entry No. mod 5
        Assert.AreEqual(GLEntry."Entry No." mod 5, GLEntry."SIFT Bucket No.", 'SIFT Bucket No. must equal Entry No. mod 5');

        // [THEN] A new G/L Register is created
        GLRegister.SetFilter("No.", '>%1', LastGLRegisterNo);
        Assert.IsTrue(not GLRegister.IsEmpty(), 'A G/L Register should have been created after posting');
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

        // [WHEN] The Sales Invoice is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(not GLEntry.IsEmpty(), 'G/L entries should have been created after posting the Sales Invoice');

        // [THEN] Each new G/L entry has SIFT Bucket No. = Entry No. mod 5
        if GLEntry.FindSet() then
            repeat
                Assert.AreEqual(
                    GLEntry."Entry No." mod 5,
                    GLEntry."SIFT Bucket No.",
                    'SIFT Bucket No. must equal Entry No. mod 5 for all new G/L entries');
            until GLEntry.Next() = 0;

        // [THEN] New Detailed Cust. Ledg. entries are created
        DetailedCustLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(not DetailedCustLedgEntry.IsEmpty(), 'Detailed Cust. Ledg. entries should have been created');
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

        // [WHEN] The Purchase Invoice is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(not GLEntry.IsEmpty(), 'G/L entries should have been created after posting the Purchase Invoice');

        // [THEN] Each new G/L entry has SIFT Bucket No. = Entry No. mod 5
        if GLEntry.FindSet() then
            repeat
                Assert.AreEqual(
                    GLEntry."Entry No." mod 5,
                    GLEntry."SIFT Bucket No.",
                    'SIFT Bucket No. must equal Entry No. mod 5 for all new G/L entries');
            until GLEntry.Next() = 0;

        // [THEN] New Detailed Vendor Ledg. entries are created
        DetailedVendorLedgEntry.SetFilter("Entry No.", '>%1', LastDtldEntryNo);
        Assert.IsTrue(not DetailedVendorLedgEntry.IsEmpty(), 'Detailed Vendor Ledg. entries should have been created');
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
        // [SCENARIO] GLRegister.GetNextEntryNo() returns a value greater than zero.
        Initialize();

        // [WHEN] GetNextEntryNo is called
        NextNo := GLRegister.GetNextEntryNo();

        // [THEN] The returned value is positive
        Assert.IsTrue(NextNo > 0, 'GLRegister.GetNextEntryNo() must return a positive value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegisterGetNextEntryNoIsMonotonicallyIncreasing()
    var
        GLRegister: Record "G/L Register";
        FirstNo: Integer;
        SecondNo: Integer;
    begin
        // [FEATURE] [G/L Register] [Sequence]
        // [SCENARIO] Successive calls to GLRegister.GetNextEntryNo() return strictly increasing values.
        Initialize();

        // [WHEN] GetNextEntryNo is called twice
        FirstNo := GLRegister.GetNextEntryNo();
        SecondNo := GLRegister.GetNextEntryNo();

        // [THEN] The second value is strictly greater than the first
        Assert.IsTrue(SecondNo > FirstNo, 'Successive calls to GLRegister.GetNextEntryNo() must return increasing values');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLRegisterGetNextEntryNoIsUniqueAndGapFreeAcrossSessions()
    var
        ConcurrentSeqTestBuffer: Record "Concurrent Seq. Test Buffer";
        RunId: Guid;
        FirstSessionId: Integer;
        SecondSessionId: Integer;
        PreviousEntryNo: Integer;
        ExpectedResultCount: Integer;
        TimeoutAt: DateTime;
        IsFirstEntry: Boolean;
    begin
        // [FEATURE] [G/L Register] [Sequence] [Concurrent Posting]
        // [SCENARIO] Overlapping G/L Register entry number allocations from separate sessions are unique and gap-free.
        Initialize();
        EnableConcurrentPosting(true);

        // [GIVEN] Two background sessions waiting at the same allocation barrier
        RunId := CreateGuid();
        CreateConcurrentSequenceSession(ConcurrentSeqTestBuffer, RunId, 1);
        CreateConcurrentSequenceSession(ConcurrentSeqTestBuffer, RunId, 2);
        Commit();

        ConcurrentSeqTestBuffer.Get(RunId, 1, 0);
        Assert.IsTrue(
            StartSession(FirstSessionId, Codeunit::"Concurrent Seq. No. Runner", CompanyName(), ConcurrentSeqTestBuffer),
            'The first concurrent sequence allocation session could not be started');
        ConcurrentSeqTestBuffer.Get(RunId, 2, 0);
        Assert.IsTrue(
            StartSession(SecondSessionId, Codeunit::"Concurrent Seq. No. Runner", CompanyName(), ConcurrentSeqTestBuffer),
            'The second concurrent sequence allocation session could not be started');

        // [WHEN] Both sessions allocate G/L Register numbers concurrently
        TimeoutAt := CurrentDateTime() + 30000;
        while (IsSessionActive(FirstSessionId) or IsSessionActive(SecondSessionId)) and (CurrentDateTime() < TimeoutAt) do
            Sleep(100);
        Assert.IsFalse(IsSessionActive(FirstSessionId), 'The first concurrent sequence allocation session timed out');
        Assert.IsFalse(IsSessionActive(SecondSessionId), 'The second concurrent sequence allocation session timed out');

        // [THEN] All allocated numbers are present, unique, and gap-free
        ExpectedResultCount := 2 * ConcurrentSeqTestBuffer.GetNoOfAllocationsPerSession();
        ConcurrentSeqTestBuffer.SetRange("Run ID", RunId);
        ConcurrentSeqTestBuffer.SetFilter("Allocation Index", '>0');
        Assert.AreEqual(ExpectedResultCount, ConcurrentSeqTestBuffer.Count(), 'Both sessions must persist every allocated G/L Register number');
        ConcurrentSeqTestBuffer.SetCurrentKey("Run ID", "Entry No.");
        IsFirstEntry := true;
        ConcurrentSeqTestBuffer.FindSet();
        repeat
            if IsFirstEntry then
                IsFirstEntry := false
            else
                Assert.AreEqual(PreviousEntryNo + 1, ConcurrentSeqTestBuffer."Entry No.", 'Concurrent G/L Register numbers must be unique and gap-free');
            PreviousEntryNo := ConcurrentSeqTestBuffer."Entry No.";
        until ConcurrentSeqTestBuffer.Next() = 0;

        ConcurrentSeqTestBuffer.DeleteAll();
        Commit();
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

        // [WHEN] The journal is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] New G/L entries are created
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(not GLEntry.IsEmpty(), 'G/L entries should have been created');

        // [THEN] New VAT entries are created
        VATEntry.SetFilter("Entry No.", '>%1', LastVATEntryNo);
        Assert.IsTrue(not VATEntry.IsEmpty(), 'VAT entries should have been created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnAfterInsertVATEntryPreservesNextEntryNoContractWithConcurrentPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ERMConcurrentGenJnlPosting: Codeunit "ERM Concurrent Gen.Jnl.Posting";
    begin
        // [FEATURE] [VAT] [Concurrent Posting] [Event]
        // [SCENARIO] OnAfterInsertVATEntry exposes the inserted VAT entry number plus one when concurrent posting is enabled.
        Initialize();
        EnableConcurrentPosting(true);
        CreateVATJournalLine(GenJournalLine, GenJournalBatch);
        ERMConcurrentGenJnlPosting.StartCapturingNextVATEntryNo();
        BindSubscription(ERMConcurrentGenJnlPosting);

        // [WHEN] A VAT entry is inserted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UnbindSubscription(ERMConcurrentGenJnlPosting);

        // [THEN] The event keeps its legacy NextEntryNo contract
        ERMConcurrentGenJnlPosting.VerifyCapturedNextVATEntryNo();
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
        GenJournalLine.FindFirst(); // Required for ES
        GenJournalLine.ModifyAll("Document No.", GenJournalLine."Document No.");

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

    local procedure CreateConcurrentSequenceSession(var ConcurrentSeqTestBuffer: Record "Concurrent Seq. Test Buffer"; RunId: Guid; SessionNo: Integer)
    begin
        ConcurrentSeqTestBuffer.Init();
        ConcurrentSeqTestBuffer."Run ID" := RunId;
        ConcurrentSeqTestBuffer."Session No." := SessionNo;
        ConcurrentSeqTestBuffer."Allocation Index" := 0;
        ConcurrentSeqTestBuffer.Insert();
    end;

    internal procedure StartCapturingNextVATEntryNo()
    begin
        CaptureNextVATEntryNo := true;
    end;

    internal procedure VerifyCapturedNextVATEntryNo()
    begin
        Assert.IsFalse(CaptureNextVATEntryNo, 'OnAfterInsertVATEntry must be raised for the posted VAT entry');
        Assert.AreEqual(InsertedVATEntryNo + 1, EventNextVATEntryNo, 'OnAfterInsertVATEntry must expose the inserted VAT entry number plus one');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterInsertVATEntry, '', false, false)]
    local procedure CaptureNextEntryNoOnAfterInsertVATEntry(GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry"; GLEntryNo: Integer; var NextEntryNo: Integer; var TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary)
    begin
        if not CaptureNextVATEntryNo then
            exit;

        InsertedVATEntryNo := VATEntry."Entry No.";
        EventNextVATEntryNo := NextEntryNo;
        CaptureNextVATEntryNo := false;
    end;
}
