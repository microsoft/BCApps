codeunit 144045 "UT REP Payment Management"
{
    //  1. Purpose of the test is to validate On Pre Data Item Trigger of Report ID - 10860 Payment List.
    //  2. Purpose of the test is to verify error on Report ID - 10861 GL/Cust. Ledger Reconciliation.
    //  3. Purpose of the test is to verify error on Report ID - 10863 GL/Vend. Ledger Reconciliation.
    //  4. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10865 'Bill' with Currency.
    //  5. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10866 'Draft' with Currency.
    //  6. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10865 'Bill' without Currency.
    //  7. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10866 'Draft' without Currency.
    //  8. Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10868 'Draft Notice'.
    //  9. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10868 'Draft Notice' with blank Payment Address Code.
    // 10. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10868 'Draft Notice' with Payment Address Code.
    // 11. Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10870 'Withdraw Notice'.
    // 12. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10870 'Withdraw Notice' with blank Payment Address Code.
    // 13. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10870 'Withdraw Notice' with Payment Address Code.
    // 14. Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
    // 15. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
    // 16. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
    // 17. Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation',
    // 18. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation'.
    // 19. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation'.
    // 20. Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10867 Remittance.
    // 
    // Covers Test Cases for WI - 344345
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                         TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // OnPreDateItemPaymentLinePaymentList                                                                                       169507
    // GLCustLedgerReconciliationDateFilterError                                                                                 169508
    // GLVendLedgerReconciliationDateFilterError                                                                                 169509
    // OnAfterGetRecordPaymentLineWithCurrencyBill, OnAfterGetRecordPaymentLineBlankCurrencyBillError                            169433
    // OnAfterGetRecordPaymentLineWithCurrencyDraft, OnAfterGetRecordPaymentLineBlankCurrencyDraftError                          169510
    // OnPreReportDraftNoticeError, OnAfterGetRecordPmtLineBlankPmtAddressDraftNotice
    // OnAfterGetRecordPmtLinePmtAddressDraftNotice                                                                              169512
    // OnPreReportWithdrawNoticeError, OnAfterGetRecordPmtLineBlankPmtAddressWithdrawNotice
    // OnAfterGetRecordPmtLinePmtAddressWithdrawNotice                                                                           169432
    // OnPreReportDraftRecapitulationError, OnAfterGetRecordPmtLineDraftRecapitulationError                                      169511
    // OnAfterGetRecordPmtLineDraftRecapitulation
    // OnPreReportWithdrawRecapitulationError, OnAfterGetRecordPmtLineWithdrawRecapitulationError
    // OnAfterGetRecordPmtLineWithdrawRecapitulation                                                                             169434
    // OnAfterGetRecordPaymentLineRemittance                                                                                     169513

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        AmountTxt: Label 'Amount %1';
        DialogErr: Label 'Dialog';
        FileNotExistsMsg: Label 'File Does Not Exists.';
        PaymentLinesAccountNoCap: Label 'Payment_Lines__Account_No__';
        PaymentLineAccountNoCap: Label 'Payment_Line__Account_No__';
        PaymentLines1NoCap: Label 'Payment_Lines1___No__';

    [Test]
    [HandlerFunctions('PaymentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDateItemPaymentLinePaymentList()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On Pre Data Item Trigger of Report ID - 10860 Payment List.

        // Setup: Create Payment Line.
        Initialize();
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, CreateVendor(), '', '');  // Blank value for Currency and Payment Address code.
        LibraryVariableStorage.Enqueue(PaymentLine."No.");  // Enqueue for PaymentListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Payment List");

        // Verify: Verify Account No on Payment List Report.
        VerifyValuesOnXML(PaymentLineAccountNoCap, PaymentLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('GLCustLedgerReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLCustLedgerReconciliationDateFilterError()
    begin
        // Purpose of the test is to verify error on Report ID - 10861 GL/Cust. Ledger Reconciliation.

        // Test to verify error 'Specify a filter for the Date Filter field in the Customer table.'.
        GLReconciliationDateFilterError(REPORT::"GL/Cust. Ledger Reconciliation");
    end;

    [Test]
    [HandlerFunctions('GLVendLedgerReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLVendLedgerReconciliationDateFilterError()
    begin
        // Purpose of the test is to verify error on Report ID - 10863 GL/Vend. Ledger Reconciliation.

        // Test to verify error 'Specify a filter for the Date Filter field in the Vendor table.'.
        GLReconciliationDateFilterError(REPORT::"GL/Vend. Ledger Reconciliation");
    end;

    local procedure GLReconciliationDateFilterError(ReportID: Integer)
    begin
        // Setup: Enqueue values for GLCustLedgerReconciliationRequestPageHandler and GLVendLedgerReconciliationRequestPageHandler.
        Initialize();
        LibraryVariableStorage.Enqueue('');  // Blank for No.

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify: Verify expected error code.
        Assert.ExpectedErrorCode('DB:NoFilter');
    end;

    [Test]
    [HandlerFunctions('BillRequestpageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineWithCurrencyBill()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10865 'Bill' with Currency.
        PaymentReportWithCurrency(PaymentLine."Account Type"::Customer, CreateCustomer(), REPORT::Bill);
    end;

    [Test]
    [HandlerFunctions('DraftRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineWithCurrencyDraft()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10866 'Draft' with Currency.
        PaymentReportWithCurrency(PaymentLine."Account Type"::Vendor, CreateVendor(), REPORT::Draft);
    end;

    local procedure PaymentReportWithCurrency(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ReportID: Integer)
    var
        CurrencyCode: Code[10];
    begin
        // Setup and Exercise.
        Initialize();
        CurrencyCode := CreateCurrency();
        CreatePaymentLineAndRunPaymentReport(AccountType, AccountNo, CurrencyCode, ReportID);

        // Verify: Verify Amount Text on XML after running report.
        VerifyValuesOnXML('AmountText', StrSubstNo(AmountTxt, CurrencyCode));
    end;

    [Test]
    [HandlerFunctions('BillBlankCurrencyRequestpageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineBlankCurrencyBillError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10865 'Bill' without Currency.
        PaymentReportWithoutCurrency(PaymentLine."Account Type"::Customer, CreateCustomer(), REPORT::Bill);
    end;

    [Test]
    [HandlerFunctions('DraftBlankCurrencyRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineBlankCurrencyDraftError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10866 'Draft' without Currency.
        PaymentReportWithoutCurrency(PaymentLine."Account Type"::Vendor, CreateVendor(), REPORT::Draft);
    end;

    local procedure PaymentReportWithoutCurrency(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ReportID: Integer)
    var
        FileName: Text[1024];
    begin
        // Setup and Exercise.
        Initialize();
        FileName := FileManagement.ServerTempFileName('.pdf');
        LibraryVariableStorage.Enqueue(FileName);  // Enqueue for BillBlankCurrencyRequestpageHandler and DraftBlankCurrencyRequestpageHandler.
        CreatePaymentLineAndRunPaymentReport(AccountType, AccountNo, '', ReportID);  // Blank for Currency code.

        // Verify: Verify File Exists and not Empty.
        Assert.IsTrue(VerifyFileNotEmpty(FileName), FileNotExistsMsg);
    end;

    [Test]
    [HandlerFunctions('DraftNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportDraftNoticeError()
    begin
        // Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10868 'Draft Notice'.
        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Draft notice");

        // Verify: Verify expected error code. Actual error is 'You must specify a transfer number'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('DraftNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBlankPmtAddressDraftNotice()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10868 'Draft Notice' with blank Payment Address Code.
        RunAndVerifyDraftNoticeReport('');  // Blank for Payment Address code.
    end;

    [Test]
    [HandlerFunctions('DraftNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLinePmtAddressDraftNotice()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10868 'Draft Notice' with Payment Address Code.
        RunAndVerifyDraftNoticeReport(LibraryUTUtility.GetNewCode10());
    end;

    local procedure RunAndVerifyDraftNoticeReport(PaymentAddressCode: Code[10])
    var
        PaymentLine: Record "Payment Line";
    begin
        // Setup: Create payment Line.
        Initialize();
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, CreateVendor(), '', PaymentAddressCode);  // Blank for Currency code.
        PaymentLine.SetRange("No.", PaymentLine."No.");

        // Exercise.
        REPORT.Run(REPORT::"Draft notice", true, false, PaymentLine);  // TRUE for ReqWindow and FALSE for SystemPrinter.

        // Verify: Verify Account No on Draft Notice report.
        VerifyValuesOnXML(PaymentLines1NoCap, PaymentLine."No.");
    end;

    [Test]
    [HandlerFunctions('WithdrawNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithdrawNoticeError()
    begin
        // Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10870 'Withdraw Notice'.
        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Withdraw notice");

        // Verify: Verify expected error code. Actual error is 'You must specify a withdraw number'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithdrawNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBlankPmtAddressWithdrawNotice()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10870 'Withdraw Notice' with blank Payment Address Code.
        RunAndVerifyWithdrawNoticeReport('');  // Blank for Payment Address code.
    end;

    [Test]
    [HandlerFunctions('WithdrawNoticeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLinePmtAddressWithdrawNotice()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10870 'Withdraw Notice' with Payment Address Code.
        RunAndVerifyWithdrawNoticeReport(LibraryUTUtility.GetNewCode10());
    end;

    local procedure RunAndVerifyWithdrawNoticeReport(PaymentAddressCode: Code[10])
    var
        PaymentLine: Record "Payment Line";
    begin
        // Setup: Create payment Line.
        Initialize();
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Customer, CreateCustomer(), '', PaymentAddressCode);  // Blank for Currency code.
        PaymentLine.SetRange("No.", PaymentLine."No.");

        // Exercise.
        REPORT.Run(REPORT::"Withdraw notice", true, false, PaymentLine);  // TRUE for ReqWindow and FALSE for SystemPrinter.

        // Verify: Verify Account No on Withdraw Notice report.
        VerifyValuesOnXML(PaymentLines1NoCap, PaymentLine."No.");
    end;

    [Test]
    [HandlerFunctions('DraftRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportDraftRecapitulationError()
    begin
        // Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Draft recapitulation");

        // Verify: Verify expected error code. Actual error is 'You must specify a transfer number'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('DraftRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineDraftRecapitulationError()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
        // Setup & Exercise.
        Initialize();
        asserterror CreatePaymentLineAndRunDraftRecapitulationReport('');  // Blank for AccountNo.

        // Verify: Verify expected error code. Actual error is 'Vendor does not exist'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('DraftRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineDraftRecapitulation()
    var
        VendorNo: Code[20];
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10869 'Draft Recapitulation'.
        // Setup & Exercise.
        Initialize();
        VendorNo := CreateVendor();
        CreatePaymentLineAndRunDraftRecapitulationReport(VendorNo);

        // Verify: Verify Account No on XML after running Draft Recapitulation report.
        VerifyValuesOnXML(PaymentLinesAccountNoCap, VendorNo);
    end;

    [Test]
    [HandlerFunctions('WithdrawRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithdrawRecapitulationError()
    begin
        // Purpose of the test is to validate On Pre Report Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation',
        // Setup.
        Initialize();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Withdraw recapitulation");

        // Verify: Verify expected error code. Actual error is 'You must specify a withdraw number'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithdrawRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineWithdrawRecapitulationError()
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation'.
        // Setup & Exercise.
        Initialize();
        asserterror CreatePaymentLineAndRunWithdrawRecapitulationReport('');  // Blank for AccountNo.

        // Verify: Verify expected error code. Actual error is 'Customer  does not exist'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithdrawRecapitulationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineWithdrawRecapitulation()
    var
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10871 'Withdraw Recapitulation'.
        // Setup & Exercise.
        Initialize();
        CustomerNo := CreateCustomer();
        CreatePaymentLineAndRunWithdrawRecapitulationReport(CustomerNo);

        // Verify: Verify Account No on XML after running Withdraw Recapitulation report.
        VerifyValuesOnXML(PaymentLinesAccountNoCap, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('RemittanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineRemittance()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to validate On After Get Record Trigger of Payment Line for Report ID - 10867 Remittance.
        // Setup: Create payment Line.
        Initialize();
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Customer, CreateCustomer(), CreateCurrency(), '');  // Blank for Payment Address Code.
        PaymentLine.SetRange("No.", PaymentLine."No.");

        // Exercise.
        REPORT.Run(REPORT::Remittance, true, false, PaymentLine);  // TRUE for ReqWindow and FALSE for SystemPrinter.

        // Verify: Verify Account No on XML after running Remittance report.
        VerifyValuesOnXML(PaymentLineAccountNoCap, PaymentLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('DraftNoticeToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DraftNoticeSaveToExcel()
    var
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 332702] Run report "Draft notice" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, CreateVendor(), '', '');

        // [WHEN] Run report "Draft notice", save report output to Excel file.
        PaymentLine.SetRecFilter();
        REPORT.Run(REPORT::"Draft notice", true, false, PaymentLine);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 6, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Draft notice'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DraftRecapitulationToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DraftRecapitulationSaveToExcel()
    var
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 332702] Run report "Draft recapitulation" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, CreateVendor(), '', '');

        // [WHEN] Run report "Draft recapitulation", save report output to Excel file.
        PaymentLine.SetRecFilter();
        REPORT.Run(REPORT::"Draft recapitulation", true, false, PaymentLine);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 7, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Draft Recapitulation'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RemittanceToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemittanceSaveToExcel()
    var
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 332702] Run report "Remittance" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Customer, CreateCustomer(), '', '');

        // [WHEN] Run report "Remittance", save report output to Excel file.
        PaymentLine.SetRecFilter();
        REPORT.Run(REPORT::"Remittance", true, false, PaymentLine);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 8, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Remittance'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('WithdrawRecapitulationToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WithdrawRecapitulationSaveToExcel()
    var
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 332702] Run report "Withdraw recapitulation" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, CreateVendor(), '', '');

        // [WHEN] Run report "Withdraw recapitulation", save report output to Excel file.
        PaymentLine.SetRecFilter();
        REPORT.Run(REPORT::"Withdraw recapitulation", true, false, PaymentLine);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 13, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Withdraw Recapitulation'), '');
    end;

    [Test]
    [HandlerFunctions('WithdrawNoticeToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WithdrawNoticeSaveToExcel()
    var
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 337173] Run report "Withdraw notice" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Customer, CreateCustomer(), '', '');

        // [WHEN] Run report "Withdraw notice", save report output to Excel file.
        PaymentLine.SetRecFilter();
        REPORT.Run(REPORT::"Withdraw notice", true, false, PaymentLine);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 12, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Withdraw'), '');
    end;

    [Test]
    [HandlerFunctions('GLCustLedgerRecoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunReportGLCustLedgerRecoWithoutError()
    begin
        // [SCENARIO 455845] Run Report with no error message.
        Initialize();

        // [VERIFY] Run report and save file in pdf successfully in handler page.
        REPORT.Run(REPORT::"GL/Cust. Ledger Reconciliation");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentHeader(): Code[20]
    var
        PaymentHeader: Record "Payment Header";
    begin
        PaymentHeader."No." := LibraryUTUtility.GetNewCode();
        PaymentHeader."Account Type" := PaymentHeader."Account Type"::"Bank Account";
        PaymentHeader.Insert();
        exit(PaymentHeader."No.");
    end;

    local procedure CreatePaymentLine(var PaymentLine: Record "Payment Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; PaymentAddressCode: Code[10])
    begin
        PaymentLine."No." := CreatePaymentHeader();
        PaymentLine."Account Type" := AccountType;
        PaymentLine."Account No." := AccountNo;
        PaymentLine."Currency Code" := CurrencyCode;
        PaymentLine.Marked := true;
        PaymentLine."Payment Address Code" := PaymentAddressCode;
        PaymentLine."Applies-to ID" := LibraryUTUtility.GetNewCode10();
        PaymentLine.Insert();
    end;

    local procedure CreatePaymentLineAndRunDraftRecapitulationReport(VendorNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        // Setup: Create Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Vendor, VendorNo, CreateCurrency(), '');  // Blank for Payment Address code.
        PaymentLine.SetRange("No.", PaymentLine."No.");

        // Exercise.
        REPORT.Run(REPORT::"Draft recapitulation", true, false, PaymentLine);  // TRUE for ReqWindow and FALSE for SystemPrinter.
    end;

    local procedure CreatePaymentLineAndRunWithdrawRecapitulationReport(CustomerNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        // Setup: Create Payment Line.
        CreatePaymentLine(PaymentLine, PaymentLine."Account Type"::Customer, CustomerNo, CreateCurrency(), '');  // Blank for Payment Address code.
        PaymentLine.SetRange("No.", PaymentLine."No.");

        // Exercise.
        REPORT.Run(REPORT::"Withdraw recapitulation", true, false, PaymentLine);  // TRUE for ReqWindow and FALSE for SystemPrinter.
    end;

    local procedure CreatePaymentLineAndRunPaymentReport(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; ReportID: Integer)
    var
        PaymentLine: Record "Payment Line";
    begin
        // Setup: Create Payment Line.
        CreatePaymentLine(PaymentLine, AccountType, AccountNo, CurrencyCode, '');  // Blank for Payment Address code.
        LibraryVariableStorage.Enqueue(PaymentLine."No.");  // Enqueue for BillRequestpageHandler and DraftRequestPageHandler.

        // Exercise.
        REPORT.Run(ReportID);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure VerifyFileNotEmpty(FileName: Text): Boolean
    var
        File: File;
    begin
        // The parameter FileName should contain the full File Name including path.
        if FileName = '' then
            exit(false);
        if File.Open(FileName) then
            if File.Len > 0 then
                exit(true);
        exit(false);
    end;

    local procedure VerifyValuesOnXML(Caption: Text[50]; Value: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCustLedgerReconciliationRequestPageHandler(var GLCustLedgerReconciliation: TestRequestPage "GL/Cust. Ledger Reconciliation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GLCustLedgerReconciliation.Customer.SetFilter("No.", No);
        GLCustLedgerReconciliation.Customer.SetFilter("Date Filter", Format(0D));
        GLCustLedgerReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVendLedgerReconciliationRequestPageHandler(var GLVendLedgerReconciliation: TestRequestPage "GL/Vend. Ledger Reconciliation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GLVendLedgerReconciliation.Vendor.SetFilter("No.", No);
        GLVendLedgerReconciliation.Vendor.SetFilter("Date Filter", Format(0D));
        GLVendLedgerReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentListRequestPageHandler(var PaymentList: TestRequestPage "Payment List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PaymentList."Payment Line".SetFilter("No.", No);
        PaymentList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillRequestpageHandler(var Bill: TestRequestPage Bill)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Bill."Payment Line".SetFilter("No.", No);
        Bill.IssueDate.SetValue(0D);
        Bill.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillBlankCurrencyRequestpageHandler(var Bill: TestRequestPage Bill)
    var
        No: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(FileName);
        LibraryVariableStorage.Dequeue(No);
        Bill."Payment Line".SetFilter("No.", No);
        Bill.IssueDate.SetValue(0D);
        Bill.SaveAsPdf(FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftRequestPageHandler(var Draft: TestRequestPage Draft)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        Draft.IssueDate.SetValue(0D);  // Issue date
        Draft."Payment Line".SetFilter("No.", No);
        Draft.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftBlankCurrencyRequestPageHandler(var Draft: TestRequestPage Draft)
    var
        No: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(FileName);
        LibraryVariableStorage.Dequeue(No);
        Draft.IssueDate.SetValue(0D);  // Issue date
        Draft."Payment Line".SetFilter("No.", No);
        Draft.SaveAsPdf(FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftNoticeRequestPageHandler(var DraftNotice: TestRequestPage "Draft notice")
    begin
        DraftNotice.NumberOfCopies.SetValue(LibraryRandom.RandIntInRange(1, 10));
        DraftNotice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftNoticeToExcelRequestPageHandler(var DraftNotice: TestRequestPage "Draft notice")
    begin
        DraftNotice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftRecapitulationRequestPageHandler(var DraftRecapitulation: TestRequestPage "Draft recapitulation")
    begin
        DraftRecapitulation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure DraftRecapitulationToExcelRequestPageHandler(var DraftRecapitulation: TestRequestPage "Draft recapitulation")
    begin
        DraftRecapitulation.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawNoticeRequestPageHandler(var WithdrawNotice: TestRequestPage "Withdraw notice")
    begin
        WithdrawNotice.NumberOfCopies.SetValue(LibraryRandom.RandIntInRange(1, 10));
        WithdrawNotice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawNoticeToExcelRequestPageHandler(var WithdrawNotice: TestRequestPage "Withdraw notice")
    begin
        WithdrawNotice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawRecapitulationRequestPageHandler(var WithdrawRecapitulation: TestRequestPage "Withdraw recapitulation")
    begin
        WithdrawRecapitulation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawRecapitulationToExcelRequestPageHandler(var WithdrawRecapitulation: TestRequestPage "Withdraw recapitulation")
    begin
        WithdrawRecapitulation.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceRequestPageHandler(var Remittance: TestRequestPage Remittance)
    begin
        Remittance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceToExcelRequestPageHandler(var Remittance: TestRequestPage Remittance)
    begin
        Remittance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCustLedgerRecoRequestPageHandler(var GLCustLedgerReconciliation: TestRequestPage "GL/Cust. Ledger Reconciliation")
    begin
        GLCustLedgerReconciliation.Customer.SetFilter("Date Filter",
          StrSubstNo('%1..%2', CalcDate('<-1Y>', WorkDate()), CalcDate('<+1Y>', WorkDate())));
        GLCustLedgerReconciliation.SaveAsPdf(FomatFileName(GLCustLedgerReconciliation.Caption));
    end;
}

