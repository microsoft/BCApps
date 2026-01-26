codeunit 144010 "UT REP Cash Bank Giro"
{
    // // [FEATURE] [UT] [Cash Bank Giro]
    // 1-2. Purpose of this test case to validate CBG Statement and CBG Statement Line with and without Document No.
    // 3-6. Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Customer and Vendor, Bank Type "Bank/Giro" and Cash,Applies To Document No. and Identification Blank.
    // 7-8. Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Vendor and Customer, VAT Percent 0 and Random Amount and Amount Incl VAT False.
    // 
    // Covers Test Cases for WI - 342795
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                             TFS ID
    // -----------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordCBGStatementWithDocumentNo, OnAfterGetRecordCBGStatementWithoutDocumentNo                    154625
    // OnAfterGetRecordCBGStmtLineForCustomerWithBank, OnAfterGetRecordCBGStmtLineForCustomerWithCash
    // OnAfterGetRecordCBGStmtLineForVendorWithBank, OnAfterGetRecordCBGStmtLineForVendorWithCash
    // OnShowVATWithVATPercent, OnShowVATWithoutVATPercent

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStatementWithDocumentNo()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Document No.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Vendor, CBGStatement.Type::"Bank/Giro", CreateVendorLedgerEntry(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStatementWithoutDocumentNo()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line without Document No.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Customer, CBGStatement.Type::Cash, CreateCustomerLedgerEntry(), '',
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStmtLineForCustomerWithBank()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Customer, Bank Type "Bank/Giro", Applies To Document No. and Identification Blank.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Customer, CBGStatement.Type::"Bank/Giro", CreateCustomerLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStmtLineForCustomerWithCash()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Customer, Bank Type Cash, Applies To Document No. and Identification Blank.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Customer, CBGStatement.Type::Cash, CreateCustomerLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStmtLineForVendorWithBank()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Vendor, Bank Type "Bank/Giro", Applies To Document No. and Identification Blank.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Vendor, CBGStatement.Type::"Bank/Giro", CreateVendorLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCBGStmtLineForVendorWithCash()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Vendor, Bank Type Cash, Applies To Document No. and Identification Blank.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Vendor, CBGStatement.Type::Cash, CreateVendorLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', LibraryRandom.RandInt(10), true);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnShowVATWithVATPercent()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Vendor, VAT Percent 0 and Amount Incl VAT False.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Vendor, CBGStatement.Type::Cash, CreateVendorLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', 0, false);  // Taking VAT Percent 0.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnShowVATWithoutVATPercent()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test case to validate CBG Statement and CBG Statement Line with Account Type Vendor, Random VAT Percent and Amount Incl VAT False.
        CBGPostingTestFromCBGStatement(
          CBGStatementLine."Account Type"::Customer, CBGStatement.Type::"Bank/Giro", CreateCustomerLedgerEntry(),
          LibraryUTUtility.GetNewCode(), '', '', '', LibraryRandom.RandInt(10), false);  // Taking Random VAT Percent.
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustEntryApplyIDInvisibleWhenPaymentHistoryLinesExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Customer with "Applied Amount" = "--" are hidden if Stan created Bank/Giro Journal lines from Payment History.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification = I1.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockCustLedgerEntry(CustLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Customer, CustLedgerEntry."Customer No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Customer Ledger Entry linked with GBG Statement Line.
        UpdateCustLedgerEntryForCBGReport(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CustLedgerEntry.Description)), 1,
            MaxStrLen(CustLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("External Document No."), DATABASE::"Cust. Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is hidden off Applied Entry section.
        VerifyCBGEntryApplyIDLineInvisible();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustEntryApplyIDVisibleWhenPaymentHistoryLinesNotExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Customer with "Applied Amount" = "--" are visible if Stan created Bank/Giro Journal lines manually.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification has no value.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockCustLedgerEntry(CustLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Customer, CustLedgerEntry."Customer No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"), '',
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Customer Ledger Entry linked with GBG Statement Line.
        UpdateCustLedgerEntryForCBGReport(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CustLedgerEntry.Description)), 1,
            MaxStrLen(CustLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("External Document No."), DATABASE::"Cust. Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is visible in Applied Entry section.
        VerifyCBGCustEntryApplyIDLineVisible(CustLedgerEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorEntryApplyIDInvisibleWhenPaymentHistoryLinesExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Vendor with "Applied Amount" = "--" are hidden if Stan created Bank/Giro Journal lines from Payment History.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification = I1.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockVendLedgerEntry(VendorLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Vendor Ledger Entry linked with GBG Statement Line.
        UpdateVendorLedgerEntryForCBGReport(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(VendorLedgerEntry.Description)), 1,
            MaxStrLen(VendorLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("External Document No."), DATABASE::"Vendor Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is hidden off Applied Entry section.
        VerifyCBGEntryApplyIDLineInvisible();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorEntryApplyIDVisibleWhenPaymentHistoryLinesNotExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Vendor with "Applied Amount" = "--" are visible if Stan created Bank/Giro Journal lines manually.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification has no value.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockVendLedgerEntry(VendorLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"), '',
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Vendor Ledger Entry linked with GBG Statement Line.
        UpdateVendorLedgerEntryForCBGReport(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(VendorLedgerEntry.Description)), 1,
            MaxStrLen(VendorLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("External Document No."), DATABASE::"Vendor Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is visible in Applied Entry section.
        VerifyCBGVendorEntryApplyIDLineVisible(VendorLedgerEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmplEntryApplyIDInvisibleWhenPaymentHistoryLinesExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Employee with "Applied Amount" = "--" are hidden if Stan created Bank/Giro Journal lines from Payment History.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification = I1.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockEmplLedgerEntry(EmployeeLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Employee Ledger Entry linked with GBG Statement Line.
        UpdateEmplLedgerEntryForCBGReport(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(EmployeeLedgerEntry.FieldNo("Document No."), DATABASE::"Employee Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(EmployeeLedgerEntry.Description)), 1,
            MaxStrLen(EmployeeLedgerEntry.Description)),
          true,
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is hidden off Applied Entry section.
        VerifyCBGEntryApplyIDLineInvisible();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmplEntryApplyIDVisibleWhenPaymentHistoryLinesNotExist()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. Applied Entries for Employee with "Applied Amount" = "--" are visible if Stan created Bank/Giro Journal lines manually.
        Initialize();

        // [GIVEN] CBG Statement with linked CBG Statement Line. "CBG Statement Line".Identification has no value.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockEmplLedgerEntry(EmployeeLedgerEntry);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"), '',
          LibraryRandom.RandInt(10), false);

        // [GIVEN] Employee Ledger Entry linked with GBG Statement Line.
        UpdateEmplLedgerEntryForCBGReport(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(EmployeeLedgerEntry.FieldNo("Document No."), DATABASE::"Employee Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(EmployeeLedgerEntry.Description)), 1,
            MaxStrLen(EmployeeLedgerEntry.Description)),
          true,
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Line with "Applied Amount" = "--" is visible in Applied Entry section.
        VerifyCBGEmplEntryApplyIDLineVisible(EmployeeLedgerEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustEntryAppliedAmountZeroDecimalsAreShown()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. "Applied Amount" values for Applied Entries for Customer are shown with decimals when the decimals equal to zero.
        Initialize();

        // [GIVEN] Bank/Giro Journal line created from Payment History.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockCustLedgerEntry(CustLedgerEntry);
        MockCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Customer, CustLedgerEntry."Customer No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        MockPaymentHistoryLine(PaymentHistoryLine, CBGStatementLine);
        MockDetailLine(DetailLine, PaymentHistoryLine);
        UpdateDetailLineForCBGReport(
          DetailLine, DetailLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          CustLedgerEntry."Entry No.", LibraryRandom.RandInt(100));

        UpdateCustLedgerEntryForCBGReport(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CustLedgerEntry.Description)), 1,
            MaxStrLen(CustLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("External Document No."), DATABASE::"Cust. Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Zero decimals for "Applied Amount" are shown in Applied Entry section.
        VerifyAppliedAmountZeroDecimalsAreShown(DetailLine.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorEntryAppliedAmountZeroDecimalsAreShown()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. "Applied Amount" values for Applied Entries for Vendor are shown with decimals when the decimals equal to zero.
        Initialize();

        // [GIVEN] Bank/Giro Journal line created from Payment History.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockVendLedgerEntry(VendorLedgerEntry);
        MockCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        MockPaymentHistoryLine(PaymentHistoryLine, CBGStatementLine);
        MockDetailLine(DetailLine, PaymentHistoryLine);
        UpdateDetailLineForCBGReport(
          DetailLine, DetailLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry."Entry No.", LibraryRandom.RandInt(100));

        UpdateVendorLedgerEntryForCBGReport(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(VendorLedgerEntry.Description)), 1,
            MaxStrLen(VendorLedgerEntry.Description)),
          true,
          LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("External Document No."), DATABASE::"Vendor Ledger Entry"),
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Zero decimals for "Applied Amount" are shown in Applied Entry section.
        VerifyAppliedAmountZeroDecimalsAreShown(DetailLine.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EmplEntryAppliedAmountZeroDecimalsAreShown()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 251022] Stan runs "CBG Posting - Test" report from Bank/Giro Journal. "Applied Amount" values for Applied Entries for Employee are shown with decimals when the decimals equal to zero.
        Initialize();

        // [GIVEN] Bank/Giro Journal line created from Payment History.
        MockCBGStatement(
          CBGStatement, CBGStatement.Type::"Bank/Giro",
          LibraryUtility.GenerateRandomCode20(CBGStatement.FieldNo("Document No."), DATABASE::"CBG Statement"));

        MockEmplLedgerEntry(EmployeeLedgerEntry);
        MockCBGStatementLine(CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.", '',
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo("Applies-to ID"), DATABASE::"CBG Statement Line"),
          LibraryUtility.GenerateRandomCode(CBGStatementLine.FieldNo(Identification), DATABASE::"CBG Statement Line"),
          LibraryRandom.RandInt(10), false);

        MockPaymentHistoryLine(PaymentHistoryLine, CBGStatementLine);
        MockDetailLine(DetailLine, PaymentHistoryLine);
        UpdateDetailLineForCBGReport(
          DetailLine, DetailLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.",
          EmployeeLedgerEntry."Entry No.", LibraryRandom.RandInt(100));

        UpdateEmplLedgerEntryForCBGReport(
          EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Invoice,
          LibraryUtility.GenerateRandomCode20(EmployeeLedgerEntry.FieldNo("Document No."), DATABASE::"Employee Ledger Entry"),
          CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(EmployeeLedgerEntry.Description)), 1,
            MaxStrLen(EmployeeLedgerEntry.Description)),
          true,
          CBGStatementLine."Applies-to ID", WorkDate());

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [WHEN] Run "CBG Posting - Test" report.
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] Zero decimals for "Applied Amount" are shown in Applied Entry section.
        VerifyAppliedAmountZeroDecimalsAreShown(DetailLine.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CBGPostingTestFromCBGStatement(AccountType: Option; Type: Option; AccountNo: Code[20]; DocumentNo: Code[20]; AppliesToDocNo: Code[20]; AppliesToID: Code[50]; Identification: Code[20]; VATPercent: Integer; AmountInclVAT: Boolean)
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create CBG Statement, CBG StatementLine.
        Initialize();
        MockCBGStatement(CBGStatement, Type, DocumentNo);
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          AccountType, AccountNo, AppliesToDocNo, AppliesToID, Identification, VATPercent, AmountInclVAT);
        LibraryVariableStorage.Enqueue(CBGStatement."No.");  // Enqueue value for CBGPostingTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(CBGStatement."Journal Template Name");
        LibraryVariableStorage.Enqueue(AmountInclVAT);  // Enqueue value for CBGPostingTestRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"CBG Posting - Test");

        // Verify: Verify CBG Statement.
        VerifyCBGDataOnReport(CBGStatement, AccountNo);
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestXmlRequestPageHandler')]
    PROCEDURE CustLedgerEntriesAreNotShownForBlankedAppliesToID()
    VAR
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    BEGIN
        // [FEATURE] [Customer]
        // [SCENARIO 395874] CBG Posting - Test report doesn't show opened customer ledger entries for blanked Applies-To ID
        Initialize();

        // [GIVEN] Customer with opened ledger entry
        MockCustLedgerEntry(CustLedgerEntry);
        UpdateCustLedgerEntryForCBGReport(
          CustLedgerEntry, CustLedgerEntry."Document Type"::" ", '', 'dummy', true, 'dummy', '', WorkDate());

        // [GIVEN] CBG Statement with customer line with blanked Applies-To ID
        MockCBGStatement(CBGStatement, CBGStatement.Type::"Bank/Giro", LibraryUtility.GenerateGUID());
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          '', '', '', LibraryRandom.RandInt(10), false);

        // [WHEN] Run "CBG Posting - Test" report
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] There is no customer "Applied" section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AccType_CBGStmtLine', 'Customer');
        LibraryReportDataset.AssertElementWithValueExists('AccNo_CBGStmtLine', CustLedgerEntry."Customer No.");
        LibraryReportDataset.AssertElementWithValueNotExist('CustNo_CustEntryApplyID', CustLedgerEntry."Customer No.");
        LibraryVariableStorage.AssertEmpty();
    END;

    [Test]
    [HandlerFunctions('CBGPostingTestXmlRequestPageHandler')]
    PROCEDURE VendLedgerEntriesAreNotShownForBlankedAppliesToID()
    VAR
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    BEGIN
        // [FEATURE] [Vendor]
        // [SCENARIO 395874] CBG Posting - Test report doesn't show opened vendor ledger entries for blanked Applies-To ID
        Initialize();

        // [GIVEN] Vendor with opened ledger entry
        MockVendLedgerEntry(VendorLedgerEntry);
        UpdateVendorLedgerEntryForCBGReport(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", '', 'dummy', true, 'dummy', '', WorkDate());

        // [GIVEN] CBG Statement with vendor line with blanked Applies-To ID
        MockCBGStatement(CBGStatement, CBGStatement.Type::"Bank/Giro", LibraryUtility.GenerateGUID());
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.",
          '', '', '', LibraryRandom.RandInt(10), false);

        // [WHEN] Run "CBG Posting - Test" report
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] There is no vendor "Applied" section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AccType_CBGStmtLine', 'Vendor');
        LibraryReportDataset.AssertElementWithValueExists('AccNo_CBGStmtLine', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.AssertElementWithValueNotExist('VendorNo_VendEntryApplyID', VendorLedgerEntry."Vendor No.");
        LibraryVariableStorage.AssertEmpty();
    END;

    [Test]
    [HandlerFunctions('CBGPostingTestXmlRequestPageHandler')]
    PROCEDURE EmplLedgerEntriesAreNotShownForBlankedAppliesToID()
    VAR
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    BEGIN
        // [FEATURE] [Employee]
        // [SCENARIO 395874] CBG Posting - Test report doesn't show opened employee ledger entries for blanked Applies-To ID
        Initialize();

        // [GIVEN] Employee with opened ledger entry
        MockEmplLedgerEntry(EmployeeLedgerEntry);
        UpdateEmplLedgerEntryForCBGReport(
          EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", '', 'dummy', true, '', WorkDate());

        // [GIVEN] CBG Statement with employee line with blanked Applies-To ID
        MockCBGStatement(CBGStatement, CBGStatement.Type::"Bank/Giro", LibraryUtility.GenerateGUID());
        MockCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatementLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.",
          '', '', '', LibraryRandom.RandInt(10), false);

        // [WHEN] Run "CBG Posting - Test" report
        RunCBGPostingTestReport(CBGStatement."No.", CBGStatement."Journal Template Name", true);

        // [THEN] There is no employee "Applied" section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AccType_CBGStmtLine', 'Employee');
        LibraryReportDataset.AssertElementWithValueExists('AccNo_CBGStmtLine', EmployeeLedgerEntry."Employee No.");
        LibraryReportDataset.AssertElementWithValueNotExist('EmployeeNo_EmplEntryApplyID', EmployeeLedgerEntry."Employee No.");
        LibraryVariableStorage.AssertEmpty();
    END;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure MockCBGStatement(var CBGStatement: Record "CBG Statement"; Type: Option; DocumentNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CBGStatement.Init();
        CBGStatement."Journal Template Name" := GenJournalTemplate.Name;
        CBGStatement."No." := LibraryRandom.RandInt(10);
        CBGStatement."Account No." := CBGStatement."Journal Template Name";
        CBGStatement."Account Type" := CBGStatement."Account Type"::"Bank Account";
        CBGStatement.Date := WorkDate();
        CBGStatement.Type := Type;
        CBGStatement."Document No." := DocumentNo;
        CBGStatement.Currency := LibraryUTUtility.GetNewCode10();
        CBGStatement.Insert();
    end;

    local procedure MockCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JnlTemplateName: Code[10]; No: Integer; AccountType: Option; AccountNo: Code[20]; AppliesToDocNo: Code[20]; AppliesToID: Code[50]; Identification: Code[20]; VATPercent: Integer; AmountInclVAT: Boolean)
    begin
        CBGStatementLine.Init();
        CBGStatementLine."Journal Template Name" := JnlTemplateName;
        CBGStatementLine."No." := No;
        CBGStatementLine."Account Type" := AccountType;
        CBGStatementLine."Account No." := AccountNo;
        CBGStatementLine.Description := CBGStatementLine."Account No.";
        CBGStatementLine."Applies-to Doc. No." := AppliesToDocNo;
        CBGStatementLine."Applies-to ID" := AppliesToID;
        CBGStatementLine.Identification := Identification;
        CBGStatementLine."VAT %" := VATPercent;
        CBGStatementLine."Amount incl. VAT" := AmountInclVAT;
        CBGStatementLine.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgerEntry(CustLedgerEntry);
        exit(CustLedgerEntry."Customer No.");
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgerEntry(VendorLedgerEntry);
        exit(VendorLedgerEntry."Vendor No.");
    end;

    local procedure MockVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry.Insert();
    end;

    local procedure MockEmplLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(EmployeeLedgerEntry, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Employee No." := LibraryUTUtility.GetNewCode();
        EmployeeLedgerEntry.Insert();
    end;

    local procedure MockPaymentHistoryLine(var PaymentHistoryLine: Record "Payment History Line"; CBGStatementLine: Record "CBG Statement Line")
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Line No." := LibraryUtility.GetNewRecNo(PaymentHistoryLine, PaymentHistoryLine.FieldNo("Line No."));
        PaymentHistoryLine."Our Bank" := CBGStatementLine."Statement No.";
        PaymentHistoryLine.Amount := CBGStatementLine.Amount;
        PaymentHistoryLine."Account No." := CBGStatementLine."Account No.";
        PaymentHistoryLine.Status := PaymentHistoryLine.Status::Transmitted;
        PaymentHistoryLine.Identification := CBGStatementLine.Identification;
        PaymentHistoryLine.Insert();
    end;

    local procedure MockDetailLine(var DetailLine: Record "Detail Line"; PaymentHistoryLine: Record "Payment History Line")
    begin
        DetailLine.Init();
        DetailLine."Transaction No." := LibraryUtility.GetNewRecNo(DetailLine, DetailLine.FieldNo("Transaction No."));
        DetailLine."Connect Batches" := PaymentHistoryLine."Run No.";
        DetailLine."Connect Lines" := PaymentHistoryLine."Line No.";
        DetailLine."Our Bank" := PaymentHistoryLine."Our Bank";
        DetailLine.Insert();
    end;

    local procedure UpdateDetailLineForCBGReport(var DetailLine: Record "Detail Line"; AccountType: Option; AccountNo: Code[20]; SerialNo: Integer; Amount: Decimal)
    begin
        DetailLine.Status := DetailLine.Status::"In process";
        DetailLine."Account Type" := AccountType;
        DetailLine."Account No." := AccountNo;
        DetailLine."Serial No. (Entry)" := SerialNo;
        DetailLine.Amount := Amount;
        DetailLine.Modify();
    end;

    local procedure UpdateCustLedgerEntryForCBGReport(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Description: Text[100]; Open: Boolean; ExtDocumentNo: Code[35]; AppliesToID: Code[50]; DocumentDate: Date)
    begin
        CustLedgerEntry."Applies-to ID" := AppliesToID;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Description := Description;
        CustLedgerEntry.Open := Open;
        CustLedgerEntry."External Document No." := ExtDocumentNo;
        CustLedgerEntry."Document Date" := DocumentDate;
        CustLedgerEntry.Modify();
    end;

    local procedure UpdateVendorLedgerEntryForCBGReport(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Description: Text[100]; Open: Boolean; ExtDocumentNo: Code[35]; AppliesToID: Code[50]; DocumentDate: Date)
    begin
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry.Description := Description;
        VendorLedgerEntry.Open := Open;
        VendorLedgerEntry."External Document No." := ExtDocumentNo;
        VendorLedgerEntry."Document Date" := DocumentDate;
        VendorLedgerEntry.Modify();
    end;

    local procedure UpdateEmplLedgerEntryForCBGReport(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Description: Text[100]; Open: Boolean; AppliesToID: Code[50]; DocumentDate: Date)
    begin
        EmployeeLedgerEntry."Applies-to ID" := AppliesToID;
        EmployeeLedgerEntry."Document Type" := DocumentType;
        EmployeeLedgerEntry."Document No." := DocumentNo;
        EmployeeLedgerEntry.Description := Description;
        EmployeeLedgerEntry.Open := Open;
        EmployeeLedgerEntry."Posting Date" := DocumentDate;
        EmployeeLedgerEntry.Modify();
    end;

    local procedure RunCBGPostingTestReport(CBGStatementNo: Integer; JnlTemplateName: Code[10]; ShowAppliedEntries: Boolean)
    begin
        Commit();
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        LibraryVariableStorage.Enqueue(CBGStatementNo);
        LibraryVariableStorage.Enqueue(JnlTemplateName);
        LibraryVariableStorage.Enqueue(ShowAppliedEntries);
        REPORT.Run(REPORT::"CBG Posting - Test");
    end;

    local procedure VerifyCBGDataOnReport(CBGStatement: Record "CBG Statement"; AccountNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_CBGStmt', CBGStatement."No.");
        LibraryReportDataset.AssertElementWithValueExists('AccNo_CBGStmt', CBGStatement."Account No.");
        LibraryReportDataset.AssertElementWithValueExists('JnlTmpltName_CBGStmt', CBGStatement."Journal Template Name");
        LibraryReportDataset.AssertElementWithValueExists('Currency_CBGStatement', CBGStatement.Currency);
        LibraryReportDataset.AssertElementWithValueExists('Desc_CBGStmtLine', AccountNo);
    end;

    local procedure VerifyCBGCustEntryApplyIDLineVisible(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        AppliedEntryCaptionRowNo: Integer;
        FirstAppliedEntryRowNo: Integer;
        DocTypeColNo: Integer;
        DocNoColNo: Integer;
        DescriptionColNo: Integer;
        ExtDocNoColNo: Integer;
        DocDateColNo: Integer;
        AppliedAmountColNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        AppliedEntryCaptionRowNo := LibraryReportValidation.FindRowNoFromColumnCaption('Applied Entries');
        FirstAppliedEntryRowNo := AppliedEntryCaptionRowNo + 2;

        DocTypeColNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Applied Entries') + 1;
        DocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Our Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        DescriptionColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Description', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        ExtDocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Your Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '') + 1;
        DocDateColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Date', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        AppliedAmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Applied amount', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');

        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocTypeColNo, Format(CustLedgerEntry."Document Type"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocNoColNo, CustLedgerEntry."Document No.");
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DescriptionColNo, CustLedgerEntry.Description);
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, ExtDocNoColNo, CustLedgerEntry."External Document No.");
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocDateColNo, Format(CustLedgerEntry."Document Date"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, AppliedAmountColNo, '--');
    end;

    local procedure VerifyCBGVendorEntryApplyIDLineVisible(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        AppliedEntryCaptionRowNo: Integer;
        FirstAppliedEntryRowNo: Integer;
        DocTypeColNo: Integer;
        DocNoColNo: Integer;
        DescriptionColNo: Integer;
        ExtDocNoColNo: Integer;
        DocDateColNo: Integer;
        AppliedAmountColNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        AppliedEntryCaptionRowNo := LibraryReportValidation.FindRowNoFromColumnCaption('Applied Entries');
        FirstAppliedEntryRowNo := AppliedEntryCaptionRowNo + 2;

        DocTypeColNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Applied Entries') + 1;
        DocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Our Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        DescriptionColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Description', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        ExtDocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Your Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '') + 1;
        DocDateColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Date', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        AppliedAmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Applied amount', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');

        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocTypeColNo, Format(VendorLedgerEntry."Document Type"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocNoColNo, VendorLedgerEntry."Document No.");
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DescriptionColNo, VendorLedgerEntry.Description);
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, ExtDocNoColNo, VendorLedgerEntry."External Document No.");
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocDateColNo, Format(VendorLedgerEntry."Document Date"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, AppliedAmountColNo, '--');
    end;

    local procedure VerifyCBGEmplEntryApplyIDLineVisible(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        AppliedEntryCaptionRowNo: Integer;
        FirstAppliedEntryRowNo: Integer;
        DocTypeColNo: Integer;
        DocNoColNo: Integer;
        DescriptionColNo: Integer;
        ExtDocNoColNo: Integer;
        DocDateColNo: Integer;
        AppliedAmountColNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        AppliedEntryCaptionRowNo := LibraryReportValidation.FindRowNoFromColumnCaption('Applied Entries');
        FirstAppliedEntryRowNo := AppliedEntryCaptionRowNo + 2;

        DocTypeColNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Applied Entries') + 1;
        DocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Our Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        DescriptionColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Description', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        ExtDocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Your Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '') + 1;
        DocDateColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Date', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        AppliedAmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Applied amount', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');

        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocTypeColNo, Format(EmployeeLedgerEntry."Document Type"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocNoColNo, EmployeeLedgerEntry."Document No.");
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DescriptionColNo, EmployeeLedgerEntry.Description);
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, ExtDocNoColNo, '--');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocDateColNo, Format(EmployeeLedgerEntry."Posting Date"));
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, AppliedAmountColNo, '--');
    end;

    local procedure VerifyCBGEntryApplyIDLineInvisible()
    var
        AppliedEntryCaptionRowNo: Integer;
        FirstAppliedEntryRowNo: Integer;
        DocTypeColNo: Integer;
        DocNoColNo: Integer;
        DescriptionColNo: Integer;
        ExtDocNoColNo: Integer;
        DocDateColNo: Integer;
        AppliedAmountColNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        AppliedEntryCaptionRowNo := LibraryReportValidation.FindRowNoFromColumnCaption('Applied Entries');
        FirstAppliedEntryRowNo := AppliedEntryCaptionRowNo + 2;

        DocTypeColNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Applied Entries') + 1;
        DocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Our Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        DescriptionColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Description', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        ExtDocNoColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Your Document No.', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '') + 1;
        DocDateColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Date', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');
        AppliedAmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Applied amount', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');

        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocTypeColNo, '');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocNoColNo, '');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DescriptionColNo, '');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, ExtDocNoColNo, '');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, DocDateColNo, '');
        LibraryReportValidation.VerifyCellValue(FirstAppliedEntryRowNo, AppliedAmountColNo, '');
    end;

    local procedure VerifyAppliedAmountZeroDecimalsAreShown(AppliedAmountValue: Decimal)
    var
        AppliedEntryCaptionRowNo: Integer;
        AppliedAmountColNo: Integer;
        AppliedEntryDetailRowNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        AppliedEntryCaptionRowNo := LibraryReportValidation.FindRowNoFromColumnCaption('Applied Entries');
        AppliedAmountColNo :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Applied amount', StrSubstNo('%1..', AppliedEntryCaptionRowNo), '');

        AppliedEntryDetailRowNo :=
          LibraryReportValidation.FindRowNoFromColumnNoAndValueInsideArea(
            AppliedAmountColNo, Format(AppliedAmountValue), StrSubstNo('%1..', AppliedEntryCaptionRowNo));

        LibraryReportValidation.VerifyCellNumberFormat(AppliedEntryDetailRowNo, AppliedAmountColNo, '0.00');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CBGPostingTestRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    begin
        CBGPostingTest."CBG Statement".SetFilter("No.", Format(LibraryVariableStorage.DequeueInteger()));
        CBGPostingTest."Gen. Journal Batch".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        CBGPostingTest."Show Applied Entries".SetValue(LibraryVariableStorage.DequeueBoolean());
        CBGPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CBGPostingTestExcelRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    var
        FileName: Variant;
    begin
        FileName := LibraryVariableStorage.DequeueText();
        CBGPostingTest."CBG Statement".SetFilter("No.", Format(LibraryVariableStorage.DequeueInteger()));
        CBGPostingTest."Gen. Journal Batch".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        CBGPostingTest."Show Applied Entries".SetValue(LibraryVariableStorage.DequeueBoolean());
        CBGPostingTest.SaveAsExcel(FileName);
    end;

    [RequestPageHandler]
    procedure CBGPostingTestXmlRequestPageHandler(VAR CBGPostingTest: TestRequestPage "CBG Posting - Test")
    begin
        LibraryVariableStorage.DequeueText(); // dummy
        CBGPostingTest."CBG Statement".SetFilter("No.", Format(LibraryVariableStorage.DequeueInteger()));
        CBGPostingTest."Gen. Journal Batch".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        CBGPostingTest."Show Applied Entries".SetValue(LibraryVariableStorage.DequeueBoolean());
        CBGPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

