codeunit 144002 "ERM Fixed Assets - Local"
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

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
#if not CLEAN28
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
#endif
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        WrongJournalUsedErr: Label 'FA Journal without G/L Integration should be used for depreciation calculation.';
        NoPurchInvoiceExistErr: Label 'Purchase invoice was not posted.';
        DepreciationErr: Label 'Depreciation is not equal to Acquisition';
        DerogatoryAmountErr: Label 'The derogatory amount is not correct';
        DepreciationAmountErr: Label 'The depreciation amount is not correct';
        BookValueAmountErr: Label 'The book-value amount is not correct';
        NoGLEntryErr: Label 'Number of G/L entries did not match the expected';
        NumberFAEntryErr: Label 'Number of FA entries did not match the expected';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

    [Test]
    [Scope('OnPrem')]
    procedure DerogatoryWithModifiedFAPostingDate()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        VerifyFAPostingDate(FANo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithFALine()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        InvoiceNo: Code[20];
    begin
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        InvoiceNo := CreateAndPostPurchaseInvoice(FANo, NormalDeprBookCode);

        VerifyPostedInvoice(InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFAJournalLine()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // Post FA Journal Lines with FA Posting Type: Depreciation and Derogatory and check FA Ledger Entries.
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        CreatePostFAJournalLines(FANo, NormalDeprBookCode);

        CheckFALedgerEntries(FANo, TaxDeprBookCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueAmountsInNormalBookWithDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        // Check Book Value and Derogatory amounts in Normal Book in case of Derogatory Entry
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        VerifyBookValueAmounts(FANo, NormalDeprBookCode, AcqCostAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BookValueAmountsInTaxBookWithDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        AcqCostAmount: Decimal;
        DerogatoryAmt: Decimal;
    begin
        // Check Book Value and Derogatory amounts in Tax Book in case of Derogatory Entry
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        CreatePostAcquisitionAndDerogatory(
          AcqCostAmount, DerogatoryAmt, FANo, NormalDeprBookCode);

        VerifyBookValueAmounts(FANo, TaxDeprBookCode, AcqCostAmount - DerogatoryAmt, -DerogatoryAmt);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationWithoutGLIntegration()
    var
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // Check derogatory line created in FA Journal after depreciation calculation without G/L integration
        // 1.Setup: : Create Fixed Asset, Depreciation Books, FA Depreciation Book With FA Posting Group
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        // 2.Exercise: create FA Journal Line and post it, calculate depreciation
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<1D>', WorkDate()), false);

        // 3.Verify FA Journal Line with FA Posting Type: Deregatory;
        VerifyFAJournalLine(FANo);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinalDepreciationWithNegativeDerogatory()
    var
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // Checks posting final Depreciation with Negative Deroagatory

        // 1. Setup
        FANo := CreateFAWithBooks(NormalDeprBookCode, TaxDeprBookCode, CalcDate('<CY-1Y+1D>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // 2. Excercise
        // Certain values to get further necessary Derogatory
        CreatePurchaseInvoiceAndPost(FANo, NormalDeprBookCode, 1, 1000, CalcDate('<CY-8M+1D>', WorkDate()));
        // Creates journal lines for 31/8/CurentYear and post
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate('<CY-4M>', WorkDate()), true);
        // Creates journal lines for 31/12/CurentYear and post
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), true);

        // 3. Verify
        VerifyFinalDepreciationWithNegativeDerogatory(FANo);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckDerogAmountReportProjectedValue()
    var
        FAJournalLine: Record "FA Journal Line";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        Amount: Decimal;
    begin
        // Check Depreciation and Derogatory amounts in Projected Value report.
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);

        UpdateIntegrationInBook(NormalDeprBookCode, false);

        Amount := LibraryRandom.RandDec(1000000, 1);

        // 2.Exercise: create FA Journal Line and post it, calculate depreciation
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost", Amount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        RunCalculateDepreciationReport(FANo, NormalDeprBookCode, CalcDate('<CY+3M>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // Projected Value
        RunFAProjValueDerogReport(NormalDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+365D>', WorkDate()), 0D, false);

        // 3.Verify derogatory value.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValues(FANo, CountExpectedAmount(FANo, TaxDeprBookCode, Amount));
    end;
#endif

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckBookValueForDepreciationWithDerogatory()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        EndingDate: Date;
    begin
        // Checks posting for Calculation of Depreciation and Derogatory for Negative Book Value.

        // 1. Setup : Create Fixed Asset, Depreciation Books, FA Depreciation Book With FA Posting Group and Post Acquisition.
        EndingDate := CalcDate('<CY>', WorkDate());
        FANo := CreateFAWithBooks(NormalDeprBookCode, TaxDeprBookCode, CalcDate('<-CY>', WorkDate()), EndingDate);
        UpdateFADepreciationBook(FADepreciationBook, FANo, TaxDeprBookCode, EndingDate);
        CreatePurchaseInvoiceAndPost(
          FANo, NormalDeprBookCode,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(1000, 2),
          CalcDate('<-CM>', FADepreciationBook."Depreciation Ending Date"));

        // 2. Excercise : Run Calculate Depreciation Report For different Posting Dates
        RunCalculateDepReportForDifferentPostingDates(FANo, NormalDeprBookCode, FADepreciationBook."Depreciation Ending Date");

        // 3. Verify : Verify the FA Eedger Entry for Acquisition, Depreciation and Derogatory.
        VerifyFinalDepreciationWithNegativeDerogatory(FANo);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO] Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via FA journal w/o G/L integration
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
        FADepreciationBook.CalcFields(Derogatory, Depreciation);
        ExpectedDerogatoryRatio := Amount / FADepreciationBook.Derogatory;
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
        FADepreciationBook.CalcFields(Derogatory, Depreciation);
        Assert.AreNearlyEqual(FADepreciationBook.Derogatory, (Amount + Amount2) / ExpectedDerogatoryRatio, 1, DerogatoryAmountErr);
        Assert.AreNearlyEqual(FADepreciationBook.Depreciation, (Amount + Amount2) / ExpectedDepreciationRatio, 1, DepreciationAmountErr);

        // [THEN] No G/L entries are created
        VerifyNoOfFALedgerEntries(0, NoGLEntryErr, FANo, true, -1);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO] Error when Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via
        // FA journal w/ G/L integration for Derogatory only
        // [GIVEN] A Fixed asset with a normal and tax depreciation book with G/L integration for derogatory only
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        UpdateIntegrationInBook(NormalDeprBookCode, false);
        DepreciationBook.Get(NormalDeprBookCode);
        DepreciationBook.Validate("G/L Integration - Derogatory", true);
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
        FADepreciationBook.CalcFields(Derogatory, Depreciation);

        // [WHEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] An error is thrown that you can't depreciate acquisition cost with only Derogatory G/L integration
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO] Additional acquisition cost for already depreciated FA with "Depr. Acquisition Cost" = Yes via FA journal w/ G/L integration
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
        FADepreciationBook.CalcFields(Derogatory, Depreciation);
        ExpectedDerogatoryRatio := Amount / FADepreciationBook.Derogatory;
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
        FADepreciationBook.CalcFields(Derogatory, Depreciation);
        Assert.AreNearlyEqual(FADepreciationBook.Derogatory, (Amount + Amount2) / ExpectedDerogatoryRatio, 1, DerogatoryAmountErr);
        Assert.AreNearlyEqual(FADepreciationBook.Depreciation, (Amount + Amount2) / ExpectedDepreciationRatio, 1, DepreciationAmountErr);

        // [THEN] 6 G/L entries are created
        VerifyNoOfFALedgerEntries(6, NoGLEntryErr, FANo, true, -1);
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntryRequestPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO] Cancel Additional acquisition cost's derogatory entry FA journal w/o G/L integration
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
        FADepreciationBook.CalcFields(Derogatory);
        ExpectedDerogatory := FADepreciationBook.Derogatory;

        // [GIVEN] An additional acquisition cost is posted via FA journal line with "Depr. acquisition Cost" = Yes
        CreateFAJournalLine(
          FAJournalLine, FANo, NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2));
        FAJournalLine.Validate("Depr. Acquisition Cost", true);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Derogatory amount is from both acquisitions
        VerifyNoOfFALedgerEntries(4, NumberFAEntryErr, FANo, false, FALedgerEntry."FA Posting Type"::Derogatory.AsInteger());
        FADepreciationBook.CalcFields(Derogatory);
        Assert.AreNotEqual(FADepreciationBook.Derogatory, ExpectedDerogatory, DerogatoryAmountErr);

        // [WHEN] The additional acquisition cost derogatory entry is cancelled
        CancelLastFALedgerEntry(NormalDeprBookCode, FALedgerEntry."FA Posting Type"::Derogatory.AsInteger());
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] The derogatory value is only for the first acquisition depreciation
        FADepreciationBook.CalcFields(Derogatory);
        Assert.AreEqual(ExpectedDerogatory, FADepreciationBook.Derogatory, DerogatoryAmountErr);
    end;

    [Test]
    [HandlerFunctions('ReverseFALedgerEntriesPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
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
        // [SCENARIO] Reverse an additional acquisition for FA with G/L integration
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
    [Scope('OnPrem')]
    procedure ReverseDerogEntryInitAcqCost()
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
        // [SCENARIO] Reverse the depreciation+derogatory for the first depreciation of a fixed asset
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

        // [WHEN] The depreciation is reversed from company book
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        FALedgerEntry.FindLast();
        ReverseFALedgerEntries(FALedgerEntry);

        // [WHEN] The derogatory is reversed from company book
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Derogatory);
        FALedgerEntry.FindLast();
        ReverseFALedgerEntries(FALedgerEntry);

        // [THEN] The FA ledger entries created by the report are all reversed
        VerifyAllFALedgEntriesReversed(LastFALedgerEntryNo);

        // [THEN] The book-value of Tax book is that as it was before the report was executed
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.CalcFields("Book Value");
        Assert.AreEqual(ExpectedBookValue, FADepreciationBook."Book Value", BookValueAmountErr);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectionBothBooksAreClosed()
    var
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NoOfYearsNormal: Decimal;
        NoOfYearsTax: Decimal;
        AcqCostAmount: Decimal;
    begin
        // [SCENARIO 135585] REP10886 "Fixed Asset - Projected Value (Derogatory)": both "Normal" (10 years) and "Tax" (8 years) books are closed at the end of projected "Normal" period (10 years).
        AcqCostAmount := 100000;
        NoOfYearsNormal := 10; // 10000 per year
        NoOfYearsTax := 8; // 12500 per year

        // [GIVEN] Setup both books: "Normal" - 10 years and "Tax"(Derogatory) - 8 years
        // [GIVEN] Post Acquisition Cost Amount = 100000
        // [GIVEN] Post first Depreciation = 360 Days
        // [GIVEN] Post second Depreciation = 90 Days
        PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(
          NormalDeprBookCode, TaxDeprBookCode, NoOfYearsNormal, NoOfYearsTax, AcqCostAmount);

        // [WHEN] Run "Fixed Asset - Projected Value (Derogatory)" report on "Normal" book with 10 years period.
        RunFAProjValueDerogReport(
          NormalDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+' + Format(NoOfYearsNormal) + 'Y>', WorkDate()), WorkDate(), true);

        // [THEN] Both books are projected to closed (Book Value = 0) at the end of projected period (10 years).
        VerifyFAProjectionBothBooksAreClosed();
    end;

    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectionBothBooksOneClosed()
    var
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NoOfYearsNormal: Decimal;
        NoOfYearsTax: Decimal;
        AcqCostAmount: Decimal;
    begin
        // [SCENARIO 135585] REP10886 "Fixed Asset - Projected Value (Derogatory)": "Normal" (10 years) book is open and "Tax" (8 years) book is closed at the end of projected Tax period (8 years).
        AcqCostAmount := 100000;
        NoOfYearsNormal := 10; // 10000 per year
        NoOfYearsTax := 8; // 12500 per year

        // [GIVEN] Setup both books: "Normal" - 10 years and "Tax"(Derogatory) - 8 years
        // [GIVEN] Post Acquisition Cost Amount = 100000
        // [GIVEN] Post first Depreciation = 360 Days
        // [GIVEN] Post second Depreciation = 90 Days
        PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(
          NormalDeprBookCode, TaxDeprBookCode, NoOfYearsNormal, NoOfYearsTax, AcqCostAmount);

        // [WHEN] Run "Fixed Asset - Projected Value (Derogatory)" report on "Normal" book with 8 years.
        RunFAProjValueDerogReport(
          NormalDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+' + Format(NoOfYearsTax) + 'Y>', WorkDate()), WorkDate(), true);

        // [THEN] "Tax" book is projected to closed (Book Value = 0), "Normal" book is open (Book Value <> 0) at the end of projected period (8 years).
        VerifyFAProjectionBothBooksOneClosed();
    end;

    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectionBothBooksInTheMidOfPeriod()
    var
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NoOfYearsNormal: Decimal;
        NoOfYearsTax: Decimal;
        AcqCostAmount: Decimal;
    begin
        // [SCENARIO 135585] REP10886 "Fixed Asset - Projected Value (Derogatory)": both "Normal" (10 years) and "Tax" (8 years) books are open in the middle of projected "Normal" period (5 years).
        AcqCostAmount := 100000;
        NoOfYearsNormal := 10; // 10000 per year
        NoOfYearsTax := 8; // 12500 per year

        // [GIVEN] Setup both books: "Normal" - 10 years and "Tax"(Derogatory) - 8 years
        // [GIVEN] Post Acquisition Cost Amount = 100000
        // [GIVEN] Post first Depreciation = 360 Days
        // [GIVEN] Post second Depreciation = 90 Days
        PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(
          NormalDeprBookCode, TaxDeprBookCode, NoOfYearsNormal, NoOfYearsTax, AcqCostAmount);

        // [WHEN] Run "Fixed Asset - Projected Value (Derogatory)" report on "Normal" book with 5 years period.
        RunFAProjValueDerogReport(
          NormalDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+' + Format(NoOfYearsTax - 3) + 'Y>', WorkDate()), WorkDate(), true);

        // [THEN] Both books are projected to open (Book Value <> 0) at the end of projected period (5 years).
        VerifyFAProjectionBothBooksInTheMidOfPeriod();
    end;

    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectionTaxBookIsClosed()
    var
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NoOfYearsNormal: Decimal;
        NoOfYearsTax: Decimal;
        AcqCostAmount: Decimal;
    begin
        // [SCENARIO 135585] REP10886 "Fixed Asset - Projected Value (Derogatory)": "Tax" (8 years) book is closed at the end of projected "Tax" period (8 years).
        AcqCostAmount := 100000;
        NoOfYearsNormal := 10; // 10000 per year
        NoOfYearsTax := 8; // 12500 per year

        // [GIVEN] Setup both books: "Normal" - 10 years and "Tax"(Derogatory) - 8 years
        // [GIVEN] Post Acquisition Cost Amount = 100000
        // [GIVEN] Post first Depreciation = 360 Days
        // [GIVEN] Post second Depreciation = 90 Days
        PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(
          NormalDeprBookCode, TaxDeprBookCode, NoOfYearsNormal, NoOfYearsTax, AcqCostAmount);

        // [WHEN] Run "Fixed Asset - Projected Value (Derogatory)" report on "Tax" book with 8 years period.
        RunFAProjValueDerogReport(
          TaxDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+' + Format(NoOfYearsTax) + 'Y>', WorkDate()), WorkDate(), true);

        // [THEN] "Tax" book is projected to closed (Book Value = 0) at the end of projected period (8 years).
        VerifyFAProjectionTaxBookIsClosed();
    end;

    [Test]
    [HandlerFunctions('FAProjValueDerogRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAProjectionTaxBookInTheMidOfPeriod()
    var
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
        NoOfYearsNormal: Decimal;
        NoOfYearsTax: Decimal;
        AcqCostAmount: Decimal;
    begin
        // [SCENARIO 135585] REP10886 "Fixed Asset - Projected Value (Derogatory)": "Tax" (8 years) book is open in the middle of projected "Tax" period (5 years).
        AcqCostAmount := 100000;
        NoOfYearsNormal := 10; // 10000 per year
        NoOfYearsTax := 8; // 12500 per year

        // [GIVEN] Setup both books: "Normal" - 10 years and "Tax"(Derogatory) - 8 years
        // [GIVEN] Post Acquisition Cost Amount = 100000
        // [GIVEN] Post first Depreciation = 360 Days
        // [GIVEN] Post second Depreciation = 90 Days
        PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(
          NormalDeprBookCode, TaxDeprBookCode, NoOfYearsNormal, NoOfYearsTax, AcqCostAmount);

        // [WHEN] Run "Fixed Asset - Projected Value (Derogatory)" report on "Tax" book with 5 years period.
        RunFAProjValueDerogReport(
          TaxDeprBookCode, CalcDate('<CY>', WorkDate()), CalcDate('<CY+' + Format(NoOfYearsTax - 3) + 'Y>', WorkDate()), WorkDate(), true);

        // [THEN] "Tax" book is projected to open (Book Value <> 0) at the end of projected period (5 years).
        VerifyFAProjectionTaxBookInTheMidOfPeriod();
    end;
#endif

    [Test]
    procedure FAPostingDateOnPurchaseOrderLinesUI()
    var
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
    begin
        // [FEATURE] [Fixed Asset] [UI]
        // [SCENARIO 404315] FA Posting Date field is visible on purchase order lines
        PurchaseOrderSubform.OpenEdit();
        Assert.IsTrue(PurchaseOrderSubform."FA Posting Date".Visible(), '');
        PurchaseOrderSubform.Close();
    end;

    [Test]
    procedure FAPostingDateOnPurchaseInvoiceLinesUI()
    var
        PurchInvoiceSubform: TestPage "Purch. Invoice Subform";
    begin
        // [FEATURE] [Fixed Asset] [UI]
        // [SCENARIO 404315] FA Posting Date field is visible on purchase invoice lines
        PurchInvoiceSubform.OpenEdit();
        Assert.IsTrue(PurchInvoiceSubform."FA Posting Date".Visible(), '');
        PurchInvoiceSubform.Close();
    end;

#if not CLEAN28
    local procedure PrepareBothFABooksWithCustomPeriodAndAcqCostAmount(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10]; NoOfYearsNormal: Decimal; NoOfYearsTax: Decimal; AcqCostAmount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Create two FA Depreciation Books with Period = [01-01-SS..31-12-EE], where SS - starting year, EE - ending year
        CreateNormalAndTaxDeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateFAPostingGroup(FixedAsset);
        CreateFADeprBookWithDates(
            FixedAsset."No.", NormalDeprBookCode, FixedAsset."FA Posting Group",
            CalcDate('<-CY>', WorkDate()),
            CalcDate('<' + Format(NoOfYearsNormal - 1) + 'Y+CY>', WorkDate()));
        CreateFADeprBookWithDates(
          FixedAsset."No.", TaxDeprBookCode, FixedAsset."FA Posting Group",
          CalcDate('<-CY>', WorkDate()),
          CalcDate('<' + Format(NoOfYearsTax - 1) + 'Y+CY>', WorkDate()));
        UpdateIntegrationInBook(NormalDeprBookCode, false);

        CreateFAJournalLine(
          FAJournalLine, FixedAsset."No.", NormalDeprBookCode, FAJournalLine."FA Posting Type"::"Acquisition Cost", AcqCostAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // Post first Depreciation = 360 Days
        RunCalculateDepreciationReport(FixedAsset."No.", NormalDeprBookCode, CalcDate('<CY>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // Post second Depreciation = 90 Days
        RunCalculateDepreciationReport(FixedAsset."No.", NormalDeprBookCode, CalcDate('<CY+3M>', WorkDate()), false);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;
#endif

    local procedure CreateFAWithNormalAndTaxFADeprBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateNormalAndTaxDeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateFAPostingGroup(FixedAsset);
        CreateFADeprBook(FixedAsset."No.", NormalDeprBookCode, FixedAsset."FA Posting Group");
        CreateFADeprBook(FixedAsset."No.", TaxDeprBookCode, FixedAsset."FA Posting Group");
        exit(FixedAsset."No.");
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
        DepreciationBook."Used with Derogatory Book" := TaxDeprBookCode;
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

    local procedure CreateNormalAndTaxDeprBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10])
    begin
        NormalDeprBookCode := CreateDeprBookModifyDerogCalc('');
        UpdateIntegrationInBook(NormalDeprBookCode, true);
        TaxDeprBookCode := CreateDeprBookModifyDerogCalc(NormalDeprBookCode);
    end;

    local procedure CreateDeprBookModifyDerogCalc(DerogDeprBookCode: Code[10]): Code[10]
    var
        DeprBook: Record "Depreciation Book";
    begin
        CreateAndSetupDeprBook(DeprBook);
        DeprBook.Validate("Use Same FA+G/L Posting Dates", false);
        DeprBook.Validate("Derogatory Calculation", DerogDeprBookCode);
        DeprBook.Modify(true);
        exit(DeprBook.Code);
    end;

    local procedure CreatePostAcquisitionAndDerogatory(var AcqCostAmount: Decimal; var DerogAmount: Decimal; FANo: Code[20]; DeprBookCode: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        AcqCostAmount := LibraryRandom.RandIntInRange(10000, 50000);
        DerogAmount := AcqCostAmount / 3;
        CreatePostGenJnlLine(
          GenJnlLine, WorkDate(), GenJnlLine."FA Posting Type"::"Acquisition Cost",
          FANo, DeprBookCode, AcqCostAmount);
        CreatePostGenJnlLine(
          GenJnlLine, CalcDerogatoryDate(), GenJnlLine."FA Posting Type"::Derogatory,
          FANo, DeprBookCode, -DerogAmount);
    end;

    local procedure CreatePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DeprBookCode: Code[10]; Amount: Decimal)
    begin
        CreateGenJournalLine(
          GenJnlLine, FAPostingDate, FAPostingType, FANo, DeprBookCode, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DeprBookCode: Code[10]; LineAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"Fixed Asset", FANo, LineAmount);
        GenJnlLine.Validate("FA Posting Type", FAPostingType);
        GenJnlLine.Validate("FA Posting Date", FAPostingDate);
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJnlLine.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; Amount: Decimal)
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        LibraryERM.CreateFAJournalLine(
          FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name,
          FAJournalLine."Document Type"::" ", FAPostingType,
          FANo, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFADeprBook(FANo: Code[20]; DeprBookCode: Code[10]; FAPostingGroup: Code[20])
    begin
        CreateFADeprBookWithDates(
          FANo, DeprBookCode, FAPostingGroup, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandIntInRange(2, 5)) + 'Y>', WorkDate()));
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

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFAPostingGroup(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        CreateFixedAsset(FixedAsset);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        UpdateFAPostingGroup(FAPostingGroup);
    end;

    local procedure CreateAndSetupDeprBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
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

    local procedure UpdateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    var
        FAPostingGroup2: Record "FA Posting Group";
        RecRef: RecordRef;
    begin
        FAPostingGroup2.Init();
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(FAPostingGroup2);

        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DeprBookCode: Code[10]; Value: Boolean)
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(DeprBookCode);
        DeprBook.Validate("G/L Integration - Acq. Cost", Value);
        DeprBook.Validate("G/L Integration - Depreciation", Value);
        DeprBook.Validate("G/L Integration - Derogatory", Value);
        DeprBook.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; TaxDeprBookCode: Code[10]; EndingDate: Date)
    begin
        FADepreciationBook.Get(FANo, TaxDeprBookCode);
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate(StrSubstNo('<-%1M>', LibraryRandom.RandIntInRange(5, 7)), EndingDate));
        FADepreciationBook.Modify(true);
    end;

    local procedure CalcDerogatoryDate(): Date
    begin
        exit(CalcDate('<1M>', WorkDate()));
    end;

#if not CLEAN28
    local procedure CountExpectedAmount(FANo: Code[20]; TaxDeprBook: Code[20]; Amt: Decimal): Decimal
    var
        FATaxDeprBook: Record "FA Depreciation Book";
    begin
        FATaxDeprBook.Get(FANo, TaxDeprBook);
        exit(Round(Amt * 270 / 360 / FATaxDeprBook."No. of Depreciation Years"));
    end;
#endif

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
    begin
        RunCalculateDepreciationReport(FixedAssetNo, DepreciationBookCode, PostingDate, BalanceAccount);

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.SetRange("Account No.", FixedAssetNo);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCalculateDepReportForDifferentPostingDates(FANo: Code[20]; NormalDeprBookCode: Code[10]; DepreciationEndingDate: Date)
    begin
        RunCalculateDepreciationReportAndPostJournalLines(FANo, NormalDeprBookCode, DepreciationEndingDate, true);
        RunCalculateDepreciationReportAndPostJournalLines(
          FANo, NormalDeprBookCode, CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), DepreciationEndingDate), true);
    end;

#if not CLEAN28
    local procedure RunFAProjValueDerogReport(DeprBookCode: Code[10]; StartingDate: Date; EndingDate: Date; PostedFrom: Date; PrintDetails: Boolean)
    begin
        LibraryVariableStorage.Enqueue(DeprBookCode);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PostedFrom);
        LibraryVariableStorage.Enqueue(PrintDetails);
        Commit();
        REPORT.Run(REPORT::"FA - Proj. Value (Derogatory)");
    end;
#endif

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

    local procedure VerifyBookValueAmounts(FANo: Code[20]; DeprBookCode: Code[10]; ExpectedBookValueAmt: Decimal; ExpectedDerogatoryAmt: Decimal)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        VerifyExcludeDerogatory(FANo, DeprBookCode);
        FADeprBook.Get(FANo, DeprBookCode);
        FADeprBook.CalcFields("Book Value");
        FADeprBook.CalcFields(Derogatory);
        FADeprBook.TestField("Book Value", ExpectedBookValueAmt);
        FADeprBook.TestField(Derogatory, ExpectedDerogatoryAmt);
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
              "Exclude Derogatory",
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

    local procedure VerifyPostedInvoice(DocumentNo: Code[20])
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(PurchaseInvoiceLine.IsEmpty, NoPurchInvoiceExistErr);
    end;

#if not CLEAN28
    local procedure VerifyValues(FANo: Code[20]; ExpectedAmount: Decimal)
    begin
        LibraryReportDataset.SetRange('FixedAssetNo', FANo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogAmount', -ExpectedAmount);
    end;
#endif

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

    local procedure VerifyAllFALedgEntriesReversed(LastFALedgerEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetFilter("Entry No.", '>%1', LastFALedgerEntryNo);
        FALedgerEntry.SetRange("Reversed by Entry No.", 0);
        FALedgerEntry.SetRange("Reversed Entry No.", 0);
        Assert.AreEqual(0, FALedgerEntry.Count, NumberFAEntryErr);
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

#if not CLEAN28
    local procedure VerifyFAProjValueRepPostedEntryAmounts(Amount: Decimal; BookValue: Decimal; DerogAmount: Decimal; DerogBookValue: Decimal; DerogDiffBokkValue: Decimal; MoveNextRow: Boolean)
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_FALedgerEntry', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('BookValue', BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('FALedgerEntryDerogAmount', DerogAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('FALedgerEntryDerogBookValue', DerogBookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('FALedgerEntryDerogDiffBookValue', DerogDiffBokkValue);
        if MoveNextRow then
            LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyFAProjValueRepProjectedAmounts(Amount: Decimal; BookValue: Decimal; DerogAmount: Decimal; DerogBookValue: Decimal; DerogDiffBokkValue: Decimal; MoveNextRow: Boolean)
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals('DeprAmount', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('EntryAmt1Custom1Amt', BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogAmount', DerogAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogBookValue', DerogBookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('DerogDiffBookValue', DerogDiffBokkValue);
        if MoveNextRow then
            LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyFAProjValueRepAssetAmounts(Amount: Decimal; BookValue: Decimal; DerogAmount: Decimal; DerogBookValue: Decimal; DerogDiffBokkValue: Decimal; MoveNextRow: Boolean)
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals('GroupAmounts_1', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalBookValue_1', BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('AssetDerogAmount', DerogAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('AssetDerogBookValue', DerogBookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('AssetDerogDiffBookValue', DerogDiffBokkValue);
        if MoveNextRow then
            LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyFAProjValueRepTotalAmounts(Amount: Decimal; BookValue: Decimal; DerogAmount: Decimal; DerogBookValue: Decimal; DerogDiffBokkValue: Decimal; MoveNextRow: Boolean)
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmounts1', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalBookValue2', BookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalDerogAmount', DerogAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalDerogBookValue', DerogBookValue);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalDerogDiffBookValue', DerogDiffBokkValue);
        if MoveNextRow then
            LibraryReportDataset.GetNextRow();
    end;

    local procedure VerifyFAProjectionBothBooksAreClosed()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);

        // Initial Acqusition Cost Amount = 100000
        VerifyFAProjValueRepPostedEntryAmounts(100000, 100000, 100000, 100000, 0, true);
        // First posted Depreciation = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-10000, 90000, -12500, 87500, -2500, true);
        // Second posted Depreciation = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 87500, -3125, 84375, -3125, true);

        // Projection1: 270 Days. All others = 360 Days
        VerifyFAProjValueRepProjectedAmounts(-7500, 80000, -9375, 75000, -5000, false);
        VerifyFAProjValueRepAssetAmounts(-7500, 80000, -9375, 75000, -5000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 70000, -12500, 62500, -7500, false);
        VerifyFAProjValueRepAssetAmounts(-17500, 70000, -21875, 62500, -7500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 60000, -12500, 50000, -10000, false);
        VerifyFAProjValueRepAssetAmounts(-27500, 60000, -34375, 50000, -10000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 50000, -12500, 37500, -12500, false);
        VerifyFAProjValueRepAssetAmounts(-37500, 50000, -46875, 37500, -12500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 40000, -12500, 25000, -15000, false);
        VerifyFAProjValueRepAssetAmounts(-47500, 40000, -59375, 25000, -15000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 30000, -12500, 12500, -17500, false);
        VerifyFAProjValueRepAssetAmounts(-57500, 30000, -71875, 12500, -17500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 20000, -12500, 0, -20000, false);
        VerifyFAProjValueRepAssetAmounts(-67500, 20000, -84375, 0, -20000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 10000, 0, 0, -10000, false);
        VerifyFAProjValueRepAssetAmounts(-77500, 10000, -84375, 0, -10000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 0, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-87500, 0, -84375, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(0, 0, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-87500, 0, -84375, 0, 0, true);

        VerifyFAProjValueRepTotalAmounts(-87500, 0, -84375, 0, 0, true);
    end;

    local procedure VerifyFAProjectionBothBooksOneClosed()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);

        // Initial Acqusition Cost Amount = 100000
        VerifyFAProjValueRepPostedEntryAmounts(100000, 100000, 100000, 100000, 0, true);
        // First posted Depreciation = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-10000, 90000, -12500, 87500, -2500, true);
        // Second posted Depreciation = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 87500, -3125, 84375, -3125, true);

        // Projection1: 270 Days. All others = 360 Days
        VerifyFAProjValueRepProjectedAmounts(-7500, 80000, -9375, 75000, -5000, false);
        VerifyFAProjValueRepAssetAmounts(-7500, 80000, -9375, 75000, -5000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 70000, -12500, 62500, -7500, false);
        VerifyFAProjValueRepAssetAmounts(-17500, 70000, -21875, 62500, -7500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 60000, -12500, 50000, -10000, false);
        VerifyFAProjValueRepAssetAmounts(-27500, 60000, -34375, 50000, -10000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 50000, -12500, 37500, -12500, false);
        VerifyFAProjValueRepAssetAmounts(-37500, 50000, -46875, 37500, -12500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 40000, -12500, 25000, -15000, false);
        VerifyFAProjValueRepAssetAmounts(-47500, 40000, -59375, 25000, -15000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 30000, -12500, 12500, -17500, false);
        VerifyFAProjValueRepAssetAmounts(-57500, 30000, -71875, 12500, -17500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 20000, -12500, 0, -20000, false);
        VerifyFAProjValueRepAssetAmounts(-67500, 20000, -84375, 0, -20000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 10000, 0, 0, -10000, false);
        VerifyFAProjValueRepAssetAmounts(-77500, 10000, -84375, 0, -10000, true);

        VerifyFAProjValueRepTotalAmounts(-77500, 10000, -84375, 0, -10000, true);
    end;

    local procedure VerifyFAProjectionBothBooksInTheMidOfPeriod()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);

        // Initial Acqusition Cost Amount = 100000
        VerifyFAProjValueRepPostedEntryAmounts(100000, 100000, 100000, 100000, 0, true);
        // First posted Depreciation = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-10000, 90000, -12500, 87500, -2500, true);
        // Second posted Depreciation = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 87500, -3125, 84375, -3125, true);

        // Projection1: 270 Days. All others = 360 Days
        VerifyFAProjValueRepProjectedAmounts(-7500, 80000, -9375, 75000, -5000, false);
        VerifyFAProjValueRepAssetAmounts(-7500, 80000, -9375, 75000, -5000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 70000, -12500, 62500, -7500, false);
        VerifyFAProjValueRepAssetAmounts(-17500, 70000, -21875, 62500, -7500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 60000, -12500, 50000, -10000, false);
        VerifyFAProjValueRepAssetAmounts(-27500, 60000, -34375, 50000, -10000, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 50000, -12500, 37500, -12500, false);
        VerifyFAProjValueRepAssetAmounts(-37500, 50000, -46875, 37500, -12500, true);

        VerifyFAProjValueRepProjectedAmounts(-10000, 40000, -12500, 25000, -15000, false);
        VerifyFAProjValueRepAssetAmounts(-47500, 40000, -59375, 25000, -15000, true);

        VerifyFAProjValueRepTotalAmounts(-47500, 40000, -59375, 25000, -15000, true);
    end;

    local procedure VerifyFAProjectionTaxBookIsClosed()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);

        // Initial Acqusition Cost Amount = 100000
        VerifyFAProjValueRepPostedEntryAmounts(100000, 100000, 0, 0, 0, true);
        // First posted Depreciation = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-10000, 90000, 0, 0, 0, true);
        // First posted Derogatory = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 87500, 0, 0, 0, true);
        // Second posted Depreciation = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 85000, 0, 0, 0, true);
        // Second posted Derogatory = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-625, 84375, 0, 0, 0, true);

        // Projection1: 270 Days. All others = 360 Days
        VerifyFAProjValueRepProjectedAmounts(-9375, 75000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-9375, 75000, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 62500, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-21875, 62500, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 50000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-34375, 50000, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 37500, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-46875, 37500, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 25000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-59375, 25000, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 12500, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-71875, 12500, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 0, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-84375, 0, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(0, 0, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-84375, 0, 0, 0, 0, true);

        VerifyFAProjValueRepTotalAmounts(-84375, 0, 0, 0, 0, true);
    end;

    local procedure VerifyFAProjectionTaxBookInTheMidOfPeriod()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);

        // Initial Acqusition Cost Amount = 100000
        VerifyFAProjValueRepPostedEntryAmounts(100000, 100000, 0, 0, 0, true);
        // First posted Depreciation = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-10000, 90000, 0, 0, 0, true);
        // First posted Derogatory = 360 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 87500, 0, 0, 0, true);
        // Second posted Depreciation = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-2500, 85000, 0, 0, 0, true);
        // Second posted Derogatory = 90 Days
        VerifyFAProjValueRepPostedEntryAmounts(-625, 84375, 0, 0, 0, true);

        // Projection1: 270 Days. All others = 360 Days
        VerifyFAProjValueRepProjectedAmounts(-9375, 75000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-9375, 75000, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 62500, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-21875, 62500, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 50000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-34375, 50000, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 37500, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-46875, 37500, 0, 0, 0, true);

        VerifyFAProjValueRepProjectedAmounts(-12500, 25000, 0, 0, 0, false);
        VerifyFAProjValueRepAssetAmounts(-59375, 25000, 0, 0, 0, true);

        VerifyFAProjValueRepTotalAmounts(-59375, 25000, 0, 0, 0, true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAProjValueDerogRPH(var FAProjValueDerogatory: TestRequestPage "FA - Proj. Value (Derogatory)")
    begin
        FAProjValueDerogatory.DepreciationBook.SetValue(LibraryVariableStorage.DequeueText());
        FAProjValueDerogatory.FirstDeprDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAProjValueDerogatory.LastDeprDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAProjValueDerogatory.IncludePostedFrom.SetValue(LibraryVariableStorage.DequeueDate());
        FAProjValueDerogatory.PrintPerFixedAsset.SetValue(LibraryVariableStorage.DequeueBoolean());
        FAProjValueDerogatory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

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

    local procedure ReverseFALedgerEntries(var FALedgerEntry: Record "FA Ledger Entry")
    var
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        FALedgerEntries.OpenEdit();
        FALedgerEntries.FILTER.SetFilter("Entry No.", Format(FALedgerEntry."Entry No."));
        FALedgerEntries.ReverseTransaction.Invoke();
        FALedgerEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CancelFALedgerEntryRequestPageHandler(var CancelFAEntries: TestRequestPage "Cancel FA Entries")
    begin
        CancelFAEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseFALedgerEntriesPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Message, CompletionStatsTok) then
            Reply := false
        else
            Reply := true;
    end;
}

