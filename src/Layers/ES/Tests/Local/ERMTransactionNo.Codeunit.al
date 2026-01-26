codeunit 144012 "ERM Transaction No."
{
    // Feature covered - Transaction No.
    // 
    //  1. Verify No. of Transaction in GL Register after post transaction with Transaction No. from General Journal.
    //  2. Verify No. of Transaction in GL Register after post transaction with Transaction No. from Payment Journal.
    //  3. Verify No. of Transaction in GL Register after post transaction with Transaction No. from Cash Receipt Journal.
    //  4. Verify No. of Transaction in GL Register after post transaction with Transaction No. from Sales Journal.
    //  5. Verify No. of Transaction in GL Register after post transaction with Transaction No. from Purchase Journal.
    //  6. Verify No. of Transaction in GL Register after post transaction without Transaction No. from General Journal.
    //  7. Verify No. of Transaction in GL Register after post transaction without Transaction No. from Payment Journal.
    //  8. Verify No. of Transaction in GL Register after post transaction without Transaction No. from Cash Receipt Journal.
    //  9. Verify No. of Transaction in GL Register after post transaction without Transaction No. from Sales Journal.
    // 10. Verify No. of Transaction in GL Register after post transaction without Transaction No. from Purchase Journal.
    // 11. Verify No. of Transaction in GL Register after post transaction with Transaction No. from Recurring Journal.
    // 12. Verify No. of Transaction in GL Register after post transaction without Transaction No. from Recurring Journal.
    // 13. Verify Period Transaction No. on GL Register after run Set Period Trans. Nos. Batch Report.
    // 14. Verify GL Register report after post General Journal with Transaction No.
    // 15. Verify Warning message and Error text on General Journal - Test report.
    // 
    // Covers Test Cases for WI: 350829
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // GeneralJournalWithTransactionNo                                                                                             151338
    // PaymentJournalWithTransactionNo,PaymentJournalWithoutTransactionNo                                                          151345
    // CashReceiptJournalWithTransactionNo,CashReceiptJournalWithoutTransactionNo                                                  151344
    // SalesJournalWithTransactionNo,SalesJournalWithoutTransactionNo                                                              151342
    // PurchaseJournalWithTransactionNo,PurchaseJournalWithoutTransactionNo                                                        151343
    // GeneralJournalWithoutTransactionNo                                                                                          151433
    // RecurringJournalWithoutTransactionNo,RecurringJournalWithTransactionNo                                                      151346
    // 
    // Covers Test Cases for WI: 351435
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // PeriodTransactionNoOnGLRegister                                                                                             151426
    // GLRegisterReportWithDifferentFilters                                                                          151427,151428,151348
    // GeneralJournalTestReportWithWarning                                                                                         151347

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ErrorTextNumberCap: Label 'ErrorTextNumber';
        ExpectedValueErr: Label 'Expected value is not equal to Actual value.';
        GLEntryCreditAmtCap: Label 'CreditAmt_GLEntry';
        GLEntryDebitAmtCap: Label 'DebitAmt_GLEntry';
        GLEntryPostDateCap: Label 'G_L_Entry__Posting_Date_';
        TransErrorTxt: Label 'Transaction %1 is out of balance by %2.';
        WarningCap: Label 'WarningCaption';
        WarningMsg: Label 'Warning!';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        OneDocSameNoErr: Label 'There must be one   invoice, credit memo, or finance charge memo with the same Document No.';

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from General Journal.
        JournalPostWithTransactionNo(GenJournalTemplate.Type::General);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalWithTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from Payment Journal.
        JournalPostWithTransactionNo(GenJournalTemplate.Type::Payments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalWithTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from Cash Receipt Journal.
        JournalPostWithTransactionNo(GenJournalTemplate.Type::"Cash Receipts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalWithTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transaction in GL Register after post transaction with Transaction No. from Sales Journal.
        JournalPostWithTransactionNo(GenJournalTemplate.Type::Sales);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalWithTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from Purchase Journal.
        JournalPostWithTransactionNo(GenJournalTemplate.Type::Purchases);
    end;

    local procedure JournalPostWithTransactionNo(Type: Enum "Gen. Journal Template Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup & Exercise.
        Initialize();
        PostJournalsWithTransactionNo(GenJournalLine, Type, LibraryRandom.RandIntInRange(1, 10));  // Using Random for Transaction No.

        // Verify: Verify No. of Transactions in GL Register.
        VerifyGLRegister(GenJournalLine, 2);  // Using 2 for compare with maximum number of transactions.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithoutTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from General Journal.
        JournalPostWithoutTransactionNo(GenJournalTemplate.Type::General);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalWithoutTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction without Transaction No. from Payment Journal.
        JournalPostWithoutTransactionNo(GenJournalTemplate.Type::Payments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalWithoutTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction without Transaction No. from Cash Receipt Journal.
        JournalPostWithoutTransactionNo(GenJournalTemplate.Type::"Cash Receipts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalWithoutTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction without Transaction No. from Sales Journal.
        JournalPostWithoutTransactionNo(GenJournalTemplate.Type::Sales);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalWithoutTransactionNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify No. of Transactions in GL Register after post transaction without Transaction No. from Purchase Journal.
        JournalPostWithoutTransactionNo(GenJournalTemplate.Type::Purchases);
    end;

    local procedure JournalPostWithoutTransactionNo(Type: Enum "Gen. Journal Template Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // Setup & Exercise.
        Initialize();
        PostJournalsWithTransactionNo(GenJournalLine, Type, 0);  // Using 0 for Transaction No.

        // Verify: Verify No. of Transaction in GL Register.
        GLRegister.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GLRegister.FindFirst();
        Assert.AreEqual(GenJournalLine."Posting Date", GLRegister."Posting Date", ExpectedValueErr);
        Assert.AreEqual(1, GLRegister.Count, ExpectedValueErr);  // Using 1 for compare with maximum number of transactions.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJournalWithTransactionNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify No. of Transactions in GL Register after post transaction with Transaction No. from Recurring Journal.

        // Setup & Exercise.
        Initialize();
        PostRecurringJournalsWithTransactionNo(GenJournalLine, LibraryRandom.RandIntInRange(1, 10));  // Using Random for Transaction No.

        // Verify: Verify No. of Transactions in GL Register.
        VerifyGLRegister(GenJournalLine, 2);  // Using 2 for compare with maximum number of transactions.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJournalWithoutTransactionNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
    begin
        // Verify No. of Transactions in GL Register after post transaction without Transaction No. from Recurring Journal.

        // Setup & Exercise.
        Initialize();
        PostRecurringJournalsWithTransactionNo(GenJournalLine, 0);  // Using 0 for Transaction No.

        // Verify: Verify No. of Transactions in GL Register.
        GLRegister.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GLRegister.FindFirst();
        Assert.AreEqual(GenJournalLine."Posting Date", GLRegister."Posting Date", ExpectedValueErr);
        Assert.AreEqual(1, GLRegister.Count, ExpectedValueErr);  // Using 1 for compare with maximum number of transactions.
    end;

    [Test]
    [HandlerFunctions('SetPeriodTransNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PeriodTransactionNoOnGLRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify Period Transaction No. on GL Register after run Set Period Trans. Nos. Batch Report.

        // Setup: Post General Journal with different Transaction No.
        Initialize();
        CreateJournalLinesWithTransactionNo(GenJournalLine, GenJournalTemplate.Type::General, LibraryRandom.RandIntInRange(1, 10));  // Using Random for Transaction No.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        SetPeriodTransNos(Format(WorkDate()));

        // Verify: Verify existance of Period Transaction No. field on GL Register.
        Assert.IsTrue(GetPeriodTransactionNo(GenJournalLine."Journal Batch Name") <> 0, ExpectedValueErr);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler,SetPeriodTransNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLRegisterReportWithDifferentFilters()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify GL Register report after post General Journal with Transaction No.

        // Setup: Post General Journal with different Transaction No.
        Initialize();
        CreateJournalLinesWithTransactionNo(GenJournalLine, GenJournalTemplate.Type::General, LibraryRandom.RandIntInRange(1, 10));  // Using Random for Transaction No.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetPeriodTransNos(Format(WorkDate()));
        LibraryVariableStorage.Enqueue(GetPeriodTransactionNo(GenJournalLine."Journal Batch Name"));  // Enqueue value for GLRegisterRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"G/L Register");

        // Verify: Verify values on GL Register Report.
        VerifyReportValues(GLEntryDebitAmtCap, GenJournalLine."Debit Amount", GLEntryPostDateCap, Format(GenJournalLine."Posting Date"));
        LibraryReportDataset.SetRange(GLEntryCreditAmtCap, GenJournalLine."Credit Amount");
        LibraryReportDataset.GetNextRow();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestReportWithWarning()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify Warning message and error text on General Journal - Test report.

        // Setup: Create General Journal line with different Transaction No.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(1, 10));  // Using Random for Amouont & Transaction No.
        CreateJournalLine(GenJournalLine, GenJournalBatch, -GenJournalLine.Amount / 2, GenJournalLine."Transaction No." + 1);  // Division by 2 required for Partial Amount & plus 1 required for different Transaction No.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");  // Enqueue value for GeneralJournalTestRequestPageHandler.
        Commit();  // Required for run General Journal - Test report.

        // Exercise.
        REPORT.Run(REPORT::"General Journal - Test");

        // Verify: Verify values on General Journal - Test report.
        VerifyReportValues(
          WarningCap, StrSubstNo(WarningMsg), ErrorTextNumberCap,
          StrSubstNo(TransErrorTxt, GenJournalLine."Transaction No.", GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversedGLRegisterPostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        // [FEATURE] [G/L Register] [Reverse]
        // [SCENARIO 372274] Reversed G/L Register has the same "Posting Date" as source G/L Register
        Initialize();

        // [GIVEN] Post General Journal with "Posting Date" = "D"
        PostJournalsWithTransactionNo(GenJournalLine, GenJournalTemplate.Type::Payments, 0);  // Using 0 for Transaction No.

        // [WHEN] Reverse last "G/L Register"
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // [THEN] Created reversed "G/L Register"."Posting Date" = "D"
        GLRegister.FindLast();
        Assert.AreEqual(GenJournalLine."Posting Date", GLRegister."Posting Date", GLRegister.FieldCaption("Posting Date"));
    end;

    [Test]
    [HandlerFunctions('SetPeriodTransNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SetPeriodTransNosWithCombinedPostingDatesAndTransactionNos()
    var
        GLEntry: array[10] of Record "G/L Entry";
        TransactionNo: Integer;
        StartPeriodNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Period Transaction No.] [Set Period Trans. Nos.] [UT]
        // [SCENARIO 266203] Report 10700 "Set Period Trans. Nos." in case of different "Transaction No." within the same "Posting Date"
        // [SCENARIO 266203] and different "Posting Date" within the same "Transaction No."
        Initialize();
        TransactionNo := GetLastTransactionNo();

        // [GIVEN] GLEntry1:  "Entry No." = 1  "Posting Date" = 03-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry2:  "Entry No." = 2  "Posting Date" = 02-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry3:  "Entry No." = 3  "Posting Date" = 01-01-2018, "Transaction No." = 2
        // [GIVEN] GLEntry4:  "Entry No." = 4  "Posting Date" = 01-01-2018, "Transaction No." = 1
        // [GIVEN] GLEntry5:  "Entry No." = 5  "Posting Date" = 01-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry6:  "Entry No." = 6  "Posting Date" = 02-01-2018, "Transaction No." = 2
        // [GIVEN] GLEntry7:  "Entry No." = 7  "Posting Date" = 02-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry8:  "Entry No." = 8  "Posting Date" = 03-01-2018, "Transaction No." = 3
        // [GIVEN] GLEntry9:  "Entry No." = 9  "Posting Date" = 03-01-2018, "Transaction No." = 1
        // [GIVEN] GLEntry10: "Entry No." = 10 "Posting Date" = 01-01-2018, "Transaction No." = 1
        MockGLEntry(GLEntry[1], WorkDate() + 3, TransactionNo + 3);
        MockGLEntry(GLEntry[2], WorkDate() + 2, TransactionNo + 3);
        MockGLEntry(GLEntry[3], WorkDate() + 1, TransactionNo + 2);
        MockGLEntry(GLEntry[4], WorkDate() + 1, TransactionNo + 1);
        MockGLEntry(GLEntry[5], WorkDate() + 1, TransactionNo + 3);
        MockGLEntry(GLEntry[6], WorkDate() + 2, TransactionNo + 2);
        MockGLEntry(GLEntry[7], WorkDate() + 2, TransactionNo + 3);
        MockGLEntry(GLEntry[8], WorkDate() + 3, TransactionNo + 3);
        MockGLEntry(GLEntry[9], WorkDate() + 3, TransactionNo + 1);
        MockGLEntry(GLEntry[10], WorkDate() + 1, TransactionNo + 1);

        // [WHEN] Run report 10700 "Set Period Trans. Nos." using Date Filter = 01-01-2018..03-01-2018
        SetPeriodTransNos(StrSubstNo('%1..%2', WorkDate() + 1, WorkDate() + 3));
        for i := 1 to ArrayLen(GLEntry) do
            GLEntry[i].Find();

        // [THEN] GLEntry4  "Period Trans. No." = 1
        // [THEN] GLEntry10 "Period Trans. No." = 1
        // [THEN] GLEntry3  "Period Trans. No." = 2
        // [THEN] GLEntry5  "Period Trans. No." = 3
        // [THEN] GLEntry6  "Period Trans. No." = 4
        // [THEN] GLEntry2  "Period Trans. No." = 5
        // [THEN] GLEntry7  "Period Trans. No." = 5
        // [THEN] GLEntry9  "Period Trans. No." = 6
        // [THEN] GLEntry1  "Period Trans. No." = 7
        // [THEN] GLEntry8  "Period Trans. No." = 7
        StartPeriodNo := GLEntry[4]."Period Trans. No.";
        GLEntry[10].TestField("Period Trans. No.", StartPeriodNo);
        GLEntry[3].TestField("Period Trans. No.", StartPeriodNo + 1);
        GLEntry[5].TestField("Period Trans. No.", StartPeriodNo + 2);
        GLEntry[6].TestField("Period Trans. No.", StartPeriodNo + 3);
        GLEntry[2].TestField("Period Trans. No.", StartPeriodNo + 4);
        GLEntry[7].TestField("Period Trans. No.", StartPeriodNo + 4);
        GLEntry[9].TestField("Period Trans. No.", StartPeriodNo + 5);
        GLEntry[1].TestField("Period Trans. No.", StartPeriodNo + 6);
        GLEntry[8].TestField("Period Trans. No.", StartPeriodNo + 6);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SetPeriodTransNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SetPeriodTransNosSeveralYears()
    var
        GLEntry: array[4] of Record "G/L Entry";
        TransactionNo: Integer;
        PostingDate: array[2] of Date;
        i: Integer;
    begin
        // [FEATURE] [Period Transaction No.] [Set Period Trans. Nos.] [UT]
        // [SCENARIO 266203] Report 10700 "Set Period Trans. Nos." in case of several G/L Entries with the same "Transaction No." and different "Posting Date" for several years
        Initialize();
        TransactionNo := GetLastTransactionNo() + 1;
        for i := 1 to ArrayLen(PostingDate) do begin
            LibraryFiscalYear.CreateFiscalYear();
            PostingDate[i] := LibraryFiscalYear.GetFirstPostingDate(false);
            LibraryFiscalYear.CloseFiscalYear();
        end;

        // [GIVEN] GLEntry1:  "Entry No." = 1  "Posting Date" = 02-01-2019, "Transaction No." = 1
        // [GIVEN] GLEntry2:  "Entry No." = 2  "Posting Date" = 01-01-2019, "Transaction No." = 1
        // [GIVEN] GLEntry3:  "Entry No." = 3  "Posting Date" = 02-01-2018, "Transaction No." = 1
        // [GIVEN] GLEntry4:  "Entry No." = 4  "Posting Date" = 01-01-2018, "Transaction No." = 1
        MockGLEntry(GLEntry[1], PostingDate[2] + 1, TransactionNo);
        MockGLEntry(GLEntry[2], PostingDate[2], TransactionNo);
        MockGLEntry(GLEntry[3], PostingDate[1] + 1, TransactionNo);
        MockGLEntry(GLEntry[4], PostingDate[1], TransactionNo);

        // [WHEN] Run report 10700 "Set Period Trans. Nos." using Date Filter = 01-01-2018..03-01-2018
        SetPeriodTransNos(StrSubstNo('%1..%2', PostingDate[1], PostingDate[2] + 1));
        for i := 1 to ArrayLen(GLEntry) do
            GLEntry[i].Find();

        // [THEN] GLEntry4 "Period Trans. No." = 2
        // [THEN] GLEntry3 "Period Trans. No." = 3
        // [THEN] GLEntry2 "Period Trans. No." = 2
        // [THEN] GLEntry1 "Period Trans. No." = 3
        GLEntry[4].TestField("Period Trans. No.", 2);
        GLEntry[3].TestField("Period Trans. No.", 3);
        GLEntry[2].TestField("Period Trans. No.", 2);
        GLEntry[1].TestField("Period Trans. No.", 3);
    end;

    [Test]
    [HandlerFunctions('SetPeriodTransNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesPageHasPeriodTransNoFieldAndAction()
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Period Transaction No.] [UI] [UT]
        // [SCENARIO 266203] There is a field "Period Trans. No." and action "Set Period Trans. Nos." on the "General Ledger Entries" page
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        MockGLEntry(GLEntry, WorkDate() + 1, GetLastTransactionNo() + 1);

        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.GotoRecord(GLEntry);
        Assert.IsTrue(GeneralLedgerEntries."Period Trans. No.".Enabled(), '');
        Assert.IsTrue(GeneralLedgerEntries."Period Trans. No.".Visible(), '');
        Assert.IsTrue(GeneralLedgerEntries.SetPeriodTransNos.Enabled(), '');
        Assert.IsTrue(GeneralLedgerEntries.SetPeriodTransNos.Visible(), '');
        GeneralLedgerEntries."Period Trans. No.".AssertEquals(0);
        GeneralLedgerEntries.Close();

        SetPeriodTransNos(Format(WorkDate() + 1));
        GLEntry.Find();

        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.GotoRecord(GLEntry);
        GeneralLedgerEntries."Period Trans. No.".AssertEquals(GLEntry."Period Trans. No.");
        GeneralLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJournalWithAllocationSaleGenPostingType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        // [FEATURE] [Recurring Journal] [Sales]
        // [SCENARIO 273494] Post Recurring Journal Line of G/L Account Type and it's Allocation with Sale Gen. Posting Type.
        Initialize();

        // [GIVEN] Recurring Journal Line with "Account Type" = "G/L Account" and empty "Gen. Posting Type".
        // [GIVEN] Allocation Line with "Gen. Posting Type" = Sale.
        // [WHEN] Post Recurring Journal Line.
        asserterror CreateAndPostRecurringJnlLineWithAllocation(GenJournalLine, GenJnlAllocation, LibraryERM.CreateGLAccountWithSalesSetup());

        // [THEN] Error "There must be one invoice, credit memo, or finance charge memo with the same Document No." is thrown.
        Assert.ExpectedError(OneDocSameNoErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringJournalWithAllocationPurchaseGenPostingType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        // [FEATURE] [Recurring Journal] [Purchase]
        // [SCENARIO 273494] Post Recurring Journal Line of G/L Account Type and it's Allocation with Purchase Gen. Posting Type.
        Initialize();

        // [GIVEN] Recurring Journal Line with "Account Type" = "G/L Account" and empty "Gen. Posting Type".
        // [GIVEN] Allocation Line with "Gen. Posting Type" = Purchase.
        // [WHEN] Post Recurring Journal Line.
        asserterror CreateAndPostRecurringJnlLineWithAllocation(GenJournalLine, GenJnlAllocation, LibraryERM.CreateGLAccountWithPurchSetup());

        // [THEN] Error "There must be one invoice, credit memo, or finance charge memo with the same Document No." is thrown.
        Assert.ExpectedError(OneDocSameNoErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal; TransactionNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Transaction No.", TransactionNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLinesWithTransactionNo(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type"; TransactionNo: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        CreateJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), TransactionNo);  // Using Random for Amount.
        CreateJournalLine(GenJournalLine, GenJournalBatch, -GenJournalLine.Amount, GenJournalLine."Transaction No.");
        CreateJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), TransactionNo + TransactionNo);  // Using Random for Amount.
        CreateJournalLine(GenJournalLine, GenJournalBatch, -GenJournalLine.Amount, GenJournalLine."Transaction No.");
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal; TransactionNo: Integer)
    var
        RecurringFrequency: DateFormula;
    begin
        CreateJournalLine(GenJournalLine, GenJournalBatch, Amount, TransactionNo);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        Evaluate(RecurringFrequency, '<1M>');  // Required 1 Month.
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAllocationLine(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AllocationPercent: Decimal)
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", AccountNo);
        GenJnlAllocation.Validate("Allocation %", AllocationPercent);
        GenJnlAllocation.Modify(true);
    end;

    local procedure CreateAndPostRecurringJnlLineWithAllocation(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation"; AllocationAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);

        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), 0);
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, AllocationAccountNo, 100);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; PostingDate: Date; TransactionNo: Integer)
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Transaction No." := TransactionNo;
        GLEntry.Insert();
    end;

    local procedure GetPeriodTransactionNo(JournalBatchName: Code[10]): Integer
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        GLRegister.FindLast();
        GLEntry.Get(GLRegister."From Entry No.");
        exit(GLEntry."Period Trans. No.");
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure PostJournalsWithTransactionNo(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type"; TransactionNo: Integer)
    begin
        // Setup: Create General Journal Batch, create multiline Transaction on Gen. Journal Line with Transaction No.
        CreateJournalLinesWithTransactionNo(GenJournalLine, Type, TransactionNo);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostRecurringJournalsWithTransactionNo(var GenJournalLine: Record "Gen. Journal Line"; TransactionNo: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup: Create Recurring General Journal Template & Batch, create multiline Transaction on Recurring Gen. Journal Line with Transaction No.
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), TransactionNo);  // Using Random for Amount.
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, -GenJournalLine.Amount, GenJournalLine."Transaction No.");
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandDec(100, 2), TransactionNo + TransactionNo);  // Using Random for Amount.
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, -GenJournalLine.Amount, GenJournalLine."Transaction No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetPeriodTransNos(DateFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(DateFilter);
        Commit();
        REPORT.Run(REPORT::"Set Period Trans. Nos.");
    end;

    local procedure VerifyGLRegister(GenJournalLine: Record "Gen. Journal Line"; NoOfTransaction: Integer)
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GLRegister.FindLast();
        GLRegister.TestField("Posting Date", GenJournalLine."Posting Date");
        Assert.AreEqual(NoOfTransaction, GLRegister.Count, ExpectedValueErr);
    end;

    local procedure VerifyReportValues(Caption: Text; Value: Variant; Caption2: Text; Value2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    var
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalBatchName);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRegisterRequestPageHandler(var GLRegisterPage: TestRequestPage "G/L Register")
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        GLEntry.Get(GLRegister."From Entry No.");
        GLEntry.TestField("Period Trans. No.", LibraryVariableStorage.DequeueInteger());

        GLRegisterPage."G/L Register".SetFilter("No.", Format(GLRegister."No."));
        GLRegisterPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SetPeriodTransNosRequestPageHandler(var SetPeriodTransNos: TestRequestPage "Set Period Trans. Nos.")
    begin
        SetPeriodTransNos."G/L Entry".SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        SetPeriodTransNos.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

