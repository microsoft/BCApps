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

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
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
        NumberMaintenanceEntryErr: Label 'Number of maintenance entries did not match the expected';
        DerogatoryAcqErr: Label 'The derogatory book did not receive the acquisition cost from the purchase invoice.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        MissingDerogatoryCounterpartTok: Label 'The derogatory counterpart for source entry';
        MultipleDerogatoryCounterpartsTok: Label 'More than one derogatory counterpart references source entry';

    [Test]
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
        VerifyLinkedCounterparts(FANo, NormalDeprBookCode, TaxDeprBookCode);
    end;

    [Test]
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

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
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
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
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
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
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
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntryRequestPageHandler,MessageHandler,DepreciationCalcConfirmHandler')]
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

    [Test]
    procedure AcquisitionViaPurchInvoiceMirrorsToDerogatoryBook()
    var
        FANormalDeprBook: Record "FA Depreciation Book";
        FATaxDeprBook: Record "FA Depreciation Book";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617319] An acquisition cost posted from a purchase invoice mirrors to the derogatory (tax) book

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
    procedure AcquisitionSalvageCompanionIsLinked()
    var
        FAJournalLine: Record "FA Journal Line";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617320] An automatic salvage companion is explicitly linked to its source companion

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
        SourceSalvageFALedgerEntry.FindFirst();
        SourceSalvageFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        CounterpartSalvageFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartSalvageFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        CounterpartSalvageFALedgerEntry.SetRange("FA Posting Type", CounterpartSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
    procedure GeneralJournalSalvageCompanionIsLinked()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceSalvageFALedgerEntry: Record "FA Ledger Entry";
        CounterpartSalvageFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617322] A general-journal salvage companion is explicitly linked to its source companion

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
        SourceSalvageFALedgerEntry.FindFirst();
        CounterpartSalvageFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartSalvageFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        CounterpartSalvageFALedgerEntry.SetRange("FA Posting Type", CounterpartSalvageFALedgerEntry."FA Posting Type"::"Salvage Value");
        CounterpartSalvageFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, CounterpartSalvageFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
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
        // [SCENARIO 617321] Automatic-only depreciation still produces linked tax-book companions

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
    end;

    [Test]
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
        // [SCENARIO 617323] A changed relationship does not redirect reversal of linked FA history
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        NewTaxDeprBookCode := ChangeDerogatoryRelationship(FANo, NormalDeprBookCode, TaxDeprBookCode);

        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", NewTaxDeprBookCode);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", ReversingFALedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
    procedure MaintenanceReversalUsesPersistedLinkAfterRelationshipRemoval()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617324] Removed setup does not suppress reversal of linked maintenance history
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ClearDerogatoryRelationship(TaxDeprBookCode);

        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    procedure MissingRequiredFACounterpartErrors()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617325] An eligible FA source cannot be reversed without its linked counterpart
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartFALedgerEntry.Delete();

        asserterror ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        Assert.ExpectedError(MissingDerogatoryCounterpartTok);
    end;

    [Test]
    procedure MissingRequiredMaintenanceCounterpartErrors()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617326] An eligible maintenance source cannot be reversed without its linked counterpart
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartMaintenanceLedgerEntry.Delete();

        asserterror ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        Assert.ExpectedError(MissingDerogatoryCounterpartTok);
    end;

    [Test]
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
        // [SCENARIO 617338] FA source reversal is rolled back when its linked counterpart is already reversed
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseFAEntry(CounterpartFALedgerEntry, CounterpartReversalFALedgerEntry);
        FALedgerEntryCount := FALedgerEntry.Count();
        Commit();

        asserterror ReverseFAEntry(SourceFALedgerEntry, SourceReversalFALedgerEntry);

        Assert.ExpectedTestFieldError(CounterpartFALedgerEntry.FieldCaption("Reversed by Entry No."), Format(0));
        Assert.AreEqual(FALedgerEntryCount, FALedgerEntry.Count(), NumberFAEntryErr);
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        SourceFALedgerEntry.TestField(Reversed, false);
        SourceFALedgerEntry.TestField("Reversed by Entry No.", 0);
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.TestField(Reversed, true);
        CounterpartFALedgerEntry.TestField("Reversed by Entry No.", CounterpartReversalFALedgerEntry."Entry No.");
        FALedgerEntry.SetRange("Reversed Entry No.", SourceFALedgerEntry."Entry No.");
        Assert.AreEqual(0, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    [Test]
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
        // [SCENARIO 617339] Maintenance source reversal is rolled back when its linked counterpart is already reversed
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseMaintenanceEntry(
            CounterpartMaintenanceLedgerEntry, CounterpartReversalMaintenanceLedgerEntry);
        MaintenanceLedgerEntryCount := MaintenanceLedgerEntry.Count();
        Commit();

        asserterror ReverseMaintenanceEntry(
            SourceMaintenanceLedgerEntry, SourceReversalMaintenanceLedgerEntry);

        Assert.ExpectedTestFieldError(
            CounterpartMaintenanceLedgerEntry.FieldCaption("Reversed by Entry No."), Format(0));
        Assert.AreEqual(
            MaintenanceLedgerEntryCount, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        SourceMaintenanceLedgerEntry.TestField(Reversed, false);
        SourceMaintenanceLedgerEntry.TestField("Reversed by Entry No.", 0);
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.TestField(Reversed, true);
        CounterpartMaintenanceLedgerEntry.TestField(
            "Reversed by Entry No.", CounterpartReversalMaintenanceLedgerEntry."Entry No.");
        MaintenanceLedgerEntry.SetRange("Reversed Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(0, MaintenanceLedgerEntry.Count(), NumberMaintenanceEntryErr);
    end;

    [Test]
    procedure MultipleFACounterpartsAcrossBooksError()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617327] FA reversal rejects multiple global persisted links
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        InsertDuplicateFALinkInAnotherBook(CounterpartFALedgerEntry);

        asserterror ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        Assert.ExpectedError(MultipleDerogatoryCounterpartsTok);
    end;

    [Test]
    procedure MultipleMaintenanceCounterpartsAcrossBooksError()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617328] Maintenance reversal rejects multiple global persisted links
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        InsertDuplicateMaintenanceLinkInAnotherBook(CounterpartMaintenanceLedgerEntry);

        asserterror ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        Assert.ExpectedError(MultipleDerogatoryCounterpartsTok);
    end;

    [Test]
    procedure UnlinkedCurrentlyIneligibleFAReversesNormally()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617329] A currently ineligible unlinked FA source receives only its normal reversal
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartFALedgerEntry.Delete();
        ClearDerogatoryRelationship(TaxDeprBookCode);

        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        SourceFALedgerEntry.TestField(Reversed, true);
        ReversingFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", ReversingFALedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
    end;

    [Test]
    procedure UnlinkedCurrentlyIneligibleMaintenanceReversesNormally()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617330] A currently ineligible unlinked maintenance source receives only its normal reversal
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        CounterpartMaintenanceLedgerEntry.Delete();
        ClearDerogatoryRelationship(TaxDeprBookCode);

        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        SourceMaintenanceLedgerEntry.TestField(Reversed, true);
        ReversingMaintenanceLedgerEntry.TestField("Derogatory Source Entry No.", 0);
        CounterpartMaintenanceLedgerEntry.SetRange(
            "Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry."Entry No.");
        Assert.AreEqual(0, CounterpartMaintenanceLedgerEntry.Count, NumberMaintenanceEntryErr);
    end;

    [Test]
    procedure MarkedLegacyFAUsesHeuristicFallback()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617331] Only a marked legacy FA source can use heuristic reversal
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkFAEntriesAsAmbiguousLegacy(SourceFALedgerEntry, CounterpartFALedgerEntry);

        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    procedure MarkedLegacyMaintenanceUsesHeuristicFallback()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617332] Only a marked legacy maintenance source can use heuristic reversal
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkMaintenanceEntriesAsAmbiguousLegacy(SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry);

        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    procedure MarkedLegacyFAUsesHeuristicAfterRelationshipRemoval()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617336] Removed setup does not suppress marked legacy FA fallback
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkFAEntriesAsAmbiguousLegacy(SourceFALedgerEntry, CounterpartFALedgerEntry);
        ClearDerogatoryRelationship(TaxDeprBookCode);

        ReverseFAEntry(SourceFALedgerEntry, ReversingFALedgerEntry);

        VerifyLinkedFAReversal(
            SourceFALedgerEntry, CounterpartFALedgerEntry, ReversingFALedgerEntry, TaxDeprBookCode);
    end;

    [Test]
    procedure MarkedLegacyMaintenanceUsesHeuristicAfterRelationshipChange()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617337] Changed setup does not redirect marked legacy maintenance fallback
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        MarkMaintenanceEntriesAsAmbiguousLegacy(SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry);
        ChangeDerogatoryRelationship(FANo, NormalDeprBookCode, TaxDeprBookCode);

        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        VerifyLinkedMaintenanceReversal(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            ReversingMaintenanceLedgerEntry, TaxDeprBookCode);
    end;

    [Test]
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
        // [SCENARIO 617333] Reversal of an FA reversal keeps both reversal chains aligned
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseFAEntry(SourceFALedgerEntry, FirstReversingFALedgerEntry);
        FindLinkedFAEntry(
            FirstCounterpartReversal, FirstReversingFALedgerEntry."Entry No.", TaxDeprBookCode);

        ReverseFAEntry(FirstReversingFALedgerEntry, SecondReversingFALedgerEntry);

        FindLinkedFAEntry(
            SecondCounterpartReversal, SecondReversingFALedgerEntry."Entry No.", TaxDeprBookCode);
        SourceFALedgerEntry.Get(SourceFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        FirstReversingFALedgerEntry.Get(FirstReversingFALedgerEntry."Entry No.");
        FirstCounterpartReversal.Get(FirstCounterpartReversal."Entry No.");
        SourceFALedgerEntry.TestField(Reversed, false);
        CounterpartFALedgerEntry.TestField(Reversed, false);
        FirstReversingFALedgerEntry.TestField("Reversed by Entry No.", SecondReversingFALedgerEntry."Entry No.");
        FirstCounterpartReversal.TestField("Reversed by Entry No.", SecondCounterpartReversal."Entry No.");
    end;

    [Test]
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
        // [SCENARIO 617334] Reversal of a maintenance reversal keeps both reversal chains aligned
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ReverseMaintenanceEntry(SourceMaintenanceLedgerEntry, FirstReversingMaintenanceLedgerEntry);
        FindLinkedMaintenanceEntry(
            FirstCounterpartReversal, FirstReversingMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);

        ReverseMaintenanceEntry(FirstReversingMaintenanceLedgerEntry, SecondReversingMaintenanceLedgerEntry);

        FindLinkedMaintenanceEntry(
            SecondCounterpartReversal, SecondReversingMaintenanceLedgerEntry."Entry No.", TaxDeprBookCode);
        SourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        FirstReversingMaintenanceLedgerEntry.Get(FirstReversingMaintenanceLedgerEntry."Entry No.");
        FirstCounterpartReversal.Get(FirstCounterpartReversal."Entry No.");
        SourceMaintenanceLedgerEntry.TestField(Reversed, false);
        CounterpartMaintenanceLedgerEntry.TestField(Reversed, false);
        FirstReversingMaintenanceLedgerEntry.TestField(
            "Reversed by Entry No.", SecondReversingMaintenanceLedgerEntry."Entry No.");
        FirstCounterpartReversal.TestField("Reversed by Entry No.", SecondCounterpartReversal."Entry No.");
    end;

    [Test]
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
        // [SCENARIO 617335] Automatic source and tax-book salvage companions reverse through their link
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
        ReverseFAEntry(SourceAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        CounterpartSalvageFALedgerEntry.Get(CounterpartSalvageFALedgerEntry."Entry No.");
        SourceSalvageFALedgerEntry.TestField(Reversed, true);
        CounterpartSalvageFALedgerEntry.TestField(Reversed, true);
        ReversingSalvageFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        ReversingSalvageFALedgerEntry.SetRange("Reversed Entry No.", SourceSalvageFALedgerEntry."Entry No.");
        ReversingSalvageFALedgerEntry.FindFirst();
        FindLinkedFAEntry(
            CounterpartSalvageReversal, ReversingSalvageFALedgerEntry."Entry No.", TaxDeprBookCode);
    end;

    [Test]
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
        // [SCENARIO 617340] Direct tax-book acquisition reversal reverses its automatic salvage companion once
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

        ReverseFAEntry(CounterpartAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        CounterpartAcquisitionFALedgerEntry.Get(CounterpartAcquisitionFALedgerEntry."Entry No.");
        CounterpartSalvageFALedgerEntry.Get(CounterpartSalvageFALedgerEntry."Entry No.");
        CounterpartAcquisitionFALedgerEntry.TestField(
            "Reversed by Entry No.", ReversingAcquisitionFALedgerEntry."Entry No.");
        CounterpartSalvageFALedgerEntry.TestField(Reversed, true);
        SourceAcquisitionFALedgerEntry.Get(SourceAcquisitionFALedgerEntry."Entry No.");
        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        SourceAcquisitionFALedgerEntry.TestField(Reversed, false);
        SourceSalvageFALedgerEntry.TestField(Reversed, false);
        Assert.AreEqual(FALedgerEntryCount + 2, FALedgerEntry.Count(), NumberFAEntryErr);
        FALedgerEntry.SetRange("Reversed Entry No.", CounterpartSalvageFALedgerEntry."Entry No.");
        Assert.AreEqual(1, FALedgerEntry.Count(), NumberFAEntryErr);
    end;

    [Test]
    procedure DirectFACounterpartReversalPreservesRoleAfterSetupChange()
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        ReversingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617341] Direct FA counterpart reversal keeps its persisted role after the book becomes a source
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedFAAcquisition(
            SourceFALedgerEntry, CounterpartFALedgerEntry, FANo, NormalDeprBookCode, TaxDeprBookCode);
        ConfigureBookAsDerogatorySource(FANo, TaxDeprBookCode);

        ReverseFAEntry(CounterpartFALedgerEntry, ReversingFALedgerEntry);

        CounterpartFALedgerEntry.Get(CounterpartFALedgerEntry."Entry No.");
        CounterpartFALedgerEntry.TestField("Reversed by Entry No.", ReversingFALedgerEntry."Entry No.");
        ReversingFALedgerEntry.TestField(
            "Derogatory Source Entry No.", CounterpartFALedgerEntry."Derogatory Source Entry No.");
    end;

    [Test]
    procedure DirectMaintenanceCounterpartReversalPreservesRoleAfterSetupChange()
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617342] Direct maintenance counterpart reversal keeps its persisted role after the book becomes a source
        FANo := CreateFAWithNormalAndTaxFADeprBooks(NormalDeprBookCode, TaxDeprBookCode);
        PostLinkedMaintenance(
            SourceMaintenanceLedgerEntry, CounterpartMaintenanceLedgerEntry,
            FANo, NormalDeprBookCode, TaxDeprBookCode);
        ConfigureBookAsDerogatorySource(FANo, TaxDeprBookCode);

        ReverseMaintenanceEntry(CounterpartMaintenanceLedgerEntry, ReversingMaintenanceLedgerEntry);

        CounterpartMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Entry No.");
        CounterpartMaintenanceLedgerEntry.TestField(
            "Reversed by Entry No.", ReversingMaintenanceLedgerEntry."Entry No.");
        ReversingMaintenanceLedgerEntry.TestField(
            "Derogatory Source Entry No.", CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No.");
    end;

    [Test]
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
        // [SCENARIO 617343] Shared posting metadata does not make an acquisition reverse another salvage companion
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

        ReverseFAEntry(FirstAcquisitionFALedgerEntry, ReversingAcquisitionFALedgerEntry);

        FirstSalvageFALedgerEntry.Get(FirstSalvageFALedgerEntry."Entry No.");
        FirstSalvageFALedgerEntry.TestField(Reversed, true);
        SecondAcquisitionFALedgerEntry.Get(SecondAcquisitionFALedgerEntry."Entry No.");
        SecondAcquisitionFALedgerEntry.TestField(Reversed, false);
        SecondSalvageFALedgerEntry.Get(SecondSalvageFALedgerEntry."Entry No.");
        SecondSalvageFALedgerEntry.TestField(Reversed, false);
    end;

    [Test]
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
        // [SCENARIO 617344] Reversal of an acquisition reversal restores its automatic salvage companion
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

        ReverseFAEntry(FirstAcquisitionReversal, SecondAcquisitionReversal);

        SourceAcquisitionFALedgerEntry.Get(SourceAcquisitionFALedgerEntry."Entry No.");
        SourceAcquisitionFALedgerEntry.TestField(Reversed, false);
        SourceSalvageFALedgerEntry.Get(SourceSalvageFALedgerEntry."Entry No.");
        SourceSalvageFALedgerEntry.TestField(Reversed, false);
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
    end;

    local procedure ReverseFAEntry(FALedgerEntry: Record "FA Ledger Entry"; var ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        FAInsertLedgerEntry.InsertReverseEntry(0, 1, FALedgerEntry."Entry No.", NewEntryNo, 0);
        ReversingFALedgerEntry.Get(NewEntryNo);
    end;

    local procedure ReverseMaintenanceEntry(MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        NewEntryNo: Integer;
    begin
        FAInsertLedgerEntry.InsertReverseEntry(0, 2, MaintenanceLedgerEntry."Entry No.", NewEntryNo, 0);
        ReversingMaintenanceLedgerEntry.Get(NewEntryNo);
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
        FALedgerEntry.FindFirst();
    end;

    local procedure FindLinkedMaintenanceEntry(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceEntryNo: Integer; DepreciationBookCode: Code[10])
    begin
        MaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", SourceEntryNo);
        MaintenanceLedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        MaintenanceLedgerEntry.FindFirst();
    end;

    local procedure ClearDerogatoryRelationship(TaxDeprBookCode: Code[10])
    var
        TaxDepreciationBook: Record "Depreciation Book";
    begin
        TaxDepreciationBook.Get(TaxDeprBookCode);
        TaxDepreciationBook.Validate("Derogatory Calc.", '');
        TaxDepreciationBook.Modify(true);
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
        DeprBook.Validate("Derogatory Calc.", DerogDeprBookCode);
        DeprBook.Modify(true);
        exit(DeprBook.Code);
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
        FADeprBook.CalcFields("Derogatory Amount");
        FADeprBook.TestField("Book Value", ExpectedBookValueAmt);
        FADeprBook.TestField("Derogatory Amount", ExpectedDerogatoryAmt);
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

    local procedure VerifyPostedInvoice(DocumentNo: Code[20])
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(PurchaseInvoiceLine.IsEmpty, NoPurchInvoiceExistErr);
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

    local procedure VerifyLinkedCounterparts(FANo: Code[20]; NormalDepreciationBookCode: Code[10]; TaxDepreciationBookCode: Code[10])
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
    begin
        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", NormalDepreciationBookCode);
        SourceFALedgerEntry.SetRange("Automatic Entry", false);
        SourceFALedgerEntry.FindSet();
        repeat
            SourceFALedgerEntry.TestField("Derogatory Source Entry No.", 0);
            CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
            CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDepreciationBookCode);
            Assert.AreEqual(1, CounterpartFALedgerEntry.Count, NumberFAEntryErr);
        until SourceFALedgerEntry.Next() = 0;
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
}
