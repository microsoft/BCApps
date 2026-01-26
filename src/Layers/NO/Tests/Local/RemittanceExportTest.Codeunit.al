codeunit 144129 "Remittance - Export Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRemittance: Codeunit "Library - Remittance";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        FileMgt: Codeunit "File Management";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        TC60552ExpectedErr: Label 'You must fill in one of the following fields in journal line %1: KID, External Document No., or Recipient Ref.';
        TC60551ExpectedErr: Label 'You must fill in one of the following fields in journal line %1: KID, External Document No. or Recipient Ref. Abroad.';
        IncorrectCharValueErr: Label 'Incorrect char value.';
        LinesDoesntMatchErr: Label 'Lines does not match.';
        MissedSpecWarningTxt: Label 'It is not required to fill in Specification (Norges Bank)';
        MissedPaymentTypeCodeAbroadWarningTxt: Label 'It is not required to fill in Payment Type Code Abroad';
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        SchemaNameTok: Label '//SchmeNm';
        WrongSchmeNmErr: Label 'Incorrect schema name.';
        HeaderNotExpectedErr: Label 'Header sequence 600F is not expected in line %1';
        HeaderExpectedErr: Label 'Header sequence 600F expected in line %1';

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60574RunTheRemittanceExportBBSReport()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
        OldDate: Date;
    begin
        // [FEATURE] [BBS]
        // [SCENARIO] the Remittance - export (BBS) report is generating correct output in the specified path
        // Setup and Execute
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBBSExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount, LibraryRemittance.GetLastPaymentOrderID());

        LibraryVariableStorage.AssertEmpty();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60574RunTheRemittanceExportBBSReportWithKID()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
        OldDate: Date;
    begin
        // [FEATURE] [BBS] [KID]
        // [SCENARIO] the Remittance - export (BBS) report is generating correct output in the specified path
        // Setup and Execute
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        GenJournalLine.Validate(KID, GetKIDNumber());
        GenJournalLine.Modify(true);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBBSExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount, LibraryRemittance.GetLastPaymentOrderID());

        LibraryVariableStorage.AssertEmpty();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60574RunTheRemittanceExportBBSReportUnstructured()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        BatchName: Code[10];
        FileName: Text;
        OldDate: Date;
    begin
        // [SCENARIO] the Remittance - export (BBS) report is generating correct output in the specified path
        // Setup and Execute
        Initialize();

        OldDate := UpdateWorkdate(Today);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup.Modify();

        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::BBS,
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        GenJournalLine.Validate("External Document No.", '');
        GenJournalLine.Modify(true);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBBSExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount, LibraryRemittance.GetLastPaymentOrderID());

        LibraryVariableStorage.AssertEmpty();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60574RunTheRemittanceExportBankReport()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
        OldDate: Date;
    begin
        // [SCENARIO] the Remittance - export (Bank) report is generating correct output in the specified path
        // Setup and Execute
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBankExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount);

        LibraryVariableStorage.AssertEmpty();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60574RunTheRemittanceExportBankReportWithKID()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
        OldDate: Date;
    begin
        // [FEATURE] [KID]
        // [SCENARIO] the Remittance - export (Bank) report is generating correct output in the specified path
        // Setup and Execute
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        GenJournalLine.Validate(KID, GetKIDNumber());
        GenJournalLine.Modify(true);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBankExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount);

        LibraryVariableStorage.AssertEmpty();
        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60563ExportWithSpecialChars()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
    begin
        // [SCENARIO] the special characters are displayed correctly in the exported text file after posting with "special characters" the External Document No.
        // Setup and Execute
        Initialize();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Fokus Bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);

        GenJournalLine.Validate("External Document No.", '@&TEST#$%*'); // Value from manual test.
        GenJournalLine.Modify(true);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBankExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBBSHandler,RemPaymOrderManExportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60573ManualExportOfPaymentOrder()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        RemittancePaymentOrder: TestPage "Remittance Payment Order";
        BatchName: Code[10];
        LastPaymentOrderID: Integer;
        FileName: Text;
        FileName2: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Do a manual export and compare with previously exported file.
        // Setup and Execute
        Initialize();

        LibraryRemittance.SetupDomesticRemittancePayment(RemittanceAgreement."Payment System"::BBS, RemittanceAgreement,
          RemittanceAccount, Vendor, GenJournalLine);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        LastPaymentOrderID := LibraryRemittance.GetLastPaymentOrderID();

        RemittancePaymentOrder.OpenEdit();
        RemittancePaymentOrder.GotoKey(LastPaymentOrderID);

        FileName2 := LibraryRemittance.GetTempFileName();
        LibraryVariableStorage.Enqueue(FileName2);
        RemittancePaymentOrder.ExportPaymentFile.Invoke(); // Manual Export.

        CompareFiles(); // -> this does absolutely nothing.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60633CreateAndWithNonLCYAndCheckAmountIsPostedInLCY()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
    begin
        // [SCENARIO] the amount is calculated in LCY (NOK), when posting with Non-LCY currency code
        Initialize();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        VerifyBankExportFileWithSinglePayment(RemittanceAgreement, RemittanceAccount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60551ErrorExportForeignUnstructuredPayments()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
    begin
        // [SCENARIO] Error if trying to export unstructured payments
        Initialize();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);

        LibraryRemittance.ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);
        GenJournalLine.Validate("External Document No.", '');
        GenJournalLine.Validate("Recipient Ref. Abroad", '');
        GenJournalLine.Modify(true);
        Commit();

        LibraryVariableStorage.Enqueue(RemittanceAgreement.Code);
        FileName := LibraryRemittance.GetTempFileName();
        LibraryVariableStorage.Enqueue(FileName);

        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJournalLine);
        Assert.AreEqual(StrSubstNo(TC60551ExpectedErr, GenJournalLine."Line No."), GetLastErrorText, 'Wrong Error Message');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TC60552ErrorExportDomesticUnstructuredPayments()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        FileName: Text;
    begin
        // [SCENARIO] Error if trying to export unstructured payments without a "Recipient Ref. 1"
        Initialize();

        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);

        LibraryRemittance.ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);
        GenJournalLine.Validate("External Document No.", '');
        GenJournalLine.Validate("Recipient Ref. 1", '');
        GenJournalLine.Modify(true);
        Commit();

        LibraryVariableStorage.Enqueue(RemittanceAgreement.Code);
        FileName := LibraryRemittance.GetTempFileName();
        LibraryVariableStorage.Enqueue(FileName);

        asserterror CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJournalLine);
        Assert.AreEqual(StrSubstNo(TC60552ExpectedErr, GenJournalLine."Line No."), GetLastErrorText, 'Wrong Error Message');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnRemitSuggestionFromGeneralJournal()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        BatchName: Code[10];
        ShortcutDimension1Code: Code[20];
        ShortcutDimension2Code: Code[20];
    begin
        // [FEATURE] [Suggest Remittance Payments] [Dimension]
        // [Scenario 364448] Report Suggest Remittance Payments trnasfers dimensions to Payment Journal
        Initialize();

        // [GIVEN] Vendor with Remittance Account
        LibraryRemittance.SetupDomesticRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine);

        // [GIVEN] General Journal Line with dimensions "X" and "Y"
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShortcutDimension1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDimension2Code := GenJournalLine."Shortcut Dimension 2 Code";

        // [WHEN] Post General Journal and run "Suggest Remittance Payments"
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);
        LibraryRemittance.ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        // [THEN] General Journal has dimension "X" and "Y"
        VerifyDimensionOnGeneralJournalLineFromInvoice(BatchName, ShortcutDimension1Code, ShortcutDimension2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,WaitingJnlPaymOverviewHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WaitingJournalPaymentOverviewReport()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        WaitingJournal: Record "Waiting Journal";
        RemittancePaymentOrder: Record "Remittance Payment Order";
        Amount: Variant;
        v: Variant;
        BatchName: Code[10];
        FileName: Text;
        dt: DateTime;
    begin
        // [FEATURE] [Waiting Journal]
        Initialize();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);

        FileName := ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        LibraryVariableStorage.Enqueue(LibraryRemittance.GetLastPaymentOrderID());
        REPORT.Run(REPORT::"Waiting Jnl - paym. overview", true);

        LibraryReportDataset.LoadDataSetFile();

        WaitingJournal.SetRange(Reference, LibraryRemittance.GetLastPaymentOrderID());
        WaitingJournal.FindFirst();
        RemittancePaymentOrder.Get(WaitingJournal."Payment Order ID - Sent");

        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The should only be one line in the Waiting Journal with the Document No.');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow('Amount_WaitingJournal', Amount);
        Assert.AreEqual(WaitingJournal.Amount, Amount, 'Amount');
        LibraryReportDataset.GetElementValueInCurrentRow('PaymOrderDate', v);
        Evaluate(dt, v, 9);
        Assert.AreEqual(RemittancePaymentOrder.Date, DT2Date(dt), 'PaymentOrderDate');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RemPaymentOrderStatusHandler')]
    [Scope('OnPrem')]
    procedure RemPaymentOrderStatusReport()
    var
        v: Variant;
        Amount: array[4] of Decimal;
        Reference: array[4] of Integer;
        i: Integer;
        State: Option Sent,Approved,Settled,Rejected;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Test for the "Rem. Payment Order Status" report.
        Initialize();

        // Setup.
        DeleteRemittancePaymentOrders();
        CreateRemittancePaymentOrder(Amount, Reference, 1);
        Commit();

        // Execute
        REPORT.Run(REPORT::"Rem. payment order status", true);
        LibraryReportDataset.LoadDataSetFile();

        // Verify
        Assert.AreEqual(4, LibraryReportDataset.RowCount(), 'RowCount');
        for i := State::Sent to State::Rejected do begin
            LibraryReportDataset.GetNextRow();

            LibraryReportDataset.GetElementValueInCurrentRow('NumberSent_RemittancePmtOrder', v);
            Assert.AreEqual(1, v, 'Number Sent');
            LibraryReportDataset.GetElementValueInCurrentRow('NumberApproved_RemittancePmtOrder', v);
            Assert.AreEqual(1, v, 'Number Approved');
            LibraryReportDataset.GetElementValueInCurrentRow('NumberSettled_RemittancePmtOrder', v);
            Assert.AreEqual(1, v, 'Number Settled');
            LibraryReportDataset.GetElementValueInCurrentRow('NumberRejected_RemittancePmtOrder', v);
            Assert.AreEqual(1, v, 'Number Rejected');

            LibraryReportDataset.GetElementValueInCurrentRow('Amount_WaitingJournal', v);
            Assert.AreEqual(Amount[i + 1], v, 'Amount');
            LibraryReportDataset.GetElementValueInCurrentRow('Reference_WaitingJournal', v);
            Assert.AreEqual(Reference[i + 1], v, 'Reference');
        end;

        // TearDown
        DeleteRemittancePaymentOrders();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemPaymentOrderStatusReportExcelLayout()
    var
        RemPaymentOrderStatus: Report "Rem. payment order status";
        Amount: array[4] of Decimal;
        Reference: array[4] of Integer;
        LineCnt: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 256370] "Rem. Payment Order Status" report is groupped by payment status
        Initialize();

        // [GIVEN] Remittance Payment Order with 2 payments of each type Sent, Approved, Settled, Rejected
        DeleteRemittancePaymentOrders();
        LineCnt := LibraryRandom.RandIntInRange(2, 5);
        CreateRemittancePaymentOrder(Amount, Reference, LineCnt);
        Commit();

        // [WHEN] Run Rem. Payment Order Status report
        RemPaymentOrderStatus.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] Number of payments of each type Sent, Approved, Settled, Rejected is printed as 2
        LibraryReportValidation.VerifyCellValue(6, 6, 'Number Sent');
        LibraryReportValidation.VerifyCellValue(7, 6, 'Number Approved');
        LibraryReportValidation.VerifyCellValue(8, 6, 'Number Settled');
        LibraryReportValidation.VerifyCellValue(9, 6, 'Number Rejected');

        // [THEN] Total LCY amounts are shown for each group of type Sent, Approved, Settled, Rejected
        LibraryReportValidation.VerifyCellValue(15, 1, 'Sent payments - total (LCY)');
        LibraryReportValidation.VerifyCellValue(15, 11, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(19, 1, 'Approved payments - total (LCY)');
        LibraryReportValidation.VerifyCellValue(19, 11, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(23, 1, 'Settled payments - total (LCY)');
        LibraryReportValidation.VerifyCellValue(23, 11, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(27, 1, 'Rejected payments - total (LCY)');
        LibraryReportValidation.VerifyCellValue(27, 11, Format(Amount[4]));

        // TearDown
        DeleteRemittancePaymentOrders();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ConfirmHandlerForExportPayment,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndEmptySpecConfirmYes()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378832] When payment's amount is less than the limit to Norges Bank and specification field is empty then NAV asks confirmation during the export (answer = Yes)
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount greater than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Mock empty Specification (Norges Bank) field
        ResetJnlLineEmptySpecification(GenJournalLine);

        // [WHEN] Payment is being exported
        RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, MissedSpecWarningTxt, true);

        // [THEN] Confirmation dialog appeared "It is not required to fill in Specification (Norges Bank)..."
        // Verification is inside the ConfirmHandlerForExportPaymentYes
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ConfirmHandlerForExportPayment,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndEmptySpecConfirmNo()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378832] When payment's amount is less than the limit to Norges Bank and specification field is empty then NAV asks confirmation during the export (answer = No)
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount greater than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Mock empty Specification (Norges Bank) field
        ResetJnlLineEmptySpecification(GenJournalLine);

        // [WHEN] Payment is being exported and answer No on the confirmation
        asserterror RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, MissedSpecWarningTxt, false);

        // [THEN] Export is cancelled and journal line still present
        Assert.RecordIsNotEmpty(GenJournalLine);
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndFilledSpec()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378832] When payment's amount is less than the limit to Norges Bank and specification field is filled then NAV doesn't show confirmation during the export
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount less than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Specification (Norges Bank) field is filled in
        GenJournalLine.TestField("Specification (Norges Bank)");

        // [WHEN] Payment is being exported
        RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, '', false);

        // [THEN] Export finished successfully without confirmation dialog, Gen. Journal Batch is cleared after export
        // Test is executed without confirmation handler
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWhenLimitIsZero()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378832] When PurchSetup."Amt. Spec limit to Norges Bank" = 0 then NAV doesn't show confirmation during the export
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" = 0
        SetAmountSpecLimit(0);

        // [GIVEN] Payment journal line with some amount
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, LibraryRandom.RandDec(100, 2));

        // [WHEN] Payment is being exported
        RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, '', false);

        // [THEN] Export finished successfully without confirmation dialog, Gen. Journal Batch is cleared after export
        // Test is executed without confirmation handler
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ConfirmHandlerForExportPayment,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndEmptyPaymentTypeCodeAbroadConfirmYes()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379716] When payment's amount is less than the limit to Norges Bank and payment type code abroad field is empty then NAV asks confirmation during the export (answer = Yes)
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount greater than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Empty Payment Type Code Abroad field
        ResetJnlLineEmptyPaymentTypeCodeAbroad(GenJournalLine);

        // [WHEN] Payment is being exported
        RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, MissedPaymentTypeCodeAbroadWarningTxt, true);

        // [THEN] Confirmation dialog appeared "It is not required to fill in Payment Type Code Abroad..."
        // Verification is inside the ConfirmHandlerForExportPaymentYes
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,ConfirmHandlerForExportPayment,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndEmptyPaymentTypeCodeAbroadConfirmNo()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379716] When payment's amount is less than the limit to Norges Bank and payment type code abroad field is empty then NAV asks confirmation during the export (answer = No)
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount greater than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Empty Payment Type Code Abroad field
        ResetJnlLineEmptyPaymentTypeCodeAbroad(GenJournalLine);

        // [WHEN] Payment is being exported and answer No on the confirmation
        asserterror RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, MissedPaymentTypeCodeAbroadWarningTxt, false);

        // [THEN] Export is cancelled and journal line still present
        Assert.RecordIsNotEmpty(GenJournalLine);
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAmountLessThanLimitAndFilledPaymentTypeCodeAbroad()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GenJournalLine: Record "Gen. Journal Line";
        LimitAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379716] When payment's amount is less than the limit to Norges Bank and payment type code abroad field is filled then NAV doesn't show confirmation during the export
        Initialize();

        // [GIVEN] PurchSetup."Amt. Spec limit to Norges Bank" has some value "LimitAmount"
        LimitAmount := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        SetAmountSpecLimit(LimitAmount);

        // [GIVEN] Payment journal line with amount less than "LimitAmount"
        PreparePaymentJnlLine(RemittanceAgreement, RemittanceAccount, GenJournalLine, Round(LimitAmount / 2));
        // [GIVEN] Payment Type Code Abroad field is filled in
        GenJournalLine.TestField("Payment Type Code Abroad");

        // [WHEN] Payment is being exported
        RunPaymentExport(GenJournalLine, RemittanceAgreement.Code, '', false);

        // [THEN] Export finished successfully without confirmation dialog, Gen. Journal Batch is cleared after export
        // Test is executed without confirmation handler
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceExportBankHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentsWithExternalDocNoSingleHeaderInExportFile()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RemittanceExportBank: Report "Remittance - export (bank)";
        InvoicesCount: Integer;
        HeaderSequenceLineNo: Integer;
        FileName: Text;
        RemittanceAgreementCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Remittance Payments] [Remittance - export (bank)]
        // [SCENARIO 234988] When Remittance - export (bank) is run for suggested Remittance Payment Lines with External Doc No <> '', then only one header exists in export file.
        Initialize();

        InvoicesCount := 9;        // Max count of unstructured payments per transaction = 8
        HeaderSequenceLineNo := 8; // line No with header sequence '600F'
        FileName := FileMgt.ServerTempFileName('txt');

        // [GIVEN] Suggested Remittance Payments for 9 Purchase Invoices, each with "External Document No." <> ''
        RemittanceAgreementCode := CreateRemittanceAgreementWithExportFile(FileName);
        VendorNo := CreateVendorWithRemittance(RemittanceAgreementCode);
        PostInvoicesWithExternalDocNo(VendorNo, InvoicesCount);
        InitPaymentJnlLine(GenJournalLine);
        Commit();
        RunSuggestRemittancePayments(GenJournalLine, VendorNo, GetRemittanceAccountCodeForVendorNo(VendorNo));

        // [WHEN] Remittance - export (bank) is run
        FindPaymentJnlLine(GenJournalLine, VendorNo);
        RemittanceExportBank.SetJournalLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(RemittanceAgreementCode);
        LibraryVariableStorage.Enqueue(FileName);
        RemittanceExportBank.Run();

        // [THEN] Exactly one header exists in export file
        VerifyRemittanceExportFileExactlyOneHeaderExists(FileName, HeaderSequenceLineNo, InvoicesCount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstrPrtyInXmlIsHighWhenUrgent()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        // [SCENARIO 381523] The <InstrPrty> is "HIGH" in SEPA Credit Transfer XML if Urgent is True in General Journal Line

        Initialize();
        // [GIVEN] "Urgent" is True in General Journal Line
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate(Urgent, true);
        GenJnlLine.Modify(true);
        TempBlob.CreateOutStream(OutStr);

        // [WHEN] Export Gen. Journal Line with SEPA Credit Transfer XML port
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);
        TempBlob.CreateInStream(InStr);

        // [THEN] The <InstrPrty> is "HIGH" if Urgent is True in General Journal Line
        VerifyInstrPrty(TempBlob, 'HIGH');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstrPrtyInXmlIsNormWhenNotUrgent()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        // [SCENARIO 381523] The <InstrPrty> is "NORM" in SEPA Credit Transfer XML if Urgent is False in General Journal Line

        Initialize();
        // [GIVEN] "Urgent" is False in General Journal Line
        CreateGenJnlLine(GenJnlLine);
        GenJnlLine.Validate(Urgent, false);
        GenJnlLine.Modify(true);
        TempBlob.CreateOutStream(OutStr);

        // [WHEN] Export Gen. Journal Line with SEPA Credit Transfer XML port
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJnlLine);
        TempBlob.CreateInStream(InStr);

        // [THEN] The <InstrPrty> is "NORM" if Urgent is false in General Journal Line
        VerifyInstrPrty(TempBlob, 'NORM');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SEPAIntstructionPriorityIsHighIfUrgentIsTrue()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381523] "SEPA Instruction Priority" is High if Urgent is True in Payment Export Data

        PaymentExportData.Init();
        PaymentExportData.Validate(Urgent, true);
        PaymentExportData.TestField("SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::HIGH);
        PaymentExportData.TestField("SEPA Instruction Priority Text", 'HIGH');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SEPAIntstructionPriorityIsNormalIfUrgentIsFalse()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381523] "SEPA Instruction Priority" is Normal if Urgent is False in Payment Export Data

        PaymentExportData.Init();
        PaymentExportData.Validate(Urgent, false);
        PaymentExportData.TestField("SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::NORMAL);
        PaymentExportData.TestField("SEPA Instruction Priority Text", 'NORM');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentExportForeignRefAbroad()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TempBlob: Codeunit "Temp Blob";
        NodeList: DotNet XmlNodeList;
        OutStr: OutStream;
    begin
        // [SCENARIO 217316] "Schema Name" tag is not filled with "Ref. Aboard" value of Remittance Account when export payment
        Initialize();

        // [GIVEN] Gen. Journal Line with "Recipient Ref. Abroad" = "ACC"
        CreateGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Recipient Ref. Abroad", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        // [WHEN] Export the line to SEPA CT file
        TempBlob.CreateOutStream(OutStr);
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        XMLPORT.Export(BankAccount.GetPaymentExportXMLPortID(), OutStr, GenJournalLine);

        // [THEN] Xml contains tag "//SchmeNm" is empty and contains subtag <Cd> with "BANK" value
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList(SchemaNameTok, NodeList);
        Assert.AreEqual('BANK', NodeList.Item(0).InnerText, WrongSchmeNmErr);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentsWithoutCrMemos()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RemittanceAgreementCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Remittance Payments]
        // [SCENARIO 234989] Posted CrMemo, run Suggest Remmitance Payments. Cr Memo shouldn't suggested.
        Initialize();

        // [GIVEN] Suggested Remittance Payments for Credit Memo
        RemittanceAgreementCode := CreateRemittanceAgreementWithExportFile(FileMgt.ServerTempFileName('txt'));
        VendorNo := CreateVendorWithRemittance(RemittanceAgreementCode);
        PostCrMemoWithExternalDocNo(VendorNo);
        InitPaymentJnlLine(GenJournalLine);
        Commit();

        // [WHEN] Suggest Remmitance Payments is run
        RunSuggestRemittancePayments(GenJournalLine, VendorNo, GetRemittanceAccountCodeForVendorNo(VendorNo));

        // [THEN] There are no Gen. Journal Line that was suggested
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();
        LibraryERMCountryData.UpdateLocalData();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        isInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure ExecuteAndVerifyRemittanceExportPaymentFile(RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; Vendor: Record Vendor; GenJournalLine: Record "Gen. Journal Line"; BatchName: Code[10]) FileName: Text
    var
        LastPaymentOrderID: Integer;
    begin
        // Setup
        LastPaymentOrderID := LibraryRemittance.GetLastPaymentOrderID();

        FileName := LibraryRemittance.ExecuteRemittanceExportPaymentFile(LibraryVariableStorage,
            RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, BatchName);
        VerifyRemittanceExport(LastPaymentOrderID, GenJournalLine);
        exit(FileName);
    end;

    local procedure UpdateDimensionOnGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);
    end;

    local procedure InitPaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentJnlBatchWithBankAccount(GenJournalBatch);
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
    end;

    local procedure FindPaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
    end;

    local procedure CreateRemittanceAgreementWithExportFile(FileName: Text): Code[10]
    var
        RemittanceAgreement: Record "Remittance Agreement";
    begin
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::"Other bank");
        RemittanceAgreement.Validate(
          "Payment File Name", CopyStr(FileName, 1, MaxStrLen(RemittanceAgreement."Payment File Name")));
        RemittanceAgreement.Modify(true);
        exit(RemittanceAgreement.Code);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GenJournalLine.DeleteAll();
        CreateGenJournalBatchWithTemplate(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandIntInRange(10, 100));
        GenJournalLine.Validate("Recipient Bank Account", CreateVendorBankAccountWithIBAN(GenJournalLine."Account No."));
        GenJournalLine.Validate("Currency Code", GeneralLedgerSetup.GetCurrencyCode('EUR')); // "Currency Code" have to equal 'EUR' according of checking "Gen. Journal Line" in codeunit 1223 "SEPA CT-Check Line"
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccountWithExportImportSetup());
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentJnlBatchWithBankAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateVendorWithRemittance(RemittanceAgreementCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        RemittanceAccount: Record "Remittance Account";
    begin
        LibraryRemittance.CreateDomesticRemittanceAccount(RemittanceAgreementCode, RemittanceAccount);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Remittance, true);
        Vendor.Validate("Remittance Account Code", RemittanceAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccountWithIBAN(VendorNo: Code[20]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(IBAN), DATABASE::"Vendor Bank Account");
        VendorBankAccount.Modify();
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateBankAccountWithExportImportSetup(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryUtility.FillFieldMaxText(BankAccount, BankAccount.FieldNo("Bank Account No."));
        BankAccount.Get(BankAccount."No.");
        BankAccount.IBAN := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account");
        BankAccount."Credit Transfer Msg. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        BankAccount."Payment Export Format" := CreateBankExportImportSetup();
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankExportImportSetup(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"SEPA CT-Export File";
        BankExportImportSetup."Processing XMLport ID" := XMLPORT::"SEPA CT pain.001.001.09";
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateRemittancePaymentOrder(var Amount: array[4] of Decimal; var Reference: array[4] of Integer; LinesCnt: Integer)
    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        State: Option Sent,Approved,Settled,Rejected;
        i: Integer;
        j: Integer;
    begin
        RemittancePaymentOrder.Init();
        RemittancePaymentOrder.ID := LibraryUtility.GetNewRecNo(RemittancePaymentOrder, RemittancePaymentOrder.FieldNo(ID));
        RemittancePaymentOrder.Insert();
        for i := State::Sent to State::Rejected do
            for j := 1 to LinesCnt do
                InsertWaitingJournalLine(Amount[i + 1], Reference[i + 1], RemittancePaymentOrder.ID, i);
    end;

    local procedure RunSuggestRemittancePayments(GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; RemittanceAccountCode: Code[10])
    var
        SuggestRemittancePayments: Report "Suggest Remittance Payments";
    begin
        LibraryVariableStorage.Enqueue(RemittanceAccountCode);
        LibraryVariableStorage.Enqueue(VendorNo);
        SuggestRemittancePayments.SetGenJnlLine(GenJournalLine);
        SuggestRemittancePayments.RunModal();
    end;

    local procedure GetRemittanceAccountCodeForVendorNo(VendorNo: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(Vendor."Remittance Account Code");
    end;

    local procedure VerifyRemittanceExport(LastPaymentOrderID: Integer; GenJournalLine: Record "Gen. Journal Line")
    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        WaitingJournal: Record "Waiting Journal";
    begin
        // Remittance Exporting creates an entry in the Remittance Payment Order table.
        // with information about the export (type, date, comment).
        Assert.AreEqual(LastPaymentOrderID + 1, LibraryRemittance.GetLastPaymentOrderID(), 'Payment Order not created');

        Assert.IsTrue(RemittancePaymentOrder.Get(LastPaymentOrderID + 1), 'Payment Order not found.');
        Assert.AreEqual(RemittancePaymentOrder.Type::Export, RemittancePaymentOrder.Type, 'Wrong Payment Order Type');
        // Assert.AreEqual(TODAY,RemittancePaymentOrder.Date,'Wrong date.');
        Assert.IsFalse(RemittancePaymentOrder.Canceled, 'Payment Order is canceled');

        // The exported file must be equal to corresponding lines in
        // PaymentOrderData
        VerifyCorrespondenceToPaymentOrderData(RemittancePaymentOrder.ID);

        VerifyFileLinesAgainstCRLF(RemittancePaymentOrder.ID);

        // Check the payment lines are moved to Waiting Journal
        WaitingJournal.SetRange("Payment Order ID - Sent", RemittancePaymentOrder.ID);
        Assert.AreEqual(1, WaitingJournal.Count, 'Invalid number of lines in Waiting Journal');
        Assert.IsTrue(WaitingJournal.FindFirst(), 'Waiting Journal Record not found');
        Assert.AreEqual(WaitingJournal."Remittance Status"::Sent, WaitingJournal."Remittance Status", 'Remittance Status incorrect');
        Assert.AreEqual(GenJournalLine."Remittance Agreement Code", WaitingJournal."Remittance Agreement Code",
          'Wrong Remittance Agreement Code');
        Assert.AreEqual(GenJournalLine.Amount, WaitingJournal.Amount, 'Waiting Journal amount differ from payment');
    end;

    local procedure VerifyBankExportFileWithSinglePayment(RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account")
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        ExportFile: File;
        Ins: InStream;
        OperatorNo: Text[11];
        Division: Text[11];
        OwnAccountNo: Text[11];
        GlobalNo: Integer;
        DailyNo: Integer;
        CountTrans: Integer;
        ServerFileName: Text;
    begin
        LibraryRemittance.GetGenJournalLinesFromWaitingJournal(LibraryRemittance.GetLastPaymentOrderID(), TempGenJournalLine);

        GetInStreamWithoutCRNL(Ins, ExportFile);

        DailyNo := RemittanceAgreement."Latest Daily Sequence No.";
        GlobalNo := RemittanceAgreement."Latest Sequence No.";

        // BetFor00
        CountTrans += 1;
        VerifyApplicationHeader(Ins, RemittanceAccount.Type, DailyNo);

        Assert.IsTrue(RemittanceAgreement.Get(RemittanceAccount."Remittance Agreement Code"), 'Agreement not found.');

        if RemittanceAgreement."Payment System" = RemittanceAgreement."Payment System"::"DnB Telebank" then
            OperatorNo := CopyStr(FormatNumStr(RemittanceAgreement."Operator No.", 11), 1, 11)
        else
            OperatorNo := PadStr(RemittanceAgreement."Operator No.", 11, ' ');

        if RemittanceAgreement."Payment System" = RemittanceAgreement."Payment System"::"Fokus Bank" then
            Division := CopyStr(FormatNumStr(RemittanceAgreement.Division, 11), 1, 11)
        else
            Division := PadStr(RemittanceAgreement.Division, 11, ' ');

        AssertValue(Ins, 'BETFOR00', 0, 'BETFOR00');
        AssertValue(Ins, RemittanceAgreement."Company/Agreement No.", -11, 'CompanyAgreementNo');
        AssertValue(Ins, Division, 0, 'Division');
        AssertGlobalNo(Ins, GlobalNo);
        AssertFill(Ins, 6);

        // Line 2
        AssertToday(Ins);
        AssertValue(Ins, RemittanceAgreement.Password, 10, 'Password');
        AssertValue(Ins, 'VERSJON002', 0, 'Version');
        AssertFill(Ins, 10);
        AssertValue(Ins, OperatorNo, 11, 'Operator');
        AssertValue(Ins, ' ', 1, 'Sigill Seal-use. Not used.');
        AssertValue(Ins, '0', -6, 'Sigill Seal-date. Not used.');
        AssertValue(Ins, '0', -20, 'Sigill Part-key. Not used.');
        AssertValue(Ins, ' ', 0, 'Sigill how. Not used.');
        AssertFill(Ins, 7);

        // Line 3
        AssertFill(Ins, 80);

        // Line 4
        AssertFill(Ins, 80);

        if RemittanceAccount.Type = RemittanceAccount.Type::"Payment Instr." then
            OwnAccountNo := '00000000000'
        else
            OwnAccountNo := CopyStr(FormatNumStr(RemittanceAccount."Bank Account No.", 11), 1, 11);

        if RemittanceAccount.Type = RemittanceAccount.Type::Domestic then begin
            // BetFor21
            CountTrans += 1;
            VerifyBetFor21(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);

            // BetFor23
            CountTrans += 1;
            VerifyBetFor23(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);
        end else begin
            CountTrans += 4;
            // BetFor01
            VerifyBetFor01(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);

            // BetFor02
            VerifyBetFor02(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);

            // BetFor03
            VerifyBetFor03(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);

            // BetFor04
            VerifyBetFor04(Ins, RemittanceAgreement, RemittanceAccount, OwnAccountNo, TempGenJournalLine, DailyNo, GlobalNo);
        end;

        // BetFor99
        CountTrans += 1;
        VerifyBetFor99(Ins, RemittanceAgreement, RemittanceAccount, DailyNo, GlobalNo, CountTrans);

        Assert.IsTrue(Ins.EOS, 'Not end of stream');

        ServerFileName := ExportFile.Name;
        ExportFile.Close();
        FileMgt.DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyBetFor21(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Vendor: Record Vendor;
        RecipientAccountNo: Text[11];
        TextCode: Text[3];
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR21', DailyNo, GlobalNo);

        if Vendor."Recipient Bank Account No." = '' then
            RecipientAccountNo := '00000000019' // Use 19 if none specified
        else
            RecipientAccountNo := CopyStr(FormatNumStr(Vendor."Recipient Bank Account No.", 11), 1, 11);

        // The implementation does a big switch on "BOLS Text Code" but ends up
        // with this. Bug in implementation??
        if GenJournalLine.KID <> '' then
            TextCode := '601'
        else
            if GenJournalLine."External Document No." <> '' then
                TextCode := '600'
            else
                TextCode := '602';

        AssertValue(Ins, FormatDateYYMMDD(WorkDate()), 0, 'DueDate');
        AssertValue(Ins, GenJournalLine."Account No.", 30, 'Account No');
        AssertValue(Ins, ' ', 0, 'Reserved');
        AssertValue(Ins, RecipientAccountNo, 0, 'Recipient Account No');
        AssertValue(Ins, Vendor.Name, 30, 'Recipient Name');
        AssertValue(Ins, Vendor.Address, 30, 'Recipient Address');
        AssertValue(Ins, Vendor."Address 2", 30, 'Recipient Address 2');
        AssertValue(Ins, Vendor."Post Code", 4, 'Recipient Post Code');
        AssertValue(Ins, Vendor.City, 26, 'Recipient City');
        AssertValue(Ins, '0', -15, 'Amount to own account. Not supported.');
        AssertValue(Ins, TextCode, 0, 'BOLS');
        AssertValue(Ins, 'F', 1, 'Transaction Type. Only invoice supported.');
        AssertValue(Ins, ' ', 1, 'Deleting. Set =''D'' if transaction was previously deleting.');
        AssertValue(Ins, '0', -15, 'Total amount. Only settled return R2.');
        AssertValue(Ins, '0', -5, 'Reserved');
        AssertFill(Ins, 6);
        AssertFill(Ins, 6);
        AssertFill(Ins, 1);
        AssertFill(Ins, 9);
        AssertFill(Ins, 10);
    end;

    local procedure VerifyBetFor23(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Vendor: Record Vendor;
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR23', DailyNo, GlobalNo);

        if (GenJournalLine.KID = '') and (GenJournalLine."External Document No." = '') then begin
            AssertValue(Ins, GenJournalLine."Recipient Ref. 1", 40, 'Recipient Ref 1');
            AssertValue(Ins, GenJournalLine."Recipient Ref. 2", 40, 'Recipient Ref 2');
            AssertValue(Ins, GenJournalLine."Recipient Ref. 3", 40, 'Recipient Ref 3');
            AssertFill(Ins, 27);
        end else begin
            AssertFill(Ins, 40 * 3);
            AssertValue(Ins, GenJournalLine.KID, 27, 'KID');
        end;
        AssertValue(Ins, Format(LibraryRemittance.GetLastPaymentOrderID()), 30, 'Own ref. Waiting Journal Ref');
        AssertValue(Ins, FormatDecStr(GenJournalLine."Amount (LCY)", 15), 0, 'Amount (LCY)');
        if GenJournalLine."Amount (LCY)" < 0 then
            AssertValue(Ins, 'K', 0, 'Credit Code')
        else
            AssertValue(Ins, 'D', 0, 'Debit code');
        if (GenJournalLine.KID = '') and (GenJournalLine."External Document No." <> '') then
            AssertValue(Ins, GenJournalLine."External Document No.", 20, 'Invoice No')
        else
            AssertFill(Ins, 20);
        AssertValue(Ins, '000', 0, 'Serial No');
        AssertFill(Ins, 1);
        if (GenJournalLine.KID = '') and (GenJournalLine."External Document No." <> '') then begin
            AssertValue(Ins, Vendor."Our Account No.", 15, 'Our account no.');
            AssertValue(Ins, FormatDateYYYYMMDD(WorkDate()), 0, 'InvoiceDate');
        end else begin
            AssertFill(Ins, 15);
            AssertFill(Ins, 8);
        end;
    end;

    local procedure VerifyBetFor01(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        CurrencyCode: Code[3];
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR01', DailyNo, GlobalNo);

        AssertValue(Ins, FormatDateYYMMDD(GenJournalLine."Due Date"), 0, 'Due Date');
        AssertValue(Ins, GenJournalLine."Account No.", 30, 'Own ref payment order');
        CurrencyCode := CopyStr(Skip(Ins, 3), 1, 3);
        if CurrencyCode <> '' then
            Assert.IsTrue(Currency.Get(CurrencyCode), 'Payment Currency not found.');
        CurrencyCode := CopyStr(Skip(Ins, 3), 1, 3);
        if CurrencyCode <> '' then
            Assert.IsTrue(Currency.Get(CurrencyCode), 'Invoice Currency not found.');
        AssertValue(Ins, SelectStr(Vendor."Charges Abroad" + 1, 'OUR,BEN,   '), 0, 'Charges Abroad');
        AssertValue(Ins, SelectStr(Vendor."Charges Domestic" + 1, 'OUR,BEN,   '), 0, 'Charges Domestic');
        Skip(Ins, 30); // Warning.
        Skip(Ins, 1); // Urgent. = Y
        AssertValue(Ins, FormatDecStr(GenJournalLine."Agreed Exch. Rate", 8), 0, 'Agreed Exch Rate');
        AssertValue(Ins, GenJournalLine."Futures Contract No.", 6, 'Futures Contract No');
        AssertValue(Ins, FormatDecStr(GenJournalLine."Futures Contract Exch. Rate", 8), 0, 'Futures Contract Exch. Rate.');
        AssertValue(Ins, SelectStr(GenJournalLine.Check + 1, ' ,0,1'), 0, 'Check');
        AssertFill(Ins, 6);
        AssertFill(Ins, 2);
        AssertValue(Ins, '0', -12, 'Real exchange rate.');
        AssertFill(Ins, 12);
        AssertValue(Ins, '0', -16, 'Debited amount.');
        AssertValue(Ins, '0', -16, 'Transferred amount.');
        AssertFill(Ins, 5); // Client Ref.
        AssertValue(Ins, '0', -6, 'M Execution');
        AssertValue(Ins, GenJournalLine."Agreed With", 6, 'Agreed with');
        AssertValue(Ins, ' ', 0, 'Deleting. not supported.');
        AssertValue(Ins, ' ', 0, 'SBP code.');
        AssertValue(Ins, '0', -6, 'Value date');
        AssertValue(Ins, '0', -9, 'Commision');
        AssertValue(Ins, '0', -12, 'Exchange rate in LCY');
        AssertFill(Ins, 1);
        AssertValue(Ins, '0', -16, 'Skipped');
        AssertFill(Ins, 1); // Price Info
        AssertFill(Ins, 10); // Reserved
    end;

    local procedure VerifyBetFor02(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Vendor: Record Vendor;
        BankCode: Text[15];
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR02', DailyNo, GlobalNo);

        if Vendor."Rcpt. Bank Country/Region Code" in ['AU', 'CA', 'IE', 'GB', 'CH', 'ZA', 'DE', 'US', 'AT'] then
            BankCode := PadStr(Vendor."Recipient Bank Account No.", 15);

        AssertValue(Ins, Vendor.SWIFT, 11, 'SWIFT');

        // The following looks weird, but the test matches what is currently implemented.
        // If BankCode is non-empty we skip name and address 1, but writes out address 2 + 3?
        if BankCode = '' then begin
            AssertValue(Ins, Vendor."Bank Name", 35, 'Bank Name');
            AssertValue(Ins, Vendor."Bank Address 1", 35, 'Bank Address 1');
        end else begin
            AssertFill(Ins, 35);
            AssertFill(Ins, 35);
        end;
        AssertValue(Ins, Vendor."Bank Address 2", 35, 'Bank Address 2');
        AssertValue(Ins, Vendor."Bank Address 3", 35, 'Bank Address 3');
        AssertValue(Ins, Vendor."SWIFT Remb. Bank", 11, 'SWITFT Remb Bank');
        AssertValue(Ins, Vendor."Rcpt. Bank Country/Region Code", 2, 'Bank Country/Region Code');
        AssertValue(Ins, BankCode, 15, 'Bank Code');
        if RemittanceAccount.Type = RemittanceAccount.Type::"Payment Instr." then
            AssertValue(Ins, RemittanceAccount."Bank Account No.", 35, 'Bank Account No')
        else
            AssertFill(Ins, 35);
        AssertFill(Ins, 26);
    end;

    local procedure VerifyBetFor03(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Vendor: Record Vendor;
        Recipient: array[4] of Text[35];
        i: Integer;
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR03', DailyNo, GlobalNo);

        Recipient[1] := CopyStr(Vendor.Name, 1, 35);
        Recipient[2] := CopyStr(Vendor.Address, 1, 35);
        Recipient[3] := CopyStr(Vendor."Address 2", 1, 35);
        Recipient[4] := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
        CompressArray(Recipient);

        AssertValue(Ins, Vendor."Recipient Bank Account No.", 35, 'Recip Bank Account');
        for i := 1 to 4 do
            AssertValue(Ins, UpperCase(Recipient[i]), 35, 'Address ' + Format(i));
        AssertValue(Ins, Vendor."Country/Region Code", 2, 'Country/Region');
        AssertValue(Ins, SelectStr(Vendor."Recipient Confirmation" + 1, ' ,T,F'), 1, 'Recip Confirmation');
        AssertValue(Ins, Vendor."Telex Country/Region Code", 2, 'Telex Country/Region');
        AssertValue(Ins, Vendor."Telex/Fax No.", 18, 'Telex/Fax No.');
        AssertValue(Ins, Vendor."Recipient Contact", 20, 'Recip Contact');
        AssertFill(Ins, 22);
    end;

    local procedure VerifyBetFor04(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; OwnAccountNo: Text[11]; GenJournalLine: Record "Gen. Journal Line"; var DailyNo: Integer; var GlobalNo: Integer)
    var
        Vendor: Record Vendor;
        RecipientRef: Text[35];
    begin
        Assert.IsTrue(Vendor.Get(GenJournalLine."Account No."), 'Vendor not found.');

        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          OwnAccountNo, 'BETFOR04', DailyNo, GlobalNo);

        if GenJournalLine.KID <> '' then
            RecipientRef := GenJournalLine.KID
        else
            if GenJournalLine."External Document No." <> '' then
                RecipientRef := GenJournalLine."External Document No."
            else
                RecipientRef := GenJournalLine."Recipient Ref. Abroad";

        AssertValue(Ins, RecipientRef, 35, 'Recipient Ref');
        AssertValue(Ins, Format(LibraryRemittance.GetLastPaymentOrderID()), 35, 'OwnRef');
        AssertValue(Ins, FormatDecStr(GenJournalLine.Amount, 15), 0, 'Amount');
        AssertBoolean(Ins, GenJournalLine.Amount < 0, 'K', 'D', 'DebitCredit code');
        AssertValue(Ins, GenJournalLine."Payment Type Code Abroad", 6, 'Payment Type Abroad');
        AssertValue(Ins, GenJournalLine."Specification (Norges Bank)", 60, 'Spec Norges Bank');
        AssertBoolean(Ins, Vendor."To Own Account", 'Y', ' ', 'To Own Account');
        AssertFill(Ins, 1);
        AssertValue(Ins, '0', -6, 'Reserved');
        AssertFill(Ins, 1);
        AssertValue(Ins, '0', -6, 'Reserved');
        AssertFill(Ins, 45);
        AssertBoolean(Ins, GenJournalLine.KID <> '', 'K', ' ', 'KID Foreign');
        AssertValue(Ins, '000', 0, 'Reserved');
        AssertFill(Ins, 24);
    end;

    local procedure VerifyBetFor99(Ins: InStream; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; var DailyNo: Integer; var GlobalNo: Integer; CountTrans: Integer)
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        VerifyBetForHeader(Ins, RemittanceAccount.Type, RemittanceAgreement."Company/Agreement No.",
          PadStr('', 11, ' '), 'BETFOR99', DailyNo, GlobalNo);
        AssertToday(Ins); // Production Date
        AssertFill(Ins, 19); // Reserved
        AssertValue(Ins, Format(CountTrans), -5, 'Number of transactions');
        AssertFill(Ins, 163);
        AssertFill(Ins, 4 + 1 + 1 + 1 + 18); // Sigill - not used.
        AssertValue(Ins, UpperCase(PadStr('Nav ' + ApplicationSystemConstants.ApplicationVersion(), 11)), 16, 'Application Version');
        AssertFill(Ins, 8);
        if RemittanceAgreement."Payment System" = RemittanceAgreement."Payment System"::"DnB Telebank" then
            AssertFill(Ins, 80);
    end;

    local procedure VerifyApplicationHeader(Ins: InStream; Type: Option Domestic,Foreign,"Payment Instr."; var DailyNo: Integer)
    begin
        // Appl Header
        AssertValue(Ins, 'AH', 0, 'ID');
        AssertValue(Ins, '2', 0, 'Version');
        AssertValue(Ins, '00', 0, 'Return Code');
        if Type = Type::Domestic then
            AssertValue(Ins, 'TBII', 0, 'Routine ID')
        else
            AssertValue(Ins, 'TBIU', 0, 'Routine ID');
        AssertToday(Ins);
        AssertDailyNo(Ins, DailyNo);
        AssertFill(Ins, 8); // Trans. Code - reserved
        AssertFill(Ins, 11); // UserID - Reserved
        AssertValue(Ins, '04', 0, 'Number');
    end;

    local procedure VerifyBetForHeader(Ins: InStream; Type: Option Domestic,Foreign,"Payment Instr."; CompanyAgreementNo: Text[11]; OwnAccountNo: Text[11]; BetFor: Text[8]; var DailyNo: Integer; var GlobalNo: Integer)
    begin
        VerifyApplicationHeader(Ins, Type, DailyNo);

        AssertValue(Ins, BetFor, 0, BetFor);
        AssertValue(Ins, CompanyAgreementNo, -11, 'CompanyAgreementNo');
        AssertValue(Ins, OwnAccountNo, 0, 'Own Account No');
        AssertGlobalNo(Ins, GlobalNo);
        AssertFill(Ins, 6);
    end;

    local procedure VerifyBBSExportFileWithSinglePayment(RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; PaymentOrderID: Integer)
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        Vendor: Record Vendor;
        ExportFile: File;
        Ins: InStream;
        TransType: Code[2];
        PaymentOrderNoOfTrans: Integer;
        PaymentOrderNoOfRec: Integer;
        TransNo: Integer;
        BBSPaymentOrderNo: Integer;
        NextRecordType: Code[8];
        ShipNoOfTrans: Integer;
        ShipNoOfRec: Integer;
        ServerFileName: Text;
    begin
        // This method only verifies a BBS file with a single payment.
        PaymentOrderNoOfTrans := 0;
        PaymentOrderNoOfRec := 0;
        TransNo := 1;

        BBSPaymentOrderNo := RemittanceAgreement."Latest BBS Payment Order No.";
        LibraryRemittance.GetGenJournalLinesFromWaitingJournal(PaymentOrderID, TempGenJournalLine);

        GetInStreamWithoutCRNL(Ins, ExportFile);

        VerifyRecordType10(Ins, PaymentOrderID, RemittanceAgreement, ShipNoOfTrans, ShipNoOfRec);
        VerifyRecordType20(Ins, RemittanceAccount, BBSPaymentOrderNo, PaymentOrderNoOfTrans, PaymentOrderNoOfRec, ShipNoOfRec);

        if TempGenJournalLine.KID = '' then
            TransType := '03' // Transfer with notice to beneficiary
        else
            TransType := '16'; // transfer with KID and bottom specification to beneficiary
        Vendor.Get(TempGenJournalLine."Account No.");

        VerifyRecordType30(Ins, TempGenJournalLine, Vendor, TransType, TransNo,
          PaymentOrderNoOfTrans, PaymentOrderNoOfRec, ShipNoOfTrans, ShipNoOfRec);
        VerifyRecordType31(Ins, Vendor, TransType, TransNo, PaymentOrderNoOfRec, ShipNoOfRec);

        if TempGenJournalLine.KID = '' then begin
            VerifyRecordType40(Ins, Vendor, TransNo, PaymentOrderNoOfRec, ShipNoOfRec);
            VerifyRecordType41(Ins, Vendor, TransNo, PaymentOrderNoOfRec, ShipNoOfRec);
        end;

        NextRecordType := CopyStr(Skip(Ins, 8), 1, 8);
        if TempGenJournalLine.KID = '' then
            VerifyRecordType49(Ins, NextRecordType, TransNo, PaymentOrderNoOfRec, ShipNoOfRec)
        else
            VerifyRecordType50(Ins, NextRecordType, TempGenJournalLine, TransNo, PaymentOrderNoOfRec, ShipNoOfRec);

        VerifyRecordType88(Ins, NextRecordType, TempGenJournalLine, PaymentOrderNoOfTrans, PaymentOrderNoOfRec, ShipNoOfRec);
        VerifyRecordType89(Ins, TempGenJournalLine, ShipNoOfTrans, ShipNoOfRec);

        Assert.IsTrue(Ins.EOS, 'Not end of stream');

        ServerFileName := ExportFile.Name;
        ExportFile.Close();
        FileMgt.DeleteServerFile(ServerFileName);
    end;

    local procedure PostCrMemoWithExternalDocNo(VendorNo: Code[20]);
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreatePaymentJnlBatchWithBankAccount(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyRecordType10(Ins: InStream; PaymentOrderID: Integer; RemittanceAgreement: Record "Remittance Agreement"; var ShipNoOfTrans: Integer; var ShipNoOfRec: Integer)
    begin
        ShipNoOfTrans := 0;
        ShipNoOfRec := 1;
        AssertValue(Ins, 'NY000010', 0, 'NY000010');
        AssertValue(Ins, RemittanceAgreement."BBS Customer Unit ID", -8, 'BBS Customer Unit ID');
        AssertValue(Ins, Format(PaymentOrderID), -7, 'PaymentOrderID');
        AssertValue(Ins, '00008080', 0, 'Magic');
        AssertFill0(Ins, 49);
    end;

    local procedure VerifyRecordType20(Ins: InStream; RemittanceAccount: Record "Remittance Account"; var BBSPaymentOrderNo: Integer; var PaymentOrderNoOfTrans: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        PaymentOrderNoOfTrans := 0;
        PaymentOrderNoOfRec := 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, 'NY040020', 0, 'NY040020');
        AssertValue(Ins, RemittanceAccount."BBS Agreement ID", -9, 'BBS Agreement ID');
        BBSPaymentOrderNo += 1;
        AssertValue(Ins, Format(BBSPaymentOrderNo), -7, 'BBSPaymentOrderNo');
        AssertValue(Ins, RemoveNonNumericChars(RemittanceAccount."Bank Account No."), 0, 'BankAccountNo');
        AssertFill0(Ins, 45);
    end;

    local procedure VerifyRecordType30(Ins: InStream; var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; TransType: Code[2]; var TransNo: Integer; var PaymentOrderNoOfTrans: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfTrans: Integer; var ShipNoOfRec: Integer)
    begin
        AssertValue(Ins, 'NY04', 0, 'NY04');
        AssertValue(Ins, TransType, 0, 'TransType');
        AssertValue(Ins, '30', 0, '30');
        TransNo += 1;
        PaymentOrderNoOfTrans += 1;
        PaymentOrderNoOfRec += 1;
        ShipNoOfTrans += 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(TransNo), -7, 'TransNo');
        AssertValue(Ins, FormatDateDDMMYY(GenJournalLine."Posting Date"), 0, 'Due Date');
        AssertValue(Ins, Vendor."Recipient Bank Account No.", -11, 'CreditAccount');
        AssertValue(Ins, FormatDecStr(GenJournalLine."Amount (LCY)", 17), 0, 'SumAmount'); // Sum of all amount. Assuming only one line in export.
        AssertFill(Ins, 25);
        AssertFill0(Ins, 6);
    end;

    local procedure VerifyRecordType31(Ins: InStream; Vendor: Record Vendor; TransType: Code[2]; TransNo: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        AssertValue(Ins, 'NY04', 0, 'NY04');
        AssertValue(Ins, TransType, 0, 'TransType');
        AssertValue(Ins, '31', 0, '31');
        PaymentOrderNoOfRec += 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(TransNo), -7, 'TransNo');
        AssertValue(Ins, Vendor.Name, 10, 'ShortName');
        AssertValue(Ins, Format(LibraryRemittance.GetLastPaymentOrderID()), -25, 'BBSOwnRef');
        AssertFill(Ins, 25);
        AssertFill0(Ins, 5);
    end;

    local procedure VerifyRecordType40(Ins: InStream; Vendor: Record Vendor; TransNo: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        AssertValue(Ins, 'NY040340', 0, 'NY040340');
        PaymentOrderNoOfRec += 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(TransNo), -7, 'TransNo');
        AssertValue(Ins, Vendor.Name, 30, 'Name');
        AssertValue(Ins, Vendor."Post Code", 4, 'PostNo');
        AssertFill(Ins, 3);
        AssertValue(Ins, Vendor.City, 25, 'Place');
        AssertFill0(Ins, 3);
    end;

    local procedure VerifyRecordType41(Ins: InStream; Vendor: Record Vendor; TransNo: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        AssertValue(Ins, 'NY040341', 0, 'NY040341');
        PaymentOrderNoOfRec += 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(TransNo), -7, 'TransNo');
        AssertValue(Ins, Vendor.Address, 30, 'Address');
        AssertValue(Ins, Vendor."Address 2", 30, 'Address 2');
        AssertFill(Ins, 3); // CountryRegion. Potentially a bug. always blank.
        AssertFill0(Ins, 2);
    end;

    local procedure VerifyRecordType49(Ins: InStream; var RecordType: Code[8]; TransNo: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        while RecordType = 'NY040349' do begin
            PaymentOrderNoOfRec += 1;
            ShipNoOfRec += 1;
            AssertValue(Ins, Format(TransNo), -7, 'TransNo');
            Skip(Ins, 3); // MessageLineNo.
            Skip(Ins, 1); // 1 or 2
            Skip(Ins, 40); // Recipient Ref.
            AssertFill(Ins, 21);
            RecordType := CopyStr(Skip(Ins, 8), 1, 8);
        end;
    end;

    local procedure VerifyRecordType50(Ins: InStream; var RecordType: Code[8]; var GenJournalLine: Record "Gen. Journal Line"; TransNo: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    var
        UnderSpecTransType: Code[2];
    begin
        PaymentOrderNoOfRec += 1;
        ShipNoOfRec += 1;

        if GenJournalLine.Amount < 0 then // Credit memo payment
            UnderSpecTransType := '17'
        else
            UnderSpecTransType := '16';

        Assert.AreEqual(RecordType, 'NY04' + UnderSpecTransType + '50', 'NY04' + UnderSpecTransType + '50');
        AssertValue(Ins, Format(TransNo), -7, 'TransNo');
        AssertValue(Ins, PadStr('', 25 - StrLen(GenJournalLine.KID)) + GenJournalLine.KID, 0, 'KID');
        AssertValue(Ins, FormatDecStr(GenJournalLine.Amount, 17), 0, 'Amount');
        AssertFill0(Ins, 23);

        RecordType := CopyStr(Skip(Ins, 8), 1, 8);
    end;

    local procedure VerifyRecordType88(Ins: InStream; RecordType: Code[8]; var TempGenJournalLine: Record "Gen. Journal Line" temporary; PaymentOrderNoOfTrans: Integer; var PaymentOrderNoOfRec: Integer; var ShipNoOfRec: Integer)
    begin
        Assert.AreEqual(RecordType, 'NY040088', 'NY040088');
        PaymentOrderNoOfRec += 1;
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(PaymentOrderNoOfTrans), -8, 'PaymentOrderNoOfTrans');
        AssertValue(Ins, Format(PaymentOrderNoOfRec), -8, 'PaymentOrderNoOfRec');
        AssertValue(Ins, FormatDecStr(TempGenJournalLine."Amount (LCY)", 17), 0, 'PaymOrderAmount');
        AssertValue(Ins, FormatDateDDMMYY(TempGenJournalLine."Posting Date"), 0, 'FirstPaymentDate');
        AssertValue(Ins, FormatDateDDMMYY(TempGenJournalLine."Posting Date"), 0, 'LastPaymentDate');
        AssertFill0(Ins, 27);
    end;

    local procedure VerifyRecordType89(Ins: InStream; var TempGenJournalLine: Record "Gen. Journal Line" temporary; ShipNoOfTrans: Integer; var ShipNoOfRec: Integer)
    begin
        AssertValue(Ins, 'NY040089', 0, 'NY040089');
        ShipNoOfRec += 1;
        AssertValue(Ins, Format(ShipNoOfTrans), -8, 'ShipNoOfTrans');
        AssertValue(Ins, Format(ShipNoOfRec), -8, 'ShipNoOfRec');
        AssertValue(Ins, FormatDecStr(TempGenJournalLine."Amount (LCY)", 17), 0, 'SumAmount');
        AssertValue(Ins, FormatDateDDMMYY(TempGenJournalLine."Posting Date"), 0, 'FirstPayment');
        AssertFill0(Ins, 33);
    end;

    local procedure VerifyCorrespondenceToPaymentOrderData(RemittancePaymentOrderID: Integer)
    var
        PaymentOrderData: Record "Payment Order Data";
        ExportFile: File;
        Ins: InStream;
        String: Text[80];
    begin
        GetInStreamWithoutCRNL(Ins, ExportFile);

        PaymentOrderData.SetRange("Payment Order No.", RemittancePaymentOrderID);
        PaymentOrderData.SetRange("Empty Line", false);
        if PaymentOrderData.FindSet() then
            repeat
                Ins.ReadText(String, MaxStrLen(String));
                Assert.AreEqual(PaymentOrderData.Data, String, LinesDoesntMatchErr);
            until PaymentOrderData.Next() = 0;
        ExportFile.Close();
    end;

    local procedure VerifyFileLinesAgainstCRLF(RemittancePaymentOrderID: Integer)
    var
        PaymentOrderData: Record "Payment Order Data";
        TempFile: File;
        Char: Char;
        ServerFileName: Text;
    begin
        // Verify that each file line separated by carriage return and new line symbols
        TempFile.Open(ServerFileName);

        PaymentOrderData.SetRange("Payment Order No.", RemittancePaymentOrderID);
        PaymentOrderData.SetRange("Empty Line", false);
        if PaymentOrderData.FindSet() then
            repeat
                TempFile.Seek(80); // each line contains 80 symbols
                TempFile.Read(Char);
                AssertChar(13, Char); // carriage return
                TempFile.Read(Char);
                AssertChar(10, Char); // line feed
            until PaymentOrderData.Next() = 0;

        TempFile.Close();
        FileMgt.DeleteServerFile(ServerFileName);
    end;

    local procedure VerifyDimensionOnGeneralJournalLineFromInvoice(BatchName: Code[10]; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.FindLast();
        Assert.AreEqual(DimValue1Code, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(DimValue2Code, GenJournalLine."Shortcut Dimension 2 Code", GenJournalLine.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    local procedure VerifyInstrPrty(var TempBlob: Codeunit "Temp Blob"; ExpectedValue: Text)
    var
        NodeList: DotNet XmlNodeList;
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, NamespaceTxt);
        LibraryXPathXMLReader.GetNodeList('//InstrPrty', NodeList);
        Assert.AreEqual(ExpectedValue, NodeList.Item(0).InnerText, '');
    end;

    local procedure VerifyRemittanceExportFileExactlyOneHeaderExists(FileName: Text; HeaderSequencePos: Integer; RecordsCount: Integer)
    var
        File: File;
        Index: Integer;
        TextLine: Text;
    begin
        File.WriteMode(false);
        File.TextMode(true);
        File.Open(FileName);
        for Index := 1 to HeaderSequencePos - 1 do begin
            File.Read(TextLine);
            Assert.AreNotEqual('600F', CopyStr(TextLine, 24, 4), StrSubstNo(HeaderNotExpectedErr, Index));
        end;

        File.Read(TextLine);
        Assert.AreEqual('600F', CopyStr(TextLine, 24, 4), StrSubstNo(HeaderExpectedErr, HeaderSequencePos));

        for Index := HeaderSequencePos + 1 to HeaderSequencePos + RecordsCount * 4 do begin
            File.Read(TextLine);
            Assert.AreNotEqual('600F', CopyStr(TextLine, 24, 4), StrSubstNo(HeaderNotExpectedErr, Index));
        end;
        File.Close();
    end;

    local procedure AssertChar(ExpectedValue: Integer; Char: Char)
    var
        "Integer": Integer;
    begin
        Integer := Char;
        Assert.AreEqual(ExpectedValue, Integer, IncorrectCharValueErr);
    end;

    local procedure AssertToday(Ins: InStream)
    var
        Month: Integer;
        Date: Integer;
        LocalToday: Date;
        Yesterday: Date;
        Ms: Duration;
        TodayStr: Text[4];
    begin
        // Verify that the String contains MMDD for today.
        // In case we are just after midnight it also accepts Today - 1, since the output
        // could have been written to file immediately before midnight
        Assert.AreEqual(4, Ins.ReadText(TodayStr, 4), 'Buffer underflow');

        Assert.IsTrue(Evaluate(Month, CopyStr(TodayStr, 1, 2)), 'Malformed date');
        Assert.IsTrue(Evaluate(Date, CopyStr(TodayStr, 3, 2)), 'Malformed date');

        LocalToday := Today;

        if (Date = Date2DMY(LocalToday, 1)) and (Month = Date2DMY(LocalToday, 2)) then
            exit;

        // If we are less than 1 second past midnight we will also accept yesterday.
        Yesterday := CalcDate('<-1D>', LocalToday);
        Ms := CreateDateTime(LocalToday, Time) - CreateDateTime(LocalToday, 0T);

        if (Ms < 1000) and (Date = Date2DMY(Yesterday, 1)) and (Month = Date2DMY(Yesterday, 2)) then
            exit;

        Assert.Fail('''' + TodayStr + ''' not accepted as Today (MMDD)');
    end;

    local procedure AssertValue(Ins: InStream; Value: Text[1024]; Length: Integer; Description: Text[1024])
    var
        s: Text[1024];
    begin
        if Length = 0 then
            Length := StrLen(Value)
        else
            if Length > 0 then
                Value := PadStr(Value, Length, ' ')
            else begin
                Value := FormatNumStr(CopyStr(Value, 1, 30), -Length);
                Length := -Length;
            end;

        Assert.AreEqual(Length, Ins.ReadText(s, Length), 'Buffer underflow');
        Assert.AreEqual(Value, s, Description);
    end;

    local procedure AssertDailyNo(Ins: InStream; var DailyNo: Integer)
    begin
        DailyNo += 1;
        AssertValue(Ins, FormatNumStr(Format(DailyNo), 6), 0, 'DailyNo');
    end;

    local procedure AssertGlobalNo(Ins: InStream; var GlobalNo: Integer)
    begin
        GlobalNo += 1;
        AssertValue(Ins, FormatNumStr(Format(GlobalNo), 4), 0, 'GlobalNo');
    end;

    local procedure AssertFill(Ins: InStream; FillCount: Integer)
    begin
        AssertValue(Ins, '', FillCount, 'Fill');
    end;

    local procedure AssertFill0(Ins: InStream; FillCount: Integer)
    begin
        AssertValue(Ins, PadStr('', FillCount, '0'), 0, 'Fill0');
    end;

    local procedure AssertBoolean(Ins: InStream; Value: Boolean; TrueValue: Text[1]; FalseValue: Text[1]; Message: Text[1024])
    var
        ReadValue: Text[1];
    begin
        ReadValue := CopyStr(Skip(Ins, 1), 1, 1);
        if Value then
            Assert.AreEqual(TrueValue, ReadValue, Message)
        else
            Assert.AreEqual(FalseValue, ReadValue, Message);
    end;

    local procedure Skip(Ins: InStream; SkipCount: Integer) result: Text[1024]
    begin
        Assert.AreEqual(SkipCount, Ins.Read(result, SkipCount), 'Buffer underflow');
    end;

    local procedure CompareFiles()
    var
        ExpectedIns: InStream;
        ActualIns: InStream;
        ExpectedRead: Integer;
        ActualRead: Integer;
        ExpectedText: Text[80];
        ActualText: Text[80];
    begin
        repeat
            ExpectedRead := ExpectedIns.Read(ExpectedText, MaxStrLen(ExpectedText));
            ActualRead := ActualIns.Read(ActualText, MaxStrLen(ActualText));
            Assert.AreEqual(ExpectedRead, ActualRead, 'Files doesn''t match');
            Assert.AreEqual(ExpectedText, ActualText, 'Files doesn''t match');
        until ExpectedRead = 0;
    end;

    local procedure RemoveNonNumericChars(Value: Text[50]) result: Code[50]
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to StrLen(Value) do
            if (Value[i] >= '0') and (Value[i] <= '9') then begin
                j += 1;
                result[j] := Value[i];
            end;
        exit(result);
    end;

    local procedure FormatNumStr(Value: Code[50]; Length: Integer): Code[50]
    begin
        Value := RemoveNonNumericChars(Value);
        exit(Format(Value, 0, StrSubstNo('<text,%1><filler,0>', Length)));
    end;

    local procedure FormatDecStr(Value: Decimal; Length: Integer): Text[30]
    begin
        exit(
          ConvertStr(
            Format(Value, Length - 2, '<integer>') +
            CopyStr(
              Format(
                Round(Value, 0.01, '<'),
                0, '<decimal,3><filler,0>'),
              2, 2),
            ' ', '0'));
    end;

    local procedure FormatDateYYMMDD(Date: Date): Text[6]
    begin
        exit(Format(Date, 0, '<Year,2><Filler Character,0><Month,2><Filler Character,0><Day,2><Filler Character,0>'));
    end;

    local procedure FormatDateDDMMYY(Date: Date): Text[6]
    begin
        exit(Format(Date, 0, '<Day,2><Filler Character,0><Month,2><Filler Character,0><Year,2><Filler Character,0>'));
    end;

    local procedure FormatDateYYYYMMDD(Date: Date): Text[8]
    begin
        exit(Format(Date, 0, '<Year4><Month,2><Filler Character,0><Day,2><Filler Character,0>'));
    end;

    local procedure InsertWaitingJournalLine(var Amount: Decimal; var Reference: Integer; PaymentOrderID: Integer; Status: Option Sent,Approved,Settled,Rejected)
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        WaitingJournal.Init();
        WaitingJournal.Reference := LibraryUtility.GetNewRecNo(WaitingJournal, WaitingJournal.FieldNo(Reference));

        case Status of
            Status::Sent:
                begin
                    WaitingJournal."Payment Order ID - Sent" := PaymentOrderID;
                    WaitingJournal."Remittance Status" := WaitingJournal."Remittance Status"::Sent;
                end;
            Status::Approved:
                WaitingJournal."Payment Order ID - Approved" := PaymentOrderID;
            Status::Settled:
                WaitingJournal."Payment Order ID - Settled" := PaymentOrderID;
            Status::Rejected:
                WaitingJournal."Payment Order ID - Rejected" := PaymentOrderID;
        end;
        WaitingJournal."Document No." := LibraryUtility.GenerateGUID();
        WaitingJournal.Amount := LibraryRandom.RandDecInRange(10, 20, 2);
        WaitingJournal."Amount (LCY)" := WaitingJournal.Amount;
        WaitingJournal.Insert();

        Amount += WaitingJournal.Amount;
        Reference := WaitingJournal.Reference;
    end;

    local procedure GetInStreamWithoutCRNL(var ClearedInstream: InStream; var TempFile: File)
    var
        FileMgt: Codeunit "File Management";
        OutStream: OutStream;
        ServerFileName: Text;
        NewString: Text;
        Byte: Integer;
        i: Integer;
        Char: Char;
    begin
        TempFile.Open(ServerFileName);
        for i := 1 to TempFile.Len do begin
            TempFile.Read(Char);
            Byte := Char;
            if not (Byte in [10, 13]) then // get rid of carriage return and line feed symbols
                NewString += Format(Char);
        end;
        TempFile.Close();
        FileMgt.DeleteServerFile(ServerFileName);

        ServerFileName := FileMgt.ServerTempFileName('txt');
        TempFile.WriteMode(true);
        TempFile.Create(ServerFileName);
        TempFile.CreateOutStream(OutStream);
        OutStream.WriteText(NewString);
        TempFile.Close();

        TempFile.Open(ServerFileName);
        TempFile.TextMode := true;
        TempFile.CreateInStream(ClearedInstream);
    end;

    local procedure GetKIDNumber(): Code[10]
    var
        DocumentTools: Codeunit DocumentTools;
    begin
        exit('1234' + DocumentTools.Modulus10('1234'));
    end;

    local procedure DeleteRemittancePaymentOrders()
    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        PaymentOrderData: Record "Payment Order Data";
        WaitingJournal: Record "Waiting Journal";
    begin
        RemittancePaymentOrder.DeleteAll();
        PaymentOrderData.DeleteAll();
        WaitingJournal.DeleteAll();
    end;

    local procedure PreparePaymentJnlLine(var RemittanceAgreement: Record "Remittance Agreement"; var RemittanceAccount: Record "Remittance Account"; var GenJournalLine: Record "Gen. Journal Line"; NewAmount: Decimal)
    var
        Vendor: Record Vendor;
        BatchName: Code[10];
    begin
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, false);
        SetJnlLineAmountLCY(GenJournalLine, -NewAmount);
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        UpdateBatchBankPaymentExportFormat(GenJournalLine."Journal Template Name", BatchName);

        LibraryRemittance.ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);
    end;

    local procedure PostInvoicesWithExternalDocNo(VendorNo: Code[20]; InvoicesCount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
    begin
        CreatePaymentJnlBatchWithBankAccount(GenJournalBatch);
        for Index := 1 to InvoicesCount do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNo(), -LibraryRandom.RandDecInRange(1000, 2000, 2));
            GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunPaymentExport(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAgreementCode: Code[10]; ExpectedMessage: Text; ConfirmAnswer: Boolean)
    var
        FileName: Text;
    begin
        LibraryVariableStorage.Enqueue(RemittanceAgreementCode);
        FileName := LibraryRemittance.GetTempFileName();
        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(ExpectedMessage);
        LibraryVariableStorage.Enqueue(ConfirmAnswer);
        Commit(); // COMMIT is required to run this codeunit
        CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJournalLine);
    end;

    local procedure SetAmountSpecLimit(LimitAmount: Decimal)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Amt. Spec limit to Norges Bank", LimitAmount);
        PurchSetup.Modify(true);
    end;

    local procedure SetJnlLineAmountLCY(var GenJournalLine: Record "Gen. Journal Line"; NewAmount: Decimal)
    begin
        GenJournalLine.Validate("Amount (LCY)", NewAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure ResetJnlLineEmptySpecification(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Specification (Norges Bank)", '');
        GenJournalLine.Modify(true);
    end;

    local procedure ResetJnlLineEmptyPaymentTypeCodeAbroad(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Payment Type Code Abroad", '');
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateWorkdate(NewDate: Date) OldDate: Date
    begin
        OldDate := WorkDate();
        WorkDate := NewDate;
        if Date2DWY(NewDate, 1) in [6, 7] then // "Posting Date" and "Pmt. Discount Date" compared works date in CU 15000001
            WorkDate := WorkDate() + 2;
    end;

    local procedure UpdateBatchBankPaymentExportFormat(TemplateName: Code[10]; BatchName: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        BankAccount.Get(GenJournalBatch."Bal. Account No.");
        BankAccount."Payment Export Format" := LibraryRemittance.FindRemittanceExportSetup(false);
        BankAccount.Modify();
        Commit();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestRemittancePaymentsHandler(var SuggestRemittancePayments: TestRequestPage "Suggest Remittance Payments")
    var
        VendorNo: Variant;
        RemittanceAccountCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAccountCode);
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestRemittancePayments.LastPaymentDate.SetValue(WorkDate());
        SuggestRemittancePayments.Vendor.SetFilter("No.", VendorNo);
        SuggestRemittancePayments.Vendor.SetFilter("Remittance Account Code", RemittanceAccountCode);
        SuggestRemittancePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceExportBankHandler(var RemittanceExportBank: TestRequestPage "Remittance - export (bank)")
    var
        RemittanceAgreementCode: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAgreementCode);
        RemittanceExportBank.RemAgreementCode.Value := RemittanceAgreementCode;
        LibraryVariableStorage.Dequeue(FileName);
        RemittanceExportBank.CurrentFilename.Value := FileName;
        RemittanceExportBank.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceExportBBSHandler(var RemittanceExportBBS: TestRequestPage "Remittance - export (BBS)")
    var
        RemittanceAgreementCode: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(RemittanceAgreementCode);
        RemittanceExportBBS.RemAgreementCode.Value := RemittanceAgreementCode;
        LibraryVariableStorage.Dequeue(FileName);
        RemittanceExportBBS.CurrentFilename.Value := FileName;
        RemittanceExportBBS.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemPaymOrderManExportHandler(var RemPaymOrderManExportHandler: TestRequestPage "Rem. paym. order - man. export")
    var
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(FileName);
        RemPaymOrderManExportHandler.Filename.Value := FileName;
        RemPaymOrderManExportHandler.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WaitingJnlPaymOverviewHandler(var WaitingJnlPaymOverview: TestRequestPage "Waiting Jnl - paym. overview")
    var
        v: Variant;
    begin
        LibraryVariableStorage.Dequeue(v);
        WaitingJnlPaymOverview."Waiting Journal".SetFilter(Reference, Format(v));
        WaitingJnlPaymOverview.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemPaymentOrderStatusHandler(var RemPaymentOrderStatus: TestRequestPage "Rem. payment order status")
    begin
        RemPaymentOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForExportPayment(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        v: Variant;
        Expected: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(v);
        Expected := v;
        Assert.AreEqual(Expected, Message, 'Wrong Message');
    end;
}

