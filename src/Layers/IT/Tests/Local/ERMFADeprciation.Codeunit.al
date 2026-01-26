codeunit 144143 "ERM FA Deprciation"
{
    // // [FEATURE] [Fixed Asset]
    //  1. Test to verify values on the Report - Depreciation Book after Calculate Depreciation.
    //  2. Test to verify values on the Report - Depreciation Book when Disposal Entry Posted after Reclassification.
    //  3. Test to verify values on the Report - Depreciation Book after Reclassification.
    //  4. Test to verify Total Depreciation Percentage on the Depreciation Table Card (5659).
    //  5. Test to verify Amount on FA Ledger Entry when Purchase Invoice posted with Multiple Fixed Assets with Depreciation Code.
    //  6. Test to verify Amount on Vendor Ledger Entry when VAT Transaction Report Amount is specified.
    //  7. Test to verify Amount on Customer Ledger Entry when VAT Transaction Report Amount is specified.
    //  8. Test to verify totaling (FA Class/FA Subclass) values on the Report - Single FA Class.
    //  9. Test to verify totaling (FA Class/FA Subclass) values on the Report - Multiple Class/Multiple Subclasses.
    //  10. Test to verify totaling (FA Class/FA Subclass) values on the Report - Multiple Classes/Single Subclass.
    //  11. Test to verify totaling (FA Class/FA Subclass) values on the Report - Single Class/Multipe Subclasses.
    // 
    // Covers Test Cases for WI - 345437
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // DepreciationBookAfterCalculateDepreciation                                                   174177,205177,299640,288740,309672
    // DepreciationBookAfterDisposal                                                                153330,153332,205180
    // DepreciationBookAfterReclassify                                                              235871,235872
    // TotalDepreciationPercentageOnDepreciationTableCard                                           154973
    // PurchaseInvoiceLinesWithMultipleFixedAssets                                                  258799
    // PurchaseInvoiceWithVATTransactionReportAmount, SalesInvoiceWithVATTransactionReportAmount    302764
    // DepreciationBookSingleClassTotal, DepreciationBookMultiClassMultiSubclass                    355627
    // DepreciationBookMultiClassSingleSublclass, DepreciationBookSingleClassMultipleSubclass       355627

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CompletionStatsTok: Label 'The depreciation has been calculated.';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationBookRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookAfterCalculateDepreciation()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
    begin
        // Test to verify values on the Report - Depreciation Book after Calculate Depreciation.

        // Setup: Create Depreciation Table with Multiple Lines and FA Depreciation Books with Depreciation Book Code.
        Initialize();
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, WorkDate());

        // Post Purchase Invoice with Fixed Assets.
        CreateAndPostPurchaseInvoiceWithMultipleLines(FADepreciationBook);
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", CalcDate('<CY>', WorkDate()), '');  // Enqueue values in CalculateDepreciationRequestPageHandler.
        PostGenJournalLineAfterCalculateDepreciation(true);

        // Exercise.
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[2]."FA No.", '', true, CalcDate('<1Y>', WorkDate()));

        // Verify: Verify values on Report - Depreciation Book.
        FADepreciationBook[2].CalcFields("Book Value");
        VerifyValuesOnDepreciationBookReport(
          true,
          'Fixed_Asset_No_', 'DeprBookCode', 'TotalEndingAmounts_1_', 'BookValueAtEndingDate', FADepreciationBook[2]."FA No.",
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[2]."Book Value", FADepreciationBook[2]."Book Value");
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookAfterDisposal()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        Amount: Decimal;
    begin
        // Test to verify values on the Report - Depreciation Book when Disposal Entry Posted after Reclassification.

        // Setup: Create Depreciation Table with Multiple Lines and FA Depreciation Books with Depreciation Book Code.
        Initialize();
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // Post General Journal with FA Posting Type Acquisition Cost.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostDisposalAfterReclassification(FADepreciationBook, Amount, Amount, LibraryRandom.RandDec(100, 2));

        // Exercise.
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code",
          FADepreciationBook[1]."FA No.", FADepreciationBook[2]."FA No.", true, CalcDate('<1Y>', WorkDate()));

        // Verify: Verify values on Report - Depreciation Book.
        VerifyValuesOnDepreciationBookReport(
          true, 'StartAmounts_1_', 'NetChangeAmounts_1_', 'NetChangeAmounts_Type__Control1130086', 'TotalInventoryYear_1_',
          Amount, 0, 0, Amount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookAfterPartialDisposalPrimaryFA()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        OriginalAmount: Decimal;
        ReclassAmount: Decimal;
        DisposalAmount: Decimal;
    begin
        // [FEATURE] [FA Disposal]
        // [SCENARIO 372227] Local rep 12119 "Depreciation Book" shows original Acqisition Cost amount and partial Disposal Amount for main Fixed Asset
        Initialize();
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [GIVEN] Create Acquisision Cost on "FA1" with Amount = 1000
        // [GIVEN] Reclassificate "FA1" to "FA2" with Amount = 300
        // [GIVEN] Create and post Disposal on "FA1" with Amount = 700
        OriginalAmount := LibraryRandom.RandDec(1000, 2);
        ReclassAmount := Round(OriginalAmount / 3);
        DisposalAmount := OriginalAmount - ReclassAmount;
        CreateAndPostDisposalAfterReclassification(FADepreciationBook, OriginalAmount, ReclassAmount, DisposalAmount);

        // [WHEN] Run "Depreciation Book" report for "FA1"
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", '', true, CalcDate('<2Y>', WorkDate()));

        // [THEN] "FA1" Acquisition Cost amount = 1000
        // [THEN] "FA1" Disposal amount = 700
        // [THEN] "FA1" Book Value amount = 300
        VerifyFAAfterPartialDisposal(OriginalAmount, -DisposalAmount, OriginalAmount - DisposalAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookAfterPartialDisposalSecondaryFA()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        OriginalAmount: Decimal;
        ReclassAmount: Decimal;
        DisposalAmount: Decimal;
    begin
        // [FEATURE] [FA Disposal]
        // [SCENARIO 372227] Local rep 12119 "Depreciation Book" shows zero amounts for Reclassified Fixed Asset
        Initialize();
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [GIVEN] Create Acquisision Cost on "FA1" with Amount = 1000
        // [GIVEN] Reclassificate "FA1" to "FA2" with Amount = 300
        // [GIVEN] Create and post Disposal on "FA1" with Amount = 700
        OriginalAmount := LibraryRandom.RandDec(1000, 2);
        ReclassAmount := Round(OriginalAmount / 3);
        DisposalAmount := OriginalAmount - ReclassAmount;
        CreateAndPostDisposalAfterReclassification(FADepreciationBook, OriginalAmount, ReclassAmount, DisposalAmount);

        // [WHEN] Run "Depreciation Book" report for "FA2"
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[2]."FA No.", '', true, CalcDate('<2Y>', WorkDate()));

        // [THEN] "FA2" Acquisition Cost amount = 0
        // [THEN] "FA2" Disposal amount = 0
        // [THEN] "FA2" Book Value amount = 0
        VerifyFAAfterPartialDisposal(0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookAfterReclassify()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test to verify values on the Report - Depreciation Book after Reclassification.

        // Setup: Create Depreciation Table with Multiple Lines and FA Depreciation Books with Depreciation Book Code.
        Initialize();
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // Post General Journal with FA Posting Type Acquisition Cost.
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", Amount, WorkDate());
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code",
          FADepreciationBook[1]."FA No.", CalcDate('<CY>', WorkDate()), '');  // Enqueue values in CalculateDepreciationRequestPageHandler.
        PostGenJournalLineAfterCalculateDepreciation(true);

        // Create and Reclassify FA Reclass Journal and Post FA Reclass Journal.
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(
            FADepreciationBook, Amount, CalcDate('<1Y>', WorkDate())),
          FADepreciationBook[1]."Depreciation Book Code");

        // Exercise.
        Commit();  // Commit Required.
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code",
          FADepreciationBook[1]."FA No.", FADepreciationBook[2]."FA No.", true, CalcDate('<1Y>', WorkDate()));

        // Verify: Verify values on Report - Depreciation Book.
        VerifyValuesOnDepreciationBookReport(
          true,
          'Fixed_Asset_No_', 'DeprBookCode', 'NetChangeAmounts_Type__Control1130086', 'TotalInventoryYear_1_',
          FADepreciationBook[1]."FA No.", FADepreciationBook[1]."Depreciation Book Code", 0, Amount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookTotalDepreciationPercentAfterReclassify()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DepreciationAmount: Decimal;
        DepreciationPerc: Decimal;
    begin
        // [SCENARIO 542307] Depreciation Book Report shows wrong values in Total Depreciation %
        Initialize();

        // [GIVEN]  Create 2 FA and one Depreciation book
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));

        // [GIVEN] Post Acquisition and Depreciation of 1st FA
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", Amount, WorkDate());
        EnqueueValuesInRequestPageHandler(
            FADepreciationBook[1]."Depreciation Book Code",
            FADepreciationBook[1]."FA No.", CalcDate('<CY>', WorkDate()), '');
        PostGenJournalLineAfterCalculateDepreciation(true);

        // [GIVEN] Post Reclassification of 1st FA to 2nd FA
        ReclassifyAndPostFAReclassJournal(
            CreateFAReclassJournalLine(
                FADepreciationBook, Amount, CalcDate('<1Y>', WorkDate())),
                FADepreciationBook[1]."Depreciation Book Code");

        // [GIVEN] Depreciate reclassified 2nd FA
        Commit();
        EnqueueValuesInRequestPageHandler(
            FADepreciationBook[2]."Depreciation Book Code",
            FADepreciationBook[2]."FA No.", CalcDate('<2Y>', WorkDate()), '');
        PostGenJournalLineAfterCalculateDepreciation(true);

        // [WHEN] Executing Depreciation Book Report
        Commit();
        RunDepreciationBookReport(
            FADepreciationBook[1]."Depreciation Book Code",
            FADepreciationBook[1]."FA No.", FADepreciationBook[2]."FA No.",
            true, CalcDate('<2Y>', WorkDate()));

        // [GIVEN] Calculate FA Ledger Entry Depreciation %
        FALedgerEntry.SetRange("FA No.", FADepreciationBook[2]."FA No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindSet();
        FALedgerEntry.CalcSums(Amount);
        DepreciationAmount := FALedgerEntry.Amount;
        DepreciationPerc := (DepreciationAmount * 100) / Amount;

        // [THEN] Total Depreciation Percent of the report for 2nd FA should be equal to be percent calculated based on depreciated amount in FA Ledger Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BasicDepreciationPerc', Abs(DepreciationPerc));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDepreciationPercentageOnDepreciationTableCard()
    var
        DepreciationTableCode: Code[10];
    begin
        // Test to verify Total Depreciation Percentage on the Depreciation Table Card (5659).

        // Setup: Create Depreciation Table Lines with Period Depreciation %.
        Initialize();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();

        // Exercise & Verify: Open Depreciation Table Card and Verify Total Depreciation Percentage.
        OpenAndVerifyTotalDepreciationOnDepriciationTableCard(DepreciationTableCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLinesWithMultipleFixedAssets()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
    begin
        // Test to verify Amount on FA Ledger Entry when Purchase Invoice posted with Multiple Fixed Assets with Depreciation Code.

        // Setup: Create FA Depreciation Books with Depreciation Book Code.
        Initialize();
        CreateFADepreciationBookSetup(FADepreciationBook[1], '', WorkDate(), CreateDepreciationBookAndFAJournalSetup());  // Depreciation Table Code as blank.
        CreateFADepreciationBookSetup(FADepreciationBook[2], '', WorkDate(), FADepreciationBook[1]."Depreciation Book Code");  // Depreciation Table Code as blank.

        // Exercise: Post Purchase Invoice with Fixed Assets.
        CreateAndPostPurchaseInvoiceWithMultipleLines(FADepreciationBook);

        // Verify: Verify Amount on FA Ledger Entry.
        VerifyAmountOnFALedgerEntry(FADepreciationBook[1]);
        VerifyAmountOnFALedgerEntry(FADepreciationBook[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithVATTransactionReportAmount()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        PurchaseHeader: Record "Purchase Header";
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
        DocumentNo: Code[20];
    begin
        // Test to verify Amount on Vendor Ledger Entry when VAT Transaction Report Amount is specified.

        // Setup: Create VAT Transaction Report Amount, FA Depreciation Book and Purchase Invoice.
        Initialize();
        UpdateVATTransactionReportAmount(VATTransactionReportAmount);
        CreateFADepreciationBookSetup(FADepreciationBook, '', WorkDate(), CreateDepreciationBookAndFAJournalSetup());
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");

        // Exercise: Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Vendor Ledger Entry for Purchase Invoice.
        VerifyAmountOnVendorLedgerEntry(DocumentNo, PurchaseHeader."Buy-from Vendor No.");

        // Tear down.
        VATTransactionReportAmount.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithVATTransactionReportAmount()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
        DocumentNo: Code[20];
    begin
        // Test to verify Amount on Customer Ledger Entry when VAT Transaction Report Amount is specified.

        // Setup: Create VAT Transaction Report Amount, FA Depreciation Book and Sales Invoice.
        Initialize();
        UpdateVATTransactionReportAmount(VATTransactionReportAmount);
        CreateFADepreciationBookSetup(FADepreciationBook, '', WorkDate(), CreateDepreciationBookAndFAJournalSetup());  // Depreciation Table Code as blank.
        CreateAndPostGenJournalLine(
          FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandDec(1000, 2), WorkDate());
        CreateSalesHeader(SalesHeader);
        CreateSalesLine(
          SalesHeader, SalesLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", LibraryRandom.RandDec(10, 2));

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Customer Ledger Entry for Sales Invoice.
        VerifyAmountOnCustLedgerEntry(DocumentNo, SalesHeader."Sell-to Customer No.");

        // Tear down.
        VATTransactionReportAmount.Delete(true);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookSingleClassTotal()
    var
        DeprBookCode: Code[10];
        Amount: Decimal;
    begin
        // Test to verify Totals -  1 FA, 1 Class.
        DeprBookCode := CreateDepreciationBookAndFAJournalSetup();
        Amount := PurchFAWithFAClassSubclass(DeprBookCode, CreateFAClass(), '', WorkDate());

        RunDepreciationBookReport(DeprBookCode, '', '', false, CalcDate('<1Y>', WorkDate()));
        VerifyFAClassTotalling(true, Amount, Amount, 0, Amount);
        VerifyFASubclassTotalling(false, Amount, Amount, 0, Amount);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookMultiClassMultiSubclass()
    var
        DeprBookCode: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Test to verify Totals -  2 FAs, 2 Classes, 2 Subclasses
        Initialize();
        DeprBookCode := CreateDepreciationBookAndFAJournalSetup();

        Amount1 := PurchFAWithFAClassSubclass(DeprBookCode, CreateFAClass(), CreateFASubclass(), WorkDate());
        Amount2 := PurchFAWithFAClassSubclass(DeprBookCode, CreateFAClass(), CreateFASubclass(), WorkDate());

        RunDepreciationBookReport(DeprBookCode, '', '', true, CalcDate('<1Y>', WorkDate()));
        VerifyFAClassTotalling(true, Amount1, Amount1, 0, Amount1);
        VerifyFAClassTotalling(false, Amount2, Amount2, 0, Amount2);
        VerifyFASubclassTotalling(false, Amount1, Amount1, 0, Amount1);
        VerifyFASubclassTotalling(false, Amount2, Amount2, 0, Amount2);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookMultiClassSingleSublclass()
    var
        FASubclassCode: Code[10];
        DeprBookCode: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Test to verify Totals - 2 FAs, 2 Classes, 1 Subclass
        Initialize();
        DeprBookCode := CreateDepreciationBookAndFAJournalSetup();
        FASubclassCode := CreateFASubclass();

        Amount1 := PurchFAWithFAClassSubclass(DeprBookCode, CreateFAClass(), FASubclassCode, WorkDate());
        Amount2 := PurchFAWithFAClassSubclass(DeprBookCode, CreateFAClass(), FASubclassCode, WorkDate());

        RunDepreciationBookReport(DeprBookCode, '', '', true, CalcDate('<1Y>', WorkDate()));
        VerifyFAClassTotalling(true, Amount1, Amount1, 0, Amount1);
        VerifyFAClassTotalling(false, Amount2, Amount2, 0, Amount2);
        VerifyFASubclassTotalling(false, Amount1, Amount1, 0, Amount1);
        VerifyFASubclassTotalling(false, Amount1 + Amount2, Amount1 + Amount2, 0, Amount1 + Amount2);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationBookSingleClassMultipleSubclass()
    var
        FAClassCode: Code[10];
        DeprBookCode: Code[10];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Test to verify Totals - 2 FAs, 1 Class, 2 Subclasses
        Initialize();
        DeprBookCode := CreateDepreciationBookAndFAJournalSetup();
        FAClassCode := CreateFAClass();

        Amount1 := PurchFAWithFAClassSubclass(DeprBookCode, FAClassCode, CreateFASubclass(), WorkDate());
        Amount2 := PurchFAWithFAClassSubclass(DeprBookCode, FAClassCode, CreateFASubclass(), WorkDate());

        RunDepreciationBookReport(DeprBookCode, '', '', true, CalcDate('<1Y>', WorkDate()));
        VerifyFAClassTotalling(true, Amount1, Amount1, 0, Amount1);
        VerifyFAClassTotalling(false, Amount1 + Amount2, Amount1 + Amount2, 0, Amount1 + Amount2);
        VerifyFASubclassTotalling(false, Amount1, Amount1, 0, Amount1);
        VerifyFASubclassTotalling(false, Amount2, Amount2, 0, Amount2);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookSingleClassMultipleSubclassYearTotals()
    var
        FAClassCode: Code[10];
        Amount: Decimal;
    begin
        // Test to verify Totals / FA Depr. Starting Date is in different years for each FA.
        // Check totals(FA Class totaling) are not summarized between years.
        FAClassCode := CreateFAClass();
        Amount := CreatePurchFARunFADeprBookReport(FAClassCode, FAClassCode, CreateFASubclass(), CreateFASubclass(), true);
        VerifyFAClassTotalling(true, Amount, Amount, 0, Amount);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookMultipleClassSingleSubclassYearTotals()
    var
        FASubClassCode: Code[10];
        Amount: Decimal;
    begin
        // Test to verify Totals / FA Depr. Starting Date is in different years for each FA.
        // Check totals(FA SubClass totaling) are not summarized between years.
        FASubClassCode := CreateFASubclass();
        Amount := CreatePurchFARunFADeprBookReport(CreateFAClass(), CreateFAClass(), FASubClassCode, FASubClassCode, false);
        VerifyFASubclassTotalling(true, Amount, Amount, 0, Amount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DerpBookFAReclassificationAfterCalcDepreciationAndAfterReclassification()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        FADepreciationBookNormal: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reclassification]
        // [SCENARIO 379832] Depreciation Book report shows line Reclassification for two FA after calculation depreciation and posting reclassification
        Initialize();

        // [GIVEN] "FA1" and "FA2" with different depreciation books
        CreateMultipleFADepreciationBookSetups(FADepreciationBook, CalcDate('<1Y>', WorkDate()));
        // [GIVEN] Fixed Asset "FA1" with Acquisision Cost = "1000"
        // [GIVEN] Posted Depreciation "FA1" with Amount = "100"
        // [GIVEN] Reclassificate "FA1" to "FA2" with Reclassify Acqu. Amount = "300"
        CreateAndPostReclassification(FADepreciationBook);

        // [GIVEN] Fixed Asset "N" with Acquisition Cost and calculated depreciation
        CreateFADepreciationBookSetup(
          FADepreciationBookNormal, FADepreciationBook[1]."Depreciation Table Code",
          WorkDate(), FADepreciationBook[1]."Depreciation Book Code");
        CreateAndPostGenJournalLine(
          FADepreciationBookNormal, GenJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandDec(1000, 2), WorkDate());
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBookNormal."FA No.", CalcDate('<CY>', WorkDate()), '');
        PostGenJournalLineAfterCalculateDepreciation(true);

        // [WHEN] Run "Depreciation Book" report for "FA1" and fixed asset "N"
        Commit();
        RunDepreciationBookReport(
          FADepreciationBook[1]."Depreciation Book Code",
          FADepreciationBook[1]."FA No.", FADepreciationBookNormal."FA No.", true, CalcDate('<2Y>', WorkDate()));

        // [THEN] Reclassification line shows
        // [THEN] Additional Amount = -"300"
        // [THEN] Amount At End Date = "700"
        // [THEN] Accumulate Depreciation = "70"
        // [THEN] Book Value At End Date = "630"
        VerifyValueOnDeprBookReportToReclassificationLine(FADepreciationBook[1]);

        // [THEN] Report prints acquisition and depreciation amounts for Fixed Asset "N" matching to Depreciation Book
        // [THEN] Reclassification amount is printed as 0 (TFS 380145)
        FADepreciationBookNormal.CalcFields("Acquisition Cost", Depreciation);
        LibraryReportDataset.SetRange('Fixed_Asset_No_', FADepreciationBookNormal."FA No.");
        VerifyValuesOnDepreciationBookReport(
          false, 'ReclassAmount_4_', 'StartAmounts_1_', 'StartingAccumulated', 'BookValueAtEndingDate',
          0, FADepreciationBookNormal."Acquisition Cost", FADepreciationBookNormal.Depreciation,
          FADepreciationBookNormal."Acquisition Cost" + FADepreciationBookNormal.Depreciation);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportForFAAfterReclassificationAndDepreciation()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Report] [FA Disposal] [Reclassification] [Depreciation Book]
        // [SCENARIO 331401] Report 12119 "Depreciation Book" do not mix reclassification amounts for "Addition in Period" and "Disposal in Period" when FA was reclassified and depreciated at the same period.
        Initialize();
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        // [GIVEN] Fixed Asset "FA1" with depreciation book starting from 01.01 , aquired for amount of 500
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDecInRange(500, 600, 2), CalcDate('<-CY>', WorkDate()));

        Commit();

        // [GIVEN] Fixed Asset "FA2" with depreciation book from 01.01
        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);

        // [GIVEN] "FA1" reclaffisied into "FA2" with Aquisition Cost = 150
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(
            FADepreciationBook, LibraryRandom.RandDecInRange(100, 200, 2),
            FADepreciationBook[2]."Depreciation Starting Date"),
          DepreciationBookCode);

        // [GIVEN] Posted Sales Invoice for "FA2" with "Depr. until FA Posting Date" option for amount = 50, at the 28.01
        PostSalesInvoiceWithFAWithDeprUntilFAPostingDate(
          FADepreciationBook[2]."FA No.", FADepreciationBook[2]."Depreciation Book Code", true);
        Commit();

        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook[2]."FA No.", '', true, CalcDate('<-CY>', WorkDate()));

        // [THEN] Total Disposal Amount in period is = 150
        FindFALedgerEntry(
          FALedgerEntry, FADepreciationBook[2]."FA No.", DepreciationBookCode,
          FALedgerEntry."Document Type"::Invoice, FALedgerEntry."FA Posting Category"::Disposal);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalDisposalAmounts_1__TotalDisposalAmounts_3__TotalDisposalAmounts_4_', FALedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportAppreciationPartOfDepreciableBasisFalse()
    var
        DepreciationTableLine: Record "Depreciation Table Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBookCode: Code[10];
        DepreciationTableCode: Code[10];
        DepreciationPercent: Integer;
        DepreciationBasis: Decimal;
    begin
        // [SCENARIO 373928] When in FA Posting Setup "Part of Depreciable Basis" is set to false for Appreciation, "Depreciation Book" report ignores appreciation in Depreciation % calculation.
        Initialize();

        // [GIVEN] Depreciaton Book with FA Posting Setup's "Part of Depreciable Basis" set to false for Appreciation.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        FAPostingTypeSetup.Get(DepreciationBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
        FAPostingTypeSetup.Validate("Part of Depreciable Basis", false);
        FAPostingTypeSetup.Modify(true);

        // [GIVEN] Deprection Table with Depreciation Line with "Period Depreciation %" = 10.
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        DepreciationTableLine.Get(DepreciationTableCode, 1);
        DepreciationPercent := DepreciationTableLine."Period Depreciation %";

        // [GIVEN] Fixed Asset with Depreciation Book starting from 01.01 using Depreciation Table.
        CreateFADepreciationBookSetup(FADepreciationBook, DepreciationTableCode, CalcDate('<-CY>', WorkDate()), DepreciationBookCode);

        // [GIVEN] Fixed Asset is aquired for amount of 500 on 01.01.
        DepreciationBasis := LibraryRandom.RandDecInRange(500, 600, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBasis, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is appreciated for amount of 100 on 01.01.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Appreciation,
            LibraryRandom.RandDecInRange(500, 600, 2), CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is depreciated for amount of 50 on 01.02.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Depreciation,
            -DepreciationBasis * DepreciationPercent / 100, WorkDate());

        // [WHEN] Report "Depreciation Book" is run.
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook."FA No.", '', true, WorkDate());

        // [THEN] BasicDepreciationPerc is equal to "Period Depreciation %" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BasicDepreciationPerc', DepreciationPercent);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportAppreciationPartOfDepreciableBasisTrue()
    var
        DepreciationTableLine: Record "Depreciation Table Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBookCode: Code[10];
        DepreciationTableCode: Code[10];
        DepreciationPercent: Integer;
        DepreciationBasis: Decimal;
        Appreciation: Decimal;
    begin
        // [SCENARIO 373928] When in FA Posting Setup "Part of Depreciable Basis" is set to true for Appreciation, "Depreciation Book" report uses appreciation in Depreciation % calculation.
        Initialize();

        // [GIVEN] Depreciaton Book with FA Posting Setup's "Part of Depreciable Basis" set to true for Appreciation.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        FAPostingTypeSetup.Get(DepreciationBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
        FAPostingTypeSetup.Validate("Part of Depreciable Basis", true);
        FAPostingTypeSetup.Modify(true);

        // [GIVEN] Deprection Table with Depreciation Line with "Period Depreciation %" = 10.
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        DepreciationTableLine.Get(DepreciationTableCode, 1);
        DepreciationPercent := DepreciationTableLine."Period Depreciation %";

        // [GIVEN] Fixed Asset with Depreciation Book starting from 01.01 using Depreciation Table.
        CreateFADepreciationBookSetup(FADepreciationBook, DepreciationTableCode, CalcDate('<-CY>', WorkDate()), DepreciationBookCode);

        // [GIVEN] Fixed Asset is aquired for amount of 500 on 01.01.
        DepreciationBasis := LibraryRandom.RandDecInRange(500, 600, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBasis, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is appreciated for amount of 100 on 01.01.
        Appreciation := LibraryRandom.RandDecInRange(500, 600, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Appreciation,
            Appreciation, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is depreciated for amount of 50 on 01.02.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Depreciation,
            -(DepreciationBasis + Appreciation) * DepreciationPercent / 100, WorkDate());

        // [WHEN] Report "Depreciation Book" is run.
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook."FA No.", '', true, WorkDate());

        // [THEN] BasicDepreciationPerc is equal to "Period Depreciation %" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BasicDepreciationPerc', DepreciationPercent);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportWriteDownPartOfDepreciableBasisFalse()
    var
        DepreciationTableLine: Record "Depreciation Table Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBookCode: Code[10];
        DepreciationTableCode: Code[10];
        DepreciationPercent: Integer;
        DepreciationBasis: Decimal;
    begin
        // [SCENARIO 373928] When in FA Posting Setup "Part of Depreciable Basis" is set to false for Write-Down, "Depreciation Book" report ignores appreciation in Depreciation % calculation.
        Initialize();

        // [GIVEN] Depreciaton Book with FA Posting Setup's "Part of Depreciable Basis" set to false for Write-Down.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        FAPostingTypeSetup.Get(DepreciationBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Part of Depreciable Basis", false);
        FAPostingTypeSetup.Modify(true);

        // [GIVEN] Deprection Table with Depreciation Line with "Period Depreciation %" = 10.
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        DepreciationTableLine.Get(DepreciationTableCode, 1);
        DepreciationPercent := DepreciationTableLine."Period Depreciation %";

        // [GIVEN] Fixed Asset with Depreciation Book starting from 01.01 using Depreciation Table.
        CreateFADepreciationBookSetup(FADepreciationBook, DepreciationTableCode, CalcDate('<-CY>', WorkDate()), DepreciationBookCode);

        // [GIVEN] Fixed Asset is aquired for amount of 500 on 01.01.
        DepreciationBasis := LibraryRandom.RandDecInRange(500, 600, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBasis, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Write-Down for Fixed Asset for amount of 100 on 01.01.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Write-Down",
            -LibraryRandom.RandDecInRange(100, 200, 2), CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is depreciated for amount of 50 on 01.02.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Depreciation,
            -DepreciationBasis * DepreciationPercent / 100, WorkDate());

        // [WHEN] Report "Depreciation Book" is run.
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook."FA No.", '', true, WorkDate());

        // [THEN] BasicDepreciationPerc is equal to "Period Depreciation %" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BasicDepreciationPerc', DepreciationPercent);
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportWriteDownPartOfDepreciableBasisTrue()
    var
        DepreciationTableLine: Record "Depreciation Table Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBookCode: Code[10];
        DepreciationTableCode: Code[10];
        DepreciationPercent: Integer;
        DepreciationBasis: Decimal;
        WriteDown: Decimal;
    begin
        // [SCENARIO 373928] When in FA Posting Setup "Part of Depreciable Basis" is set to true for Write-Down, "Depreciation Book" report uses appreciation in Depreciation % calculation.
        Initialize();

        // [GIVEN] Depreciaton Book with FA Posting Setup's "Part of Depreciable Basis" set to true for Write-Down.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        FAPostingTypeSetup.Get(DepreciationBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        FAPostingTypeSetup.Validate("Part of Depreciable Basis", true);
        FAPostingTypeSetup.Modify(true);

        // [GIVEN] Deprection Table with Depreciation Line with "Period Depreciation %" = 10.
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        DepreciationTableLine.Get(DepreciationTableCode, 1);
        DepreciationPercent := DepreciationTableLine."Period Depreciation %";

        // [GIVEN] Fixed Asset with Depreciation Book starting from 01.01 using Depreciation Table.
        CreateFADepreciationBookSetup(FADepreciationBook, DepreciationTableCode, CalcDate('<-CY>', WorkDate()), DepreciationBookCode);

        // [GIVEN] Fixed Asset is aquired for amount of 500 on 01.01.
        DepreciationBasis := LibraryRandom.RandDecInRange(500, 600, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost",
            DepreciationBasis, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Write-down for Fixed Asset for amount of 100 on 01.01.
        WriteDown := -LibraryRandom.RandDecInRange(100, 200, 2);
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::"Write-Down",
            WriteDown, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Fixed Asset is depreciated for amount of 50 on 01.02.
        CreateAndPostGenJournalLine(
            FADepreciationBook, GenJournalLine."FA Posting Type"::Depreciation,
            -(DepreciationBasis + WriteDown) * DepreciationPercent / 100, WorkDate());

        // [WHEN] Report "Depreciation Book" is run.
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook."FA No.", '', true, WorkDate());

        // [THEN] BasicDepreciationPerc is equal to "Period Depreciation %" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BasicDepreciationPerc', DepreciationPercent);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportForFAAfterReclassificationAndDepreciationAndSalesInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
        FAStartingDate: Date;
        DisposalDate: Date;
        AcquireAmount: Decimal;
    begin
        // [FEATURE] [Report] [FA Disposal] [Reclassification] [Depreciation Book]
        // [SCENARIO 391326] "Depreciation Book" report shows "Book Value" = 0 and "Amount at" = 0 for fully disposed reclassified Fixed Asset as of date of disposal
        Initialize();
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        FAStartingDate := CalcDate('<-CY>', WorkDate());
        DisposalDate := CalcDate('<CY>', WorkDate());
        AcquireAmount := LibraryRandom.RandDecInRange(500, 600, 2);

        // [GIVEN] Fixed Asset "FA1" acquired with amount 1000
        // [GIVEN] Depreciation calculated and posted for "FA1" from Jan 1st till Dec 31st / 2023.
        // [GIVEN] "FA1" reclassified to "FA2" with amount 500 and depreciation at Dec 31st / 2023
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", Round(AcquireAmount / 2), FAStartingDate);
        Commit();
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", DisposalDate, '');
        PostGenJournalLineAfterCalculateDepreciation(false);

        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);

        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(FADepreciationBook, LibraryRandom.RandDecInRange(100, 200, 2), DisposalDate),
          DepreciationBookCode);

        // [GIVEN] Sales invoice posted for "FA2" with amount 500 at Dec 31st / 2023.
        CreateSalesHeader(SalesHeader);
        SalesHeader.Validate("Posting Date", DisposalDate);
        SalesHeader.Validate("Document Date", DisposalDate);
        SalesHeader.Validate("Operation Occurred Date", DisposalDate);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, SalesLine, FADepreciationBook[2]."FA No.", DepreciationBookCode, Round(AcquireAmount / 2));

        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        Commit();

        // [WHEN] Run report "Depreciation Book" for "FA2" at with ending date Dec 31st / 2023
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook[2]."FA No.", '', true, FAStartingDate);

        // [THEN] Report output shows: 'Disposal In Period' shows shows fully disposed amount
        // [THEN] - 'Disposal in Period' shows shows fully disposed amount
        // [THEN] - 'Amount At' (disposal date) shows 0
        // [THEN] - Total 'Book Value' shows 0
        // [THEN] - Class and SubClass 'Book Value' show 0
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FindFALedgerEntry(
          FALedgerEntry, FADepreciationBook[2]."FA No.", DepreciationBookCode,
          FALedgerEntry."Document Type"::Invoice, FALedgerEntry."FA Posting Category"::Disposal);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalClass_3_', FALedgerEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalClass_4_', 0);
        VerifyValuesOnDepreciationBookReport(
          false, 'TotalSubclass_14_', 'TotalClass_14_', 'TotalInventoryYear_14_', 'BookValueAtEndingDate', 0, 0, 0, 0);

        // [THEN] - #404695 - Disposed reclassified depreciation is reflected in Disposal column (increment) and Accumulated Depreciation (decrement)
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FindFALedgerEntry(
          FALedgerEntry, FADepreciationBook[2]."FA No.", DepreciationBookCode,
          FALedgerEntry."Document Type"::Invoice, FALedgerEntry."FA Posting Category"::Disposal);

        LibraryReportDataset.AssertElementWithValueExists('TotalClass_6_', FALedgerEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('ABS_TotalClass_13__', 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DepreciationBookRequestPageHandler')]
    procedure RunDepreciationBookReportWhenSourceFAWithLongDescription()
    var
        SourceFixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCode: Code[10];
        AcquisitionDate: Date;
        DescriptionMaxLen: Integer;
    begin
        // [SCENARIO 421489] Run report "Depreciation Book" when Source Fixed Asset has Description with length 100.
        Initialize();

        // [GIVEN] Fixed Asset "FA1" with Description of length 100.
        DescriptionMaxLen := MaxStrLen(SourceFixedAsset.Description);
        LibraryFixedAsset.CreateFixedAsset(SourceFixedAsset);
        UpdateDescriptionOnFixedAsset(
          SourceFixedAsset."No.", CopyStr(LibraryUtility.GenerateRandomXMLText(DescriptionMaxLen), 1, DescriptionMaxLen));

        // [GIVEN] Acquired Fixed Asset "FA2" with Source FA No. = "FA1".
        AcquisitionDate := CalcDate('<-CY>', WorkDate());
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        CreateFADepreciationBookSetup(FADepreciationBook, CreateDepreciationTableWithMultipleLines(), AcquisitionDate, DepreciationBookCode);
        CreateAndPostGenJournalLine(FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost", 1000, AcquisitionDate);
        UpdateSourceFANoOnFixedAsset(FADepreciationBook."FA No.", SourceFixedAsset."No.");
        Commit();

        // [WHEN] Run report "Depreciation Book".
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook."FA No.", '', true, AcquisitionDate);

        // [THEN] Report was run without errors.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DeprBookCode', DepreciationBookCode);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeprBookReportForReclassifiedAndDisposedFA()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
        FAStartingDate: Date;
        DisposalDate: Date;
        AcquireAmount: Decimal;
    begin
        // [SCENARIO 426020] "Depreciation Book" report shows "Book Value" <> 0 for fully disposed reclassified Fixed Asset
        Initialize();
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        FAStartingDate := CalcDate('<-CY>', WorkDate());
        DisposalDate := CalcDate('<CY>', WorkDate());
        AcquireAmount := LibraryRandom.RandDecInRange(500, 600, 2);

        // [GIVEN] Fixed Asset "FA1"
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", Round(AcquireAmount / 2), FAStartingDate);
        Commit();
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", DisposalDate, '');
        // [GIVEN] Depreciation calculated and posted for "FA1"
        PostGenJournalLineAfterCalculateDepreciation(false);

        // [GIVEN] "FA1" partially reclassified to "FA2"
        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(FADepreciationBook, LibraryRandom.RandDecInRange(100, 200, 2), DisposalDate),
          DepreciationBookCode);

        // [GIVEN] Sales invoice posted for "FA1"
        CreateSalesHeader(SalesHeader);
        SalesHeader.Validate("Posting Date", DisposalDate);
        SalesHeader.Validate("Document Date", DisposalDate);
        SalesHeader.Validate("Operation Occurred Date", DisposalDate);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, FADepreciationBook[1]."FA No.", DepreciationBookCode, Round(AcquireAmount / 2));
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Run report "Depreciation Book" for "FA1" at with ending date Dec 31st / 2023
        Commit();
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook[1]."FA No.", '', true, FAStartingDate);

        // [THEN] - Class and SubClass 'Book Value' show 0
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnDepreciationBookReport(false, 'TotalSubclass_14_', 'TotalClass_14_', 'TotalInventoryYear_14_', 'BookValueAtEndingDate', 0, 0, 0, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAcquisitionAmountForReclassifiedAndDisposedFA()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
        FAStartingDate: Date;
        DisposalDate: Date;
        AcquireAmount: Decimal;
    begin
        // [SCENARIO 434828] Acquisition cost shows reclassification value even in the given time period even if there is no acuisition happned during that period
        Initialize();
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        FAStartingDate := CalcDate('<-CY>', WorkDate());
        DisposalDate := CalcDate('<CY>', WorkDate());
        AcquireAmount := LibraryRandom.RandDecInRange(500, 600, 2);

        // [GIVEN] Fixed Asset "FA1"
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", Round(AcquireAmount / 2), FAStartingDate);
        Commit();
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", DisposalDate, '');
        // [GIVEN] Depreciation calculated and posted for "FA1"
        PostGenJournalLineAfterCalculateDepreciation(false);

        // [GIVEN] "FA1" partially reclassified to "FA2"
        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(FADepreciationBook, LibraryRandom.RandDecInRange(100, 200, 2), DisposalDate),
          DepreciationBookCode);

        // [GIVEN] Sales invoice posted for "FA1"
        CreateSalesHeader(SalesHeader);
        SalesHeader.Validate("Posting Date", DisposalDate);
        SalesHeader.Validate("Document Date", DisposalDate);
        SalesHeader.Validate("Operation Occurred Date", DisposalDate);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, FADepreciationBook[1]."FA No.", DepreciationBookCode, Round(AcquireAmount / 2));
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Run report "Depreciation Book" for "FA1" with starting date as Acquisition posting date + 1 so that acquisition transaction cannot be part of this report.
        Commit();
        RunDepreciationBookReport(DepreciationBookCode, FADepreciationBook[1]."FA No.", '', true, FAStartingDate + 1);

        // [THEN] - Class and SubClass 'Book Value' show 0
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnDepreciationBookReport(false, 'ABS_TotalClass_13__', 'TotalClass_14_', 'TotalInventoryYear_14_', 'BookValueAtEndingDate', 0, 0, 0, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyEndTotalAmountForDisposalInPeriodAndReclassDepreciationColumn()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
        DepreciationAmount: Decimal;
        AcqCostPercentage: Decimal;
    begin
        // [SCENARIO 475594] Verify the End Total Amount for disposal in period and reclass/depreciation in the Depreciation Book report.
        Initialize();

        // [GIVEN] Created a depreciation book and table code, FA Posting Group.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        // [GIVEN] Generate a random Depreciation Amount and Acquisition Cost Percentage and save them in a variable.
        DepreciationAmount := LibraryRandom.RandIntInRange(3000, 4000);
        AcqCostPercentage := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Created a Fixed Asset "FA1".
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);

        // [GIVEN] Create and Post a Gen journal Line with FA Posting Type "Aquisition Cost".
        CreateAndPostGenJournalLine(
            FADepreciationBook[1],
            GenJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandIntInRange(10000, 20000),
            CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Create and Post a Gen journal Line with FA Posting Type "Depreciation".
        CreateAndPostGenJournalLine(
            FADepreciationBook[1],
            GenJournalLine."FA Posting Type"::Depreciation,
            -DepreciationAmount,
            CalcDate('<-CY>', WorkDate()));

        // [GIVEN] "FA1" partially reclassified to "FA2".
        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        ReclassifyAndPostFAReclassJournal(
            CreateFAReclassJournalLineWithAcqCostPercentage(
                FADepreciationBook,
                AcqCostpercentage,
                CalcDate('<CY>', WorkDate())),
            DepreciationBookCode);

        // [GIVEN] Create and Post a Gen journal Line with FA Posting Type "Disposal" for Fixed Asset "FA2".
        CreateAndPostGenJournalLine(FADepreciationBook[2], GenJournalLine."FA Posting Type"::Disposal, 0, CalcDate('<CY>', WorkDate()));

        // [WHEN] Run report "Depreciation Book" for "FA1" and "FA2".
        RunDepreciationBookReport(
            DepreciationBookCode,
            FADepreciationBook[1]."FA No.",
            FADepreciationBook[2]."FA No.",
            true,
            CalcDate('<-CY>', WorkDate()));

        // [VERIFY] Verify the End Total Amount for disposal in period and reclass/depreciation in the Depreciation Book report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ABS_TotalReclassDeprAmount__Control1130213', 0);
        LibraryReportDataset.AssertElementWithValueExists(
            'TotalDisposalAmounts_2__TotalDisposalAmounts_5__TotalDisposalAmounts_6_',
            (DepreciationAmount * AcqCostpercentage) / 100);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler,DepreciationBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckReclassAmtinDepreciationBook()
    var
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationTableCode: Code[10];
        DepreciationBookCode: Code[10];
        FAPostingGroupCode: Code[20];
        ReclassAmountTxt: Label 'ReclassAmount_4_';
        AcqAmount: Decimal;
    begin
        // [SCENARIO 555392] Check Reclass amount is correct in the Depreciation Book report when Reclassification is the first Ledger Entry for a Fixed Asset in the Italian version.
        Initialize();

        // [GIVEN] Modify Company Info
        UpdateCompanyInfo();

        // [GIVEN] Created a Depreciation Book and table code, FA Posting Group.
        DepreciationBookCode := CreateDepreciationBookAndFAJournalSetup();
        DepreciationTableCode := CreateDepreciationTableWithMultipleLines();
        CreateFAPostingGroup(FAPostingGroupCode);

        // [GIVEN] Generate a random Depreciation Amount and Acquisition Cost Percentage and save them in a variable.
        AcqAmount := LibraryRandom.RandIntInRange(100, 20000);

        // [GIVEN] Created a Fixed Asset "FA1".
        CreateFAWithDepreciationBookSetup(FADepreciationBook[1], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);

        // [GIVEN] Create and Post a Gen Journal Line with FA Posting Type "Aquisition Cost".
        CreateAndPostGenJournalLine(
            FADepreciationBook[1],
            GenJournalLine."FA Posting Type"::"Acquisition Cost",
            AcqAmount,
            WorkDate());

        // [GIVEN] "FA1" reclassified to "FA2".
        CreateFAWithDepreciationBookSetup(FADepreciationBook[2], FAPostingGroupCode, DepreciationBookCode, DepreciationTableCode);
        ReclassifyAndPostFAReclassJournal(
            CreateFAReclassJournalLine(
                FADepreciationBook,
                AcqAmount,
                WorkDate()),
                DepreciationBookCode);

        // [GIVEN] Create and Post a Gen Journal Line with FA Posting Type "Aquisition Cost" for "FA2".
        CreateAndPostGenJournalLine(
            FADepreciationBook[2],
            GenJournalLine."FA Posting Type"::"Acquisition Cost",
            LibraryRandom.RandIntInRange(100, 20000),
            WorkDate());

        // [WHEN] Run report "Depreciation Book" for "FA1" and "FA2".
        RunDepreciationBookReport(
            DepreciationBookCode,
            FADepreciationBook[2]."FA No.",
            '',
            true,
            CalcDate('<-CY>', WorkDate()));

        // [THEN] Verify the Reclass Amount in the Depreciation Book report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReclassAmountTxt, AcqAmount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        SetFiscalCodeAndRegCompanyNoOnCompanyInfo();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostDisposalAfterReclassification(FADepreciationBook: array[2] of Record "FA Depreciation Book"; InitialAmount: Decimal; ReclassAmount: Decimal; DisposalAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", InitialAmount, WorkDate());
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code",
          FADepreciationBook[1]."FA No.", CalcDate('<CY>', WorkDate()), '');  // Enqueue values in CalculateDepreciationRequestPageHandler.
        PostGenJournalLineAfterCalculateDepreciation(true);

        // Create and Reclassify FA Reclass Journal and Post FA Reclass Journal.
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(
            FADepreciationBook, ReclassAmount, CalcDate('<1Y>', WorkDate())),
          FADepreciationBook[1]."Depreciation Book Code");

        // Post General Journal with FA Posting Type Disposal.
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::Disposal, -DisposalAmount,
          CalcDate('<1Y>', FADepreciationBook[2]."Depreciation Starting Date"));  // Random Amount.
    end;

    local procedure CreateAndPostGenJournalLine(FADepreciationBook: Record "FA Depreciation Book"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FADepreciationBook."FA No.", Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithMultipleLines(FADepreciationBook: array[2] of Record "FA Depreciation Book"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, FADepreciationBook[1]."FA No.", FADepreciationBook[1]."Depreciation Book Code");
        CreatePurchaseLine(PurchaseHeader, FADepreciationBook[2]."FA No.", FADepreciationBook[2]."Depreciation Book Code");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostReclassification(FADepreciationBook: array[2] of Record "FA Depreciation Book")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(
          FADepreciationBook[1], GenJournalLine."FA Posting Type"::"Acquisition Cost", LibraryRandom.RandDec(1000, 2), WorkDate());
        EnqueueValuesInRequestPageHandler(
          FADepreciationBook[1]."Depreciation Book Code", FADepreciationBook[1]."FA No.", CalcDate('<CY>', WorkDate()), '');
        PostGenJournalLineAfterCalculateDepreciation(true);
        ReclassifyAndPostFAReclassJournal(
          CreateFAReclassJournalLine(
            FADepreciationBook, LibraryRandom.RandDec(100, 2), CalcDate('<1Y>', WorkDate())),
          FADepreciationBook[1]."Depreciation Book Code");
    end;

    local procedure CreateDepreciationTableWithMultipleLines(): Code[10]
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
    begin
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        CreateDepreciationTableLine(DepreciationTableHeader.Code);
        CreateDepreciationTableLine(DepreciationTableHeader.Code);
        CreateDepreciationTableLine(DepreciationTableHeader.Code);
        exit(DepreciationTableHeader.Code);
    end;

    local procedure CreateDepreciationBookAndFAJournalSetup(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FindFAJournalBatch(FAJournalBatch);
        FindGenJournalBatch(GenJournalBatch);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');  // User ID - Blank.
        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateDepreciationTableLine(DepreciationTableCode: Code[10])
    var
        DepreciationTableLine: Record "Depreciation Table Line";
    begin
        LibraryFixedAsset.CreateDepreciationTableLine(DepreciationTableLine, DepreciationTableCode);
        DepreciationTableLine.Validate("Period Depreciation %", LibraryRandom.RandInt(10));  // Random Period Depreciation %.
        DepreciationTableLine.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; DepreciationTableCode: Code[10]; DepreciationStartingDate: Date)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", DepreciationStartingDate);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"User-Defined");
        FADepreciationBook.Validate("First User-Defined Depr. Date", DepreciationStartingDate);
        FADepreciationBook.Validate("Depreciation Table Code", DepreciationTableCode);
        FADepreciationBook.Modify(true);
        UpdateIntegrationInDepreciationBook(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure CreateFADepreciationBookSetup(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationTableCode: Code[10]; DepreciationStartingDate: Date; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset, DepreciationBookCode, DepreciationTableCode, DepreciationStartingDate);
    end;

    local procedure CreateFAWithDepreciationBookSetup(var FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10]; DepreciationTableCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroupCode);
        FixedAsset.Modify(true);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset, DepreciationBookCode, DepreciationTableCode, CalcDate('<-CY>', WorkDate()));
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandIntInRange(5, 10));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateMultipleFADepreciationBookSetups(var FADepreciationBook: array[2] of Record "FA Depreciation Book"; DepStartingDate: Date)
    begin
        CreateFADepreciationBookSetup(
          FADepreciationBook[1],
          CreateDepreciationTableWithMultipleLines(),
          WorkDate(), CreateDepreciationBookAndFAJournalSetup());
        CreateFADepreciationBookSetup(
          FADepreciationBook[2],
          FADepreciationBook[1]."Depreciation Table Code",
          DepStartingDate, FADepreciationBook[1]."Depreciation Book Code");
    end;

    local procedure CreateFAReclassJournalLine(FADepreciationBook: array[2] of Record "FA Depreciation Book"; ReclassifyAcqCostAmount: Decimal; FAPostingDate: Date): Code[10]
    var
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
        LibraryFixedAsset.CreateFAReclassJournal(FAReclassJournalLine, FAReclassJournalTemplate.Name, FAReclassJournalBatch.Name);
        FAReclassJournalLine.Validate("FA No.", FADepreciationBook[1]."FA No.");
        FAReclassJournalLine.Validate("New FA No.", FADepreciationBook[2]."FA No.");
        FAReclassJournalLine.Validate("Depreciation Book Code", FADepreciationBook[1]."Depreciation Book Code");
        FAReclassJournalLine.Validate("FA Posting Date", FAPostingDate);
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Validate("Reclassify Acq. Cost Amount", ReclassifyAcqCostAmount);
        FAReclassJournalLine.Modify(true);
        exit(FAReclassJournalBatch.Name);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateAccountsOnFAPostingGroup(FAPostingGroup, VATPostingSetup."VAT Prod. Posting Group");
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", Vendor."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAssetNo,
          LibraryRandom.RandInt(10));  // Using Random Number Generator for Quantity.
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandDec(10, 2));  // Using the Random Number Generator for Quantity.
        SalesLine.Validate("Depreciation Book Code", DepreciationBookCode);
        SalesLine.Validate("Unit Price", LineAmount);
        SalesLine.Modify(true);
    end;

    local procedure CreateFAClass(): Code[10]
    var
        FAClass: Record "FA Class";
    begin
        FAClass.Init();
        FAClass.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(FAClass.FieldNo(Code), DATABASE::"FA Class"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"FA Class", FAClass.FieldNo(Code))));

        FAClass.Validate(Name, FAClass.Code);
        FAClass.Insert(true);
        exit(FAClass.Code);
    end;

    local procedure CreateFASubclass(): Code[10]
    var
        FASubclass: Record "FA Subclass";
    begin
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        exit(FASubclass.Code);
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryFixedAsset.UpdateFAPostingGroupGLAccounts(FAPostingGroup, VATPostingSetup);
        FAPostingGroupCode := FAPostingGroup.Code;
    end;

    local procedure PurchFAWithFAClassSubclass(DeprBookCode: Code[10]; FAClassCode: Code[10]; FASubclassCode: Code[10]; DeprStartingDate: Date) Amount: Decimal
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateFADepreciationBookSetup(FADepreciationBook, '', DeprStartingDate, DeprBookCode);
        SetFAClassSubclassCode(FADepreciationBook."FA No.", FAClassCode, FASubclassCode);
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostGenJournalLine(
          FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost", Amount, CalcDate('<1Y>', WorkDate()));
    end;

    local procedure EnqueueValuesInRequestPageHandler(DepreciationBookCode: Variant; FANo: Variant; FANo2: Variant; PrintPerFixedAsset: Variant)
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        LibraryVariableStorage.Enqueue(FANo);
        LibraryVariableStorage.Enqueue(FANo2);
        LibraryVariableStorage.Enqueue(PrintPerFixedAsset);
    end;

    local procedure FindFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure FindFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; FAPostingCategory: Enum "FA Ledger Posting Category")
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBookCode);
        FALedgerEntry.SetRange("Document Type", DocumentType);
        FALedgerEntry.SetRange("FA Posting Category", FAPostingCategory);
        FALedgerEntry.FindFirst();
    end;

    local procedure GetPeriodDepreciationPerc(DepreciationTableCode: Code[10]) PeriodDepreciationPerc: Decimal
    var
        DepreciationTableLine: Record "Depreciation Table Line";
    begin
        DepreciationTableLine.SetRange("Depreciation Table Code", DepreciationTableCode);
        DepreciationTableLine.FindSet();
        repeat
            PeriodDepreciationPerc += DepreciationTableLine."Period Depreciation %";
        until DepreciationTableLine.Next() = 0;
    end;

    local procedure OpenAndVerifyTotalDepreciationOnDepriciationTableCard(DepreciationTableCode: Code[10])
    var
        DepreciationTableCard: TestPage "Depreciation Table Card";
    begin
        DepreciationTableCard.OpenEdit();
        DepreciationTableCard.FILTER.SetFilter(Code, DepreciationTableCode);
        DepreciationTableCard.SubFormDeprTableLines.TotalDepreciationPct.AssertEquals(GetPeriodDepreciationPerc(DepreciationTableCode));
        DepreciationTableCard.Close();
    end;

    local procedure PostSalesInvoiceWithFAWithDeprUntilFAPostingDate(FANo: Code[20]; DepreciationBookCode: Code[10]; DeprUntilFAPostingDate: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader);
        CreateSalesLine(SalesHeader, SalesLine, FANo, DepreciationBookCode, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Depr. until FA Posting Date", DeprUntilFAPostingDate);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure PostFAReclassJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGenJournalBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostGenJournalLineAfterCalculateDepreciation(UpdateGenPostingType: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        REPORT.Run(REPORT::"Calculate Depreciation");

        FindGenJournalBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.FindFirst();
        if UpdateGenPostingType then begin
            GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
            GenJournalLine.Modify(true);
        end;

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ReclassifyAndPostFAReclassJournal(CurrentJnlBatchName: Code[10]; DepreciationBookCode: Code[10]): Text
    var
        FAReclassJournal: TestPage "FA Reclass. Journal";
    begin
        FAReclassJournal.OpenEdit();
        FAReclassJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        FAReclassJournal.FILTER.SetFilter("Depreciation Book Code", DepreciationBookCode);
        FAReclassJournal.Reclassify.Invoke();
        PostFAReclassJournal();
    end;

    local procedure SetFiscalCodeAndRegCompanyNoOnCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Fiscal Code", '01369030935');
        CompanyInformation.Validate("Register Company No.", Format(LibraryRandom.RandInt(10)));
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateIntegrationInDepreciationBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("Use FA Ledger Check", true);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateVATTransactionReportAmount(var VATTransactionReportAmount: Record "VAT Transaction Report Amount")
    begin
        LibraryITLocalization.CreateVATTransactionReportAmount(VATTransactionReportAmount, WorkDate());
        VATTransactionReportAmount.Validate("Threshold Amount Incl. VAT", LibraryRandom.RandDecInRange(10, 100, 2));  // Use Random value for Threshold Amount Encl. VAT.
        VATTransactionReportAmount.Validate("Threshold Amount Excl. VAT", LibraryRandom.RandDec(10, 2));  // Use Random value for Threshold Amount Incl. VAT.
        VATTransactionReportAmount.Modify(true);
    end;

    local procedure UpdateDescriptionOnFixedAsset(FANo: Code[20]; DescriptionValue: Text[100])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(FANo);
        FixedAsset.Validate(Description, DescriptionValue);
        FixedAsset.Modify(true);
    end;

    local procedure UpdateSourceFANoOnFixedAsset(FANo: Code[20]; SourceFANo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(FANo);
        FixedAsset.Validate("Source FA No.", SourceFANo);
        FixedAsset.Modify(true);
    end;

    local procedure VerifyAmountOnFALedgerEntry(FADepreciationBook: Record "FA Depreciation Book")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FADepreciationBook."FA No.");
        FALedgerEntry.FindFirst();
        FADepreciationBook.CalcFields("Book Value");
        FALedgerEntry.TestField(Amount, FADepreciationBook."Book Value");
    end;

    local procedure VerifyAmountOnCustLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Customer.Get(CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        Customer.CalcFields(Balance);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, Customer.Balance);
    end;

    local procedure VerifyAmountOnVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Vendor.Get(VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Vendor.CalcFields(Balance);
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Amount, -Vendor.Balance);
    end;

    local procedure VerifyValuesOnDepreciationBookReport(LoadDataSetFile: Boolean; Caption: Text; Caption2: Text; Caption3: Text; Caption4: Text; CaptionValue: Variant; CaptionValue2: Variant; CaptionValue3: Decimal; CaptionValue4: Decimal)
    begin
        if LoadDataSetFile then
            LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, CaptionValue);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, CaptionValue2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, CaptionValue3);
        LibraryReportDataset.AssertElementWithValueExists(Caption4, CaptionValue4);
    end;

    local procedure VerifyFAClassTotalling(LoadDataSetFile: Boolean; AdditionInPeriod: Decimal; AmountAtEndDate: Decimal; AccumulatedDepr: Decimal; BookValue: Decimal)
    begin
        VerifyValuesOnDepreciationBookReport(
          LoadDataSetFile, 'TotalClass_2_', 'TotalClass_4_', 'TotalClass_5_', 'TotalClass_14_',
          AdditionInPeriod, AmountAtEndDate, AccumulatedDepr, BookValue);
    end;

    local procedure VerifyFASubclassTotalling(LoadDataSetFile: Boolean; AdditionInPeriod: Decimal; AmountAtEndDate: Decimal; AccumulatedDepr: Decimal; BookValue: Decimal)
    begin
        VerifyValuesOnDepreciationBookReport(
          LoadDataSetFile, 'TotalSubclass_2_', 'TotalSubclass_4_', 'TotalSubclass_5_', 'TotalSubclass_14_',
          AdditionInPeriod, AmountAtEndDate, AccumulatedDepr, BookValue);
    end;

    local procedure VerifyFAAfterPartialDisposal(StartAmount: Decimal; DisposalAmount: Decimal; BookValueAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('StartAmounts_1_', StartAmount);
        LibraryReportDataset.AssertElementWithValueExists('DisposalAmounts_1_', DisposalAmount);
        LibraryReportDataset.AssertElementWithValueExists('TotalEndingAmounts_Type__Control1130084', BookValueAmount);
    end;

    local procedure VerifyValueOnDeprBookReportToReclassificationLine(FADepreciationBook: Record "FA Depreciation Book")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        AdditionInPeriod: Decimal;
        AmountAtEndDate: Decimal;
        AccumulatedDepr: Decimal;
        BookValue: Decimal;
    begin
        FALedgerEntry.SetRange("FA No.", FADepreciationBook."FA No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Reclassification Entry", true);
        FALedgerEntry.FindFirst();
        AdditionInPeriod := FALedgerEntry.Amount;
        FALedgerEntry.SetRange("Reclassification Entry");
        FALedgerEntry.FindFirst();
        AmountAtEndDate := FALedgerEntry.Amount + AdditionInPeriod;
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.CalcSums(Amount);
        AccumulatedDepr := Abs(FALedgerEntry.Amount);
        BookValue := AmountAtEndDate - AccumulatedDepr;
        VerifyValuesOnDepreciationBookReport(
          true, 'ReclassAmount_1_', 'TotalClass_4_', 'ABS_TotalClass_13__', 'BookValueAtEndingDate',
          AdditionInPeriod, AmountAtEndDate, AccumulatedDepr, BookValue);
    end;

    local procedure UpdateAccountsOnFAPostingGroup(FAPostingGroup: Record "FA Posting Group"; VATProdPostingGroup: Code[20]): Code[20]
    var
        FAPostingGroup2: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        RecRef: RecordRef;
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>%1', '');
        RecRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);  // Required for GL Accounts for Fixed Asset.
        FAPostingGroup.Validate("Acquisition Cost Bal. Acc.", GLAccount."No.");
        FAPostingGroup.Validate("Depreciation Expense Acc.", GLAccount."No.");
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccount."No.");
        FAPostingGroup.Validate("Appreciation Account", GLAccount."No.");
        FAPostingGroup.Validate("Write-Down Account", GLAccount."No.");
        FAPostingGroup.Modify(true);
        exit(GenProductPostingGroup.Code);
    end;

    local procedure SetFAClassSubclassCode(FixedAssetNo: Code[20]; FAClassCode: Code[10]; FASubclassCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(FixedAssetNo);
        FixedAsset.Validate("FA Class Code", FAClassCode);
        if FASubclassCode <> '' then
            FixedAsset.Validate("FA Subclass Code", FASubclassCode);
        FixedAsset.Modify(true);
    end;

    local procedure CreatePurchFARunFADeprBookReport(FAClassCode1: Code[10]; FAClassCode2: Code[10]; FASubClassCode1: Code[10]; FASubClassCode2: Code[10]; PrintPerFixedAsset: Boolean) Amount: Decimal
    var
        DeprBookCode: Code[10];
    begin
        DeprBookCode := CreateDepreciationBookAndFAJournalSetup();
        PurchFAWithFAClassSubclass(DeprBookCode, FAClassCode1, FASubClassCode1, WorkDate());
        Amount := PurchFAWithFAClassSubclass(DeprBookCode, FAClassCode2, FASubClassCode2, CalcDate('<1Y>', WorkDate()));
        RunDepreciationBookReport(DeprBookCode, '', '', PrintPerFixedAsset, CalcDate('<1Y>', WorkDate()));
    end;

    local procedure RunDepreciationBookReport(DepreciationBookCode: Code[10]; FANo1: Code[20]; FANo2: Code[20]; PrintPerFixedAsset: Boolean; StartDate: Date)
    var
        FANoFilter: Text;
    begin
        if FANo1 <> '' then
            FANoFilter := FANo1;
        if FANo2 <> '' then begin
            if FANo1 <> '' then
                FANoFilter += '|';
            FANoFilter += FANo2;
        end;
        LibraryVariableStorage.Enqueue(FANoFilter);
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(PrintPerFixedAsset);
        REPORT.Run(REPORT::"Depreciation Book");
    end;

    local procedure CreateFAReclassJournalLineWithAcqCostPercentage(
        FADepreciationBook: array[2] of Record "FA Depreciation Book";
        ReclassifyAcqCostPercentage: Decimal;
        FAPostingDate: Date): Code[10]
    var
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
        LibraryFixedAsset.CreateFAReclassJournal(FAReclassJournalLine, FAReclassJournalTemplate.Name, FAReclassJournalBatch.Name);
        FAReclassJournalLine.Validate("FA No.", FADepreciationBook[1]."FA No.");
        FAReclassJournalLine.Validate("New FA No.", FADepreciationBook[2]."FA No.");
        FAReclassJournalLine.Validate("Depreciation Book Code", FADepreciationBook[1]."Depreciation Book Code");
        FAReclassJournalLine.Validate("FA Posting Date", FAPostingDate);
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Validate("Reclassify Acq. Cost %", ReclassifyAcqCostPercentage);
        FAReclassJournalLine.Modify(true);

        exit(FAReclassJournalBatch.Name);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.get();
        CompanyInfo."Fiscal Code" := CopyStr(
            LibraryUtility.GenerateRandomCode(CompanyInfo.FieldNo("Fiscal Code"), Database::"Company Information"),
            1,
            LibraryUtility.GetFieldLength(Database::"Company Information", CompanyInfo.FieldNo("Fiscal Code")));

        CompanyInfo."Register Company No." := CopyStr(
            LibraryUtility.GenerateRandomCode(CompanyInfo.FieldNo("Register Company No."), Database::"Company Information"),
            1,
            LibraryUtility.GetFieldLength(Database::"Company Information", CompanyInfo.FieldNo("Register Company No.")));
        CompanyInfo.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        No: Variant;
        DepreciationBook: Variant;
        PostingDate: Variant;
        Dummy: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBook);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(Dummy);
        CalculateDepreciation."Fixed Asset".SetFilter("No.", No);
        CalculateDepreciation.FAPostingDate.SetValue(Format(PostingDate));
        CalculateDepreciation.PostingDate.SetValue(Format(PostingDate));
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBook);
        CalculateDepreciation.InsertBalAccount.SetValue(true);
        CalculateDepreciation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DepreciationBookRequestPageHandler(var DepreciationBook: TestRequestPage "Depreciation Book")
    begin
        DepreciationBook."Fixed Asset".SetFilter("No.", LibraryVariableStorage.DequeueText());
        DepreciationBook.DepreciationBook.SetValue(LibraryVariableStorage.DequeueText());
        DepreciationBook.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        DepreciationBook.EndingDate.SetValue(CalcDate('<CY>', DepreciationBook.StartingDate.AsDate()));
        DepreciationBook.PrintPerFixedAsset.SetValue(LibraryVariableStorage.DequeueBoolean());
        DepreciationBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
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

