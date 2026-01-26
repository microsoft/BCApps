codeunit 144174 "UT Quarter VAT"
{
    // // [FEATURE] [VAT Settlement]
    // 1.   Purpose of the test is to verify error on VAT Settlement Period on General Ledger Setup table.
    // 2-3. Purpose of the test is to verify VAT Settlement Period to Month and Quarter on General Ledger Setup after running Calc. and Post VAT Settlement report.
    // 4.   Purpose of the test is to verify error on VAT Settlement Period on General Ledger Setup after running Calc. and Post VAT Settlement.
    // 
    // Covers Test Cases for WI - 346153
    // ---------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------
    // OnValidateVATSettlementPeriodQuarterGLSetupErr,OnValidateVATSettlementPeriodTypeMonthGLSetup                 202273,202274,202271
    // OnValidateVATSettlementPeriodTypeQuarterGLSetup,OnValidateVATSettlementPeriodWithOutClosedEntriesErr         202275,202272,202277

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';
        LibraryERM: Codeunit "Library - ERM";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryRandom: Codeunit "Library - Random";
        CreditNextPeriodLbl: Label 'CreditNextPeriod';
        DebitNextPeriodLbl: Label 'DebitNextPeriod';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATSettlementPeriodQuarterGLSetupErr()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify error on VAT Settlement Period on Table - 98 General Ledger Setup.
        // Setup.
        Initialize();

        // Exercise.
        asserterror UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Quarter);

        // Verify: Verify Error Code. Actual error is "To change value of VAT Settlement Period all VAT Entries must be closed".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATSettlementPeriodTypeMonthGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify VAT Settlement Period to Month on General Ledger Setup after running Calc. and Post VAT Settlement Report ID - 20.
        OnValidateVATSettlementPeriod(GeneralLedgerSetup."VAT Settlement Period"::Month);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATSettlementPeriodTypeQuarterGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify VAT Settlement Period to Quarter on General Ledger Setup after running Calc. and Post VAT Settlement Report ID - 20.
        OnValidateVATSettlementPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);
    end;

    local procedure OnValidateVATSettlementPeriod(VATSettlementPeriod: Option)
    var
        EntryNo: Integer;
    begin
        // Setup: Run Calc. and Post VAT Settlement report, modify VAT Entries and Periodic Settlement VAT Entry.
        Initialize();
        EntryNo := CreateVATEntry();
        UpdateVATEntries(false, true);  // Using False and True for Closed VAT Entry.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
        UpdatePeriodicSettlementVATEntry(false, true);  // Using False and True for Closed Periodic Settlement VAT Entry.

        // Exercise.
        UpdateVATSettlementPeriodGeneralLedgerSetup(VATSettlementPeriod);

        // Verify: Verify VAT Settlement Period field on General Ledger Setup page.
        VerifyVATSettlementPeriod(VATSettlementPeriod);
        VerifyVATEntries(EntryNo);

        // TearDown: Open closed VAT Entries and Periodic Settlement VAT Entry to False.
        UpdateVATEntries(true, false);  // Using True and False for Open VAT Entry.
        UpdatePeriodicSettlementVATEntry(true, false);  // Using True and False for Open Periodic Settlement VAT Entry.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateVATSettlementPeriodWithOutClosedEntriesErr()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify error on VAT Settlement Period on General Ledger Setup after running Calc. and Post VAT Settlement Report ID - 20.
        // Setup: Run Calc. and Post VAT Settlement report.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");

        // Exercise.
        asserterror UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Quarter);

        // Verify: Verify Error Code. Actual error is "To change value of VAT Settlement Period all VAT Entries must be closed".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertPeriodicVATSettlementEntry()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        PeriodicSettlementVATEntryNext: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
        PeriodicSettlementVATEntryNext: Record "Periodic VAT Settlement Entry";
