codeunit 144711 "ERM FA-1 Report"
{
    // // [FEATURE] [Fixed Asset] [UT] [Report] [FA Release Act]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Default Signature Setup" = imd,
                  tabledata "FA Ledger Entry" = imd,
                  tabledata "Posted FA Doc. Header" = imd,
                  tabledata "Posted FA Doc. Line" = imd,
                  tabledata "Sales Invoice Header" = imd,
                  tabledata "Sales Invoice Line" = imd;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        isInitialized: Boolean;
        ZeroMonthsTxt: Label '0 months';
        DecimalFormatWithPlacesTxt: Label '<Precision,2:2><Standard Format,0>', Locked = true;
        IncorrectCellValueErr: Label 'Incorrect cell value';

    [Test]
    [Scope('OnPrem')]
    procedure FAReleaseAct()
    begin
        // [FEATURE] [FA Release Act FA-1]
        // [SCENARIO] Verify "FA Release Act FA-1" report base values
        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" ("No. of Depreciation Years" = 0.25), "FABook2"
        // [GIVEN] FA Release Act header: "Posting Date" = 25-01-18, "FA Posting Date" = 26-01-18.
        // [GIVEN] FA Release Act line: "Depreciation Book Code" = "FABook1", "New Depreciation Book Code" = "FABook2"
        // [WHEN] Run "FA Release Act FA-1" report
        // [THEN] "Date To Business Accounting" = 26-01-18 (TFS 381676)
        // [THEN] "Depreciation Rate" = 100% / (12 * 0.25) = 33.33% (TFS 382230)
        CreateVerifyFAReleaseAct();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFAReleaseAct()
    begin
        // [FEATURE] [FA Posted Release Act FA-1]
        // [SCENARIO] Verify "FA Posted Release Act FA-1" report base values
        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" ("No. of Depreciation Years" = 0.25), "FABook2"
        // [GIVEN] Posted FA Release Act header: "Posting Date" = 25-01-18, "FA Posting Date" = 26-01-18.
        // [GIVEN] Posted FA Release Act line: "Depreciation Book Code" = "FABook1", "New Depreciation Book Code" = "FABook2"
        // [WHEN] Run "FA Posted Release Act FA-1" report
        // [THEN] "Date To Business Accounting" = 26-01-18 (TFS 381676)
        // [THEN] "Depreciation Rate" = 100% / (12 * 0.25) = 33.33% (TFS 382230)
        CreateVerifyPostedFAReleaseAct();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFAReleaseAct()
    begin
        // [FEATURE] [Sales] [Sales FA Release FA-1]
        // [SCENARIO] Verify "Sales FA Release FA-1" report base values
        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" ("No. of Depreciation Years" = 0.25)
        // [GIVEN] Sales Invoice with "Posting Date" = 25-01-18, line: "Type" = "FA", "Depreciation Book Code" = "FABook1"
        // [WHEN] Run "Sales FA Release FA-1" report
        // [THEN] "Date To Business Accounting" = 25-01-18 (TFS 381676)
        // [THEN] "Depreciation Rate" = 100% / (12 * 0.25) = 33.33% (TFS 382230)
        CreateVerifySalesFAReleaseAct();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesFAReleaseAct()
    begin
        // [FEATURE] [Sales] [Posted Sales FA Release FA-1]
        // [SCENARIO] Verify "Posted Sales FA Release FA-1" report base values
        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" ("No. of Depreciation Years" = 0.25)
        // [GIVEN] Posted Sales Invoice with "Posting Date" = 25-01-18, line: "Type" = "FA", "Depreciation Book Code" = "FABook1"
        // [WHEN] Run "Posted Sales FA Release FA-1" report
        // [THEN] "Date To Business Accounting" = 25-01-18 (TFS 381676)
        // [THEN] "Depreciation Rate" = 100% / (12 * 0.25) = 33.33% (TFS 382230)
        CreateVerifyPostedSalesFAReleaseAct();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAcqPeriodWithBlankInitialReleaseDateOnFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        FADocHeader: Record "FA Document Header";
    begin
        // [FEATURE] [FA Release Act FA-1]
        // [SCENARIO 377339] "Actual Acquisition Period" should be equal '0 months' in FA Release Act report if "Initial Release Date" of Fixed Asset is blank

        Initialize();
        // [GIVEN] Fixed Asset with zero "Initial Release Date"
        MockFAWithZeroInitialReleaseDate(FixedAsset);

        // [GIVEN] FA Release Act
        MockFADocument(FADocHeader, FixedAsset."No.");

        // [WHEN] Run FA Release Act Report
        RunFAReleaseActReport(FADocHeader);

        // [THEN] Actual use = '0 months' in FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('Y', 61, 2, ZeroMonthsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMonthsCalculatedFromYearsOnFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        FADocHeader: Record "FA Document Header";
        NoOfDeprYears: Decimal;
    begin
        // [FEATURE] [FA Release Act FA-1]
        // [SCENARIO 377339] "No of months" should be calculated as "No of years" multiplied by 12 when no value is defined in FA Release Act

        Initialize();
        // [GIVEN] Fixed Asset with "No. of Depreciation Years" = 2, "No. of Depreciation Months" = 0
        NoOfDeprYears := MockFAWithNoOfDeprYearsAndZeroNoOfDeprMonths(FixedAsset);

        // [GIVEN] FA Release Act
        MockFADocument(FADocHeader, FixedAsset."No.");

        // [WHEN] Run FA Release Act Report
        RunFAReleaseActReport(FADocHeader);

        // [THEN] "No. of months" = 24 in FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('BU', 61, 2, Format(NoOfDeprYears * 12, 0, DecimalFormatWithPlacesTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAcqPeriodWithBlankInitialReleaseDateOnPostedFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        PostedFADocHeader: Record "Posted FA Doc. Header";
    begin
        // [FEATURE] [FA Posted Release Act FA-1]
        // [SCENARIO 377339] "Actual Acquisition Period" should be equal '0 months' in Posted FA Release Act report if "Initial Release Date" of Fixed Asset is blank

        Initialize();
        // [GIVEN] Fixed Asset with zero "Initial Release Date"
        MockFAWithZeroInitialReleaseDate(FixedAsset);

        // [GIVEN] Posted FA Release Act
        MockPostedFADocument(PostedFADocHeader, FixedAsset);

        // [WHEN] Run Posted FA Release Act Report
        RunPostedFAReleaseActReport(PostedFADocHeader);

        // [THEN] Actual use = '0 months' in Posted FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('Y', 61, 2, ZeroMonthsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMonthsCalculatedFromYearsOnPostedFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        NoOfDeprYears: Decimal;
    begin
        // [FEATURE] [FA Posted Release Act FA-1]
        // [SCENARIO 377339] "No of months" should be calculated as "No of years" multiplied by 12 when no value is defined in Posted FA Release Act

        Initialize();
        // [GIVEN] Fixed Asset with "No. of Depreciation Years" = 2, "No. of Depreciation Months" = 0
        NoOfDeprYears := MockFAWithNoOfDeprYearsAndZeroNoOfDeprMonths(FixedAsset);

        // [GIVEN] Posted FA Release Act
        MockPostedFADocument(PostedFADocHeader, FixedAsset);

        // [WHEN] Run Posted FA Release Act Report
        RunPostedFAReleaseActReport(PostedFADocHeader);

        // [THEN] "No. of months" = 24 in Posted FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('BU', 61, 2, Format(NoOfDeprYears * 12, 0, DecimalFormatWithPlacesTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAcqPeriodWithBlankInitialReleaseDateOnSalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Sales FA Release FA-1]
        // [SCENARIO 377339] "Actual Acquisition Period" should be equal '0 months' in Sales FA Release Act report if "Initial Release Date" of Fixed Asset is blank

        Initialize();
        // [GIVEN] Fixed Asset with zero "Initial Release Date"
        MockFAWithZeroInitialReleaseDate(FixedAsset);

        // [GIVEN] Sales FA Release Act
        MockSalesInvoice(SalesHeader, FixedAsset."No.");

        // [WHEN] Run Sales FA Release Act Report
        RunSalesReleaseActReport(SalesHeader);

        // [THEN] Actual use = '0 months' in Sales FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('Y', 61, 2, ZeroMonthsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMonthsCalculatedFromYearsOnSalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
        NoOfDeprYears: Decimal;
    begin
        // [FEATURE] [Sales] [Sales FA Release FA-1]
        // [SCENARIO 377339] "No of months" should be calculated as "No of years" multiplied by 12 when no value is defined in Sales FA Release Act

        Initialize();
        // [GIVEN] Fixed Asset with "No. of Depreciation Years" = 2, "No. of Depreciation Months" = 0
        NoOfDeprYears := MockFAWithNoOfDeprYearsAndZeroNoOfDeprMonths(FixedAsset);

        // [GIVEN] Sales FA Release Act
        MockSalesInvoice(SalesHeader, FixedAsset."No.");

        // [WHEN] Run Sales FA Release Act Report
        RunSalesReleaseActReport(SalesHeader);

        // [THEN] "No. of months" = 24 in Sales FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('BU', 61, 2, Format(NoOfDeprYears * 12, 0, DecimalFormatWithPlacesTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAcqPeriodWithBlankInitialReleaseDateOnPostedSalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Posted Sales FA Release FA-1]
        // [SCENARIO 377339] "Actual Acquisition Period" should be equal '0 months' in Posted Sales FA Release Act report if "Initial Release Date" of Fixed Asset is blank

        Initialize();
        // [GIVEN] Fixed Asset with zero "Initial Release Date"
        MockFAWithZeroInitialReleaseDate(FixedAsset);

        // [GIVEN] Posted Sales FA Release Act
        MockPostedSalesInvoice(SalesInvHeader, FixedAsset."No.");

        // [WHEN] Run Posted Sales FA Release Act Report
        RunPostedSalesReleaseActReport(SalesInvHeader);

        // [THEN] Actual use = '0 months' in Posted Sales FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('Y', 61, 2, ZeroMonthsTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMonthsCalculatedFromYearsOnPostedSalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesInvHeader: Record "Sales Invoice Header";
        NoOfDeprYears: Decimal;
    begin
        // [FEATURE] [Sales] [Posted Sales FA Release FA-1]
        // [SCENARIO 377339] "No of months" should be calculated as "No of years" multiplied by 12 when no value is defined in Posted Sales FA Release Act

        Initialize();
        // [GIVEN] Fixed Asset with "No. of Depreciation Years" = 2, "No. of Depreciation Months" = 0
        NoOfDeprYears := MockFAWithNoOfDeprYearsAndZeroNoOfDeprMonths(FixedAsset);

        // [GIVEN] Posted Sales FA Release Act
        MockPostedSalesInvoice(SalesInvHeader, FixedAsset."No.");

        // [WHEN] Run Posted Sales FA Release Act Report
        RunPostedSalesReleaseActReport(SalesInvHeader);

        // [THEN] "No. of months" = 24 in Posted Sales FA Release Act
        LibraryReportValidation.VerifyCellValueByRef('BU', 61, 2, Format(NoOfDeprYears * 12, 0, DecimalFormatWithPlacesTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseAct_DeprBookLineIsEmptyInCaseOfZeroAmounts()
    var
        FixedAsset: Record "Fixed Asset";
        FADocHeader: Record "FA Document Header";
    begin
        // [FEATURE]  [FA Release Act FA-1]
        // [SCENARIO 382230] Depreciation Book line is empty (FA Release Act - Sheet2 - Table1) in case of zero depreciation amount
        Initialize();

        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" with zero depreciation amount, "FABook2"
        // [GIVEN] FA Release Act with line: "Depreciation Book Code" = "FABook1", "New Depreciation Book Code" = "FABook2"
        MockFAWithMultipleDeprBooksWithEmptyDeprAmount(FixedAsset);
        MockFADocument(FADocHeader, FixedAsset."No.");

        // [WHEN] Run "FA Release Act FA-1" report
        RunFAReleaseActReport(FADocHeader);

        // [THEN] FA Release Act -> Sheet2 -> Table1 -> Fields1-8 are empty
        VerifyEmptyFADeprBookLineValues();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedReleaseAct_DeprBookLineIsEmptyInCaseOfZeroAmounts()
    var
        FixedAsset: Record "Fixed Asset";
        PostedFADocHeader: Record "Posted FA Doc. Header";
    begin
        // [FEATURE]  [FA Posted Release Act FA-1]
        // [SCENARIO 382230] Depreciation Book line is empty (FA Posted Release Act FA-1 - Sheet2 - Table1) in case of zero depreciation amount
        Initialize();

        // [GIVEN] Fixed Asset with FA Depreciation Books: "FABook1" with zero depreciation amount, "FABook2"
        // [GIVEN] Posted FA Release Act with line: "Depreciation Book Code" = "FABook1", "New Depreciation Book Code" = "FABook2"
        MockFAWithMultipleDeprBooksWithEmptyDeprAmount(FixedAsset);
        MockPostedFADocument(PostedFADocHeader, FixedAsset);

        // [WHEN] Run "FA Posted Release Act FA-1" report
        RunPostedFAReleaseActReport(PostedFADocHeader);

        // [THEN] FA Posted Release Act FA-1 -> Sheet2 -> Table1 -> Fields1-8 are empty
        VerifyEmptyFADeprBookLineValues();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Sales_DeprBookLineIsPrintedInCaseOfZeroAmounts()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Sales FA Release FA-1]
        // [SCENARIO 381676] Depreciation Book line is printed (Sales FA Release FA-1 - Sheet2 - Table1) in case of zero amounts
        Initialize();

        // [GIVEN] Fixed Asset "FA" with FA Depreciation Book "FABook1" with zero acquisition, depreciation amounts
        // [GIVEN] Sales Invoice with a line: "Type" = "FA", "Depreciation Book Code" = "FABook1"
        MockFAWithMultipleDeprBooksWithEmptyDeprAmount(FixedAsset);
        MockSalesInvoice(SalesHeader, FixedAsset."No.");

        // [WHEN] Run "Sales FA Release FA-1" report
        RunSalesReleaseActReport(SalesHeader);

        // [THEN] Sales FA Release FA-1 -> Sheet2 -> Table1 -> Fields1-8 are filled with zero amounts
        VerifyFA1ReportValues(
          FixedAsset, SalesHeader."No.", SalesHeader."Document Date",
          SalesHeader."No.", SalesHeader."Posting Date", SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSales_DeprBookLineIsPrintedInCaseOfZeroAmounts()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Posted Sales FA Release FA-1]
        // [SCENARIO 381676] Depreciation Book line is printed (Posted Sales FA Release FA-1 - Sheet2 - Table1) in case of zero amounts
        Initialize();

        // [GIVEN] Fixed Asset "FA" with FA Depreciation Book "FABook1" with zero acquisition, depreciation amounts
        // [GIVEN] Posted Sales Invoice with a line: "Type" = "FA", "Depreciation Book Code" = "FABook1"
        MockFAWithMultipleDeprBooksWithEmptyDeprAmount(FixedAsset);
        MockSalesInvoice(SalesHeader, FixedAsset."No.");

        // [WHEN] Run "Posted Sales FA Release FA-1" report
        RunSalesReleaseActReport(SalesHeader);

        // [THEN] Posted Sales FA Release FA-1 -> Sheet2 -> Table1 -> Fields1-8 are filled with zero zmounts
        VerifyFA1ReportValues(
          FixedAsset, SalesHeader."No.", SalesHeader."Document Date",
          SalesHeader."No.", SalesHeader."Posting Date", SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FA1Helper_CalcDepreciationRate_ZeroValues()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FA1ReportHelper: Codeunit "FA-1 Report Helper";
    begin
        // [SCENARIO 382230] COD 14946 "FA-1 Report Helper".CalcDepreciationRate() returns 0 in case of zero "No. of Depreciation Years" and "Straight-Line %"
        FADepreciationBook.Init();
        FADepreciationBook."No. of Depreciation Years" := 0;
        FADepreciationBook."Straight-Line %" := 0;
        Assert.AreEqual(
          0, FA1ReportHelper.CalcDepreciationRate(FADepreciationBook), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FA1Helper_CalcDepreciationRate_ZeroNoOfYears()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FA1ReportHelper: Codeunit "FA-1 Report Helper";
    begin
        // [SCENARIO 382230] COD 14946 "FA-1 Report Helper".CalcDepreciationRate() returns "Straight-Line %" in case of zero "No. of Depreciation Years"
        FADepreciationBook.Init();
        FADepreciationBook."No. of Depreciation Years" := 0;
        FADepreciationBook."Straight-Line %" := LibraryRandom.RandDecInRange(1, 99, 2);
        Assert.AreEqual(
          FADepreciationBook."Straight-Line %", FA1ReportHelper.CalcDepreciationRate(FADepreciationBook), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FA1Helper_CalcDepreciationRate_NoOfYears()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FA1ReportHelper: Codeunit "FA-1 Report Helper";
    begin
        // [SCENARIO 382230] COD 14946 "FA-1 Report Helper".CalcDepreciationRate() returns 100% / (12 * "No. of Depreciation Years") in case of "No. of Depreciation Years" <> 0
        FADepreciationBook.Init();
        FADepreciationBook."No. of Depreciation Years" := LibraryRandom.RandDecInRange(1, 99, 2);
        FADepreciationBook."Straight-Line %" := LibraryRandom.RandDecInRange(1, 99, 2);
        Assert.AreEqual(
          Round(100 / (12 * FADepreciationBook."No. of Depreciation Years"), 0.01),
          FA1ReportHelper.CalcDepreciationRate(FADepreciationBook), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FA1Helper_IsPrintFADeprBookLine_ZeroDeprAmount()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FA1ReportHelper: Codeunit "FA-1 Report Helper";
    begin
        // [SCENARIO 382230] COD 14946 "FA-1 Report Helper".IsPrintFADeprBookLine() returns FALSE in case of zero Depreciation amount
        MockFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        Assert.AreEqual(false, FA1ReportHelper.IsPrintFADeprBookLine(FADepreciationBook), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FA1Helper_IsPrintFADeprBookLine_DeprAmount()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FA1ReportHelper: Codeunit "FA-1 Report Helper";
    begin
        // [SCENARIO 382230] COD 14946 "FA-1 Report Helper".IsPrintFADeprBookLine() returns TRUE in case of non-zero Depreciation amount
        MockFixedAsset(FixedAsset);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        FADepreciationBook.Validate(Depreciation, LibraryRandom.RandDec(100, 2));
        Assert.AreEqual(true, FA1ReportHelper.IsPrintFADeprBookLine(FADepreciationBook), '');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        RemoveMandatorySignSetup();

        isInitialized := true;
    end;

    local procedure CreateVerifyFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        FADocHeader: Record "FA Document Header";
    begin
        Initialize();
        MockFAWithMultipleDeprBooks(FixedAsset);
        MockFADocument(FADocHeader, FixedAsset."No.");
        RunFAReleaseActReport(FADocHeader);
        VerifyFA1ReportValues(
          FixedAsset, FADocHeader."Reason Document No.", FADocHeader."Reason Document Date",
          FADocHeader."No.", FADocHeader."Posting Date", FADocHeader."FA Posting Date");
    end;

    local procedure CreateVerifyPostedFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        PostedFADocHeader: Record "Posted FA Doc. Header";
    begin
        Initialize();
        MockFAWithMultipleDeprBooks(FixedAsset);
        MockPostedFADocument(PostedFADocHeader, FixedAsset);
        RunPostedFAReleaseActReport(PostedFADocHeader);
        VerifyFA1ReportValues(
          FixedAsset, PostedFADocHeader."Reason Document No.", PostedFADocHeader."Reason Document Date",
          PostedFADocHeader."No.", PostedFADocHeader."Posting Date", PostedFADocHeader."FA Posting Date");
    end;

    local procedure CreateVerifySalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        MockFAWithMultipleDeprBooks(FixedAsset);
        MockSalesInvoice(SalesHeader, FixedAsset."No.");
        RunSalesReleaseActReport(SalesHeader);
        VerifyFA1ReportValues(
          FixedAsset, SalesHeader."No.", SalesHeader."Document Date",
          SalesHeader."No.", SalesHeader."Posting Date", SalesHeader."Posting Date");
    end;

    local procedure CreateVerifyPostedSalesFAReleaseAct()
    var
        FixedAsset: Record "Fixed Asset";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        Initialize();
        MockFAWithMultipleDeprBooks(FixedAsset);
        MockPostedSalesInvoice(SalesInvHeader, FixedAsset."No.");
        RunPostedSalesReleaseActReport(SalesInvHeader);
        VerifyFA1ReportValues(
          FixedAsset, SalesInvHeader."No.", SalesInvHeader."Document Date",
          SalesInvHeader."No.", SalesInvHeader."Posting Date", SalesInvHeader."Posting Date");
    end;

    local procedure MockFAWithZeroInitialReleaseDate(var FixedAsset: Record "Fixed Asset")
    begin
        MockFAWithMultipleDeprBooks(FixedAsset);
        FixedAsset."Initial Release Date" := 0D;
        FixedAsset.Modify();
    end;

    local procedure MockFAWithNoOfDeprYearsAndZeroNoOfDeprMonths(var FixedAsset: Record "Fixed Asset"): Decimal
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
    begin
        MockFAWithMultipleDeprBooks(FixedAsset);
        FASetup.Get();
        FADeprBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADeprBook."No. of Depreciation Months" := 0;
        FADeprBook.Modify();
        exit(FADeprBook."No. of Depreciation Years");
    end;

    local procedure MockFAWithMultipleDeprBooks(var FixedAsset: Record "Fixed Asset")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        MockFixedAsset(FixedAsset);
        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.FindSet();
        repeat
            LibraryRUReports.MockFADepreciationBook(FADeprBook);
        until FADeprBook.Next() = 0;
    end;

    local procedure MockFAWithMultipleDeprBooksWithEmptyDeprAmount(var FixedAsset: Record "Fixed Asset")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        MockFixedAsset(FixedAsset);
        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.FindSet();
        repeat
            FADeprBook.Validate("Depreciation Starting Date", CalcDate('<-CY>', WorkDate()));
            FADeprBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(10));
            FADeprBook.Validate("Disposal Date", LibraryRandom.RandDate(100));
            FADeprBook.Validate("Acquisition Date", LibraryRandom.RandDate(100));
            FADeprBook.Validate("G/L Acquisition Date", LibraryRandom.RandDate(100));
            FADeprBook.Validate("FA Posting Group", LibraryRUReports.MockFAPostingGroup());
            FADeprBook.Validate("Depreciation Method", FADeprBook."Depreciation Method"::"Straight-Line");
            FADeprBook.Validate("Book Value", LibraryRandom.RandDec(100, 2));
            FADeprBook.Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
            FADeprBook.Validate("Initial Acquisition Cost", LibraryRandom.RandDec(100, 2));
            FADeprBook.Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
            FADeprBook.Modify(true);
        until FADeprBook.Next() = 0;
    end;

    local procedure MockFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset.Init();
        FixedAsset."No." := LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("No."), DATABASE::"Fixed Asset");
        FixedAsset.Insert();
        FixedAsset.Description := LibraryUtility.GenerateGUID();
        FixedAsset."Description 2" := LibraryUtility.GenerateGUID();
        FixedAsset.Manufacturer := LibraryUtility.GenerateGUID();
        FixedAsset."Initial Release Date" := WorkDate();
        FixedAsset."FA Location Code" := LibraryRUReports.MockFALocation();
        FixedAsset."Depreciation Code" := LibraryRUReports.MockDepreciationCode();
        FixedAsset."Depreciation Group" := LibraryRUReports.MockDepreciationGroup();
        FixedAsset."Inventory Number" := LibraryUtility.GenerateGUID();
        FixedAsset."Factory No." := LibraryUtility.GenerateGUID();
        FixedAsset."Manufacturing Year" := Format(Date2DMY(WorkDate(), 3));
        FixedAsset.Modify();
        FixedAsset.InitFADeprBooks(FixedAsset."No.");
    end;

    local procedure MockFADocument(var FADocHeader: Record "FA Document Header"; FANo: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        MockFAHeader(FADocHeader);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        MockFALine(FADocHeader, FADepreciationBook)
    end;

    local procedure MockFAHeader(var FADocHeader: Record "FA Document Header")
    begin
        FADocHeader.Init();
        FADocHeader."Document Type" := FADocHeader."Document Type"::Release;
        FADocHeader."No." := LibraryUtility.GenerateRandomCode(FADocHeader.FieldNo("No."), DATABASE::"FA Document Header");
        FADocHeader.Insert();
        FADocHeader."Reason Document No." := LibraryUtility.GenerateGUID();
        FADocHeader."Reason Document Date" := WorkDate();
        FADocHeader."Posting Date" := WorkDate();
        FADocHeader."FA Posting Date" := LibraryRandom.RandDate(5);
        FADocHeader.Modify();
    end;

    local procedure MockFALine(FADocHeader: Record "FA Document Header"; FADepreciationBook: Record "FA Depreciation Book")
    var
        FADocLine: Record "FA Document Line";
    begin
        FADocLine.Init();
        FADocLine."Document Type" := FADocHeader."Document Type";
        FADocLine."Document No." := FADocHeader."No.";
        FADocLine."Line No." := LibraryUtility.GetNewRecNo(FADocLine, FADocLine.FieldNo("Line No."));
        FADocLine.Insert();
        FADocLine.Validate("FA No.", FADepreciationBook."FA No.");
        FADocLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FADocLine.Validate("New Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FADocLine.Modify();
    end;

    local procedure MockPostedFADocument(var PostedFADocHeader: Record "Posted FA Doc. Header"; FixedAsset: Record "Fixed Asset")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        MockPostedFAHeader(PostedFADocHeader);
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        MockPostedFALine(PostedFADocHeader, FixedAsset, FADepreciationBook)
    end;

    local procedure MockPostedFAHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        PostedFADocHeader.Init();
        PostedFADocHeader."Document Type" := PostedFADocHeader."Document Type"::Release;
        PostedFADocHeader."No." := LibraryUtility.GenerateRandomCode(PostedFADocHeader.FieldNo("No."), DATABASE::"Posted FA Doc. Header");
        PostedFADocHeader.Insert();
        PostedFADocHeader."Reason Document No." := LibraryUtility.GenerateGUID();
        PostedFADocHeader."Reason Document Date" := WorkDate();
        PostedFADocHeader."Posting Date" := WorkDate();
        PostedFADocHeader.Modify();
    end;

    local procedure MockPostedFALine(PostedFADocHeader: Record "Posted FA Doc. Header"; FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book")
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
    begin
        PostedFADocLine.Init();
        PostedFADocLine."Document Type" := PostedFADocHeader."Document Type";
        PostedFADocLine."Document No." := PostedFADocHeader."No.";
        PostedFADocLine."Line No." := LibraryUtility.GetNewRecNo(PostedFADocLine, PostedFADocLine.FieldNo("Line No."));
        PostedFADocLine.Insert();
        PostedFADocLine."FA No." := FixedAsset."No.";
        PostedFADocLine."Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        PostedFADocLine."New Depreciation Book Code" := FADepreciationBook."Depreciation Book Code";
        PostedFADocLine."FA Posting Group" := FADepreciationBook."FA Posting Group";
        PostedFADocLine."FA Location Code" := FixedAsset."FA Location Code";
        PostedFADocLine.Modify();
    end;

    local procedure MockSalesInvoice(var SalesHeader: Record "Sales Header"; FANo: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        MockSalesHeader(SalesHeader);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        MockSalesLine(SalesHeader, FANo, FADepreciationBook);
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader.Insert();
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader.Modify();
    end;

    local procedure MockSalesLine(SalesHeader: Record "Sales Header"; FANo: Code[20]; FADeprBook: Record "FA Depreciation Book")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
        SalesLine.Type := SalesLine.Type::"Fixed Asset";
        SalesLine."No." := FANo;
        SalesLine."Depreciation Book Code" := FADeprBook."Depreciation Book Code";
        SalesLine."Posting Group" := FADeprBook."FA Posting Group";
        SalesLine.Modify();
    end;

    local procedure MockPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; FANo: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        MockPostedSalesHeader(SalesInvHeader);
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        MockPostedSalesLine(SalesInvHeader, FANo, FADepreciationBook);
    end;

    local procedure MockPostedSalesHeader(var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvHeader.Init();
        SalesInvHeader."No." := LibraryUtility.GenerateRandomCode(SalesInvHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        SalesInvHeader.Insert();
        SalesInvHeader."Posting Date" := WorkDate();
        SalesInvHeader.Modify();
    end;

    local procedure MockPostedSalesLine(SalesInvHeader: Record "Sales Invoice Header"; FANo: Code[20]; FADeprBook: Record "FA Depreciation Book")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Init();
        SalesInvLine."Document No." := SalesInvHeader."No.";
        SalesInvLine."Line No." := LibraryUtility.GetNewRecNo(SalesInvLine, SalesInvLine.FieldNo("Line No."));
        SalesInvLine.Insert();
        SalesInvLine.Type := SalesInvLine.Type::"Fixed Asset";
        SalesInvLine."No." := FANo;
        SalesInvLine."Depreciation Book Code" := FADeprBook."Depreciation Book Code";
        SalesInvLine."Posting Group" := FADeprBook."FA Posting Group";
        SalesInvLine.Modify();
    end;

    local procedure RemoveMandatorySignSetup()
    var
        DefaultSignSetup: Record "Default Signature Setup";
    begin
        DefaultSignSetup.SetFilter(
          "Table ID", '%1|%2|%3|%4', DATABASE::"Sales Header", DATABASE::"Sales Line",
            DATABASE::"FA Document Header", DATABASE::"FA Document Line");
        DefaultSignSetup.SetRange(Mandatory, true);
        DefaultSignSetup.DeleteAll(true);
    end;

    local procedure RunFAReleaseActReport(FADocHeader: Record "FA Document Header")
    var
        FAReleaseActRep: Report "FA Release Act FA-1";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter();
        FAReleaseActRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAReleaseActRep.SetTableView(FADocHeader);
        FAReleaseActRep.UseRequestPage(false);
        FAReleaseActRep.Run();
    end;

    local procedure RunPostedFAReleaseActReport(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAReleaseActRep: Report "FA Posted Release Act FA-1";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter();
        PostedFAReleaseActRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedFAReleaseActRep.SetTableView(PostedFADocHeader);
        PostedFAReleaseActRep.UseRequestPage(false);
        PostedFAReleaseActRep.Run();
    end;

    local procedure RunSalesReleaseActReport(SalesHeader: Record "Sales Header")
    var
        SalesFAReleaseRep: Report "Sales FA Release FA-1";
    begin
        LibraryReportValidation.SetFileName(SalesHeader."No.");
        SalesHeader.SetRecFilter();
        SalesFAReleaseRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        SalesFAReleaseRep.SetTableView(SalesHeader);
        SalesFAReleaseRep.UseRequestPage(false);
        SalesFAReleaseRep.Run();
    end;

    local procedure RunPostedSalesReleaseActReport(SalesInvHeader: Record "Sales Invoice Header")
    var
        PostedSalesFAReleaseRep: Report "Posted Sales FA Release FA-1";
    begin
        LibraryReportValidation.SetFileName(SalesInvHeader."No.");
        SalesInvHeader.SetRecFilter();
        PostedSalesFAReleaseRep.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedSalesFAReleaseRep.SetTableView(SalesInvHeader);
        PostedSalesFAReleaseRep.UseRequestPage(false);
        PostedSalesFAReleaseRep.Run();
    end;

    local procedure VerifyFA1ReportValues(FixedAsset: Record "Fixed Asset"; ReasonDocNo: Code[20]; ReasonDocDate: Date; DocNo: Code[20]; DocDate: Date; FADocDate: Date)
    var
        FADeprBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryReportValidation.VerifyCellValue(24, 88, ReasonDocNo);
        LibraryReportValidation.VerifyCellValue(26, 88, Format(ReasonDocDate));
        LibraryReportValidation.VerifyCellValue(32, 36, DocNo);
        LibraryReportValidation.VerifyCellValue(32, 49, Format(DocDate));

        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.FindFirst();
        FAPostingGroup.Get(FADeprBook."FA Posting Group");

        LibraryReportValidation.VerifyCellValue(28, 88, Format(FADocDate));
        LibraryReportValidation.VerifyCellValue(29, 88, Format(FADeprBook."Disposal Date"));
        LibraryReportValidation.VerifyCellValue(30, 88, FAPostingGroup."Acquisition Cost Account");
        LibraryReportValidation.VerifyCellValue(31, 88, FixedAsset."Depreciation Code");
        LibraryReportValidation.VerifyCellValue(32, 88, FixedAsset."Depreciation Group");
        LibraryReportValidation.VerifyCellValue(33, 88, FixedAsset."Inventory Number");
        LibraryReportValidation.VerifyCellValue(34, 88, FixedAsset."Factory No.");

        VerifyRepDocLineValues(FixedAsset);
        VerifyRepFADeprBookLineValues(FixedAsset."No.");
    end;

    local procedure VerifyRepDocLineValues(FixedAsset: Record "Fixed Asset")
    begin
        LibraryReportValidation.VerifyCellValueByRef('A', 61, 2, FixedAsset."Manufacturing Year");
        LibraryReportValidation.VerifyCellValueByRef('I', 61, 2, Format(FixedAsset."Initial Release Date"));
        LibraryReportValidation.VerifyCellValueByRef('Y', 61, 2, ZeroMonthsTxt);
    end;

    local procedure VerifyRepFADeprBookLineValues(FANo: Code[20])
    var
        FADeprBook: Record "FA Depreciation Book";
        NoOfDeprMonths: Decimal;
        DecimalValue: Decimal;
    begin
        FADeprBook.SetRange("FA No.", FANo);
        FADeprBook.FindFirst();
        FADeprBook.CalcFields("Acquisition Cost", "Initial Acquisition Cost", Depreciation);
        Evaluate(NoOfDeprMonths, LibraryReportValidation.GetValueByRef('AG', 61, 2));
        Assert.AreEqual(
          Format(FADeprBook."No. of Depreciation Months", 0, DecimalFormatWithPlacesTxt),
          Format(NoOfDeprMonths, 0, DecimalFormatWithPlacesTxt), IncorrectCellValueErr);
        DecimalValue := FADeprBook.Depreciation;
        LibraryReportValidation.VerifyCellValueByRef('AO', 61, 2, Format(DecimalValue, 0, 9));
        DecimalValue := FADeprBook."Book Value";
        LibraryReportValidation.VerifyCellValueByRef('AW', 61, 2, Format(DecimalValue, 0, 9));
        DecimalValue := FADeprBook."Acquisition Cost";
        LibraryReportValidation.VerifyCellValueByRef('BE', 61, 2, Format(DecimalValue, 0, 9));
        DecimalValue := FADeprBook."Initial Acquisition Cost";
        LibraryReportValidation.VerifyCellValueByRef('BM', 61, 2, Format(DecimalValue, 0, 9));
        LibraryReportValidation.VerifyCellValueByRef('CC', 61, 2, Format(FADeprBook."Depreciation Method"));
        LibraryReportValidation.VerifyCellValueByRef('CO', 61, 2, Format(Round(100 / (12 * FADeprBook."No. of Depreciation Years"), 0.01)));
    end;

    local procedure VerifyEmptyFADeprBookLineValues()
    begin
        LibraryReportValidation.VerifyEmptyCellByRef('A', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('I', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('Q', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('Y', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('AG', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('AO', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('AW', 61, 2);
        LibraryReportValidation.VerifyEmptyCellByRef('BE', 61, 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure CopyServerFileToTargetOnBeforeDownloadHandler(ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
    begin
        // In containers the client-side Download does not materialize the exported report file at the
        // server session path the test reads, so copy the server-side source file to the target path.
        if (FromFileName = '') or (ToFileName = '') then
            exit;
        if not FileManagement.ServerFileExists(FromFileName) then
            exit;
        FileManagement.CopyServerFile(FromFileName, ToFileName, true);
        IsHandled := true;
    end;
}
