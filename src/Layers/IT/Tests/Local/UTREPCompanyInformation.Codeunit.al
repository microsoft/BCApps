codeunit 144169 "UT REP Company Information"
{
    // // [FEATURE] [UT] [Report]
    // 
    // 1.  Purpose of the test is to validate Bank Account - OnAfterGetRecord Trigger of Report 12112 (Bank Sheet - Print).
    // 2.  Purpose of the test is to validate Customer - OnAfterGetRecord Trigger of Report 12104 (Customer Sheet - Print).
    // 3.  Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report 12110 (Vendor Sheet - Print).
    // 4.  Purpose of the test is to verify Customer - OnAfterGetRecord Trigger of Report 12104 (Customer Sheet - Print).
    // 5.  Purpose of the test is to verify Vendor - OnAfterGetRecord Trigger of Report 12110 (Vendor Sheet - Print).
    // 6.  Purpose of this test is to verify error of Report 12121 (G/L Book Print) with blank dates.
    // 7.  Purpose of this test is to verify error of Report 12121 (G/L Book Print) with incomplete Company Information.
    // 8.  Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Starting Date greater than Ending Date.
    // 9.  Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Ending Date greater than Starting Date.
    // 10. Purpose of the test is to verify GL Book Entry - OnPreDataItem Trigger of Report 12121 (G/L Book - Print).
    // 11. Purpose of the test is to verify Integer - OnPreDataItem Trigger of Report 12121 (G/L Book - Print).
    // 12. Purpose of the test is to verify GL Book Entry - OnAfterGetRecord Trigger of Report 12121 (G/L Book - Print).
    // 13. Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Reprint report type.
    // 14. Purpose of the test is to verify OnPostReport Trigger of Report 12121 (G/L Book - Print).
    // 15. Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Starting Date less than Final Print Ending Date.
    // 16. Purpose of the test is to verify field values on Company Information Page.
    // 
    // Covers Test Cases for WI - 345128
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                            TFS ID
    // -------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordBankSheetPrint                                                               266295
    // OnAfterGetRecordCustomerSheetPrint, OnAfterGetRecordCustomerSheetPrintWithBlankFilters       266293
    // OnAfterGetRecordVendorSheetPrint, OnAfterGetRecordVendorSheetPrintWithBlankFilters           266294
    // OnAfterGetRecordGLBookPrintError, OnPreDataItemGLBookPrintError,
    // OnPreReportGLBookPrintError, OnValidateEndingDateGLBookPrintError,
    // OnPreDataItemGLBookEntryGLBookPrint, OnPreDataItemGLBookPrint,
    // OnAfterGetRecordGLBookEntryGLBookPrint, OnValidateReportTypeGLBookPrintError,
    // OnPostReportGLBookPrint, OnValidateStartingDateGLBookPrintError                              266289
    // OnValidateSIACodeCompanyInformation                                                          266283

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AssignedTxt: Label 'Text Constant required to check value on different fields.';
        ValidationTxt: Label 'TestValidation';
        DialogTxt: Label 'Dialog';

    [Test]
    [HandlerFunctions('BankSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankSheetPrint()
    var
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account - OnAfterGetRecord Trigger of Report 12112 (Bank Sheet - Print).

        // Setup: Create Bank Ledger Entry.
        Initialize();
        BankAccountNo := CreateBankAccount();
        CreateBankAccountLedgerEntry(BankAccountNo);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue Value in BankSheetPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Bank Sheet - Print");

        // Verify: Verify Bank Account No. on Report 12112 (Bank Sheet - Print).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('BankFilterNo', BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerSheetPrint()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord Trigger of Report 12104 (Customer Sheet - Print).

        // Setup: Create Customer with Ledger Entries.
        Initialize();
        CreateCustomer(Customer);
        CreateDetailedCustomerLedgerEntry(CreateCustomerLedgerEntry(Customer."No."));
        EnqueueValuesForHandlers(Customer."No.", Customer."Date Filter", Customer."Global Dimension 1 Filter", Customer."Currency Code");  // Enqueue values in CustomerSheetPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Sheet - Print");

        // Verify: Verify Customer No. on Report 12104 (Customer Sheet - Print).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CustFilterNo', Customer."No.");
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorSheetPrint()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report 12110 (Vendor Sheet - Print).

        // Setup: Create Vendor with Ledger Entries.
        Initialize();
        CreateVendor(Vendor);
        CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(Vendor."No."));
        EnqueueValuesForHandlers(Vendor."No.", Vendor."Date Filter", Vendor."Global Dimension 1 Filter", Vendor."Currency Code");  // Enqueue values in VendorSheetPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Sheet - Print");

        // Verify: Verify Vendor No. on Report 12110 (Vendor Sheet - Print).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendFilterNo', Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerSheetPrintWithBlankFilters()
    begin
        // Purpose of the test is to verify Customer - OnAfterGetRecord Trigger of Report 12104 (Customer Sheet - Print).
        CompanyInformationWithBlankFilters(REPORT::"Customer Sheet - Print");
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorSheetPrintWithBlankFilters()
    begin
        // Purpose of the test is to verify Vendor - OnAfterGetRecord Trigger of Report 12110 (Vendor Sheet - Print).
        CompanyInformationWithBlankFilters(REPORT::"Vendor Sheet - Print");
    end;

    local procedure CompanyInformationWithBlankFilters(ReportID: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        // Setup: Enqueue values in CustomerSheetPrintRequestPageHandler, VendorSheetPrintRequestPageHandler.
        Initialize();
        EnqueueValuesForHandlers('', 0D, '', '');  // No, Date Filter, Global Dimension 1 Code and Currency Code as blank.

        // Exercise.
        REPORT.Run(ReportID);

        // Verify: Verify Company Information.
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();
        VerifyCompanyInformationOnReports('CompAddr1', 'CompAddr2', 'CompAddr3',
          CompanyInformation.Name, CompanyInformation.Address, CompanyInformation."Post Code");
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLBookPrintError()
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with blank dates.
        // Verify actual error: "Starting Date must not be blank."
        GLBookPrintReportWithDifferentDates(0D, 0D, ValidationTxt);  // Starting and Ending Dates as blank.
    end;

    [Test]
    [HandlerFunctions('GLBookPrintInReverseRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLBookPrintError()
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with incomplete Company Information.
        // Verify actual error: "All Company Information related fields should be filled in on the request form."
        GLBookPrintReportWithDifferentDates(WorkDate(), WorkDate(), DialogTxt);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintInReverseRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportGLBookPrintError()
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Starting Date greater than Ending Date.
        // Verify actual error: "Starting Date must not be greater than EndingDate".
        GLBookPrintReportWithDifferentDates(CalcDate('<1D>', WorkDate()), WorkDate(), DialogTxt);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateEndingDateGLBookPrintError()
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Ending Date greater than Starting Date.
        // Verify actual error: "Ending Date must not be less than Starting Date."
        GLBookPrintReportWithDifferentDates(CalcDate('<1D>', WorkDate()), WorkDate(), ValidationTxt);
    end;

    local procedure GLBookPrintReportWithDifferentDates(StartingDate: Date; EndingDate: Date; ExpectedErrorCode: Text)
    var
        ReportType: Option "Test Print";
    begin
        // Setup.
        Initialize();
        EnqueueVariablesForGLBookPrintRequestPageHandler(StartingDate, EndingDate, ReportType::"Test Print");  // Enqueue values in GLBookPrintRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"G/L Book - Print");

        // Verify.
        Assert.ExpectedErrorCode(ExpectedErrorCode);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLBookEntryGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of the test is to verify GL Book Entry - OnPreDataItem Trigger of Report 12121 (G/L Book - Print).
        // Setup.
        Initialize();
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), CalcDate('<1D>', WorkDate()), ReportType::"Test Print");  // Enqueue values in GLBookPrintRequestPageHandler.
        GLBookEntry.SetRange("G/L Account No.", CreateGLBookEntry());

        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print", true, false, GLBookEntry);

        // Verify: Verify Company Information on Report 12121 (G/L Book - Print).
        VerifyCompanyInformationOnGLBookPrint();
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLBookPrint()
    var
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of the test is to verify Integer - OnPreDataItem Trigger of Report 12121 (G/L Book - Print).
        // Setup.
        Initialize();
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), CalcDate('<1D>', WorkDate()), ReportType::"Test Print");  // Enqueue values in GLBookPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print");

        // Verify: Verify Company Information on Report 12121 (G/L Book - Print).
        VerifyCompanyInformationOnGLBookPrint();
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLBookEntryGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of the test is to verify GL Book Entry - OnAfterGetRecord Trigger of Report 12121 (G/L Book - Print).
        // Setup.
        Initialize();
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), CalcDate('<1D>', WorkDate()), ReportType::"Final Print");  // Enqueue values in GLBookPrintRequestPageHandler.
        GLBookEntry.SetRange("G/L Account No.", CreateGLBookEntry());

        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print", true, false, GLBookEntry);

        // Verify: Verify Company Information on Report 12121 (G/L Book - Print).
        VerifyCompanyInformationOnGLBookPrint();
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateReportTypeGLBookPrintError()
    var
        GLBookEntry: Record "GL Book Entry";
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Reprint report type.
        // Setup.
        Initialize();
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), CalcDate('<1D>', WorkDate()), ReportType::Reprint);  // Enqueue values in GLBookPrintRequestPageHandler.
        GLBookEntry.SetRange("G/L Account No.", CreateGLBookEntry());

        // Exercise.
        asserterror REPORT.Run(REPORT::"G/L Book - Print", true, false, GLBookEntry);

        // Verify: Verify actual error: "There is nothing to reprint".
        Assert.ExpectedErrorCode(ValidationTxt);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostReportGLBookPrint()
    var
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of the test is to verify OnPostReport Trigger of Report 12121 (G/L Book - Print).

        // Setup: Enqueue values in GLBookPrintRequestPageHandler.
        Initialize();
        ReprintInfoFiscalReportsAfterFinalPrint();
        EnqueueVariablesForGLBookPrintRequestPageHandler(CalcDate('<2D>', WorkDate()), CalcDate('<3D>', WorkDate()), ReportType::Reprint);   // Taking Fixed Values for Date calculation since Start Date and End Date is based on it. Value important for Test.

        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print");

        // Verify: Verify Company Information on Report 12121 (G/L Book - Print).
        VerifyCompanyInformationOnGLBookPrint();
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler,ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateStartingDateGLBookPrintError()
    var
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        // Purpose of this test is to verify error of Report 12121 (G/L Book Print) with Starting Date less than Final Print Ending Date.

        // Setup: Enqueue values in GLBookPrintRequestPageHandler.
        Initialize();
        ReprintInfoFiscalReportsAfterFinalPrint();
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), WorkDate(), ReportType::Reprint);  // Taking Fixed Values for Date calculation since Start Date and End Date is based on it. Value important for Test.

        // Exercise.
        asserterror REPORT.Run(REPORT::"G/L Book - Print");

        // Verify: Verify actual error: "Starting Date must be greater than Ending Date".
        Assert.ExpectedErrorCode(ValidationTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSIACodeCompanyInformation()
    begin
        // Purpose of the test is to verify field values on Company Information Page.
        // Setup.
        Initialize();

        // Exercise.
        UpdateCompanyInformation();

        // Verify: Verify values on Company Information page.
        VerifyValuesOnCompanyInformationPage();
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRPH')]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintWithCorrOfRemainingAmt()
    var
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CorrOfRemainingAmountLCY: Decimal;
        InvoiceCLENo: Integer;
        PaymentCLENo: Integer;
    begin
        // [FEATURE] [Sales] [Currency] [Adjustment]
        // [SCENARIO 123287] "Customer Sheet - Print" correctly prints Totals in case of "Correction of Remaining Amount" <> 0
        Initialize();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        AmountLCY := Round(Amount / 2);
        CorrOfRemainingAmountLCY := Round(AmountLCY / 2);

        // [GIVEN] Foreign customer
        CurrencyCode := MockCurrency();
        CustomerNo := MockForeignCustomer(CurrencyCode);

        // [GIVEN] Sales Invoice with Amount = "A"
        InvoiceCLENo := MockSalesInvoice(CustomerNo, CurrencyCode, Amount, AmountLCY);

        // [GIVEN] Payment, applied to the Invoice with "Correction of Remaining Amount" <> 0
        PaymentCLENo := MockCustomerPayment(CustomerNo, CurrencyCode, Amount, AmountLCY);
        MockCustomerApplication(InvoiceCLENo, PaymentCLENo, Amount, AmountLCY, CorrOfRemainingAmountLCY);

        // [GIVEN] Unapply previous application
        MockCustomerApplication(InvoiceCLENo, PaymentCLENo, -Amount, -AmountLCY, -CorrOfRemainingAmountLCY);

        // [WHEN] Run "Customer Sheet - Print" report
        RunCustomerSheetPrintReport(CustomerNo);

        // [THEN] Total Increases Amount = "A"
        // [THEN] Total Decreases Amount = "A"
        // [THEN] Total Amount LCY = 0
        VerifyCustomerSheetPrintReportTotals(AmountLCY, 0);
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRPH')]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintWithApplyAndCorrOfRemainingAmt()
    var
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CorrOfRemainingAmountLCY: Decimal;
        InvoiceCLENo: Integer;
        PaymentCLENo: Integer;
    begin
        // [FEATURE] [Sales] [Currency] [Adjustment]
        // [SCENARIO 362703] "Customer Sheet - Print" correctly prints Totals after Apply in case of "Correction of Remaining Amount" <> 0
        Initialize();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        AmountLCY := Round(Amount / 2);
        CorrOfRemainingAmountLCY := Round(AmountLCY / 2);

        // [GIVEN] Foreign customer
        CurrencyCode := MockCurrency();
        CustomerNo := MockForeignCustomer(CurrencyCode);

        // [GIVEN] Sales Invoice with Amount = "A"
        InvoiceCLENo := MockSalesInvoice(CustomerNo, CurrencyCode, Amount, AmountLCY);

        // [GIVEN] Payment, applied to the Invoice with "Correction of Remaining Amount" = "B"
        PaymentCLENo := MockCustomerPayment(CustomerNo, CurrencyCode, Amount, AmountLCY);
        MockCustomerApplication(InvoiceCLENo, PaymentCLENo, Amount, AmountLCY, CorrOfRemainingAmountLCY);

        // [WHEN] Run "Customer Sheet - Print" report
        RunCustomerSheetPrintReport(CustomerNo);

        // [THEN] Total Increases Amount = "A"
        // [THEN] Total Decreases Amount = "A"
        // [THEN] Total Amount LCY = "B"
        VerifyCustomerSheetPrintReportTotals(AmountLCY, CorrOfRemainingAmountLCY);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Date Filter" := WorkDate();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountLedgerEntry(BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry."Entry No." := LibraryRandom.RandInt(10);
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        BankAccountLedgerEntry."Posting Date" := WorkDate();
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Date Filter" := WorkDate();
        Customer."Currency Code" := LibraryUTUtility.GetNewCode10();
        Customer."Global Dimension 1 Code" := CreateDimension();
        Customer.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntry(EntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedVendorLedgerEntry(EntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(EntryNo);
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Document No." := VendorLedgerEntry."Document No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Posting Date" := VendorLedgerEntry."Posting Date";
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.Code := LibraryUTUtility.GetNewCode();
        Dimension.Insert();
        exit(Dimension.Code);
    end;

    local procedure CreateGLBookEntry(): Code[20]
    var
        GLBookEntry: Record "GL Book Entry";
        GLBookEntry2: Record "GL Book Entry";
        EntryNo: Integer;
    begin
        GLBookEntry2.FindLast();
        EntryNo := GLBookEntry2."Entry No." + 1;
        GLBookEntry2.DeleteAll(true);
        GLBookEntry."Entry No." := EntryNo;
        GLBookEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLBookEntry."Official Date" := CalcDate('<-1D>', WorkDate());
        GLBookEntry."Progressive No." := 0;
        GLBookEntry.Insert();
        exit(GLBookEntry."G/L Account No.");
    end;

    local procedure CreateReprintInfoFiscalReports()
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
    begin
        // Taking Fixed Values for Date calculation since Start Date and End Date is based on it. Value important for Test.
        ReprintInfoFiscalReports.Report := ReprintInfoFiscalReports.Report::"G/L Book - Print";
        ReprintInfoFiscalReports."Start Date" := CalcDate('<2D>', WorkDate());
        ReprintInfoFiscalReports."End Date" := CalcDate('<3D>', WorkDate());
        ReprintInfoFiscalReports.Insert();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Date Filter" := WorkDate();
        Vendor."Currency Code" := LibraryUTUtility.GetNewCode10();
        Vendor."Global Dimension 1 Code" := CreateDimension();
        Vendor.Insert();
    end;

    local procedure CreateVendorLedgerEntry(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockSalesInvoice(CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, CurrencyCode);
        MockDetailedCustLedgerEntry(CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::"Initial Entry", Amount, AmountLCY);
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockCustomerPayment(CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Payment, CurrencyCode);
        MockDetailedCustLedgerEntry(CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::"Initial Entry", -Amount, -AmountLCY);
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockCustomerApplication(InvoiceCLENo: Integer; PaymentCLENo: Integer; Amount: Decimal; AmountLCY: Decimal; CorrOfRemainingAmountLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.Get(InvoiceCLENo);
        MockDetailedCustLedgerEntry(CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::Application, -Amount, -AmountLCY);

        CustLedgerEntry.Get(PaymentCLENo);
        MockDetailedCustLedgerEntry(CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::Application, Amount, AmountLCY);
        MockDetailedCustLedgerEntry(
          CustLedgerEntry, DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount", 0, CorrOfRemainingAmountLCY);
    end;

    local procedure MockCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Code := LibraryUtility.GenerateRandomCode(Currency.FieldNo(Code), DATABASE::Currency);
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure MockForeignCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer."Currency Code" := CurrencyCode;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10])
    var
        LastEntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then
            LastEntryNo := CustLedgerEntry."Entry No.";
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := CustomerNo;
        CustLedgerEntry."Currency Code" := CurrencyCode;
        CustLedgerEntry.Insert();
    end;

    local procedure MockDetailedCustLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; NewAmount: Decimal; NewAmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastEntryNo: Integer;
    begin
        if DetailedCustLedgEntry.FindLast() then
            LastEntryNo := DetailedCustLedgEntry."Entry No.";
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Document Type" := CustLedgerEntry."Document Type";
        DetailedCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Currency Code" := CustLedgerEntry."Currency Code";
        DetailedCustLedgEntry.Amount := NewAmount;
        DetailedCustLedgEntry."Amount (LCY)" := NewAmountLCY;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure EnqueueVariablesForGLBookPrintRequestPageHandler(StartingDate: Variant; EndingDate: Variant; ReportType: Variant)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(ReportType);
    end;

    local procedure EnqueueValuesForHandlers(No: Variant; DateFilter: Variant; GlobalDimension1Code: Variant; CurrencyCode: Code[10])
    begin
        EnqueueVariablesForGLBookPrintRequestPageHandler(No, DateFilter, GlobalDimension1Code);
        LibraryVariableStorage.Enqueue(CurrencyCode);
    end;

    local procedure ReprintInfoFiscalReportsAfterFinalPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        EnqueueVariablesForGLBookPrintRequestPageHandler(WorkDate(), CalcDate('<1D>', WorkDate()), ReportType::"Final Print");  // Enqueue values in GLBookPrintHandler.
        GLBookEntry.SetRange("G/L Account No.", CreateGLBookEntry());
        REPORT.Run(REPORT::"G/L Book - Print", true, false, GLBookEntry);
        CreateReprintInfoFiscalReports();
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."SIA Code" := CopyStr(AssignedTxt, 1, 4);
        CompanyInformation."Autoriz. No." := CopyStr(AssignedTxt, 1, 10);
        CompanyInformation."Autoriz. Date" := WorkDate();
        CompanyInformation."Signature on Bill" := CopyStr(AssignedTxt, 1, 20);
        CompanyInformation.BBAN := CopyStr(AssignedTxt, 1, 30);
        CompanyInformation.Modify();
    end;

    local procedure RunCustomerSheetPrintReport(CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
        Commit();
        REPORT.Run(REPORT::"Customer Sheet - Print");
    end;

    local procedure VerifyCompanyInformationOnReports(Caption: Text; Caption2: Text; Caption3: Text; CaptionValue: Text[100]; CaptionValue2: Text[100]; CaptionValue3: Code[20])
    begin
        LibraryReportDataset.AssertElementWithValueExists(Caption, CaptionValue);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, CaptionValue2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, CaptionValue3);
    end;

    local procedure VerifyValuesOnCompanyInformationPage()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        CompanyInformation.OpenView();
        CompanyInformation."SIA Code".AssertEquals(UpperCase(CopyStr(AssignedTxt, 1, 4)));
        CompanyInformation."Autoriz. No.".AssertEquals(UpperCase(CopyStr(AssignedTxt, 1, 10)));
        CompanyInformation."Autoriz. Date".AssertEquals(WorkDate());
        CompanyInformation."Signature on Bill".AssertEquals(CopyStr(AssignedTxt, 1, 20));
        CompanyInformation.BBAN.AssertEquals(UpperCase(CopyStr(AssignedTxt, 1, 30)));
        CompanyInformation.Close();
    end;

    local procedure VerifyCompanyInformationOnGLBookPrint()
    begin
        LibraryReportDataset.LoadDataSetFile();
        VerifyCompanyInformationOnReports(
          'CompanyInformation_4_', 'CompanyInformation_5_', 'CompanyInformation_6_',
          CopyStr(AssignedTxt, 1, 50), CopyStr(AssignedTxt, 1, 20), UpperCase(CopyStr(AssignedTxt, 1, 20)));
    end;

    local procedure VerifyCustomerSheetPrintReportTotals(AmountLCY: Decimal; TotalAmountLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalIcreasesAmtForRTC', AmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalDecreasesAmtForRTC', AmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountLCYForRTC', TotalAmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('StartOnHand', 0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankSheetPrintRequestPageHandler(var BankSheetPrint: TestRequestPage "Bank Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankSheetPrint."Bank Account".SetFilter("No.", No);
        BankSheetPrint."Bank Account".SetFilter("Date Filter", Format(WorkDate()));
        BankSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintRequestPageHandler(var CustomerSheetPrint: TestRequestPage "Customer Sheet - Print")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimension1Code: Variant;
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(GlobalDimension1Code);
        LibraryVariableStorage.Dequeue(CurrencyCode);
        CustomerSheetPrint.Customer.SetFilter("No.", No);
        CustomerSheetPrint.Customer.SetFilter("Date Filter", Format(DateFilter));
        CustomerSheetPrint.Customer.SetFilter("Global Dimension 1 Code", GlobalDimension1Code);
        CustomerSheetPrint.Customer.SetFilter("Currency Code", CurrencyCode);
        CustomerSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintRPH(var CustomerSheetPrint: TestRequestPage "Customer Sheet - Print")
    begin
        CustomerSheetPrint.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        StartingDate: Variant;
        EndingDate: Variant;
        ReportType: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(ReportType);
        if Format(StartingDate) = '' then
            GLBookPrint.StartingDate.SetValue(WorkDate());
        GLBookPrint.StartingDate.SetValue(Format(StartingDate));
        GLBookPrint.EndingDate.SetValue(Format(EndingDate));
        GLBookPrint.ReportType.SetValue(ReportType);
        GLBookPrint.PrintCompanyInformations.SetValue(true);
        GLBookPrint.RegisterCompanyNo.SetValue(CopyStr(AssignedTxt, 1, 50));
        GLBookPrint.VATRegistrationNo.SetValue(CopyStr(AssignedTxt, 1, 20));
        GLBookPrint.FiscalCode.SetValue(UpperCase(CopyStr(AssignedTxt, 1, 20)));
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintInReverseRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        StartingDate: Variant;
        EndingDate: Variant;
        ReportType: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(ReportType);
        GLBookPrint.EndingDate.SetValue(Format(EndingDate));
        GLBookPrint.StartingDate.SetValue(Format(StartingDate));
        GLBookPrint.ReportType.SetValue(ReportType);
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorSheetPrintRequestPageHandler(var VendorSheetPrint: TestRequestPage "Vendor Sheet - Print")
    var
        No: Variant;
        DateFilter: Variant;
        GlobalDimension1Code: Variant;
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(GlobalDimension1Code);
        LibraryVariableStorage.Dequeue(CurrencyCode);
        VendorSheetPrint.Vendor.SetFilter("No.", No);
        VendorSheetPrint.Vendor.SetFilter("Date Filter", Format(DateFilter));
        VendorSheetPrint.Vendor.SetFilter("Global Dimension 1 Code", GlobalDimension1Code);
        VendorSheetPrint.Vendor.SetFilter("Currency Code", CurrencyCode);
        VendorSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