#endif
        PeriodStartDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372230] Prior Period Input/Output VAT moved to the next period when new Periodic Settlement VAT Entry is inserted
        Initialize();

        // [GIVEN] Set PeriodStartDate after existing last Periodic VAT Settlement Entry for "VAT Settlement Period" = Month
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        GeneralLedgerSetup.Get();
        PeriodStartDate := CalcDate('<1M + CM>', GeneralLedgerSetup."Last Settlement Date") + 1;

        // [GIVEN] Periodic Settlement VAT Entry with "Prior Period Input VAT" = "X", "Prior Period Output VAT" = "Y"
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        UpdatePriorPeriodIOVAT(
          PeriodicSettlementVATEntry, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Create new Periodic Settlement VAT Entry
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(
          PeriodicSettlementVATEntryNext, CalcDate('<+1M + CM>', PeriodStartDate));
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(
          PeriodicSettlementVATEntryNext, CalcDate('<+1M + CM>', PeriodStartDate));
#endif
        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = "X", "Prior Period Output VAT" = "Y"
        PeriodicSettlementVATEntryNext.TestField("Prior Period Input VAT", PeriodicSettlementVATEntry."Prior Period Input VAT");
        PeriodicSettlementVATEntryNext.TestField("Prior Period Output VAT", PeriodicSettlementVATEntry."Prior Period Output VAT");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementAfterEmptyVATPeriodInputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        PeriodStartDate: Date;
    begin
        // [SCENARIO 372230] Prior Period Input VAT moved to the next period after "Calc. and Post VAT Settlement" is running
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] Set up General Ledger Setup with "VAT Settlement Period" = Month and new Last Settlement Date
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] New empty Periodic Settlement VAT Entry with "Prior Period Input VAT" = "X", "Prior Period Output VAT" = 0
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        PeriodicSettlementVATEntry.FindLast();
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, LibraryRandom.RandDecInRange(100, 200, 2), 0);

        // [WHEN] Run "Calc. and Post VAT Settlement" report
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");

        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = "X", "Prior Period Output VAT" = 0
        // [THEN] Report shows Next Period Input VAT = "X", Next Period Output VAT = 0
        VerifyNextPeriodValues(PeriodicSettlementVATEntry."Prior Period Input VAT", 0);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementAfterEmptyVATPeriodOutputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        PeriodStartDate: Date;
    begin
        // [SCENARIO 372230] Prior Period Output VAT moved to the next period after "Calc. and Post VAT Settlement" is running
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] Set up General Ledger Setup with "VAT Settlement Period" = Month and new Last Settlement Date
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] New empty Periodic Settlement VAT Entry with "Prior Period Input VAT" = 0, "Prior Period Output VAT" = "Y"
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        PeriodicSettlementVATEntry.FindLast();
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, 0, LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Run "Calc. and Post VAT Settlement" report
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");

        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = 0, "Prior Period Output VAT" = "Y"
        // [THEN] Report shows Next Period Input VAT = 0, Next Period Output VAT = "Y"
        VerifyNextPeriodValues(0, PeriodicSettlementVATEntry."Prior Period Output VAT");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementAfterEmptyVATPeriodOutputVATLessThanInputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        VATPostingSetup: Record "VAT Posting Setup";
        PeriodStartDate: Date;
        InputVATAmount: Decimal;
        SalesVATAmount: Decimal;
    begin
        // [SCENARIO 374916] Run "Calc. and Post VAT Settlement" when Output VAT Amount for the period is less than Prior Period Input VAT
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] Set up General Ledger Setup with "VAT Settlement Period" = Month and new Last Settlement Date
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] New empty Periodic Settlement VAT Entry with "Prior Period Input VAT" = "X"
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        InputVATAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, InputVATAmount, 0);

        // [GIVEN] VAT Entry with Type = "Sale" (Output VAT) and Amount = "A" < "X"
        SalesVATAmount := InputVATAmount - LibraryRandom.RandDecInRange(100, 200, 2);
        MockVATEntrySales(PeriodStartDate, SalesVATAmount, VATPostingSetup);

        // [WHEN] Run "Calc. and Post VAT Settlement" report
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");

        // [THEN] Periodic Settlement VAT Entry has "VAT Settlement" = "X" - "A"
        PeriodicSettlementVATEntry.Find();
        PeriodicSettlementVATEntry.TestField("VAT Settlement", InputVATAmount - SalesVATAmount);

        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = "X" - "A", "Prior Period Output VAT" = 0
        // [THEN] Report shows Next Period Input VAT = "X" - "A", Next Period Output VAT = 0
        VerifyNextPeriodValues(InputVATAmount - SalesVATAmount, 0);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementAfterEmptyVATPeriodOutputVATGreaterOrEqualThanInputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        VATPostingSetup: Record "VAT Posting Setup";
        PeriodStartDate: Date;
        InputVATAmount: Decimal;
        SalesVATAmount: Decimal;
    begin
        // [SCENARIO 374916] Run "Calc. and Post VAT Settlement" when Output VAT Amount for the period is greater than Prior Period Input VAT
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] Set up General Ledger Setup with "VAT Settlement Period" = Month and new Last Settlement Date
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] New empty Periodic Settlement VAT Entry with "Prior Period Input VAT" = "X"
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        InputVATAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, InputVATAmount, 0);

        // [GIVEN] VAT Entry with Type = "Sale" (Output VAT) and Amount = "B" >= "X"
        SalesVATAmount := InputVATAmount + LibraryRandom.RandDecInRange(100, 200, 2);
        MockVATEntrySales(PeriodStartDate, SalesVATAmount, VATPostingSetup);

        // [WHEN] Run "Calc. and Post VAT Settlement" report
        LibraryVariableStorage.Enqueue(true);
        VATPostingSetup.SetRecFilter();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        // [THEN] Periodic Settlement VAT Entry has "VAT Settlement" = "X" - "B"
        PeriodicSettlementVATEntry.Find();
        PeriodicSettlementVATEntry.TestField("VAT Settlement", InputVATAmount - SalesVATAmount);

        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = 0, "Prior Period Output VAT" = 0
        // [THEN] Report shows Next Period Input VAT = 0, Next Period Output VAT = 0
        VerifyNextPeriodValues(0, 0);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementWithNextYearPeriodSales()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        VATPostingSetup: Record "VAT Posting Setup";
        DateFormula: DateFormula;
        DateFormulaText: Text;
        PeriodStartDate: Date;
        VATEntryDate: Date;
        InputVATAmount: Decimal;
        SalesVATAmount: Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 213601] Run "Calc. and Post VAT Settlement" at December 2019, January 2020, February 2020
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries until 10/2019
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] GLSetup."VAT Settlement Period" = Month and "Last Settlement Date" = 30/11/2019
        // [GIVEN] "Periodic Settlement VAT Entry" with "VAT Period" = "2019/11" and "Prior Period Input VAT" = 1000
        GeneralLedgerSetup.Get();
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := SetLastSettlementDateOnGLSetup(CalcDate('<CY+1Y-2M>', GeneralLedgerSetup."Last Settlement Date"));

