codeunit 134130 "ERM Reverse And VAT Settlement"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Settlement]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        VATCalculationType: Enum "Tax Calculation Type";
        GenPostingType: Enum "General Posting Type";
        GenJnlDocumentType: Enum "Gen. Journal Document Type";
        GenJnlAccountType: Enum "Gen. Journal Account Type";
        isInitialized: Boolean;
        MakeInconsistent: Boolean;
        ReversalError: Label 'You cannot reverse %1 No. %2 because the entry is closed.', Comment = '%1: Table Caption;%2: Field Value';
        VATBaseError: Label '%1 amount must be %2 in %3.';
        ReverseDateCompressErr: Label 'The transaction cannot be reversed, because the %1 has been compressed.', Comment = '%1 - Table Name';
        DocNo: Label 'Test1';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcVATSettlementAndVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATAmount: Decimal;
    begin
        // [SCENARIO] Check VAT Settlement VAT Entry after Run VAT Settlement Batch job for Posted General Journal Lines.

        // Setup: First run VAT Settlement Report to Calculate VAT Entry for all records, then Create and Post General Journal Line and
        // Run VAT Settlement Report for Posted Entry only.
        Initialize();
        CalcAndVATSettlement(LibraryERM.CreateGLAccountNo(), DocNo);
        CreatePostGeneralJournalLine(GenJournalLine, WorkDate());
        VATAmount :=
          FindVATAmount(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group", GenJournalLine.Amount);

        // Exercise: Run VAT Settlement Batch Job.
        CalcAndVATSettlement(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Verify: Verify VAt Settlement VAt Entry has been created.
        VerifyVATEntry(GenJournalLine."Document No.", -VATAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcVATSettlementAndReverse()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reverse]
        // [SCENARIO] Check Reverse Transaction Error after Run VAT Settlement Batch job for Posted General Journal Lines.

        // Setup: First run VAT Settlement Report to Calculate VAT Entry for all records, then Create and Post General Journal Line and
        // VAT Settlement Report for Posted Entry only.
        Initialize();
        CalcAndVATSettlement(LibraryERM.CreateGLAccountNo(), DocNo);
        CreatePostGeneralJournalLine(GenJournalLine, WorkDate());

        // Exercise: Run VAT Settlement Batch Job.
        CalcAndVATSettlement(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Verify: Verify that Error raised during Reversal on GL Account after run VAT Settlement Batch job.
        ReverseGLAccount(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATEntryDateCompress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLEntry: Record "G/L Entry";
        DummyVATEntry: Record "VAT Entry";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        TransactionNo: Integer;
    begin
        // [FEATURE] [Date Compress] [Reverse]
        // [SCENARIO] Check Reverse Transaction Error after Run Date Compression VAT Entry Batch job for Posted General Journal Lines.

        // [GIVEN] Posted General Journal Line with Transaction No. = 200
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        CreatePostGeneralJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true));
        TransactionNo := GetGLEntryTransactionNo(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // [GIVEN] Run Date Compress Batch job for VAT Entries.
        DateCompressVATEntry(GenJournalLine."Posting Date");
        // [GIVEN] Last TransactionNo = 201 (TFS 380533)
        GLEntry.FindLast();
        GLEntry.TestField("Transaction No.", TransactionNo + 1);

        // [WHEN] Reverse posted Journal line
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Error raised 'The transaction cannot be reversed, because the VAT Entry has been compressed'
        Assert.ExpectedError(StrSubstNo(ReverseDateCompressErr, DummyVATEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocNormalVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Normal VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Normal VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnSalesDocNormalVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Sales Invoices with different VAT Posting Setup of "Normal VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Normal VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Normal VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocReverseChargeVATInconsitencies()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        ERMReverseAndVATSettlement: Codeunit "ERM Reverse And VAT Settlement";
        GLEntriesPreview: TestPage "G/L Entries Preview";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TotalBalance: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO ] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type with added inconsistency.
        Initialize();

        BindSubscription(ERMReverseAndVATSettlement);
        ERMReverseAndVATSettlement.SetMakeInconsistent();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostPurchaseInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostPurchaseInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostPurchaseInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        GLEntriesPreview.Trap();
        RunCalcAndPostVATSettlementReportWithoutRequestPage(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Check Document No. in G/L Entries Preview
        TotalBalance := 0;
        GLEntriesPreview.First();
        repeat
            Assert.AreEqual(VATSettlementDocNo, Format(GLEntriesPreview."Document No."), 'Wrong Document No. in G/L Entries Preview');
            Evaluate(Amount, GLEntriesPreview.Amount.Value);
            TotalBalance := TotalBalance + Amount;
        until not GLEntriesPreview.Next();
        GLEntriesPreview.Close();
        Assert.AreNotEqual(0, TotalBalance, 'Total balance should not be 0');

        asserterror Commit();
        Assert.IsTrue(
            StrPos(
                GetLastErrorText(),
                'The transaction cannot be completed because it will cause inconsistencies') > 0, 'Missing inconsistency error');

        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnSalesDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Sales Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostSalesInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostSalesInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostSalesInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostPurchaseInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostPurchaseInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostPurchaseInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocReverseChargeVAT()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Reverse Charge VAT" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Reverse Charge VAT".
        CreateThreeVATPostingSetup(VATPostingSetup, VATCalculationType::"Reverse Charge VAT");

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostPurchaseInvoice(VATPostingSetup[1]);
        PostedDocNo[2] := CreateAndPostPurchaseInvoice(VATPostingSetup[2]);
        PostedDocNo[3] := CreateAndPostPurchaseInvoice(VATPostingSetup[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnSalesDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Sales Invoices with different VAT Posting Setup of "Sales Tax" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnSalesDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Sales] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Sales Invoices with different VAT Posting Setup of "Sales Tax" calculation type.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Sales Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Sale);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocSalesTaxUseTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = true.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocSalesTaxUseTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = true.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostSetOnPurchaseDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = false.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, true);

        // [THEN] Three VAT Entries with Entry No. 904, 905, 906 and with Type "Settlement" were created.
        // [THEN] VAT Entries 901, 902, 903 were closed. Closed by Entry No. for each of these VAT Entries was set to 904, 905, 906 respectively.
        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        GetSettlementVATEntriesNo(SettlementVATEntryNo, VATPostingSetup, VATSettlementDocNo);
        VerifyVATEntryClosedByEntryNo(VATEntry, SettlementVATEntryNo);
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure RunCalcPostVATSttlmtWithPostNotSetOnPurchaseDocSalesTax()
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATEntry: array[3] of Record "VAT Entry";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[3] of Code[20];
        VATSettlementDocNo: Code[20];
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: array[3] of Code[20];
        SettlementVATEntryNo: array[3] of Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Sales Tax]
        // [SCENARIO 398537] Run Calc. and Post VAT Settlement report with Post option not set on three posted Purchase Invoices with different VAT Posting Setup of "Sales Tax" calculation type. "Use Tax" = false.
        Initialize();

        // [GIVEN] Three VAT Posting Setup records with VAT Calculation Type = "Sales Tax".
        CreateAndSetupThreeSalesTaxVATPostingSetup(VATPostingSetup, TaxAreaCode, TaxGroupCode);

        // [GIVEN] Three posted Purchase Invoices, each posted with its own VAT Posting Setup. Three VAT Entries with Entry No. 901, 902, 903 are created.
        PostedDocNo[1] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[1], TaxAreaCode[1], TaxGroupCode[1]);
        PostedDocNo[2] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[2], TaxAreaCode[2], TaxGroupCode[2]);
        PostedDocNo[3] := CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup[3], TaxAreaCode[3], TaxGroupCode[3]);

        // [WHEN] Run report Calc. And Post VAT Settlement with Post option not set. Show VAT Entries option is set.
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlementReport(VATSettlementDocNo, VATPostingSetup, false);

        // [THEN] "Entry No." for Settlement VAT Entries in report results are 904, 905, 906.
        FindVATEntries(VATEntry, VATPostingSetup, PostedDocNo, GenPostingType::Purchase);
        DummyVATEntry.FindLast();
        SettlementVATEntryNo[1] := DummyVATEntry."Entry No." + 1;
        SettlementVATEntryNo[2] := DummyVATEntry."Entry No." + 2;
        SettlementVATEntryNo[3] := DummyVATEntry."Entry No." + 3;
        VerifyVATEntryNoInVATSettlementReportResults(VATEntry, SettlementVATEntryNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Reverse And VAT Settlement");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Reverse And VAT Settlement");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySales.SetInvoiceRounding(false);
        LibraryPurchase.SetInvoiceRounding(false);

        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(VATPostingSetup: Record "VAT Posting Setup") PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateAndPostGenJnlLineSalesInvoiceForSalesTax(VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]) PostedDocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenBusinessPostingGroup.Modify(true);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJnlDocumentType::Invoice, GenJnlAccountType::"G/L Account",
          LibraryERM.CreateGLAccountNo(), GenJnlAccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));

        GenJournalLine.Validate("Tax Area Code", TaxAreaCode);
        GenJournalLine.Validate("Tax Group Code", TaxGroupCode);
        GenJournalLine.Validate("Tax Liable", true);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GenJournalLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType::Sale);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PostedDocNo := GenJournalLine."Document No.";
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup") PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateAndPostGenJnlLinePurchaseInvoiceForSalesTax(VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]) PostedDocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenBusinessPostingGroup.Modify(true);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJnlDocumentType::Invoice, GenJnlAccountType::"G/L Account",
          LibraryERM.CreateGLAccountNo(), GenJnlAccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), -LibraryRandom.RandDecInRange(100, 200, 2));

        GenJournalLine.Validate("Tax Area Code", TaxAreaCode);
        GenJournalLine.Validate("Tax Group Code", TaxGroupCode);
        GenJournalLine.Validate("Tax Liable", true);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GenJournalLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType::Purchase);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PostedDocNo := GenJournalLine."Document No.";
    end;

    local procedure CreateThreeVATPostingSetup(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[1], VATCalculationType, LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[2], VATCalculationType, 0);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[3], VATCalculationType, LibraryRandom.RandDecInRange(10, 20, 2));
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            VATPostingSetup[i].Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            VATPostingSetup[i].Modify(true);
        end;
    end;

    local procedure CreateAndSetupThreeSalesTaxVATPostingSetup(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; var TaxAreaCode: array[3] of Code[20]; var TaxGroupCode: array[3] of Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup[i], VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
            VATPostingSetup[i].Validate("VAT Calculation Type", VATPostingSetup[i]."VAT Calculation Type"::"Sales Tax");
            VATPostingSetup[i].Modify(true);

            LibraryERM.CreateTaxGroup(TaxGroup);
            CreateTaxJurisdiction(TaxJurisdiction);
            LibraryERM.CreateTaxArea(TaxArea);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
            LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, 0, WorkDate());  // 0 - TaxDetail."Tax Type"::"Sales Tax" ("Sales and Use Tax" in NA)
            TaxDetail.Validate("Maximum Amount/Qty.", 9999999);
            TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandDecInRange(10, 20, 2));
            TaxDetail.Modify(true);

            TaxAreaCode[i] := TaxArea.Code;
            TaxGroupCode[i] := TaxGroup.Code;
        end;
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure CalcAndVATSettlement(AccountNo: Code[20]; DocumentNo: Code[20])
    var
        CalcandPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        CalcandPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, AccountNo, false, true);
        CalcandPostVATSettlement.SetInitialized(false);
        CalcandPostVATSettlement.SaveAsExcel(DocumentNo);
    end;

    local procedure RunCalcAndPostVATSettlementReport(DocumentNo: Code[20]; VATPostingSetup: array[3] of Record "VAT Posting Setup"; PostSettlement: Boolean)
    var
        FilterVATPostingSetup: Record "VAT Posting Setup";
        CalcandPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        CalcandPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, LibraryERM.CreateGLAccountNo(), true, PostSettlement);
        FilterVATPostingSetup.SetFilter("VAT Bus. Posting Group", '%1|%2|%3', VATPostingSetup[1]."VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group");
        CalcandPostVATSettlement.SetTableView(FilterVATPostingSetup);
        Commit();
        CalcandPostVATSettlement.Run();
    end;

    local procedure RunCalcAndPostVATSettlementReportWithoutRequestPage(DocumentNo: Code[20]; VATPostingSetup: array[3] of Record "VAT Posting Setup"; PostSettlement: Boolean)
    var
        FilterVATPostingSetup: Record "VAT Posting Setup";
        CalcandPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        CalcandPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, LibraryERM.CreateGLAccountNo(), true, PostSettlement);
        FilterVATPostingSetup.SetFilter("VAT Bus. Posting Group", '%1|%2|%3', VATPostingSetup[1]."VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group");
        CalcandPostVATSettlement.SetTableView(FilterVATPostingSetup);
        CalcandPostVATSettlement.UseRequestPage(false);
        CalcandPostVATSettlement.Run();
    end;

    local procedure FilterVATEntryByDocumentNoPostingGroups(var VATEntry: Record "VAT Entry"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type")
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, GenPostingType);
    end;

    local procedure FindVATAmount(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Amount: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATAmount := Round((Amount * VATPostingSetup."VAT %") / (VATPostingSetup."VAT %" + 100));
        exit(Amount - VATAmount);
    end;

    local procedure FindVATEntries(var VATEntry: array[3] of Record "VAT Entry"; VATPostingSetup: array[3] of Record "VAT Posting Setup"; DocumentNo: array[3] of Code[20]; GenPostingType: Enum "General Posting Type")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATEntry) do begin
            FilterVATEntryByDocumentNoPostingGroups(VATEntry[i], VATPostingSetup[i]."VAT Bus. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group", DocumentNo[i], GenPostingType);
            VATEntry[i].FindFirst();
        end;
    end;

    local procedure GetSettlementVATEntriesNo(var SettlementVATEntryNo: array[3] of Integer; VATPostingSetup: array[3] of Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        for i := 1 to ArrayLen(SettlementVATEntryNo) do begin
            FilterVATEntryByDocumentNoPostingGroups(VATEntry, VATPostingSetup[i]."VAT Bus. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group", DocumentNo, GenPostingType::Settlement);
            VATEntry.FindFirst();
            SettlementVATEntryNo[i] := VATEntry."Entry No.";
        end;
    end;

    local procedure GetGLEntryTransactionNo(GLAccountNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure DateCompressVATEntry(PostingDate: Date)
    var
        DateComprRegister: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVATEntries: Report "Date Compress VAT Entries";
    begin
        // Run the Date Compress VAT Entry Report with a closed Accounting Period.
        DateComprRetainFields."Retain Document No." := true;
        DateComprRetainFields."Retain Bill-to/Pay-to No." := false;
        DateComprRetainFields."Retain EU 3-Party Trade" := false;
        DateComprRetainFields."Retain Country/Region Code" := false;
        DateComprRetainFields."Retain Internal Ref. No." := false;
        DateCompressVATEntries.InitializeRequest(
          PostingDate, PostingDate, DateComprRegister."Period Length"::Day, DateComprRetainFields, false);
        DateCompressVATEntries.UseRequestPage(false);
        DateCompressVATEntries.Run();
    end;

    local procedure ReverseGLAccount(GLAccountNo: Code[20]; DocumentNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
        VATEntry: Record "VAT Entry";
        TransactionNo: Integer;
    begin
        TransactionNo := GetGLEntryTransactionNo(GLAccountNo, DocumentNo);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);
        Assert.ExpectedError(StrSubstNo(ReversalError, VATEntry.TableCaption(), VATEntry."Entry No."));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Assert: Codeunit Assert;
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Base, VATEntry.Base, GeneralLedgerSetup."Appln. Rounding Precision",
          StrSubstNo(VATBaseError, Base, VATEntry.Base, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryClosedByEntryNo(VATEntry: array[3] of Record "VAT Entry"; SettlementVATEntryNo: array[3] of Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATEntry) do begin
            VATEntry[i].TestField(Closed, true);
            VATEntry[i].TestField("Closed by Entry No.", SettlementVATEntryNo[i]);
        end;
    end;

    local procedure VerifyVATEntryNoInVATSettlementReportResults(VATEntry: array[3] of Record "VAT Entry"; SettlementVATEntryNo: array[3] of Integer)
    var
        Node: DotNet XmlNode;
        i: Integer;
    begin
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');

        for i := 1 to ArrayLen(VATEntry) do begin
            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result/VATBusPstGr_VATPostSetup', Node, (i * 2) - 2);
            Node := Node.ParentNode;
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPstGr_VATPostSetup', VATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATPrdPstGr_VATPostSetup', VATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'EntryNo_VATEntry', Format(VATEntry[i]."Entry No."));

            LibraryXPathXMLReader.GetNodeByElementNameByIndex('/DataSet/Result/VATBusPstGr_VATPostSetup', Node, (i * 2) - 1);
            Node := Node.ParentNode;
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATBusPstGr_VATPostSetup', VATEntry[i]."VAT Bus. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'VATPrdPstGr_VATPostSetup', VATEntry[i]."VAT Prod. Posting Group");
            LibraryXPathXMLReader.VerifyNodeValueFromParentNode(Node, 'NextVATEntryNo', Format(SettlementVATEntryNo[i]));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    procedure SetMakeInconsistent()
    begin
        MakeInconsistent := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calc. and Post VAT Settlement", 'OnBeforePostGenJnlLineReverseChargeVAT', '', false, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATAmountAddCurr: Decimal)
    begin
        if MakeInconsistent then
            if GenJnlLine.Amount > 0 then
                GenJnlLine.Amount := Round(GenJnlLine.Amount * 1.1);
    end;
}

