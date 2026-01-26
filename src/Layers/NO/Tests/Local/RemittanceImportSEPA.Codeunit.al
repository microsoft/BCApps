codeunit 144136 "Remittance - Import SEPA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Credit Transfer] [Remittance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRemittance: Codeunit "Library - Remittance";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        FileMgt: Codeunit "File Management";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
        IsInitialized: Boolean;
        ConfirmToImportTheLines: Boolean;
        SelectNoToImportTheLines: Boolean;
        NoteWithControlReturnFilesAreReadMsg: Label 'Note:\With Control, return files are read in advance to check if the import can be made.\Return data is not imported to %1.';
        ConfirmImportQst: Label 'Return data for the file "%1" are imported correctly:\Approved: %2.\Rejected: %3.\Settled: %4.\\%4 settled payments are transferred to payment journal.', Comment = 'Parameter 1 - file name, 2, 3, 4 - integer numbers.';
        ConfirmImportExchRateQst: Label 'Return data in the file to be imported has a different currency exchange rate than one in a waiting journal. This may lead to gain/loss detailed ledger entries during application.\\do you want to continue?';
        ImportCancelledErr: Label 'Import is cancelled.';
        TransactionRejectedMsg: Label 'The transaction was rejected.';

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPain001FileForBank()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        WaitingJournal: Record "Waiting Journal";
        RemittancePaymentOrder: Record "Remittance Payment Order";
        DocumentNo: Code[20];
        Amount: Decimal;
        BatchName: Code[10];
        NbRemittancePaymentOrders: Integer;
        OldDate: Date;
    begin
        // [SCENARIO] Run the remittance suggestion and export as a file. Check the waiting journal is created.

        // [GIVEN] Foreign remittance invoice
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);

        RemittancePaymentOrder.Reset();
        NbRemittancePaymentOrders := RemittancePaymentOrder.Count();

        // [WHEN] we export the remittance payments to a file
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);

        // [THEN] data is created
        GetWaitingJournal(WaitingJournal);

        RemittancePaymentOrder.Reset();
        Assert.AreEqual(
          NbRemittancePaymentOrders + 1, RemittancePaymentOrder.Count, 'Remittance Payment order count should have increased by 1.');
        RemittancePaymentOrder.FindLast();

        // [THEN] SEPA Payment Inf ID is created from "External Document No." of the invoice (TFS 230901)
        Assert.IsTrue(WaitingJournal."SEPA Msg. ID" <> '', 'SEPA MSG ID is empty.');
        WaitingJournal.TestField(
          "SEPA Instr. ID",
          CopyStr(GenJournalLine."External Document No.", 1, MaxStrLen(GenJournalLine."Document No.")));
        Assert.IsTrue(WaitingJournal."SEPA Payment Inf ID" <> '', 'SEPA Payment Inf ID is empty.');
        Assert.IsTrue(WaitingJournal."SEPA End To End ID" <> '', 'SEPA End to End ID is empty.');

        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Sent, WaitingJournal."Remittance Status", 'Waiting journal status is not Sent');
        Assert.AreEqual(
          RemittancePaymentOrder.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order is incorrect in waiting journal.');

        UpdateWorkdate(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportPain002FileWithLongNoSeriesNumber()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RemittancePaymentOrderSettled: Record "Remittance Payment Order";
        RemittancePaymentOrderSent: Record "Remittance Payment Order";
        RemittancePaymentOrderApproved: Record "Remittance Payment Order";
        WaitingJournal: Record "Waiting Journal";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
        NbRemittancePaymentOrders: Integer;
    begin
        // [SCENARIO 197492] Export pain file, import a return file built to match it, and check the data was updated accordingly
        Initialize();

        OldDate := UpdateWorkdate(Today);
        RemittancePaymentOrderSent.Reset();

        // [GIVEN] Vendor "V" with remittance setup, posted invoice ("External Document No." = "EXT")
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        ExtDocumentNo := GenJournalLine."External Document No.";

        // [GIVEN] RemittanceAccount."Document No. Series" is setup with No Series having 20-chars length of "Starting No." = "00000000000000000000" (TFS 231469)
        // [GIVEN] Export the file for the bank
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        // [GIVEN] Intermediary checks to be sure everything is created correctly
        GetWaitingJournal(WaitingJournal);

        RemittancePaymentOrderSent.FindLast();
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Sent, WaitingJournal."Remittance Status", 'Waiting journal status is not Sent');
        Assert.AreEqual(
          RemittancePaymentOrderSent.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order is incorrect in waiting journal.');

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName); // Clear all lines, it must be blank before import
        ClearAllGenJournalLines(GenJournalBatch);
        FilePath := GeneratePain002File('ACCP');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        NbRemittancePaymentOrders := RemittancePaymentOrderSent.Count();

        // [GIVEN] Import the file from the bank (approval of the payment)
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 1, 0, 0);

        // [GIVEN] Waiting journal is updated: "Remittance Status" = "Approved"
        GetWaitingJournal(WaitingJournal);
        Assert.AreEqual(
          NbRemittancePaymentOrders + 1, RemittancePaymentOrderSent.Count, 'Remittance Payment order count should have increased by 1.');
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Approved, WaitingJournal."Remittance Status", 'Waiting journal status is not Approved');
        Assert.AreEqual(
          RemittancePaymentOrderSent.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order Sent has been changed in the waiting journal.');
        RemittancePaymentOrderApproved.FindLast();
        Assert.AreEqual(
          RemittancePaymentOrderApproved.ID, WaitingJournal."Payment Order ID - Approved",
          'Reference to payment order Approved is incorrect in waiting journal.');

        // [WHEN] Import the file from the bank (settlement of the payment)
        FilePath := GeneratePain002File('ACSC');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        NbRemittancePaymentOrders := RemittancePaymentOrderSent.Count();
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 0, 1);

        // [THEN] Waiting journal is updated: "Remittance Status" = "Settled"
        GetWaitingJournal(WaitingJournal);
        RemittancePaymentOrderSettled.FindLast();
        Assert.AreEqual(
          NbRemittancePaymentOrders + 1, RemittancePaymentOrderSent.Count, 'Remittance Payment order count should have increased by 1.');
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Settled, WaitingJournal."Remittance Status", 'Waiting journal status is not settled');
        Assert.AreEqual(
          RemittancePaymentOrderSent.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order Sent has been changed in the waiting journal.');
        Assert.AreEqual(
          RemittancePaymentOrderApproved.ID, WaitingJournal."Payment Order ID - Approved",
          'Reference to payment order Approved has been changed in the waiting journal.');
        Assert.AreEqual(
          RemittancePaymentOrderSettled.ID, WaitingJournal."Payment Order ID - Settled",
          'Reference to payment order Settled is incorrect in the waiting journal.');

        // [THEN] There are two journal lines have been created (payment, balance):
        // [THEN] line1: "Document Type"::Payment, "Document No." = "00000000000000000000", "External Document No." = "EXT", "Account Type" = "Vendor",
        // [THEN] line2: "Document Type"::Payment, "Document No." = "00000000000000000000", "External Document No." = "", "Account Type" = "Bank Account"
        // [THEN] "Document Type" is Payment in the balancing payment line (TFS 232592)
        VerifyImportedLinesInternational(
          BatchName,
          GenJournalLine."Journal Template Name",
          ExtDocumentNo,
          WorkDate(),
          DocumentNo,
          Vendor."No.",
          RemittanceAccount, Amount);

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054File()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RemittancePaymentOrderSettled: Record "Remittance Payment Order";
        RemittancePaymentOrderSent: Record "Remittance Payment Order";
        WaitingJournal: Record "Waiting Journal";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
        NbRemittancePaymentOrders: Integer;
    begin
        // [SCENARIO] export CAMT054 file to setup everything correctly, the import a return file built to match it, and check the data was updated accordingly

        // [GIVEN] Foreign remittance invoice
        OldDate := UpdateWorkdate(Today);
        Initialize();
        RemittancePaymentOrderSent.Reset();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        ExtDocumentNo := GenJournalLine."External Document No.";

        // [GIVEN] export the file for the bank
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        // intermediary checks to be sure everything is created correctly
        GetWaitingJournal(WaitingJournal);

        RemittancePaymentOrderSent.FindLast();
        Assert.AreEqual(
          RemittancePaymentOrderSent.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order is incorrect in waiting journal.');
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Sent, WaitingJournal."Remittance Status", 'Waiting journal status is not Sent');

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName); // Clear all lines, it must be blank before import
        ClearAllGenJournalLines(GenJournalBatch);
        FilePath := GenerateCAMT054File();
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        NbRemittancePaymentOrders := RemittancePaymentOrderSent.Count();

        // [WHEN] we import the file from the bank (immediate settlement of the payment)
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 0, 1);

        // [THEN] waiting journal, payment journal are updated
        GetWaitingJournal(WaitingJournal);
        RemittancePaymentOrderSettled.FindLast();
        Assert.AreEqual(
          NbRemittancePaymentOrders + 1, RemittancePaymentOrderSent.Count, 'Remittance Payment order count should have increased by 1.');
        Assert.AreEqual(
          WaitingJournal."Remittance Status"::Settled, WaitingJournal."Remittance Status", 'Waiting journal status is not Settled');
        Assert.AreEqual(
          RemittancePaymentOrderSent.ID, WaitingJournal."Payment Order ID - Sent",
          'Reference to payment order Sent has been changed in the waiting journal.');
        Assert.AreEqual(
          RemittancePaymentOrderSettled.ID, WaitingJournal."Payment Order ID - Settled",
          'Reference to payment order Settled is incorrect in the waiting journal.');

        // [THEN] "Document Type" is Payment in the balancing payment line (TFS 232592)
        VerifyImportedLinesInternational(
          BatchName,
          GenJournalLine."Journal Template Name",
          ExtDocumentNo,
          WorkDate(),
          DocumentNo,
          Vendor."No.",
          RemittanceAccount, Amount);

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,PaymentOrderSettlStatusHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure SpecifyingJournalTemplateNameImportsToSpecifiedJournalAndShowsSettlementDialog()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        ImportGenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        ExtDocumentNo: Code[35];
        OldDate: Date;
    begin
        // [SCENARIO] import a pain002 file and check it is imported in the specified journal
        // [GIVEN] Foreign remittance invoice
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        ExtDocumentNo := GenJournalLine."External Document No.";

        LibraryRemittance.CreatePaymentGenJournalBatch(ImportGenJournalBatch, true);

        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName); // Clear all lines, it must be blank before import
        ClearAllGenJournalLines(GenJournalBatch);

        RemittanceAccount.Validate("Return Journal Template Name", ImportGenJournalBatch."Journal Template Name");
        RemittanceAccount.Validate("Return Journal Name", ImportGenJournalBatch.Name);
        RemittanceAccount.Modify(true);

        // [WHEN] we import data to settle a payment
        FilePath := GeneratePain002File('ACCP');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 1, 0, 0);

        FilePath := GeneratePain002File('ACSC');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 0, 1);

        // [THEN] the data is imported to the expected journal
        // [THEN] "Document Type" is Payment in the balancing payment line (TFS 232592)
        VerifyImportedLinesInternational(
          ImportGenJournalBatch.Name, GenJournalLine."Journal Template Name", ExtDocumentNo, WorkDate(), DocumentNo, Vendor."No.",
          RemittanceAccount, Amount);

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportPaymentsConfirmHandler,ImportRemittancePaymentOrderRequestPageHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure SelectingNoAfterPaymentIsImportedReversesTheEntries()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO] import data from a pain002 file but select no at the end. Check no data is imported after all.
        // [GIVEN] Foreign remittance invoice
        Initialize();

        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);

        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName); // Clear all lines, it must be blank before import
        ClearAllGenJournalLines(GenJournalBatch);

        // [WHEN] we import data but select no
        FilePath := GeneratePain002File('ACCP');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 1, 0, 0);

        FilePath := GeneratePain002File('ACSC');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [THEN] an error message confirms that the import was cancelled by the user, and no lines are imported
        asserterror ImportRemittancePaymentOrderFile(BatchName, SelectNoToImportTheLines, FilePath, 0, 0, 1);
        Assert.ExpectedError('Import is cancelled');
        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingFileWithControlBatchRevertsTheEntries()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO] import data but with the Control Batch checkbox enabled. Check no data is imported.
        // [GIVEN] Foreign remittance invoice
        OldDate := UpdateWorkdate(Today);
        Initialize();

        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);

        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName); // Clear all lines, it must be blank before import
        ClearAllGenJournalLines(GenJournalBatch);

        // [WHEN] we import data but select Check batch
        FilePath := GeneratePain002File('ACCP');
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [THEN] An error message confirms the import is cancelled.
        asserterror ImportRemittancePaymentOrderFileControlBatch(BatchName, FilePath, 1, 0, 0);
        Assert.ExpectedError('Import of return data is cancelled');

        VerifyNoLinesAreImported(BatchName, GenJournalLine."Journal Template Name");

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler,RemittanceMessageHandler')]
    [Scope('OnPrem')]
    procedure ImportingFileWithControlBatchAndRemittanceJournal()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ImportGenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO 233366] When Stan performs import data to Payment Journal from Return File with Control Batch checkbox checked, return data is not imported.
        Initialize();

        // [GIVEN] Foreign remittance invoice
        OldDate := UpdateWorkdate(WorkDate());
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);

        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);

        // [GIVEN] "Journal Name" and "Journal Template Name" fields of Remittance Account are filled with non-empty values.
        LibraryRemittance.CreatePaymentGenJournalBatch(ImportGenJournalBatch, true);
        RemittanceAccount."Return Journal Template Name" := ImportGenJournalBatch."Journal Template Name";
        RemittanceAccount."Return Journal Name" := ImportGenJournalBatch.Name;
        RemittanceAccount.Modify();

        // [GIVEN] Return File
        FilePath := GenerateCAMT054File();
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [WHEN] Perform import from Return File with Control Batch checked.
        asserterror ImportRemittancePaymentOrderFileControlBatch(ImportGenJournalBatch.Name, FilePath, 1, 0, 0);

        // [THEN] Return Data is not imported.
        VerifyNoLinesAreImported(ImportGenJournalBatch.Name, ImportGenJournalBatch."Journal Template Name");

        Cleanup(OldDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalErrorFactbox()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTemplates: TestPage "General Journal Templates";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
        FirstLineErrorText: array[2] of Text;
        SecondLineErrorText: array[2] of Text;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 231460] There is an error factbox on a payment journal page
        Initialize();

        // [GIVEN] Payment Journal with two lines:
        // [GIVEN] First line has two export processing errors "ERR1-1", "ERR1-2"
        // [GIVEN] Second line has two export processing errors "ERR2-1", "ERR2-2"
        GeneralJournalTemplates.OpenView();
        GeneralJournalTemplates.FILTER.SetFilter(Type, '4'); // Payment
        GeneralJournalBatches.Trap();
        GeneralJournalTemplates.Batches.Invoke();
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GeneralJournalTemplates.Name.Value();
        GenJournalLine."Journal Batch Name" := GeneralJournalBatches.Name.Value();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        ClearAllGenJournalLines(GenJournalBatch);
        CreateGeneralJnlLineWithPmtExportErrors(GenJournalLine, FirstLineErrorText);
        CreateGeneralJnlLineWithPmtExportErrors(GenJournalLine, SecondLineErrorText);

        // [WHEN] Open Payment journal page
        PaymentJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();

        // [THEN] Payment journal error factbox shows "ERR1-1", "ERR1-2" for the first line, "ERR2-1", "ERR2-2" for the second line
        // [THEN] No errors for the new third blanked line (just step cursor to the next line after the second one)
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(FirstLineErrorText[1]);
        PaymentJournal."Payment File Errors".Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(FirstLineErrorText[2]);
        PaymentJournal."Payment File Errors".Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(FirstLineErrorText[2]);
        PaymentJournal.Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(SecondLineErrorText[1]);
        PaymentJournal."Payment File Errors".Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(SecondLineErrorText[2]);
        PaymentJournal."Payment File Errors".Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals(SecondLineErrorText[2]);
        PaymentJournal.Next();
        PaymentJournal."Payment File Errors"."Error Text".AssertEquals('');

        PaymentJournal.Close();
        GeneralJournalBatches.Close();
        GeneralJournalTemplates.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionsUpdateWaitingJournal()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Waiting Journal] [Dimension]
        // [SCENARIO 233377] "Gen. Journal Line"."Dimension Set ID" is copying from "Waiting Journal" in "Import SEPA Common"."UpdateWaitingJournal"
        Initialize();

        // [GIVEN] "Waiting Journal" with "Dimension Set ID" = 17
        MockWaitingJournal(WaitingJournal, GenJournalLine);

        // [WHEN] Invoke "Import SEPA Common"."UpdateWaitingJournal"
        InvokeUpdateWaitingJournal(WaitingJournal, GenJournalLine);

        // [THEN] "Gen. Journal Line"."Dimension Set ID" = 17
        VerifyDimSetIDGenJnlLine(WaitingJournal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyAndAmountUpdateWaitingJournal()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyFactor: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [UT] [Waiting Journal] [Gen. Journal Line]
        // [SCENARIO 266335] Amounts, Currency Code and Factor in Gen. Journal Line are equal to Amounts, Currency Code and Factor in Waiting Journal after UpdateWaitingJournal is invoked in codeunit "Import SEPA Common"
        Initialize();

        // [GIVEN] Waiting Journal with "Currency Code" = "EUR", "Currency Factor" = 3.141593, Amount = 100.0 and "Amount (LCY)" = 31.83
        MockWaitingJournal(WaitingJournal, GenJournalLine);
        CurrencyFactor := LibraryRandom.RandDecInRange(10, 20, 4);
        Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        UpdateWaitingJournalCurrencyAndAmount(
          WaitingJournal, CreateCurrency(), CurrencyFactor, Amount, ROUND(Amount / CurrencyFactor));

        // [WHEN] Invoke UpdateWaitingJournal in codeunit "Import SEPA Common"
        InvokeUpdateWaitingJournal(WaitingJournal, GenJournalLine);

        // [THEN] "Currency Code" = "EUR" and "Currency Factor" = 3.141593 in Gen. Journal Line
        GenJournalLine.Get(WaitingJournal."Journal Template Name", WaitingJournal."Journal Batch Name", GenJournalLine."Line No." + 10000);
        GenJournalLine.TestField("Currency Code", WaitingJournal."Currency Code");
        GenJournalLine.TestField("Currency Factor", WaitingJournal."Currency Factor");

        // [THEN] Amount = 100.0 and "Amount (LCY)" = 31.83 in Gen. Journal Line
        GenJournalLine.TestField(Amount, WaitingJournal.Amount);
        GenJournalLine.TestField("Amount (LCY)", WaitingJournal."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmImportDifferentExchRate_Positive()
    var
        ImportSEPACommon: Codeunit "Import SEPA Common";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 308307] COD 10635 "Import SEPA Common".ConfirmImportExchRateDialog() in case of positive confirm
        Initialize();
        EnqueueConfirmImportWithDiffExchRate(true);

        Assert.IsTrue(ImportSEPACommon.ConfirmImportExchRateDialog(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmImportDifferentExchRate_Negative()
    var
        ImportSEPACommon: Codeunit "Import SEPA Common";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 308307] COD 10635 "Import SEPA Common".ConfirmImportExchRateDialog() in case of negative confirm
        Initialize();
        EnqueueConfirmImportWithDiffExchRate(false);

        asserterror ImportSEPACommon.ConfirmImportExchRateDialog();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ImportCancelledErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_NoDiff()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of the same currency exchange rate and amounts
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "NOK", SrcAmt = 100, TrgtAmt = 200, Factor = 0.5
        FilePath := WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept import summary confirm (1 settled)
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] No confirm warning about different exchange rate has been shown (import ignores file amount details)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_NoDiff_LCYCode()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different LCY (target) currency code
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "USD", SrcAmt = 200, TrgtAmt = 500, Factor = 0.4
        FilePath :=
          WriteCamtFiletoDiskWithCustomAmountDetails(
            WaitingJournal, CurrencyCode, LibraryUtility.GenerateGUID(), CurrencyFactor + 1, Amount + 1, AmountLCY + 1);

        // [WHEN] Import the file, accept import summary confirm (1 settled)
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] No confirm warning about different exchange rate has been shown (import ignores file amount details)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_NoDiff_Currency()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different currency (source) code
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "USD", target currency = "NOK", SrcAmt = 200, TrgtAmt = 500, Factor = 0.4
        FilePath :=
          WriteCamtFiletoDiskWithCustomAmountDetails(
            WaitingJournal, LibraryUtility.GenerateGUID(), LCYCode, CurrencyFactor + 1, Amount + 1, AmountLCY + 1);

        // [WHEN] Import the file, accept import summary confirm (1 settled)
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] No confirm warning about different exchange rate has been shown (import ignores file amount details)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_NoDiff_OnlyExchRate()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different currency exchange rate but the same amounts
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "NOK", SrcAmt = 100, TrgtAmt = 200, Factor = 0.51
        FilePath := WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor + 1, Amount, AmountLCY);

        // [WHEN] Import the file, accept import summary confirm (1 settled)
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] No confirm warning about different exchange rate has been shown (import ignores file amount details)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_Diff_OnlyAmountLCY()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different LCY (target currency) amount
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "NOK", SrcAmt = 100, TrgtAmt = 400, Factor = 0.25
        AmountLCY := AmountLCY * LibraryRandom.RandIntInRange(3, 5);
        CurrencyFactor := Amount / AmountLCY;
        FilePath := WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import, accept import summary confirm (1 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown (import uses file amount details instead of waiting journal)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 100, Amount LCY = 400, Currency Factor = 0.25
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_Diff_OnlyAmount()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different source currency amount
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "NOK", SrcAmt = 50, TrgtAmt = 200, Factor = 0.25
        Amount := Amount * LibraryRandom.RandIntInRange(3, 5);
        CurrencyFactor := Amount / AmountLCY;
        FilePath := WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import, accept import summary confirm (1 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown (import uses file amount details instead of waiting journal)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 50, Amount LCY = 200, Currency Factor = 0.25
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_DiffExchRateDetection_Diff_BothAmounts()
    var
        WaitingJournal: Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of different both source and target amounts
        PrepareDiffExchRateDetectionScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        MockWaitingJournalWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with source currency = "EUR", target currency = "NOK", SrcAmt = 50, TrgtAmt = 250, Factor = 0.2
        ModifyAmounts(Amount, AmountLCY, CurrencyFactor);
        FilePath := WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import, accept import summary confirm (1 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 1, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown (import uses file amount details instead of waiting journal)
        // [THEN] 1 payment has been settled with Currency = "EUR", Amount = 50, Amount LCY = 250, Currency Factor = 0.2
        VerifyWaitingJournal(WaitingJournal, CurrencyCode, Amount, AmountLCY, CurrencyFactor);
        VerifyGenJnlAfterDiffExchRateImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_MultiCurrExchFactor_TwoPmt_NoDiff()
    var
        WaitingJournal: array[2] of Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
        CurrencyFactor: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of two payments and no difference in exchange rate
        PrepareDiffExchRateDetectionTwoPmtScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal line1 with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [GIVEN] Waiting Journal line2 with Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        MockTwoWaitingJournalsWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with two payments:
        // [GIVEN] pmt1: source currency = "EUR", target currency = "NOK", SrcAmt = 100, TrgtAmt = 200, Factor = 0.5
        // [GIVEN] pmt2: source currency = "EUR", target currency = "NOK", SrcAmt = 200, TrgtAmt = 500, Factor = 0.4
        FilePath := WriteCamtFiletoDiskWithTwoCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept import summary confirm (2 settled)
        EnqueueConfirmImport(FilePath, 0, 0, 2, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] No confirm warning about different exchange rate has been shown (import ignores file amount details)
        // [THEN] 2 payments have been settled:
        // [THEN] pmt1: Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [THEN] pmt2: Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        // [THEN] balance: Currency = "", Amount = 700, Amount LCY = 700, Currency Factor = 0
        for i := 1 to ARRAYLEN(WaitingJournal) do
            VerifyWaitingJournal(WaitingJournal[i], CurrencyCode, Amount[i], AmountLCY[i], CurrencyFactor[i]);
        VerifyGenJnlAfterDiffExchRateTwoPmtImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_MultiCurrExchFactor_TwoPmt_OnlyFirstDiff()
    var
        WaitingJournal: array[2] of Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
        CurrencyFactor: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of two payments and different 1st exchange rate
        PrepareDiffExchRateDetectionTwoPmtScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal line1 with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [GIVEN] Waiting Journal line2 with Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        MockTwoWaitingJournalsWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with two payments:
        // [GIVEN] pmt1: source currency = "EUR", target currency = "NOK", SrcAmt = 50, TrgtAmt = 250, Factor = 0.2
        // [GIVEN] pmt2: source currency = "EUR", target currency = "NOK", SrcAmt = 200, TrgtAmt = 500, Factor = 0.4
        ModifyAmounts(Amount[1], AmountLCY[1], CurrencyFactor[1]);
        FilePath := WriteCamtFiletoDiskWithTwoCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import (once), accept import summary confirm (2 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 2, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown once (import uses file amount details instead of waiting journal)
        // [THEN] 2 payments have been settled:
        // [THEN] pmt1: Currency = "EUR", Amount = 50, Amount LCY = 250, Currency Factor = 0.2
        // [THEN] pmt2: Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        // [THEN] balance: Currency = "", Amount = 750, Amount LCY = 750, Currency Factor = 0
        for i := 1 to ARRAYLEN(WaitingJournal) do
            VerifyWaitingJournal(WaitingJournal[i], CurrencyCode, Amount[i], AmountLCY[i], CurrencyFactor[i]);
        VerifyGenJnlAfterDiffExchRateTwoPmtImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_MultiCurrExchFactor_TwoPmt_OnlySecondDiff()
    var
        WaitingJournal: array[2] of Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
        CurrencyFactor: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of two payments and different 2nd exchange rate
        PrepareDiffExchRateDetectionTwoPmtScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal line1 with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [GIVEN] Waiting Journal line2 with Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        MockTwoWaitingJournalsWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with two payments:
        // [GIVEN] pmt1: source currency = "EUR", target currency = "NOK", SrcAmt = 100, TrgtAmt = 200, Factor = 0.5
        // [GIVEN] pmt2: source currency = "EUR", target currency = "NOK", SrcAmt = 250, TrgtAmt = 1000, Factor = 0.25
        ModifyAmounts(Amount[2], AmountLCY[2], CurrencyFactor[2]);
        FilePath := WriteCamtFiletoDiskWithTwoCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import (once), accept import summary confirm (2 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 2, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown once (import uses file amount details instead of waiting journal)
        // [THEN] 2 payments have been settled:
        // [THEN] pmt1: Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [THEN] pmt2: Currency = "EUR", Amount = 250, Amount LCY = 1000, Currency Factor = 0.25
        // [THEN] balance: Currency = "", Amount = 1200, Amount LCY = 1200, Currency Factor = 0
        for i := 1 to ARRAYLEN(WaitingJournal) do
            VerifyWaitingJournal(WaitingJournal[i], CurrencyCode, Amount[i], AmountLCY[i], CurrencyFactor[i]);
        VerifyGenJnlAfterDiffExchRateTwoPmtImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportCamt054_MultiCurrExchFactor_TwoPmt_BothDiff()
    var
        WaitingJournal: array[2] of Record "Waiting Journal";
        GenJournalLine: Record "Gen. Journal Line";
        FilePath: Text;
        LCYCode: Code[10];
        CurrencyCode: Code[10];
        Amount: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
        CurrencyFactor: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 308307] Import CAMT054 file in case of two payments and different both exchange rates
        PrepareDiffExchRateDetectionTwoPmtScenario(LCYCode, CurrencyCode, Amount, AmountLCY, CurrencyFactor);

        // [GIVEN] LCY Code = "NOK"
        // [GIVEN] Waiting Journal line1 with Currency = "EUR", Amount = 100, Amount LCY = 200, Currency Factor = 0.5
        // [GIVEN] Waiting Journal line2 with Currency = "EUR", Amount = 200, Amount LCY = 500, Currency Factor = 0.4
        MockTwoWaitingJournalsWithAmounts(WaitingJournal, GenJournalLine, CurrencyCode, CurrencyFactor, Amount, AmountLCY);

        // [GIVEN] CAMT054 file with two payments:
        // [GIVEN] pmt1: source currency = "EUR", target currency = "NOK", SrcAmt = 50, TrgtAmt = 250, Factor = 0.2
        // [GIVEN] pmt2: source currency = "EUR", target currency = "NOK", SrcAmt = 250, TrgtAmt = 1000, Factor = 0.25
        for i := 1 to ARRAYLEN(WaitingJournal) do
            ModifyAmounts(Amount[i], AmountLCY[i], CurrencyFactor[i]);
        FilePath := WriteCamtFiletoDiskWithTwoCustomAmountDetails(WaitingJournal, CurrencyCode, LCYCode, CurrencyFactor, Amount, AmountLCY);

        // [WHEN] Import the file, accept different exchange rate import (once), accept import summary confirm (2 settled)
        EnqueueConfirmImportWithDiffExchRate(true);
        EnqueueConfirmImport(FilePath, 0, 0, 2, true);
        ImportAndHandleCAMT054File(GenJournalLine, FilePath);

        // [THEN] Confirm warning about different exchange rate has been shown once (import uses file amount details instead of waiting journal)
        // [THEN] 2 payments have been settled:
        // [THEN] pmt1: Currency = "EUR", Amount = 50, Amount LCY = 250, Currency Factor = 0.2
        // [THEN] pmt2: Currency = "EUR", Amount = 250, Amount LCY = 1000, Currency Factor = 0.25
        // [THEN] balance: Currency = "", Amount = 1250, Amount LCY = 1250, Currency Factor = 0
        for i := 1 to ARRAYLEN(WaitingJournal) do
            VerifyWaitingJournal(WaitingJournal[i], CurrencyCode, Amount[i], AmountLCY[i], CurrencyFactor[i]);
        VerifyGenJnlAfterDiffExchRateTwoPmtImport(WaitingJournal);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportRejectedPain002FileWithReasonAndAdditionalInfo()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        WaitingJournal: Record "Waiting Journal";
        DocumentNo: Code[20];
        FilePath: Text;
        ReasonText: Text;
        AdditionalInfo: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO 341733] Stan can import the rejected pain.002 file with both status reason and additional information

        Initialize();
        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName);
        ClearAllGenJournalLines(GenJournalBatch);

        // [GIVEN] Rejected Pain.002 file with the reason code "X" and additional information text "Y"
        ReasonText := LibraryUtility.GenerateGUID();
        AdditionalInfo := LibraryUtility.GenerateGUID();
        AddToNameValueBuffer(TempNameValueBuffer, '        <StsRsnInf>');
        AddToNameValueBuffer(TempNameValueBuffer, '          <Rsn>');
        AddToNameValueBuffer(TempNameValueBuffer, StrSubstNo('            <Cd>%1</Cd>', ReasonText));
        AddToNameValueBuffer(TempNameValueBuffer, '          </Rsn>');
        AddToNameValueBuffer(TempNameValueBuffer, StrSubstNo('          <AddtlInf>%1</AddtlInf>', AdditionalInfo));
        AddToNameValueBuffer(TempNameValueBuffer, '        </StsRsnInf>');

        FilePath := GeneratePain002FileWithCustomStatusInfo(TempNameValueBuffer);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [GIVEN] Import the rejected file from the bank
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 1, 0);

        // [THEN] Return error log contains the following message text: Code: X Message: "Y"
        GetWaitingJournal(WaitingJournal);
        VerifyReturnError(WaitingJournal.Reference, StrSubstNo('Code: %1 Message: "%2".', ReasonText, AdditionalInfo));

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportRejectedPain002FileWithoutStatusReason()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        WaitingJournal: Record "Waiting Journal";
        DocumentNo: Code[20];
        FilePath: Text;
        AdditionalInfo: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO 341733] Stan can import the rejected pain.002 file with no status reason in the element <StsRsnInf>\<Rsn>\<Cd>

        Initialize();
        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName);
        ClearAllGenJournalLines(GenJournalBatch);

        // [GIVEN] Rejected Pain.002 file with the additional information text "Y" and without the reason of failure
        AdditionalInfo := LibraryUtility.GenerateGUID();
        AddToNameValueBuffer(TempNameValueBuffer, '        <StsRsnInf>');
        AddToNameValueBuffer(TempNameValueBuffer, StrSubstNo('          <AddtlInf>%1</AddtlInf>', AdditionalInfo));
        AddToNameValueBuffer(TempNameValueBuffer, '        </StsRsnInf>');
        FilePath := GeneratePain002FileWithCustomStatusInfo(TempNameValueBuffer);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [GIVEN] Import the rejected file from the bank
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 1, 0);

        // [THEN] Return error log contains the following message text: Message: "Y"
        GetWaitingJournal(WaitingJournal);
        VerifyReturnError(WaitingJournal.Reference, StrSubstNo('Message: "%1".', AdditionalInfo));

        Cleanup(OldDate);
    end;

    [Test]
    [HandlerFunctions('SuggestRemittancePaymentsHandler,RemittanceMessageHandler,ImportRemittancePaymentOrderRequestPageHandler,ImportPaymentsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportRejectedPain002FileWithoutStatusInfo()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        WaitingJournal: Record "Waiting Journal";
        DocumentNo: Code[20];
        FilePath: Text;
        Amount: Decimal;
        BatchName: Code[10];
        OldDate: Date;
    begin
        // [SCENARIO 341733] Stan can import the rejected pain.002 file with no status information

        Initialize();
        OldDate := UpdateWorkdate(Today);
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"Other bank",
          RemittanceAgreement,
          RemittanceAccount,
          Vendor,
          GenJournalLine, true);
        UpdateSetupForBankAndExport(GenJournalLine, RemittanceAccount, DocumentNo, Vendor, BatchName, Amount);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", BatchName);
        ClearAllGenJournalLines(GenJournalBatch);

        // [GIVEN] Rejected Pain.002 file with no status information in the nodes StsRsnInf
        AddToNameValueBuffer(TempNameValueBuffer, '        <StsRsnInf>');
        AddToNameValueBuffer(TempNameValueBuffer, '        </StsRsnInf>');
        FilePath := GeneratePain002FileWithCustomStatusInfo(TempNameValueBuffer);
        LibraryRemittance.CreateReturnFileSetupEntry(RemittanceAgreement.Code, FilePath);

        // [GIVEN] Import the rejected file from the bank
        ImportRemittancePaymentOrderFile(BatchName, ConfirmToImportTheLines, FilePath, 0, 1, 0);

        // [THEN] Return error log contains the following message text: The transaction was rejected.
        GetWaitingJournal(WaitingJournal);
        VerifyReturnError(WaitingJournal.Reference, TransactionRejectedMsg);

        Cleanup(OldDate);
    end;

    local procedure Initialize()
    var
        WaitingJournal: Record "Waiting Journal";
        ReturnFileSetup: Record "Return File Setup";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        ReturnError: Record "Return Error";
    begin
        LibraryVariableStorage.Clear();
        WaitingJournal.DeleteAll();
        ReturnFileSetup.DeleteAll();
        VendorBankAccount.DeleteAll();
        Vendor.DeleteAll();
        ReturnError.DeleteAll();

        LibraryERMCountryData.UpdateLocalData();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        ConfirmToImportTheLines := true;
        SelectNoToImportTheLines := false;
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
    end;

    local procedure PrepareDiffExchRateDetectionScenario(var LCYCode: Code[10]; var CurrencyCode: Code[10]; var Amount: Decimal; var AmountLCY: Decimal; var CurrencyFactor: Decimal)
    begin
        Initialize();
        LCYCode := LibraryUtility.GenerateGUID();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        AmountLCY := LibraryRandom.RandDecInRange(10000, 20000, 2);
        CurrencyFactor := Amount / AmountLCY;
        UpdateGLSetup(LCYCode);
    end;

    local procedure PrepareDiffExchRateDetectionTwoPmtScenario(var LCYCode: Code[10]; var CurrencyCode: Code[10]; var Amount: array[2] of Decimal; var AmountLCY: array[2] of Decimal; var CurrencyFactor: array[2] of Decimal)
    var
        i: Integer;
    begin
        Initialize();
        LCYCode := LibraryUtility.GenerateGUID();
        CurrencyCode := CreateCurrency();
        for i := 1 to ARRAYLEN(Amount) do begin
            Amount[i] := LibraryRandom.RandDecInRange(1000, 2000, 2);
            AmountLCY[i] := LibraryRandom.RandDecInRange(10000, 20000, 2);
            CurrencyFactor[i] := Amount[i] / AmountLCY[i];
        end;
        UpdateGLSetup(LCYCode);
    end;

    local procedure UpdateWaitingJournalCurrencyAndAmount(var WaitingJournal: Record "Waiting Journal"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; LineAmount: Decimal; AmountLCY: Decimal)
    begin
        WaitingJournal.Validate("Currency Code", CurrencyCode);
        WaitingJournal.Validate("Currency Factor", CurrencyFactor);
        WaitingJournal.Validate(Amount, LineAmount);
        WaitingJournal.Validate("Amount (LCY)", AmountLCY);
        WaitingJournal.Modify(true);
    end;

    local procedure UpdateGLSetup(NewLCYCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GLSetup.Validate("LCY Code", NewLCYCode);
        GLSetup.Modify();
    end;

    local procedure CreateCurrency(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(1, 10, 2)));
    end;

    local procedure GetWaitingJournal(var WaitingJournal: Record "Waiting Journal")
    begin
        Clear(WaitingJournal);
        Assert.AreEqual(1, WaitingJournal.Count, 'Wrong number of lines found in waiting journal');
        WaitingJournal.FindFirst();
    end;

    local procedure ClearAllGenJournalLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure CreateNoSeriesWithLongDocNos(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(
          NoSeriesLine, NoSeries.Code,
          PadStr('', MaxStrLen(NoSeriesLine."Starting No."), '0'),
          PadStr('', MaxStrLen(NoSeriesLine."Starting No."), '9'));
        exit(NoSeries.Code);
    end;

    local procedure CreateGeneralJnlLineWithPmtExportErrors(GenJournalLine: Record "Gen. Journal Line"; var ErrorText: array[2] of Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        i: Integer;
    begin
        LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', 0);
        for i := 1 to ArrayLen(ErrorText) do begin
            ErrorText[i] := LibraryUtility.GenerateGUID();
            PaymentJnlExportErrorText.CreateNew(GenJournalLine, ErrorText[i], LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        end;
    end;

    local procedure ImportRemittancePaymentOrderFileControlBatch(GenJournalBatchName: Code[20]; FilePath: Text; Approved: Integer; Rejected: Integer; Settled: Integer)
    begin
        InvokeImportRemittancePaymentOrderFile(GenJournalBatchName, true, true, FilePath, Approved, Rejected, Settled);
    end;

    local procedure ImportRemittancePaymentOrderFile(GenJournalBatchName: Code[20]; ConfirmTheImport: Boolean; FilePath: Text; Approved: Integer; Rejected: Integer; Settled: Integer)
    begin
        InvokeImportRemittancePaymentOrderFile(GenJournalBatchName, ConfirmTheImport, false, FilePath, Approved, Rejected, Settled);
    end;

    local procedure InvokeImportRemittancePaymentOrderFile(GenJournalBatchName: Code[20]; ConfirmTheImport: Boolean; UseControlBatch: Boolean; FilePath: Text; Approved: Integer; Rejected: Integer; Settled: Integer)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);

        LibraryVariableStorage.Enqueue(UseControlBatch);
        if UseControlBatch then
            LibraryVariableStorage.Enqueue(StrSubstNo(NoteWithControlReturnFilesAreReadMsg, PRODUCTNAME.Full()));
        EnqueueConfirmImport(FilePath, Approved, Rejected, Settled, ConfirmTheImport);

        // ImportPaymentOrder action
        Commit();
        PaymentJournal.ImportReturnData.Invoke();
    end;

    local procedure GeneratePain002File(StatusCode: Text[50]): Text
    var
        ServerTemplateFileName: Text;
    begin
        ServerTemplateFileName := FileMgt.ServerTempFileName('xml');
        WritePainFileToDisk(ServerTemplateFileName);
        exit(ChangePaint002XMLContentAndSave(ServerTemplateFileName, StatusCode));
    end;

    local procedure GeneratePain002FileWithCustomStatusInfo(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Text
    var
        ServerTemplateFileName: Text;
    begin
        ServerTemplateFileName := FileMgt.ServerTempFileName('xml');
        WritePainFileCustStatusInfoToDisk(TempNameValueBuffer, ServerTemplateFileName);
        exit(ChangePaint002XMLContentAndSave(ServerTemplateFileName, 'RJCT'));
    end;

    local procedure ChangePaint002XMLContentAndSave(ServerTemplateFileName: Text; StatusCode: Text[50]): Text
    var
        WaitingJournal: Record "Waiting Journal";
        XMLBuffer: Record "XML Buffer";
        ServerFileName: Text;
    begin
        GetWaitingJournal(WaitingJournal);
        XMLBuffer.Reset();
        XMLBuffer.DeleteAll();
        XMLBuffer.Load(ServerTemplateFileName);

        UpdateXmlFileBasedOnNames(XMLBuffer, 'CreDtTm', FormatDate(WorkDate()));
        UpdateXmlFileBasedOnNames(XMLBuffer, 'OrgnlMsgId', WaitingJournal."SEPA Msg. ID");
        UpdateXmlFileBasedOnNames(XMLBuffer, 'OrgnlPmtInfId', WaitingJournal."SEPA Payment Inf ID");
        UpdateXmlFileBasedOnNames(XMLBuffer, 'OrgnlInstrId', WaitingJournal."SEPA Instr. ID");
        UpdateXmlFileBasedOnNames(XMLBuffer, 'OrgnlEndToEndId', WaitingJournal."SEPA End To End ID");
        UpdateXmlFileBasedOnNames(XMLBuffer, 'TxSts', StatusCode);

        XMLBuffer.Reset();
        XMLBuffer.FindFirst();
        ServerFileName := FileMgt.ServerTempFileName('xml');
        XMLBuffer.Save(ServerFileName);
    end;

    local procedure GenerateCAMT054File(): Text
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        GetWaitingJournal(WaitingJournal);
        exit(WriteCamtFiletoDisk(WaitingJournal, WorkDate(), 'BOOK'));
    end;

    local procedure GetClientFileFromServerFile(): Text
    begin
        // how do any of these tests work? 
    end;

    local procedure UpdateXmlFileBasedOnNames(var XMLBuffer: Record "XML Buffer"; NameToSearch: Text[250]; ValueToUse: Text[250])
    begin
        XMLBuffer.SetFilter(Name, NameToSearch);
        XMLBuffer.FindFirst();
        XMLBuffer.Validate(Value, ValueToUse);
        XMLBuffer.Modify(true);
    end;

    local procedure FormatDate(Date: Date): Text[250]
    begin
        exit(Format(Date, 0, '20<Year,2>-<Month,2>-<Day,2>T00:00:00'));
    end;

    local procedure UpdateSetupForBankAndExport(var GenJournalLine: Record "Gen. Journal Line"; var RemittanceAccount: Record "Remittance Account"; var DocumentNo: Code[20]; Vendor: Record Vendor; var BatchName: Code[10]; var Amount: Decimal)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentDocNo: Code[20];
    begin
        RemittanceAccount.Validate("Document No. Series", CreateNoSeriesWithLongDocNos());
        RemittanceAccount.Modify(true);
        DocumentNo := LibraryUtility.GetNextNoFromNoSeries(RemittanceAccount."Document No. Series", WorkDate());

        // Prepare to export the remittance file
        BatchName := LibraryRemittance.PostGenJournalLine(GenJournalLine);
        PaymentDocNo := UpdateGenJnlBatchNoSeries(GenJournalLine);
        Commit();
        LibraryRemittance.ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", RemittanceAccount."Account No.");
        VendorBankAccount.Reset();
        VendorBankAccount.SetFilter("Bank Account No.", Vendor."Recipient Bank Account No.");
        VendorBankAccount.FindFirst();
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        // Document No is taken from Gen. Journal Batch No. Series. (TFS 230901)
        GenJournalLine.TestField("Document No.", PaymentDocNo);
        GenJournalLine.Modify(true);

        // Execute Export Payments
        SEPACTExportFile.EnableExportToServerFile();
        SEPACTExportFile.Run(GenJournalLine);

        // Verify the payment line created by the suggestion is deleted
        Assert.IsFalse(GenJournalLine.FindFirst(), 'Payment line found.');

        // Generate the Bank Payment file
        // Suprisingly report is ignoring amount from the file
        // We are also summing the values but there is no check on the sum
        Amount := GenJournalLine.Amount;
    end;

    local procedure UpdateWorkdate(NewDate: Date) OldDate: Date
    begin
        OldDate := WorkDate();
        WorkDate := NewDate;
        if Date2DWY(NewDate, 1) in [6, 7] then // "Posting Date" and "Pmt. Discount Date" compared works date in CU 15000001
            WorkDate := WorkDate() + 2;
    end;

    local procedure MockWaitingJournal(var WaitingJournal: Record "Waiting Journal"; var GenJournalLine: Record "Gen. Journal Line")
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
    begin
        CreateRemittanceAccountWithAgreement(RemittanceAccount, RemittanceAgreement);
        CreateGenJnlBatchWithTemplate(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryRemittance.CreateGenJournalLine(GenJournalLine, GenJournalBatch, Vendor, RemittanceAgreement, '');
        WaitingJournal.Init();
        WaitingJournal."Remittance Account Code" := RemittanceAccount.Code;
        WaitingJournal."Remittance Agreement Code" := RemittanceAccount."Remittance Agreement Code";
        WaitingJournal."Dimension Set ID" := LibraryRandom.RandIntInRange(10, 100);
        WaitingJournal."Remittance Status" := WaitingJournal."Remittance Status"::Sent;
        WaitingJournal."Journal Template Name" := GenJournalBatch."Journal Template Name";
        WaitingJournal."Journal Batch Name" := GenJournalBatch.Name;
        WaitingJournal."Account No." := LibraryPurchase.CreateVendorNo();
        WaitingJournal."SEPA Msg. ID" := LibraryUtility.GenerateGUID();
        WaitingJournal."SEPA Instr. ID" := LibraryUtility.GenerateGUID();
        WaitingJournal."SEPA End To End ID" := LibraryUtility.GenerateGUID();
        WaitingJournal."SEPA Payment Inf ID" := LibraryUtility.GenerateGUID();
        WaitingJournal.Insert();
    end;

    local procedure MockWaitingJournalWithAmounts(var WaitingJournal: Record "Waiting Journal"; var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; Amount: Decimal; AmountLCY: Decimal)
    begin
        MockWaitingJournal(WaitingJournal, GenJournalLine);
        UpdateWaitingJournalCurrencyAndAmount(WaitingJournal, CurrencyCode, CurrencyFactor, Amount, AmountLCY);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.DeleteAll();
    end;

    local procedure MockTwoWaitingJournalsWithAmounts(var WaitingJournal: array[2] of Record "Waiting Journal"; var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; CurrencyFactor: array[2] of Decimal; Amount: array[2] of Decimal; AmountLCY: array[2] of Decimal)
    var
        i: Integer;
    begin
        MockWaitingJournal(WaitingJournal[1], GenJournalLine);
        for i := 2 to ARRAYLEN(WaitingJournal) do begin
            WaitingJournal[i] := WaitingJournal[1];
            WaitingJournal[i].Reference += 1;
            WaitingJournal[i]."SEPA Msg. ID" := LibraryUtility.GenerateGUID();
            WaitingJournal[i].Insert();
        end;
        for i := 1 to ARRAYLEN(WaitingJournal) do
            UpdateWaitingJournalCurrencyAndAmount(WaitingJournal[i], CurrencyCode, CurrencyFactor[i], Amount[i], AmountLCY[i]);
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.DeleteAll();
    end;

    local procedure CreateRemittanceAccountWithAgreement(var RemittanceAccount: Record "Remittance Account"; var RemittanceAgreement: Record "Remittance Agreement")
    begin
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::BBS);
        LibraryRemittance.CreatedomesticRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount);
        RemittanceAccount."Document No. Series" := LibraryERM.CreateNoSeriesCode();
        RemittanceAccount.Modify();
    end;

    local procedure CreateGenJnlBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure UpdateGenJnlBatchNoSeries(GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
        exit(LibraryUtility.GetNextNoFromNoSeries(GenJournalBatch."No. Series", WorkDate()));
    end;

    local procedure InvokeUpdateWaitingJournal(WaitingJournal: Record "Waiting Journal"; GenJournalLine: Record "Gen. Journal Line")
    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        LatestRemittanceAccount: Record "Remittance Account";
        LatestRemittanceAgreement: Record "Remittance Agreement";
        ImportSEPACommon: Codeunit "Import SEPA Common";
        MappedTransactionStatus: Option Approved,Settled,Rejected,Pending;
        AccountCurrency: Code[10];
        NumberApproved: Integer;
        NumberSettled: Integer;
        NumberRejected: Integer;
        TransDocumentNo: Code[20];
        BalanceEntryAmountLCY: Decimal;
        MoreReturnJournals: Boolean;
        First: Boolean;
        LatestDate: Date;
        LatestVend: Code[20];
        LatestCurrencyCode: Code[10];
        CreateNewDocumentNo: Boolean;
        BalanceEntryAmount: Decimal;
    begin
        ImportSEPACommon.UpdateWaitingJournal(
          WaitingJournal, MappedTransactionStatus::Settled, '', '', RemittancePaymentOrder,
          WorkDate(), GenJournalLine, AccountCurrency, NumberApproved, NumberSettled, NumberRejected,
          TransDocumentNo, BalanceEntryAmountLCY, MoreReturnJournals, First, LatestDate, LatestVend, LatestRemittanceAccount,
          LatestRemittanceAgreement, LatestCurrencyCode, CreateNewDocumentNo, false, BalanceEntryAmount);
    end;

    local procedure ModifyAmounts(var Amount: Decimal; var AmountLCY: Decimal; var CurrencyFactor: Decimal)
    begin
        Amount := Amount * LibraryRandom.RandIntInRange(3, 5);
        AmountLCY := AmountLCY * LibraryRandom.RandIntInRange(6, 8);
        CurrencyFactor := Amount / AmountLCY;
    end;

    local procedure EnqueueConfirmImport(FilePath: Text; Approved: Integer; Rejected: Integer; Settled: Integer; ConfirmTheImport: Boolean)
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmImportQst, FileMgt.GetFileName(FilePath), Approved, Rejected, Settled));
        LibraryVariableStorage.Enqueue(ConfirmTheImport);
    end;

    local procedure EnqueueConfirmImportWithDiffExchRate(ConfirmTheImport: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ConfirmImportExchRateQst);
        LibraryVariableStorage.Enqueue(ConfirmTheImport);
    end;

    local procedure ImportAndHandleCAMT054File(GenJournalLine: Record "Gen. Journal Line"; FileName: Text)
    var
        ImportCAMT054: Codeunit "Import CAMT054";
    begin
        ImportCAMT054.ImportAndHandleCAMT054File(GenJournalLine, COPYSTR(FileName, 1, 250), '');
    end;

    local procedure AddToNameValueBuffer(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Name: Text)
    begin
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID += 1;
        TempNameValueBuffer.Name := CopyStr(Name, 1, MaxStrLen(TempNameValueBuffer.Name));
        TempNameValueBuffer.Insert();
    end;

    local procedure VerifyImportedLinesInternational(BatchName: Code[10]; TemplateName: Code[10]; ExtDocumentNo: Code[35]; PostingDate: Date; DocumentNo: Code[20]; VendorAccountNo: Code[20]; RemittanceAccount: Record "Remittance Account"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(2, GenJournalLine.Count, 'Number of imported lines not correct'); // was 4 for bank because of commission and rounding lines
        GenJournalLine.Find('-');

        VerifyPaymentLine(GenJournalLine, PostingDate, DocumentNo, VendorAccountNo, Amount, ExtDocumentNo);

        GenJournalLine.Next();

        VerifyBalancingLine(GenJournalLine, PostingDate, DocumentNo, RemittanceAccount."Account No.", -Amount);
    end;

    local procedure VerifyNoLinesAreImported(BatchName: Code[10]; TemplateName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        Assert.AreEqual(0, GenJournalLine.Count, 'There should be no lines created');
    end;

    local procedure VerifyPaymentLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal; ExtDocumentNo: Code[35])
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, DocumentNo, AccountNo, Amount);

        Assert.AreEqual(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type", 'Document Type was set to wrong value');
        Assert.AreEqual(ExtDocumentNo, GenJournalLine."External Document No.", 'External document no was set to a wrong value');
        Assert.AreEqual(
          GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual(ExtDocumentNo, GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. was not set to a correct value');
        Assert.AreEqual(true, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Applies-to Doc. Type",
          'Applies-to Doc. Type was not set to correct value');
    end;

    local procedure VerifyBalancingLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    begin
        VerifyGenJournalLine(GenJournalLine, PostingDate, DocumentNo, AccountNo, Amount);

        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
        Assert.AreEqual('', GenJournalLine."External Document No.", 'External document No. should be blank');
        Assert.AreEqual(
          GenJournalLine."Account Type"::"Bank Account",
          GenJournalLine."Account Type",
          'Account type was not set to a correct value');
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. should be blank');
        Assert.AreEqual(false, GenJournalLine.IsApplied(), 'IsApplied was not set to a correct value');
        Assert.AreEqual(
          GenJournalLine."Applies-to Doc. Type"::" ", GenJournalLine."Applies-to Doc. Type",
          'Applies-to Doc. Type was not set to correct value');
    end;

    local procedure VerifyGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    begin
        Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", 'Posting date was not set to a correct value');
        Assert.AreEqual(DocumentNo, GenJournalLine."Document No.", 'Wrong document no. was set to the line');
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'Account no was not set to a correct value');
        Assert.AreEqual(Amount, GenJournalLine.Amount, 'Amount was not set to a correct value');
        Assert.AreEqual(false, GenJournalLine."Has Payment Export Error", 'Has payment export error was not set to correct value');
    end;

    local procedure VerifyDimSetIDGenJnlLine(WaitingJournal: Record "Waiting Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", WaitingJournal."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", WaitingJournal."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", WaitingJournal."Account No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Dimension Set ID", WaitingJournal."Dimension Set ID");
    end;

    local procedure VerifyWaitingJournal(WaitingJournal: Record "Waiting Journal"; ExpectedCurrencyCode: Code[10]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal; ExpectedCurrencyFactor: Decimal)
    begin
        WaitingJournal.Find();
        WaitingJournal.TestField("Currency Code", ExpectedCurrencyCode);
        WaitingJournal.TestField(Amount, ExpectedAmount);
        WaitingJournal.TestField("Amount (LCY)", ExpectedAmountLCY);
        Assert.AreNearlyEqual(ExpectedCurrencyFactor, WaitingJournal."Currency Factor", 0.000000000000001, '');
    end;

    local procedure VerifyGenJnlAfterDiffExchRateImport(WaitingJournal: Record "Waiting Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        WaitingJournal.Find();
        GenJournalLine.SetRange("Journal Template Name", WaitingJournal."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", WaitingJournal."Journal Batch Name");
        Assert.AreEqual(2, GenJournalLine.COUNT, 'expected 2 gen. jnl. lines after camt054 file import');
        // Payment:
        GenJournalLine.FindSet();
        VerifyGenJournalLineAmounts(GenJournalLine, WaitingJournal."Currency Code", WaitingJournal.Amount, WaitingJournal."Amount (LCY)", WaitingJournal."Currency Factor");
        // Balance:
        GenJournalLine.Next();
        VerifyGenJournalLineAmounts(GenJournalLine, '', -WaitingJournal."Amount (LCY)", -WaitingJournal."Amount (LCY)", 0);
    end;

    local procedure VerifyGenJnlAfterDiffExchRateTwoPmtImport(WaitingJournal: array[2] of Record "Waiting Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
        totalAmountLCY: Decimal;
    begin
        WaitingJournal[1].Find();
        WaitingJournal[2].Find();

        GenJournalLine.SetRange("Journal Template Name", WaitingJournal[1]."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", WaitingJournal[1]."Journal Batch Name");
        Assert.AreEqual(3, GenJournalLine.COUNT, 'expected 3 gen. jnl. lines after camt054 file import with 2 paymets');

        // Payment:
        GenJournalLine.FindSet();
        VerifyGenJournalLineAmounts(GenJournalLine, WaitingJournal[1]."Currency Code", WaitingJournal[1].Amount, WaitingJournal[1]."Amount (LCY)", WaitingJournal[1]."Currency Factor");
        GenJournalLine.Next();
        VerifyGenJournalLineAmounts(GenJournalLine, WaitingJournal[2]."Currency Code", WaitingJournal[2].Amount, WaitingJournal[2]."Amount (LCY)", WaitingJournal[2]."Currency Factor");

        // Balance:
        GenJournalLine.Next();
        totalAmountLCY := -(WaitingJournal[1]."Amount (LCY)" + WaitingJournal[2]."Amount (LCY)");
        VerifyGenJournalLineAmounts(GenJournalLine, '', totalAmountLCY, totalAmountLCY, 0);
    end;

    local procedure VerifyGenJournalLineAmounts(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal; CurrencyFactor: Decimal)
    begin
        GenJournalLine.TestField("Currency Code", CurrencyCode);
        GenJournalLine.TestField(Amount, ExpectedAmount);
        GenJournalLine.TestField("Amount (LCY)", ExpectedAmountLCY);
        Assert.AreNearlyEqual(CurrencyFactor, GenJournalLine."Currency Factor", 0.000000000000001, '');
    end;

    local procedure WritePainFileToDisk(Destination: Text)
    var
        OutFile: File;
        OutStream: OutStream;
    begin
        OutFile.TextMode(true);
        OutFile.Create(Destination);
        OutFile.CreateOutStream(OutStream);

        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(OutStream, '<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.002.001.03">');
        WriteLine(OutStream, '  <CstmrPmtStsRpt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>XML990920160222150337602</MsgId>');
        WriteLine(OutStream, '      <CreDtTm>2019-01-22T14:03:37Z</CreDtTm>');
        WriteLine(OutStream, '      <InitgPty>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <OrgId>');
        WriteLine(OutStream, '            <Othr>');
        WriteLine(OutStream, '              <Id>NDEATEST</Id>');
        WriteLine(OutStream, '              <SchmeNm>');
        WriteLine(OutStream, '                <Cd>BANK</Cd>');
        WriteLine(OutStream, '              </SchmeNm>');
        WriteLine(OutStream, '            </Othr>');
        WriteLine(OutStream, '            <Othr>');
        WriteLine(OutStream, '              <Id>7771627073</Id>');
        WriteLine(OutStream, '              <SchmeNm>');
        WriteLine(OutStream, '                <Cd>CUST</Cd>');
        WriteLine(OutStream, '              </SchmeNm>');
        WriteLine(OutStream, '            </Othr>');
        WriteLine(OutStream, '          </OrgId>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </InitgPty>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <OrgnlGrpInfAndSts>');
        WriteLine(OutStream, '      <OrgnlMsgId>1037</OrgnlMsgId>');
        WriteLine(OutStream, '      <OrgnlMsgNmId>pain.001.001.03</OrgnlMsgNmId>');
        WriteLine(OutStream, '    </OrgnlGrpInfAndSts>');
        WriteLine(OutStream, '    <OrgnlPmtInfAndSts>');
        WriteLine(OutStream, '      <OrgnlPmtInfId>1037/1</OrgnlPmtInfId>');
        WriteLine(OutStream, '      <TxInfAndSts>');
        WriteLine(OutStream, '        <OrgnlInstrId>G04001</OrgnlInstrId>');
        WriteLine(OutStream, '        <OrgnlEndToEndId>1037/1</OrgnlEndToEndId>');
        WriteLine(OutStream, '        <TxSts>ACSC</TxSts>');
        WriteLine(OutStream, '        <StsRsnInf>');
        WriteLine(OutStream, '          <Rsn>');
        WriteLine(OutStream, '            <Cd>DT06</Cd>');
        WriteLine(OutStream, '          </Rsn>');
        WriteLine(OutStream, '          <AddtlInf>Info</AddtlInf>');
        WriteLine(OutStream, '        </StsRsnInf>');
        WriteLine(OutStream, '      </TxInfAndSts>        ');
        WriteLine(OutStream, '    </OrgnlPmtInfAndSts>');
        WriteLine(OutStream, '  </CstmrPmtStsRpt>');
        WriteLine(OutStream, '</Document>');
        OutFile.Close();
    end;

    local procedure WritePainFileCustStatusInfoToDisk(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Destination: Text)
    var
        OutFile: File;
        OutStream: OutStream;
    begin
        OutFile.TextMode(true);
        OutFile.Create(Destination);
        OutFile.CreateOutStream(OutStream);

        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(OutStream, '<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.002.001.03">');
        WriteLine(OutStream, '  <CstmrPmtStsRpt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>XML990920160222150337602</MsgId>');
        WriteLine(OutStream, '      <CreDtTm>2019-01-22T14:03:37Z</CreDtTm>');
        WriteLine(OutStream, '      <InitgPty>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <OrgId>');
        WriteLine(OutStream, '            <Othr>');
        WriteLine(OutStream, '              <Id>NDEATEST</Id>');
        WriteLine(OutStream, '              <SchmeNm>');
        WriteLine(OutStream, '                <Cd>BANK</Cd>');
        WriteLine(OutStream, '              </SchmeNm>');
        WriteLine(OutStream, '            </Othr>');
        WriteLine(OutStream, '            <Othr>');
        WriteLine(OutStream, '              <Id>7771627073</Id>');
        WriteLine(OutStream, '              <SchmeNm>');
        WriteLine(OutStream, '                <Cd>CUST</Cd>');
        WriteLine(OutStream, '              </SchmeNm>');
        WriteLine(OutStream, '            </Othr>');
        WriteLine(OutStream, '          </OrgId>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </InitgPty>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <OrgnlGrpInfAndSts>');
        WriteLine(OutStream, '      <OrgnlMsgId>1037</OrgnlMsgId>');
        WriteLine(OutStream, '      <OrgnlMsgNmId>pain.001.001.03</OrgnlMsgNmId>');
        WriteLine(OutStream, '    </OrgnlGrpInfAndSts>');
        WriteLine(OutStream, '    <OrgnlPmtInfAndSts>');
        WriteLine(OutStream, '      <OrgnlPmtInfId>1037/1</OrgnlPmtInfId>');
        WriteLine(OutStream, '      <TxInfAndSts>');
        WriteLine(OutStream, '        <OrgnlInstrId>G04001</OrgnlInstrId>');
        WriteLine(OutStream, '        <OrgnlEndToEndId>1037/1</OrgnlEndToEndId>');
        WriteLine(OutStream, '        <TxSts>ACSC</TxSts>');
        TempNameValueBuffer.FindSet();
        repeat
            WriteLine(OutStream, TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next() = 0;
        WriteLine(OutStream, '      </TxInfAndSts>        ');
        WriteLine(OutStream, '    </OrgnlPmtInfAndSts>');
        WriteLine(OutStream, '  </CstmrPmtStsRpt>');
        WriteLine(OutStream, '</Document>');
        OutFile.Close();
    end;

    local procedure WriteCamtFiletoDisk(WaitingJournal: Record "Waiting Journal"; Date: Date; Sts: Text): Text
    var
        OutFile: File;
        OutStream: OutStream;
        ServerFileName: Text;
    begin
        ServerFileName := FileMgt.ServerTempFileName('xml');
        OutFile.TextMode(true);
        OutFile.Create(ServerFileName);
        OutFile.CreateOutStream(OutStream);
        WriteCamtFile_StartFile(OutStream);
        WriteCamtFile_StartEntry(OutStream, WaitingJournal, Date, Sts);
        WriteCamtFile_AmountDetails_EUR(OutStream);
        WriteCamtFile_FinishEntry(OutStream);
        WriteCamtFile_FinishFile(OutStream);
        OutFile.Close();
        exit(GetClientFileFromServerFile());
    end;

    local procedure WriteCamtFiletoDiskWithCustomAmountDetails(WaitingJournal: Record "Waiting Journal"; SrcCcy: Text; TrgtCcy: Text; XchgRate: Decimal; SrcAmt: Decimal; TrgtAmt: Decimal): Text
    var
        OutFile: File;
        OutStream: OutStream;
        ServerFileName: Text;
    begin
        ServerFileName := FileMgt.ServerTempFileName('xml');
        OutFile.TextMode(true);
        OutFile.Create(ServerFileName);
        OutFile.CreateOutStream(OutStream);
        WriteCamtFile_StartFile(OutStream);
        WriteCamtFile_StartEntry(OutStream, WaitingJournal, WorkDate(), 'BOOK');
        WriteCamtFile_AmountDetails_Custom(OutStream, SrcCcy, TrgtCcy, 1 / XchgRate, SrcAmt, TrgtAmt);
        WriteCamtFile_FinishEntry(OutStream);
        WriteCamtFile_FinishFile(OutStream);
        OutFile.Close();
        exit(GetClientFileFromServerFile());
    end;

    local procedure WriteCamtFiletoDiskWithTwoCustomAmountDetails(WaitingJournal: array[2] of Record "Waiting Journal"; SrcCcy: Text; TrgtCcy: Text; XchgRate: array[2] of Decimal; SrcAmt: array[2] of Decimal; TrgtAmt: array[2] of Decimal): Text
    var
        OutFile: File;
        OutStream: OutStream;
        ServerFileName: Text;
        i: Integer;
    begin
        ServerFileName := FileMgt.ServerTempFileName('xml');
        OutFile.TextMode(true);
        OutFile.Create(ServerFileName);
        OutFile.CreateOutStream(OutStream);
        WriteCamtFile_StartFile(OutStream);

        for i := 1 to ARRAYLEN(WaitingJournal) do begin
            WriteCamtFile_StartEntry(OutStream, WaitingJournal[i], WorkDate(), 'BOOK');
            WriteCamtFile_AmountDetails_Custom(OutStream, SrcCcy, TrgtCcy, 1 / XchgRate[i], SrcAmt[i], TrgtAmt[i]);
            WriteCamtFile_FinishEntry(OutStream);
        end;

        WriteCamtFile_FinishFile(OutStream);
        OutFile.Close();
        exit(GetClientFileFromServerFile());
    end;

    local procedure WriteCamtFile_StartFile(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
        WriteLine(OutStream, '<Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.02">');
        WriteLine(OutStream, '    <BkToCstmrDbtCdtNtfctn>');
        WriteLine(OutStream, '        <GrpHdr>');
        WriteLine(OutStream, '            <MsgId>XML990920161031126389571</MsgId>');
        WriteLine(OutStream, '            <CreDtTm>2016-10-31T08:30:56Z</CreDtTm>');
        WriteLine(OutStream, '            <MsgRcpt>');
        WriteLine(OutStream, '                <Id>');
        WriteLine(OutStream, '                    <OrgId>');
        WriteLine(OutStream, '                        <Othr>');
        WriteLine(OutStream, '                            <Id>NDEATEST</Id>');
        WriteLine(OutStream, '                            <SchmeNm>');
        WriteLine(OutStream, '                                <Cd>BANK</Cd>');
        WriteLine(OutStream, '                            </SchmeNm>');
        WriteLine(OutStream, '                        </Othr>');
        WriteLine(OutStream, '                        <Othr>');
        WriteLine(OutStream, '                            <Id>00911071991</Id>');
        WriteLine(OutStream, '                            <SchmeNm>');
        WriteLine(OutStream, '                                <Cd>CUST</Cd>');
        WriteLine(OutStream, '                            </SchmeNm>');
        WriteLine(OutStream, '                        </Othr>');
        WriteLine(OutStream, '                    </OrgId>');
        WriteLine(OutStream, '                </Id>');
        WriteLine(OutStream, '            </MsgRcpt>');
        WriteLine(OutStream, '            <AddtlInf>/DEBT/</AddtlInf>');
        WriteLine(OutStream, '        </GrpHdr>');
        WriteLine(OutStream, '        <Ntfctn>');
        WriteLine(OutStream, '            <Id>2016-10-31-08.30.56-EUR7054</Id>');
        WriteLine(OutStream, '            <CreDtTm>2019-01-22T08:30:56Z</CreDtTm>');
        WriteLine(OutStream, '            <Acct>');
        WriteLine(OutStream, '                <Id>');
        WriteLine(OutStream, '                    <IBAN>NO2960730447054</IBAN>');
        WriteLine(OutStream, '                </Id>');
        WriteLine(OutStream, '                <Ccy>EUR</Ccy>');
        WriteLine(OutStream, '                <Svcr>');
        WriteLine(OutStream, '                    <FinInstnId>');
        WriteLine(OutStream, '                        <BIC>NDEANOKK</BIC>');
        WriteLine(OutStream, '                        <PstlAdr>');
        WriteLine(OutStream, '                            <Ctry>NO</Ctry>');
        WriteLine(OutStream, '                        </PstlAdr>');
        WriteLine(OutStream, '                    </FinInstnId>');
        WriteLine(OutStream, '                </Svcr>');
        WriteLine(OutStream, '            </Acct>');
    end;

    local procedure WriteCamtFile_StartEntry(var OutStream: OutStream; WaitingJournal: Record "Waiting Journal"; Date: Date; Sts: Text)
    begin
        WriteLine(OutStream, '            <Ntry>');
        WriteLine(OutStream, '                <NtryRef>1</NtryRef>');
        WriteLine(OutStream, '                <Amt Ccy="EUR">65400.00</Amt>');
        WriteLine(OutStream, '                <CdtDbtInd>DBIT</CdtDbtInd>');
        WriteLine(OutStream, StrSubstNo('                <Sts>%1</Sts>', Sts));
        WriteLine(OutStream, '                <BookgDt>');
        WriteLine(OutStream, StrSubstNo('                    <Dt>%1</Dt>', forMAT(Date, 0, 9)));
        WriteLine(OutStream, '                </BookgDt>');
        WriteLine(OutStream, '                <ValDt>');
        WriteLine(OutStream, '                    <Dt>2016-10-31</Dt>');
        WriteLine(OutStream, '                </ValDt>');
        WriteLine(OutStream, '                <BkTxCd>');
        WriteLine(OutStream, '                    <Domn>');
        WriteLine(OutStream, '                        <Cd>PMNT</Cd>');
        WriteLine(OutStream, '                        <Fmly>');
        WriteLine(OutStream, '                            <Cd>ICDT</Cd>');
        WriteLine(OutStream, '                            <SubFmlyCd>XBCT</SubFmlyCd>');
        WriteLine(OutStream, '                        </Fmly>');
        WriteLine(OutStream, '                    </Domn>');
        WriteLine(OutStream, '                </BkTxCd>');
        WriteLine(OutStream, '                <NtryDtls>');
        WriteLine(OutStream, '                    <TxDtls>');
        WriteLine(OutStream, '                        <Refs>');
        WriteLine(OutStream, StrSubstNo('                            <MsgId>%1</MsgId>', WaitingJournal."SEPA Msg. ID"));
        WriteLine(OutStream, '                            <AcctSvcrRef>Blah</AcctSvcrRef>');
        WriteLine(OutStream, StrSubstNo('                            <PmtInfId>%1</PmtInfId>', WaitingJournal."SEPA Payment Inf ID"));
        WriteLine(OutStream, StrSubstNo('                            <InstrId>%1</InstrId>', WaitingJournal."SEPA Instr. ID"));
        WriteLine(OutStream, StrSubstNo('                            <EndToEndId>%1</EndToEndId>', WaitingJournal."SEPA End To End ID"));
        WriteLine(OutStream, '                        </Refs>');
    end;

    local procedure WriteCamtFile_AmountDetails_EUR(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '                        <AmtDtls>');
        WriteLine(OutStream, '                            <InstdAmt>');
        WriteLine(OutStream, '                                <Amt Ccy="EUR">65400.00</Amt>');
        WriteLine(OutStream, '                            </InstdAmt>');
        WriteLine(OutStream, '                            <TxAmt>');
        WriteLine(OutStream, '                                <Amt Ccy="EUR">65400.00</Amt>');
        WriteLine(OutStream, '                            </TxAmt>');
        WriteLine(OutStream, '                        </AmtDtls>');
    end;

    local procedure WriteCamtFile_AmountDetails_Custom(var OutStream: OutStream; SrcCcy: Text; TrgtCcy: Text; XchgRate: Decimal; SrcAmt: Decimal; TrgtAmt: Decimal)
    begin
        WriteLine(OutStream, '                        <AmtDtls>');
        WriteLine(OutStream, '                            <InstdAmt>');
        WriteLine(OutStream, StrSubstNo('                                <Amt Ccy="%1">%2</Amt>', SrcCcy, forMAT(SrcAmt, 0, 9)));
        WriteLine(OutStream, '                                <CcyXchg>');
        WriteLine(OutStream, StrSubstNo('                                    <SrcCcy>%1</SrcCcy>', SrcCcy));
        WriteLine(OutStream, StrSubstNo('                                    <TrgtCcy>%1</TrgtCcy>', TrgtCcy));
        WriteLine(OutStream, StrSubstNo('                                    <XchgRate>%1</XchgRate>', forMAT(XchgRate, 0, 9)));
        WriteLine(OutStream, '                                </CcyXchg>');
        WriteLine(OutStream, '                            </InstdAmt>');
        WriteLine(OutStream, '                            <TxAmt>');
        WriteLine(OutStream, StrSubstNo('                                <Amt Ccy="%1">%2</Amt>', TrgtCcy, forMAT(TrgtAmt, 0, 9)));
        WriteLine(OutStream, '                            </TxAmt>');
        WriteLine(OutStream, '                        </AmtDtls>');
    end;

    local procedure WriteCamtFile_FinishEntry(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '                        <BkTxCd>');
        WriteLine(OutStream, '                            <Domn>');
        WriteLine(OutStream, '                                <Cd>PMNT</Cd>');
        WriteLine(OutStream, '                                <Fmly>');
        WriteLine(OutStream, '                                    <Cd>ICDT</Cd>');
        WriteLine(OutStream, '                                    <SubFmlyCd>XBCT</SubFmlyCd>');
        WriteLine(OutStream, '                                </Fmly>');
        WriteLine(OutStream, '                            </Domn>');
        WriteLine(OutStream, '                        </BkTxCd>');
        WriteLine(OutStream, '                        <RltdPties>');
        WriteLine(OutStream, '                            <UltmtDbtr>');
        WriteLine(OutStream, '                                <Nm>J.S.Cock AS</Nm>');
        WriteLine(OutStream, '                                <PstlAdr>');
        WriteLine(OutStream, '                                    <StrtNm>Nedre Rommen 3</StrtNm>');
        WriteLine(OutStream, '                                    <PstCd>0988</PstCd>');
        WriteLine(OutStream, '                                    <TwnNm>OSLO</TwnNm>');
        WriteLine(OutStream, '                                    <Ctry>NO</Ctry>');
        WriteLine(OutStream, '                                </PstlAdr>');
        WriteLine(OutStream, '                            </UltmtDbtr>');
        WriteLine(OutStream, '                            <Cdtr>');
        WriteLine(OutStream, '                                <Nm>Peter Kahlhorn</Nm>');
        WriteLine(OutStream, '                                <PstlAdr>');
        WriteLine(OutStream, '                                    <StrtNm>Waaler Strasse 5</StrtNm>');
        WriteLine(OutStream, '                                    <PstCd>DE-86807</PstCd>');
        WriteLine(OutStream, '                                    <TwnNm>BUCHLOE</TwnNm>');
        WriteLine(OutStream, '                                    <Ctry>DE</Ctry>');
        WriteLine(OutStream, '                                </PstlAdr>');
        WriteLine(OutStream, '                            </Cdtr>');
        WriteLine(OutStream, '                            <CdtrAcct>');
        WriteLine(OutStream, '                                <Id>');
        WriteLine(OutStream, '                                    <IBAN>DE23700100800909428807</IBAN>');
        WriteLine(OutStream, '                                </Id>');
        WriteLine(OutStream, '                                <Ccy>EUR</Ccy>');
        WriteLine(OutStream, '                            </CdtrAcct>');
        WriteLine(OutStream, '                            <UltmtCdtr>');
        WriteLine(OutStream, '                                <Nm>Peter Kahlhorn</Nm>');
        WriteLine(OutStream, '                                <PstlAdr>');
        WriteLine(OutStream, '                                    <StrtNm>Waaler Strasse 5</StrtNm>');
        WriteLine(OutStream, '                                    <PstCd>DE-86807</PstCd>');
        WriteLine(OutStream, '                                    <TwnNm>BUCHLOE</TwnNm>');
        WriteLine(OutStream, '                                    <Ctry>DE</Ctry>');
        WriteLine(OutStream, '                                    <AdrLine>Waaler Strasse 5</AdrLine>');
        WriteLine(OutStream, '                                </PstlAdr>');
        WriteLine(OutStream, '                            </UltmtCdtr>');
        WriteLine(OutStream, '                        </RltdPties>');
        WriteLine(OutStream, '                        <RltdAgts>');
        WriteLine(OutStream, '                            <DbtrAgt>');
        WriteLine(OutStream, '                                <FinInstnId>');
        WriteLine(OutStream, '                                    <BIC>NDEANOKK</BIC>');
        WriteLine(OutStream, '                                    <PstlAdr>');
        WriteLine(OutStream, '                                        <Ctry>NO</Ctry>');
        WriteLine(OutStream, '                                    </PstlAdr>');
        WriteLine(OutStream, '                                </FinInstnId>');
        WriteLine(OutStream, '                            </DbtrAgt>');
        WriteLine(OutStream, '                            <CdtrAgt>');
        WriteLine(OutStream, '                                <FinInstnId>');
        WriteLine(OutStream, '                                    <BIC>PBNKDEFF700</BIC>');
        WriteLine(OutStream, '                                    <Nm>Commerzbank</Nm>');
        WriteLine(OutStream, '                                    <PstlAdr>');
        WriteLine(OutStream, '                                        <Ctry>DE</Ctry>');
        WriteLine(OutStream, '                                    </PstlAdr>');
        WriteLine(OutStream, '                                </FinInstnId>');
        WriteLine(OutStream, '                            </CdtrAgt>');
        WriteLine(OutStream, '                        </RltdAgts>');
        WriteLine(OutStream, '                        <RmtInf>');
        WriteLine(OutStream, '                            <Ustrd>Payment of Faktura 437525 </Ustrd>');
        WriteLine(OutStream, '                        </RmtInf>');
        WriteLine(OutStream, '                    </TxDtls>');
        WriteLine(OutStream, '                </NtryDtls>');
        WriteLine(OutStream, '            </Ntry>');
    end;

    local procedure WriteCamtFile_FinishFile(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '        </Ntfctn>');
        WriteLine(OutStream, '    </BkToCstmrDbtCdtNtfctn>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure VerifyReturnError(WaitingJournalReference: Integer; ExpectedMessageText: Text)
    var
        ReturnError: Record "Return Error";
    begin
        ReturnError.SetRange("Waiting Journal Reference", WaitingJournalReference);
        ReturnError.FindFirst();
        ReturnError.TestField("Message Text", ExpectedMessageText);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportRemittancePaymentOrderRequestPageHandler(var RemPaymentOrderImport: TestRequestPage "Rem. payment order - import")
    var
        IsControlBatch: Variant;
    begin
        LibraryVariableStorage.Dequeue(IsControlBatch);

        // Control108003 is Control Batch filed
        RemPaymentOrderImport.ControlBatch.SetValue(IsControlBatch);
        RemPaymentOrderImport.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentOrderSettlStatusHandler(var PaymentOrderSettlStatus: TestPage "Payment Order - Settl. Status")
    begin
        // Page is not testable
        PaymentOrderSettlStatus.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ImportPaymentsConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LowerCase(LibraryVariableStorage.DequeueText()), LowerCase(Question));
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RemittanceMessageHandler(Message: Text)
    var
        v: Variant;
        Expected: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(v);
        Expected := v;
        Assert.AreEqual(Expected, Message, 'Wrong Message');
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

    local procedure Cleanup(OldDate: Date)
    begin
        UpdateWorkdate(OldDate);
    end;
}

