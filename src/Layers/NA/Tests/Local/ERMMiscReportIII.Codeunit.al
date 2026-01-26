codeunit 142062 "ERM Misc. Report III"
{
    // Verify ERM Miscellaneous Reports:
    //  1. Verify Aged Accounts Payable Report with Due Date option.
    //  2. Verify Aged Accounts Payable Report with Trans Date option.
    //  3. Verify Aged Accounts Payable Report with Document Date option.
    //  4. Verify Payment Journal Test Report with Show Dimensions option.
    //  5. Verify Top Vendor List Report with Show as Balances.
    //  6. Verify Top Vendor List Report with Show as Purchases.
    //  7. Verify Sales Invoice Report with Company Address and without Log Interaction.
    //  8. Verify Sales Invoice Report without Company Address and with Log Interaction.
    //  9. Verify Sales Shipment Report with Company Address and Log Interaction.
    // 10. Verify Sales Quote Report with Company Address and Log Interaction.
    // 11. Verify Sales Order Report with Company Address and Log Interaction.
    // 12. Verify Sales Credit Memo Report with Company Address and Log Interaction.
    // 13. Verify Item Turnover Report with Item No. filter.
    // 14. Verify Item Turnover Report with only Date filter and other fields are blank.
    // 15. Verify Purchase Advice Report without filter.
    // 16. Verify Purchase Advice Report using filters.
    // 17. Verify Purchase Order Status Report without filter.
    // 18. Verify Purchase Order Status Report With filters.
    // 19. Verify GST/HST Internet File Transfer Report without Start Date.
    // 20. Verify GST/HST Internet File Transfer Report without End Date.
    // 21. Verify Sales Order Report with Line Amount Excl. Tax. BUGID:151937.
    // 23. Verify Sales Invoice Report with 'Show Assembly Components' option.
    // 32. Verify Total caption for Sales Invoice Report (given currency).
    // 33. Verify Total caption for Sales Invoice Report (local currency).
    // 34. Verify Total caption for Purchase Invoice Report (given currency).
    // 35. Verify Total caption for Purchase Invoice Report (local currency).
    //
    // Covers Test Cases for WI - 332267
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // PaymentJournalTestWithShowDimensions                                                            171128
    // TopVendorListWithShowAsBalances, TopVendorListWithShowAsPurchases                               171178
    //
    // Covers Test Cases for WI - 329576
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportWithCompanyAddress, SalesInvoiceReportWithLogInteraction                      157066
    // SalesShipmentReport                                                                             171083
    // SalesQuoteReport                                                                                171082
    // SalesOrderReport                                                                                171081
    // SalesCreditMemoReport                                                                           171079
    //
    // Covers Test Cases for WI - 327944
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // RunItemTurnOverWithItemNoFilter, RunItemTurnOverWithDatefilter                                  171090
    // RunPurchaseAdviceReportWithoutFilter, RunPurchaseAdviceReportWithFilters                        171103
    // RunPurchaseOrderStatusReportWithoutFilter, RunPurchaseOrderStatusReportWithFilters              171100
    //
    // Covers Test Cases for WI - 330785
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // GSTHSTInternetFileTransferWithBlankStartDate                                                    202397
    // GSTHSTInternetFileTransferWithBlankEndDate                                                      202397
    //
    // Covers Test Cases for WI - 338154
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesOrderConfirmationReport                                                                    151937
    //
    // BUG ID 58797
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name
    // ------------------------------------------------------------------------------------------------------
    // AgedAccountsPayableWithUseExternalDocNo
    //
    // Covers Test Cases for HFR - 351480
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportWithAssemblyComponents                                                        351480
    //
    // Covers Test Cases for HFR - 354445
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // CheckTotalAmountOnAgedAccountsPayable,CheckTotalAmountOnReportWithMultipleVendor                354445
    // CheckTotalAmountOnAgedAccountsReceivable,CheckTotalAmountOnReportWithMultipleCustomer
    // CheckTotalAmountOnAgedAccountsPayableWithCurrency,
    // CheckTotalAmountOnReportWithMultipleVendorWithCurrency,
    // CheckTotalAmountOnAgedAccountsReceivableWithCurrency,
    // CheckTotalAmountOnReportWithMultipleCustomerWithCurrency
    //
    // Covers Test Cases for HFR - 351480
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportTotalsWithCurrency                                                            360300
    // SalesInvoiceReportTotalsWithoutCurrency                                                         360300
    // PurchInvoiceReportTotalsWithCurrency                                                            360300
    // PurchInvoiceReportTotalsWithoutCurrency                                                         360300

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        BalancesCap: Label 'Balances';
        ColHeadCap: Label 'ColHead';
        CompanyAddress: Label 'CompanyAddress1';
        CrMemoItemNo: Label 'TempSalesCrMemoLineNo';
        CrMemoQuantity: Label 'TempSalesCrMemoLineQty';
        DimTextCap: Label 'DimText';
        "Filter": Label '%1..%2';
        Filter2: Label '%1 - %2';
        GLAccNetChangeNetChangeinJnlCap: Label 'GLAccNetChange__Net_Change_in_Jnl__';
        GenJournaLineDocumentNoCap: Label 'Gen__Journal_Line__Document_No__';
        GenJournalLineAccountNoCap: Label 'Gen__Journal_Line__Account_No__';
        GenJournalLineAmountCap: Label 'Gen__Journal_Line_Amount';
        GrandTotalCap: Label 'GrandTotal';
        ICaption: Label 'i', Comment = 'i for Rank';
        InvoiceItemNo: Label 'TempSalesInvoiceLineNo';
        ItemNoCap: Label 'Item__No__';
        MainTitleCap: Label 'MainTitle_';
        DateError: Label '%1 should not be blank.';
        OrderedQty: Label 'OrderedQuantity';
        QtyOnSalesOrder: Label 'Item__Qty__on_Sales_Order_';
        PurchasesCap: Label 'Purchases';
        PurchaseLineQuantity: Label 'Purchase_Line_Quantity';
        SalesInvoiceNo: Label 'No_SalesInvHeader';
        SalesShipmentNo: Label 'No_SalesShptHeader';
        SalesHeaderNo: Label 'No_SalesHeader';
        SalesCrMemoNo: Label 'No_SalesCrMemoHeader';
        SalesLineItemNo: Label 'TempSalesLineNo';
        SalesLineQuantity: Label 'TempSalesLineQuantity';
        ShipmentItemNo: Label 'TempSalesShptLineNo';
        Top2VendorsCap: Label 'Top 20 Vendors';
        TopNoiCaption: Label 'TopNo_i_';
        TopAmountiCaption: Label 'TopAmount_i_';
        TopCap: Label 'Top__';
        TotalPrice: Label 'AmountExclInvDisc';
        ValueMustMatch: Label 'Value must match.';
        WrongTotalAmountErr: Label 'Wrong total Amount.';
        TotalCaptionCapTxt: Label 'TotalCaption';
        TotalCaptionTxt: Label 'Total %1:';
        PurchaseInvoiceNoTxt: Label 'No_PurchInvHeader';
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        FieldMustBeVisibleInAreaErr: Label 'Field %1 must be visible in %2.';
        TestFieldNotFoundErr: Label 'TestFieldNotFound';
        RemitAddressShouldExistErr: Label 'Remit Address Name should exist in the Positive Pay Export File.';
        RemitToCodeMissingErr: Label 'Remit-To Code missing on payment journal line.';
        SalesCommentToMatch: Label 'HighDescriptionToPrint';
        RowMustExist: Label 'Row must exist.';

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalTestWithShowDimensions()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Payment Journal Test report with Show Dimensions option.

        // Setup: Create a payment entry for a vendor with dimensions.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, CreateVendor(), Dimension.Code, DimensionValue.Code);
        CreateGenJournalLine(
          GenJournalLine, DefaultDimension."No.", GenJournalLine."Account Type"::Vendor,
          LibraryRandom.RandDec(10, 2));

        // Enqueue values for PaymentJournalTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Payment Journal - Test");

        // Verify: Verify Dimension and Amounts on generated Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, StrSubstNo(Filter2, Dimension.Code, DimensionValue.Code));
        LibraryReportDataset.AssertElementWithValueExists(GLAccNetChangeNetChangeinJnlCap, -GenJournalLine.Amount);
        VerifyValuesOnReport(
          GenJournalLine."Document No.", GenJournaLineDocumentNoCap, GenJournalLineAccountNoCap, GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(GenJournalLineAmountCap, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopVendorListWithShowAsBalances()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Verify Top Vendor List Report with Show as Balances.

        // Setup: Create and post invoices for two vendors.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use random for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Use random for Direct Unit Cost.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry, Quantity, 3 * DirectUnitCost);  // To generate greater amount.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry2, Quantity, DirectUnitCost);
        EnqueueValuesForReport(StrSubstNo(Filter, VendorLedgerEntry."Vendor No.", VendorLedgerEntry2."Vendor No."), 0);  // Using 0 for Balances option.

        // Exercise.
        REPORT.Run(REPORT::"Top __ Vendor List");

        // Verify: Verify rank and amount on generated Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportTopVendorList(
          BalancesCap, VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry2."Vendor No.", Abs(VendorLedgerEntry."Amount (LCY)"), Abs(VendorLedgerEntry2."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopVendorListWithShowAsPurchases()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Verify Top Vendor List Report with Show as Purchases.

        // Setup: Create and post invoices for two vendors.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Use random for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Use random for Direct Unit Cost.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry, Quantity, 3 * DirectUnitCost);  // To generate greater amount.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry2, Quantity, DirectUnitCost);
        EnqueueValuesForReport(StrSubstNo(Filter, VendorLedgerEntry."Vendor No.", VendorLedgerEntry2."Vendor No."), 1);  // Using 1 for Purchases option.

        // Exercise.
        REPORT.Run(REPORT::"Top __ Vendor List");

        // Verify: Verify rank and amount on generated Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportTopVendorList(
          PurchasesCap, VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry2."Vendor No.", Abs(VendorLedgerEntry."Purchase (LCY)"), Abs(VendorLedgerEntry2."Purchase (LCY)"));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithCompanyAddress()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Sales Invoice Report with Company Address and without Log Interaction.
        Initialize();
        CompanyInformation.Get();
        RunAndVerifySalesInvoiceReport(CompanyInformation.Name, true, false, true);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithLogInteraction()
    begin
        // Verify Sales Invoice Report without Company Address and with Log Interaction.
        Initialize();
        RunAndVerifySalesInvoiceReport('', false, true, false);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Sales Shipment Report with Company Address and Log Interaction.

        // Setup: Create and post Sales Invoice.
        Initialize();
        CompanyInformation.Get();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, false);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for SalesShipmentRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Shipment NA");

        // Verify: Verify Company Information and Posted Sales Shipment values on Sales Shipment Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, CompanyAddress, CompanyInformation.Name);
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, ShipmentItemNo, SalesLine."No.");
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, OrderedQty, SalesLine.Quantity);
        VerifyLogInteraction(DocumentNo, false);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Quote Report with Company Address and Log Interaction.

        // Setup: Create Sales Quote.
        Initialize();
        CompanyInformation.Get();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesQuoteRequestPageHandler.
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Quote NA");

        // Verify: Verify Company Information and Sales Quote values on Sales Quote Report.
        VerifySalesReport(
          SalesLine, SalesLine."Document No.", CompanyInformation.Name, SalesHeaderNo, SalesLineItemNo, SalesLineQuantity, false);
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order Report with Company Address and Log Interaction.

        // Setup: Create Sales Order.
        Initialize();
        CompanyInformation.Get();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesOrderRequestPageHandler.
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Order");

        // Verify: Verify Company Information and Sales Order values on Sales Order Report.
        VerifySalesReport(
          SalesLine, SalesLine."Document No.", CompanyInformation.Name, SalesHeaderNo, SalesLineItemNo, SalesLineQuantity, false);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Sales Credit Memo Report with Company Address and Log Interaction.

        // Setup: Create and post Sales Credit Memo.
        Initialize();
        CompanyInformation.Get();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", true);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for SalesCreditMemoRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Credit Memo NA");

        // Verify: Verify Company Information and Posted Sales Credit Memo values on Sales Credit Memo Report.
        VerifySalesReport(SalesLine, DocumentNo, CompanyInformation.Name, SalesCrMemoNo, CrMemoItemNo, CrMemoQuantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunItemTurnOverWithItemNoFilter()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item Turnover Report with Item No. filter.

        // Setup.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);

        // Exercise.
        RunItemTurnoverReport(ItemJournalLine."Item No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoCap, ItemJournalLine."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunItemTurnOverWithDatefilter()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
    begin
        // Verify Item Turnover Report with only Date filter and other fields are blank.

        // Setup: Create and post Item Journal with different Items.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);
        CreateAndPostItemJournalLine(ItemJournalLine2);

        // Exercise.
        RunItemTurnoverReport('');  // Using blank value for Item No. filter.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportValues(ItemNoCap, ItemJournalLine."Item No.", ItemJournalLine2."Item No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseAdviceReportWithoutFilter()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Purchase Advice Report without filter.
        RunAndVerifyPurchaseAdviceReport(SalesLine, 0D, '');  // Using blank value for Item No. filter.
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseAdviceReportWithFilters()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Purchase Advice Report using filters.
        RunAndVerifyPurchaseAdviceReport(SalesLine, WorkDate(), SalesLine."No.");
    end;

    local procedure RunAndVerifyPurchaseAdviceReport(var SalesLine: Record "Sales Line"; DateFilter: Date; No: Code[20])
    begin
        // Setup: Create Sales Order
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);

        // Exercise.
        RunPurchaseAdviceReport(DateFilter, No, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(QtyOnSalesOrder, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatusReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseOrderStatusReportWithoutFilter()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Status Report without filter.
        RunAndVerifyPurchaseOrderStatusReport(PurchaseLine, 0D, '');  // Using blank value for Item No. filter.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatusReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseOrderStatusReportWithFilters()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Status Report With filters.
        RunAndVerifyPurchaseOrderStatusReport(PurchaseLine, WorkDate(), PurchaseLine."No.");
    end;

    local procedure RunAndVerifyPurchaseOrderStatusReport(var PurchaseLine: Record "Purchase Line"; DateFilter: Date; No: Code[20])
    begin
        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateItem(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Used Random value for Quantity.

        // Exercise.
        RunPurchaseOrderStatusReport(DateFilter, No);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLineQuantity, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferWithBlankStartDate()
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without Start Date.
        GSTHSTInternetFileTransferWithoutMandatoryFilters(0D, WorkDate(), 'Start Date');  // Taking 0D for Starting Date.
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferWithBlankEndDate()
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without End Date.
        GSTHSTInternetFileTransferWithoutMandatoryFilters(WorkDate(), 0D, 'End Date');  // Taking 0D for End Date.
    end;

    local procedure GSTHSTInternetFileTransferWithoutMandatoryFilters(StartDate: Date; EndDate: Date; DateString: Text[10])
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without mandatory filters.

        // Setup.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        LibraryVariableStorage.Enqueue(StartDate);  // Enqueue values for GSTHSTInternetFileTransferRequestPageHandler.
        LibraryVariableStorage.Enqueue(EndDate);
        Commit();  // Required to run the report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"GST/HST Internet File Transfer");

        // Verify.
        Assert.ExpectedError(StrSubstNo(DateError, DateString));
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderConfirmationReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order Report with Line Amount Excl. Tax. BUGID:151937.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesOrderRequestPageHandler.
        Commit();  // Codeunit 313 Sales-Printed OnRun Calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Sales Order");

        // Verify: Verify Total Price on Sales Order Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalPrice, SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceAssemblyRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithAssemblyComponents()
    begin
        // Verify Sales Invoice Report with 'Show Assembly Components' option.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        RunAndVerifySalesInvoiceReportAssembly(2);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportTotalsWithCurrency()
    begin
        // Verify Total caption for Sales Invoice Report (given currency).
        Initialize();
        RunAndVerifySalesInvoiceReportTotals(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportTotalsWithoutCurrency()
    begin
        // Verify Total caption for Sales Invoice Report (local currency).
        Initialize();
        RunAndVerifySalesInvoiceReportTotals('');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportTotalsWithCurrency()
    var
        Vendor: Record Vendor;
    begin
        // Verify Total caption for Purchase Invoice Report (given currency).
        Initialize();
        CreateVendorWithCurrency(Vendor);
        RunAndVerifyPurchInvoiceReportTotals(Vendor);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportTotalsWithoutCurrency()
    var
        Vendor: Record Vendor;
    begin
        // Verify Total caption for Purchase Invoice Report (local currency).
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        RunAndVerifyPurchInvoiceReportTotals(Vendor);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceAssemblyRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportComponentOrderQtyWithAdjmtValueEntry()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Sales Invoice] [Assembly]
        // [SCENARIO 375200] Sales Invoice Report should not take into account adjustment Value Entry for calculating Order Qty of assembly components
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Component Item with "Quantity Per" = "X" of Assembly Item
        // [GIVEN] Posted Sales Invoice for Assembly Item for Quantity = "Y"
        // [GIVEN] Adjustment Value Entry for Component Item of Quantity = "X * Y"
        Qty := LibraryRandom.RandDec(10, 2);
        QtyPer := LibraryRandom.RandDec(10, 2);

        CreateSalesDocumentWithItem(SalesLine, SalesLine."Document Type"::Order, CreateAssemblyItemWithComponents(1, QtyPer), Qty);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Sales Invoice Report with option "DisplayAsmInfo"
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for SalesInvoiceAssemblyRequestPageHandler
        LibraryVariableStorage.Enqueue(true); // Show Assembly Components
        REPORT.Run(REPORT::"Sales Invoice NA");

        // [THEN] "Order Qty" in Sales Invoice Report for Component Item is "X * Y"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesInvHeader', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempPostedAsmLineQuantity', QtyPer * Qty);
    end;

    [Test]
    [HandlerFunctions('SalesInvReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvReportAdditionalDescription()
    var
        DocumentNo: Code[20];
        Desc: array[2] of Text;
        DescLineNo: array[2] of Integer;
    begin
        // [SCENARIO 378362] Additional descriptions in posted sales invoice should be show on Sales Invoice report
        Initialize();

        // [GIVEN] Posted sales invoice with additional descriptions in lines
        // [GIVEN] First line has Type = Item
        // [GIVEN] Second and third lines have Type = <blank> and descriptions = "DESC1"/"DESC2"
        DocumentNo := CreateAndPostSalesInvWithAdditionalDescription(Desc, DescLineNo);

        // [WHEN] Invoke Sales Invoice report
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(REPORT::"Sales Invoice NA");

        // [THEN] Report should contain line with "DESC1"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TempSalesInvoiceLineLineNo', DescLineNo[1]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('HighDescriptionToPrint', Desc[1]);

        // [THEN] Report should contain line with "DESC2"
        LibraryReportDataset.SetRange('TempSalesInvoiceLineLineNo', DescLineNo[2]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('HighDescriptionToPrint', Desc[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingListReportAvailableInSuiteAppArea()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 256995] "Picking List by Order" report should be available under #Suite application area

        Initialize();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        LibraryApplicationArea.EnableFoundationSetup();
        SalesOrder.OpenView();
        Assert.IsTrue(SalesOrder."Report Picking List by Order".Enabled(), 'Action must be enabled in Foundation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingListReportNotAvailableInBasicAppArea()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 256995] "Picking List by Order" report should not be available under #Basic application area

        Initialize();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        LibraryApplicationArea.EnableBasicSetup();
        SalesOrder.OpenView();
        asserterror SalesOrder."Report Picking List by Order".Invoke();

        Assert.ExpectedErrorCode('TestActionNotFound');
    end;

    [Test]
    [HandlerFunctions('PrintStubStubCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubStubCheck()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10401 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10401 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Stub/Check)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubStubCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubStubCheck()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10401 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10401 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Stub/Check)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubCheckStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10411 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10411 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Check/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubCheckStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10411 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10411 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Check/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepCheckStubStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10412 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepCheckStubStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10412 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintThreeChecksPerPageReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepThreeChecksPerPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10413 Check is 30
        MaxEntries := 30;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10413 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Three Checks per Page");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintThreeChecksPerPageReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepThreeChecksPerPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize();

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10413 Check is 30
        MaxEntries := 30;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10413 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Three Checks per Page");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order" available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Order", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order" available under #Suite application area
        Initialize();

        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Order", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderPrePrintedRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order (Pre-Printed)" available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Order (Pre-Printed)", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Basic'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderPrePrintedRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order (Pre-Printed)" available under #Suite application area
        Initialize();

        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Order (Pre-Printed)", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckReturnOrderConfirmRequestPageOptonsVisibilityInPurchaseReturnOrderAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Return Order Confirm" available under #PurchaseReturnOrder application area
        Initialize();

        LibraryApplicationArea.EnablePurchaseReturnOrderSetup();
        Commit();

        REPORT.Run(REPORT::"Return Order Confirm", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Purchase Return Order'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Purchase Return Order'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Purchase Return Order'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Purchase Return Order'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckReturnOrderConfirmRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Return Order Confirm" are not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Return Order Confirm", true, false, PurchaseHeader);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseBlanketOrderRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Blanket Order" available under #Suite application area
        Initialize();

        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Blanket Order", true, false, PurchaseHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Foundation'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseBlanketOrderRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Blanket Order" are not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Blanket Order", true, false, PurchaseHeader);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceCrMemoSalesTaxRequestPageOptonsVisibilityInServiceAppArea()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" available under #Service application area
        Initialize();

        LibraryApplicationArea.EnableServiceManagementSetup();
        Commit();

        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax", true, false, ServiceCrMemoHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Service'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Service'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoSalesTaxWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceCrMemoSalesTaxRequestPageOptonsVisibilityInBasicAppArea()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" are not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax", true, false, ServiceCrMemoHeader);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceSalesTaxRequestPageOptonsVisibilityInServiceAppArea()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" available under #Service application area
        Initialize();

        LibraryApplicationArea.EnableServiceManagementSetup();
        Commit();

        REPORT.Run(REPORT::"Service Invoice-Sales Tax", true, false, ServiceInvoiceHeader);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Service'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Service'));
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Service'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceSalesTaxRequestPageOptonsVisibilityInBasicAppArea()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" are not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Service Invoice-Sales Tax", true, false, ServiceInvoiceHeader);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceSaveAsPDFReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchaseAdvice()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 333888] Report "Purchase Advice" can be printed without RDLC rendering errors
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Report "Purchase Advice" is being printed to PDF
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        RunPurchaseAdviceReport(WorkDate(), SalesLine."No.", false);

        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceSKUVisibilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseAdviceUseSKUOptionVisibilityInWarehouseAppArea()
    begin
        // [FEATURE] [Purchase] [Stockkeeping Unit] [Planning] [Application Area] [UT]
        // [SCENARIO 367615] "Use Stockkeeping Unit" option of report "Purchase Advice" is available under #Planning application area        Initialize();
        Initialize();

        EnablePlanningApplicationAreaSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Advice", true, false);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Planning'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseAdviceUseSKUOptionVisibilityInBasicAppArea()
    begin
        // [FEATURE] [Purchase] [Stockkeeping Unit] [Basic] [Application Area] [UT]
        // [SCENARIO 367615] "Use Stockkeeping Unit" option of report "Purchase Advice" is not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Advice", true, false);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAdviceReportRespectsOrderMultipleOnItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase Advice] [Item]
        // [SCENARIO 373974] Purchase Advice report respects "Order Multiple" setting on item.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Item with "Maximum Inventory" = 100, "Order Multiple" = 10.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Maximum Inventory", 100);
        Item.Validate("Order Multiple", 10);
        Item.Modify(true);

        // [GIVEN] Create sales order for 5 pcs.
        CreateSalesDocumentWithItem(SalesLine, SalesLine."Document Type"::Order, Item."No.", 5);

        // [WHEN] Run Purchase Advice report per item.
        RunPurchaseAdviceReport(WorkDate(), Item."No.", false);

        // [THEN] The report suggests reordering 110 pcs (105 to reach the maximum inventory and round up to 110).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ReorderAmount1', 110);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAdviceReportRespectsOrderMultipleOnSKU()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase Advice] [Stockkeeping Unit]
        // [SCENARIO 373974] Purchase Advice report respects "Order Multiple" setting on SKU.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Item with "Reorder Policy" = 50, "Reorder Quantity" = 40, "Order Multiple" = 30.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", 50);
        Item.Validate("Reorder Quantity", 40);
        Item.Validate("Order Multiple", 30);
        Item.Modify(true);

        // [GIVEN] Create stockkeeping unit on location "L".
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');

        // [GIVEN] Create sales order for 5 pcs on location "L".
        CreateSalesDocumentWithItem(SalesLine, SalesLine."Document Type"::Order, Item."No.", 5);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [WHEN] Run Purchase Advice report per SKU.
        RunPurchaseAdviceReport(WorkDate(), Item."No.", true);

        // [THEN] The report suggests reordering 90 pcs (55 to reach reorder point, round up to 80 = 2 orders for 40 pcs, round up to 90).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ReorderAmount1', 90);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocumentNoIsPrintedForSalesInvoiceInSalesDocumentTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 379746] Run report 202 "Sales Document - Test" for Sales Invoice with External Doc. No.
        Initialize();

        // [GIVEN] Created Sales Invoice with External Document No.
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("External Document No.", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run report 202 the "Sales Document - Test"
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Sales Document - Test", true, false, SalesHeader);

        // [THEN] External Document No. is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('SalesHeader__External_Document_No__', SalesHeader."External Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderCheckVisibilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckOptionArchiveOrdersIsEnabledInSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 381376] Request page option "Archive Orders" is enabled in Sales Order report when "Archive Orders" in Sales Setup set to "true"
        Initialize();

        // [GIVEN] Set "Archive Orders" in Sales Setup to "true"
        SalesReceivablesSetup.Validate("Archive Orders", true);
        SalesReceivablesSetup.Modify(true);
        Commit();

        // [WHEN] Run report "Sales Order"
        REPORT.Run(REPORT::"Sales Order", true, false, SalesHeader);

        // [THEN] "Archive Orders" option is enable in request page of Sales Order
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyZIPCodeInRemitAddressOnPrintedVendorCheckWhenUsingReportCheckStubStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        RemitAddress: Record "Remit Address";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 460209] ZIP code on the "Remit to" address is not showing on the printed vendor's check when using report layout 10412
        Initialize();

        // [GIVEN] Vendor Exist with Remit Address as Default
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [GIVEN] Create Payment Journal With "Remit-to Code" for Vendor
        CreateGenJournalLineWithBankAccount(GenJournalLine, "Gen. Journal Document Type"::Payment, "Gen. Journal Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(500, 0), "Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Remit-to Code", RemitAddress.Code);
        GenJournalLine.Modify();

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify();

        // [GIVEN] Select Bank Account and Last Check No On Report
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify();
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        // [WHEN] Check printed from Payment Journal page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [VERIFY] Verify: Remit Address including Zip Code on Check Report
        VerifyZipCodeOnReport(RemitAddress);
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateRemitAddressNameOnBankAccountPositivePayExport()
    var
        Vendor: Record Vendor;
        RemitAddress: Record "Remit Address";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchLineDef: Record "Data Exch. Line Def";
        CheckLedgerEntry: Record "Check Ledger Entry";
        PositivePayEntry: Record "Positive Pay Entry";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        ExpLauncherPosPay: Codeunit "Exp. Launcher Pos. Pay";
        PaymentJournal: TestPage "Payment Journal";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 461669] Positive Pay is not taking the Remit Address when exporting the file, it is still getting the vendor information instead of the Remit Address even if we indicate the remit to code (Remit Adress) on the payment journal.
        Initialize();

        // [GIVEN] Vendor Exist with Remit Address as Default
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandInt(20), 1));
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [GIVEN] Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export"
        LibraryPaymentExport.CreateBankExportImportSetup(
            BankExportImportSetup,
            FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Detail));
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        // [GIVEN] Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);
        CreateGenJournalLineWithWithExportImportBankAccount(
            GenJournalLine, "Gen. Journal Document Type"::Payment,
            "Gen. Journal Account Type"::Vendor,
            Vendor."No.",
            LibraryRandom.RandDec(500, 0),
            "Bank Payment Type"::"Computer Check",
            BankAccountNo);
        GenJournalLine.Validate("Remit-to Code", RemitAddress.Code);
        GenJournalLine.Modify();

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify();
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(false);
        Commit();

        // [GIVEN] Check printed from Payment Journal page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();
        PaymentJournal.Post.Invoke();

        // [WHEN] Export Positive Pay
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNo);
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);
        CheckLedgerEntry.FindFirst();

        // [THEN] Exported file contain a line with the Remit Address Name as Description
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);

        // [VERIFY] Verify: Description Exists in Exported Positive Payment File based on Remit Address Name
        Assert.IsTrue(CheckRemitAddressNameExistsInFileDetailLine(PositivePayEntry, RemitAddress.Name), RemitAddressShouldExistErr);
    end;

    [Test]
    [HandlerFunctions('PrintStubCheckStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyZIPCodeInRemitAddressOnPrintedVendorCheckWhenUsingReportStubCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        RemitAddress: Record "Remit Address";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 464069] ZIP code on the "Remit to" address is not showing on the printed vendor's check when using NA check report layouts other than 10412
        Initialize();

        // [GIVEN] Vendor Exist with Remit Address as Default
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [GIVEN] Create Payment Journal With "Remit-to Code" for Vendor
        CreateGenJournalLineWithBankAccount(GenJournalLine, "Gen. Journal Document Type"::Payment, "Gen. Journal Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(500, 0), "Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Remit-to Code", RemitAddress.Code);
        GenJournalLine.Modify();

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", Report::"Check (Stub/Check/Stub)");
        ReportSelections.Modify();

        // [GIVEN] Select Bank Account and Last Check No On Report
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify();
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        // [WHEN] Check printed from Payment Journal page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [VERIFY] Verify: Remit Address including Zip Code on Check Report
        VerifyZipCodeOnReport(RemitAddress);
    end;

    [Test]
    [HandlerFunctions('PrintStubStubCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyZIPCodeInRemitAddressOnPrintedVendorCheckWhenUsingReportStubStubCheck()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        RemitAddress: Record "Remit Address";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 464069] ZIP code on the "Remit to" address is not showing on the printed vendor's check when using NA check report layouts other than 10412
        Initialize();

        // [GIVEN] Vendor Exist with Remit Address as Default
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [GIVEN] Create Payment Journal With "Remit-to Code" for Vendor
        CreateGenJournalLineWithBankAccount(GenJournalLine, "Gen. Journal Document Type"::Payment, "Gen. Journal Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(500, 0), "Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Remit-to Code", RemitAddress.Code);
        GenJournalLine.Modify();

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", Report::"Check (Stub/Stub/Check)");
        ReportSelections.Modify();

        // [GIVEN] Select Bank Account and Last Check No On Report
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify();
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        // [WHEN] Check printed from Payment Journal page
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke();

        // [VERIFY] Verify: Remit Address including Zip Code on Check Report
        VerifyZipCodeOnReport(RemitAddress);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRemitToCodeOnPaymentJournalLineWhenPostedInvoiceAppliedUsingAppliesToDocNo()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        RemitAddress: Record "Remit Address";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 467669] Remit-to Code does not default onto Payment Journal line if user clicks on Applies-to Doc. No. field to apply the payment to invoice on which the Remit-to Code exists
        Initialize();

        // [GIVEN] Create Vendor with Remit Address as Default
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [THEN] Create and post invoice for vendor
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        PurchaseHeader.Validate("Remit-to Code", RemitAddress.Code);
        PurchaseHeader.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create Payment Journal with posted vendor invoice
        CreateGenJournalLineWithBankAccount(
            GenJournalLine,
            "Gen. Journal Document Type"::Payment,
            "Gen. Journal Account Type"::Vendor,
            Vendor."No.",
            LibraryRandom.RandDec(500, 0),
            "Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);

        // [VERIFY] Verify: Remit-to Code on payment journal line
        Assert.AreEqual(RemitAddress.Code, GenJournalLine."Remit-to Code", RemitToCodeMissingErr);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceNAReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintOnInvoiceCheckedOnSalesCommentLineRaiseErrorWhileRunningSalesInvoiceNAReport()
    var
        SalesCommentLine: Record "Sales Comment Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 471909] Having Print on Invoice checkbox checked generate error when running standard Report
        Initialize();

        // [GIVEN] Create and post Sales Invoice.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine);
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for SalesInvoiceNAReportRequestPageHandler.

        // [WHEN] Run Sales Invoice NA Report
        Report.Run(Report::"Sales Invoice NA");  // Opens SalesInvoiceNAReportRequestPageHandler.
        Commit();

        // [VERIFY] Verify: Verify Sales Comment Line after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(SalesCommentToMatch, SalesCommentLine.Comment + ' ');
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), RowMustExist);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,PrintCheckStubStubReqPageHandlerRemitCode,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckStubInfoWhenMultipleRemitToCodesUsedForSingleVendor()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        RemitToAddress: array[2] of Record "Remit Address";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 556064] Check Stub info is correct when Multiple Remit-to Codes are used on multiple Posted Invoices for a single Vendor and Print Check is completed after Summarize Per Vendor groups.
        Initialize();

        // [GIVEN] Create Vendor with multiple Remit To Address.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateRemitToAddress(RemitToAddress[1], Vendor."No.");
        LibraryPurchase.CreateRemitToAddress(RemitToAddress[2], Vendor."No.");

        // [GIVEN] Create Purchase Invoice and Post.
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", '');
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", RemitToAddress[1].Code);
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", RemitToAddress[2].Code);
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", '');
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", RemitToAddress[1].Code);
        CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(PurchaseHeader, Vendor."No.", RemitToAddress[2].Code);

        // [GIVEN] Report 10411 is set as report for Check.
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", Report::"Check (Stub/Check/Stub)");
        ReportSelections.Modify(true);

        // [GIVEN] Create General Journal Batch.
        CreateGeneralJournalBatchWithTemplate(GenJournalBatch);

        // [GIVEN] Create Bank Account and update Last Check No.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);

        // [GIVEN] Open Payment Journal.
        PaymentJournal.OpenEdit();

        // [WHEN] Suggest vendor Payment action invoke with Summarize Per Vendor and Bank Payment Type as Computer Check.
        SuggestVendorPayment(PaymentJournal, GenJournalBatch.Name, Vendor."No.", BankAccount."No.");

        // [WHEN] Print the Check.
        PrintCheck(PaymentJournal, BankAccount."No.");

        //  [THEN] Verify that the Line amount does not contain 0 value.
        VerifyCheckReportLineAmount();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        TaxSetup: Record "Tax Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables setup");
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure CreateGenJournalLineWithBankAccount(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BankPaymentType: Enum "Bank Payment Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostGenJournalLines(GenJnlTemplateType: Enum "Gen. Journal Template Type"; "Page": Option; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenJnlLinesCount: Integer; PurchaseAmount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalTemplate.Get(LibraryJournals.SelectGenJournalTemplate(GenJnlTemplateType, Page));
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        for i := 1 to GenJnlLinesCount do
            LibraryJournals.CreateGenJournalLine2(
              GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocumentType,
              AccountType, AccountNo, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", PurchaseAmount);
        // Test MAX length = 35 (TFS ID: 305391)
        GenJournalLine."External Document No." := CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1);
        GenJournalLine.Modify();

        GenJournalLine.SetRange("Account No.", AccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ToInvoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, ToInvoice));
    end;

    local procedure CreateAndPostSalesDocumentWithCustomer(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ToInvoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, CustomerNo, CreateItem(), LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, ToInvoice));
    end;

    local procedure CreateAndPostInvoiceAndFindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostPurchaseInvoice(CreateItem(), Quantity, DirectUnitCost);
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
    end;

    local procedure CreateAndPostPurchaseInvoice(ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, ItemNo, Quantity, DirectUnitCost);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVendor(ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocumentWithVendor(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, ItemNo, Quantity, DirectUnitCost, VendorNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          CreateItem(), LibraryRandom.RandDec(100, 2));  // Using Random values for Quantity.
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(1000, 2));  // Using Random values for Unit Amount.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithQty(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, Quantity);
        // Using Random values for Quantity.
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(1000, 2));
        // Using Random values for Unit Amount.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostSalesInvWithAdditionalDescription(var Desc: array[2] of Text; var DescLineNo: array[2] of Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        CreateBlankSalesLineWithDesc(Desc[1], DescLineNo[1], SalesHeader."No.", SalesHeader."Document Type");
        CreateBlankSalesLineWithDesc(Desc[2], DescLineNo[2], SalesHeader."No.", SalesHeader."Document Type");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBlankSalesLineWithDesc(var Desc: Text; var DescLineNo: Integer; DocNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine."Document No." := DocNo;
        SalesLine."Document Type" := DocumentType;
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        DescLineNo := SalesLine."Line No.";
        SalesLine.Description := LibraryUtility.GenerateGUID();
        Desc := SalesLine.Description + ' ';
        SalesLine.Insert();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Maximum Inventory", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAssemblyItemWithComponents(NumberOfComponents: Integer; QtyPer: Decimal): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
        LibraryAssembly: Codeunit "Library - Assembly";
        ItemNo: Code[20];
    begin
        LibraryAssembly.CreateItem(
          AssemblyItem, AssemblyItem."Costing Method"::Average, AssemblyItem."Replenishment System"::Assembly, '', '');
        AssemblyItem.Validate("Assembly Policy", AssemblyItem."Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        AssemblyItem.Modify(true);
        if NumberOfComponents <= 0 then
            NumberOfComponents := 1;
        while NumberOfComponents > 0 do begin
            NumberOfComponents -= 1;
            ItemNo := CreateItem();
            CreateAndPostItemJournalLineWithQty(ItemNo, 100 + LibraryRandom.RandDec(10, 2), '');
            LibraryAssembly.CreateAssemblyListComponent(
              BOMComponent.Type::Item, ItemNo, AssemblyItem."No.", '',
              BOMComponent."Resource Usage Type", QtyPer, true);
        end;
        exit(AssemblyItem."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreatePaymentGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        CreatePurchaseDocumentWithVendor(PurchaseLine, DocumentType, ItemNo, Quantity, DirectUnitCost, CreateVendor());
    end;

    local procedure CreatePurchaseDocumentWithVendor(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, Customer."No.", CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesDocumentWithItem(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, Customer."No.", ItemNo, Qty);
    end;

    local procedure CreateSalesDocumentWithCustomerAndItem(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrencyWithExchangeRate());
        Vendor.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Modify(true);
        CreateExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(
          CurrencyExchangeRate, CurrencyCode, CalcDate(StrSubstNo('<-%1M>', LibraryRandom.RandIntInRange(4, 8)), WorkDate()));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDecInDecimalRange(50, 100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount",
          LibraryRandom.RandIntInRange(2, 5) * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure EnqueueValuesForReport(VendorNo: Text; OptionValue: Option)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue values for TopVendorListRequestPageHandler.
        LibraryVariableStorage.Enqueue(OptionValue);
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure RunAndVerifySalesInvoiceReport(CompanyInformationName: Text[100]; PrintCompany: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean)
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(PrintCompany);
        LibraryVariableStorage.Enqueue(LogInteraction);

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify: Verify Company Information and Posted Sales Invoice values on Sales Invoice Report.
        VerifySalesReport(SalesLine, DocumentNo, CompanyInformationName, SalesInvoiceNo, InvoiceItemNo, OrderedQty, ActualLogInteraction);
    end;

    local procedure RunAndVerifySalesInvoiceReportAssembly(NumberOfComponents: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Order.
        CreateSalesDocumentWithItem(
          SalesLine, SalesLine."Document Type"::Order,
          CreateAssemblyItemWithComponents(NumberOfComponents, LibraryRandom.RandDec(10, 2)), LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(true); // Show Assembly Components

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify: Verify total Amount in report.
        VerifySalesReportWithAssembly(SalesLine.Amount);
    end;

    local procedure RunAndVerifySalesInvoiceReportTotals(CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        CreateCustomerWithCurrency(Customer, CurrencyCode);
        DocumentNo := CreateAndPostSalesDocumentWithCustomer(SalesLine, SalesLine."Document Type"::Invoice, Customer."No.", true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(false); // PrintCompany
        LibraryVariableStorage.Enqueue(false); // LogInteraction

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify.
        VerifySalesPurchaseReportTotals(DocumentNo, SalesInvoiceNo, CurrencyCode);
    end;

    local procedure RunAndVerifyPurchInvoiceReportTotals(Vendor: Record Vendor)
    var
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        DocumentNo :=
          CreateAndPostPurchaseInvoiceWithVendor(
            CreateItem(), LibraryRandom.RandIntInRange(1, 10),
            LibraryRandom.RandDecInDecimalRange(10, 100, 2), Vendor."No.");

        // Enqueue value for PurchaseInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Purchase Invoice NA");

        // Verify.
        VerifySalesPurchaseReportTotals(DocumentNo, PurchaseInvoiceNoTxt, Vendor."Currency Code");
    end;

    local procedure RunItemTurnoverReport(ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for ItemTurnoverReqPageHandler.
        REPORT.Run(REPORT::"Item Turnover");
    end;

    local procedure RunPurchaseAdviceReport(PostingDate: Date; ItemNo: Code[20]; PerSKU: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue value for PurchaseAdviceReqPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for PurchaseAdviceReqPageHandler.
        LibraryVariableStorage.Enqueue(PerSKU);
        Commit();  // Commit is required to run Report.
        REPORT.Run(REPORT::"Purchase Advice");
    end;

    local procedure RunPurchaseOrderStatusReport(PostingDate: Date; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue value for PurchaseOrderStatusReqPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for PurchaseOrderStatusReqPageHandler.
        Commit();  // Commit is required to run Report.
        REPORT.Run(REPORT::"Purchase Order Status");
    end;

    local procedure SetupGenJournalLinesForCheckReports(var GenJournalLine: Record "Gen. Journal Line"; var PaymentAmt: Integer; MaxEntries: Integer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchaseAmt: Integer;
    begin
        PurchaseAmt := Sign * LibraryRandom.RandInt(10);
        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        PaymentAmt := LibraryRandom.RandIntInRange(Sign * (MaxEntries + 1) * PurchaseAmt, Sign * (MaxEntries + 9) * PurchaseAmt);
        CreateGenJournalLineWithBankAccount(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType,
          AccountNo, PaymentAmt, GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        CreateAndPostGenJournalLines(
          GenJournalTemplate.Type::Purchases, PAGE::"Purchase Journal",
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, MaxEntries, PurchaseAmt);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure EnablePlanningApplicationAreaSetup()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        ApplicationAreaSetup.Validate("Company Name", CompanyName);
        ApplicationAreaSetup.Validate(Planning, true);
        ApplicationAreaSetup.Insert(true);
        ApplicationAreaMgmtFacade.SetupApplicationArea();
    end;

    local procedure VerifyLogInteraction(DocumentNo: Code[20]; ActualLogInteraction: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        ExpLogInteraction: Boolean;
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        ExpLogInteraction := InteractionLogEntry.IsEmpty();
        Assert.AreEqual(ExpLogInteraction, ActualLogInteraction, ValueMustMatch)
    end;

    local procedure VerifyReportTopVendorList(ColHeadValue: Text[50]; VendorNo: Code[20]; VendorNo2: Code[20]; Amount: Decimal; Amount2: Decimal)
    var
        TotalAmount: Decimal;
    begin
        TotalAmount := Amount + Amount2;
        LibraryReportDataset.AssertElementWithValueExists(MainTitleCap, Format(Top2VendorsCap));
        LibraryReportDataset.AssertElementWithValueExists(ColHeadCap, Format(ColHeadValue));
        VerifyValuesOnTopVendorList(VendorNo, Amount, Round(Amount * 100 / TotalAmount), TotalAmount, 1);  // Using 1 for Rank 1.
        VerifyValuesOnTopVendorList(VendorNo2, Amount2, Round(Amount2 * 100 / TotalAmount), TotalAmount, 2);  // Using 2 for Rank 2.
    end;

    local procedure VerifySalesReport(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; CompanyInformationName: Text[100]; DocumentNoCap: Text[50]; ItemNoCap: Text[50]; QuantityCap: Text[50]; ActualLogInteraction: Boolean)
    begin
        LibraryReportDataset.LoadDataSetFile();
        if SalesLine."Document Type" <> SalesLine."Document Type"::Quote then
            VerifyValuesOnReport(DocumentNo, DocumentNoCap, CompanyAddress, CompanyInformationName);
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, ItemNoCap, SalesLine."No.");
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, QuantityCap, SalesLine.Quantity);
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, TotalPrice, SalesLine.Amount);
        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    local procedure VerifySalesReportWithAssembly(TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(TotalAmount, LibraryReportDataset.Sum(TotalPrice), WrongTotalAmountErr);
    end;

    local procedure VerifySalesPurchaseReportTotals(DocumentNo: Code[20]; DocumentNoCaption: Text[50]; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            CurrencyCode := GetLCYCode();
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(DocumentNo, DocumentNoCaption, TotalCaptionCapTxt, StrSubstNo(TotalCaptionTxt, CurrencyCode));
    end;

    local procedure VerifyTotalLineAmountOnReport(Amount: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalLineAmount', Amount);
    end;

    local procedure VerifyValuesOnTopVendorList(VendorNo: Code[20]; Amount: Decimal; Percentage: Decimal; TotalAmount: Decimal; Rank: Integer)
    begin
        VerifyValuesOnReport(Rank, ICaption, TopNoiCaption, VendorNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(TopAmountiCaption, Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(TopCap, Percentage);
        LibraryReportDataset.AssertCurrentRowValueEquals(GrandTotalCap, TotalAmount);
    end;

    local procedure VerifyValuesOnReport(RowValue: Variant; RowCaption: Text[50]; ValueCaption: Text[50]; Value: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ValueCaption, Value);
    end;

    local procedure VerifyReportValues(RowCaption: Text[50]; RowValue: Code[20]; RowValue1: Code[20])
    begin
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue);
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue1);
    end;

    local procedure VerifyZipCodeOnReport(RemitAddress: Record "Remit Address")
    var
        Country: Record "Country/Region";
    begin
        Country.Get(RemitAddress."Country/Region Code");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CheckToAddr_01_', RemitAddress.Name);
        LibraryReportDataset.AssertElementWithValueExists('CheckToAddr_2_', RemitAddress.Address);
        LibraryReportDataset.AssertElementWithValueExists('CheckToAddr_3_', RemitAddress."Post Code" + ' ' + RemitAddress.City);
        LibraryReportDataset.AssertElementWithValueExists('CheckToAddr_4_', Country.Name);
    end;

    local procedure CreateBankAccount(BankExportCode: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));  // Take Random Value.
        BankAccount.Validate("Positive Pay Export Code", BankExportCode);
        BankAccount.Validate("Bank Account No.", Format(LibraryRandom.RandInt(1000000000)));
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalLineWithWithExportImportBankAccount(
        var GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
                          AccountType: Enum "Gen. Journal Account Type";
                          AccountNo: Code[20];
                          Amount: Decimal;
                          BankPaymentType: Enum "Bank Payment Type";
                          BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            DocumentType,
            AccountType,
            AccountNo,
            Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure FindPositivePayExportDataExchDef(LineType: Option): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchDef.SetRange(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.FindSet();
        repeat
            DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
            DataExchLineDef.SetRange("Line Type", LineType);
            if not DataExchLineDef.IsEmpty() then
                exit(DataExchDef.Code);
        until DataExchDef.Next() = 0;
        exit('');
    end;

    local procedure FilterCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20])
    begin
        CheckLedgerEntry.SetCurrentKey("Bank Account No.", "Check Date");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Check Date", 0D, WorkDate());
    end;

    local procedure GetPositivePayExportedFile(var PositivePayEntry: Record "Positive Pay Entry"; BankAccountNo: Code[20])
    begin
        PositivePayEntry.SetRange("Bank Account No.", BankAccountNo);
        PositivePayEntry.FindFirst();
        PositivePayEntry.CalcFields("Exported File");
    end;

    local procedure CheckRemitAddressNameExistsInFileDetailLine(var PositivePayEntry: Record "Positive Pay Entry"; RemitAddressName: Text[100]) Exists: Boolean;
    var
        Stream: InStream;
        TextLine: Text;
    begin
        PositivePayEntry."Exported File".CreateInStream(Stream);
        while (not Stream.EOS) and (not Exists) do begin
            Stream.ReadText(TextLine);
            Exists := TextLine.Contains(RemitAddressName)
        end;
        exit(Exists);
    end;

    local procedure CreateAndPostSalesDocumentWithSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line"): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomerWithCurrency(Customer, '');

        CreateSalesDocumentWithCustomerAndItem(
            SalesLine,
            SalesHeader."Document Type"::Order,
            Customer."No.",
            CreateItemWithExtendedText(),
            LibraryRandom.RandDec(10, 2));

        CreateSalesCommentLine(
            SalesCommentLine,
            SalesCommentLine."Document Type"::Order,
            SalesLine."Document No.",
            SalesLine."Line No.");

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesCommentLine(
        var SalesCommentLine: Record "Sales Comment Line";
        DocumentType: Enum "Sales Comment Document Type";
                          DocumentNo: Code[20];
                          DocumentLineNo: Integer)
    begin
        LibrarySales.CreateSalesCommentLine(
            SalesCommentLine,
            DocumentType,
            DocumentNo,
            DocumentLineNo);

        SalesCommentLine.Code := LibraryUTUtility.GetNewCode10();
        SalesCommentLine."Print On Invoice" := true;
        SalesCommentLine.Modify(true);
    end;

    local procedure CreateItemWithExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItem());
        Item.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(100, 10000, 2));
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);

        exit(Item."No.");
    end;

    local procedure CreatePurchaseInvoiceForVendorNoWithRemitAddressAndPost(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; RemittoCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        if RemittoCode <> '' then begin
            PurchaseHeader.Validate("Remit-to Code", RemittoCode);
            PurchaseHeader.Modify(true);
        end;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateGeneralJournalBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SuggestVendorPayment(var PaymentJournal: TestPage "Payment Journal"; JournalBatchName: Code[10]; VendorNo: Code[20]; BankAccountNo: Code[20])
    begin
        Commit();  // Commit required for open Payment Journal.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        PaymentJournal.SuggestVendorPayments.Invoke();  // Opens handler - SuggestVendorPaymentRequestPageHandler.
    end;

    local procedure PrintCheck(var PaymentJournal: TestPage "Payment Journal"; BankAccountNo: Code[20])
    begin
        Commit();  // Commit required for open Payment Journal.
        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentJournal.PrintCheck.Invoke();
    end;

    local procedure VerifyCheckReportLineAmount()
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('LineAmount___LineDiscount', 0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferRequestPageHandler(var GSTHSTInternetFileTransfer: TestRequestPage "GST/HST Internet File Transfer")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GSTHSTInternetFileTransfer.StartDate.SetValue(StartDate);
        GSTHSTInternetFileTransfer.EndDate.SetValue(EndDate);
        GSTHSTInternetFileTransfer.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalTestRequestPageHandler(var PaymentJournalTest: TestRequestPage "Payment Journal - Test")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        PaymentJournalTest.ShowDimensions.SetValue(true);
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        PaymentJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintStubStubCheckReqPageHandler(var Check: TestRequestPage "Check (Stub/Stub/Check)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintStubCheckStubReqPageHandler(var Check: TestRequestPage "Check (Stub/Check/Stub)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckStubStubReqPageHandler(var Check: TestRequestPage "Check (Check/Stub/Stub)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintThreeChecksPerPageReqPageHandler(var Check: TestRequestPage "Three Checks per Page")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        SalesInvoice.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        SalesInvoice.LogInteraction.SetValue(LogInteraction);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceAssemblyRequestPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
        ShowAssemblyComponents: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAssemblyComponents);
        SalesInvoice.DisplayAsmInfo.SetValue(ShowAssemblyComponents);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvReqPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    begin
        SalesInvoice."Sales Invoice Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales Shipment NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesShipment.PrintCompanyAddress.SetValue(true);
        SalesShipment.LogInteraction.SetValue(true);
        SalesShipment."Sales Shipment Header".SetFilter("No.", No);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Sales Quote NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesQuote.PrintCompanyAddress.SetValue(true);
        SalesQuote.LogInteraction.SetValue(true);
        SalesQuote."Sales Header".SetFilter("No.", No);
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesOrder.PrintCompanyAddress.SetValue(true);
        SalesOrder.LogInteraction.SetValue(true);
        SalesOrder."Sales Header".SetFilter("No.", No);
        SalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales Credit Memo NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesCreditMemo.PrintCompanyAddress.SetValue(true);
        SalesCreditMemo.LogInteraction.SetValue(true);
        SalesCreditMemo."Sales Cr.Memo Header".SetFilter("No.", No);
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Caption);
        PurchaseBlanketOrder.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderWithErrorRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    begin
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        PurchaseBlanketOrder.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrder.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrder.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrder.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.ArchiveDocument.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrder.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrder.LogInteraction.Caption);
        PurchaseOrder.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrePrintedRequestPageHandler(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.ArchiveDocument.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.LogInteraction.Caption);
        PurchaseOrderPrePrinted.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    begin
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Visible());
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Caption);
        ReturnOrderConfirm.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmWithErrorRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    begin
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ReturnOrderConfirm.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSalesTaxRequestPageHandler(var ServiceCreditMemoSalesTax: TestRequestPage "Service Credit Memo-Sales Tax")
    begin
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Caption);
        ServiceCreditMemoSalesTax.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSalesTaxWithErrorRequestPageHandler(var ServiceCreditMemoSalesTax: TestRequestPage "Service Credit Memo-Sales Tax")
    begin
        asserterror LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ServiceCreditMemoSalesTax.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxRequestPageHandler(var ServiceInvoiceSalesTax: TestRequestPage "Service Invoice-Sales Tax")
    begin
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Visible());
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Caption);
        ServiceInvoiceSalesTax.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxWithErrorRequestPageHandler(var ServiceInvoiceSalesTax: TestRequestPage "Service Invoice-Sales Tax")
    begin
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ServiceInvoiceSalesTax.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TopVendorListRequestPageHandler(var TopVendorList: TestRequestPage "Top __ Vendor List")
    var
        VendorNo: Variant;
        Show: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(Show);
        TopVendorList.Show.SetValue(Show);
        TopVendorList.Vendor.SetFilter("No.", VendorNo);
        TopVendorList.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        TopVendorList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTurnoverReqPageHandler(var ItemTurnover: TestRequestPage "Item Turnover")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemTurnover.Item.SetFilter("Date Filter", Format(WorkDate()));
        ItemTurnover.Item.SetFilter("No.", ItemNo);
        ItemTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceReqPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseAdvice.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseAdvice.Item.SetFilter("No.", ItemNo);
        PurchaseAdvice.UseSKU.SetValue(LibraryVariableStorage.DequeueBoolean());
        PurchaseAdvice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceSKUVisibilityRequestPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    begin
        LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Visible());
        LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Caption);
        PurchaseAdvice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceWithErrorRequestPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    begin
        asserterror LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Visible());
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        PurchaseAdvice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatusReqPageHandler(var PurchaseOrderStatus: TestRequestPage "Purchase Order Status")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseOrderStatus.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseOrderStatus.Item.SetFilter("No.", ItemNo);
        PurchaseOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK().Invoke();
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceSaveAsPDFReqPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseAdvice.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseAdvice.Item.SetFilter("No.", ItemNo);
        PurchaseAdvice.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderCheckVisibilityRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    begin
        LibraryVariableStorage.Enqueue(SalesOrder.ArchiveDocument.Enabled());
        SalesOrder.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceNAReportRequestPageHandler(var SalesInvoicePrePrinted: TestRequestPage "Sales Invoice NA")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesInvoicePrePrinted."Sales Invoice Header".SetFilter("No.", DocumentNo);
        SalesInvoicePrePrinted.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate(Format(LibraryRandom.RandInt(3)) + 'M', WorkDate()));  // Using Random for Months.
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.BalAccountType.SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        SuggestVendorPayments.BankPaymentType.SetValue(GenJournalLine."Bank Payment Type"::"Computer Check");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckStubStubReqPageHandlerRemitCode(var Check: TestRequestPage "Check (Stub/Check/Stub)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
