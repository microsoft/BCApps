codeunit 142060 "ERM Sales/Purchase Report"
{
    // Test- Various Test cases of Sales or Purchase Reports.
    // 1.  Verify Posted Sales Documents created from Sales Posting Batch Job.
    // 2.  Verify Company Information and Dimension on Sales Invoice Report.
    // 3.  Verify Company Information and Dimension on Sales Credit Memo Report.
    // 4.  Verify Registration Number of Vendor in Purchase Header Archive.
    // 5.  Verify Company Information, Registration Number and Dimension on Purchase Credit Memo Report.
    // 6.  Verify Purchase Credit Memo Report with Number of Copies filter.
    // 7.  Verify Purchase Credit Memo Report with Pay To Vendor Number filter.
    // 8.  Verify Purchase Credit Memo Report with Buy From Vendor Number filter.
    // 9.  Verify Purchase Credit Memo Report with Posting Date filter.
    // 10. Verify Purchase Credit Memo Report with Vendor Credit Memo Number filter.
    // 11. Verify Vendor Detailed Aging Report without any Vendor No. filter.
    // 12. Verify Vendor Detailed Aging Report with one Vendor No. as filter.
    // 13. Verify Vendor Detailed Aging Report with Vendor No. range as filter.
    // 14. Verify Crossborder Services report with 'Statistic On' as 'Type of Service' and Additional Reporting Currency FALSE.
    // 15. Verify Crossborder Services report with 'Statistic On' as Countries and Additional Reporting Currency FALSE.
    // 16. Verify Crossborder Services report with 'Statistic On' as Both and Additional Reporting Currency FALSE.
    // 17. Verify Crossborder Services report with 'Statistic On' as 'Type of Service' and Additional Reporting Currency TRUE.
    // 18. Verify Crossborder Services report with 'Statistic On' as Countries and Additional Reporting Currency TRUE.
    // 19. Verify Crossborder Services report with 'Statistic On' as Both and Additional Reporting Currency TRUE.
    // 20. Verify Crossborder Services report with Posting Date Filter.
    // 21. Verify Crossborder Services report with Country Region Filter.
    // 22. Verify Crossborder Services report with General Product Posting Group Filter.
    // 23. Verify Crossborder Services report with Posting Date and Country Region Filter.
    // 24. Verify Crossborder Services report with Posting Date, Country Region Filter and General Product Posting Group.
    //
    // Covers Test cases: for WI - 326566
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // SalesOrderWithSalesPostingBatchJob                                                                151814
    //
    // Covers Test cases: for WI - 326564
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // SalesOrderWithSalesInvoiceReport, SalesCrMemowithSalesCreditMemoReport                            151815
    // PurchaseOrderWithVendRegistrationNumber,
    // PurchCrMemowithPurchaseCreditMemoReport                                      151817,152696,153189,153192
    //
    // Covers Test cases: for WI - 326565
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // PurchCreditMemoReportWithNoOfCopiesFilter                                                         153193
    // PurchCreditMemoReportWithPayToVendNoFilter                                                        153199
    // PurchCreditMemoReportWithBuyFromVendFilter                                                        153202
    // PurchCreditMemoReportWithPostingDateFilter                                                        153205
    // PurchCreditMemoReportWithVendCrMemoNoFilter                                                       153208
    //
    // Covers Test cases: for WI - 326561
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // VendDtldAgingReportWithoutVendorFilter, VendDtldAgingReportWithVendorNoFilter
    // VendDtldAgingReportWithVendorNoRangeFilter                                    152918,152919,152920,152921
    //
    // Covers Test cases: for WI - 326538
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // CrossborderServicesWithTypeOfServices                                                             153166
    // CrossborderServicesWithCountries                                                                  153165
    // CrossborderServicesWithBoth                                                                       153167
    // CrossborderServicesWithTypeOfServicesInFCY                                                        153169
    // CrossborderServicesWithCountriesInFCY                                                             153168
    // CrossborderServicesWithBothInFCY                                                                  153170
    //
    // Covers Test cases: for WI - 326558
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // CrossborderServicesWithPostingDateFilter                                                          153171
    // CrossborderServicesWithCountryRegionFilter                                                        153172
    // CrossborderServicesWithGenProdPostingGroupFilter                                                  153173
    // CrossborderServicesWithPostingDateAndCountryRegionFilter                                          153174
    // CrossborderServicesWithMultipleFilters                                                            153175

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        BuyFromVendCaption: Label 'BuyfromVendNo_PurchCrMemoHdr';
        CompanyInfoVATRegNo: Label 'CompanyInfoVATRegNo';
        CountryRegionCodeCaption: Label 'VATEntryCountry__Country_Region_Code_';
        CurrencyString: Label 'All amounts are in %1.';
        FilterValue: Label 'No.: %1';
        FilterText: Label 'VAT Entry: %1: %2';
        FilterTextCaption: Label 'FilterText';
        GenProdPostingGroupCaption: Label 'VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_';
        HeaderTextCaption: Label 'HeaderText';
        MultipleFilters: Label 'VAT Entry: Gen. Prod. Posting Group: %1, Posting Date: %2, Country/Region Code: %3';
        OutputNoCaption: Label 'OutputNo';
        PayToVendorCaption: Label 'PaytoVendNo_PurchCrMemoHdr';
        PostingDateCaption: Label 'PostingDate_PurchCrMemoHdr';
        PurchCrMemoHdrRegNoCaption: Label 'RegNo_PurchCrMemoHdr';
        PurchFromVendorCaption: Label 'PurchFromVend';
        PurchFromVendorControlCaption: Label 'PurchFromVend_Control1160025';
        PurchHdrDimensionText: Label 'DimText_DimensionLoop1';
        PostingDateCountryCodeFilter: Label 'VAT Entry: Posting Date: %1, Country/Region Code: %2';
        QuantityCaption: Label 'Quantity_PurchCrMemoLine';
        RangeFilter: Label '%1|%2';
        RegistrationNoCaption: Label 'RegNoText';
        RemainingAmountCaption: Label 'CurrTotalBuffer2TotAmt';
        SalesToCustomerCaption: Label 'SalesToCust';
        SalesToCustomerControlCaption: Label 'SalesToCust_Control1160023';
        VendFilterCaption: Label 'VendFilter';
        DescriptionContainDateErr: Label 'In %1 field %2 does not conatin any date', Comment = '%1 - Table Caption, %2 - Field Caption';
        ShipmentNoLbl: Label 'Shipment No. %1:', Comment = '%1 - Sales Shipment No.';
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        isInitialized: Boolean;
        No_SalesShipmentLine_XPathTok: Label '/ReportDataSet/DataItems/DataItem/DataItems/DataItem/DataItems/DataItem/DataItems/DataItem/Columns/Column[@name=''No_SalesShptLine'']';
        OrderNo_StandardSalesInvoice_XPathTok: Label '/ReportDataSet/DataItems/DataItem/Columns/Column[@name=''OrderNo'']';

    [Test]
    [HandlerFunctions('BatchPostSalesOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithSalesPostingBatchJob()
    var
        SalesHeader: Record "Sales Header";
        SalesOrders: TestPage "Sales Order List";
    begin
        // Verify Posted Sales Documents created from Sales Posting Batch Job.

        // Setup: Create Sales Order.
        Initialize();
        LibrarySales.SetPostAndPrintWithJobQueue(false);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithDimension());
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue value for BatchPostSalesOrdersRequestPageHandler.
        LibraryVariableStorage.Enqueue(false); // do not print
        SalesOrders.OpenEdit();
        SalesOrders.FILTER.SetFilter("No.", SalesHeader."No.");
        Commit();  // COMMIT is required for run Sales Posting Batch Job Report.

        // Exercise: Run Sales Posting Batch Job Report.
        SalesOrders."Post &Batch".Invoke();  // Control is using to run Sales Posting Batch Job Report.

        // Verify: Verify Posted Sales Shipment and posted Sales Invoice.
        VerifyPostedSalesDocument(SalesHeader."No.", SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithVendRegistrationNumber()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Verify Registration Number of Vendor in Purchase Header Archive.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithDimension());
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // Exercise: Post Purchase Order as Ship and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Registration Number in Purchase Header Archive.
        VerifyPurchaseHeaderArchive(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemowithPurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        OptionValue: Option No;
    begin
        // Verify Company Information, Registration Number and Dimension on Purchase Credit Memo Report.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendorWithDimension());
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(OptionValue::No);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.

        // Exercise: Run Purchase Credit Memo Report.
        REPORT.Run(REPORT::"Purchase - Credit Memo");

        // Verify: Verify Company Information, Dimension and Registration Number on Purchase Credit Memo Report.
        VerifyCompanyInfoAndDocHdrDim(
          PurchaseHeader."Dimension Set ID", PurchaseHeader."Shortcut Dimension 1 Code", PurchHdrDimensionText, CompanyInfoVATRegNo);
        VerifyPurchaseCreditMemoRegistrationNo(PurchaseHeader.FieldCaption("Registration No."), PurchaseHeader."Registration No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithNoOfCopiesFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        NumberOfCopies: Variant;
        GeneratedPageValue: Integer;
        OptionString: Option No,NoOfCopies;
    begin
        // Verify Purchase Credit Memo Report with Number of Copies filter.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LibraryVariableStorage.Enqueue(OptionString::NoOfCopies);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.

        // Exercise: Run Purchase Credit Memo Report.
        REPORT.Run(REPORT::"Purchase - Credit Memo");

        // Verify: Verify Number of copies on Purchase Credit Memo Report.
        LibraryVariableStorage.Dequeue(NumberOfCopies);  // Dequeue variable.
        GeneratedPageValue := NumberOfCopies;
        VerifyElementWithValue(OutputNoCaption, GeneratedPageValue + 1)
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithPayToVendNoFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        OptionString: Option No,NoOfCopies,PayToVendNo;
    begin
        // Verify Purchase Credit Memo Report with Pay To Vendor Number filter.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();

        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LibraryVariableStorage.Enqueue(OptionString::PayToVendNo);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Pay-to Vendor No.");  // Enqueue value for PurchaseCreditMemoRequestPageHandler.

        // Exercise and Verification: Run Purchase Credit Memo Report. Verify Pay To Vendor Number on Purchase Credit Memo Report.
        RunCreditMemoReportAndVerify(PayToVendorCaption, PurchaseHeader."Pay-to Vendor No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithBuyFromVendFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        OptionString: Option No,NoOfCopies,PayToVendNo,BuyFromVendNo;
    begin
        // Verify Purchase Credit Memo Report with Buy From Vendor Number filter.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendorWithDimension());
        UpdatePurchHdrPayToVendorNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(OptionString::BuyFromVendNo);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");  // Enqueue value for PurchaseCreditMemoRequestPageHandler.

        // Exercise and Verification: Run Purchase Credit Memo Report. Verify Buy From Vendor Number on Purchase Credit Memo Report.
        RunCreditMemoReportAndVerify(BuyFromVendCaption, PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithPostingDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        OptionString: Option No,NoOfCopies,PayToVendNo,BuyFromVendNo,PostingDate;
    begin
        // Verify Purchase Credit Memo Report with Posting Date filter.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LibraryVariableStorage.Enqueue(OptionString::PostingDate);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.

        // Exercise and Verification: Run Purchase Credit Memo Report. Verify Posting Date on Purchase Credit Memo Report.
        RunCreditMemoReportAndVerify(PostingDateCaption, Format(PurchaseHeader."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithVendCrMemoNoFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        OptionString: Option No,NoOfCopies,PayToVendNo,BuyFromVendNo,PostingDate,VendCrMemoNo;
    begin
        // Verify Purchase Credit Memo Report with Vendor Credit Memo Number filter.

        // Setup: Create and post Purchase Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LibraryVariableStorage.Enqueue(OptionString::VendCrMemoNo);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Vendor Cr. Memo No.");  // Enqueue value for PurchaseCreditMemoRequestPageHandler.
        PurchCrMemoLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoLine.FindFirst();

        // Exercise and Verification: Run Purchase Credit Memo Report. Verify Quantity on Purchase Credit Memo Report.
        RunCreditMemoReportAndVerify(QuantityCaption, PurchCrMemoLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithoutVendorFilter()
    begin
        // Verify Vendor Detailed Aging Report without any Vendor No. filter.

        // Setup.
        Initialize();

        // Needed to close any write transactions before running report.
        Commit();

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(WorkDate(), '', '');  // Blank values for Vendor No.
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithVendorNoFilter()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Vendor Detailed Aging Report with one Vendor No. as filter.

        // Setup: Create and post Purchase Invoice.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(
          PurchaseHeader."Due Date", PurchaseHeader."Buy-from Vendor No.", StrSubstNo(FilterValue, PurchaseHeader."Buy-from Vendor No."));
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithVendorNoRangeFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Verify Vendor Detailed Aging Report with Vendor No. range as filter.

        // Setup: Create and post Purchase Invoice for different Vendors.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateAndPostPurchaseDocument(PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice);

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(
          PurchaseHeader."Due Date", StrSubstNo(RangeFilter, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No."),
          StrSubstNo(FilterValue, StrSubstNo(RangeFilter, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.")));
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithTypeOfServices()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as 'Type of Service' and Additional Reporting Currency FALSE.

        // Setup and Exercise.
        PostSalesOrderAndRunCrossBorderServiceReport(SalesLine, StatisticOn::"Type of Service");

        // Verify: Verify type of Service and Sales Amount on Crossborder Services report.
        GeneralLedgerSetup.Get();
        VerifyCrossBorderServiceReport(
          GeneralLedgerSetup."LCY Code", GenProdPostingGroupCaption, SalesLine."Gen. Prod. Posting Group", SalesToCustomerControlCaption,
          Round(SalesLine."Line Amount", 1));  // Taken 1 for Precision as specified in base object Crossborder Serivces report.
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithCountries()
    var
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as Countries and Additional Reporting Currency FALSE..
        CrossborderServicesWithAddReportingCurrencyFalse(StatisticOn::Countries);
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithBoth()
    var
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as Both and Additional Reporting Currency FALSE.
        CrossborderServicesWithAddReportingCurrencyFalse(StatisticOn::Both);
    end;

    local procedure CrossborderServicesWithAddReportingCurrencyFalse(StatisticOn: Option)
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
    begin
        // Setup and Exercise.
        PostSalesOrderAndRunCrossBorderServiceReport(SalesLine, StatisticOn);

        // Verify: Verify Country Region code and Sales Amount on Crossborder Services report.
        Customer.Get(SalesLine."Sell-to Customer No.");
        GeneralLedgerSetup.Get();
        VerifyCrossBorderServiceReport(
          GeneralLedgerSetup."LCY Code", CountryRegionCodeCaption, Customer."Country/Region Code", SalesToCustomerCaption,
          Round(SalesLine."Line Amount", 1));  // Taken 1 for Precision as specified in base object Crossborder Serivces report.
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithTypeOfServicesInFCY()
    var
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as 'Type of Service' and Additional Reporting Currency TRUE.

        // Setup: Update General Ledger Setup.
        Initialize();
        CurrencyCode := UpdateGeneralLedgerSetup();

        // Exercise.
        PostPurchOrderAndRunCrossBorderServiceReport(PurchaseLine, StatisticOn::"Type of Service");

        // Verify: Verify type of Service and Purchase Amount on Crossborder Services report.
        VerifyCrossBorderServiceReport(CurrencyCode,
          GenProdPostingGroupCaption, PurchaseLine."Gen. Prod. Posting Group", PurchFromVendorControlCaption,
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", '', CurrencyCode, WorkDate()), 1));  // Taken 1 for Precision as specified in base object Crossborder Serivces report.
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithCountriesInFCY()
    var
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as Countries and Additional Reporting Currency TRUE.
        CrossBorderServicesWithAddReportingCurrencyTrue(StatisticOn::Countries);
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandler')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithBothInFCY()
    var
        StatisticOn: Option Countries,"Type of Service",Both;
    begin
        // Verify Crossborder Services report with 'Statistic On' as Both and Additional Reporting Currency TRUE.
        CrossBorderServicesWithAddReportingCurrencyTrue(StatisticOn::Both);
    end;

    local procedure CrossBorderServicesWithAddReportingCurrencyTrue(StatisticOn: Option)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
    begin
        // Setup: Update General Ledger Setup.
        Initialize();
        CurrencyCode := UpdateGeneralLedgerSetup();

        // Exercise.
        PostPurchOrderAndRunCrossBorderServiceReport(PurchaseLine, StatisticOn);

        // Verify: Verify Country Region code and Purchase Amount on Crossborder Services report.
        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        VerifyCrossBorderServiceReport(
          CurrencyCode, CountryRegionCodeCaption, Vendor."Country/Region Code", PurchFromVendorCaption,
          Round(LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", '', CurrencyCode, WorkDate()), 1));  // Taken 1 for Precision as specified in base object Crossborder Serivces report.
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandlerForFilters')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithPostingDateFilter()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
    begin
        // Verify Crossborder Services report with Posting Date Filter.

        // Setup: Create and post Sales Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        EnqueueValuesForCrossBorderServiceReport(Format(WorkDate()), OptionString::PostingDate, false);  // False for Show Amount in Additional reporting Currency.

        // Exercise and Verification.
        RunAndVerifyCrossborderServicesReport(FilterTextCaption, StrSubstNo(FilterText, SalesHeader.FieldCaption("Posting Date"), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandlerForFilters')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithCountryRegionFilter()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
    begin
        // Verify Crossborder Services report with Country Region Filter.

        // Setup: Create and post Sales Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        Customer.Get(SalesLine."Sell-to Customer No.");
        EnqueueValuesForCrossBorderServiceReport(Customer."Country/Region Code", OptionString::CountryRegion, false);  // False for Show Amount in Additional reporting Currency.

        // Exercise and Verification.
        RunAndVerifyCrossborderServicesReport(
          FilterTextCaption, StrSubstNo(FilterText, Customer.FieldCaption("Country/Region Code"), Customer."Country/Region Code"));
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandlerForFilters')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithGenProdPostingGroupFilter()
    var
        SalesLine: Record "Sales Line";
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
    begin
        // Verify Crossborder Services report with General Product Posting Group Filter.

        // Setup: Create and post Sales Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        EnqueueValuesForCrossBorderServiceReport(SalesLine."Gen. Prod. Posting Group", OptionString::GenProdPostingGroup, false);  // False for Show Amount in Additional reporting Currency.

        // Exercise and Verification.
        RunAndVerifyCrossborderServicesReport(
          FilterTextCaption, StrSubstNo(FilterText, SalesLine.FieldCaption("Gen. Prod. Posting Group"), SalesLine."Gen. Prod. Posting Group"));
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandlerForFilters')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithPostingDateAndCountryRegionFilter()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
    begin
        // Verify Crossborder Services report with Posting Date and Country Region Filter.

        // Setup: Create and post Sales Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        Customer.Get(SalesLine."Sell-to Customer No.");
        EnqueueValuesForCrossBorderServiceReport(Customer."Country/Region Code", OptionString::PostingDateCountryRegion, false);  // False for Show Amount in Additional reporting Currency.

        // Exercise and Verification.
        RunAndVerifyCrossborderServicesReport(
          FilterTextCaption, StrSubstNo(PostingDateCountryCodeFilter, WorkDate(), Customer."Country/Region Code"));
    end;

    [Test]
    [HandlerFunctions('CrossBorderServicesHandlerForFilters')]
    [Scope('OnPrem')]
    procedure CrossborderServicesWithMultipleFilters()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
    begin
        // Verify Crossborder Services report with Posting Date, Country Region and General Product Posting Group Filter.

        // Setup: Create and post Sales Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        Customer.Get(SalesLine."Sell-to Customer No.");
        EnqueueValuesForCrossBorderServiceReport(Customer."Country/Region Code", OptionString::PostingDateCountryRegionGenProdPostingGrp, false);  // False for Show Amount in Additional reporting Currency.
        LibraryVariableStorage.Enqueue(SalesLine."Gen. Prod. Posting Group");  // Enqueue for CrossBorderServicesHandlerForFilters.

        // Exercise and Verification.
        RunAndVerifyCrossborderServicesReport(
          FilterTextCaption, StrSubstNo(MultipleFilters, SalesLine."Gen. Prod. Posting Group", WorkDate(), Customer."Country/Region Code"));
    end;

    [Test]
    [HandlerFunctions('PHVendorDetailedAging')]
    [Scope('OnPrem')]
    procedure VendorDetailedAgingReportWithBlankDueDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 165243] Run Vendor Detailed Aging report when Vendor Ledger Entry has Due Date = 0D
        Initialize();

        // [GIVEN] Create Vendor Ledger Entry with "Due Date" = 0D
        CreateVendorLedgerEntry(VendorLedgerEntry);

        // [WHEN] Run Vendor Detailed Aging report with blank Due Date and Document No. = "D"
        Vendor.SetRange("No.", VendorLedgerEntry."Vendor No.");
        Commit();
        REPORT.Run(REPORT::"Vendor Detailed Aging", true, false, Vendor);

        // [THEN] Verify "Document No." = "D" on Vendor Detailed Aging report
        VerifyVendorDetailedAgingDocumentNo(VendorLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReportWithBlankResponsibilityCenter()
    var
        SalesHeader: Record "Sales Header";
        CompanyInfo: Record "Company Information";
        BlanketSalesOrderReport: Report "Blanket Sales Order";
    begin
        // [FEATURE] [Sales] [Company Information]
        // [SCENARIO 281443] Running Report 210 on a Blanket Sales Order with blank Responsibility Center, default Company Information is used
        Initialize();
        CompanyInfo.Get();

        // [GIVEN] A Blanket Sales Order with Reponsibility Center blank
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());

        // [WHEN] Report 210 is run
        SalesHeader.SetRange("No.", SalesHeader."No.");
        BlanketSalesOrderReport.SetTableView(SalesHeader);
        Commit();
        BlanketSalesOrderReport.Run();
        // Handled by BlanketSalesOrderRequestPageHandler

        // [THEN] Company Information is filled
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoVATRegNo', CompanyInfo."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrdersRequestPageHandler,MessageHandler,SalesShipmentReportHandler,StandardSalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure TwoSalesOrderBatchPostingWithPrint()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SalesOrders: TestPage "Sales Order List";
        Index: Integer;
        SalesHeaderFilter: Text;
    begin
        // [FEATURE] [Batch Posting] [Sales] [Order]
        // [SCENARIO 357933] Stan can post and print two sales orders via "Batch Post Sales Orders"
        Initialize();

        SetReportOutputTypeOnSalesSetup(SalesReceivablesSetup."Report Output Type"::Print);
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Two sales orders
        for Index := 1 to ArrayLen(SalesHeader) do begin
            CreateSalesDocument(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, Customer."No.");
            LibrarySales.FindFirstSalesLine(SalesLine[Index], SalesHeader[Index]);
        end;

        SalesHeaderFilter := StrSubstNo('%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        LibraryVariableStorage.Enqueue(SalesHeaderFilter);
        LibraryVariableStorage.Enqueue(true); // print
        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibraryVariableStorage.Enqueue(SalesHeader[Index]."No."); // for shipment header
            LibraryVariableStorage.Enqueue(SalesHeader[Index]."No."); // for invoice header
        end;

        SalesOrders.OpenEdit();
        SalesOrders.FILTER.SetFilter("No.", SalesHeaderFilter);
        Commit();

        // [WHEN] Run "Batch Post Sales Orders" report with "Print" option for two orders
        SalesOrders."Post &Batch".Invoke(); // runs Batch Posting Sales Orders report

        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[Index].RecordId); // background post
            FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader[Index]."No.");
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesShipmentHeader.RecordId); // background print shipment
            FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader[Index]."No.");
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesInvoiceHeader.RecordId); // background print invoice
        end;

        // [THEN] 4 reports printed. Shipment and Invoice per each posted order
        Assert.AreEqual(2 * ArrayLen(SalesHeader), LibraryVariableStorage.Length(), '');

        for Index := 1 to ArrayLen(SalesHeader) do begin
            VerifyPostedSalesDocument(SalesHeader[Index]."No.", Customer."No.");
            VerifyPrintedSalesShipment(SalesLine[Index]);
            VerifyPrintedStandardSalesInvoice(SalesHeader[Index]);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CommentLineShowsOnlySalesShipmentNumberNotDateWhenUsingGetShipmentLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        ShipmentNo: Code[20];
    begin
        // [SCENARIO 599207] Verify that when the Get Shipment Line function is used in a Sales Invoice, the comment line description contains only the shipment number and not the date.
        Initialize();
        WorkDate := Today();

        // [GIVEN] Create Customer and Item
        CreateCustomerAndItem(Customer, Item);

        // [GIVEN] Create Sales Order with multiple line.
        CreateSalesOrderWithMultipleLine(SalesHeader[1], Customer."No.", Item."No.");

        // [GIVEN] Update the work date before processing the shipment.
        WorkDate := CalcDate('<10D>', WorkDate());

        // [GIVEN] Ship the Sales Order.
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [GIVEN] Create a Sales Header and set the Document Type to Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, Customer."No.");
        LibraryVariableStorage.Enqueue(SalesHeader[1]."No.");

        // [WHEN] When getting Sales Shipment Lines in a sales invoice.
        GetSalesShipmentLines(SalesHeader[2]);

        // [THEN] Comment line displays only the shipment number not the date.
        VerifyCommentLineDescriptionHasOnlyShipmentNo(SalesHeader[2]."No.", ShipmentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Sales/Purchase Report");

        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        DeleteObjectOptionsIfNeeded();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        isInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Sales/Purchase Report");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveSalesSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Sales/Purchase Report");
    end;

    local procedure CalculateRemAmountAsOfDueDate(DueDate: Date; VendorNo: Code[50]) RemAmount: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntry.SetFilter("Due Date", '0D..%1', DueDate);
        VendorLedgerEntry.SetRange("Currency Code", '');
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields("Remaining Amount");
                RemAmount += VendorLedgerEntry."Remaining Amount";
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, CreateVendorWithDimension());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndUpdateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", CreateGLAccount());
        Currency.Validate("Residual Losses Account", CreateGLAccount());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithCountryRegionCode(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithDimension(): Code[20]
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        FindDimensionValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Random value for Quantity.
    end;

    local procedure CreateVendorWithCountryRegionCode(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithDimension(): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Registration Number", LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
        FindDimensionValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Vendor."No.")
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry");
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure EnqueueValuesForCrossBorderServiceReport(Value: Code[20]; StatisticOn: Option; AdditionalReportingCurrency: Boolean)
    begin
        LibraryVariableStorage.Enqueue(StatisticOn);
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(AdditionalReportingCurrency);
    end;

    local procedure FindDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; OrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure PostPurchOrderAndRunCrossBorderServiceReport(var PurchaseLine: Record "Purchase Line"; StatisticOn: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Create and modify Vendor, create and post Purchase order.
        CreateVendorWithCountryRegionCode(Vendor);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        EnqueueValuesForCrossBorderServiceReport(Vendor."Country/Region Code", StatisticOn, true);
        Commit();  // COMMIT required to run the report.

        // Run Crossborder Services report.
        REPORT.Run(REPORT::"Crossborder Services");
    end;

    local procedure PostSalesOrderAndRunCrossBorderServiceReport(var SalesLine: Record "Sales Line"; StatisticOn: Option)
    var
        Customer: Record Customer;
    begin
        // Setup: Create and modify Customer, create and post Purchase Order.
        Initialize();
        SetupForCrossborderServicesReport(SalesLine);
        Customer.Get(SalesLine."Sell-to Customer No.");
        EnqueueValuesForCrossBorderServiceReport(Customer."Country/Region Code", StatisticOn, false);
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Crossborder Services");
    end;

    local procedure RunAndVerifyCrossborderServicesReport(ElementName: Text[50]; ElementValue: Variant)
    begin
        Commit();  // Commit required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Crossborder Services");

        // Verify: Verify Filter Text on Crossborder Services report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ElementValue);
    end;

    local procedure RunCreditMemoReportAndVerify(ElementName: Text[50]; ElementValue: Variant)
    begin
        // Exercise: Run Purchase Credit Memo Report.
        REPORT.Run(REPORT::"Purchase - Credit Memo");

        // Verify: Verify Name and Value on Purchase Credit Memo Report.
        VerifyElementWithValue(ElementName, ElementValue);
    end;

    local procedure RunVendorDetailedAgingReportAndVerify(EndingDate: Date; VendorNo: Text[50]; VendorFilterValue: Text[50])
    var
        RemAmount: Decimal;
    begin
        // Calculate Remaining Amount till Due Date.
        RemAmount := CalculateRemAmountAsOfDueDate(EndingDate, VendorNo);

        // Enqueue for VendorDetailedAgingRequestPageHandler.
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(VendorNo);

        // Exercise: Run Vendor Detailed Aging Report.
        REPORT.Run(REPORT::"Vendor Detailed Aging");

        // Verify: Verify Vendor filter and Remaining Amount on the report.
        VerifyElementWithValue(VendFilterCaption, VendorFilterValue);
        LibraryReportDataset.AssertElementWithValueExists(RemainingAmountCaption, RemAmount);
    end;

    local procedure SetupForCrossborderServicesReport(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        CreateCustomerWithCountryRegionCode(Customer);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        FindSalesLine(SalesLine, SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateGeneralLedgerSetup(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();

        // As there is no need to run Ajdust Add. Reporting Currency Batch Job so we are not validating Additional Reporting Currency field.
        GeneralLedgerSetup."Additional Reporting Currency" := CreateAndUpdateCurrency();
        GeneralLedgerSetup.Modify(true);
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure SetReportOutputTypeOnSalesSetup(ReportOutputType: Enum "Setup Report Output Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Report Output Type" := ReportOutputType;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdatePurchHdrPayToVendorNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendorWithDimension());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyCompanyInfoAndDocHdrDim(DimensionSetID: Integer; DimensionValueCode: Code[20]; ElementName: Text[50]; VATRegNoName: Text[50])
    var
        CompanyInformation: Record "Company Information";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimCodeValue: Text[50];
    begin
        // Verify Companay VAT Registration Number and Dimension value.
        CompanyInformation.Get();
        VerifyElementWithValue(VATRegNoName, CompanyInformation."VAT Registration No.");
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValueCode);
        DimensionSetEntry.FindFirst();
        DimCodeValue := DimensionSetEntry."Dimension Code" + ' ' + DimensionSetEntry."Dimension Value Code";  // Add Space between Dimension Code and Dimension Value Code.
        LibraryReportDataset.AssertElementWithValueExists(ElementName, DimCodeValue);
    end;

    local procedure VerifyCrossBorderServiceReport(CurrencyCode: Text[50]; RowCaption: Text[100]; RowValue: Variant; Columncaption: Text[50]; ColumnValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(HeaderTextCaption, StrSubstNo(CurrencyString, CurrencyCode));
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(Columncaption, ColumnValue);
    end;

    local procedure VerifyElementWithValue(ElementName: Text[50]; ElementValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ElementValue);
    end;

    local procedure VerifyPostedSalesDocument(OrderNo: Code[20]; SellToCustomerNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Sales Shipment Line and Sales Invoice Line.
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceLine.SetRange("Order No.", OrderNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Sell-to Customer No.", SellToCustomerNo);
    end;

    local procedure VerifyPurchaseCreditMemoRegistrationNo(RegistrationValue: Text[50]; RegistrationNo: Text[50])
    begin
        LibraryReportDataset.SetRange(RegistrationNoCaption, RegistrationValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(PurchCrMemoHdrRegNoCaption, RegistrationNo);
    end;

    local procedure VerifyPurchaseHeaderArchive(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
        PurchaseHeaderArchive.TestField("Registration No.", PurchaseHeader."Registration No.");
    end;

    local procedure VerifyVendorDetailedAgingDocumentNo(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vend', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_VendLedgEntry', VendorLedgerEntry."Document No.");
    end;

    local procedure VerifyPrintedSalesShipment(SalesLine: Record "Sales Line")
    begin
        Clear(LibraryXPathXMLReader);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath(No_SalesShipmentLine_XPathTok, 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(No_SalesShipmentLine_XPathTok, SalesLine."No.");
    end;

    local procedure VerifyPrintedStandardSalesInvoice(SalesHeader: Record "Sales Header")
    begin
        Clear(LibraryXPathXMLReader);
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/ReportDataSet/DataItems/DataItem', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(OrderNo_StandardSalesInvoice_XPathTok, SalesHeader."No.");
    end;

    local procedure CreateCustomerAndItem(var Customer: Record Customer; var Item: Record Item)
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateSalesOrderWithMultipleLine(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: array[2] of Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandIntInRange(10000, 20000));
        SalesLine[1].Validate(SalesLine[1]."Shipment Date", WorkDate(CalcDate('<7D>', WorkDate())));
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemNo, LibraryRandom.RandIntInRange(5, 10));
        SalesLine[2].Validate("Unit Price", SalesLine[1]."Unit Price");
        SalesLine[2].Modify(true);
    end;

    local procedure GetSalesShipmentLines(var SalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", LibraryVariableStorage.DequeueText());
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShipmentLine);
    end;

    local procedure VerifyCommentLineDescriptionHasOnlyShipmentNo(DocumentNo: Code[20]; ShipmentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.SetRange("No.", '');
        SalesLine.FindFirst();
        Assert.AreEqual(
            SalesLine.Description, StrSubstNo(ShipmentNoLbl, ShipmentNo),
            StrSubstNo(
                DescriptionContainDateErr, SalesLine.TableCaption(), SalesLine.FieldCaption(Description)));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersRequestPageHandler(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    var
        No: Variant;
        PrintDocuments: Boolean;
    begin
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        PrintDocuments := LibraryVariableStorage.DequeueBoolean();
        BatchPostSalesOrders.Ship.SetValue(true);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.PostingDate.SetValue(WorkDate());
        BatchPostSalesOrders."Sales Header".SetFilter("No.", No);
        if PrintDocuments then
            BatchPostSalesOrders.PrintDoc.SetValue(PrintDocuments);
        BatchPostSalesOrders.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CrossBorderServicesHandler(var CrossborderServices: TestRequestPage "Crossborder Services")
    var
        StatisticOn: Variant;
        CountryRegionCode: Variant;
        ShowAmountInAddReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatisticOn);
        LibraryVariableStorage.Dequeue(CountryRegionCode);
        LibraryVariableStorage.Dequeue(ShowAmountInAddReportingCurrency);
        CrossborderServices.Selection.SetValue(StatisticOn);  // Setting value for control 'Statistic on'.
        CrossborderServices.UseAmtsInAddCurr.SetValue(ShowAmountInAddReportingCurrency);  // Setting value for control 'Show Amount in Additional Reporting Currency'.
        CrossborderServices."VAT Entry".SetFilter("Country/Region Code", CountryRegionCode);
        CrossborderServices.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CrossBorderServicesHandlerForFilters(var CrossborderServices: TestRequestPage "Crossborder Services")
    var
        AddReportingCurrency: Variant;
        CountryRegionCode: Variant;
        GenProdPostingGroup: Variant;
        OptionValue: Variant;
        FilterOption: Option;
        OptionString: Option PostingDate,CountryRegion,GenProdPostingGroup,PostingDateCountryRegion,PostingDateCountryRegionGenProdPostingGrp;
        StatisticsOn: Option Countries,"Type Of Service",Both;
    begin
        CrossborderServices.Selection.SetValue(StatisticsOn::Countries);  // Setting value for control 'Statistics on'.
        CrossborderServices.UseAmtsInAddCurr.SetValue(false);  // Setting value for control 'Show Amount in Additional Reporting Currency'.
        LibraryVariableStorage.Dequeue(OptionValue); // Dequeue variable.
        FilterOption := OptionValue;
        case FilterOption of
            OptionString::CountryRegion:
                begin
                    LibraryVariableStorage.Dequeue(CountryRegionCode);  // Dequeue variable.
                    CrossborderServices."VAT Entry".SetFilter("Country/Region Code", CountryRegionCode);
                end;
            OptionString::PostingDate:
                CrossborderServices."VAT Entry".SetFilter("Posting Date", Format(WorkDate()));
            OptionString::GenProdPostingGroup:
                begin
                    LibraryVariableStorage.Dequeue(GenProdPostingGroup);  // Dequeue variable.
                    CrossborderServices."VAT Entry".SetFilter("Gen. Prod. Posting Group", GenProdPostingGroup);
                end;
            OptionString::PostingDateCountryRegion:
                begin
                    LibraryVariableStorage.Dequeue(CountryRegionCode);  // Dequeue variable.
                    CrossborderServices."VAT Entry".SetFilter("Country/Region Code", CountryRegionCode);
                    CrossborderServices."VAT Entry".SetFilter("Posting Date", Format(WorkDate()));
                end;
            OptionString::PostingDateCountryRegionGenProdPostingGrp:
                begin
                    LibraryVariableStorage.Dequeue(CountryRegionCode);  // Dequeue variable.
                    LibraryVariableStorage.Dequeue(AddReportingCurrency);
                    LibraryVariableStorage.Dequeue(GenProdPostingGroup);  // Dequeue variable.
                    CrossborderServices."VAT Entry".SetFilter("Country/Region Code", CountryRegionCode);
                    CrossborderServices."VAT Entry".SetFilter("Gen. Prod. Posting Group", GenProdPostingGroup);
                    CrossborderServices."VAT Entry".SetFilter("Posting Date", Format(WorkDate()));
                end;
        end;
        CrossborderServices.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    var
        BuyFromVendorNo: Variant;
        No: Variant;
        OptionValue: Variant;
        PayToVendorNo: Variant;
        VendorCrMemoNo: Variant;
        FilterOption: Option;
        OptionString: Option No,NoOfCopies,PayToVendNo,BuyFromVendNo,PostingDate,VendCrMemoNo;
    begin
        LibraryVariableStorage.Dequeue(OptionValue); // Dequeue variable.
        FilterOption := OptionValue;
        case FilterOption of
            OptionString::No:
                begin
                    LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
                    PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
                end;
            OptionString::NoOfCopies:
                begin
                    PurchaseCreditMemo.NoOfCopies.SetValue(LibraryRandom.RandInt(10));  // Random value for Number of copies.
                    LibraryVariableStorage.Enqueue(PurchaseCreditMemo.NoOfCopies.Value);  // Enqueue value for further use. Control use for Number of copies.
                end;
            OptionString::PayToVendNo:
                begin
                    LibraryVariableStorage.Dequeue(PayToVendorNo);  // Dequeue variable.
                    PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("Pay-to Vendor No.", PayToVendorNo);
                end;
            OptionString::BuyFromVendNo:
                begin
                    LibraryVariableStorage.Dequeue(BuyFromVendorNo);  // Dequeue variable.
                    PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("Buy-from Vendor No.", BuyFromVendorNo);
                end;
            OptionString::PostingDate:
                PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("Posting Date", Format(WorkDate()));
            OptionString::VendCrMemoNo:
                begin
                    LibraryVariableStorage.Dequeue(VendorCrMemoNo);  // Dequeue variable.
                    PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("Vendor Cr. Memo No.", VendorCrMemoNo);
                end;
        end;
        PurchaseCreditMemo.ShowInternalInfo.SetValue(true);  // Control use for Show Internal Information.
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderRequestPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailedAgingRequestPageHandler(var VendorDetailedAging: TestRequestPage "Vendor Detailed Aging")
    var
        EndingDate: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndingDate);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        VendorDetailedAging.EndingDate.SetValue(EndingDate);  // Control use for Ending Date.
        VendorDetailedAging.Vendor.SetFilter("No.", No);
        VendorDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PHVendorDetailedAging(var VendorDetailedAging: TestRequestPage "Vendor Detailed Aging")
    begin
        VendorDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        ObjectOptions: Record "Object Options";
    begin
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.DeleteAll();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHandler(var SalesShipment: Report "Sales - Shipment")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        FileManagement: Codeunit "File Management";
        FilePath: Text;
    begin
        FindSalesShipmentHeader(SalesShipmentHeader, LibraryVariableStorage.DequeueText());
        SalesShipment.SetTableView(SalesShipmentHeader);
        FilePath := FileManagement.ServerTempFileName('xml');
        SalesShipment.SaveAsXml(FilePath);
        LibraryVariableStorage.Enqueue(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceReportHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FileManagement: Codeunit "File Management";
        FilePath: Text;
    begin
        FindSalesInvoiceHeader(SalesInvoiceHeader, LibraryVariableStorage.DequeueText());
        StandardSalesInvoice.SetTableView(SalesInvoiceHeader);
        FilePath := FileManagement.ServerTempFileName('xml');
        StandardSalesInvoice.SaveAsXml(FilePath);
        LibraryVariableStorage.Enqueue(FilePath);
    end;
}