#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        InputVATAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        SalesVATAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, InputVATAmount, 0);

        // [GIVEN] VAT Entry with "sales" amount = 50 and 01/12/2019
        // [GIVEN] VAT Entry with "sales" amount = 150 and 01/01/2019
        // [GIVEN] VAT Entry with "sales" amount = 250 and 01/02/2020

        // [WHEN] Run "Calc. and Post VAT Settlement" report December 2019, January 2020, February 2020
        for Index := 1 to 3 do begin
            DateFormulaText := StrSubstNo('<%1M>', Index - 1);
            Evaluate(DateFormula, DateFormulaText);
            VATEntryDate := CalcDate(DateFormula, PeriodStartDate);
            MockVATEntrySales(VATEntryDate, SalesVATAmount, VATPostingSetup);

            LibraryVariableStorage.Enqueue(true);
            VATPostingSetup.SetRecFilter();
            REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);
        end;

        // [THEN] "Periodic Settlement VAT Entry" with "VAT Period" = "2019/11" has "Prior Period Input VAT" = 1000, "VAT Settlement" = 1000 - 50 = 950 and "Prior Year Input VAT" = 0
        PeriodicSettlementVATEntry.Find();
        PeriodicSettlementVATEntry.TestField("VAT Period", StrSubstNo('%1/11', Date2DMY(PeriodStartDate, 3)));
        PeriodicSettlementVATEntry.TestField("VAT Settlement", InputVATAmount - SalesVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Period Input VAT", InputVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Year Input VAT", 0);

        // [THEN] "Periodic Settlement VAT Entry" with "VAT Period" = "2019/12" has "Prior Period Input VAT" = 950, "VAT Settlement" = 950 - 150 = 800 and "Prior Year Input VAT" = 0
        PeriodicSettlementVATEntry.Next();
        PeriodicSettlementVATEntry.TestField("VAT Period", StrSubstNo('%1/12', Date2DMY(PeriodStartDate, 3)));
        PeriodicSettlementVATEntry.TestField("VAT Settlement", InputVATAmount - 2 * SalesVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Period Input VAT", InputVATAmount - SalesVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Year Input VAT", 0);

        // [THEN] "Periodic Settlement VAT Entry" with "VAT Period" = "2020/01" has "Prior Period Input VAT" = 0, "VAT Settlement" = 800 - 250 = 550 and "Prior Year Input VAT" = 800
        PeriodicSettlementVATEntry.Next();
        PeriodicSettlementVATEntry.TestField("VAT Period", StrSubstNo('%1/01', Date2DMY(PeriodStartDate, 3) + 1));
        PeriodicSettlementVATEntry.TestField("VAT Settlement", InputVATAmount - 3 * SalesVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Period Input VAT", 0);
        PeriodicSettlementVATEntry.TestField("Prior Year Input VAT", InputVATAmount - 2 * SalesVATAmount);

        // [THEN] "Periodic Settlement VAT Entry" with "VAT Period" = "2020/02" has "Prior Period Input VAT" = 550, "VAT Settlement" = 0 and "Prior Year Input VAT" = 0
        PeriodicSettlementVATEntry.Next();
        PeriodicSettlementVATEntry.TestField("VAT Period", StrSubstNo('%1/02', Date2DMY(PeriodStartDate, 3) + 1));
        PeriodicSettlementVATEntry.TestField("VAT Settlement", 0);
        PeriodicSettlementVATEntry.TestField("Prior Period Input VAT", InputVATAmount - 3 * SalesVATAmount);
        PeriodicSettlementVATEntry.TestField("Prior Year Input VAT", 0);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementAfterEmptyVATPeriodInputVATTestReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        PeriodStartDate: Date;
    begin
        // [SCENARIO 279074] Prior Period Input VAT moved to the next period after "Calc. and Post VAT Settlement" is running with Posting disabled
        Initialize();

        // [GIVEN] Closed all VAT Entries and Periodic Settlement VAT Entries
        UpdateVATEntries(false, true);
        UpdatePeriodicSettlementVATEntry(false, true);

        // [GIVEN] Set up General Ledger Setup with "VAT Settlement Period" = Month and new Last Settlement Date
        UpdateVATSettlementPeriodGeneralLedgerSetup(GeneralLedgerSetup."VAT Settlement Period"::Month);
        PeriodStartDate := UpdateLastSettlementDateOnGLSetup();

        // [GIVEN] New empty Periodic Settlement VAT Entry with "Prior Period Input VAT" = "X", "Prior Period Output VAT" = 0
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodStartDate);
#endif
        PeriodicSettlementVATEntry.FindLast();
        UpdatePriorPeriodIOVAT(PeriodicSettlementVATEntry, LibraryRandom.RandDecInRange(100, 200, 2), 0);

        // [WHEN] Run "Calc. and Post VAT Settlement" report
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");

        // [THEN] Next Periodic Settlement VAT Entry gets "Prior Period Input VAT" = "X", "Prior Period Output VAT" = 0
        // [THEN] Report shows Next Period Input VAT = "X", Next Period Output VAT = 0
        VerifyNextPeriodValuesFileOnly(PeriodicSettlementVATEntry."Prior Period Input VAT", 0);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateVATEntry(): Integer
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry.Closed := false;
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure UpdateVATEntries(Closed: Boolean; Closed2: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetRange(Closed, Closed);
        VATEntry.ModifyAll(Closed, Closed2);
    end;

    local procedure UpdatePeriodicSettlementVATEntry(Closed: Boolean; Closed2: Boolean)
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntry.Reset();
        PeriodicSettlementVATEntry.SetRange("VAT Period Closed", Closed);
        PeriodicSettlementVATEntry.ModifyAll("VAT Period Closed", Closed2);
    end;

    local procedure UpdateVATSettlementPeriodGeneralLedgerSetup(VATSettlementPeriod: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Settlement Period", VATSettlementPeriod);
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateLastSettlementDateOnGLSetup(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(SetLastSettlementDateOnGLSetup(CalcDate('<1M + CM>', GeneralLedgerSetup."Last Settlement Date")));
    end;

    local procedure SetLastSettlementDateOnGLSetup(NewDate: Date): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := NewDate;
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."Last Settlement Date" + 1);
    end;

#if not CLEAN27
    local procedure UpdatePriorPeriodIOVAT(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; InputVAT: Decimal; OutputVAT: Decimal)
    begin
        PeriodicSettlementVATEntry."Prior Period Input VAT" := InputVAT;
        PeriodicSettlementVATEntry."Prior Period Output VAT" := OutputVAT;
        PeriodicSettlementVATEntry.Modify();
    end;
#else
    local procedure UpdatePriorPeriodIOVAT(var PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry"; InputVAT: Decimal; OutputVAT: Decimal)
    begin
        PeriodicSettlementVATEntry."Prior Period Input VAT" := InputVAT;
        PeriodicSettlementVATEntry."Prior Period Output VAT" := OutputVAT;
        PeriodicSettlementVATEntry.Modify();
    end;
#endif

    local procedure MockVATEntry(PostingDate: Date; Amount: Decimal; VATEntryType: Enum "General Posting Type"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
        VATEntryLast: Record "VAT Entry";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));

        VATEntryLast.FindLast();
        VATEntry.Init();
        VATEntry."Entry No." := VATEntryLast."Entry No." + 1;
        VATEntry.Type := VATEntryType;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry.Amount := -Amount;
        VATEntry."Operation Occurred Date" := PostingDate;
        VATEntry.Insert();
    end;

    local procedure MockVATEntrySales(PostingDate: Date; Amount: Decimal; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
    begin
        MockVATEntry(PostingDate, Amount, VATEntry.Type::Sale, VATPostingSetup);
    end;

    local procedure VerifyVATSettlementPeriod(VATSettlementPeriod: Option)
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        GeneralLedgerSetup.OpenEdit();
        GeneralLedgerSetup."VAT Settlement Period".AssertEquals(VATSettlementPeriod);
        GeneralLedgerSetup.Close();
    end;

    local procedure VerifyVATEntries(EntryNo: Integer)
    var
        VATEntries: TestPage "VAT Entries";
    begin
        VATEntries.OpenEdit();
        VATEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        VATEntries.Closed.AssertEquals(Format(true));
        VATEntries.Close();
    end;

    local procedure VerifyNextPeriodValues(ExpectedNextInputVAT: Decimal; ExpectedNextOuputVAT: Decimal)
    var
#if not CLEAN27
        PeriodicSettlementVATEntryNext: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntryNext: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntryNext.FindLast();
        PeriodicSettlementVATEntryNext.TestField("Prior Period Input VAT", ExpectedNextInputVAT);
        PeriodicSettlementVATEntryNext.TestField("Prior Period Output VAT", ExpectedNextOuputVAT);

        VerifyNextPeriodValuesFileOnly(ExpectedNextInputVAT, ExpectedNextOuputVAT);
    end;

    local procedure VerifyNextPeriodValuesFileOnly(ExpectedNextInputVAT: Decimal; ExpectedNextOuputVAT: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CreditNextPeriodLbl, ExpectedNextInputVAT);
        LibraryReportDataset.AssertElementWithValueExists(DebitNextPeriodLbl, ExpectedNextOuputVAT);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CalcAndPostVATSettlement.StartingDate.SetValue(CalcDate('<1D>', GeneralLedgerSetup."Last Settlement Date"));  // Calculate first day of next month.
        CalcAndPostVATSettlement.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        CalcAndPostVATSettlement.SettlementAcc.SetValue(CreateGLAccount());
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(CreateGLAccount());
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(CreateGLAccount());
        CalcAndPostVATSettlement.Post.SetValue(LibraryVariableStorage.DequeueBoolean());
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

