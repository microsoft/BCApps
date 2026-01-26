codeunit 144005 "Report Layout - Local"
{
    // // [FEATURE] [Reports]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        VendLedgEntry1DocumentTypeCap: Label 'VendLedgEntry1__Document_Type_';
        VendLedgEntry1DocumentNoCap: Label 'VendLedgEntry1__Document_No__';
        DetailedVLEDocumentTypeCap: Label 'Detailed_Vendor_Ledg__Entry__Document_Type_';
        DetailedVLEDocumentNoCap: Label 'Detailed_Vendor_Ledg__Entry__Document_No__';
        CustLedgEntry1DocumentTypeCap: Label 'CustLedgEntry1__Document_Type_';
        CustLedgEntry1DocumentNoCap: Label 'CustLedgEntry1__Document_No__';
        DetailedCLEDocumentTypeCap: Label 'Detailed_Cust__Ledg__Entry__Document_Type_';
        DetailedCLEDocumentNoCap: Label 'Detailed_Cust__Ledg__Entry__Document_No__';
        InvoiceCap: Label 'Invoice';
        CreditMemoCap: Label 'Credit Memo';
        PaymentCap: Label 'Payment';
        RefundCap: Label 'Refund';
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataSet: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongNoOfExportedEntriesErr: Label 'Wrong no. of exported entries';
        VendLedgEntry1AmountTok: Label 'VendLedgEntry1__Amount__LCY__';
        VendLedgEntry1RemainingAmtTok: Label 'VendLedgEntry1__Remaining_Amt___LCY__';
        VendLedgEntry3OriginalAmtTok: Label 'VendLedgEntry3__Original_Amt___LCY__';
        TotalForVendorTok: Label 'TotalForVendor';
        TotalDtldVendLedgrEntries_Tok: Label 'TotalDtldVendLedgrEntries_';
        ClosedByAmountLCYVendorTok: Label 'ClosedByAmountLCY_Control1130070';
        CustLedgEntry1AmountTok: Label 'CustLedgEntry1__Amount__LCY__';
        CustLedgEntry1RemainingAmtTok: Label 'CustLedgEntry1__Remaining_Amt___LCY__';
        CustLedgEntry3OriginalAmtTok: Label 'CustLedgEntry3__Original_Amt___LCY__';
        TotalForCustomerTok: Label 'TotalForCustomer';
        TotalDtldCustLedgrEntries_Tok: Label 'TotalDtldCustLedgrEntries_';
        ClosedByAmountLCYCustomerTok: Label 'ClosedByAmountLCY_Control1130120';
        TotalClosedByAmntLCYControl1130080Tok: Label 'TotalClosedByAmntLCY_Control1130080';
        TotalClosedByAmntLCYControl1130122Tok: Label 'TotalClosedByAmntLCY_Control1130122';
        StartingDateErr: Label 'Starting Date of the report is not expected';
        EndingDateErr: Label 'Ending Date of the report is not expected';
        BalanceDueTok: Label 'BalanceDue';
        DateFilterErr: Label 'You must specify a date range in the Date Filter field in the request page, such as the past quarter or the current year.';

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorAccountBillsList()
    begin
        Initialize();
        UpdateSalesSetup();

        Commit();
        REPORT.Run(REPORT::"Vendor Account Bills List");
    end;

    [Test]
    [HandlerFunctions('RHFiscalInventoryValuation')]
    [Scope('OnPrem')]
    procedure TestFiscalInventoryValuation()
    begin
        Initialize();
        UpdateSalesSetup();

        Commit();
        REPORT.Run(REPORT::"Fiscal Inventory Valuation");
    end;

    [Test]
    [HandlerFunctions('RHDepreciationBook')]
    [Scope('OnPrem')]
    procedure TestDepreciationBook()
    begin
        Initialize();
        UpdateSalesSetup();

        Commit();
        REPORT.Run(REPORT::"Depreciation Book");
    end;

    [HandlerFunctions('RHVATRegisterPrint')]
    [Scope('OnPrem')]
    procedure TestVATRegisterPrint()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize();
        UpdateSalesSetup();

        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Register Company No."), DATABASE::"Company Information"));
        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Fiscal Code"), DATABASE::"Company Information"));

        Commit();
        REPORT.Run(REPORT::"VAT Register - Print");
    end;

    [Test]
    [HandlerFunctions('RHAnnualVATComm2010')]
    [Scope('OnPrem')]
    procedure TestAnnualVATComm2010()
    begin
        Initialize();
        UpdateSalesSetup();

        Commit();
        REPORT.Run(REPORT::"Annual VAT Comm. - 2010");
    end;

    [Test]
    [HandlerFunctions('RHAccountBookSheetPrint')]
    [Scope('OnPrem')]
    procedure TestAccountBookSheetPrint()
    begin
        Initialize();
        UpdateSalesSetup();

        Commit();
        REPORT.Run(REPORT::"Account Book Sheet - Print");
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::Invoice, false, 0);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListExists(InvoiceCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(InvoiceCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoicePartialApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
        PmtAmount: Decimal;
        DocAmount: Decimal;
    begin
        // [FEATURE] [Vendor Account Bills List]
        // [SCENARIO 375550] Report "Vendor Account Bills List" shows amounts correctly after Invoice and Payment partial apply
        Initialize();

        // [GIVEN] Vendor Invoice with Amount = 1000; Payment applied to the Invoice with Amount = 300
        PmtAmount := VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::Invoice, true, 0.3);
        DocAmount := PmtAmount / 0.3;
        PmtAmount := Round(PmtAmount);

        // [WHEN] Run "Vendor Account Bills List" report
        LibraryReportDataSet.LoadDataSetFile();

        // [THEN] Report shows Invoice Vendor Ledger Entry with Amount = -1000
        // [THEN] Report shows Payment Detailed Vendor Ledger Entry with Amount = 300
        // [THEN] Report shows Total Balance = -700
        VerifyVLEOnVendAccBillListExists(InvoiceCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(InvoiceCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListExists(PaymentCap, PaymentDocNo);

        LibraryReportDataSet.MoveToRow(1);
        VerifyExportedEntriesPairAmounts(
          DocAmount, PmtAmount, 0, DocAmount - PmtAmount, VendLedgEntry1AmountTok, TotalForVendorTok, TotalDtldVendLedgrEntries_Tok,
          ClosedByAmountLCYVendorTok, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoiceOverApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::Invoice, true, 2);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListExists(InvoiceCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(InvoiceCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListExists(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoiceFullApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::Invoice, true, 1);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListExists(InvoiceCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(InvoiceCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListExists(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRefundAndCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::"Credit Memo", false, 0);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListNotExist(CreditMemoCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListExists(RefundCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(CreditMemoCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRefundToCreditMemoPartialApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::"Credit Memo", true, 0.5);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListNotExist(CreditMemoCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListExists(RefundCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListExists(CreditMemoCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRefundToCreditMemoOverApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::"Credit Memo", true, 2);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListNotExist(CreditMemoCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListExists(RefundCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListExists(CreditMemoCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRefundToCreditMemoFullApply()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        VendorAccountBillsListScenario(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::"Credit Memo", true, 1);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyVLEOnVendAccBillListNotExist(CreditMemoCap, PurchaseDocNo);
        VerifyVLEOnVendAccBillListExists(RefundCap, PaymentDocNo);
        VerifyDtldVLEOnVendAccBillListExists(CreditMemoCap, PurchaseDocNo);
        VerifyDtldVLEOnVendAccBillListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoiceNonGLApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Application] [Bill List]
        // [SCENARION 361093] Payment applied to Invoice manually
        Initialize();

        // [GIVEN] Payment applied to Invoice via Vendor Ledger Entry
        VendorAccountBillsListScenarioNonGLApplication(PurchaseDocNo, PaymentDocNo, PurchaseHeader."Document Type"::Invoice, true, 1);

        // [WHEN] Report "Vendor Account Bill List" retrieves detailed ledger entries
        LibraryReportDataSet.LoadDataSetFile();

        // [THEN] Invoice entry must be "parent"
        VerifyVLEOnVendAccBillListExists(InvoiceCap, PurchaseDocNo);
        // [THEN] Payment entry must not be "parent"
        VerifyVLEOnVendAccBillListNotExist(PaymentCap, PaymentDocNo);
        // [THEN] Payment entry must be "child"
        VerifyDtldVLEOnVendAccBillListExists(PaymentCap, PaymentDocNo);
        // [THEN] Invoice entry must not be "child"
        VerifyDtldVLEOnVendAccBillListNotExist(InvoiceCap, PurchaseDocNo);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoicesMultyApplyBeforePostPmt()
    var
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Purchases] [Application] [Bill List]
        // [SCENARIO 363514] "Vendor Account Bills List" should show split payment after applied to two Invoices during posting of the Payment.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "I1" with amount 100
        // [GIVEN] Posted Purchase Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300 applied to "I1" and "I2" in a certain transaction
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostPaymentAppliedToTwoPurchaseInvoices(VendorNo, PaymentNo, InvoiceNo, InvoiceAmount);

        // [WHEN] "Vendor Account Bills List" report exports entries
        RunVendorAccountBillsListReport(VendorNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Vendor Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Vendor Balance Amount" = 0
        // [THEN] Total "Vendor Balance Amount" = 0
        VerifyExportedEntriesAmountsVendor(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPaymentToInvoicesMultyApplyAftePostPmt()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Purchases] [Application] [Bill List]
        // [SCENARIO 363514] "Vendor Account Bills List" should show split payment after applied to two Invoices where the Payment was an applying entry.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "I1" with amount 100
        // [GIVEN] Posted Purchase Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300
        // [GIVEN] "P1" applied to "I1" and "I2"
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostTwoPurchaseInvoicesAndPayment(VendorNo, PaymentNo, InvoiceNo, InvoiceAmount);
        ApplyAndPostVendorDocuments(VendorNo, VendorLedgerEntry."Document Type"::Payment, PaymentNo, InvoiceNo);

        // [WHEN] "Vendor Account Bills List" report exports entries
        RunVendorAccountBillsListReport(VendorNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Vendor Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Vendor Balance Amount" = 0
        // [THEN] Total "Vendor Balance Amount" = 0
        VerifyExportedEntriesAmountsVendor(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListInvoiceToPaymentAndInvoiceApply()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
        ApplyingDocumentNo: Code[20];
        AppliedDocumentNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Purchases] [Application] [Bill List]
        // [SCENARIO 363514] "Vendor Account Bills List" should show split payment after applied to two Invoices where the Invoice was an applying entry.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "I1" with amount 100
        // [GIVEN] Posted Purchase Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300
        // [GIVEN] "I1" applied to "P1" and "I2"
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostTwoPurchaseInvoicesAndPayment(VendorNo, PaymentNo, InvoiceNo, InvoiceAmount);
        ApplyingDocumentNo := InvoiceNo[1];
        AppliedDocumentNo[1] := PaymentNo;
        AppliedDocumentNo[2] := InvoiceNo[2];
        ApplyAndPostVendorDocuments(VendorNo, VendorLedgerEntry."Document Type"::Invoice, ApplyingDocumentNo, AppliedDocumentNo);

        // [WHEN] "Vendor Account Bills List" report exports entries
        RunVendorAccountBillsListReport(VendorNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Vendor Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Vendor Balance Amount" = 0
        // [THEN] Total "Vendor Balance Amount" = 0
        VerifyExportedEntriesAmountsVendor(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerVendorAccountBillsList')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPmtGenJnlLineToInvoicePartApply()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [Purchase] [Application] [Bill List]
        // [SCENARIO 378469] "Vendor Account Bill List" should show correct subtotal Balance for invoice with partially applied payment Gen. Journal Line
        Initialize();

        // [GIVEN] Posted Purchase Invoice with amount 100
        VendorNo := LibraryPurchase.CreateVendorNo();
        DocumentNo := PostPurchaseDocument(ApplyingAmount, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Posted Payment Gen. Journal Line partially applied to invoice with applied amount 35
        ExpectedResult := PostAndApplyPmtGenJnlLine(DocumentNo, GenJournalLine."Account Type"::Vendor, VendorNo, -ApplyingAmount);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [WHEN] Run "Vendor Account Bills List" report
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // [THEN] "Balance Amount" = 65 (100 - 35)
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedVLEDocumentTypeCap, PaymentCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130080Tok, ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerVendorAccountBillsList')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListPmtGenJnlLineWithAmountHigherThenApplying()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Application] [Bill List]
        // [SCENARIO 296925] Report "Customer Bills List" shows <zero> Total when Payment with higher Amount is applied to Sales Invoice
        // [SCENARIO 378837] "Vendor Account Bill List" should show correct subtotal Balance for invoice with partially applied payment Gen. Journal Line with Amount higher than applying
        Initialize();

        // [GIVEN] Posted Purchase Invoice with amount 100
        VendorNo := LibraryPurchase.CreateVendorNo();
        DocumentNo := PostPurchaseDocument(ApplyingAmount, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Posted Payment Gen. Journal Line with amount 135 applied to the invoice
        PostAndApplyPmtGenJnlLineWithHigherAmount(DocumentNo, GenJournalLine."Account Type"::Vendor, VendorNo, -ApplyingAmount);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [WHEN] Run "Vendor Account Bills List" report
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // [THEN] "Balance Amount" = 0
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedVLEDocumentTypeCap, PaymentCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130080Tok, 0);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerVendorAccountBillsList')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListCreditMemoToInvoiceApply()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [Purchase] [Application] [Bill List] [Credit Memo]
        // [SCENARIO 379566] "Vendor Account Bills List" should show correct total Balance with credit memo applied to invoice
        Initialize();

        // [GIVEN] Posted Invoice with amount = "X"
        VendorNo := LibraryPurchase.CreateVendorNo();
        DocumentNo := PostPurchaseDocument(ApplyingAmount, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Posted Credit Memo with amount = "Y" and partially applied to the invoice
        ExpectedResult := PostPurchaseCreditMemoAppliedToInvoice(VendorNo, ApplyingAmount, DocumentNo);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [WHEN] Run "Vendor Account Bills List"
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // [THEN] "Total Balance" = "X" - "Y"
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedVLEDocumentTypeCap, CreditMemoCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130080Tok, ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentAndInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::Invoice, false, 0);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListExists(InvoiceCap, SalesDocNo);
        VerifyCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(InvoiceCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoicePartialApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::Invoice, true, 0.5);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListExists(InvoiceCap, SalesDocNo);
        VerifyCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(InvoiceCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListExists(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoiceOverApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::Invoice, true, 2);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListExists(InvoiceCap, SalesDocNo);
        VerifyCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(InvoiceCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListExists(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoiceFullApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::Invoice, true, 1);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListExists(InvoiceCap, SalesDocNo);
        VerifyCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(InvoiceCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListExists(PaymentCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListRefundAndCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::"Credit Memo", false, 0);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListNotExist(CreditMemoCap, SalesDocNo);
        VerifyCLEOnCustBillsListExists(RefundCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(CreditMemoCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListRefundToCreditMemoPartialApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::"Credit Memo", true, 0.5);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListNotExist(CreditMemoCap, SalesDocNo);
        VerifyCLEOnCustBillsListExists(RefundCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListExists(CreditMemoCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListRefundToCreditMemoOverApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::"Credit Memo", true, 2);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListNotExist(CreditMemoCap, SalesDocNo);
        VerifyCLEOnCustBillsListExists(RefundCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListExists(CreditMemoCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListRefundToCreditMemoFullApply()
    var
        SalesHeader: Record "Sales Header";
        SalesDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        CustomerBillsListScenario(SalesDocNo, PaymentDocNo, SalesHeader."Document Type"::"Credit Memo", true, 1);

        LibraryReportDataSet.LoadDataSetFile();
        VerifyCLEOnCustBillsListNotExist(CreditMemoCap, SalesDocNo);
        VerifyCLEOnCustBillsListExists(RefundCap, PaymentDocNo);
        VerifyDtldCLEOnCustBillsListExists(CreditMemoCap, SalesDocNo);
        VerifyDtldCLEOnCustBillsListNotExist(RefundCap, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoiceNonGLApplication()
    var
        SalesHeader: Record "Sales Header";
        PurchaseDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARION 361353] Payment applied to Invoice manually
        Initialize();

        // [GIVEN] Payment applied to Invoice via Customer Ledger Entry
        CustomerBillsListScenarioNonGLApplication(PurchaseDocNo, PaymentDocNo, SalesHeader."Document Type"::Invoice, true, 1);

        // [WHEN] Report "Customer Bill List" retrieves detailed ledger entries
        LibraryReportDataSet.LoadDataSetFile();

        // [THEN] Invoice entry must be "parent"
        VerifyCLEOnCustBillsListExists(InvoiceCap, PurchaseDocNo);
        // [THEN] Payment entry must not be "parent"
        VerifyCLEOnCustBillsListNotExist(PaymentCap, PaymentDocNo);
        // [THEN] Payment entry must be "child"
        VerifyDtldCLEOnCustBillsListExists(PaymentCap, PaymentDocNo);
        // [THEN] Invoice entry must not be "child"
        VerifyDtldCLEOnCustBillsListNotExist(InvoiceCap, PurchaseDocNo);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoicesMultyApplyBeforePostPmt()
    var
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARIO 363514] "Customer Bills List" should show split payment after applied to two Invoices during posting of the Payment.
        Initialize();

        // [GIVEN] Posted Sales Invoice "I1" with amount 100
        // [GIVEN] Posted Sales Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300 applied to "I1" and "I2" in a certain transaction
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostPaymentAppliedToTwoSalesInvoices(CustomerNo, PaymentNo, InvoiceNo, InvoiceAmount);

        // [WHEN] "Customer Account Bills List" report exports entries
        RunCustomerBillsListReport(CustomerNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Customer Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Customer Balance Amount" = 0
        // [THEN] Total "Customer Balance Amount" = 0
        VerifyExportedEntriesAmountsCustomer(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPaymentToInvoicesMultyApplyAftePostPmt()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARIO 363514] "Customer Bills List" should show split payment after applied to two Invoices where the Payment was an applying entry.
        Initialize();

        // [GIVEN] Posted Sales Invoice "I1" with amount 100
        // [GIVEN] Posted Sales Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300
        // [GIVEN] "P1" applied to "I1" and "I2"
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostTwoSalesInvoicesAndPayment(CustomerNo, PaymentNo, InvoiceNo, InvoiceAmount);
        ApplyAndPostCustomerDocuments(
          CustomerNo, CustLedgerEntry."Document Type"::Payment, PaymentNo, InvoiceNo);

        // [WHEN] "Customer Account Bills List" report exports entries
        RunCustomerBillsListReport(CustomerNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Customer Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Customer Balance Amount" = 0
        // [THEN] Total "Customer Balance Amount" = 0
        // [THEN] Detailed customer ledger entry for applied payment should be ones
        VerifyExportedEntriesAmountsCustomer(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListInvoiceToPaymentAndInvoiceApply()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        ApplyingDocumentNo: Code[20];
        AppliedDocumentNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARIO 363514] "Customer Bills List" should show split payment after applied to two Invoice where an Invoice was an applying entry.
        Initialize();

        // [GIVEN] Posted Sales Invoice "I1" with amount 100
        // [GIVEN] Posted Sales Invoice "I2" with amount 200
        // [GIVEN] Posted Payment "P1" with amount 300
        // [GIVEN] "I1" applied to "P1" and "I2"
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostTwoSalesInvoicesAndPayment(CustomerNo, PaymentNo, InvoiceNo, InvoiceAmount);
        ApplyingDocumentNo := InvoiceNo[1];
        AppliedDocumentNo[1] := PaymentNo;
        AppliedDocumentNo[2] := InvoiceNo[2];
        ApplyAndPostCustomerDocuments(CustomerNo, CustLedgerEntry."Document Type"::Invoice, ApplyingDocumentNo, AppliedDocumentNo);

        // [WHEN] "Customer Account Bills List" report exports entries
        RunCustomerBillsListReport(CustomerNo);

        // [THEN] Exported payment amount for invoice "I1" = 100. "Customer Balance Amount" = 200
        // [THEN] Exported payment amount for invoice "I2" = 200. "Customer Balance Amount" = 0
        // [THEN] Total "Customer Balance Amount" = 0
        VerifyExportedEntriesAmountsCustomer(InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerCustomerBillsList')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPmtGenJnlLineToInvoicePartApply()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARIO 378469] "Customer Bills List" should show correct subtotal Balance for invoice with partially applied payment Gen. Journal Line
        Initialize();

        // [GIVEN] Posted Sales Invoice with amount 100
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocumentNo := PostSalesDocument(ApplyingAmount, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Posted Payment Gen. Journal Line partially applied to with applied amount 35
        ExpectedResult := PostAndApplyPmtGenJnlLine(DocumentNo, GenJournalLine."Account Type"::Customer, CustomerNo, ApplyingAmount);
        LibraryVariableStorage.Enqueue(CustomerNo);

        // [WHEN] Run "Customer Bills List" report
        REPORT.Run(REPORT::"Customer Bills List");

        // [THEN] "Balance Amount" = 65 (100 - 35)
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedCLEDocumentTypeCap, PaymentCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130122Tok, ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerCustomerBillsList')]
    [Scope('OnPrem')]
    procedure CustomerBillsListPmtGenJnlLineWithAmountHigherThenApplying()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List]
        // [SCENARIO 296925] Report "Customer Bills List" shows <zero> Total when Payment with higher Amount is applied to Sales Invoice
        // [SCENARIO 378837] "Customer Bills List" should show correct subtotal Balance for invoice with partially applied payment Gen. Journal Line with Amount is higher than applying amount
        Initialize();

        // [GIVEN] Posted Sales Invoice with amount 100
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocumentNo := PostSalesDocument(ApplyingAmount, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Posted Payment Gen. Journal Line with amount 135 applied to the invoice
        PostAndApplyPmtGenJnlLineWithHigherAmount(DocumentNo, GenJournalLine."Account Type"::Customer, CustomerNo, ApplyingAmount);
        LibraryVariableStorage.Enqueue(CustomerNo);

        // [WHEN] Run "Customer Bills List" report
        REPORT.Run(REPORT::"Customer Bills List");

        // [THEN] "Balance Amount" = 0
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedCLEDocumentTypeCap, PaymentCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130122Tok, 0);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerCustomerBillsList')]
    [Scope('OnPrem')]
    procedure CustomerBillsListCreditMemoToInvoiceApply()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ApplyingAmount: Decimal;
        ExpectedResult: Decimal;
    begin
        // [FEATURE] [Sales] [Application] [Bill List] [Credit Memo]
        // [SCENARIO 379566] "Customer Bills List" should show correct total Balance with credit memo applied to invoice
        Initialize();

        // [GIVEN] Posted Invoice with amount = "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocumentNo := PostSalesDocument(ApplyingAmount, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Posted Credit Memo with amount = "Y" and partially applied to the invoice
        ExpectedResult := PostSalesCreditMemoAppliedToInvoice(CustomerNo, ApplyingAmount, DocumentNo);
        LibraryVariableStorage.Enqueue(CustomerNo);

        // [WHEN] Run "Customer Bills List"
        REPORT.Run(REPORT::"Customer Bills List");

        // [THEN] "Total Balance" = "X" - "Y"
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(DetailedCLEDocumentTypeCap, CreditMemoCap);
        LibraryReportDataSet.GetNextRow();
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalClosedByAmntLCYControl1130122Tok, ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('RHDepreciationBookCheckDates')]
    [Scope('OnPrem')]
    procedure TestDepreciationBookRequestPageDatesOnInit()
    var
        DepreciationBookId: Integer;
    begin
        // [FEATURE] [Depreciation Book]
        // [SCENARIO 252017] Dates on the Request Page for Depreciation Book report is set to the current year on initialization.
        Initialize();
        UpdateSalesSetup();

        // [GIVEN] No saved options for Report 12119 "Depreciation Book".
        DepreciationBookId := REPORT::"Depreciation Book";
        LibraryReportValidation.DeleteObjectOptions(DepreciationBookId);
        Commit();

        // [WHEN] Run Report 12119 "Depreciation Book".
        // [THEN] Starting date is set to the first day of current year and Ending date is to the last day.
        REPORT.Run(REPORT::"Depreciation Book");
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillListPartialPaymentApplicationForInvoiceWithPaymentTerms()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PmtRate: array[2] of Integer;
        Days: array[2] of Integer;
        AmountToPay: Decimal;
        AmountToApply: array[2] of Decimal;
        InvoiceAmount: array[2] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Application] [Bill List] [Payment Terms]
        // [SCENARIO 296925] Vendor Accounts Bill List report when Purchase Invoice was posted with Payment Terms and partial Payment was applied
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitInvoicePaymentAmountsWithPmtRate(PmtRate, Days, AmountToPay, AmountToApply);

        // [GIVEN] Payment Terms with 2 Lines:
        // [GIVEN] 1st Line has Payment % = 40%, Due Date Calculation = <1D>
        // [GIVEN] 2nd Line has Payment % = 60%, Due Date Calculation = <2D>
        // [GIVEN] Posted Purchase Invoice with Amount 1000 at 1/1/2019 (Two Vendor Ledger Entries were created with Amounts -400 and -600 respectfully)
        CreatePurchaseInvoiceWithPaymentTerms(PurchaseHeader, CreatePaymentTermsWithTwoLines(PmtRate, Days), AmountToPay * 2);
        GetAmountsFromInvoiceVendLedgerEntry(InvoiceAmount, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Created Payment Gen. Journal Line with Amount 250 at 1/4/2019
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", AmountToPay);
        GenJournalLine.Validate("Posting Date", CalcDate(StrSubstNo('<%1D>', Days[2] + 1), WorkDate()));
        GenJournalLine.Modify(true);

        // [GIVEN] Applied Amount -100 to first Vendor Ledger Entry and -150 to second Vendor Ledger Entry and Posted Gen. Journal Line
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AmountToApply[1], -AmountToApply[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RemainingAmount[1] := InvoiceAmount[1] - AmountToApply[1];
        RemainingAmount[2] := InvoiceAmount[2] - AmountToApply[2];
        Vendor.SetRange("No.", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run report "Vendor Accounts Bill List"
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 4 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -400 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -300
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 250 and 'ClosedByAmountLCY_Control1130070' = 100
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry1__Amount__LCY__' = -600 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -450
        // [THEN] Report Dataset 4th row has 'VendLedgEntry3__Original_Amt___LCY__' = 250 and 'ClosedByAmountLCY_Control1130070' = 150
        // [THEN] Report Dataset 4th row has 'BalanceDue' = -300 - 450 = -750
        VerifyBillsReportsPaymentAppliedToTwoInvoices(VendorTags, InvoiceAmount, RemainingAmount, AmountToPay, AmountToApply, -1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountBillListPartialPaymentApplicationForInvoiceWithPaymentTerms()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PmtRate: array[2] of Integer;
        Days: array[2] of Integer;
        AmountToPay: Decimal;
        AmountToApply: array[2] of Decimal;
        InvoiceAmount: array[2] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Application] [Bill List] [Payment Terms]
        // [SCENARIO 296925] Customer Bills List report when Sales Invoice was posted with Payment Terms and partial Payment was applied
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitInvoicePaymentAmountsWithPmtRate(PmtRate, Days, AmountToPay, AmountToApply);

        // [GIVEN] Payment Terms with 2 Lines:
        // [GIVEN] 1st Line has Payment % = 40%, Due Date Calculation = <1D>
        // [GIVEN] 2nd Line has Payment % = 60%, Due Date Calculation = <2D>
        // [GIVEN] Posted Sales Invoice with Amount 1000 at 1/1/2019 (Two Customer Ledger Entries were created with Amounts 400 and 600 respectfully)
        CreateSalesInvoiceWithPaymentTerms(SalesHeader, CreatePaymentTermsWithTwoLines(PmtRate, Days), AmountToPay * 2);
        GetAmountsFromInvoiceCustLedgerEntry(InvoiceAmount, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Created Payment Gen. Journal Line with Amount -250 at 1/4/2019
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", -AmountToPay);
        GenJournalLine.Validate("Posting Date", CalcDate(StrSubstNo('<%1D>', Days[2] + 1), WorkDate()));
        GenJournalLine.Modify(true);

        // [GIVEN] Applied Amount 100 to first Customer Ledger Entry and 150 to second Customer Ledger Entry and Posted Gen. Journal Line
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AmountToApply[1], AmountToApply[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RemainingAmount[1] := InvoiceAmount[1] - AmountToApply[1];
        RemainingAmount[2] := InvoiceAmount[2] - AmountToApply[2];
        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");

        // [WHEN] Run report "Customer Accounts Bill List"
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 4 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 400 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 300
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -250 and 'ClosedByAmountLCY_Control1130120' = -100
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry1__Amount__LCY__' = 600 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 450
        // [THEN] Report Dataset 4th row has 'CustLedgEntry3__Original_Amt___LCY__' = -250 and 'ClosedByAmountLCY_Control1130120' = -150
        // [THEN] Report Dataset 4th row has 'BalanceDue' = 300 + 450 = 750
        VerifyBillsReportsPaymentAppliedToTwoInvoices(CustomerTags, InvoiceAmount, RemainingAmount, AmountToPay, AmountToApply, 1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyPaymToManyInvUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Payments are applied to Several Invoices and total paid Amount is less than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 210 was applied to Invoices: -100 to "I1" and -110 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -100
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 100
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -50
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = -100 - 50 = -150
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyPaymToManyInvFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Payments are applied to Several Invoices and total paid Amount equals to total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 360 was applied to Invoices: -200 to "I1" and -160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyPaymToManyInvOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Payments are applied to Several Invoices and total paid Amount is higher than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        PaidAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1000 was applied to Invoices: -200 to "I1" and -160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyPaymUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Payments and total paid Amount is less than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 210 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: 1000 to "P1" and 100 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: 800 to "P1" and 110 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -100
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 100
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -50
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = -100 - 50 = -150
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyPaymFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Payments and total paid Amount equals to total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 360 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: 1000 to "P1" and 200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: 800 to "P1" and 160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyPaymOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Payments and total paid Amount is higher than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        PaidAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 1000 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PaidAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: 1000 to "P1" and 200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: 800 to "P1" and 160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyCrMemoToManyInvUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Credit Memo are applied to Several Invoices and total returned Amount is less than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 210 was applied to Invoices: -100 to "I1" and -110 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -100
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 100
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -50
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = -100 - 50 = -150
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyCrMemoToManyInvFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Credit Memo are applied to Several Invoices and total returned Amount equals to total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 360 was applied to Invoices: -200 to "I1" and -160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyCrMemoToManyInvOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Credit Memos are applied to Several Invoices and total returned Amount is higher than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        ReturnedAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Purchase Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: -1000 to "I1" and -800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[1], -AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1000 was applied to Invoices: -200 to "I1" and -160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, -AppliedAmount[3], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyCrMemoUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Credit Memo and total returned Amount is less than total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 210 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: 1000 to "P1" and 100 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: 800 to "P1" and 110 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -100
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 100
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = -50
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 210 and 'ClosedByAmountLCY_Control1130070' = 110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = -100 - 50 = -150
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyCrMemoFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Credit Memo and total returned Amount equals to total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 360 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: 1000 to "P1" and 200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: 800 to "P1" and 160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 360 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBillListApplManyInvToManyCrMemoOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        VendorTags: array[4] of Text;
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Vendor Account Bills List report when Several Invoices are applied to Several Credit Memo and total returned Amount is higher then total invoiced Amount
        Initialize();
        InitVendorTagsArray(VendorTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        ReturnedAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 1000 both for same Vendor
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          ReturnedAmount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: 1000 to "P1" and 200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[1]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[1], AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: 800 to "P1" and 160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount[2]);
        ApplyGenJournalLineTwoVendorDocs(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AppliedAmount[2], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Vendor Account Bills List
        REPORT.Run(REPORT::"Vendor Account Bills List", true, false, Vendor);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'VendLedgEntry1__Amount__LCY__' = -1200 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 1000
        // [THEN] Report Dataset 3rd row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 200
        // [THEN] Report Dataset 4th row has 'VendLedgEntry1__Amount__LCY__' = -960 and 'VendLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1800 and 'ClosedByAmountLCY_Control1130070' = 800
        // [THEN] Report Dataset 6th row has 'VendLedgEntry3__Original_Amt___LCY__' = 1000 and 'ClosedByAmountLCY_Control1130070' = 160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(VendorTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, -1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyPaymToManyInvUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Payments are applied to Several Invoices and total paid Amount is less than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 210 was applied to Invoices: 100 to "I1" and 110 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 100
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -100
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 50
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 100 + 50 = 150
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyPaymToManyInvFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Payments are applied to Several Invoices and total paid Amount equals to total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 360 was applied to Invoices: 200 to "I1" and 160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyPaymToManyInvOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Payments are applied to Several Invoices and total paid Amount is higher than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        PaidAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment with Amount 1000 was applied to Invoices: 200 to "I1" and 160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -PaidAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyPaymUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Payments and total paid Amount is less than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 210 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaidAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: -1000 to "P1" and -100 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: -800 to "P1" and -110 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 100
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -100
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 50
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 100 + 50 = 150
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyPaymFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Payments and total paid Amount equals to total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 360 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaidAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: -1000 to "P1" and -200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: -800 to "P1" and -160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyPaymOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Payments and total paid Amount is higher than invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, PaidAmount, AppliedAmount, 2);
        PaidAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Payments: "P1" with Amount 1800 and "P2" with Amount 1000 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaidAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Payments: -1000 to "P1" and -200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Payments: -800 to "P1" and -160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Payment, -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, PaidAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyCrMemoToManyInvUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Credit Memos are applied to Several Invoices and total returned Amount is less than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 210 was applied to Invoices: 100 to "I1" and 110 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 100
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -100
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 50
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 100 + 50 = 150
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyCrMemoToManyInvFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Credit Memos are applied to Several Invoices and total returned Amount equals to total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 360 was applied to Invoices: 200 to "I1" and 160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyCrMemoToManyInvOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Credit Memos are applied to Several Invoices and total returned Amount is higher than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        ReturnedAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Sales Invoices: "I1" with Amount 1200 and "I2" with Amount 960 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount, 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1800 was applied to Invoices: 1000 to "I1" and 800 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[1]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[1], AppliedAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo with Amount 1000 was applied to Invoices: 200 to "I1" and 160 to "I2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -ReturnedAmount[2]);
        ApplyGenJournalLineTwoCustomerDocs(GenJournalLine, GenJournalLine."Document Type"::Invoice, AppliedAmount[3], AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Account Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyCrMemoUnderPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Credit Memos and total returned Amount is less than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 4);
        RemainingAmount[1] := Amount[1] - AppliedAmount[1] - AppliedAmount[3];
        RemainingAmount[2] := Amount[2] - AppliedAmount[2] - AppliedAmount[4];
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 210 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          ReturnedAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: -1000 to "P1" and -100 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: -800 to "P1" and -110 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 100
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -100
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 50
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -210 and 'ClosedByAmountLCY_Control1130120' = -110
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 100 + 50 = 150
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyCrMemoFullPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Credit Memos and total returned Amount equals to total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 360 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          ReturnedAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: -1000 to "P1" and -200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: -800 to "P1" and -160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -360 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustBillListApplManyInvToManyCrMemoOverPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Amount: array[2] of Decimal;
        ReturnedAmount: array[2] of Decimal;
        AppliedAmount: array[4] of Decimal;
        RemainingAmount: array[2] of Decimal;
        CustomerTags: array[4] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Application] [Bill List]
        // [SCENARIO 296925] Customer Bills List report when Several Invoices are applied to Several Credit Memos and total returned Amount is higher than total invoiced Amount
        Initialize();
        InitCustomerTagsArray(CustomerTags);
        InitAmounts(Amount, ReturnedAmount, AppliedAmount, 2);
        ReturnedAmount[2] *= 2;
        RemainingAmount[1] := 0;
        RemainingAmount[2] := 0;
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Posted Credit Memos: "P1" with Amount 1800 and "P2" with Amount 1000 both for same Customer
        CreateTwoGenJnlLinesForSameAccountInSameBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          ReturnedAmount, -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 1200 was applied to Credit Memos: -1000 to "P1" and -200 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[1], -AppliedAmount[3]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Invoice with Amount 960 was applied to Credit Memos: -800 to "P1" and -160 to "P2"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[2]);
        ApplyGenJournalLineTwoCustomerDocs(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", -AppliedAmount[2], -AppliedAmount[4]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report Customer Bills List
        REPORT.Run(REPORT::"Customer Bills List", true, false, Customer);

        // [THEN] Report Dataset has 6 rows:
        // [THEN] Report Dataset 1st row has 'CustLedgEntry1__Amount__LCY__' = 1200 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 2nd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -1000
        // [THEN] Report Dataset 3rd row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -200
        // [THEN] Report Dataset 4th row has 'CustLedgEntry1__Amount__LCY__' = 960 and 'CustLedgEntry1__Remaining_Amt___LCY__' = 0
        // [THEN] Report Dataset 5th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1800 and 'ClosedByAmountLCY_Control1130120' = -800
        // [THEN] Report Dataset 6th row has 'CustLedgEntry3__Original_Amt___LCY__' = -1000 and 'ClosedByAmountLCY_Control1130120' = -160
        // [THEN] Report Dataset 6th row has 'BalanceDue' = 0
        VerifyBillsReportsAmountsManyToMany(CustomerTags, Amount, RemainingAmount, ReturnedAmount, AppliedAmount, 1);
    end;

    [Test]
    [HandlerFunctions('RHFiscalInventoryValuationWithoutDateFilter')]
    [Scope('OnPrem')]
    procedure DateFilterErrorFiscalInventoryValuation()
    begin
        // [FEATURE] [UT][UI]
        // [SCENARIO 416157] Date Filter error arises if Item."Date Filter" is empty
        Initialize();
        UpdateSalesSetup();

        Commit();
        asserterror REPORT.Run(REPORT::"Fiscal Inventory Valuation");

        Assert.ExpectedError(DateFilterErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        SetFiscalCodeAndRegCompanyNoOnCompanyInfo();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure InitAmounts(var Amount: array[2] of Decimal; var PaidAmount: array[2] of Decimal; var AppliedAmount: array[4] of Decimal; Divisor: Integer)
    begin
        Amount[1] := LibraryRandom.RandDecInRange(1000, 2000, 2) * 4;
        Amount[2] := LibraryRandom.RandDecInRange(1000, 2000, 2) * 4;
        AppliedAmount[1] := Amount[1] / 2;
        AppliedAmount[2] := Amount[2] / 2;
        AppliedAmount[3] := Amount[1] / Divisor;
        AppliedAmount[4] := Amount[2] / Divisor;
        PaidAmount[1] := AppliedAmount[1] + AppliedAmount[2];
        PaidAmount[2] := AppliedAmount[3] + AppliedAmount[4];
    end;

    local procedure InitInvoicePaymentAmountsWithPmtRate(var PmtRate: array[2] of Integer; var Days: array[2] of Integer; var AmountToPay: Decimal; var AmountToApply: array[2] of Decimal)
    begin
        PmtRate[1] := LibraryRandom.RandIntInRange(30, 40);
        PmtRate[2] := 100 - PmtRate[1];
        Days[1] := LibraryRandom.RandInt(4);
        Days[2] := Days[1] + LibraryRandom.RandInt(5);
        AmountToPay := 100 * LibraryRandom.RandDecInRange(100, 200, 2);
        AmountToApply[1] := Round(AmountToPay * PmtRate[1] / 100);
        AmountToApply[2] := Round(AmountToPay * PmtRate[2] / 100);
        AmountToPay := AmountToApply[1] + AmountToApply[2];
    end;

    local procedure InitVendorTagsArray(var VendorTags: array[4] of Text)
    begin
        VendorTags[1] := VendLedgEntry1AmountTok;
        VendorTags[2] := VendLedgEntry1RemainingAmtTok;
        VendorTags[3] := VendLedgEntry3OriginalAmtTok;
        VendorTags[4] := ClosedByAmountLCYVendorTok;
    end;

    local procedure InitCustomerTagsArray(var CustomerTags: array[4] of Text)
    begin
        CustomerTags[1] := CustLedgEntry1AmountTok;
        CustomerTags[2] := CustLedgEntry1RemainingAmtTok;
        CustomerTags[3] := CustLedgEntry3OriginalAmtTok;
        CustomerTags[4] := ClosedByAmountLCYCustomerTok;
    end;

    local procedure VendorAccountBillsListScenario(var PurchaseDocNo: Code[20]; var PaymentDocNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Apply: Boolean; ApplyFactor: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        AppliesToDocType: Enum "Gen. Journal Account Type";
        AppliesToDocNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        PurchaseDocNo := PostPurchaseDocument(Amount, DocumentType, VendorNo);

        case DocumentType of
            PurchaseHeader."Document Type"::Invoice:
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Payment;
                    AppliesToDocType := GenJournalLine."Applies-to Doc. Type"::Invoice;
                end;
            PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Refund;
                    AppliesToDocType := GenJournalLine."Applies-to Doc. Type"::"Credit Memo";
                    Amount := -Amount;
                end;
        end;
        if Apply then begin
            AppliesToDocNo := PurchaseDocNo;
            Amount *= ApplyFactor;
        end;

        PaymentDocNo := CreateApplyAndPostGeneralJournalLine(
            GenJournalDocumentType, GenJournalLine."Account Type"::Vendor, VendorNo,
            AppliesToDocType, AppliesToDocNo, Amount);
        RunVendorAccountBillsListReport(VendorNo);

        exit(Amount);
    end;

    local procedure VendorAccountBillsListScenarioNonGLApplication(var PurchaseDocNo: Code[20]; var AppliedDocNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Apply: Boolean; ApplyFactor: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        PurchaseDocNo := PostPurchaseDocument(Amount, DocumentType, VendorNo);

        case DocumentType of
            PurchaseHeader."Document Type"::Invoice:
                GenJournalDocumentType := GenJournalLine."Document Type"::Payment;
            PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Refund;
                    Amount := -Amount;
                end;
        end;
        if Apply then
            Amount *= ApplyFactor;

        AppliedDocNo :=
          CreatePostGeneralJournalLine(
            GenJournalDocumentType,
            GenJournalLine."Account Type"::Vendor,
            VendorNo,
            Amount);
        ApplyAndPostVendorEntry(
          VendorLedgerEntry."Document Type"::Invoice, PurchaseDocNo, VendorLedgerEntry."Document Type"::Payment, AppliedDocNo);

        RunVendorAccountBillsListReport(VendorNo);
    end;

    local procedure CustomerBillsListScenario(var SalesDocNo: Code[20]; var PaymentDocNo: Code[20]; DocumentType: Enum "Sales Document Type"; Apply: Boolean; ApplyFactor: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Line";
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        AppliesToDocType: Enum "Gen. Journal Account Type";
        AppliesToDocNo: Code[20];
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        SalesDocNo := PostSalesDocument(Amount, DocumentType, CustomerNo);

        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Payment;
                    AppliesToDocType := GenJournalLine."Applies-to Doc. Type"::Invoice;
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Refund;
                    AppliesToDocType := GenJournalLine."Applies-to Doc. Type"::"Credit Memo";
                    Amount := -Amount;
                end;
        end;
        if Apply then begin
            AppliesToDocNo := SalesDocNo;
            Amount *= ApplyFactor;
        end;

        PaymentDocNo := CreateApplyAndPostGeneralJournalLine(
            GenJournalDocumentType, GenJournalLine."Account Type"::Customer, CustomerNo,
            AppliesToDocType, AppliesToDocNo, -Amount);
        RunCustomerBillsListReport(CustomerNo);
    end;

    local procedure CustomerBillsListScenarioNonGLApplication(var SalesDocNo: Code[20]; var AppliedDocNo: Code[20]; DocumentType: Enum "Sales Document Type"; Apply: Boolean; ApplyFactor: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        SalesDocNo := PostSalesDocument(Amount, DocumentType, CustomerNo);

        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                GenJournalDocumentType := GenJournalLine."Document Type"::Payment;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    GenJournalDocumentType := GenJournalLine."Document Type"::Refund;
                    Amount := -Amount;
                end;
        end;
        if Apply then
            Amount *= ApplyFactor;

        AppliedDocNo :=
          CreatePostGeneralJournalLine(
            GenJournalDocumentType,
            GenJournalLine."Account Type"::Customer,
            CustomerNo,
            -Amount);
        ApplyAndPostCustomerEntry(
          CustLedgerEntry."Document Type"::Invoice, SalesDocNo, CustLedgerEntry."Document Type"::Payment, AppliedDocNo);

        RunCustomerBillsListReport(CustomerNo);
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    local procedure ApplyGenJournalLineTwoVendorDocs(var GenJournalLine: Record "Gen. Journal Line"; ApplyToDocType: Enum "Gen. Journal Document Type"; AmountToApply1: Decimal; AmountToApply2: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
        VendorLedgerEntry.SetRange("Document Type", ApplyToDocType);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.FindSet();
        VendorLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply1);
        VendorLedgerEntry.Modify(true);
        VendorLedgerEntry.Next();
        VendorLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply2);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure ApplyGenJournalLineTwoCustomerDocs(var GenJournalLine: Record "Gen. Journal Line"; ApplyToDocType: Enum "Gen. Journal Document Type"; AmountToApply1: Decimal; AmountToApply2: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
        CustLedgerEntry.SetRange("Document Type", ApplyToDocType);
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.FindSet();
        CustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply1);
        CustLedgerEntry.Modify(true);
        CustLedgerEntry.Next();
        CustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply2);
        CustLedgerEntry.Modify(true);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentTypeX: Enum "Gen. Journal Document Type"; DocumentNoX: Code[20]; DocumentTypeY: Enum "Gen. Journal Document Type"; DocumentNoY: Code[20])
    var
        CustLedgerEntryX: Record "Cust. Ledger Entry";
        CustLedgerEntryY: Record "Cust. Ledger Entry";
    begin
        // Set up Amount to Apply from Remaining Amount for document X
        GetRemainingAmountOnCustomer(CustLedgerEntryX, DocumentTypeX, DocumentNoX);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryX, CustLedgerEntryX."Remaining Amount");
        // Set up Amount to Apply from Remaining Amount for document Y to be applied
        GetRemainingAmountOnCustomer(CustLedgerEntryY, DocumentTypeY, DocumentNoY);
        SetAppliesToIDCustomer(CustLedgerEntryY, CustLedgerEntryY."Remaining Amount");
        // Post application for document X
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryX);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentTypeX: Enum "Gen. Journal Document Type"; DocumentNoX: Code[20]; DocumentTypeY: Enum "Gen. Journal Document Type"; DocumentNoY: Code[20])
    var
        VendorLedgerEntryX: Record "Vendor Ledger Entry";
        VendorLedgerEntryY: Record "Vendor Ledger Entry";
    begin
        // Set up Amount to Apply from Remaining Amount for document X
        GetRemainingAmountOnVendor(VendorLedgerEntryX, DocumentTypeX, DocumentNoX);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntryX, VendorLedgerEntryX."Remaining Amount");
        // Set up Amount to Apply from Remaining Amount for document Y to be applied
        GetRemainingAmountOnVendor(VendorLedgerEntryY, DocumentTypeY, DocumentNoY);
        SetAppliesToIDVendor(VendorLedgerEntryY, VendorLedgerEntryY."Remaining Amount");
        // Post application for document X
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryX);
    end;

    local procedure ApplyGenJournalLineToVLE(var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.FindSet(true);
        repeat
            VendorLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;

        VendorLedgerEntry.CalcSums("Amount to Apply");
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate(Amount, -VendorLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyAndPostVendorDocuments(VendorNo: Code[20]; ApplyingDocumentType: Enum "Gen. Journal Document Type"; ApplyingDocumentNo: Code[20]; AppliedDocumentNo: array[2] of Code[20])
    var
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GetRemainingAmountOnVendor(ApplyingVendorLedgerEntry, ApplyingDocumentType, ApplyingDocumentNo);
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        VendorLedgerEntry.SetFilter("Document No.", '%1|%2', AppliedDocumentNo[1], AppliedDocumentNo[2]);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(ApplyingVendorLedgerEntry);
    end;

    local procedure ApplyGenJournalLineToCLE(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.FindSet(true);
        repeat
            CustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
            CustLedgerEntry.CalcFields(Amount);
            CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry.Amount);
            CustLedgerEntry.Modify(true);
        until CustLedgerEntry.Next() = 0;

        CustLedgerEntry.CalcSums("Amount to Apply");
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate(Amount, -CustLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyAndPostCustomerDocuments(CustomerNo: Code[20]; ApplyingDocumentType: Enum "Gen. Journal Document Type"; ApplyingDocumentNo: Code[20]; AppliedDocumentNo: array[2] of Code[20])
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GetRemainingAmountOnCustomer(ApplyingCustLedgerEntry, ApplyingDocumentType, ApplyingDocumentNo);
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        CustLedgerEntry.SetFilter("Document No.", '%1|%2', AppliedDocumentNo[1], AppliedDocumentNo[2]);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure CreatePaymentTermsWithTwoLines(PmtRate: array[2] of Integer; Days: array[2] of Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
        DateFormula: DateFormula;
        Index: Integer;
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        for Index := 1 to ArrayLen(Days) do begin
            LibraryERM.CreatePaymentLines(
              PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
            Evaluate(DateFormula, StrSubstNo('<%1D>', Days[Index]));
            PaymentLines.Validate("Due Date Calculation", DateFormula);
            PaymentLines.Validate("Payment %", PmtRate[Index]);
            PaymentLines.Modify(true);
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseInvoiceWithPaymentTerms(var PurchaseHeader: Record "Purchase Header"; PaymentTermsCode: Code[10]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateAndUpdateGLAccount(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithPaymentTerms(var SalesHeader: Record "Sales Header"; PaymentTermsCode: Code[10]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateAndUpdateGLAccount(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, AccountType, AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateApplyAndPostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);

        UpdateGenJournalLineWithAppliesToDoc(GenJournalLine, AppliesToDocType, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostPurchaseDocument(var Amount: Decimal; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchLine(PurchaseLine, PurchaseHeader);
        Amount := PurchaseLine."Amount Including VAT";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateTwoGenJnlLinesForSameAccountInSameBatch(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: array[2] of Decimal; Sign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Index: Integer;
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        for Index := 1 to ArrayLen(Amount) do
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccountType, AccountNo,
              GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount[Index] * Sign);
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateAndUpdateGLAccount(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure PostSalesDocument(var Amount: Decimal; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader);
        Amount := SalesLine."Amount Including VAT";
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateAndUpdateGLAccount(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndUpdateGLAccount(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure PostAndApplyPmtGenJnlLine(DocumentNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount / 3);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate(Amount, -Amount / 2);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(Amount + GenJournalLine.Amount);
    end;

    local procedure PostAndApplyPmtGenJnlLineWithHigherAmount(DocumentNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount * 3);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate(Amount, -Amount * 2);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(Amount + GenJournalLine.Amount);
    end;

    local procedure PostPaymentAppliedToTwoPurchaseInvoices(VendorNo: Code[20]; var PaymentNo: Code[20]; var InvoiceNo: array[2] of Code[20]; var InvoiceAmount: array[2] of Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        InvoiceNo[1] := PostPurchaseDocument(InvoiceAmount[1], PurchaseHeader."Document Type"::Invoice, VendorNo);
        InvoiceNo[2] := PostPurchaseDocument(InvoiceAmount[2], PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, 0);
        ApplyGenJournalLineToVLE(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure PostPaymentAppliedToTwoSalesInvoices(CustomerNo: Code[20]; var PaymentNo: Code[20]; var InvoiceNo: array[2] of Code[20]; var InvoiceAmount: array[2] of Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        InvoiceNo[1] := PostSalesDocument(InvoiceAmount[1], SalesHeader."Document Type"::Invoice, CustomerNo);
        InvoiceNo[2] := PostSalesDocument(InvoiceAmount[2], SalesHeader."Document Type"::Invoice, CustomerNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, 0);
        ApplyGenJournalLineToCLE(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure PostTwoPurchaseInvoicesAndPayment(VendorNo: Code[20]; var PaymentNo: Code[20]; var InvoiceNo: array[2] of Code[20]; var InvoiceAmount: array[2] of Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InvoiceNo[1] := PostPurchaseDocument(InvoiceAmount[1], PurchaseHeader."Document Type"::Invoice, VendorNo);
        InvoiceNo[2] := PostPurchaseDocument(InvoiceAmount[2], PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          (InvoiceAmount[1] + InvoiceAmount[2]));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure PostTwoSalesInvoicesAndPayment(CustomerNo: Code[20]; var PaymentNo: Code[20]; var InvoiceNo: array[2] of Code[20]; var InvoiceAmount: array[2] of Decimal)
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InvoiceNo[1] := PostSalesDocument(InvoiceAmount[1], SalesHeader."Document Type"::Invoice, CustomerNo);
        InvoiceNo[2] := PostSalesDocument(InvoiceAmount[2], SalesHeader."Document Type"::Invoice, CustomerNo);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          -(InvoiceAmount[1] + InvoiceAmount[2]));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";
    end;

    local procedure PostSalesCreditMemoAppliedToInvoice(CustomerNo: Code[20]; ApplyingAmount: Decimal; ApplyToDoc: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", ApplyingAmount / 3);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.ApplyCustomerLedgerEntries(SalesHeader."Document Type", SalesHeader."Document Type"::Invoice, DocumentNo, ApplyToDoc);
        exit(ApplyingAmount - SalesLine."Amount Including VAT");
    end;

    local procedure PostPurchaseCreditMemoAppliedToInvoice(VendorNo: Code[20]; ApplyingAmount: Decimal; ApplyToDoc: Code[20]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", ApplyingAmount / 3);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.ApplyVendorLedgerEntries(
          PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Invoice, DocumentNo, ApplyToDoc);
        exit(PurchaseLine."Amount Including VAT" - ApplyingAmount);
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure GetRemainingAmountOnCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure GetRemainingAmountOnVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure GetAmountsFromInvoiceVendLedgerEntry(var AmountLCY: array[2] of Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Index: Integer;
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindSet();
        Index := 1;
        repeat
            VendorLedgerEntry.CalcFields("Amount (LCY)");
            AmountLCY[Index] := -VendorLedgerEntry."Amount (LCY)";
            Index += 1;
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure GetAmountsFromInvoiceCustLedgerEntry(var AmountLCY: array[2] of Decimal; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Index: Integer;
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindSet();
        Index := 1;
        repeat
            CustLedgerEntry.CalcFields("Amount (LCY)");
            AmountLCY[Index] := CustLedgerEntry."Amount (LCY)";
            Index += 1;
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure RunVendorAccountBillsListReport(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorAccountBillsList: Report "Vendor Account Bills List";
    begin
        Vendor.SetRange("No.", VendorNo);
        VendorAccountBillsList.SetTableView(Vendor);
        VendorAccountBillsList.UseRequestPage(true);
        VendorAccountBillsList.Run();
    end;

    local procedure RunCustomerBillsListReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CustomerBillsList: Report "Customer Bills List";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerBillsList.SetTableView(Customer);
        CustomerBillsList.UseRequestPage(true);
        CustomerBillsList.Run();
    end;

    local procedure SetAppliesToIDCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    begin
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure SetAppliesToIDVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    begin
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
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

    local procedure UpdateSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // Setup logo to be printed by default
        SalesSetup.Get();
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);
    end;

    local procedure UpdateGenJournalLineWithAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        if AppliesToDocNo <> '' then begin
            GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
            GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure VerifyBillsReportsPaymentAppliedToTwoInvoices(Tags: array[4] of Text; InvoiceAmount: array[2] of Decimal; RemainingAmount: array[2] of Decimal; PaidAmount: Decimal; AppliedAmount: array[2] of Decimal; Sign: Integer)
    var
        I: Integer;
    begin
        LibraryReportDataSet.LoadDataSetFile();
        Assert.AreEqual(4, LibraryReportDataSet.RowCount(), WrongNoOfExportedEntriesErr);

        for I := 0 to ArrayLen(InvoiceAmount) - 1 do begin
            LibraryReportDataSet.MoveToRow(1 + 2 * I);
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[1], InvoiceAmount[1 + I] * Sign);
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[2], RemainingAmount[1 + I] * Sign);

            LibraryReportDataSet.GetNextRow();
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[3], -PaidAmount * Sign);
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[4], -AppliedAmount[1 + I] * Sign);
        end;

        LibraryReportDataSet.AssertCurrentRowValueEquals(BalanceDueTok, (RemainingAmount[1] + RemainingAmount[2]) * Sign);
    end;

    local procedure VerifyBillsReportsAmountsManyToMany(Tags: array[4] of Text; Amount: array[2] of Decimal; RemainingAmount: array[2] of Decimal; AppliedDocTotalAmount: array[2] of Decimal; AppliedAmount: array[4] of Decimal; Sign: Integer)
    var
        I: Integer;
        J: Integer;
    begin
        LibraryReportDataSet.LoadDataSetFile();
        Assert.AreEqual(6, LibraryReportDataSet.RowCount(), WrongNoOfExportedEntriesErr);

        for I := 0 to ArrayLen(Amount) - 1 do begin
            LibraryReportDataSet.MoveToRow(1 + 3 * I);
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[1], Amount[1 + I] * Sign);
            LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[2], RemainingAmount[1 + I] * Sign);

            for J := 0 to ArrayLen(AppliedDocTotalAmount) - 1 do begin
                LibraryReportDataSet.GetNextRow();
                LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[3], -AppliedDocTotalAmount[1 + J] * Sign);
                LibraryReportDataSet.AssertCurrentRowValueEquals(Tags[4], -AppliedAmount[1 + I + 2 * J] * Sign);
            end;
        end;

        LibraryReportDataSet.AssertCurrentRowValueEquals(BalanceDueTok, (RemainingAmount[1] + RemainingAmount[2]) * Sign);
    end;

    local procedure VerifyVLEOnVendAccBillListExists(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueExists(VendLedgEntry1DocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueExists(VendLedgEntry1DocumentNoCap, DocumentNo);
    end;

    local procedure VerifyDtldVLEOnVendAccBillListExists(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueExists(DetailedVLEDocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueExists(DetailedVLEDocumentNoCap, DocumentNo);
    end;

    local procedure VerifyVLEOnVendAccBillListNotExist(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueNotExist(VendLedgEntry1DocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueNotExist(VendLedgEntry1DocumentNoCap, DocumentNo);
    end;

    local procedure VerifyDtldVLEOnVendAccBillListNotExist(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueNotExist(DetailedVLEDocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueNotExist(DetailedVLEDocumentNoCap, DocumentNo);
    end;

    local procedure VerifyCLEOnCustBillsListExists(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueExists(CustLedgEntry1DocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueExists(CustLedgEntry1DocumentNoCap, DocumentNo);
    end;

    local procedure VerifyDtldCLEOnCustBillsListExists(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueExists(DetailedCLEDocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueExists(DetailedCLEDocumentNoCap, DocumentNo);
    end;

    local procedure VerifyCLEOnCustBillsListNotExist(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueNotExist(CustLedgEntry1DocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueNotExist(CustLedgEntry1DocumentNoCap, DocumentNo);
    end;

    local procedure VerifyDtldCLEOnCustBillsListNotExist(DocumentType: Text; DocumentNo: Code[20])
    begin
        LibraryReportDataSet.AssertElementWithValueNotExist(DetailedCLEDocumentTypeCap, DocumentType);
        LibraryReportDataSet.AssertElementWithValueNotExist(DetailedCLEDocumentNoCap, DocumentNo);
    end;

    local procedure VerifyExportedEntriesAmountsVendor(InvoiceAmount: array[2] of Decimal)
    begin
        VerifyExportedEntriesAmounts(
          InvoiceAmount, VendLedgEntry1AmountTok, TotalForVendorTok, TotalDtldVendLedgrEntries_Tok,
          ClosedByAmountLCYVendorTok, -1);
    end;

    local procedure VerifyExportedEntriesAmountsCustomer(InvoiceAmount: array[2] of Decimal)
    begin
        VerifyExportedEntriesAmounts(
          InvoiceAmount, CustLedgEntry1AmountTok, TotalForCustomerTok, TotalDtldCustLedgrEntries_Tok,
          ClosedByAmountLCYCustomerTok, 1);
    end;

    local procedure VerifyExportedEntriesAmounts(InvoiceAmount: array[2] of Decimal; LedgerEntryTok: Text; TotalAccountTok: Text; TotalDtldEntriesTok: Text; ClosedByAmountTok: Text; Sign: Integer)
    begin
        LibraryReportDataSet.LoadDataSetFile();
        Assert.AreEqual(4, LibraryReportDataSet.RowCount(), WrongNoOfExportedEntriesErr);

        LibraryReportDataSet.MoveToRow(1);
        VerifyExportedEntriesPairAmounts(
          InvoiceAmount[1], InvoiceAmount[1], 0, 0, LedgerEntryTok, TotalAccountTok, TotalDtldEntriesTok, ClosedByAmountTok, Sign);

        VerifyExportedEntriesPairAmounts(
          InvoiceAmount[2], InvoiceAmount[2], InvoiceAmount[1], 0,
          LedgerEntryTok, TotalAccountTok, TotalDtldEntriesTok, ClosedByAmountTok, Sign);
    end;

    local procedure VerifyExportedEntriesPairAmounts(InvoiceAmount: Decimal; ApplyAmount: Decimal; StartBalance: Decimal; TotalAmount: Decimal; LedgerEntryTok: Text; TotalAccountTok: Text; TotalDtldEntriesTok: Text; ClosedByAmountTok: Text; Sign: Integer)
    begin
        // 1st invoice entry
        LibraryReportDataSet.AssertCurrentRowValueEquals(LedgerEntryTok, InvoiceAmount * Sign);
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalAccountTok, InvoiceAmount * Sign);
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalDtldEntriesTok, StartBalance * -Sign);
        LibraryReportDataSet.GetNextRow();

        // Part of applied payment to 1st invoice entry
        LibraryReportDataSet.AssertCurrentRowValueEquals(LedgerEntryTok, InvoiceAmount * Sign);
        LibraryReportDataSet.AssertCurrentRowValueEquals(ClosedByAmountTok, ApplyAmount * -Sign);
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalAccountTok, TotalAmount * Sign);
        LibraryReportDataSet.AssertCurrentRowValueEquals(TotalDtldEntriesTok, (StartBalance + ApplyAmount) * -Sign);
        LibraryReportDataSet.GetNextRow();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRequestPageHandler(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    begin
        VendorAccountBillsList.EndingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Using random Date.
        VendorAccountBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    begin
        CustomerBillsList."Ending Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Using random Date.
        CustomerBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFiscalInventoryValuation(var FiscalInventoryValuation: TestRequestPage "Fiscal Inventory Valuation")
    var
        CostType: Option "Fiscal Cost","Average Cost","Weighted Average Cost","FIFO Cost","LIFO Cost","Discrete LIFO Cost";
    begin
        FiscalInventoryValuation.CompetenceDate.SetValue(CalcDate('<-2Y>', WorkDate()));
        FiscalInventoryValuation.CostType.SetValue(CostType::"Fiscal Cost");
        FiscalInventoryValuation.Item.SetFilter(
          "Date Filter", StrSubstNo('%1..%2', CalcDate('<-2Y>', WorkDate()), CalcDate('<+2Y>', WorkDate())));
        FiscalInventoryValuation.SaveAsPdf(FomatFileName(FiscalInventoryValuation.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFiscalInventoryValuationWithoutDateFilter(var FiscalInventoryValuation: TestRequestPage "Fiscal Inventory Valuation")
    var
        CostType: Option "Fiscal Cost","Average Cost","Weighted Average Cost","FIFO Cost","LIFO Cost","Discrete LIFO Cost";
    begin
        FiscalInventoryValuation.CompetenceDate.SetValue(CalcDate('<-2Y>', WorkDate()));
        FiscalInventoryValuation.CostType.SetValue(CostType::"Fiscal Cost");
        FiscalInventoryValuation.SaveAsPdf(FomatFileName(FiscalInventoryValuation.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDepreciationBook(var DepreciationBook: TestRequestPage "Depreciation Book")
    var
        RecDepreciationBook: Record "Depreciation Book";
    begin
        RecDepreciationBook.FindFirst();
        DepreciationBook.DepreciationBook.SetValue(RecDepreciationBook.Code);
        DepreciationBook.StartingDate.SetValue(CalcDate('<-2Y>', WorkDate()));
        DepreciationBook.EndingDate.SetValue(CalcDate('<+2Y>', WorkDate()));
        DepreciationBook.PrintPerFixedAsset.SetValue(true);
        DepreciationBook.SaveAsPdf(FomatFileName(DepreciationBook.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDepreciationBookCheckDates(var DepreciationBook: TestRequestPage "Depreciation Book")
    begin
        Assert.AreEqual(CalcDate('<-CY>', WorkDate()), DepreciationBook.StartingDate.AsDate(), StartingDateErr);
        Assert.AreEqual(CalcDate('<CY>', WorkDate()), DepreciationBook.EndingDate.AsDate(), EndingDateErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATRegisterPrint(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Record "VAT Register";
        RegisterCompany: Variant;
        FiscalCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(RegisterCompany);
        LibraryVariableStorage.Dequeue(FiscalCode);
        VATRegister.FindFirst();
        VATRegisterPrint.VATRegister.SetValue(VATRegister.Code);
        VATRegisterPrint.PeriodStartingDate.SetValue(CalcDate('<-2Y>', WorkDate()));
        VATRegisterPrint.PeriodEndingDate.SetValue(CalcDate('<+1Y>', WorkDate()));
        VATRegisterPrint.RegisterCompanyNo.SetValue(RegisterCompany);
        VATRegisterPrint.FiscalCode.SetValue(FiscalCode);
        VATRegisterPrint.SaveAsPdf(FomatFileName(VATRegisterPrint.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAnnualVATComm2010(var AnnualVATComm2010: TestRequestPage "Annual VAT Comm. - 2010")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementTemplate.FindLast();
        AnnualVATComm2010.StatementTemplate.SetValue(VATStatementTemplate.Name);
        VATStatementName.FindFirst();
        AnnualVATComm2010.StatementName.SetValue(VATStatementName.Name);
        AnnualVATComm2010.SeparateLedger.SetValue(true);
        AnnualVATComm2010.GroupSettlement.SetValue(true);
        AnnualVATComm2010.ExceptionalEvent.SetValue(true);
        AnnualVATComm2010.StartDate.SetValue(CalcDate('<-3Y>', WorkDate()));
        AnnualVATComm2010.EndDate.SetValue(CalcDate('<+1Y>', WorkDate()));
        AnnualVATComm2010.SaveAsPdf(FomatFileName(AnnualVATComm2010.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountBookSheetPrint(var AccountBookSheetPrint: TestRequestPage "Account Book Sheet - Print")
    begin
        AccountBookSheetPrint."G/L Account".SetFilter(
          "Date Filter", StrSubstNo('%1..%2', CalcDate('<-2Y>', WorkDate()), CalcDate('<+2Y>', WorkDate())));
        AccountBookSheetPrint.SaveAsPdf(FomatFileName(AccountBookSheetPrint.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestHandlerCustomerBillsList(var CustomerBillsList: TestRequestPage "Customer Bills List")
    begin
        CustomerBillsList."Ending Date".SetValue(LibraryRandom.RandDate(10));  // Using random Date.
        CustomerBillsList.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestHandlerVendorAccountBillsList(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    begin
        VendorAccountBillsList.EndingDate.SetValue(LibraryRandom.RandDate(10));  // Using random Date.
        VendorAccountBillsList.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorAccountBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;
}

