codeunit 134149 "ERM Fixed Assets - Local"
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
        LibraryUtility: Codeunit "Library - Utility";
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
        DerogatoryAcqErr: Label 'The derogatory book did not receive the acquisition cost from the purchase invoice.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

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

        // [THEN] The tax book received the same acquisition cost as the normal book
        FANormalDeprBook.Get(FANo, NormalDeprBookCode);
        FANormalDeprBook.CalcFields("Acquisition Cost");
        FATaxDeprBook.Get(FANo, TaxDeprBookCode);
        FATaxDeprBook.CalcFields("Acquisition Cost");
        Assert.AreNotEqual(0, FATaxDeprBook."Acquisition Cost", DerogatoryAcqErr);
        Assert.AreEqual(FANormalDeprBook."Acquisition Cost", FATaxDeprBook."Acquisition Cost", DerogatoryAcqErr);
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
        // The demo-data FA posting group may not have derogatory accounts set; set them so derogatory postings succeed.
        FAPostingGroup.Validate("Derogatory Acc.", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Account (Decrease)", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Expense Acc.", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DeprBookCode: Code[10]; Value: Boolean)
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(DeprBookCode);
        DeprBook.Validate("G/L Integration - Acq. Cost", Value);
        DeprBook.Validate("G/L Integration - Depreciation", Value);
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
