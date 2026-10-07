codeunit 134149 "ERM Derogatory Depr. Posting"
{
    // // [FEATURE] [Fixed Asset] [Derogatory]
    // 1. Test to validate FA Posting Date is not changed after posting Depreciation Journal Lines.
    // 
    // TFS_TS_ID = 342985,342819,345289,56881,66800
    // Covers Test cases:
    // ------------------------------------------------------------------------
    // Test Function Name
    // ------------------------------------------------------------------------
    // DerogatoryWithModifiedFAPostingDate                               324878
    // BookValueAmtInNormalBookWithDerogatory                            342819
    // BookValueAmtInTaxBookWithDerogatory                               342819
    // CalculateDepreciationWithoutGLIntegration                         345289
    // PostPurchInvoiceWithFALine                                        56881
    // FinalDepreciationWithNegativeDerogatory                           59954
    // CheckDerogAmountReportProjectedValue                              66800
    // CheckBookValueForDepreciationWithDerogatory                       71790

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        ComposedFrenchFeatureStateCleanup: Codeunit "ERM Derog. Feature Cleanup";
        WrongJournalUsedErr: Label 'FA Journal without G/L Integration should be used for depreciation calculation.';
        NoPurchInvoiceExistErr: Label 'Purchase invoice was not posted.';
        DepreciationErr: Label 'Depreciation is not equal to Acquisition';
        DerogatoryAmountErr: Label 'The derogatory amount is not correct';
        DepreciationAmountErr: Label 'The depreciation amount is not correct';
        BookValueAmountErr: Label 'The book-value amount is not correct';
        NoGLEntryErr: Label 'Number of G/L entries did not match the expected';
        NumberFAEntryErr: Label 'Number of FA entries did not match the expected';
        NumberMaintenanceEntryErr: Label 'Number of maintenance entries did not match the expected';
        DerogatoryAcqErr: Label 'The derogatory book did not receive the acquisition cost from the purchase invoice.';
        FinalValidationEventMarkerLbl: Label 'DEROGATORY-LINK-ORDER', Locked = true;
        FAJnlPostLineEventMarkerLbl: Label 'FA-JNL-EVENT-ORDER', Locked = true;
        GenJnlPostLineEventMarkerLbl: Label 'GEN-JNL-EVENT-ORDER', Locked = true;
        GenJnlPostLineMutatedDescriptionLbl: Label 'GEN-JNL-EVENT-MUTATED', Locked = true;
        PostDeprUntilDateEventMarkerLbl: Label 'DEPR-UNTIL-EVENT-ORDER', Locked = true;
        MaintenanceValidationEventMarkerLbl: Label 'MAINT-LINK-ORDER', Locked = true;
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        MissingDerogatoryCounterpartTok: Label 'The derogatory counterpart for source entry';
        MultipleDerogatoryCounterpartsTok: Label 'More than one derogatory counterpart references source entry';
        InvalidDerogatoryLinkTok: Label 'cannot be linked to depreciation book';
        SimulatedFeatureBodyFailureErr: Label 'Simulated composed-French test-body failure.';
        EventInvocationCountErr: Label 'The event invocation count did not match the expected value.';
        EventBookOrderErr: Label 'The depreciation-book event order did not match the expected value.';
        EventTypeOrderErr: Label 'The depreciation event type did not match the expected value.';
        EventDescriptionErr: Label 'The event mutation was not preserved by the posting workflow.';
        FAJnlPostLineEventCount: Integer;
        FirstFAJnlPostLineBookCode: Code[10];
        SecondFAJnlPostLineBookCode: Code[10];
        GenJnlPostLineEventCount: Integer;
        PostDeprUntilDateEventCount: Integer;
        FirstPostDeprUntilDateBookCode: Code[10];
        SecondPostDeprUntilDateBookCode: Code[10];
        FirstPostDeprUntilDateType: Integer;
        SecondPostDeprUntilDateType: Integer;
        PostMaintenanceEventCount: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DerogatoryWithModifiedFAPostingDate()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Derogatory With Modified FAPosting Date
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        VerifyFAPostingDate(FANo);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuccessfulComposedFrenchTestBodyRestoresFeatureState()
    var
        PreviousFeatureState: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Explicit cleanup restores feature state after a successful committed operation
        Initialize(false);

        // [GIVEN] Feature "F" has a captured initial state and a committed status change
        PreviousFeatureState := GetFeatureState();
        ComposedFrenchFeatureStateCleanup.CaptureFeatureState('AcceleratedDepreciation', CompanyName());
        ChangeFeatureState();
        Commit();

        // [WHEN] Cleanup follows the successful committed operation
        ComposedFrenchFeatureStateCleanup.RestoreFeatureState();

        // [THEN] The previously absent row or existing status is restored
        Assert.AreEqual(PreviousFeatureState, GetFeatureState(), 'Cleanup must restore the captured feature state.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedComposedFrenchTestBodyRestoresFeatureState()
    var
        PreviousFeatureState: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Explicit cleanup restores feature state after a failed committed operation
        Initialize(false);

        // [GIVEN] Feature "F" has a captured initial state and a committed status change
        PreviousFeatureState := GetFeatureState();
        ComposedFrenchFeatureStateCleanup.CaptureFeatureState('AcceleratedDepreciation', CompanyName());
        ChangeFeatureState();
        Commit();

        // [WHEN] The committed fixture operation fails
        asserterror Error(SimulatedFeatureBodyFailureErr);

        // [THEN] The original error remains observable and explicit cleanup restores the captured state
        Assert.ExpectedError(SimulatedFeatureBodyFailureErr);
        Assert.ExpectedErrorCode('Dialog');
        ComposedFrenchFeatureStateCleanup.RestoreFeatureState();
        Assert.AreEqual(PreviousFeatureState, GetFeatureState(), 'Cleanup must restore the captured feature state.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostPurchInvoiceWithFALine()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Post Purch Invoice With FALine
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        InvoiceNo := CreateAndPostPurchaseInvoice(FANo, NormalDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        VerifyPostedInvoice(InvoiceNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostFAJournalLine()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Post FAJournal Line
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        // Post FA Journal Lines with FA Posting Type: Depreciation and Derogatory and check FA Ledger Entries.
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        // [WHEN] The posting operation is performed
        CreatePostFAJournalLines(FANo, NormalDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        CheckFALedgerEntries(FANo, TaxDeprBookCode);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneralJournalAcquisitionCreatesSingleLinkedCounterpart()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] General Journal Acquisition Creates Single Linked Counterpart
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, true);

        // [WHEN] The posting operation is performed
        CreatePostGenJnlLine(
            GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost",
            FANo, NormalDeprBookCode, LibraryRandom.RandDec(10000, 2));

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenancePostingCreatesSingleLinkedCounterpart()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Maintenance Posting Creates Single Linked Counterpart
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedMaintenanceCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingTaxBookAssetDoesNotCreateCounterpart()
    var
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        AcquisitionCostAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Missing Tax Book Asset Does Not Create Counterpart
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        CreateNormalAndTaxDeprBooks(NormalDepreciationBookCode, TaxDepreciationBookCode);
        CreateFAPostingGroup(FixedAsset);
        CreateFADeprBookWithDates(
            FixedAsset."No.", NormalDepreciationBookCode, FixedAsset."FA Posting Group",
            WorkDate(), CalcDate('<5Y>', WorkDate()));
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        AcquisitionCostAmount := LibraryRandom.RandDec(10000, 2);
        CreateFAJournalLine(
            FAJournalLine, FixedAsset."No.", NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionCostAmount);

        // [WHEN] The posting operation is performed
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The posted entries and their links retain the expected values
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", NormalDepreciationBookCode);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        Assert.AreEqual(1, FALedgerEntry.Count(), NumberFAEntryErr);
        FALedgerEntry.FindFirst();
        Assert.AreEqual(AcquisitionCostAmount, FALedgerEntry.Amount, FALedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(0, FALedgerEntry."Derogatory Source Entry No.", FALedgerEntry.FieldCaption("Derogatory Source Entry No."));
        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        Assert.AreEqual(0, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BookValueAmountsInNormalBookWithDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Book Value Amounts In Normal Book With Derogatory
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        // Check Book Value and Derogatory amounts in Normal Book in case of Derogatory Entry
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        VerifyBookValueAmounts(FANo, NormalDeprBookCode, AcqCostAmount, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BookValueAmountsInTaxBookWithDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Book Value Amounts In Tax Book With Derogatory
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        // Check Book Value and Derogatory amounts in Tax Book in case of Derogatory Entry
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        // [THEN] The posted entries and their links retain the expected values
        VerifyBookValueAmounts(FANo, TaxDeprBookCode, AcqCostAmount - DerogatoryAmt, -DerogatoryAmt);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CalculateDepreciationWithoutGLIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Calculate Depreciation Without GLIntegration
        Initialize();

        // Check derogatory line created in FA Journal after depreciation calculation without G/L integration

        // [GIVEN] FA "FA" has normal and tax depreciation books
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        // [WHEN] create FA Journal Line and post it, calculate depreciation
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<1D>', WorkDate()), false);

        // [THEN] FA Journal Line with FA Posting Type: Deregatory;
        VerifyFAJournalLine(FANo);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinalDepreciationWithNegativeDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Final Depreciation With Negative Derogatory
        Initialize();

        // Checks posting final Depreciation with Negative Deroagatory

        // [GIVEN] FA "FA" has the depreciation books and acquisition needed for the calculation
        FANo := CreateFAWithBooks(NormalDeprBookCode, TaxDeprBookCode, CalcDate('<CY-1Y+1D>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [WHEN] The depreciation is calculated and posted
        // Certain values to get further necessary Derogatory
        CreatePurchaseInvoiceAndPost(FANo, NormalDeprBookCode, 1, 1000, CalcDate('<CY-8M+1D>', WorkDate()));
        // Creates journal lines for 31/8/CurentYear and post
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate('<CY-4M>', WorkDate()), true);
        // Creates journal lines for 31/12/CurentYear and post
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);

        // [THEN] The ledger entries retain the expected acquisition, depreciation and derogatory amounts
        VerifyFinalDepreciationWithNegativeDerogatory(FANo);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CheckBookValueForDepreciationWithDerogatory()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        EndingDate: Date;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Check Book Value For Depreciation With Derogatory
        Initialize();

        // Checks posting for Calculation of Depreciation and Derogatory for Negative Book Value.

        // [GIVEN] FA "FA" has the depreciation books and acquisition needed for the calculation
        EndingDate := CalcDate('<CY>', WorkDate());
        FANo := CreateFAWithBooks(NormalDeprBookCode, TaxDeprBookCode, CalcDate('<-CY>', WorkDate()), EndingDate);
        UpdateFADepreciationBook(FADepreciationBook, FANo, TaxDeprBookCode, EndingDate);
        CreatePurchaseInvoiceAndPost(
          FANo, NormalDeprBookCode,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(1000, 2),
          CalcDate('<-CM>', FADepreciationBook."Depreciation Ending Date"));

        // [WHEN] The depreciation is calculated and posted
        RunCalculateDepReportForDifferentPostingDates(FANo, NormalDeprBookCode, FADepreciationBook."Depreciation Ending Date");

        // [THEN] The ledger entries retain the expected acquisition, depreciation and derogatory amounts
        VerifyFinalDepreciationWithNegativeDerogatory(FANo);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CheckDerogAmountAddAcqCost()
    var
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        ExpectedDerogatoryRatio: Decimal;
        ExpectedDepreciationRatio: Decimal;
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via FA journal w/o G/L integration
        Initialize();

        // [GIVEN] A Fixed asset with a normal and tax depreciation book without G/L integration
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        // [GIVEN] An acquisition cost is posted via FA journal line
        Amount := LibraryRandom.RandDec(10000, 2);
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost", Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount", Depreciation);
        ExpectedDerogatoryRatio := Amount / FADepreciationBook."Derogatory Amount";
        ExpectedDepreciationRatio := Amount / FADepreciationBook.Depreciation;

        // [WHEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes
        Amount2 := LibraryRandom.RandDec(10000, 2);
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost", Amount2);
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The depreciation books are updated with depreciation and derogatory entries according to the ratio
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount", Depreciation);
        Assert.AreNearlyEqual(FADepreciationBook."Derogatory Amount", (Amount + Amount2) / ExpectedDerogatoryRatio, 1, DerogatoryAmountErr);
        Assert.AreNearlyEqual(FADepreciationBook.Depreciation, (Amount + Amount2) / ExpectedDepreciationRatio, 1, DepreciationAmountErr);

        // [THEN] No G/L entries are created
        VerifyNoOfFALedgerEntries(0, NoGLEntryErr, FANo, true, -1);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ErrPostingAddAcqViaFAJnlWithGLInt()
    var
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Error when Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via
        Initialize();

        // FA journal w/ G/L integration for Derogatory only

        // [GIVEN] A Fixed asset with a normal and tax depreciation book with G/L integration for derogatory only
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        DepreciationBook.Get(NormalDeprBookCode);
        DepreciationBook.Validate("Integration G/L - Derogatory", true);
        DepreciationBook.Modify(true);

        // [GIVEN] An acquisition cost is posted via FA journal line
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        GenJournalLine.SetRange("Account No.", FANo);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount", Depreciation);

        // [WHEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] An error is thrown that you can't depreciate acquisition cost with only Derogatory G/L integration
        Assert.ExpectedError(FAJournalLine.FieldCaption("Depr. Acquisition Cost"));
        Assert.ExpectedError('must not be specified');
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CheckDerogAmountAddAcqCostGL()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        ExpectedDerogatoryRatio: Decimal;
        ExpectedDepreciationRatio: Decimal;
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via FA journal w/ G/L integration
        Initialize();

        // [GIVEN] A Fixed asset with a normal and tax depreciation book with G/L integration
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, true);

        // [GIVEN] An acquisition cost is posted via FA G/L journal line
        Amount := LibraryRandom.RandDec(10000, 2);
        CreatePostGenJnlLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost",
          FANo, NormalDeprBookCode, Amount);

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount", Depreciation);
        ExpectedDerogatoryRatio := Amount / FADepreciationBook."Derogatory Amount";
        ExpectedDepreciationRatio := Amount / FADepreciationBook.Depreciation;

        // [WHEN] An additional acquisition cost is posted via FA G/L journal line with "Depr. acquisition Cost" = Yes
        Amount2 := LibraryRandom.RandDec(10000, 2);
        CreateGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, NormalDeprBookCode, Amount2);
        GenJournalLine.Validate("Depr. Acquisition Cost", true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The depreciation books are updated with depreciation and derogatory entries according to the ratio
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount", Depreciation);
        Assert.AreNearlyEqual(FADepreciationBook."Derogatory Amount", (Amount + Amount2) / ExpectedDerogatoryRatio, 1, DerogatoryAmountErr);
        Assert.AreNearlyEqual(FADepreciationBook.Depreciation, (Amount + Amount2) / ExpectedDepreciationRatio, 1, DepreciationAmountErr);

        // [THEN] 6 G/L entries are created
        VerifyNoOfFALedgerEntries(6, NoGLEntryErr, FANo, true, -1);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntryRequestPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CancelDerogEntryAddAcqCost()
    var
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        ExpectedDerogatory: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Cancel Additional acquisition cost's derogatory entry FA journal w/o G/L integration
        Initialize();

        // [GIVEN] A Fixed asset with a normal and tax depreciation book without G/L integration
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        // [GIVEN] An acquisition cost is posted via FA journal line
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount");
        ExpectedDerogatory := FADepreciationBook."Derogatory Amount";

        // [GIVEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Derogatory amount is from both acquisitions
        VerifyNoOfFALedgerEntries(4, NumberFAEntryErr, FANo, false, FALedgerEntry."FA Posting Type"::Derogatory.AsInteger());
        FADepreciationBook.CalcFields("Derogatory Amount");
        Assert.AreNotEqual(FADepreciationBook."Derogatory Amount", ExpectedDerogatory, DerogatoryAmountErr);

        // [WHEN] The additional acquisition cost derogatory entry is cancelled
        CancelLastFALedgerEntry(NormalDeprBookCode, FALedgerEntry."FA Posting Type"::Derogatory.AsInteger());
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The derogatory value is only for the first acquisition depreciation
        FADepreciationBook.CalcFields("Derogatory Amount");
        Assert.AreEqual(ExpectedDerogatory, FADepreciationBook."Derogatory Amount", DerogatoryAmountErr);
    end;

    [Test]
    [HandlerFunctions('ReverseFALedgerEntriesPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDerogEntryAddAcqCost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        ExpectedBookValue: Decimal;
        LastFALedgerEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reverse an additional acquisition for FA with G/L integration
        Initialize();

        // [GIVEN] A Fixed asset with a normal and tax depreciation book with G/L integration
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, true);

        // [GIVEN] An acquisition cost is posted via FA G/L journal line
        CreateGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, NormalDeprBookCode,
          LibraryRandom.RandDecInRange(10000, 1000000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Book Value");
        ExpectedBookValue := FADepreciationBook."Book Value";
        FALedgerEntry.FindLast();
        LastFALedgerEntryNo := FALedgerEntry."Entry No.";

        // [GIVEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes and "Depr. until FA Posting Date" = Yes
        CreateGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, NormalDeprBookCode,
          LibraryRandom.RandDecInRange(100, 10000, 2));
        GenJournalLine.Validate("Depr. until FA Posting Date", true);
        GenJournalLine.Validate("Depr. Acquisition Cost", true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] The additional acquisition cost is reversed from company book
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        FALedgerEntry.FindLast();
        ReverseFALedgerEntries(FALedgerEntry);

        // [THEN] The FA ledger entries created by the additional acquisition are all reversed
        VerifyAllFALedgEntriesReversed(LastFALedgerEntryNo);

        // [THEN] The book-value of Tax book is that as it was before the additional acquisition
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Book Value");
        Assert.AreEqual(ExpectedBookValue, FADepreciationBook."Book Value", BookValueAmountErr);
    end;

    [Test]
    [HandlerFunctions('ReverseFALedgerEntriesPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDerogEntryInitAcqCost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryFALedgerEntry: Record "FA Ledger Entry";
        DepreciationCounterpartFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryCounterpartFALedgerEntry: Record "FA Ledger Entry";
        SourceTransactions: Dictionary of [Integer, Integer];
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        ExpectedBookValue: Decimal;
        LastFALedgerEntryNo: Integer;
        TransactionNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reverse the depreciation+derogatory for the first depreciation of a fixed asset
        Initialize();

        // [GIVEN] A Fixed asset with a normal and tax depreciation book with G/L integration
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, true);

        // [GIVEN] An acquisition cost is posted via FA G/L journal line
        CreateGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, NormalDeprBookCode,
          LibraryRandom.RandDecInRange(10000, 1000000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Book Value");
        ExpectedBookValue := FADepreciationBook."Book Value";
        FALedgerEntry.FindLast();
        LastFALedgerEntryNo := FALedgerEntry."Entry No.";

        // [GIVEN] The FA is depreciated via Calculate Depreciation report
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] The calculated depreciation and derogatory sources and their linked counterparts
        FindFALedgerEntry(
            DepreciationFALedgerEntry, FANo, NormalDeprBookCode,
            DepreciationFALedgerEntry."FA Posting Type"::Depreciation);
        FindLinkedFAEntry(
            DepreciationCounterpartFALedgerEntry, DepreciationFALedgerEntry."Entry No.", TaxDeprBookCode);
        FindFALedgerEntry(
            DerogatoryFALedgerEntry, FANo, NormalDeprBookCode,
            DerogatoryFALedgerEntry."FA Posting Type"::Derogatory);
        FindLinkedFAEntry(
            DerogatoryCounterpartFALedgerEntry, DerogatoryFALedgerEntry."Entry No.", TaxDeprBookCode);
        SourceTransactions.Set(
            DepreciationFALedgerEntry."Transaction No.", DepreciationFALedgerEntry."Entry No.");
        SourceTransactions.Set(
            DerogatoryFALedgerEntry."Transaction No.", DerogatoryFALedgerEntry."Entry No.");

        // [WHEN] Each distinct source transaction is reversed from the company book
        foreach TransactionNo in SourceTransactions.Keys() do begin
            FALedgerEntry.Get(SourceTransactions.Get(TransactionNo));
            ReverseFALedgerEntries(FALedgerEntry);
        end;

        // [THEN] Both linked counterparts are automatically reversed exactly once
        VerifyCalculatedSourceReversal(
            DepreciationFALedgerEntry, DepreciationCounterpartFALedgerEntry, TaxDeprBookCode);
        VerifyCalculatedSourceReversal(
            DerogatoryFALedgerEntry, DerogatoryCounterpartFALedgerEntry, TaxDeprBookCode);

        // [THEN] The FA ledger entries created by the report are all reversed
        VerifyAllFALedgEntriesReversed(LastFALedgerEntryNo);

        // [THEN] The book-value of Tax book is that as it was before the report was executed
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Book Value");
        Assert.AreEqual(ExpectedBookValue, FADepreciationBook."Book Value", BookValueAmountErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AcquisitionViaPurchInvoiceMirrorsToDerogatoryBook()
    var
        FANormalDeprBook: Record "FA Depreciation Book";
        FATaxDeprBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617319] An acquisition cost posted from a purchase invoice mirrors to the derogatory (tax) book
        Initialize();

        // [GIVEN] A fixed asset with a normal and a tax (derogatory) depreciation book
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] An acquisition cost is posted via a purchase invoice on the normal book
        CreateAndPostPurchaseInvoice(FANo, NormalDeprBookCode);

        // [THEN] The tax book received the same acquisition as the normal book (compared via Book Value so the
        // check is independent of the FA posting type the localization uses for the acquisition)
        FANormalDeprBook.Get(FANo, NormalDeprBookCode);
        FANormalDeprBook.CalcFields("Book Value");
        FATaxDeprBook.Get(FANo, TaxDeprBookCode);
        FATaxDeprBook.CalcFields("Book Value");
        Assert.AreNotEqual(0, FATaxDeprBook."Book Value", DerogatoryAcqErr);
        Assert.AreEqual(FANormalDeprBook."Book Value", FATaxDeprBook."Book Value", DerogatoryAcqErr);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AcquisitionSalvageCompanionIsLinked()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617320] An automatic salvage companion is explicitly linked to its source companion
        Initialize();

        // [GIVEN] A fixed asset with a normal and a tax (derogatory) depreciation book
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);

        // [WHEN] The acquisition and its automatic salvage value are posted
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The tax-book salvage entry links to the normal-book salvage entry
        SourceSalvageFALedgerEntry.SetRange("FA No.", FANo);
        SourceSalvageFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        SourceSalvageFALedgerEntry.SetRange("FA Posting Type", SourceSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        Assert.AreEqual(1, SourceSalvageFALedgerEntry.Count(), NumberFAEntryErr);
        SourceSalvageFALedgerEntry.FindFirst();
        Assert.AreEqual(0, SourceSalvageFALedgerEntry."Derogatory Source Entry No.", SourceSalvageFALedgerEntry.FieldCaption("Derogatory Source Entry No."));
        CounterpartSalvageFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartSalvageFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        CounterpartSalvageFALedgerEntry.SetRange("FA Posting Type", CounterpartSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count, NumberFAEntryErr);
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count(), NumberFAEntryErr);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneralJournalSalvageCompanionIsLinked()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617322] A general-journal salvage companion is explicitly linked to its source companion
        Initialize();

        // [GIVEN] An acquisition with salvage for a fixed asset with normal and tax books
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost",
          FANo, NormalDeprBookCode, LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify(true);

        // [WHEN] The general-journal acquisition is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The tax-book salvage entry links to the normal-book salvage entry
        SourceSalvageFALedgerEntry.SetRange("FA No.", FANo);
        SourceSalvageFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        SourceSalvageFALedgerEntry.SetRange("FA Posting Type", SourceSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        Assert.AreEqual(1, SourceSalvageFALedgerEntry.Count(), NumberFAEntryErr);
        SourceSalvageFALedgerEntry.FindFirst();
        CounterpartSalvageFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartSalvageFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        CounterpartSalvageFALedgerEntry.SetRange("FA Posting Type", CounterpartSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count, NumberFAEntryErr);
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count(), NumberFAEntryErr);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AutomaticOnlyDepreciationCompanionsAreLinked()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AutomaticSourceCount: Integer;
        FAPostingDate: Date;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617321] Automatic-only depreciation still produces linked tax-book companions
        Initialize();

        // [GIVEN] An acquired fixed asset with a normal and a tax (derogatory) depreciation book
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::Depreciation, 0);
        FAJournalLine.Validate("FA Posting Date", CalcDate('<1Y>', WorkDate()));
        FAJournalLine.Validate("Depr. until FA Posting Date", true);
        FAJournalLine.Modify(true);
        FAPostingDate := FAJournalLine."FA Posting Date";

        // [WHEN] A zero-amount depreciation line creates only automatic entries
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Every automatic normal-book entry created on that date has one linked tax-book companion
        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        SourceFALedgerEntry.SetRange("FA Posting Date", FAPostingDate);
        SourceFALedgerEntry.SetRange("Automatic Entry", true);
        SourceFALedgerEntry.FindSet();
        repeat
            AutomaticSourceCount += 1;
            CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
            CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
            Assert.AreEqual(1, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
        until SourceFALedgerEntry.Next() = 0;
        Assert.AreNotEqual(0, AutomaticSourceCount, NumberFAEntryErr);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.");
        CounterpartFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartFALedgerEntry.SetRange("FA Posting Date", FAPostingDate);
        CounterpartFALedgerEntry.SetRange("Automatic Entry", true);
        Assert.AreEqual(AutomaticSourceCount, CounterpartFALedgerEntry.Count(), NumberFAEntryErr);
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneratedMirrorDoesNotRunConfiguredDuplication()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        DuplicateFAJournalLine: Record "FA Journal Line";
        FASetup: Record "FA Setup";
        Insurance: Record Insurance;
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        DuplicateTemplateName: Code[10];
        DuplicateBatchName: Code[10];
        ExpectedInsuranceDocumentNo: Code[20];
        ExpectedInsuranceAmount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Generated Mirror Does Not Run Configured Duplication
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        CreateDuplicationTarget(
            DepreciationBook, FANo, DuplicateTemplateName, DuplicateBatchName);
        LibraryFixedAsset.CreateInsurance(Insurance);
        FASetup.Get();
        FASetup.Validate("Insurance Depr. Book", NormalDepreciationBookCode);
        FASetup.Validate("Automatic Insurance Posting", true);
        FASetup.Modify(true);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Duplicate in Depreciation Book", DepreciationBook.Code);
        FAJournalLine.Validate("Insurance No.", Insurance."No.");
        FAJournalLine.Modify(true);
        ExpectedInsuranceDocumentNo := FAJournalLine."Document No.";
        ExpectedInsuranceAmount := FAJournalLine.Amount;

        // [WHEN] The posting operation is performed
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The posted entries and their links retain the expected values
        DuplicateFAJournalLine.SetRange("Journal Template Name", DuplicateTemplateName);
        DuplicateFAJournalLine.SetRange("Journal Batch Name", DuplicateBatchName);
        DuplicateFAJournalLine.SetRange("FA No.", FANo);
        Assert.AreEqual(
            1, DuplicateFAJournalLine.Count(),
            'Only the source posting may run the configured duplication dispatcher.');
        InsCoverageLedgerEntry.SetRange("Insurance No.", Insurance."No.");
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        Assert.AreEqual(
            1, InsCoverageLedgerEntry.Count(),
            'Only the source posting may create an insurance coverage ledger entry.');
        InsCoverageLedgerEntry.FindFirst();
        Assert.AreEqual(ExpectedInsuranceAmount, InsCoverageLedgerEntry.Amount, InsCoverageLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedInsuranceDocumentNo, InsCoverageLedgerEntry."Document No.", InsCoverageLedgerEntry.FieldCaption("Document No."));
        VerifyLinkedCounterparts(FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReturningInsertionOverloadsReturnInsertedIdentities()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        DirectFALedgerEntry: Record "FA Ledger Entry";
        InsertedFALedgerEntry: Record "FA Ledger Entry";
        LocatedFALedgerEntry: Record "FA Ledger Entry";
        TaxBookFALedgerEntry: Record "FA Ledger Entry";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DirectMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        InsertedMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        LocatedMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TaxBookMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        TaxBookFALedgerEntryCount: Integer;
        TaxBookMaintenanceLedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Returning Insertion Overloads Return Inserted Identities
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDepreciationBookCode, TaxDepreciationBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry,
            FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
        DirectFALedgerEntry := SourceFALedgerEntry;
        PrepareDirectFALedgerEntry(DirectFALedgerEntry);
        TaxBookFALedgerEntry.SetRange("FA No.", FANo);
        TaxBookFALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        TaxBookFALedgerEntryCount := TaxBookFALedgerEntry.Count();

        // [WHEN] The posting operation is performed
        FAInsertLedgerEntry.InsertFA(DirectFALedgerEntry, InsertedFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        Assert.AreEqual(
            TaxBookFALedgerEntryCount, TaxBookFALedgerEntry.Count(),
            'Direct FA insertion must not add a tax-book mirror.');
        TaxBookFALedgerEntry.Reset();
        TaxBookFALedgerEntry.SetRange(
            "Derogatory Source Entry No.", InsertedFALedgerEntry."Entry No.");
        Assert.AreEqual(
            0, TaxBookFALedgerEntry.Count(),
            'Direct FA insertion must not create a row linked to the returned entry.');
        LocatedFALedgerEntry.SetRange("FA No.", DirectFALedgerEntry."FA No.");
        LocatedFALedgerEntry.SetRange("Depreciation Book Code", DirectFALedgerEntry."Depreciation Book Code");
        LocatedFALedgerEntry.SetRange("Document No.", DirectFALedgerEntry."Document No.");
        LocatedFALedgerEntry.SetRange("FA Posting Type", DirectFALedgerEntry."FA Posting Type");
        Assert.AreEqual(1, LocatedFALedgerEntry.Count(), NumberFAEntryErr);
        LocatedFALedgerEntry.FindFirst();
        Assert.AreEqual(
            LocatedFALedgerEntry."Entry No.", InsertedFALedgerEntry."Entry No.",
            'The returning FA insertion overload must return the uniquely inserted entry.');
        Assert.AreEqual(DirectFALedgerEntry."FA No.", InsertedFALedgerEntry."FA No.", InsertedFALedgerEntry.FieldCaption("FA No."));
        Assert.AreEqual(DirectFALedgerEntry."Depreciation Book Code", InsertedFALedgerEntry."Depreciation Book Code", InsertedFALedgerEntry.FieldCaption("Depreciation Book Code"));
        Assert.AreEqual(DirectFALedgerEntry."Document No.", InsertedFALedgerEntry."Document No.", InsertedFALedgerEntry.FieldCaption("Document No."));
        Assert.AreEqual(DirectFALedgerEntry."FA Posting Type", InsertedFALedgerEntry."FA Posting Type", InsertedFALedgerEntry.FieldCaption("FA Posting Type"));

        // [GIVEN] Maintenance entry "M" is prepared for direct insertion
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
        DirectMaintenanceLedgerEntry := SourceMaintenanceLedgerEntry;
        PrepareDirectMaintenanceLedgerEntry(DirectMaintenanceLedgerEntry);
        Clear(FAInsertLedgerEntry);
        TaxBookMaintenanceLedgerEntry.SetRange("FA No.", FANo);
        TaxBookMaintenanceLedgerEntry.SetRange(
            "Depreciation Book Code", TaxDepreciationBookCode);
        TaxBookMaintenanceLedgerEntryCount := TaxBookMaintenanceLedgerEntry.Count();

        // [WHEN] The maintenance insertion overload returns the inserted record
        FAInsertLedgerEntry.InsertMaintenance(
            DirectMaintenanceLedgerEntry, InsertedMaintenanceLedgerEntry);

        // [THEN] The returned maintenance identity matches the stored record without an extra mirror

        Assert.AreEqual(
            TaxBookMaintenanceLedgerEntryCount, TaxBookMaintenanceLedgerEntry.Count(),
            'Direct maintenance insertion must not add a tax-book mirror.');
        TaxBookMaintenanceLedgerEntry.Reset();
        TaxBookMaintenanceLedgerEntry.SetRange(
            "Derogatory Source Entry No.", InsertedMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(
            0, TaxBookMaintenanceLedgerEntry.Count(),
            'Direct maintenance insertion must not create a row linked to the returned entry.');
        LocatedMaintenanceLedgerEntry.SetRange("FA No.", DirectMaintenanceLedgerEntry."FA No.");
        LocatedMaintenanceLedgerEntry.SetRange(
            "Depreciation Book Code", DirectMaintenanceLedgerEntry."Depreciation Book Code");
        LocatedMaintenanceLedgerEntry.SetRange("Document No.", DirectMaintenanceLedgerEntry."Document No.");
        LocatedMaintenanceLedgerEntry.SetRange("Maintenance Code", DirectMaintenanceLedgerEntry."Maintenance Code");
        Assert.AreEqual(1, LocatedMaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        LocatedMaintenanceLedgerEntry.FindFirst();
        Assert.AreEqual(
            LocatedMaintenanceLedgerEntry."Entry No.", InsertedMaintenanceLedgerEntry."Entry No.",
            'The returning maintenance insertion overload must return the uniquely inserted entry.');
        Assert.AreEqual(DirectMaintenanceLedgerEntry."FA No.", InsertedMaintenanceLedgerEntry."FA No.", InsertedMaintenanceLedgerEntry.FieldCaption("FA No."));
        Assert.AreEqual(DirectMaintenanceLedgerEntry."Depreciation Book Code", InsertedMaintenanceLedgerEntry."Depreciation Book Code", InsertedMaintenanceLedgerEntry.FieldCaption("Depreciation Book Code"));
        Assert.AreEqual(DirectMaintenanceLedgerEntry."Document No.", InsertedMaintenanceLedgerEntry."Document No.", InsertedMaintenanceLedgerEntry.FieldCaption("Document No."));
        Assert.AreEqual(DirectMaintenanceLedgerEntry."Maintenance Code", InsertedMaintenanceLedgerEntry."Maintenance Code", InsertedMaintenanceLedgerEntry.FieldCaption("Maintenance Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinalLinkValidationRunsAfterPostingEvent()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        EventSubscriber: Codeunit "ERM Derogatory Depr. Posting";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Final Link Validation Runs After Posting Event
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate(Description, FinalValidationEventMarkerLbl);
        FAJournalLine.Modify(true);

        BindSubscription(EventSubscriber);

        // [WHEN] The invalid operation is attempted
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        UnbindSubscription(EventSubscriber);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedError(InvalidDerogatoryLinkTok);
        Assert.ExpectedErrorCode('Dialog');
        FALedgerEntry.SetRange("FA No.", FANo);
        Assert.AreEqual(0, FALedgerEntry.Count(), 'The rejected source and counterpart must be rolled back together.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAReversalUsesPersistedLinkAfterRelationshipChanges()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NewTaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617323] A changed relationship does not redirect reversal of linked FA history
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        NewTaxDeprBookCode := ChangeDerogatoryRelationship(FANo, NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", NewTaxDeprBookCode);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", ReversingFALedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenanceReversalUsesPersistedLinkAfterRelationshipRemoval()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617324] Removed setup does not suppress reversal of linked maintenance history
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ClearDerogatoryRelationship(TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingRequiredFACounterpartErrors()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617325] An eligible FA source cannot be reversed without its linked counterpart
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartFALedgerEntry.Delete();

        // [WHEN] The invalid operation is attempted
        asserterror ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedError(MissingDerogatoryCounterpartTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingRequiredMaintenanceCounterpartErrors()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617326] An eligible maintenance source cannot be reversed without its linked counterpart
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartMaintenanceLedgerEntry.Delete();

        // [WHEN] The invalid operation is attempted
        asserterror ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedError(MissingDerogatoryCounterpartTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AlreadyReversedFACounterpartErrorsAndRollsBackSourceReversal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        CounterpartReversalFALedgerEntry: Record "FA Ledger Entry";
        SourceReversalFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        FALedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617338] FA source reversal is rolled back when its linked counterpart is already reversed
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseFAEntry(CounterpartFALedgerEntry, CounterpartReversalFALedgerEntry);
        FALedgerEntryCount := FALedgerEntry.Count();
        Commit();

        // [WHEN] The invalid operation is attempted
        asserterror ReverseFAEntry(SourceFALedgerEntry, SourceReversalFALedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedTestFieldError(CounterpartFALedgerEntry.FieldCaption("Reversed by Entry No."), Format(0));
        Assert.ExpectedErrorCode('TestField');
        Assert.AreEqual(FALedgerEntryCount, FALedgerEntry.Count(), NumberFAEntryErr);
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SourceFALedgerEntry.Reversed, SourceFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(0, SourceFALedgerEntry."Reversed by Entry No.", SourceFALedgerEntry.FieldCaption("Reversed by Entry No."));
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        Assert.AreEqual(true, CounterpartFALedgerEntry.Reversed, CounterpartFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(CounterpartReversalFALedgerEntry."Entry No.", CounterpartFALedgerEntry."Reversed by Entry No.", CounterpartFALedgerEntry.FieldCaption("Reversed by Entry No."));
        FALedgerEntry.SetRange("Reversed Entry No.", SourceFALedgerEntry."Entry No.");
        Assert.AreEqual(0, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AlreadyReversedMaintenanceCounterpartErrorsAndRollsBackSourceReversal()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartReversalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        SourceReversalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        MaintenanceLedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617339] Maintenance source reversal is rolled back when its linked counterpart is already reversed
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseMaintenanceEntry(
            CounterpartMaintenanceLedgerEntry, CounterpartReversalMaintenanceLedgerEntry);
        MaintenanceLedgerEntryCount := MaintenanceLedgerEntry.Count();
        Commit();

        // [WHEN] The invalid operation is attempted
        asserterror ReverseMaintenanceEntry(
            SourceMaintenanceLedgerEntry, SourceReversalMaintenanceLedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedTestFieldError(
            CounterpartMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."), Format(0));
        Assert.ExpectedErrorCode('TestField');
        Assert.AreEqual(
            MaintenanceLedgerEntryCount, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(false, SourceMaintenanceLedgerEntry.Reversed, SourceMaintenanceLedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(0, SourceMaintenanceLedgerEntry."Reversed by Entry No.", SourceMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."));
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(true, CounterpartMaintenanceLedgerEntry.Reversed, CounterpartMaintenanceLedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(CounterpartReversalMaintenanceLedgerEntry."Entry No.", CounterpartMaintenanceLedgerEntry."Reversed by Entry No.", CounterpartMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."));
        MaintenanceLedgerEntry.SetRange("Reversed Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(0, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MultipleFACounterpartsAcrossBooksError()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617327] FA reversal rejects multiple global persisted links
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        InsertDuplicateFALinkInAnotherBook(CounterpartFALedgerEntry);

        // [WHEN] The invalid operation is attempted
        asserterror ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedError(MultipleDerogatoryCounterpartsTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MultipleMaintenanceCounterpartsAcrossBooksError()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617328] Maintenance reversal rejects multiple global persisted links
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        InsertDuplicateMaintenanceLinkInAnotherBook(CounterpartMaintenanceLedgerEntry);

        // [WHEN] The invalid operation is attempted
        asserterror ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The expected error is reported without changing the existing entries
        Assert.ExpectedError(MultipleDerogatoryCounterpartsTok);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UnlinkedCurrentlyIneligibleFAReversesNormally()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617329] A currently ineligible unlinked FA source receives only its normal reversal
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartFALedgerEntry.Delete();
        ClearDerogatoryRelationship(TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        Assert.AreEqual(true, SourceFALedgerEntry.Reversed, SourceFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(0, ReversingFALedgerEntry."Derogatory Source Entry No.", ReversingFALedgerEntry.FieldCaption("Derogatory Source Entry No."));
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", ReversingFALedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UnlinkedCurrentlyIneligibleMaintenanceReversesNormally()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617330] A currently ineligible unlinked maintenance source receives only its normal reversal
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartMaintenanceLedgerEntry.Delete();
        ClearDerogatoryRelationship(TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(true, SourceMaintenanceLedgerEntry.Reversed, SourceMaintenanceLedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(0, ReversingMaintenanceLedgerEntry."Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry.FieldCaption("Derogatory Source Entry No."));
        CounterpartMaintenanceLedgerEntry.SetRange(
            "Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartMaintenanceLedgerEntry.Count, NumberMaintenanceEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MarkedLegacyFAUsesHeuristicFallback()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617331] Only a marked legacy FA source can use heuristic reversal
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkFAEntriesAsAmbiguousLegacy(SourceFALedgerEntry, CounterpartFALedgerEntry);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MarkedLegacyMaintenanceUsesHeuristicFallback()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617332] Only a marked legacy maintenance source can use heuristic reversal
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkMaintenanceEntriesAsAmbiguousLegacy(SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MarkedLegacyFAUsesHeuristicAfterRelationshipRemoval()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617336] Removed setup does not suppress marked legacy FA fallback
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkFAEntriesAsAmbiguousLegacy(SourceFALedgerEntry, CounterpartFALedgerEntry);
        ClearDerogatoryRelationship(TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MarkedLegacyMaintenanceUsesHeuristicAfterRelationshipChange()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617337] Changed setup does not redirect marked legacy maintenance fallback
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkMaintenanceEntriesAsAmbiguousLegacy(SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry);
        ChangeDerogatoryRelationship(FANo, NormalDeprBookCode, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAReversalOfReversalPreservesMarksAndLinks()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        FirstReversingFALedgerEntry: Record "FA Ledger Entry";
        FirstCounterpartReversal: Record "FA Ledger Entry";
        SecondReversingFALedgerEntry: Record "FA Ledger Entry";
        SecondCounterpartReversal: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617333] Reversal of an FA reversal keeps both reversal chains aligned
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseFAEntry(SourceFALedgerEntry, FirstReversingFALedgerEntry);
        FindLinkedFAEntry(
            FirstCounterpartReversal, FirstReversingFALedgerEntry."Entry No.", TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(FirstReversingFALedgerEntry, SecondReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        FindLinkedFAEntry(
            SecondCounterpartReversal, SecondReversingFALedgerEntry."Entry No.", TaxDeprBookCode);
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        FirstReversingFALedgerEntry.Get(FirstReversingFALedgerEntry."Entry No.");
        FirstCounterpartReversal.Get(FirstCounterpartReversal."Entry No.");
        Assert.AreEqual(false, SourceFALedgerEntry.Reversed, SourceFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(false, CounterpartFALedgerEntry.Reversed, CounterpartFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(SecondReversingFALedgerEntry."Entry No.", FirstReversingFALedgerEntry."Reversed by Entry No.", FirstReversingFALedgerEntry.FieldCaption("Reversed by Entry No."));
        Assert.AreEqual(SecondCounterpartReversal."Entry No.", FirstCounterpartReversal."Reversed by Entry No.", FirstCounterpartReversal.FieldCaption("Reversed by Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MaintenanceReversalOfReversalPreservesMarksAndLinks()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FirstReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FirstCounterpartReversal: Record "Maintenance Ledger Entry";
        SecondReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        SecondCounterpartReversal: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617334] Reversal of a maintenance reversal keeps both reversal chains aligned
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, FirstReversingMaintenanceLedgerEntry);
        FindLinkedMaintenanceEntry(
            FirstCounterpartReversal, FirstReversingMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(FirstReversingMaintenanceLedgerEntry, SecondReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        FindLinkedMaintenanceEntry(
            SecondCounterpartReversal, SecondReversingMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        FirstReversingMaintenanceLedgerEntry.Get(FirstReversingMaintenanceLedgerEntry."Entry No.");
        FirstCounterpartReversal.Get(FirstCounterpartReversal."Entry No.");
        Assert.AreEqual(false, SourceMaintenanceLedgerEntry.Reversed, SourceMaintenanceLedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(false, CounterpartMaintenanceLedgerEntry.Reversed, CounterpartMaintenanceLedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(SecondReversingMaintenanceLedgerEntry."Entry No.", FirstReversingMaintenanceLedgerEntry."Reversed by Entry No.", FirstReversingMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."));
        Assert.AreEqual(SecondCounterpartReversal."Entry No.", FirstCounterpartReversal."Reversed by Entry No.", FirstCounterpartReversal.FieldCaption("Reversed by Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AutomaticSalvageCompanionsReverseThroughLinks()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        ReversingAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        ReversingSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageReversal: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617335] Automatic source and tax-book salvage companions reverse through their link
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            SourceAcquisitionFALedgerEntry, FANo, NormalDeprBookCode,
            SourceAcquisitionFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FindFALedgerEntry(
            SourceSalvageFALedgerEntry, FANo, NormalDeprBookCode,
            SourceSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        FindLinkedFAEntry(
            CounterpartSalvageFALedgerEntry, SourceSalvageFALedgerEntry."Entry No.", TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(SourceAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        CounterpartSalvageFALedgerEntry.Get(CounterpartSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(true, SourceSalvageFALedgerEntry.Reversed, SourceSalvageFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(true, CounterpartSalvageFALedgerEntry.Reversed, CounterpartSalvageFALedgerEntry.FieldCaption(Reversed));
        ReversingSalvageFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        ReversingSalvageFALedgerEntry.SetRange("Reversed Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        ReversingSalvageFALedgerEntry.FindFirst();
        FindLinkedFAEntry(
            CounterpartSalvageReversal, ReversingSalvageFALedgerEntry."Entry No.", TaxDeprBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TaxBookAcquisitionReversesSameBookAutomaticSalvageOnce()
    var
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        CounterpartAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        ReversingAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        FALedgerEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617340] Direct tax-book acquisition reversal reverses its automatic salvage companion once
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            SourceAcquisitionFALedgerEntry, FANo, NormalDeprBookCode,
            SourceAcquisitionFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FindLinkedFAEntry(
            CounterpartAcquisitionFALedgerEntry, SourceAcquisitionFALedgerEntry."Entry No.", TaxDeprBookCode);
        FindFALedgerEntry(
            SourceSalvageFALedgerEntry, FANo, NormalDeprBookCode,
            SourceSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        FindLinkedFAEntry(
            CounterpartSalvageFALedgerEntry, SourceSalvageFALedgerEntry."Entry No.", TaxDeprBookCode);
        FALedgerEntryCount := FALedgerEntry.Count();

        // [WHEN] The posting operation is performed
        ReverseFAEntry(CounterpartAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        CounterpartAcquisitionFALedgerEntry.Get(CounterpartAcquisitionFALedgerEntry."Entry No.");
        CounterpartSalvageFALedgerEntry.Get(CounterpartSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(ReversingAcquisitionFALedgerEntry."Entry No.", CounterpartAcquisitionFALedgerEntry."Reversed by Entry No.", CounterpartAcquisitionFALedgerEntry.FieldCaption("Reversed by Entry No."));
        Assert.AreEqual(true, CounterpartSalvageFALedgerEntry.Reversed, CounterpartSalvageFALedgerEntry.FieldCaption(Reversed));
        SourceAcquisitionFALedgerEntry.Get(SourceAcquisitionFALedgerEntry."Entry No.");
        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SourceAcquisitionFALedgerEntry.Reversed, SourceAcquisitionFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(false, SourceSalvageFALedgerEntry.Reversed, SourceSalvageFALedgerEntry.FieldCaption(Reversed));
        Assert.AreEqual(FALedgerEntryCount + 2, FALedgerEntry.Count(), NumberFAEntryErr);
        FALedgerEntry.SetRange("Reversed Entry No.", CounterpartSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DirectFACounterpartReversalPreservesRoleAfterSetupChange()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617341] Direct FA counterpart reversal keeps its persisted role after the book becomes a source
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ConfigureBookAsDerogatorySource(FANo, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(CounterpartFALedgerEntry, ReversingFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        Assert.AreEqual(ReversingFALedgerEntry."Entry No.", CounterpartFALedgerEntry."Reversed by Entry No.", CounterpartFALedgerEntry.FieldCaption("Reversed by Entry No."));
        Assert.AreEqual(CounterpartFALedgerEntry."Derogatory Source Entry No.", ReversingFALedgerEntry."Derogatory Source Entry No.", ReversingFALedgerEntry.FieldCaption("Derogatory Source Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DirectMaintenanceCounterpartReversalPreservesRoleAfterSetupChange()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617342] Direct maintenance counterpart reversal keeps its persisted role after the book becomes a source
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ConfigureBookAsDerogatorySource(FANo, TaxDeprBookCode);

        // [WHEN] The posting operation is performed
        ReverseMaintenanceEntry(CounterpartMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(ReversingMaintenanceLedgerEntry."Entry No.", CounterpartMaintenanceLedgerEntry."Reversed by Entry No.", CounterpartMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."));
        Assert.AreEqual(CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry."Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry.FieldCaption("Derogatory Source Entry No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AcquisitionReversesOnlyItsAdjacentAutomaticSalvage()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FirstAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        FirstSalvageFALedgerEntry: Record "FA Ledger Entry";
        SecondAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        SecondSalvageFALedgerEntry: Record "FA Ledger Entry";
        ReversingAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        SharedDocumentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617343] Shared posting metadata does not make an acquisition reverse another salvage companion
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        DepreciationBook.Get(NormalDeprBookCode);
        DepreciationBook."Allow Identical Document No." := true;
        DepreciationBook.Modify();
        DepreciationBook.Get(TaxDeprBookCode);
        DepreciationBook."Allow Identical Document No." := true;
        DepreciationBook.Modify();

        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);
        SharedDocumentNo := FAJournalLine."Document No.";
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            FirstAcquisitionFALedgerEntry, FANo, NormalDeprBookCode,
            FirstAcquisitionFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FirstSalvageFALedgerEntry.Get(FirstAcquisitionFALedgerEntry."Entry No." + 1);

        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Document No.", SharedDocumentNo);
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            SecondAcquisitionFALedgerEntry, FANo, NormalDeprBookCode,
            SecondAcquisitionFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        SecondSalvageFALedgerEntry.Get(SecondAcquisitionFALedgerEntry."Entry No." + 1);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(FirstAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        // [THEN] The posted entries and their links retain the expected values
        FirstSalvageFALedgerEntry.Get(FirstSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(true, FirstSalvageFALedgerEntry.Reversed, FirstSalvageFALedgerEntry.FieldCaption(Reversed));
        SecondAcquisitionFALedgerEntry.Get(SecondAcquisitionFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SecondAcquisitionFALedgerEntry.Reversed, SecondAcquisitionFALedgerEntry.FieldCaption(Reversed));
        SecondSalvageFALedgerEntry.Get(SecondSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SecondSalvageFALedgerEntry.Reversed, SecondSalvageFALedgerEntry.FieldCaption(Reversed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AcquisitionReversalOfReversalRestoresAutomaticSalvage()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        FirstAcquisitionReversal: Record "FA Ledger Entry";
        SecondAcquisitionReversal: Record "FA Ledger Entry";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617344] Reversal of an acquisition reversal restores its automatic salvage companion
        Initialize();

        // [GIVEN] FA "FA" has the posting setup and entries required by the scenario
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Salvage Value", -LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            SourceAcquisitionFALedgerEntry, FANo, NormalDeprBookCode,
            SourceAcquisitionFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        SourceSalvageFALedgerEntry.Get(SourceAcquisitionFALedgerEntry."Entry No." + 1);
        ReverseFAEntry(SourceAcquisitionFALedgerEntry, FirstAcquisitionReversal);

        // [WHEN] The posting operation is performed
        ReverseFAEntry(FirstAcquisitionReversal, SecondAcquisitionReversal);

        // [THEN] The posted entries and their links retain the expected values
        SourceAcquisitionFALedgerEntry.Get(SourceAcquisitionFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SourceAcquisitionFALedgerEntry.Reversed, SourceAcquisitionFALedgerEntry.FieldCaption(Reversed));
        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(false, SourceSalvageFALedgerEntry.Reversed, SourceSalvageFALedgerEntry.FieldCaption(Reversed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FAJournalBeforeEventRunsForSourceBeforeGeneratedMirror()
    var
        FAJournalLine: Record "FA Journal Line";
        EventSubscriber: Codeunit "ERM Derogatory Depr. Posting";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        EventCount: Integer;
        FirstBookCode: Code[10];
        SecondBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617319] FA journal event runs for the source before its generated mirror
        Initialize();

        // [GIVEN] FA "FA" with normal and derogatory depreciation books
        FANo := CreateFAWithNormalAndTaxFADeprBooks(
            NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandInt(10000));
        FAJournalLine.Validate(Description, FAJnlPostLineEventMarkerLbl);
        FAJournalLine.Modify(true);
        EventSubscriber.InitializeDerogatoryEventTracking();
        BindSubscription(EventSubscriber);

        // [WHEN] The acquisition is posted from the FA journal
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        UnbindSubscription(EventSubscriber);

        // [THEN] The event runs first for the source and then for the generated mirror
        EventSubscriber.GetFAJnlPostLineEventState(EventCount, FirstBookCode, SecondBookCode);
        Assert.AreEqual(2, EventCount, EventInvocationCountErr);
        Assert.AreEqual(NormalDepreciationBookCode, FirstBookCode, EventBookOrderErr);
        Assert.AreEqual(TaxDepreciationBookCode, SecondBookCode, EventBookOrderErr);
        VerifyLinkedCounterparts(FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure GeneralJournalBeforeEventRunsOnceBeforeCentralMirroring()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        EventSubscriber: Codeunit "ERM Derogatory Depr. Posting";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        EventCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617319] General journal event mutation is preserved by central mirroring
        Initialize();

        // [GIVEN] General journal acquisition "GJ" for FA "FA"
        FANo := CreateFAWithNormalAndTaxFADeprBooks(
            NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, true);
        CreateGenJournalLine(
            GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost",
            FANo, NormalDepreciationBookCode, LibraryRandom.RandInt(10000));
        GenJournalLine.Validate(Description, GenJnlPostLineEventMarkerLbl);
        GenJournalLine.Modify(true);
        EventSubscriber.InitializeDerogatoryEventTracking();
        BindSubscription(EventSubscriber);

        // [WHEN] General journal acquisition "GJ" is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UnbindSubscription(EventSubscriber);

        // [THEN] The event runs once and its mutation reaches the source and mirror
        EventSubscriber.GetGenJnlPostLineEventState(EventCount);
        Assert.AreEqual(1, EventCount, EventInvocationCountErr);
        FindFALedgerEntry(
            SourceFALedgerEntry, FANo, NormalDepreciationBookCode,
            SourceFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FindLinkedFAEntry(
            CounterpartFALedgerEntry, SourceFALedgerEntry."Entry No.", TaxDepreciationBookCode);
        Assert.AreEqual(
            GenJnlPostLineMutatedDescriptionLbl, SourceFALedgerEntry.Description, EventDescriptionErr);
        Assert.AreEqual(
            GenJnlPostLineMutatedDescriptionLbl, CounterpartFALedgerEntry.Description, EventDescriptionErr);
        VerifyLinkedCounterparts(FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeprUntilDateBeforeEventPreservesAutomaticSourceMirrorOrder()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        EventSubscriber: Codeunit "ERM Derogatory Depr. Posting";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        FAPostingDate: Date;
        EventCount: Integer;
        FirstBookCode: Code[10];
        SecondBookCode: Code[10];
        FirstEventType: Integer;
        SecondEventType: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617319] Depreciation-until-date event preserves automatic source and mirror order
        Initialize();

        // [GIVEN] Acquired FA "FA" with an automatic-only depreciation journal line
        FANo := CreateFAWithNormalAndTaxFADeprBooks(
            NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandInt(10000));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::Depreciation, 0);
        FAJournalLine.Validate("FA Posting Date", CalcDate('<1Y>', WorkDate()));
        FAJournalLine.Validate("Depr. until FA Posting Date", true);
        FAJournalLine.Validate(Description, PostDeprUntilDateEventMarkerLbl);
        FAJournalLine.Modify(true);
        FAPostingDate := FAJournalLine."FA Posting Date";
        EventSubscriber.InitializeDerogatoryEventTracking();
        BindSubscription(EventSubscriber);

        // [WHEN] The automatic-only depreciation line is posted
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        UnbindSubscription(EventSubscriber);

        // [THEN] The source event precedes the mirror event with the same calculation type
        EventSubscriber.GetPostDeprUntilDateEventState(
            EventCount, FirstBookCode, SecondBookCode, FirstEventType, SecondEventType);
        Assert.AreEqual(2, EventCount, EventInvocationCountErr);
        Assert.AreEqual(NormalDepreciationBookCode, FirstBookCode, EventBookOrderErr);
        Assert.AreEqual(TaxDepreciationBookCode, SecondBookCode, EventBookOrderErr);
        Assert.AreEqual(0, FirstEventType, EventTypeOrderErr);
        Assert.AreEqual(0, SecondEventType, EventTypeOrderErr);
        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", NormalDepreciationBookCode);
        SourceFALedgerEntry.SetRange("FA Posting Date", FAPostingDate);
        SourceFALedgerEntry.SetRange("Automatic Entry", true);
        Assert.IsFalse(SourceFALedgerEntry.IsEmpty(), NumberFAEntryErr);
        VerifyLinkedCounterparts(FANo, NormalDepreciationBookCode, TaxDepreciationBookCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinalMaintenanceLinkValidationRunsAfterPostingEvent()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        Maintenance: Record Maintenance;
        EventSubscriber: Codeunit "ERM Derogatory Depr. Posting";
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
        EventCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 617319] Final maintenance link validation runs after the posting event
        Initialize();

        // [GIVEN] Maintenance journal line "MJ" whose mirror is corrupted by a posting subscriber
        FANo := CreateFAWithNormalAndTaxFADeprBooks(
            NormalDepreciationBookCode, TaxDepreciationBookCode);
        UpdateIntegrationInBook(NormalDepreciationBookCode, false);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDepreciationBookCode,
            FAJournalLine."FA Posting Type"::Maintenance, LibraryRandom.RandInt(1000));
        FAJournalLine.Validate("Maintenance Code", Maintenance.Code);
        FAJournalLine.Validate(Description, MaintenanceValidationEventMarkerLbl);
        FAJournalLine.Modify(true);
        EventSubscriber.InitializeDerogatoryEventTracking();
        BindSubscription(EventSubscriber);

        // [WHEN] Maintenance journal line "MJ" is posted
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        UnbindSubscription(EventSubscriber);

        // [THEN] Final validation rejects the corrupted mirror and rolls back both entries
        Assert.ExpectedError(InvalidDerogatoryLinkTok);
        Assert.ExpectedErrorCode('Dialog');
        EventSubscriber.GetPostMaintenanceEventState(EventCount);
        Assert.AreEqual(2, EventCount, EventInvocationCountErr);
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        Assert.IsTrue(
            MaintenanceLedgerEntry.IsEmpty(),
            'The rejected maintenance source and counterpart must be rolled back together.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure OwnedJournalPostingPreservesForeignBatches()
    var
        FAJournalSetup: Record "FA Journal Setup";
        ForeignGenJournalBatch: Record "Gen. Journal Batch";
        ForeignGenJournalLine: Record "Gen. Journal Line";
        ForeignFAJournalBatch: Record "FA Journal Batch";
        ForeignFAJournalLine: Record "FA Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        GeneralLineBefore: Text;
        FALineBefore: Text;
        FANo: Code[20];
        NormalBookCode: Code[10];
        TaxBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Posting in fixture-owned journals leaves other batches unchanged.
        Initialize();

        // [GIVEN] FA "A" has owned journals, with unrelated rows in other batches of the same templates.
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalBookCode, TaxBookCode);
        FAJournalSetup.Get(NormalBookCode, '');
        LibraryERM.CreateGenJournalBatch(ForeignGenJournalBatch, FAJournalSetup."Gen. Jnl. Template Name");
        LibraryERM.CreateGeneralJnlLine(
            ForeignGenJournalLine, ForeignGenJournalBatch."Journal Template Name", ForeignGenJournalBatch.Name,
            ForeignGenJournalLine."Document Type"::" ", ForeignGenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), 100);
        LibraryFixedAsset.CreateFAJournalBatch(ForeignFAJournalBatch, FAJournalSetup."FA Jnl. Template Name");
        LibraryFixedAsset.CreateFAJournalLine(ForeignFAJournalLine, ForeignFAJournalBatch."Journal Template Name", ForeignFAJournalBatch.Name);
        GeneralLineBefore := Format(ForeignGenJournalLine);
        FALineBefore := Format(ForeignFAJournalLine);

        // [WHEN] A valid general-journal acquisition and FA-journal maintenance are posted by batch.
        CreatePostGenJnlLine(GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo, NormalBookCode, 1000);
        PostLinkedMaintenance(SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry, FANo, NormalBookCode, TaxBookCode);

        // [THEN] Both foreign rows are unchanged and posting created one linked counterpart per entry.
        ForeignGenJournalLine.Get(ForeignGenJournalLine."Journal Template Name", ForeignGenJournalLine."Journal Batch Name", ForeignGenJournalLine."Line No.");
        ForeignFAJournalLine.Get(ForeignFAJournalLine."Journal Template Name", ForeignFAJournalLine."Journal Batch Name", ForeignFAJournalLine."Line No.");
        Assert.AreEqual(GeneralLineBefore, Format(ForeignGenJournalLine), 'Foreign general journal rows must remain untouched.');
        Assert.AreEqual(FALineBefore, Format(ForeignFAJournalLine), 'Foreign FA journal rows must remain untouched.');
        VerifyLinkedCounterparts(FANo, NormalBookCode, TaxBookCode);
        VerifyLinkedMaintenanceCounterparts(FANo, NormalBookCode, TaxBookCode);
    end;

    local procedure Initialize()
    begin
        Initialize(true);
    end;

    local procedure Initialize(EnableComposedFrenchFeature: Boolean)
    begin
        if EnableComposedFrenchFeature then
            ComposedFrenchFeatureStateCleanup.EnableFeatureForComposedFrenchTests();
    end;

    local procedure GetFeatureState(): Text
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureDataUpdateStatus.Get('AcceleratedDepreciation', CompanyName()) then
            exit(Format(FeatureDataUpdateStatus."Feature Status"));
        exit('Absent');
    end;

    local procedure ChangeFeatureState()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if not FeatureDataUpdateStatus.Get('AcceleratedDepreciation', CompanyName()) then begin
            FeatureDataUpdateStatus."Feature Key" := 'AcceleratedDepreciation';
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus.Insert();
        end;
        if FeatureDataUpdateStatus."Feature Status" = FeatureDataUpdateStatus."Feature Status"::Enabled then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled
        else
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Enabled;
        FeatureDataUpdateStatus.Modify();
    end;

    local procedure CalcDerogatoryDate(): Date
    begin
        exit(CalcDate('<1M>', WorkDate()));
    end;

    local procedure CancelLastFALedgerEntry(DepreciationBookCode: Code[10]; FAPostingType: Option)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        FALedgerEntries.OpenEdit();
        FALedgerEntry.SetFilter("Depreciation Book Code", DepreciationBookCode);
        FALedgerEntry.SetFilter("FA Posting Type", Format(FAPostingType));
        FALedgerEntry.FindLast();
        FALedgerEntries.FILTER.SetFilter("Entry No.", Format(FALedgerEntry."Entry No."));
        FALedgerEntries.CancelEntries.Invoke();  // Open handler - CancelFAEntriesRequestPageHandler.
        FALedgerEntries.OK().Invoke();
    end;

    local procedure ChangeDerogatoryRelationship(FANo: Code[20]; NormalDeprBookCode: Code[10]; TaxDeprBookCode: Code[10]): Code[10]
    var
        NormalFADepreciationBook: Record "FA Depreciation Book";
        NewTaxDeprBookCode: Code[10];
    begin
        ClearDerogatoryRelationship(TaxDeprBookCode);
        NewTaxDeprBookCode := CreateDeprBookModifyDerogCalc(NormalDeprBookCode);
        NormalFADepreciationBook.Get(FANo, NormalDeprBookCode);
        CreateFADeprBookWithDates(
            FANo, NewTaxDeprBookCode, NormalFADepreciationBook."FA Posting Group",
            NormalFADepreciationBook."Depreciation Starting Date", NormalFADepreciationBook."Depreciation Ending Date");
        exit(NewTaxDeprBookCode);
    end;

    local procedure CheckFALedgerEntries(FANo: Code[20]; DeprBookCode: Code[20])
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
        Assert.IsFalse(FALedgEntry.IsEmpty, NoPurchInvoiceExistErr);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Derogatory);
        Assert.IsFalse(FALedgEntry.IsEmpty, NoPurchInvoiceExistErr);
    end;

    local procedure ClearDerogatoryRelationship(TaxDeprBookCode: Code[10])
    var
        TaxDepreciationBook: Record "Depreciation Book";
    begin
        TaxDepreciationBook.Get(TaxDeprBookCode);
        TaxDepreciationBook.Validate("Derogatory Calc.", '');
        TaxDepreciationBook.Modify(true);
    end;

    local procedure ConfigureBookAsDerogatorySource(FANo: Code[20]; SourceDeprBookCode: Code[10])
    var
        SourceFADepreciationBook: Record "FA Depreciation Book";
        NewTaxDeprBookCode: Code[10];
    begin
        ClearDerogatoryRelationship(SourceDeprBookCode);
        NewTaxDeprBookCode := CreateDeprBookModifyDerogCalc(SourceDeprBookCode);
        SourceFADepreciationBook.Get(FANo, SourceDeprBookCode);
        CreateFADeprBookWithDates(
            FANo, NewTaxDeprBookCode, SourceFADepreciationBook."FA Posting Group",
            SourceFADepreciationBook."Depreciation Starting Date", SourceFADepreciationBook."Depreciation Ending Date");
    end;

    local procedure CreateAndPostPurchaseInvoice(FANo: Code[20]; DeprBookCode: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("FA Posting Type", PurchaseLine."FA Posting Type"::"Acquisition Cost");
        PurchaseLine.Validate("Depreciation Book Code", DeprBookCode);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndSetupDeprBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateDeprBookModifyDerogCalc(DerogDeprBookCode: Code[10]): Code[10]
    var
        DeprBook: Record "Depreciation Book";
    begin
        CreateAndSetupDeprBook(DeprBook);
        DeprBook.Validate("Use Same FA+G/L Posting Dates", false);
        DeprBook.Validate("Derogatory Calc.", DerogDeprBookCode);
        DeprBook.Modify(true);
        exit(DeprBook.Code);
    end;

    local procedure CreateDuplicationTarget(var DuplicateDepreciationBook: Record "Depreciation Book"; FANo: Code[20]; var DuplicateTemplateName: Code[10]; var DuplicateBatchName: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateAndSetupDeprBook(DuplicateDepreciationBook);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalSetup.Get(DuplicateDepreciationBook.Code, '');
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Modify(true);
        LibraryFixedAsset.CreateFADepreciationBook(
            FADepreciationBook, FANo, DuplicateDepreciationBook.Code);
        DuplicateTemplateName := FAJournalBatch."Journal Template Name";
        DuplicateBatchName := FAJournalBatch.Name;
    end;

    local procedure CreateFADeprBookWithDates(FANo: Code[20]; DeprBookCode: Code[10]; FAPostingGroup: Code[20]; StartingDate: Date; EndingDate: Date)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADeprBook, FANo, DeprBookCode);
        FADeprBook.Validate("Depreciation Book Code", DeprBookCode);
        FADeprBook.Validate("Depreciation Starting Date", StartingDate);
        FADeprBook.Validate("Depreciation Ending Date", EndingDate);
        FADeprBook.Validate("FA Posting Group", FAPostingGroup);
        FADeprBook.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalBatch.Get(FAJournalSetup."FA Jnl. Template Name", FAJournalSetup."FA Jnl. Batch Name");
        // Some localizations ship the FA journal batch without a No. Series, which leaves the line's
        // Document No. blank and blocks posting. Ensure a No. Series so the document number is assigned.
        if FAJournalBatch."No. Series" = '' then begin
            FAJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            FAJournalBatch.Modify(true);
        end;
        LibraryERM.CreateFAJournalLine(
          FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name,
          FAJournalLine."Document Type"::" ", FAPostingType,
          FANo, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAPostingGroup(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        CreateFixedAsset(FixedAsset);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        UpdateFAPostingGroup(FAPostingGroup);
    end;

    local procedure CreateFAWithBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10]; StartingDate: Date; EndingDate: Date): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateNormalAndTaxDeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateFAPostingGroup(FixedAsset);
        DepreciationBook.Get(NormalDeprBookCode);
        DepreciationBook."Use Rounding in Periodic Depr." := true;
        DepreciationBook."G/L Integration - Depreciation" := true;
        DepreciationBook."Use FA Ledger Check" := true;
        DepreciationBook."Use Same FA+G/L Posting Dates" := true;
        DepreciationBook."Derogatory Book Code" := TaxDeprBookCode;
        DepreciationBook.Modify(true);

        DepreciationBook.Get(TaxDeprBookCode);
        DepreciationBook."Allow more than 360/365 Days" := true;
        DepreciationBook."Use FA Ledger Check" := true;
        DepreciationBook."Use Same FA+G/L Posting Dates" := true;
        DepreciationBook.Modify(true);
        CreateFADeprBookWithDates(FixedAsset."No.", NormalDeprBookCode, FixedAsset."FA Posting Group", StartingDate, EndingDate);
        CreateFADeprBookWithDates(FixedAsset."No.", TaxDeprBookCode, FixedAsset."FA Posting Group", StartingDate, EndingDate);
        exit(FixedAsset."No.");
    end;

    local procedure CreateFAWithNormalAndTaxFADeprBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateNormalAndTaxDeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateFAPostingGroup(FixedAsset);
        CreateFADeprBookWithDates(FixedAsset."No.", NormalDeprBookCode, FixedAsset."FA Posting Group", WorkDate(), CalcDate('<5Y>', WorkDate()));
        CreateFADeprBookWithDates(FixedAsset."No.", TaxDeprBookCode, FixedAsset."FA Posting Group", WorkDate(), CalcDate('<3Y>', WorkDate()));
        exit(FixedAsset."No.");
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DeprBookCode: Code[10]; LineAmount: Decimal)
    var
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FAJournalSetup.Get(DeprBookCode, '');
        GenJournalBatch.Get(FAJournalSetup."Gen. Jnl. Template Name", FAJournalSetup."Gen. Jnl. Batch Name");
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"Fixed Asset", FANo, LineAmount);
        GenJnlLine.Validate("FA Posting Type", FAPostingType);
        GenJnlLine.Validate("FA Posting Date", FAPostingDate);
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJnlLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateNormalAndTaxDeprBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10])
    begin
        NormalDeprBookCode := CreateDeprBookModifyDerogCalc('');
        UpdateIntegrationInBook(NormalDeprBookCode, true);
        TaxDeprBookCode := CreateDeprBookModifyDerogCalc(NormalDeprBookCode);
    end;

    local procedure CreatePostAcquisitionAndDerogatory(var AcqCostAmount: Decimal; var DerogAmount: Decimal; FANo: Code[20]; DeprBookCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        AcqCostAmount := LibraryRandom.RandIntInRange(10000, 50000);
        DerogAmount := Round(AcqCostAmount / 3, LibraryERM.GetAmountRoundingPrecision());
        CreatePostGenJnlLine(
          GenJnlLine, WorkDate(), GenJnlLine."FA Posting Type"::"Acquisition Cost",
          FANo, DeprBookCode, AcqCostAmount);
        CreatePostGenJnlLine(
          GenJnlLine, CalcDerogatoryDate(), GenJnlLine."FA Posting Type"::Derogatory,
          FANo, DeprBookCode, -DerogAmount);
    end;

    local procedure CreatePostFAJournalLines(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLine(
          FAJournalLine, FANo, DeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        CreateFAJournalLine(
          FAJournalLine, FANo, DeprBookCode, FAJournalLine."FA Posting Type"::Depreciation,
          -LibraryRandom.RandDec(50, 2));
        CreateFAJournalLine(
          FAJournalLine, FANo, DeprBookCode, FAJournalLine."FA Posting Type"::Derogatory,
          -LibraryRandom.RandDec(50, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreatePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DeprBookCode: Code[10]; Amount: Decimal)
    begin
        CreateGenJournalLine(
          GenJnlLine, FAPostingDate, FAPostingType, FANo, DeprBookCode, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreatePurchaseInvoiceAndPost(FANo: Code[20]; DeprBookCode: Code[20]; Quantity: Decimal; Price: Decimal; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Price);
        PurchaseLine.Validate("Depreciation Book Code", DeprBookCode);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindLast();
    end;

    local procedure FindLinkedFAEntry(var FALedgerEntry: Record "FA Ledger Entry"; SourceEntryNo: Integer; DepreciationBookCode: Code[10])
    begin
        FALedgerEntry.SetRange("Derogatory Source Entry No.", SourceEntryNo);
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        Assert.AreEqual(1, FALedgerEntry.Count(), NumberFAEntryErr);
        FALedgerEntry.FindFirst();
    end;

    local procedure FindLinkedMaintenanceEntry(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceEntryNo: Integer; DepreciationBookCode: Code[10])
    begin
        MaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", SourceEntryNo);
        MaintenanceLedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        Assert.AreEqual(1, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        MaintenanceLedgerEntry.FindFirst();
    end;

    internal procedure GetFAJnlPostLineEventState(var EventCount: Integer; var FirstBookCode: Code[10]; var SecondBookCode: Code[10])
    begin
        EventCount := FAJnlPostLineEventCount;
        FirstBookCode := FirstFAJnlPostLineBookCode;
        SecondBookCode := SecondFAJnlPostLineBookCode;
    end;

    internal procedure GetGenJnlPostLineEventState(var EventCount: Integer)
    begin
        EventCount := GenJnlPostLineEventCount;
    end;

    internal procedure GetPostDeprUntilDateEventState(var EventCount: Integer; var FirstBookCode: Code[10]; var SecondBookCode: Code[10]; var FirstEventType: Integer; var SecondEventType: Integer)
    begin
        EventCount := PostDeprUntilDateEventCount;
        FirstBookCode := FirstPostDeprUntilDateBookCode;
        SecondBookCode := SecondPostDeprUntilDateBookCode;
        FirstEventType := FirstPostDeprUntilDateType;
        SecondEventType := SecondPostDeprUntilDateType;
    end;

    internal procedure GetPostMaintenanceEventState(var EventCount: Integer)
    begin
        EventCount := PostMaintenanceEventCount;
    end;

    internal procedure InitializeDerogatoryEventTracking()
    begin
        Clear(FAJnlPostLineEventCount);
        Clear(FirstFAJnlPostLineBookCode);
        Clear(SecondFAJnlPostLineBookCode);
        Clear(GenJnlPostLineEventCount);
        Clear(PostDeprUntilDateEventCount);
        Clear(FirstPostDeprUntilDateBookCode);
        Clear(SecondPostDeprUntilDateBookCode);
        Clear(FirstPostDeprUntilDateType);
        Clear(SecondPostDeprUntilDateType);
        Clear(PostMaintenanceEventCount);
    end;

    local procedure InsertDuplicateFALinkInAnotherBook(CounterpartFALedgerEntry: Record "FA Ledger Entry")
    var
        LastFALedgerEntry: Record "FA Ledger Entry";
    begin
        LastFALedgerEntry.FindLast();
        CounterpartFALedgerEntry."Entry No." := LastFALedgerEntry."Entry No." + 1;
        CounterpartFALedgerEntry."Depreciation Book Code" := CreateDeprBookModifyDerogCalc('');
        CounterpartFALedgerEntry.Insert();
    end;

    local procedure InsertDuplicateMaintenanceLinkInAnotherBook(CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        LastMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        LastMaintenanceLedgerEntry.FindLast();
        CounterpartMaintenanceLedgerEntry."Entry No." := LastMaintenanceLedgerEntry."Entry No." + 1;
        CounterpartMaintenanceLedgerEntry."Depreciation Book Code" := CreateDeprBookModifyDerogCalc('');
        CounterpartMaintenanceLedgerEntry.Insert();
    end;

    local procedure MarkFAEntriesAsAmbiguousLegacy(var SourceFALedgerEntry: Record "FA Ledger Entry"; var CounterpartFALedgerEntry: Record "FA Ledger Entry")
    begin
        SourceFALedgerEntry."Legacy Derogatory Ambiguous" := true;
        SourceFALedgerEntry.Modify();
        CounterpartFALedgerEntry."Derogatory Source Entry No." := 0;
        CounterpartFALedgerEntry.Modify();
    end;

    local procedure MarkMaintenanceEntriesAsAmbiguousLegacy(var SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        SourceMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" := true;
        SourceMaintenanceLedgerEntry.Modify();
        CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := 0;
        CounterpartMaintenanceLedgerEntry.Modify();
    end;

    local procedure PostLinkedFAAcquisition(var SourceFALedgerEntry: Record "FA Ledger Entry"; var CounterpartFALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; NormalDeprBookCode: Code[10]; TaxDeprBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFALedgerEntry(
            SourceFALedgerEntry, FANo, NormalDeprBookCode,
            SourceFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FindLinkedFAEntry(CounterpartFALedgerEntry, SourceFALedgerEntry."Entry No.", TaxDeprBookCode);
        VerifyTaxBookFALedgerEntryCount(FANo, TaxDeprBookCode, 1);
    end;

    local procedure PostLinkedMaintenance(var SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FANo: Code[20]; NormalDeprBookCode: Code[10]; TaxDeprBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        Maintenance: Record Maintenance;
    begin
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        CreateFAJournalLine(
            FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::Maintenance,
            LibraryRandom.RandDec(1000, 2));
        FAJournalLine.Validate("Maintenance Code", Maintenance.Code);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        SourceMaintenanceLedgerEntry.SetRange("FA No.", FANo);
        SourceMaintenanceLedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        SourceMaintenanceLedgerEntry.FindLast();
        FindLinkedMaintenanceEntry(
            CounterpartMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);
        VerifyTaxBookMaintenanceLedgerEntryCount(FANo, TaxDeprBookCode, 1);
    end;

    local procedure PrepareDirectFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry")
    begin
        FALedgerEntry."Entry No." := 0;
        FALedgerEntry."Document No." := LibraryRandom.RandText(MaxStrLen(FALedgerEntry."Document No."));
        FALedgerEntry."Journal Batch Name" := '';
        FALedgerEntry."Derogatory Source Entry No." := 0;
        FALedgerEntry.Reversed := false;
        FALedgerEntry."Reversed by Entry No." := 0;
        FALedgerEntry."Reversed Entry No." := 0;
    end;

    local procedure PrepareDirectMaintenanceLedgerEntry(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        MaintenanceLedgerEntry."Entry No." := 0;
        MaintenanceLedgerEntry."Document No." :=
            LibraryRandom.RandText(MaxStrLen(MaintenanceLedgerEntry."Document No."));
        MaintenanceLedgerEntry."Journal Batch Name" := '';
        MaintenanceLedgerEntry."Derogatory Source Entry No." := 0;
        MaintenanceLedgerEntry.Reversed := false;
        MaintenanceLedgerEntry."Reversed by Entry No." := 0;
        MaintenanceLedgerEntry."Reversed Entry No." := 0;
    end;

    local procedure ReverseFAEntry(FALedgerEntry: Record "FA Ledger Entry"; var ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        FAInsertLedgerEntry.InsertReverseEntry(0, 1, FALedgerEntry."Entry No.", NewEntryNo, 0);
        ReversingFALedgerEntry.Get(NewEntryNo);
    end;

    local procedure ReverseFALedgerEntries(var FALedgerEntry: Record "FA Ledger Entry")
    var
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        FALedgerEntries.OpenEdit();
        FALedgerEntries.FILTER.SetFilter("Entry No.", Format(FALedgerEntry."Entry No."));
        FALedgerEntries.ReverseTransaction.Invoke();
        FALedgerEntries.OK().Invoke();
    end;

    local procedure ReverseMaintenanceEntry(MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        FAInsertLedgerEntry.InsertReverseEntry(0, 2, MaintenanceLedgerEntry."Entry No.", NewEntryNo, 0);
        ReversingMaintenanceLedgerEntry.Get(NewEntryNo);
    end;

    local procedure RunCalculateDepreciationReport(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; BalanceAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, PostingDate, false, 0, PostingDate, '', FixedAsset.Description, BalanceAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunCalculateDepreciationReportAndPostJournalLines(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; BalanceAccount: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        RunCalculateDepreciationReport(FixedAssetNo, DepreciationBookCode, PostingDate, BalanceAccount);

        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCalculateDepReportForDifferentPostingDates(FANo: Code[20]; NormalDeprBookCode: Code[10]; DepreciationEndingDate: Date)
    begin
        RunCalculateDepreciationReportAndPostJournalLines(FANo, NormalDeprBookCode, DepreciationEndingDate, true);
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), DepreciationEndingDate), true);
    end;

    local procedure UpdateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; TaxDeprBookCode: Code[10]; EndingDate: Date)
    begin
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate(StrSubstNo('<-%1M>', LibraryRandom.RandIntInRange(5, 7)), EndingDate));
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        FAJournalBatch.Modify(true);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        FAPostingGroup.Validate("Derogatory Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Derogatory Account (Decrease)", CreateGLAccount());
        FAPostingGroup.Validate("Derogatory Expense Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", CreateGLAccount());
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DeprBookCode: Code[10]; Value: Boolean)
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(DeprBookCode);
        // Set every G/L integration flag deterministically. Some localizations post the acquisition as a
        // different FA posting type (e.g. CZ posts it as Custom 2), so all types must be integrated for the
        // purchase/derogatory postings to succeed regardless of country.
        DeprBook.Validate("G/L Integration - Acq. Cost", Value);
        DeprBook.Validate("G/L Integration - Depreciation", Value);
        DeprBook.Validate("G/L Integration - Write-Down", Value);
        DeprBook.Validate("G/L Integration - Appreciation", Value);
        DeprBook.Validate("G/L Integration - Custom 1", Value);
        DeprBook.Validate("G/L Integration - Custom 2", Value);
        DeprBook.Validate("G/L Integration - Disposal", Value);
        DeprBook.Validate("G/L Integration - Maintenance", Value);
        DeprBook.Validate("Integration G/L - Derogatory", Value);
        DeprBook.Modify(true);
    end;

    local procedure VerifyAllFALedgEntriesReversed(LastFALedgerEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetFilter("Entry No.", '>%1', LastFALedgerEntryNo);
        FALedgerEntry.SetRange("Reversed by Entry No.", 0);
        FALedgerEntry.SetRange("Reversed Entry No.", 0);
        Assert.AreEqual(0, FALedgerEntry.Count, NumberFAEntryErr);
    end;

    local procedure VerifyBookValueAmounts(FANo: Code[20]; DeprBookCode: Code[10]; ExpectedBookValueAmt: Decimal; ExpectedDerogatoryAmt: Decimal)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        VerifyExcludeDerogatory(FANo, DeprBookCode);
        FADeprBook.Get(FANo, DeprBookCode);
        FADeprBook.CalcFields("Book Value");
        FADeprBook.CalcFields("Derogatory Amount");
        FADeprBook.TestField("Book Value", ExpectedBookValueAmt);
        FADeprBook.TestField("Derogatory Amount", ExpectedDerogatoryAmt);
    end;

    local procedure VerifyCalculatedSourceReversal(SourceFALedgerEntry: Record "FA Ledger Entry"; CounterpartFALedgerEntry: Record "FA Ledger Entry"; TaxDeprBookCode: Code[10])
    var
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        CounterpartReversal: Record "FA Ledger Entry";
    begin
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        SourceFALedgerEntry.TestField(Reversed, true);
        SourceFALedgerEntry.TestField("Reversed by Entry No.");
        ReversingFALedgerEntry.Get(SourceFALedgerEntry."Reversed by Entry No.");
        ReversingFALedgerEntry.TestField("Reversed Entry No.", SourceFALedgerEntry."Entry No.");
        FindLinkedFAEntry(CounterpartReversal, ReversingFALedgerEntry."Entry No.", TaxDeprBookCode);
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.TestField(Reversed, true);
        CounterpartFALedgerEntry.TestField("Reversed by Entry No.", CounterpartReversal."Entry No.");
        CounterpartReversal.TestField("Reversed Entry No.", CounterpartFALedgerEntry."Entry No.");
    end;

    local procedure VerifyExcludeDerogatory(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FALedgEntry: Record "FA Ledger Entry";
        DeprBook: Record "Depreciation Book";
        DerogatoryBook: Boolean;
    begin
        DeprBook.Get(DeprBookCode);
        DerogatoryBook := DeprBook.IsDerogatoryBook();
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.FindSet();
        repeat
            FALedgEntry.TestField(
              "Derogatory Excluded",
              (FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::Derogatory) and not DerogatoryBook);
        until FALedgEntry.Next() = 0;
    end;

    local procedure VerifyFAJournalLine(FANo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("FA No.", FANo);
        FAJournalLine.SetRange("FA Posting Type", FAJournalLine."FA Posting Type"::Derogatory);
        Assert.IsTrue(FAJournalLine.FindFirst(), WrongJournalUsedErr);
    end;

    local procedure VerifyFAPostingDate(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetFilter(
          "FA Posting Type", '%1|%2',
          FALedgerEntry."FA Posting Type"::Depreciation,
          FALedgerEntry."FA Posting Type"::Derogatory);
        FALedgerEntry.FindSet();
        repeat
            FALedgerEntry.TestField("FA Posting Date", CalcDerogatoryDate());
        until FALedgerEntry.Next() = 0;
    end;

    local procedure VerifyFinalDepreciationWithNegativeDerogatory(FixedAssetNo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationSum: Decimal;
        AcqusiutionSum: Decimal;
    begin
        FALedgerEntry.SetRange("FA No.", FixedAssetNo);
        FALedgerEntry.SetFilter("FA Posting Type", '%1|%2', FALedgerEntry."FA Posting Type"::Depreciation, FALedgerEntry."FA Posting Type"::Derogatory);
        FALedgerEntry.CalcSums(Amount);
        DepreciationSum := FALedgerEntry.Amount;

        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Depreciation Book Code");
        FALedgerEntry.CalcSums(Amount);
        AcqusiutionSum := FALedgerEntry.Amount;

        Assert.AreEqual(DepreciationSum, -AcqusiutionSum, DepreciationErr);
    end;

    local procedure VerifyLinkedCounterparts(FANo: Code[20]; NormalDepreciationBookCode: Code[10]; TaxDepreciationBookCode: Code[10])
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ExpectedCounterpartCount: Integer;
    begin
        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", NormalDepreciationBookCode);
        ExpectedCounterpartCount := SourceFALedgerEntry.Count();
        SourceFALedgerEntry.FindSet();
        repeat
            SourceFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
            CounterpartFALedgerEntry.Reset();
            CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
            CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
            Assert.AreEqual(1, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
        until SourceFALedgerEntry.Next() = 0;
        CounterpartFALedgerEntry.Reset();
        CounterpartFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        Assert.AreEqual(ExpectedCounterpartCount, CounterpartFALedgerEntry.Count(), NumberFAEntryErr);
        CounterpartFALedgerEntry.SetFilter("Derogatory Source Entry No.", '<>%1', 0);
        Assert.AreEqual(ExpectedCounterpartCount, CounterpartFALedgerEntry.Count(), NumberFAEntryErr);
    end;

    local procedure VerifyLinkedFAReversal(SourceFALedgerEntry: Record "FA Ledger Entry"; CounterpartFALedgerEntry: Record "FA Ledger Entry"; ReversingFALedgerEntry: Record "FA Ledger Entry"; TaxDeprBookCode: Code[10])
    var
        CounterpartReversal: Record "FA Ledger Entry";
    begin
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        SourceFALedgerEntry.TestField("Reversed by Entry No.", ReversingFALedgerEntry."Entry No.");
        FindLinkedFAEntry(CounterpartReversal, ReversingFALedgerEntry."Entry No.", TaxDeprBookCode);
        CounterpartFALedgerEntry.TestField("Reversed by Entry No.", CounterpartReversal."Entry No.");
        VerifyTaxBookFALedgerEntryCount(SourceFALedgerEntry."FA No.", TaxDeprBookCode, 2);
    end;

    local procedure VerifyLinkedMaintenanceCounterparts(FANo: Code[20]; NormalDepreciationBookCode: Code[10]; TaxDepreciationBookCode: Code[10])
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ExpectedCounterpartCount: Integer;
    begin
        SourceMaintenanceLedgerEntry.SetRange("FA No.", FANo);
        SourceMaintenanceLedgerEntry.SetRange("Depreciation Book Code", NormalDepreciationBookCode);
        ExpectedCounterpartCount := SourceMaintenanceLedgerEntry.Count();
        SourceMaintenanceLedgerEntry.FindSet();
        repeat
            SourceMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 0);
            CounterpartMaintenanceLedgerEntry.Reset();
            CounterpartMaintenanceLedgerEntry.SetRange(
                "Derogatory Source Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
            CounterpartMaintenanceLedgerEntry.SetRange(
                "Depreciation Book Code", TaxDepreciationBookCode);
            Assert.AreEqual(1, CounterpartMaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        until SourceMaintenanceLedgerEntry.Next() = 0;
        CounterpartMaintenanceLedgerEntry.Reset();
        CounterpartMaintenanceLedgerEntry.SetRange("FA No.", FANo);
        CounterpartMaintenanceLedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
        Assert.AreEqual(
            ExpectedCounterpartCount, CounterpartMaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        CounterpartMaintenanceLedgerEntry.SetFilter("Derogatory Source Entry No.", '<>%1', 0);
        Assert.AreEqual(
            ExpectedCounterpartCount, CounterpartMaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
    end;

    local procedure VerifyLinkedMaintenanceReversal(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; TaxDeprBookCode: Code[10])
    var
        CounterpartReversal: Record "Maintenance Ledger Entry";
    begin
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        SourceMaintenanceLedgerEntry.TestField("Reversed by Entry No.", ReversingMaintenanceLedgerEntry."Entry No.");
        FindLinkedMaintenanceEntry(
            CounterpartReversal, ReversingMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);
        CounterpartMaintenanceLedgerEntry.TestField("Reversed by Entry No.", CounterpartReversal."Entry No.");
        VerifyTaxBookMaintenanceLedgerEntryCount(
            SourceMaintenanceLedgerEntry."FA No.", TaxDeprBookCode, 2);
    end;

    local procedure VerifyNoOfFALedgerEntries(Expected: Integer; ErrorMsg: Text; FANo: Code[20]; HasGLEntry: Boolean; FAPostingType: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        if HasGLEntry then
            FALedgerEntry.SetFilter("G/L Entry No.", '>0');
        if FAPostingType <> -1 then
            FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        Assert.AreEqual(Expected, FALedgerEntry.Count, ErrorMsg);
    end;

    local procedure VerifyPostedInvoice(DocumentNo: Code[20])
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(PurchaseInvoiceLine.IsEmpty, NoPurchInvoiceExistErr);
    end;

    local procedure VerifyTaxBookFALedgerEntryCount(FANo: Code[20]; TaxDeprBookCode: Code[10]; ExpectedCount: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        Assert.AreEqual(ExpectedCount, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    local procedure VerifyTaxBookMaintenanceLedgerEntryCount(FANo: Code[20]; TaxDeprBookCode: Code[10]; ExpectedCount: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        Assert.AreEqual(ExpectedCount, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    procedure CancelFALedgerEntryRequestPageHandler(var CancelFAEntries: TestRequestPage "Cancel FA Entries")
    begin
        CancelFAEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ReverseFALedgerEntriesPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke();
    end;

    [ConfirmHandler]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Message, CompletionStatsTok) then
            Reply := false
        else
            Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnBeforeFAJnlPostLine', '', false, false)]
    local procedure TrackFAJnlPostLineBookOrder(var FAJournalLine: Record "FA Journal Line"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; CheckLine: Boolean; var IsHandled: Boolean)
    begin
        if FAJournalLine.Description <> FAJnlPostLineEventMarkerLbl then
            exit;

        FAJnlPostLineEventCount += 1;
        case FAJnlPostLineEventCount of
            1:
                FirstFAJnlPostLineBookCode := FAJournalLine."Depreciation Book Code";
            2:
                SecondFAJnlPostLineBookCode := FAJournalLine."Depreciation Book Code";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnBeforeGenJnlPostLine', '', false, false)]
    local procedure MutateDescriptionBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; FAAmount: Decimal; VATAmount: Decimal; NextTransactionNo: Integer; NextGLEntryNo: Integer; GLRegisterNo: Integer; var IsHandled: Boolean)
    begin
        if GenJournalLine.Description <> GenJnlPostLineEventMarkerLbl then
            exit;

        GenJnlPostLineEventCount += 1;
        GenJournalLine.Description := GenJnlPostLineMutatedDescriptionLbl;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnBeforePostDeprUntilDate', '', false, false)]
    local procedure TrackPostDeprUntilDateBookOrder(var FALedgEntry: Record "FA Ledger Entry"; var FAPostingDate: Date; Type: Option; var IsHandled: Boolean)
    begin
        if FALedgEntry.Description <> PostDeprUntilDateEventMarkerLbl then
            exit;

        PostDeprUntilDateEventCount += 1;
        case PostDeprUntilDateEventCount of
            1:
                begin
                    FirstPostDeprUntilDateBookCode := FALedgEntry."Depreciation Book Code";
                    FirstPostDeprUntilDateType := Type;
                end;
            2:
                begin
                    SecondPostDeprUntilDateBookCode := FALedgEntry."Depreciation Book Code";
                    SecondPostDeprUntilDateType := Type;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnPostFixedAssetOnBeforeInsertEntry', '', false, false)]
    local procedure CorruptGeneratedMirrorLinkAfterPostingEvent(var FALedgEntry: Record "FA Ledger Entry")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        if FALedgEntry.Description <> FinalValidationEventMarkerLbl then
            exit;

        DepreciationBook.Get(FALedgEntry."Depreciation Book Code");
        if DepreciationBook."Derogatory Calc." = '' then
            exit;

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FALedgEntry."FA No." := FixedAsset."No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnPostMaintenanceOnBeforeInsertEntry', '', false, false)]
    local procedure CorruptGeneratedMaintenanceMirrorAfterPostingEvent(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        if MaintenanceLedgEntry.Description <> MaintenanceValidationEventMarkerLbl then
            exit;

        PostMaintenanceEventCount += 1;
        DepreciationBook.Get(MaintenanceLedgEntry."Depreciation Book Code");
        if DepreciationBook."Derogatory Calc." = '' then
            exit;

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        MaintenanceLedgEntry."FA No." := FixedAsset."No.";
    end;

}
