codeunit 144097 "ERM Reports"
{
    // // [FEATURE] [Report]
    // 1. Test to verify values on Aged Accounts Receivable report after Sales Order posting.
    // 2. Test to verify Payment Discount Amount on Order Confirmation report.
    // 3. Test to verify Payment Discount Amount on Order report.
    // 4. Test to verify that Customer - Summary Aging report ignores Detailed Cust. Ledger Entries
    //    with Excluded from calculation = TRUE
    // 
    // Covers Test Cases for WI - 351123.
    // ---------------------------------------
    // Test Function Name               TFS ID
    // ---------------------------------------
    // AgedAccountsReceivableReport     345408
    // 
    // Covers Test Cases for WI - 351430.
    // ------------------------------------------------
    // Test Function Name                        TFS ID
    // ------------------------------------------------
    // PaymentDiscountOnOrderConfirmationReport  344105
    // PaymentDiscountOnOrderReport              343880

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LineAmtInvDiscAmtPurchLineCap: Label 'LineAmtInvDiscAmt_PurchLine';
        PeriodLengthTxt: Label '1M';
        CustBalDueTxt: Label 'CustBalDue';
        CustBalanceDueTxt: Label 'CustBalanceDue';
        LineTotalCustBalTxt: Label 'LineTotalCustBal';
        LineTotalCustBal1Txt: Label 'LineTotalCustBal1';
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        TotalInclVAT_EC_Lbl: Label 'Total %1 Incl. VAT+EC', Comment = '%1 - Currency Code';
        TotalExclVAT_EC_Lbl: Label 'Total %1 Excl. VAT+EC', Comment = '%1 - Currency Code';
        VAT_EC_Base_CaptionLbl: Label 'VAT + EC Base';
        EC_Pct_CaptionLbl: Label 'EC %';
        EC_Amount_CaptionLbl: Label 'EC Amount';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,OrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnOrderReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Test to verify Payment Discount Amount on Order report.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseOrder(PurchaseLine, Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue for OrderRequestPageHandler.
        Commit();  // commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::Order);  // Opens OrderRequestPageHandler.

        // Verify: Verify Test to verify Payment Discount Amount on Order report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          LineAmtInvDiscAmtPurchLineCap, -Round(PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingExcludeFromCalculation()
    var
        Customer: Record Customer;
        NonExcludedAmount: array[4] of Decimal;
        NonExcludedSum: Decimal;
        I: Integer;
    begin
        // Test to verify that Customer - Summary Aging report ignores Detailed Cust. Ledger Entries
        // with Excluded from calculation = TRUE

        // Setup: Create Customer, Cust. Ledger Entry and Pairs of Detailed Cust. Ledger Entries
        // for all 4 report periods, one with Excluded from calculation = TRUE, one with equal to FALSE
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        for I := 0 to ArrayLen(NonExcludedAmount) - 1 do begin
            NonExcludedAmount[I + 1] :=
              CreatePairDtldCustLedgEntry(Customer."No.", CalcDate('<' + Format(I) + 'M>', WorkDate()));
            NonExcludedSum += NonExcludedAmount[I + 1];
        end;
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for CustomerSummaryAgingRequestPageHandler
        Commit();
        // Exercise.
        REPORT.Run(REPORT::"Customer - Summary Aging");
        // Verify: Verify values on Aged Accounts Receivable report for each of 4 periods and Totals
        VerifyCustomerSummaryAgingRep(NonExcludedSum, NonExcludedAmount);
    end;

    [Test]
    [HandlerFunctions('ArchivedSalesOrderExcelRPH')]
    [Scope('OnPrem')]
    procedure VATAmountOnArchivedSalesOrderWithMultupleLinesExcel()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales] [VAT] [Document Archive]
        // [SCENARIO 377101] "VAT Amount" should be calculated correctly in "Archived Sales Order" report when using multiple lines

        // [GIVEN] Sales Order with two lines, "Total Amount Incl. VAT" = 200, "Total VAT Amount" = 36
        Initialize();
        CreateSalesOrderWithTwoLines(SalesHeader, TempVATAmountLine);

        // [GIVEN] Archived Sales Order
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [WHEN] Open report "Archived Sales Order" in Excel
        RunArchivedSalesOrderReport(SalesHeader."No.");

        // [THEN] "VAT Amount" cell value is 36, "Total Amount Incl. VAT" cell values is 200
        VerifyArchivedSalesOrderExcel(TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('ArchivedSalesOrderDatasetRPH')]
    [Scope('OnPrem')]
    procedure VATAmountOnArchivedSalesOrderWithMultupleLinesDataset()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales] [VAT] [Document Archive]
        // [SCENARIO 377446] "EC %", "EC Amount" should be printed on VAT Amount Specification Section in "Archived Sales Order" report

        // [GIVEN] Sales Order with "VAT %" = 16, "EC %" = 4, Line Amount = 1000
        Initialize();
        CreateSalesOrderWithTwoLines(SalesHeader, TempVATAmountLine);

        // [GIVEN] Archived Sales Order
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [WHEN] Run "Archived Sales Order" report
        RunArchivedSalesOrderReport(SalesHeader."No.");

        // [THEN] Total Document VAT Amount = 200
        // [THEN] VAT Amount Specification section has:
        // [THEN] "VAT %" = 16
        // [THEN] "EC %" = 4
        // [THEN] "VAT Base" = 1000
        // [THEN] "VAT Amount" = 160
        // [THEN] "EC Amount" = 40
        VerifyArchivedSalesOrderDataset(TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('ArchivedPurchOrderPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmountOnArchivedPurchOrderWithMultupleLines()
    var
        PurchHeader: Record "Purchase Header";
        TotalPurchLine: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Purchase] [VAT] [Document Archive]
        // [SCENARIO 377101] "VAT Amount" should be calculated correctly in "Archived Purchase Order" report when using multiple lines

        // [GIVEN] Purchase Order with two lines, "Total Amount Incl. VAT" = 200, "Total VAT Amount" = 36
        Initialize();
        CreatePurchOrderWithTwoLines(PurchHeader, TotalPurchLine);

        // [GIVEN] Archived Purchase Order
        ArchiveManagement.StorePurchDocument(PurchHeader, false);

        // [WHEN] Open report "Archived Purchase Order" in Excel
        RunArchivedPurchaseOrderReport(PurchHeader."No.");

        // [THEN] "VAT Amount" cell value is 36, "Total Amount Incl. VAT" cell values is 200
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          36, 22, LibraryReportValidation.FormatDecimalValue(TotalPurchLine."Amount Including VAT" - TotalPurchLine.Amount), '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          39, 22, LibraryReportValidation.FormatDecimalValue(TotalPurchLine."Amount Including VAT"), '1');
    end;

    [Test]
    [HandlerFunctions('RHCustomerAnnualDeclaration')]
    [Scope('OnPrem')]
    procedure CustomerAnnualDeclarationWithDifferentDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerNo: Code[20];
        AmountLCY: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 165387] Run Customer Annual Declaration using "Posting Date" instead of "Document Date"

        // [GIVEN] Posted sales "Invoice[1]" with "Amount" = 100, "Posting Date" = 25/03/2016 and "Document Date" = 25/05/2016
        // [GIVEN] Posted sales "Invoice[2]" with "Amount" = 200, "Posting Date" = 25/01/2016 and "Document Date" = 25/03/2016
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        AmountLCY := MockCustLedgerEntryWithDifferentDate(CustLedgerEntry, CustomerNo, WorkDate(), CalcDate('<+2M>', WorkDate()));
        MockCustLedgerEntryWithDifferentDate(CustLedgerEntry, CustomerNo, CalcDate('<-2M>', WorkDate()), WorkDate());

        // [WHEN] Run "Customer Annual Declaration" report with "Date Filter" = "01/03/2016..31/03/2016"
        Commit();
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", CalcDate('<CM+1D-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));
        REPORT.Run(REPORT::"Customer - Annual Declaration", true, false, Customer);

        // [THEN] "Amount (LCY)" = 100 in Customer Annual Declaration report
        VerifyCustomerAnnualDeclaration(CustomerNo, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('RHVendorAnnualDeclaration')]
    [Scope('OnPrem')]
    procedure VendorAnnualDeclarationWithDifferentDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        AmountLCY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 165387] Run Vendor Annual Declaration using "Posting Date" instead of "Document Date"

        // [GIVEN] Posted purchase "Invoice[1]" with "Amount" = 100, "Posting Date" = 25/03/2016 and "Document Date" = 25/05/2016
        // [GIVEN] Posted purchase "Invoice[2]" with "Amount" = 200, "Posting Date" = 25/01/2016 and "Document Date" = 25/03/2016
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        AmountLCY := MockVendorLedgerEntryWithDifferentDate(VendorLedgerEntry, VendorNo, WorkDate(), CalcDate('<+2M+1D>', WorkDate()));
        MockVendorLedgerEntryWithDifferentDate(VendorLedgerEntry, VendorNo, CalcDate('<-2M>', WorkDate()), WorkDate());

        // [WHEN] Run "Vendor Annual Declaration" report with "Date Filter" = "01/03/2016..31/03/2016"
        Commit();
        Vendor.SetRange("No.", VendorLedgerEntry."Vendor No.");
        Vendor.SetRange("Date Filter", CalcDate('<CM+1D-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));
        REPORT.Run(REPORT::"Vendor - Annual Declaration", true, false, Vendor);

        // [THEN] "Amount (LCY)" = 100 in Vendor Annual Declaration report
        VerifyVendorAnnualDeclaration(VendorNo, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuotePmtMethodTranslation()
    var
        CompanyInformation: Record "Company Information";
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Quote] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Quote"
        Initialize();

        // [GIVEN] Company Information with "Allow Blank Payment Info."
        CompanyInformation.Get();
        CompanyInformation.Validate("Allow Blank Payment Info.", true);
        CompanyInformation.Modify();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Sales Quote with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Quote, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Quote"
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
        LibraryReportDataset.AssertElementTagWithValueExists('SalesPersonBlank_Lbl', '');
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Service] [Invoice] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Service - Invoice"
        Initialize();

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Service Invoice with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateServiceInvoiceWithPaymentMethod(
          ServiceHeader, PaymentMethod.Code, CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");

        // [WHEN] Run report "Service - Invoice"
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDesc>'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDesc', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('RHCustomerAnnualDeclarationWithMinAmount')]
    procedure CustomerAnnualDeclarationWithNegativeAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerNo: Code[20];
        CrMemoAmountLCY: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 621785] Customer Annual Declaration report should include customers with negative amounts
        // when the absolute value exceeds MinAmount, consistent with Make 347 Declaration

        // [GIVEN] Posted sales credit memo with negative Amount (LCY)
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        CrMemoAmountLCY := MockCustCreditMemoLedgerEntry(CustLedgerEntry, CustomerNo, WorkDate());

        // [WHEN] Run "Customer Annual Declaration" report with MinAmount < Abs(Amount)
        Commit();
        LibraryVariableStorage.Enqueue(Abs(CrMemoAmountLCY) / 2);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", CalcDate('<CM+1D-1M>', WorkDate()), CalcDate('<CM>', WorkDate()));
        Report.Run(Report::"Customer - Annual Declaration", true, false, Customer);

        // [THEN] Customer is included in the report with the negative SalesAmt
        VerifyCustomerAnnualDeclaration(CustomerNo, CrMemoAmountLCY);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();
    end;

    local procedure ModifyLanguageWindowsLanguageID(LanguageCode: Code[10]; WindowsLanguageID: Integer)
    var
        Language: Record Language;
    begin
        Language.Get(LanguageCode);
        Language.Validate("Windows Language ID", WindowsLanguageID);
        Language.Modify(true);
    end;

    local procedure CreateCustomerWithLanguageCode(LanguageCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSalesDocumentWithPaymentMethod(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PaymentMethodCode: Code[10]; CustNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceWithPaymentMethod(var ServiceHeader: Record "Service Header"; PaymentMethodCode: Code[10]; CustNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustNo);
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random for quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustLedgEntry(CustomerNo: Code[20]; PostingDate: Date): Integer
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry.FindLast() then;
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := CustLedgEntry."Entry No." + 1;
        CustLedgEntry."Customer No." := CustomerNo;
        CustLedgEntry."Posting Date" := PostingDate;
        CustLedgEntry.Insert();
        exit(CustLedgEntry."Entry No.");
    end;

    local procedure CreateDtldCustLedgEntry(CustomerNo: Code[20]; InitialEntryDueDate: Date; ExcludedFromCalc: Boolean; AmountLCY: Decimal; CustLedgEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DtldCustLedgEntry.FindLast() then;
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Entry No." := DtldCustLedgEntry."Entry No." + 1;
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DtldCustLedgEntry."Customer No." := CustomerNo;
        DtldCustLedgEntry."Initial Entry Due Date" := InitialEntryDueDate;
        DtldCustLedgEntry."Posting Date" := InitialEntryDueDate;
        DtldCustLedgEntry."Excluded from calculation" := ExcludedFromCalc;
        DtldCustLedgEntry.Amount := AmountLCY;
        DtldCustLedgEntry."Amount (LCY)" := AmountLCY;
        DtldCustLedgEntry.Insert();
    end;

    local procedure CreatePairDtldCustLedgEntry(CustomerNo: Code[20]; InitialEntryDueDate: Date) NotExcludedAmount: Decimal
    var
        CustLedgEntryNo: Integer;
    begin
        NotExcludedAmount := LibraryRandom.RandDec(100, 2);
        CustLedgEntryNo := CreateCustLedgEntry(CustomerNo, InitialEntryDueDate);
        CreateDtldCustLedgEntry(
          CustomerNo, InitialEntryDueDate, true, LibraryRandom.RandDec(100, 2), CustLedgEntryNo);
        CreateDtldCustLedgEntry(
          CustomerNo, InitialEntryDueDate, false, NotExcludedAmount, CustLedgEntryNo);
    end;

    local procedure CreateSalesOrderWithTwoLines(var SalesHeader: Record "Sales Header"; var VATAmountLine: Record "VAT Amount Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 20));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
            SalesLine.Modify(true);
        end;
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        UpdateVATPostingSetup(VATPostingSetup);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);
    end;

    local procedure CreatePurchOrderWithTwoLines(var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDec(10, 2));
            PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchLine.Modify(true);
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        TotalPurchLine.SetRange("Document Type", PurchHeader."Document Type");
        TotalPurchLine.SetRange("Document No.", PurchHeader."No.");
        TotalPurchLine.CalcSums(Amount, "Amount Including VAT");
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentDiscountType: Option; DiscountCalculation: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GeneralLedgerSetup.Validate("Discount Calculation", DiscountCalculation);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandIntInRange(1, 5));
        VATPostingSetup.Modify(true);
    end;

    local procedure MockCustLedgerEntryWithDifferentDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date; DocumentDate: Date): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Date" := DocumentDate;
        CustLedgerEntry.Insert();
        MockDetailedCustLedgerEntry(CustLedgerEntry);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        exit(CustLedgerEntry."Amount (LCY)" + MockGLEntryWithDifferentDate(CustLedgerEntry."Document No.", GLEntry."Gen. Posting Type"::Sale, PostingDate, DocumentDate));
    end;

    local procedure MockVendorLedgerEntryWithDifferentDate(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PostingDate: Date; DocumentDate: Date): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry");
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Date" := DocumentDate;
        VendorLedgerEntry.Insert();
        MockDetailedVendLedgerEntry(VendorLedgerEntry);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        exit(
          -VendorLedgerEntry."Amount (LCY)" -
          MockGLEntryWithDifferentDate(VendorLedgerEntry."Document No.", GLEntry."Gen. Posting Type"::Purchase, PostingDate, DocumentDate));
    end;

    local procedure MockDetailedCustLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure MockDetailedVendLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry."Amount (LCY)" := -LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure MockGLEntryWithDifferentDate(DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; PostingDate: Date; DocumentDate: Date): Decimal
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."Document No." := DocumentNo;
        GLEntry."G/L Account No." := LibraryERM.CreateGLAccountNo();
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Document Date" := DocumentDate;
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry."Gen. Posting Type" := GenPostingType;
        GLEntry.Insert();
        GLAccount.Get(GLEntry."G/L Account No.");
        GLAccount."Ignore in 347 Report" := true;
        GLAccount.Modify();
        exit(GLEntry.Amount);
    end;

    local procedure RunArchivedSalesOrderReport(DocumentNo: Code[20])
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Commit();
        SalesHeaderArchive.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Archived Sales Order", true, false, SalesHeaderArchive);
    end;

    local procedure RunArchivedPurchaseOrderReport(DocumentNo: Code[20])
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        Commit();
        PurchaseHeaderArchive.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Archived Purchase Order", true, false, PurchaseHeaderArchive);
    end;

    local procedure VerifyCustomerSummaryAgingRep(NonExcludedSum: Decimal; NonExcludedAmount: array[4] of Decimal)
    var
        I: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        // Verify Totals
        LibraryReportDataset.AssertElementWithValueExists(LineTotalCustBalTxt, NonExcludedSum);
        LibraryReportDataset.AssertElementWithValueExists(LineTotalCustBal1Txt, NonExcludedSum);
        // Values per Period (should not include Excluded from calculation = TRUE)
        for I := 2 to 5 do
            LibraryReportDataset.AssertElementWithValueExists(
              CustBalDueTxt + Format(I), NonExcludedAmount[I - 1]);
        // Totals for each period (should not include Excluded from calculation = TRUE)
        for I := 9 downto 6 do
            LibraryReportDataset.AssertElementWithValueExists(
              CustBalanceDueTxt + Format(I), NonExcludedAmount[10 - I]);
    end;

    local procedure VerifyArchivedSalesOrderExcel(VATAmountLine: Record "VAT Amount Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryReportValidation.OpenExcelFile();
        // Document Totals
        LibraryReportValidation.VerifyCellValueByRef(
          'L', 76, 1, StrSubstNo(TotalExclVAT_EC_Lbl, GeneralLedgerSetup."LCY Code")); // Total Excl VAT+EC Caption
        LibraryReportValidation.VerifyCellValueByRef(
          'AC', 76, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."VAT Base")); // Total Excl VAT+EC
        LibraryReportValidation.VerifyCellValueByRef(
          'AC', 77, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."VAT Amount" + VATAmountLine."EC Amount")); // VAT+EC Amount
        LibraryReportValidation.VerifyCellValueByRef(
          'L', 80, 1, StrSubstNo(TotalInclVAT_EC_Lbl, GeneralLedgerSetup."LCY Code")); // Total Incl VAT+EC Caption
        LibraryReportValidation.VerifyCellValueByRef(
          'AC', 80, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."Amount Including VAT")); // Total Incl VAT+EC

        // VAT Amount Specification section
        LibraryReportValidation.VerifyCellValueByRef(
          'B', 89, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."VAT %")); // VAT %
        LibraryReportValidation.VerifyCellValueByRef('E', 86, 1, EC_Pct_CaptionLbl); // EC % Caption
        LibraryReportValidation.VerifyCellValueByRef(
          'E', 89, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."EC %")); // EC %
        LibraryReportValidation.VerifyCellValueByRef('O', 86, 1, VAT_EC_Base_CaptionLbl); // VAT Base Caption
        LibraryReportValidation.VerifyCellValueByRef(
          'O', 89, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."VAT Base")); // VAT Base
        LibraryReportValidation.VerifyCellValueByRef(
          'Q', 89, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."VAT Amount")); // VAT Amount
        LibraryReportValidation.VerifyCellValueByRef('X', 86, 1, EC_Amount_CaptionLbl); // EC Amount Caption
        LibraryReportValidation.VerifyCellValueByRef(
          'X', 89, 1, LibraryReportValidation.FormatDecimalValue(VATAmountLine."EC Amount")); // EC Amount
    end;

    local procedure VerifyArchivedSalesOrderDataset(VATAmountLine: Record "VAT Amount Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount', VATAmountLine."VAT Amount" + VATAmountLine."EC Amount");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVAT', VATAmountLine."VAT %");
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLine__EC_Pct', VATAmountLine."EC %");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATBase', VATAmountLine."VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('VATAmtLineVATAmt', VATAmountLine."VAT Amount");
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLine__EC_Amount', VATAmountLine."EC Amount");
    end;

    local procedure VerifyCustomerAnnualDeclaration(CustomerNo: Code[20]; AmountLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Customer__No__', CustomerNo);
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesAmt', AmountLCY);
    end;

    local procedure VerifyVendorAnnualDeclaration(VendorNo: Code[20]; AmountLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Vendor__No__', VendorNo);
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchaseAmt', AmountLCY);
    end;

    local procedure MockCustCreditMemoLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::"Credit Memo";
        CustLedgerEntry."Document No." := LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Date" := PostingDate;
        CustLedgerEntry.Insert();

        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry."Amount (LCY)" := -LibraryRandom.RandDecInRange(100, 1000, 2);
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Insert();

        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingRequestPageHandler(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    var
        CustomerNo: Variant;
    begin
        CustomerSummaryAging.StartingDate.SetValue(WorkDate());
        CustomerSummaryAging.PeriodLength.SetValue(PeriodLengthTxt);
        CustomerSummaryAging.ShowAmountsInLCY.SetValue(false);
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerSummaryAging.Customer.SetFilter("No.", CustomerNo);
        CustomerSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderRequestPageHandler(var "Order": TestRequestPage "Order")
    var
        BuyFromVendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        Order."Purchase Header".SetFilter("Buy-from Vendor No.", BuyFromVendorNo);
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderExcelRPH(var ArchivedSalesOrder: TestRequestPage "Archived Sales Order")
    begin
        ArchivedSalesOrder.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderDatasetRPH(var ArchivedSalesOrder: TestRequestPage "Archived Sales Order")
    begin
        ArchivedSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedPurchOrderPageHandler(var ArchivedPurchOrder: TestRequestPage "Archived Purchase Order")
    begin
        ArchivedPurchOrder.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerAnnualDeclaration(var CustomerAnnualDeclaration: TestRequestPage "Customer - Annual Declaration")
    begin
        CustomerAnnualDeclaration.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorAnnualDeclaration(var VendorAnnualDeclaration: TestRequestPage "Vendor - Annual Declaration")
    begin
        VendorAnnualDeclaration.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RHCustomerAnnualDeclarationWithMinAmount(var CustomerAnnualDeclaration: TestRequestPage "Customer - Annual Declaration")
    var
        MinAmountValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(MinAmountValue);
        CustomerAnnualDeclaration.MinAmount.SetValue(MinAmountValue);
        CustomerAnnualDeclaration.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RHVendorAnnualDeclarationWithMinAmount(var VendorAnnualDeclaration: TestRequestPage "Vendor - Annual Declaration")
    var
        MinAmountValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(MinAmountValue);
        VendorAnnualDeclaration.MinAmount.SetValue(MinAmountValue);
        VendorAnnualDeclaration.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

