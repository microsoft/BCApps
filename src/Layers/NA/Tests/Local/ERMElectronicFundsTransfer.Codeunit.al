codeunit 142083 "ERM Electronic Funds Transfer"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment] [Journal] [EFT]
    end;

    var
        TempACHRBHeader: Record "ACH RB Header" temporary;
        TempACHRBDetail: Record "ACH RB Detail" temporary;
        TempACHRBFooter: Record "ACH RB Footer" temporary;
        TempACHUSHeader: Record "ACH US Header" temporary;
        TempACHUSDetail: Record "ACH US Detail" temporary;
        TempACHUSFooter: Record "ACH US Footer" temporary;
        TempACHCecobanHeader: Record "ACH Cecoban Header" temporary;
        TempACHCecobanDetail: Record "ACH Cecoban Detail" temporary;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        EntryStatusErr: Label 'Entry Status must be equal to ''Posted''  in Check Ledger Entry: Entry No.';
        MyBalCaptionTxt: Label 'myBal';
        TempPathTxt: Label '.\', Comment = 'Path';
        TransitNoTxt: Label '095021007';
        FederalIDNoErr: Label 'Federal ID No. must have a value in Company Information';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        FileMgt: Codeunit "File Management";
        TempSubDirectoryTxt: Label '142083_Test\';
        "Layout": Option RDLC,Word;
        AmountVerificationMsg: Label 'Amount must be equal.';
        NoOfRecordsErr: Label 'No of records must be same.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        NoExportDiffCurrencyErr: Label 'You cannot export journal entries if Currency Code is different in Gen. Journal Line and Bank Account.';
        EFTExportGenJnlLineErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        MandatoryDimErr: Label 'Select a %1 for the %2 %3 for %4 %5.';
        RemitAdvFileNotFoundTxt: Label 'Remittance Advice file has not been found';
        ForceDocBalanceFalseQst: Label 'Warning:  Transactions cannot be financially voided when Force Doc. Balance is set to No';
        CheckExportedErr: Label 'Check Exported must be true.';
        DocumentNoBlankErr: Label 'Document No. must be blank.';
        AppliedIsTrueErr: Label 'Applied(Yes/No) must be Yes.';
        VendorLedgLedgerErr: Label '%1 must be exist.', Comment = '%=1 Table Caption';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalAfterPostPurchaseOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify XML Data after Export Electronic Payment Journal.
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Export the Payment
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN]  Verify XML Data.
        GenJournalLine.Find();

        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Gen__Journal_Line___Applies_to_Doc__No__', GenJournalLine."Applies-to Doc. No.");
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalAfterPostPurchaseOrderWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export the Payment
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] Make sure Exported to Payment File is set in the Gen Journal Line
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create one payment journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Try and export it twice
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] No message is given they will need to void the trx and reenter
        GenJournalLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalTwiceWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create one payment journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Try and export it twice
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] No message is given they will need to void the trx and reenter
        GenJournalLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnVoidCheckWithExportedEntryStatus()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgEntry: Record "Check Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export the Payment Journal try to void the check
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        asserterror VoidCheckCheckLedgerEntries(GenJournalLine."Bal. Account No.");

        // [THEN] Verify Void Check error and verify Entry Status is Exported.
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", true);
        Assert.ExpectedTestFieldError(CheckLedgEntry.FieldCaption("Entry Status"), Format(CheckLedgEntry."Entry Status"::Posted));
        Assert.ExpectedError(EntryStatusErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnBlankFederalIDNoAfterExportPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify Error after Export Electronic Payment Journal when Federal ID No is blank on Company Information.
        // [GIVEN] Create Electonic Payment Journal and set Federal ID No to blank.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        ModifyFederalIdCompanyInformation('');  // Federal ID No as blank.
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Try to Export Payment Journal
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that it did not get exported and we recieved an error from no Federal ID
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", false);
        Assert.ExpectedError(FederalIDNoErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        AccountNo: Code[20];
        CustomerBankAccountCode: Code[20];
    begin
        // Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [WHEN] Export Payment Journal
        // [THEN] Verify Account No. and Amount Paid on XML file.
        AccountNo := CreateCustomerBankAccountWithCustomer(true, CustomerBankAccountCode);
        ExportPaymentJournalAndVerifyXML(
          AccountNo, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Bal. Account Type"::Customer, CustomerBankAccountCode);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeCustomerWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Amount: Decimal;
        CustomerNo: Code[20];
        CustomerAccountBankCode: Code[10];
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);

        // [WHEN] Export Payment Journal
        // [THEN] Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CustomerNo := CreateCustomerBankAccountWithCustomer(true, CustomerAccountBankCode);
        CreateAndExportPaymentJournal(GenJournalLine."Document Type"::Payment,
          GenJournalLine."Bal. Account Type"::Customer, CustomerNo,
          Amount, CopyStr(LibraryUtility.GenerateGUID(), 1, 3), LibraryUtility.GenerateGUID(), false, CustomerAccountBankCode);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        FindAndUpdateVendorBankAccount(VendorBankAccount);

        // [WHEN] Export Payment Journal
        // [THEN] Verify XML after creating and exporting Electronic Payment Journal with Bal. Account Type as Vendor.
        ExportPaymentJournalAndVerifyXML(
          VendorBankAccount."Vendor No.", GenJournalLine."Document Type"::Payment,
          GenJournalLine."Bal. Account Type"::Vendor, VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithBalAccountTypeVendorWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Amount: Decimal;
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        FindAndUpdateVendorBankAccount(VendorBankAccount);

        // [WHEN] Export Payment Journal
        // [THEN] Verify Word Layout after creating and exporting Electronic Payment Journal with Bal. Account Type as Customer.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CreateAndExportPaymentJournal(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Bal. Account Type"::Vendor, VendorBankAccount."Vendor No.", Amount,
          CopyStr(LibraryUtility.GenerateGUID(), 1, 3), LibraryUtility.GenerateGUID(), false, VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalPostPurchaseOrderVerifyEFTExportWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export Payment Journal
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        Commit();

        // [THEN] Verify Data is created in the EFT Export Table
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        EFTExport.SetRange("Line No.", GenJournalLine."Line No.");
        EFTExport.FindFirst();
        EFTExport.TestField("Check Exported", true);
        EFTExport.TestField("Check Printed", true);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportTwoPaymentJournalPostPurchaseOrderVerifyEFTExportWordLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create 2 Electonic Payment Journals
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicMultiplePaymentJournals(GenJournalLine);

        // [WHEN] Export Payment Journals
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] Verify 2 records are in the EFT Export Table
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        Assert.AreEqual(EFTExport.Count, 2, NoOfRecordsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportTwoPaymentJournalOpenUpGenerateEFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
    begin
        // [GIVEN] Create 2 Electonic Payment Journals
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicMultiplePaymentJournals(GenJournalLine);

        // [WHEN] Export Payment Journals and open up the Generate EFT page
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();
        PaymentJournal.Close();

        // [THEN] Iterate through each line in the repeater to make sure there is 2 records
        if GenerateEFTFiles.GenerateEFTFileLines.First() then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next();

        Assert.AreEqual(Count, 2, NoOfRecordsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentPostPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileManagement: Codeunit "File Management";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
        FilePath: Text;
    begin
        // [SCENARIO] Verify Entry Status on Check Ledger Entry after Post Electronic Payment Journal.
        // 270132: One check ledger entry creates when export electronic payment journal
        // 286778: Entry Status is "Posted"
        // 377993: Resulting file name = Remittance Advice <Vendor's Name>.pdf

        // [GIVEN] Create and Export Electronic Payment Journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        Vendor.Get(GenJournalLine."Account No.");

        // TFS ID 435431: To ensure that its EFT File is generated before posting of journal Line.
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();
        PaymentJournal.Close();

        if GenerateEFTFiles.GenerateEFTFileLines.First() then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next();

        GenerateEFTFiles.GenerateEFTFile.Invoke();
        // [WHEN] Post the General Journal Line and open up the Generate EFT Files Page
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Iterate through each line in the repeater to make sure there is 1 record
        Assert.AreEqual(Count, 1, NoOfRecordsErr);

        // [THEN] One check ledger entry has been created
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        VerifyCheckLedgEntryCount(
          GenJournalLine."Posting Date", BankAccount."Last Remittance Advice No.", CheckLedgerEntry."Entry Status"::Posted, 1);
        // 377993: Resulting file name = Remittance Advice <Vendor's Name>.pdf
        FilePath := FileManagement.CombinePath(TemporaryPath, StrSubstNo('Remittance Advice for %1.pdf', Vendor.Name));
        Assert.IsTrue(File.Exists(FilePath), RemitAdvFileNotFoundTxt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalPostWithoutTransmit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [GIVEN] Create Payment Journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [WHEN] Export Electronic payment
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);

        GenJournalLine.TestField("Check Transmitted", false);

        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Line No.", GenJournalLine."Line No.");
        GenJournalLine2.FindFirst();

        // TFS ID 435431: To ensure that its EFT File is generated before posting of journal Line.
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();
        PaymentJournal.Close();

        GenerateEFTFiles.GenerateEFTFile.Invoke();

        // [WHEN] Post the payment journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL ENTRY is created
        VerifyGLEntry(
          GenJournalLine2."Document Type", GenJournalLine2."Document No.", GenJournalLine2."Bal. Account No.", Abs(GenJournalLine2.Amount));
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyDeleteEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        "Count": Integer;
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [WHEN] Export Payment Journal
        PrepareEFTExportScenario(GenJournalLine, PaymentJournal);

        // [THEN] Verify Data is created in the EFT Export Table
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();
        PaymentJournal.Close();

        // [THEN] Verify Data is deleted
        if GenerateEFTFiles.GenerateEFTFileLines.First() then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next();

        Assert.AreEqual(Count, 1, NoOfRecordsErr);

        GenerateEFTFiles.Delete.Invoke();

        EFTExport.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        Count := EFTExport.Count();

        Assert.RecordIsEmpty(EFTExport);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyVendorErrorNoUseForElectronicPaymentsEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify the EFT Export record gets created
        // [GIVEN] Create Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournalNoUseForElecPayment(GenJournalLine);

        // [WHEN] Export Payment Journal
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that we get an message error because Vendor Bank account doesn't have Use For Electronic Payments set.
        Assert.ExpectedError(HasErrorsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalVerifyCustomerErrorNoUseForElectronicPaymentsEFTExport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        Amount: Decimal;
        AccountNo: Code[20];
        CustomerBankAccountCode: Code[20];
    begin
        // [GIVEN] Create a Electronic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);

        // [WHEN] Export Payment Journal
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.

        AccountNo := CreateCustomerBankAccountWithCustomer(false, CustomerBankAccountCode);

        CreatePaymentJournal(GenJournalLine,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account", CreateAndModifyBankAccount(),
          GenJournalLine."Applies-to Doc. Type"::" ", '',
          GenJournalLine."Bal. Account Type"::Customer,
          AccountNo, Amount, CustomerBankAccountCode);
        GenJournalLine.Validate("Transaction Type Code", GenJournalLine."Transaction Type Code"::BUS);
        GenJournalLine.Validate("Transaction Code", CopyStr(LibraryUtility.GenerateGUID(), 1, 3));
        GenJournalLine.Validate("Company Entry Description", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        PaymentJournal.OpenEdit();

        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Verify that we get an message error because Customer Bank account doesn't have Use For Electronic Payments set.
        Assert.ExpectedError(HasErrorsErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournaGenerateEFTFile()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        PaymentJournal: TestPage "Payment Journal";
        PathToExport: Text;
    begin
        // [SCENARIO 263518] Stan can export Generated EFT File via windows client
        // [SCENARIO 292459,297292] No extra check ledger entries are created
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] EFT export worksheet ready for export
        PrepareEFTExportScenario(GenJournalLine, PaymentJournal);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(TempEFTExportWorkset.Description));
        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert();

        // [WHEN] Stan call Generate EFT and selects folder "C:\EFT Generation" on a local machine
        PathToExport := FileManagement.ServerCreateTempSubDirectory();
        GenerateEFT.SetSavePath(PathToExport);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);
        GenerateEFT.ProcessAndGenerateEFTFile(TempEFTExportWorkset."Bank Account No.", WorkDate(), TempEFTExportWorkset, EFTValues);

        // [THEN] No extra check ledger entries have been created
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        VerifyCheckLedgEntryCount(0D, BankAccount."Last Remittance Advice No.", CheckLedgerEntry."Entry Status"::Exported, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnDifferentCurrenciesAfterExportPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 262728] Verify Error after Export Electronic Payment Journal when Journal Line Currency Code <> Bank Account Currency Code.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Electonic Payment Journal and Bank Account with empty Currency Code.
        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);

        // [GIVEN] Set Journal Line Currency Code.
        GenJournalLine.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.0, 1.0));
        GenJournalLine.Modify(true);

        // [WHEN] Try to Export Payment Journal.
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [THEN] Payment Journal was not exported and a message of Errors existence occurs.
        Assert.ExpectedError(HasErrorsErr);
        GenJournalLine.Find();
        GenJournalLine.TestField("Exported to Payment File", false);

        // [THEN] Payment Journal Export Error contains a Currency Error.
        VerifyPaymentFileError(GenJournalLine, NoExportDiffCurrencyErr);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalGenerateEFTVerifyNoOfRecords()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EFTExportWorkset: Record "EFT Export Workset";
        EFTExport: Record "EFT Export";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ExpLauncherEFT: Codeunit "Exp. Launcher EFT";
        EFTValues: Codeunit "EFT Values";
        DataCompression: Codeunit "Data Compression";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        ZipFileName: Text;
        "Count": Integer;
    begin
        // [GIVEN] Create 1 Electonic Payment Journal
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Export Payment Journals and open up the Generate EFT page
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();
        PaymentJournal.Close();

        // [THEN] Iterate through each line in the repeater to make sure there is 1 record
        if GenerateEFTFiles.GenerateEFTFileLines.First() then
            repeat
                Count += 1;
            until not GenerateEFTFiles.GenerateEFTFileLines.Next();

        Assert.AreEqual(1, Count, NoOfRecordsErr);

        EFTExportWorkset.DeleteAll();
        EFTExport.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        EFTExport.FindFirst();
        EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(EFTExportWorkset.Description));
        EFTExportWorkset.TransferFields(EFTExport);
        EFTExportWorkset.Include := true;
        EFTExportWorkset.UserSettleDate := WorkDate();
        EFTExportWorkset.ProcessOrder := 1;
        EFTExportWorkset.Insert();

        EFTValues.SetNoOfRec := 0;
        ExpLauncherEFT.SetTestMode();
        // [THEN] Start EFT Process and verify the file will have 10 lines.
        ExpLauncherEFT.EFTPaymentProcess(EFTExportWorkset, TempNameValueBuffer, DataCompression, ZipFileName, EFTValues);
        Assert.AreEqual(10, EFTValues.GetNoOfRec(), 'Wrong number of Records');
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure ExportSeveralVendorsWithSameNamePDF()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: array[3] of Record "Vendor Bank Account";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        FilesList: List of [Text];
        VendorName: Text;
        i: Integer;
    begin
        // [FEATURE] [Report] [Export]
        // [SCENARIO 401532] Export payment journal Remittance Advice for several vendors with the same name
        // [SCENARIO 401532] produces several pdf files with different names
        Initialize();
        CheckClearAllReportsZip();
        CreateExportReportSelection(Layout::RDLC);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Three vendors with the same name "X"
        VendorName := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            FindAndUpdateVendorBankAccount(VendorBankAccount[i]);
            Vendor.Get(VendorBankAccount[i]."Vendor No.");
            Vendor.Validate(Name, CopyStr(VendorName, 1, MaxStrLen(Vendor.Name)));
            Vendor.Modify(true);
        END;

        // [GIVEN] Bank account setup for US EFT DEFAULT export
        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        // [GIVEN] Payment journal with 3 lines for different vendors
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            CreatePaymentGLLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
              VendorBankAccount[i]."Vendor No.", GenJournalLine."Document Type"::" ", '',
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", 1);
            GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount[i].Code);
            GenJournalLine.Modify(true);
        end;
        LibraryVariableStorage.Enqueue(BankAccount."No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        // [WHEN] Export payment journal
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);

        // [WHEN] Three files have been exported:
        // [THEN] "Remittance Advice for X_Export Electronic Payments.pdf"
        // [THEN] "Remittance Advice for X_Export Electronic Payments (1).pdf"
        // [THEN] "Remittance Advice for X_Export Electronic Payments (2).pdf"
        GetFilesListFromZip(FilesList);
        Assert.AreEqual(3, FilesList.Count(), '');
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1.pdf', VendorName)), RemitAdvFileNotFoundTxt);
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1 (1).pdf', VendorName)), RemitAdvFileNotFoundTxt);
        Assert.IsTrue(FilesList.Contains(StrSubstNo('Remittance Advice for %1 (2).pdf', VendorName)), RemitAdvFileNotFoundTxt);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneratingEFTFileInCAFormatRollbackAllExportedLinesOnError()
    var
        Vendor: array[2] of Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
    begin
        // [FEATURE] [Generate EFT File]
        // [SCENARIO 310585] When an error occurs during processing of exported lines in CA format, none of the lines must be marked as transmitted.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Create two vendors - "CA" and "UNDEF", the first one has Country Code = "CA", the country code on another vendor is blank.
        // [GIVEN] Set up Vendor Bank Account for each vendor.
        CreateVendorWithVendorBankAccount(Vendor[1], VendorBankAccount[1], 'CA');
        CreateVendorWithVendorBankAccount(Vendor[2], VendorBankAccount[2], '');

        // [GIVEN] Bank Account set up for "CA" EFT export format.
        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::CA);
        BankAccount.Validate("Payment Export Format", 'CA EFT DEFAULT');
        BankAccount.Validate("EFT Export Code", 'CA EFT DEFAULT');
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        // [GIVEN] Post an invoice for each vendor.
        // [GIVEN] Generate payment journal line for each invoice, populate an appropriate Vendor Bank Account.
        // [GIVEN] Export the payment journal.
        // [GIVEN] Mark the exported lines as "Include" so they can be processed to EFT file.
        CreateAndExportVendorPayments(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        GenerateEFT.SetSavePath(TemporaryPath);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);
        asserterror GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate(), TempEFTExportWorkset, EFTValues);

        // [THEN] An error message is thrown, as the country code for vendor "UNDEF" is not populated.
        Assert.ExpectedError('Country must have a value');

        // [THEN] None of the exported lines are marked as Transmitted, since the generating EFT file failed.
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, false);
        Assert.RecordCount(EFTExport, ArrayLen(Vendor));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneratingEFTFileInCAFormatCustomDateFormat()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        TempACHRBHeader: Record "ACH RB Header" temporary;
        TempACHRBDetail: Record "ACH RB Detail" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        DateFormat: Text[100];
        DateFormatLength: Integer;
        ExpectedDateInt: Integer;
        EFTFilePath: Text;
    begin
        // [FEATURE] [Generate EFT File] [Date Format] [Data Exchange Definition]
        // [SCENARIO 338287] Stan can export payment with export type "CA" to EFT file with custom "Date Format" specified in "Data Exchange Definition"
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Vendor and Bank Accoutn with Country Code = "CA" and setup for EFT export "CA"
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        DuplicateDataExchangeDefinition(DataExchDef, BankExportImportSetup, 'CA EFT DEFAULT');
        DateFormat := '<Day,2><Month,2><Year,2>';
        DateFormatLength := 6;

        // [GIVEN] "Data Format" = <Day,2><Month,2><Year,2> for "File Created Date" in header and "Payment Date" in detail lines
        UpdateDateFormatsOnCAEFTDataExchDef(DataExchDef, DateFormat, DateFormatLength, false);

        // [GIVEN] Bank Account set up for "CA" EFT export format.
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::CA);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("EFT Export Code", BankExportImportSetup.Code);
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        // [GIVEN] Post an invoice for each vendor.
        // [GIVEN] Generate payment journal line for each invoice, populate an appropriate Vendor Bank Account.
        // [GIVEN] Export the payment journal.
        // [GIVEN] Mark the exported lines as "Include" so they can be processed to EFT file.
        // [GIVEN] TODAY = 23/03/2019, WORKDATE = 20/03/2019
        CreateAndExportVendorPayment(TempEFTExportWorkset, GenJournalLine, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        EFTFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        GenerateEFT.SetSavePath(EFTFilePath);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate(), TempEFTExportWorkset, EFTValues);

        // [THEN] Exported lines are marked as Transmitted
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, true);
        Assert.RecordCount(EFTExport, 1);

        // [THEN] ACHRBHeader."File Created Date" = 230319
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        Evaluate(ExpectedDateInt, Format(Today, DateFormatLength, DateFormat));
        TempACHRBHeader.FindLast();
        TempACHRBHeader.TestField("File Creation Date", ExpectedDateInt);

        // [THEN] ACHRBDetail."Payment Date" = 200319
        Evaluate(ExpectedDateInt, Format(WorkDate(), DateFormatLength, DateFormat));
        TempACHRBDetail.FindFirst();
        TempACHRBDetail.TestField("Payment Date", ExpectedDateInt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalGenerateEFT_ACH_EntrySequenceNo()
    var
        Vendor: Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        EFTFilePath: Text;
    begin
        // [FEATURE] [Generate EFT File] [ACH] [Data Exchange Definition]
        // [SCENARIO 336577] Cassie can export payment journal as EFT with "Entry Detail Sequence No" field in Data Exchange Definition mapping.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount[1], 'US');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount[2], 'US');

        DuplicateDataExchangeDefinition(DataExchDef, BankExportImportSetup, 'US EFT DEFAULT');
        InsertEntryDetailSequenceNo(DataExchDef);

        CreateBankAccount(BankAccount, VendorBankAccount[1]."Transit No.", BankAccount."Export Format"::US);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("EFT Export Code", BankExportImportSetup.Code);
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        CreateAndExportVendorPayments(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        EFTFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        GenerateEFT.SetSavePath(EFTFilePath);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate(), TempEFTExportWorkset, EFTValues);

        // [THEN] All exported lines are marked as Transmitted
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, true);
        Assert.RecordCount(EFTExport, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JulianDate()
    var
        ExportEFTRB: Codeunit "Export EFT (RB)";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 303720] Codeunit "Export EFT (RB)".JulianDate() returns integer value "YYDDD"
        Assert.AreEqual(20150, ExportEFTRB.JulianDate(20200529D), 'JulianDate');
        Assert.AreEqual(21001, ExportEFTRB.JulianDate(20210101D), 'JulianDate');
        Assert.AreEqual(22365, ExportEFTRB.JulianDate(20221231D), 'JulianDate');
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTExport_CA_ValidateFileOutput()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
        TextLine: Text;
        DetailCode: Code[20];
        Lines: List of [Text];
    begin
        // [FEATURE] [EFT] [CA]
        // [SCENARIO 303720] E2E validation of CA EFT DEFAULT format
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [WHEN] Use CA EFT DEFAULT Data Exch format
        DataExchDef.SetRange(Code, 'CA EFT DEFAULT');
        DataExchDef.FindFirst();
        DetailCode := 'DETAIL';

        // [GIVEN] Bank account with CA EFT DEFAULT format
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::CA, CreateBankExportImportSetup(DataExchDef.Code),
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        ERMElectronicFundsTransfer.GetTempACHRBFooter(TempACHRBFooter);
        TempACHRBDetail.FindFirst();

        // [WHEN] Reading exported file into lines
        Lines := ReadEFTFileOutputLines(DataExchDef.Code, DetailCode);

        // [THEN] Validate CA Header, Detail and Footer from file
        Lines.Get(1, TextLine);
        ValidateEFTCAHeader(TextLine);

        Lines.Get(2, TextLine);
        ValidateEFTCADetail(TextLine);

        TempACHRBDetail.Next();
        Lines.Get(3, TextLine);
        ValidateEFTCADetailAddress1(TextLine);

        TempACHRBDetail.Next();
        Lines.Get(4, TextLine);
        ValidateEFTCADetailAddress2(TextLine);

        Lines.Get(5, TextLine);
        ValidateEFTCAFooter(TextLine);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTExport_US_ValidateFileOutput()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
        TextLine: Text;
        DetailCode: Code[20];
        Lines: List of [Text];
    begin
        // [FEATURE] [EFT] [US]
        // [SCENARIO 303720] E2E validation of US EFT DEFAULT format
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [WHEN] Use US EFT DEFAULT Data Exch format
        DataExchDef.SetRange(Code, 'US EFT DEFAULT');
        DataExchDef.FindFirst();
        DetailCode := 'DETAIL';

        // [GIVEN] Bank account with US EFT DEFAULT format
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        UpdateNameOnVendor(Vendor, CopyStr(LibraryUtility.GenerateRandomXMLText(50), 1, 50));
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(DataExchDef.Code),
            '', '');

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);
        ERMElectronicFundsTransfer.GetTempACHUSDetail(TempACHUSDetail);
        ERMElectronicFundsTransfer.GetTempACHUSHeader(TempACHUSHeader);
        ERMElectronicFundsTransfer.GetTempACHUSFooter(TempACHUSFooter);

        // [WHEN] Reading exported file into lines
        Lines := ReadEFTFileOutputLines(DataExchDef.Code, DetailCode);

        // [THEN] Validate US Header, Detail and Footer from file
        Lines.Get(1, TextLine);
        TempACHUSHeader.FindFirst();
        ValidateEFTUSHeaderA(TextLine);

        TempACHUSHeader.Next();
        Lines.Get(2, TextLine);
        ValidateEFTUSHeaderB(TextLine);

        TempACHUSDetail.FindFirst();
        Lines.Get(3, TextLine);
        ValidateEFTUSDetail(TextLine);

        TempACHUSFooter.FindFirst();
        Lines.Get(4, TextLine);
        ValidateEFTUSFooterA(TextLine);

        TempACHUSFooter.Next();
        Lines.Get(5, TextLine);
        ValidateEFTUSFooterB(TextLine);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_CA()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [CA]
        // [SCENARIO 303720] Export EFT CA (RB) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH RB Header "Settlement Date" field
        // [SCENARIO 401126] Settlement Julian Date is exported with the Julian date format of the "Settlement Date" field value
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Data Exchange Definition for CA with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::CA, CreateBankExportImportSetup(CreateDataExchDefForCA()),
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Header, Detail, Footer contains "File Creation Number" value
        // [THEN] Detail contains business data from payment journal
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        Assert.IsTrue(EFTValues.IsSetFileCreationNumber(), 'EFTValues.IsSetFileCreationNumber()');
        Assert.AreEqual(BankAccount."Last E-Pay File Creation No.", EFTValues.GetFileCreationNumber(), 'EFTValues.GetFileCreationNumber()');
        VerifyEFTExportCA(ERMElectronicFundsTransfer, TempEFTExportWorkset, BankAccount."Last E-Pay File Creation No.", SettleDate);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_US()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [US]
        // [SCENARIO 303720] Export EFT US (ACH) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH US Header "Effective Date" field
        // [SCENARIO 430249] Vendor Name is trimmed to 22 characters.
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Data Exchange Definition for US with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        // [GIVEN] Vendor Name value has length 50.
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        UpdateNameOnVendor(Vendor, CopyStr(LibraryUtility.GenerateRandomXMLText(50), 1, 50));
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Detail contains business data from payment journal
        // [THEN] Vendor Name was trimmed to 22 chars and copied to ACHUSDetail."Payee Name".
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        VerifyEFTExportUS(ERMElectronicFundsTransfer, TempEFTExportWorkset, SettleDate, CopyStr(Vendor.Name, 1, 22));
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExport_MX()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SettleDate: Date;
    begin
        // [FEATURE] [MX]
        // [SCENARIO 303720] Export EFT MX (Cecoban) with two headers and all business data in payment journal
        // [SCENARIO 362896] Settlement Date is exported via data exchange ACH US Header "Effective Date" field
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Data Exchange Definition for MX with two headers
        // [GIVEN] Bank account "Last E-Pay File Creation No." = 1
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'MX');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::MX, CreateBankExportImportSetup(CreateDataExchDefForMX()), '', '');

        // [GIVEN] Exported payment journal line with filled in all business data
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file
        SettleDate := LibraryRandom.RandDate(10);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", SettleDate, TempEFTExportWorkset, EFTValues);

        // [THEN] Bank account "Last E-Pay File Creation No." = 2
        // [THEN] Detail contains business data from payment journal
        VerifyBankAccountFileCreationNumberIncrement(BankAccount);
        VerifyEFTExportMX(ERMElectronicFundsTransfer, TempEFTExportWorkset, SettleDate);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportTransmit()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export and tranmit one line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        // [GIVEN] EFT Export line is created with "Sequence No." = 1
        // [GIVEN] Payment journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Sequence No.", LastSequenceNo + 1);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Perform EFT Export (Generate EFT file)
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] Journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = True
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    procedure EFTSequenceNo_CreateExportVoid()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export and void one line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        // [GIVEN] EFT Export line is created with "Sequence No." = 1
        // [GIVEN] Payment journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Sequence No.", LastSequenceNo + 1);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Perform journal "Void" action
        PerformVoidTransmitElecPayments(GenJournalLine);

        // [THEN] EFT Export line is deleted
        // [THEN] Payment journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        Assert.RecordIsEmpty(EFTExport);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportPostCreateExport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, post first line and create, export second line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        MockExportPayment(GenJournalLine, LastSequenceNo + 1);

        // TFS ID 435431: To ensure that its EFT File is generated before posting of journal Line.
        FindEFTExportByGenJournalLine(EFTExport, GenJournalLine);
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [GIVEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GenJournalLine.Find();
        GenJournalLine.Delete();

        // [GIVEN] Create a new payment journal line ("EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False)
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);

        // [WHEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);

        // [THEN] Payment journal line is updated with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 2, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_CreateExportPostCreateTransmit()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, post first line, create second line, transmit first line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] A new payment journal line has "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, 0, false, false);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);
        FindEFTExport(EFTExport, GenJournalLine);

        // TFS ID 435431: To ensure that its EFT File is generated before posting of journal Line.
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [GIVEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Line No.", GenJournalLine."Line No.");
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."Recipient Bank Account" := VendorBankAccount.Code;
            GenJournalLine.Modify();
        end;

        // [GIVEN] Create a new payment journal line ("EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False)
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        VerifyLastGenJnlLineFields(GenJournalLine, 0, false, false);

        // [WHEN] Perform EFT Export (Generate EFT file)
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] Journal line remains with "EFT Export Sequence No." = 0, "Check Exported" = False, "Check Transmitted" = False
        VerifyLastGenJnlLineFields(GenJournalLine, 0, false, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_TransmitFirstOfTwoLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, transmit the first of two lines
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Two payment journal lines
        // [GIVEN] Perform journal "Export" action
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, BankAccountNo);
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        MockExportPayment(GenJournalLine[2], LastSequenceNo + 2);

        // [WHEN] Perform EFT Export (Generate EFT file) for the first line
        FindEFTExport(EFTExport, GenJournalLine[1]);
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] The first journal line is updated with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = True
        // [THEN] The second journal line remains with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine[1], LastSequenceNo + 1, true, true);
        VerifyGenJnlLineFields(GenJournalLine[2], LastSequenceNo + 2, true, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_TransmitSecondOfTwoLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] create, export, transmit the second of two lines
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Two payment journal lines
        // [GIVEN] Perform journal "Export" action
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        MockExportPayment(GenJournalLine[1], LastSequenceNo + 1);
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        ExportPaymentJournalViaAction(GenJournalLine[2], GenJournalBatch, BankAccountNo);

        // [WHEN] Perform EFT Export (Generate EFT file) for the second line
        FindEFTExport(EFTExport, GenJournalLine[2]);
        ProcessAndGenerateEFTFile(EFTExport, BankAccountNo);

        // [THEN] The first journal line remains with "EFT Export Sequence No." = 1, "Check Exported" = True, "Check Transmitted" = False
        // [THEN] The second journal line is updated with "EFT Export Sequence No." = 2, "Check Exported" = True, "Check Transmitted" = True
        VerifyGenJnlLineFields(GenJournalLine[1], LastSequenceNo + 1, true, false);
        VerifyGenJnlLineFields(GenJournalLine[2], LastSequenceNo + 2, true, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure EFTSequenceNo_DeleteEFTExportLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] deletion of EFT Export line
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Payment journal line
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Delete EFT Export line
        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.Delete(true);

        // [THEN] The journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, 0, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    procedure EFTSequenceNo_DeleteEFTExportLineViaPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        BankAccountNo: Code[20];
        LastSequenceNo: Integer;
    begin
        // [SCENARIO 360400] EFT Export "Sequence No." relation to journal line "EFT Sequence No." in case of
        // [SCENARIO 360400] deletion of EFT Export line via page
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        PrepareEFTSequenceNoScenario(GenJournalBatch, VendorBankAccount, BankAccountNo, LastSequenceNo);

        // [GIVEN] Payment journal line
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccountNo);
        // [GIVEN] Perform journal "Export" action
        ExportPaymentJournalViaAction(GenJournalLine, GenJournalBatch, BankAccountNo);
        VerifyGenJnlLineFields(GenJournalLine, LastSequenceNo + 1, true, false);

        // [WHEN] Delete EFT Export line via page
        GenerateEFTFiles.OpenEdit();
        GenerateEFTFiles."Bank Account".SetValue(BankAccountNo);
        GenerateEFTFiles.Delete.Invoke();

        // [THEN] The journal line is updated with "EFT Export Sequence No." = 0, "Check Exported" = True, "Check Transmitted" = False
        VerifyGenJnlLineFields(GenJournalLine, 0, True, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_RequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, use request page)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, use request page)
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PrintElectronicPaymentsRDLC(GenJournalLine, true);

        // [THEN] Report is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
        DeleteBankAccount(GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRH')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_NoRequestPage_DiffSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, w\o request page, different saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, w\o request page, different saved bank account)
        PrintElectronicPaymentsRDLC(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_RequestPage_BlankBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, use request page, blank bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, use request page, blank bank account)
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        asserterror PrintElectronicPaymentsRDLC(GenJournalLine, true);

        // [THEN] Report is not printed
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('Bank Account');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRH')]
    [Scope('OnPrem')]
    procedure PrintReport_RDLC_NoRequestPage_BlankedSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (RDLC, w\o request page, blanked saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (RDLC, w\o request page, blanked saved bank account)
        PrintElectronicPaymentsRDLC(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_RequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, use request page)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, use request page)
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PrintElectronicPaymentsWord(GenJournalLine, true);

        // [THEN] Report is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
        DeleteBankAccount(GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_NoRequestPage_DiffSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, w\o request page, different saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, w\o request page, different saved bank account)
        PrintElectronicPaymentsWord(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_RequestPage_BlankBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, use request page, blank bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, use request page, blank bank account)
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        asserterror PrintElectronicPaymentsWord(GenJournalLine, true);

        // [THEN] Report is not printed
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('Bank Account');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWordRH')]
    [Scope('OnPrem')]
    procedure PrintReport_Word_NoRequestPage_BlankedSavedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 360400] Print Remittance Advice for already exported and printed payment journal line (Word, w\o request page, blanked saved bank account)
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Payment journal line with "Check Exported", "Check Printed", "Check Transmitted" = True
        PrepareGenJournalLineForPrintReport(GenJournalLine);

        // [WHEN] Print the Remittance Advice report (Word, w\o request page, blanked saved bank account)
        PrintElectronicPaymentsWord(GenJournalLine, false);

        // [THEN] Report is printed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordLayoutRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EFTExportGenJnlLineDimensionError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        ObjectTranslation: Record "Object Translation";
        ObjectOptions: Record "Object Options";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
        GenerateEFTFiles: TestPage "Generate EFT Files";
        ErrorText: Text;
    begin
        // [FEATURE] [Generate EFT File]
        // [SCENARIO 352093] Error when trying to use "Generate EFT File" for exported Gen. Journal line with wrong Dimension setup.
        Initialize();
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", Report::"ExportElecPayments - Word");
        ObjectOptions.DeleteAll();
        ObjectOptions.SetRange("Object ID", Report::"Export Electronic Payments");
        ObjectOptions.DeleteAll();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Gen. Journal Line Payment exported with empty Dimension for Vendor with Default Dimension having "Value Posting"::"Code Mandatory".
        CreateTestElectronicPaymentJournalWordLayout(GenJournalLine);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension, DATABASE::Vendor, GenJournalLine."Account No.", DefaultDimension."Value Posting"::"Code Mandatory");

        // [GIVEN] GenerateEFTFiles page is opened from Payment Journal.
        Commit();  // Commit required.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ExportPaymentsToFile.Invoke();
        GenerateEFTFiles.Trap();
        PaymentJournal.GenerateEFT.Invoke();

        // [WHEN] "Generate EFT File" action is invoked on GenerateEFTFiles page.
        asserterror GenerateEFTFiles.GenerateEFTFile.Invoke();
        PaymentJournal.Close();

        // [THEN] Error is thrown with Error Code "TestWrapped:Dialog" and
        // [THEN] text "A dimension used in Gen. Journal Line has caused an error. Select a Dimension Value Code for the Dimension Code for Vendor.".
        Assert.ExpectedErrorCode('TestWrapped:Dialog');
        ErrorText :=
                StrSubstNo(
                    MandatoryDimErr, DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension.FieldCaption("Dimension Code"),
                    DefaultDimension."Dimension Code", ObjectTranslation.TranslateTable(DefaultDimension."Table ID"), DefaultDimension."No.");
        ErrorText :=
                StrSubstNo(
                    EFTExportGenJnlLineErr, GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.", ErrorText);
        Assert.ExpectedError(ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleCustomerBankAccountsForElectronicPayment()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        Initialize();

        // [GIVEN] A customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A customer bank account for the customer we have just created
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [GIVEN] The customer bank account has "Use for Electronic Payments" set to true
        CustomerBankAccount.Validate("Use for Electronic Payments", true);
        CustomerBankAccount.Modify(true);

        // [WHEN] Creating a second customer bank account with "Use for Electronic Payments" set to true
        // for the same customer
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate("Use for Electronic Payments", true);
        CustomerBankAccount.Modify(true);

        // [THEN] No errors occur and the customer has 2 customer bank accounts with
        // "Use for Electronic Payments" set to true
        CustomerBankAccount.SetRange("Customer No.", Customer."No.");
        CustomerBankAccount.SetRange("Use for Electronic Payments", true);
        Assert.AreEqual(2, CustomerBankAccount.Count,
            'The customer should have 2 bank accounts that have electronic payments enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleVendorBankAccountsForElectronicPayment()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Initialize();

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A vendor bank account for the vendor we have just created
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [GIVEN] The vendor bank account has "Use for Electronic Payments" set to true
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);

        // [WHEN] Creating a second vendor bank account with "Use for Electronic Payments" set to true
        // for the same vendor
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);

        // [THEN] No errors occur and the vendor has 2 vendor bank accounts with
        // "Use for Electronic Payments" set to true
        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.SetRange("Use for Electronic Payments", true);
        Assert.AreEqual(2, VendorBankAccount.Count,
            'The vendor should have 2 bank accounts that have electronic payments enabled');
    end;

    [Test]
    procedure ACHRBHeaderSettlementJulianDateUT()
    var
        ACHRBHeader: Record "ACH RB Header";
        ExportEFTRB: Codeunit "Export EFT (RB)";
        Date: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 401126] TAB 10303 "ACH RB Header"."Settlement Julian Date" contains a date in the Julian date format
        Date := LibraryRandom.RandDate(1000);
        ACHRBHeader.Validate("Settlement Date", Date);
        ACHRBHeader.TestField("Settlement Date", Date);
        ACHRBHeader.TestField("Settlement Julian Date", ExportEFTRB.JulianDate(Date));

        ACHRBHeader.Validate("Settlement Date", 0D);
        ACHRBHeader.TestField("Settlement Date", 0D);
        ACHRBHeader.TestField("Settlement Julian Date", 0);
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    procedure RunExportElecPaymentsWordWithRequestPageOnMarkedGenJnlLines()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 400511] Run report "ExportElecPayments - Word" with request page on marked Payment Journal lines.
        Initialize();

        // [GIVEN] Two Payment Journal lines for one Vendor. Both lines are marked.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);

        // [WHEN] Run report "ExportElecPayments - Word" with request page on marked General Journal Lines from Payment Journal.
        // [WHEN] On the request page set Bank Account No.; filters for Gen. Journal Batch/Template are empty.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        GenJournalLine.MarkedOnly(true);
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [THEN] Report was printed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH,ConfirmHandlerEnqueueQuestion')]
    procedure RunExportElecPaymentsWordWithRequestPageOnMarkedGenJnlLinesWhenForceDocBalanceFalse()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 400511] Run report "ExportElecPayments - Word" with request page on marked Payment Journal lines when Force Doc. Balance = false.
        Initialize();

        // [GIVEN] General Journal Template with "Forced Doc. Balance" = false.
        // [GIVEN] Two Payment Journal lines for one Vendor. Both lines are marked.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", false);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Mark(true);

        // [WHEN] Run report "ExportElecPayments - Word" with request page on marked General Journal Lines from Payment Journal.
        // [WHEN] On the request page set Bank Account No.; filters for Gen. Journal Batch/Template are empty.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        GenJournalLine.MarkedOnly(true);
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [THEN] A confirm dialog "Transactions cannot be financially voided" is shown. Report was printed after user proceeded with confirm.
        Assert.ExpectedConfirm(ForceDocBalanceFalseQst, LibraryVariableStorage.DequeueText());
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.AssertEmpty();
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", true);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,VoidCheckPageHandler')]
    procedure FinanciallyVoidCheckForFCYBank()
    var
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        EFTExport: Record "EFT Export";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [Check] [Currency]
        // [SCENARIO 408136] Financially Void check for the FCY bank account
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] FCY Bank Account with EFT setup
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::CA, CreateBankExportImportSetup(CreateDataExchDefForCA()),
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        // [GIVEN] FCY Vendor Payment with 1000 CAD Amount and 900 USD Amount LCY
        // [GIVEN] Export the payment
        CreateAndExportVendorPayment(TempEFTExportWorkset, GenJournalLine, VendorBankAccount, BankAccount."No.");
        GenJournalLine.TestField("Currency Code");
        GenJournalLine.TestField(Amount);

        // [GIVEN] A new check is created with Amount = 1000 and status = Exported
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField(Amount, GenJournalLine.Amount);
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::Exported);

        // TFS ID 435431: To ensure that its EFT File is generated before posting of journal Line.
        FindEFTExportByGenJournalLine(EFTExport, GenJournalLine);
        ProcessAndGenerateEFTFile(EFTExport, BankAccount."No.");

        // [GIVEN] Post the payment
        // [GIVEN] The check status = Posted and linked bank ledger entry has Amount = -1000, Amount LCY = -900
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CheckLedgerEntry.Find();
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
        CheckLedgerEntry.TestField("Bank Account Ledger Entry No.");
        BankAccountLedgerEntry.GET(CheckLedgerEntry."Bank Account Ledger Entry No.");
        BankAccountLedgerEntry.TestField(Amount, -GenJournalLine.Amount);
        BankAccountLedgerEntry.TestField("Amount (LCY)", -GenJournalLine."Amount (LCY)");

        // [WHEN] Void the check (financial void)
        VoidCheck(CheckLedgerEntry);

        // [THEN] The check has status is "Financially Voided"
        // [THEN] A new bank ledgerentry is created with Amount = +1000, Amount LCY = +900
        CheckLedgerEntry.Find();
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::"Financially Voided");
        BankAccountLedgerEntry.Next();
        BankAccountLedgerEntry.TestField(Amount, GenJournalLine.Amount);
        BankAccountLedgerEntry.TestField("Amount (LCY)", GenJournalLine."Amount (LCY)");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordOutputXMLRequestPageHandler')]
    procedure RunExportPaymentsWordPaymentJournalPageMultipleLinesOneVendor()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        ServerTempFileName: Text;
        DocumentNos: List of [Code[20]];
    begin
        // [SCENARIO 409562] Run Bank - Export on Payment Journal page with multiple Payment Journal lines for one Vendor. Vendor Remittance report is "ExportElecPayments - Word".
        Initialize();

        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [GIVEN] Report "ExportElecPayments - Word" is set as a report for Vendor Remittance.
        CreateExportReportSelection(Layout::Word);

        // [GIVEN] Two Payment Journal lines with Gen. Journal Batch "B" for one Vendor.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        // [WHEN] Open Payment Journal, set Batch Name "B", run Bank - Export.
        // [WHEN] Set Output = XML on requst page of report "ExportElecPayments - Word".
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Bal. Account No.");

        // [THEN] One xml file for both Payment Journal lines is created.
        ServerTempFileName := LibraryFileMgtHandler.GetServerTempFileName();
        Assert.AreEqual('xml', FileMgt.GetExtension(ServerTempFileName), '');
        GenJournalLine[1].Find();
        GenJournalLine[2].Find();
        DocumentNos.AddRange(GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");
        VerifyDocumentNoInXmlOutput(ServerTempFileName, DocumentNos);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsWordOutputXMLRequestPageHandler')]
    procedure RunExportPaymentsWordPaymentJournalPageMultLinesMultVendors()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        ServerTempFileName: Text;
        XmlFileNames: List of [Text];
        DocumentNos1: List of [Code[20]];
        DocumentNos2: List of [Code[20]];
    begin
        // [SCENARIO 409562] Run Bank - Export on Payment Journal page with multiple Payment Journal lines for one Vendor. Vendor Remittance report is "ExportElecPayments - Word".
        Initialize();

        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [GIVEN] Report "ExportElecPayments - Word" is set as a report for Vendor Remittance.
        CreateExportReportSelection(Layout::Word);

        // [GIVEN] Four Payment Journal lines with Gen. Journal Batch "B", two lines for each Vendor.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[3], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[4], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        // [WHEN] Open Payment Journal, set Batch Name "B", run Bank - Export.
        // [WHEN] Set Output = XML on requst page of report "ExportElecPayments - Word".
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Bal. Account No.");

        // [THEN] One zip archive with two xml files is created. Each xml file contains two payments for one Vendor.
        ServerTempFileName := LibraryFileMgtHandler.GetServerTempFileName();
        Assert.AreEqual('zip', FileMgt.GetExtension(ServerTempFileName), '');
        GenJournalLine[1].Find();
        GenJournalLine[2].Find();
        GenJournalLine[3].Find();
        GenJournalLine[4].Find();
        DocumentNos1.AddRange(GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");
        DocumentNos2.AddRange(GenJournalLine[3]."Document No.", GenJournalLine[4]."Document No.");

        GetFilesFromZipArchive(ServerTempFileName, XmlFileNames);

        VerifyDocumentNoInXmlOutput(XmlFileNames.Get(1), DocumentNos1);
        VerifyDocumentNoAbsenceInXmlOutput(XmlFileNames.Get(1), DocumentNos2);

        VerifyDocumentNoInXmlOutput(XmlFileNames.Get(2), DocumentNos2);
        VerifyDocumentNoAbsenceInXmlOutput(XmlFileNames.Get(2), DocumentNos1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsOutputXMLRequestPageHandler')]
    procedure RunExportPaymentsPaymentJournalPageMultipleLinesOneVendor()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        ServerTempFileName: Text;
        DocumentNos: List of [Code[20]];
    begin
        // [SCENARIO 409562] Run Bank - Export on Payment Journal page with multiple Payment Journal lines for one Vendor. Vendor Remittance report is "Export Elecronic Payments".
        Initialize();

        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [GIVEN] Report "Export Elecronic Payments" is set as a report for Vendor Remittance.
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Two Payment Journal lines with Gen. Journal Batch "B" for one Vendor.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        // [WHEN] Open Payment Journal, set Batch Name "B", run Bank - Export.
        // [WHEN] Set Output = XML on requst page of report "Export Elecronic Payments".
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Bal. Account No.");

        // [THEN] One xml file for both Payment Journal lines is created.
        ServerTempFileName := LibraryFileMgtHandler.GetServerTempFileName();
        Assert.AreEqual('xml', FileMgt.GetExtension(ServerTempFileName), '');
        GenJournalLine[1].Find();
        GenJournalLine[2].Find();
        DocumentNos.AddRange(GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");
        VerifyDocumentNoInXmlOutput(ServerTempFileName, DocumentNos);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsOutputXMLRequestPageHandler')]
    procedure RunExportPaymentsPaymentJournalPageMultLinesMultVendors()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        ServerTempFileName: Text;
        XmlFileNames: List of [Text];
        DocumentNos1: List of [Code[20]];
        DocumentNos2: List of [Code[20]];
    begin
        // [SCENARIO 409562] Run Bank - Export on Payment Journal page with multiple Payment Journal lines for one Vendor. Vendor Remittance report is "ExportElecPayments - Word".
        Initialize();

        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true);
        LibraryFileMgtHandler.SetSaveFileActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        // [GIVEN] Report "Export Elecronic Payments" is set as a report for Vendor Remittance.
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Four Payment Journal lines with Gen. Journal Batch "B", two lines for each Vendor.
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[1], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[2], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateVendorPaymentLine(GenJournalLine[3], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine[4], GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");

        // [WHEN] Open Payment Journal, set Batch Name "B", run Bank - Export.
        // [WHEN] Set Output = XML on requst page of report "Export Elecronic Payments".
        ExportPaymentJournalViaAction(GenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Bal. Account No.");

        // [THEN] One zip archive with two xml files is created. Each xml file contains two payments for one Vendor.
        ServerTempFileName := LibraryFileMgtHandler.GetServerTempFileName();
        Assert.AreEqual('zip', FileMgt.GetExtension(ServerTempFileName), '');
        GenJournalLine[1].Find();
        GenJournalLine[2].Find();
        GenJournalLine[3].Find();
        GenJournalLine[4].Find();
        DocumentNos1.AddRange(GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");
        DocumentNos2.AddRange(GenJournalLine[3]."Document No.", GenJournalLine[4]."Document No.");

        GetFilesFromZipArchive(ServerTempFileName, XmlFileNames);

        VerifyDocumentNoInXmlOutput(XmlFileNames.Get(1), DocumentNos1);
        VerifyDocumentNoAbsenceInXmlOutput(XmlFileNames.Get(1), DocumentNos2);

        VerifyDocumentNoInXmlOutput(XmlFileNames.Get(2), DocumentNos2);
        VerifyDocumentNoAbsenceInXmlOutput(XmlFileNames.Get(2), DocumentNos1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneratingEFTFileInCAFormatCustomDateFormatWithFieldMappingHeaderDetail()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        EFTExport: Record "EFT Export";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        TempACHRBHeader: Record "ACH RB Header" temporary;
        TempACHRBDetail: Record "ACH RB Detail" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        FileManagement: Codeunit "File Management";
        DateFormat: Text[100];
        DateFormatLength: Integer;
        ExpectedDateInt: Integer;
        EFTFilePath: Text;
    begin
        // [FEATURE] [Generate EFT File] [Date Format] [Data Exchange Definition]
        // [SCENARIO 338287] Stan can export payment with export type "CA" to EFT file with custom "Date Format" specified in "Data Exchange Definition"
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Vendor and Bank Accoutn with Country Code = "CA" and setup for EFT export "CA"
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'CA');
        DuplicateDataExchangeDefinition(DataExchDef, BankExportImportSetup, 'CA EFT DEFAULT');
        DateFormat := '<Day,2><Month,2><Year,2>';
        DateFormatLength := 6;

        // [GIVEN] "Data Format" = <Day,2><Month,2><Year,2> for "File Created Date" in header and "Payment Date" in detail lines
        UpdateDateFormatsOnCAEFTDataExchDef(DataExchDef, DateFormat, DateFormatLength, true);

        // [GIVEN] Bank Account set up for "CA" EFT export format.
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::CA);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("EFT Export Code", BankExportImportSetup.Code);
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        // [GIVEN] Post an invoice for each vendor.
        // [GIVEN] Generate payment journal line for each invoice, populate an appropriate Vendor Bank Account.
        // [GIVEN] Export the payment journal.
        // [GIVEN] Mark the exported lines as "Include" so they can be processed to EFT file.
        // [GIVEN] TODAY = 23/03/2019, WORKDATE = 20/03/2019
        CreateAndExportVendorPayment(TempEFTExportWorkset, GenJournalLine, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        Commit();
        EFTFilePath := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName(''));
        GenerateEFT.SetSavePath(EFTFilePath);
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", WorkDate(), TempEFTExportWorkset, EFTValues);

        // [THEN] Exported lines are marked as Transmitted
        EFTExport.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        EFTExport.SetRange(Transmitted, true);
        Assert.RecordCount(EFTExport, 1);

        // [THEN] ACHRBHeader."File Created Date" = 230319
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        Evaluate(ExpectedDateInt, Format(Today, DateFormatLength, DateFormat));
        TempACHRBHeader.FindLast();
        TempACHRBHeader.TestField("File Creation Date", ExpectedDateInt);

        // [THEN] ACHRBDetail."Payment Date" = 200319
        Evaluate(ExpectedDateInt, Format(WorkDate(), DateFormatLength, DateFormat));
        TempACHRBDetail.FindFirst();
        TempACHRBDetail.TestField("Payment Date", ExpectedDateInt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure TestEFTGenJnlLineOnPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
    begin
        // [SCENARIO 435431] To check if system is throwing an error if a journal is getting posted without generating EFT file where sequence no. is non zero
        // [GIVEN] Create and Export Electronic Payment Journal.
        Initialize();

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        CreateExportReportSelection(Layout::RDLC);
        CreateElectronicPaymentJournal(GenJournalLine);

        // [GIVEN] Export Payment journal Line
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        Vendor.Get(GenJournalLine."Account No.");

        // [WHEN] Post the General Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Then System should throw an error that "Check transmitted" should be true if journal line has "EFT Export Sequence No." as non zero
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Check Transmitted"), '');
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    procedure ExtDataHandlingCodeunitOnEFTFileExport()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        DataExchDefCode: Code[20];
        IsCodeunitRun: Boolean;
    begin
        // [SCENARIO 442042] "Ext. Data Handling Codeunit" of Data Exchange Definition on EFT file export.
        Initialize();
        BindSubscription(ERMElectronicFundsTransfer);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Data Exchange Definition "DE" for US with "Ext. Data Handling Codeunit" = "Read Data Exch. from Stream".
        DataExchDefCode := CreateDataExchDefForUS();
        UpdateExtDataHandlingCodOnDataExchDef(DataExchDefCode, Codeunit::"Read Data Exch. from Stream");

        // [GIVEN] Vendor with Bank account.
        // [GIVEN] Bank Import/Export Setup "BS" with Data Exch. Definition "DE".
        // [GIVEN] Bank Account with Payment Export Format = "BS".
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(DataExchDefCode), '', '');

        // [GIVEN] Exported payment journal line.
        CreateAndExportVendorPaymentWithAllBusinessData(TempEFTExportWorkset, VendorBankAccount, BankAccount."No.");

        // [WHEN] Generate EFT file.
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccount."No.", LibraryRandom.RandDate(10), TempEFTExportWorkset, EFTValues);

        // [THEN] Codeunit "Read Data Exch. from Stream" was run.
        IsCodeunitRun := ERMElectronicFundsTransfer.DequeueFromLibraryVariableStorage();
        Assert.IsTrue(IsCodeunitRun, '');
    end;

    [Test]
    [HandlerFunctions('ExportElecPaymentsWord_SaveAsXmlRPH')]
    procedure RunExportElecPaymentsWordAfterValidatingAppliesToDocNo()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PostedInvoiceAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 455654] Run report "ExportElecPayments - Word" after validating Applies to Doc. No on Gen Journal line
        Initialize();

        // [GIVEN] Prepare Bank Accout, Vendor and Journal Batch
        CreateBankAccountForCountry(BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        // [GIVEN] Create and post invoice for vendor
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PostedInvoiceAmount := GetInvoiceAmount(InvoiceNo);

        // [GIVEN] Create a payment line for vendor with Applies-to Doc. No. = InvoiceNo
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Validate(Amount, -PostedInvoiceAmount);
        GenJournalLine.Modify(true);

        // [WHEN] Run report "ExportElecPayments - Word" with request page on General Journal Line from Payment Journal.
        // [WHEN] On the request page set Bank Account No.; filters for Gen. Journal Batch/Template are empty.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [THEN] Report was printed. There are no unapplied lines in dataset
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('Unapplied_Number', 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ExportElectronicPaymentsWordLayoutRequestPageHandler,ApplyVendorEntriesWithSetAppliesToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalPostPurchaseOrderVerifyDocumentNoBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 534209] Export Payment Journal When Apllies-to ID set and during Void Document No. will be blank and Applies to Entry updated by correct Document No.
        Initialize();

        // [GIVEN] Set Client Type and bindsubscription
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Export Report Selection
        CreateExportReportSelection(Layout::Word);

        // [GIVEN] Create Electronic Payment Journal with Applies-to ID set
        CreateElectronicPaymentJournalsWithApplication(GenJournalLine);

        // [WHEN] Export Payment Journals
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] VerifyCheck Exported as true
        GenJournalLine.Find();
        Assert.IsTrue(GenJournalLine."Check Exported", CheckExportedErr);

        // [WHEN] Void the Transaction as exported
        PerformVoidTransmitElecPayments(GenJournalLine);

        // [THEN] Verify GenJournalLine Document No. is blank after void the Exported file
        GenJournalLine.Find();
        Assert.AreEqual('', GenJournalLine."Document No.", DocumentNoBlankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandler')]
    procedure CompanyLogoAndAddrIsDisplayedInExportElecPaymentsWordReportOnlyWhenSetToTrueInReqPage()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 543593] Company Logo and Company Address is displayed in "ExportElecPayments - Word" report
        // only when Stan sets Print Company Address and Print Company Logo as true on request page.
        Initialize();

        // [GIVEN] Create Bank Account With Export Setup.
        CreateBankAccountForCountry(
            BankAccount,
            BankAccount."Export Format"::US,
            CreateBankExportImportSetup(CreateDataExchDefForUS()),
            '',
            '');

        // [GIVEN] Create Vendor with Bank Account.
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');

        // [GIVEN] Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");

        // [GIVEN] Create Payment Journal Lines for Vendor.
        CreateVendorPaymentLine(
            GenJournalLine,
            GenJournalBatch,
            VendorBankAccount."Vendor No.",
            VendorBankAccount.Code,
            BankAccount."No.");

        // [GIVEN] Run "ExportElecPayments - Word" report.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        // [GIVEN] Find Company Information.
        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);

        // [WHEN] Report is printed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Gen__Journal_Line___Document_No__', GenJournalLine."Document No.");
        LibraryReportDataset.GetNextRow();

        // [THEN] Company Picture is displayed in the report.
        LibraryReportDataset.CurrentRowHasElement('CompanyPicture');

        // [THEN] Address of Company Information is displyed in the report.
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress_1_', CompanyInformation.Name);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedIsTrueOnPaymentJournalAfterVoidActionIsExecuted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 546680] Export Payment Journal when "Applies-to Doc. No." set and during Void
        // "Applies-to Doc. No." will not be blank.
        Initialize();

        // [GIVEN] Set Client Type and BindSubscription.
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Export Report Selection.
        CreateExportReportSelection(Layout::RDLC);

        // [GIVEN] Create one payment journal with "Applies-to Doc. No.".
        CreateElectronicPaymentJournal(GenJournalLine);

        // [WHEN] Export Payment Journals.
        PaymentJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        // [THEN] Verify Check Exported as true.
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
        Assert.IsTrue(GenJournalLine."Check Exported", CheckExportedErr);

        // [WHEN] Void the Transaction as exported.
        PerformVoidTransmitElecPayments(GenJournalLine);

        // [THEN] Verify GenJournalLine "Applies-to DocumentNo." is True after void the Exported file.
        Assert.AreEqual(true, GenJournalLine.IsApplied(), AppliedIsTrueErr);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ExportElectronicPaymentsRequestPageHandler,VoidElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    procedure SuggestVendorPaymentForMultipleVendorAndExportAndVoidElectronicPaymentFile()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: array[2] of Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Amount: Decimal;
        RequestPageXML: Text;
        VendorNo: Text;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 563194] Verify that when the remittance is voided, the vendor documents are not unapplied from the payment.
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Electronic Bank Account.
        CreateElectronicExportBankAccount(BankAccount);

        // [GIVEN] Create a General Journal Batch using Journal Template Payments.
        CreateGeneralJournalBatchWithBalAccountType(GenJournalBatch, GenJournalTemplate.Type::Payments, BankAccount."No.");

        // [GIVEN] Create Vendor & their Bank Account.
        CreateVendorWithBankAccount(Vendor[1], VendorBankAccount[1]);
        CreateVendorWithBankAccount(Vendor[2], VendorBankAccount[2]);

        // [GIVEN] Post Multiple Vendor Ledger Entry.
        Amount := CreateAndPostVendorLedgerEntry(Vendor[1]."No.");
        CreateAndPostVendorLedgerEntry(Vendor[2]."No.");
        CreateAndPostVendorLedgerEntry(Vendor[2]."No.");
        CreateAndPostVendorLedgerEntry(Vendor[1]."No.");
        CreateAndPostVendorLedgerEntry(Vendor[1]."No.");

        VendorNo := Vendor[1]."No." + '|' + Vendor[2]."No.";
        PaymentJournal.OpenEdit();

        // [GIVEN] Suggest Vendor Payment with Summarize per Vendor  set True.
        SuggestVendorPayment(PaymentJournal, GenJournalBatch.Name, VendorNo, BankAccount."No.");

        // [GIVEN] Set Vendor Bank Account in Payment Journal Page.
        SetVendorBankAccountInPaymentJournal(PaymentJournal, VendorBankAccount[1].Code, VendorBankAccount[2].Code);

        // [GIVEN] Export Electronic File.
        InvokeExportPaymentJournalAction(PaymentJournal, GenJournalBatch, BankAccount."No.");

        Commit();
        // [WHEN] Void the exported file.
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        PaymentJournal.VoidPayments.Invoke();

        // [THEN] Vendor Ledger Entry should be contain the "Applies-to ID".
        VendorLedgerEntry.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        Assert.IsFalse(VendorLedgerEntry.IsEmpty(), StrSubstNo(VendorLedgLedgerErr, VendorLedgerEntry.TableCaption));

        // [GIVEN] Set Request Page Parameter
        FindGenJnlLine(GenJournalLine, GenJournalBatch);
        EnqueueMultipleValues(BankAccount."No.", GenJournalBatch);

        // [WHEN] Run Export Electronic Payments Reports 2nd time.
        Commit();
        RequestPageXML := Report.RunRequestPage(Report::"Export Electronic Payments", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Export Electronic Payments", GenJournalLine, RequestPageXML);

        // [THEN] verify Data.
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Ledger_Entry__Document_Type_', 'Invoice');
        LibraryReportDataset.AssertElementWithValueNotExist('Text004', 'Unapplied Amount');
        LibraryReportDataset.AssertElementWithValueExists('AmountPaid_Control43', Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ExportElectronicPaymentsRequestPageHandler,VoidElectronicPaymentsRequestPageHandler,ApplyVendorEntriesWithSetAppliesToIDModalPageHandler,ConfirmHandler')]
    procedure ManualVendorPaymentForAVendorStillRemainsAppliedEvenIfVoidedAfterExport()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: array[2] of Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 572812] When Stan runs Void action for two Payment type Gen. Journal Lines created
        // for different Vendors, one using Suggest Vendor Payments action and another one manually,
        // then "Applies-to ID" doesn't become blank in them.
        Initialize();
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        BindSubscription(TestClientTypeSubscriber);
        BindSubscription(ERMElectronicFundsTransfer);

        // [GIVEN] Create Electronic Bank Account.
        CreateElectronicExportBankAccount(BankAccount);

        // [GIVEN] Create a General Journal Batch using Journal Template Payments.
        CreateGeneralJournalBatchWithBalAccountType(GenJournalBatch, GenJournalTemplate.Type::Payments, BankAccount."No.");

        // [GIVEN] Create Vendor & their Bank Account.
        CreateVendorWithBankAccount(Vendor[1], VendorBankAccount[1]);
        CreateVendorWithBankAccount(Vendor[2], VendorBankAccount[2]);

        // [GIVEN] Post Multiple Vendor Ledger Entry.
        CreateAndPostVendorLedgerEntry(Vendor[1]."No.");
        CreateAndPostVendorLedgerEntry(Vendor[2]."No.");

        // [GIVEN] Suggest Vendor Payment with Summarize per Vendor set to True.
        PaymentJournal.OpenEdit();
        SuggestVendorPayment(PaymentJournal, GenJournalBatch.Name, Vendor[1]."No.", BankAccount."No.");

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor[1]."No.");
        VendorLedgerEntry.FindFirst();

        // [GIVEN] Find Gen. Journal Line.
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account No.", Vendor[1]."No.");
        GenJournalLine.FindFirst();

        // [GIVEN] Validate "Applies-to Doc. Type" and "Applies-to Doc. No." in Gen. Journal Line.
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);

        // [GIVEN] Set Vendor Bank Account in Payment Journal Page.
        PaymentJournal.First();
        PaymentJournal."Recipient Bank Account".SetValue(VendorBankAccount[1].Code);

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor[2]."No.");
        VendorLedgerEntry.FindFirst();

        // [GIVEN] Create Payment Gen. Journal Line.
        CreatePaymentGLLine(
            GenJournalLine, GenJournalBatch,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            Vendor[2]."No.",
            GenJournalLine."Applies-to Doc. Type"::" ",
            '',
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccount."No.",
            VendorLedgerEntry.Amount);

        // [GIVEN] Validate "Recipient Bank Account" and "Document No." in Gen. Journal Line.
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount[2].Code);
        GenJournalLine.Validate("Document No.", LibraryRandom.RandText(MaxStrLen(GenJournalLine."Document No.")));
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);

        // [GIVEN] Run Apply Entries action.
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.Filter.SetFilter("Account No.", Vendor[2]."No.");
        PaymentJournal.ApplyEntries.Invoke();

        // [GIVEN] Export Electronic File.
        InvokeExportPaymentJournalAction(PaymentJournal, GenJournalBatch, BankAccount."No.");
        Commit();

        // [GIVEN] Void the exported file.
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        PaymentJournal.VoidPayments.Invoke();

        // [WHEN] Find Gen. Journal Line.
        GenJournalLine.SetRange("Account No.", Vendor[1]."No.");
        GenJournalLine.FindFirst();

        // [THEN] "Applies-to ID" is not blank in Gen. Journal Line.
        Assert.IsTrue(GenJournalLine."Applies-to ID" <> '', '');

        // [WHEN] Find Gen. Journal Line.
        GenJournalLine.SetRange("Account No.", Vendor[2]."No.");
        GenJournalLine.FindFirst();

        // [THEN] "Applies-to ID" is not blank in Gen. Journal Line.
        Assert.IsTrue(GenJournalLine."Applies-to ID" <> '', '');
    end;

    [HandlerFunctions('ExportElecPaymentsWordRequestPageHandlerWithAmt')]
    [Test]
    procedure TheRemittanceAdviceGeneratedFromThePaymentJournalsPageIsNotAccurateWhenTheInvoicesBeingPaidArEInAForeignCurrency()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ExportElectronicPayments: Report "Export Electronic Payments";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        // [SCENATIO 576329] The Remittance Advice generated from the Payment Journals page is not accurate when the invoices being paid are in a foreign currency.
        Initialize();

        // [GIVEN] Create Vendor and Vendor Bank account.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.0, 1.0));
        Vendor.Modify(true);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(111111, 999999));
        VendorBankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        VendorBankAccount."Use for Electronic Payments" := true;
        VendorBankAccount."Transit No." := '0610000104';
        VendorBankAccount.Modify();
        DocumentNo := CreateAndPostPurchaseInvoiceWithOneLine(Vendor."No.", '123', 0D);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry."Amount to Apply" := 87.90;
        VendorLedgerEntry.CalcFields("Amount (LCY)");

        // [GIVEN] Create Bank account.
        CreateBankAccountPayment(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::CA);
        CreateBankAccWithBankSetup(BankAccount, 'US EFT DEFAULT');

        // [GIVEN] Create Genereal journal Batch and  Payment Journal Line
        CreateGeneralJournalBatchPayment(GenJournalBatch, BankAccount."No.");
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.",
          VendorLedgerEntry."Amount to Apply", VendorBankAccount.Code);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Amount (LCY)");

        // [WHEN] Export Electronic Payment
        GenJournalLine.SetRecFilter();
        ExportElectronicPayments.SetTableView(GenJournalLine);
        ExportElectronicPayments.UseRequestPage(false);
        Commit();
        ExportElectronicPayments.RunModal();

        // [GIVEN] Run "ExportElecPayments - Word" report.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Amount (LCY)");

        // [WHEN] Export Electronic Paymeny wordLayout
        RunReportExportElecPaymentsWord(GenJournalLine, true);

        //[THEN] Check unapplied amount not exists both reports.
        LibraryReportDataset.AssertElementWithValueNotExist('Text004', 'Unapplied Amount');
    end;

    local procedure Initialize()
    var
        EFTExport: Record "EFT Export";
    begin
        LibraryVariableStorage.Clear();
        ModifyFederalIdCompanyInformation(LibraryUtility.GenerateGUID());
        EFTExport.DeleteAll();

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        CreateCountryRegion('US');
        CreateCountryRegion('CA');
        CreateCountryRegion('MX');

        IsInitialized := true;
    end;

    local procedure CreateCountryRegion(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryRegionCode) then begin
            CountryRegion.Code := CountryRegionCode;
            CountryRegion.Insert();
        end;
        CountryRegion."ISO Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(CountryRegion."ISO Code"));
        CountryRegion.Modify();
    end;

    local procedure ValidateEFTCAHeader(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTCAOutputFileFormatErr: Label 'Error in EFT CA file output';
        Expected, Actual : Text;
    begin
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBHeader."Record Count"), 6, '0', 0);
        Actual := Line.Substring(1, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := TempACHRBHeader."Record Type";
        Actual := Line.Substring(7, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := TempACHRBHeader."Transaction Code";
        Actual := Line.Substring(8, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBHeader."Client Number"), 10, '0', 1);
        Actual := Line.Substring(11, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBHeader."Client Name"), 30, ' ', 1);
        Actual := Line.Substring(21, 30);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBHeader."File Creation Number"), 4, '0', 0);
        Actual := Line.Substring(51, 4);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBHeader."File Creation Date"), 7, '0', 0);
        Actual := Line.Substring(55, 7);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHRBHeader."Currency Type", 1, 3), 3, ' ', 1);
        Actual := Line.Substring(62, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := TempACHRBHeader."Input Type";
        Actual := Line.Substring(65, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);
    end;

    local procedure ReadText(Line: Text; var Pos: Integer; Length: Integer) SubString: Text
    begin
        SubString := Line.Substring(Pos, Length);
        Pos += Length;
    end;

    local procedure ValidateEFTUSHeaderA(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTUSOutputFileFormatErr: Label 'Error in EFT US file output';
        Expected, Actual : Text;
        ValueAsDateTime, CreationDateTime : DateTime;
        Pos: Integer;
    begin
        Pos := 1;
        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '01';
        Actual := ReadText(Line, Pos, 2);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSHeader."Transit Routing Number", 1, 10), 10, ' ', 1);
        Actual := ReadText(Line, Pos, 10);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := CopyStr(TempACHUSHeader."Federal ID No.", 1, 9);
        Actual := ReadText(Line, Pos, 9);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := Format(TempACHUSHeader."File Creation Date", 0, '<Year,2><Month,2><Day,2>');
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        CreationDateTime := CreateDateTime(Today(), TempACHUSHeader."File Creation Time");
        Evaluate(ValueAsDateTime, Format(CreationDateTime, 0, 9), 9);
        Expected := Format(ValueAsDateTime, 0, '<Hours24,2><Minutes,2>');
        Actual := ReadText(Line, Pos, 4);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '094';
        Actual := ReadText(Line, Pos, 3);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '10';
        Actual := ReadText(Line, Pos, 2);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSHeader."Bank Name", 1, 23), 23, ' ', 1);
        Actual := ReadText(Line, Pos, 23);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(Uppercase(TempACHUSHeader."Company Name"), 1, 23), 23, ' ', 1);
        Actual := ReadText(Line, Pos, 23);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSHeader.Reference, 1, 8), 8, ' ', 1);
        Actual := ReadText(Line, Pos, 8);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);
    end;

    local procedure ValidateEFTUSHeaderB(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTUSOutputFileFormatErr: Label 'Error in EFT US file output';
        Expected, Actual : Text;
        Pos: Integer;
    begin
        Pos := 1;
        Expected := '5';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '220';
        Actual := ReadText(Line, Pos, 3);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(Uppercase(TempACHUSHeader."Company Name"), 1, 36), 36, ' ', 1);
        Actual := ReadText(Line, Pos, 36);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := CopyStr(TempACHUSHeader."Federal ID No.", 1, 9);
        Actual := ReadText(Line, Pos, 9);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := 'CTX';
        Actual := ReadText(Line, Pos, 3);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSHeader."Company Entry Description", 1, 10), 10, ' ', 1);
        Actual := ReadText(Line, Pos, 10);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := Format(TempACHUSHeader."Company Descriptive Date", 0, '<Year,2><Month,2><Day,2>');
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := Format(TempACHUSHeader."Effective Date", 0, '<Year,2><Month,2><Day,2>');
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSHeader."Filler/Reserved", 1, 3), 3, ' ', 1);
        Actual := ReadText(Line, Pos, 3);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := CopyStr(TempACHUSHeader."Transit Routing Number", 1, 8);
        Actual := ReadText(Line, Pos, 8);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSHeader."Batch Number"), 7, '0', 0);
        Actual := ReadText(Line, Pos, 7);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

    end;

    local procedure ValidateEFTCADetail(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTCAOutputFileFormatErr: Label 'Error in EFT CA file output';
        Expected, Actual : Text;
    begin
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Record Count"), 6, '0', 0);
        Actual := Line.Substring(1, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'C';
        Actual := Line.Substring(7, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Transaction Code"), 3, ' ', 1);
        Actual := Line.Substring(8, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Client Number"), 10, '0', 1);
        Actual := Line.Substring(11, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := ' ';
        Actual := Line.Substring(21, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Customer/Vendor Number"), 19, ' ', 1);
        Actual := Line.Substring(22, 19);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Payment Number"), 2, '0', 1);
        Actual := Line.Substring(41, 2);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(TempACHRBDetail."Bank No.", 4, '0', 0);
        Actual := Line.Substring(43, 4);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(TempACHRBDetail."Transit Routing No.", 5, '0', 0);
        Actual := Line.Substring(47, 5);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(TempACHRBDetail."Recipient Bank No.", 18, ' ', 1);
        Actual := Line.Substring(52, 18);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := ' ';
        Actual := Line.Substring(70, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        // Payment amount is multiplied by 100, then default formatted.
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Payment Amount" * 100, 0, 1), 10, '0', 0);
        Actual := Line.Substring(71, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '      ';
        Actual := Line.Substring(81, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Payment Date"), 7, ' ', 1);
        Actual := Line.Substring(87, 7);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Vendor/Customer Name"), 30, ' ', 1);
        Actual := Line.Substring(94, 30);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := CopyStr(TempACHRBDetail."Language Code", 1, 1);
        Actual := Line.Substring(124, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := ' ';
        Actual := Line.Substring(125, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Client Name"), 15, ' ', 1);
        Actual := Line.Substring(126, 15);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := CopyStr(TempACHRBDetail."Currency Code", 1, 3);
        Actual := Line.Substring(141, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := ' ';
        Actual := Line.Substring(144, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Country"), 3, ' ', 1);
        Actual := Line.Substring(145, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '  ';
        Actual := Line.Substring(148, 2);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '  ';
        Actual := Line.Substring(150, 2);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'N';
        Actual := Line.Substring(152, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);
    end;

    local procedure ValidateEFTUSDetail(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTUSOutputFileFormatErr: Label 'Error in EFT US file output';
        Expected, Actual : Text;
        Pos: Integer;
    begin
        Pos := 1;
        Expected := '6';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSDetail."Transaction Code"), 2, '0', 0);
        Actual := ReadText(Line, Pos, 2);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Payee Transit Routing Number", 1, 9), 9, ' ', 0);
        Actual := ReadText(Line, Pos, 9);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Payee Bank Account Number", 1, 17), 17, ' ', 1);
        Actual := ReadText(Line, Pos, 17);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSDetail."Payment Amount" * 100, 0, 1), 10, '0', 0);
        Actual := ReadText(Line, Pos, 10);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Payee ID/Cross Reference Numbe", 1, 15), 15, ' ', 1);
        Actual := ReadText(Line, Pos, 15);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSDetail."Addenda Record Indicator"), 4, '0', 0);
        Actual := ReadText(Line, Pos, 4);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(Uppercase(TempACHUSDetail."Payee Name"), 1, 22), 22, ' ', 1);
        Actual := ReadText(Line, Pos, 22);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Filler/Reserved", 1, 2), 2, ' ', 1);
        Actual := ReadText(Line, Pos, 2);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Discretionary Data", 1, 2), 2, ' ', 1);
        Actual := ReadText(Line, Pos, 2);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSDetail."Addenda Record Indicator"), 1, '0', 0);
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSDetail."Trace Number", 1, 15), 15, ' ', 1);
        Actual := ReadText(Line, Pos, 15);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

    end;

    local procedure ValidateEFTCADetailAddress1(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTCAOutputFileFormatErr: Label 'Error in EFT CA file output';
        Expected, Actual : Text;
    begin
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Record Count"), 6, '0', 0);
        Actual := Line.Substring(1, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'C';
        Actual := Line.Substring(7, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'AD1';
        Actual := Line.Substring(8, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD1Client No"), 10, '0', 1);
        Actual := Line.Substring(11, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(UpperCase(TempACHRBDetail."AD1Company Name"), 30, ' ', 1);
        Actual := Line.Substring(21, 30);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(UpperCase(CopyStr(TempACHRBDetail.AD1Address, 1, 35)), 35, ' ', 1);
        Actual := Line.Substring(51, 35);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(UpperCase(TempACHRBDetail."AD1City State"), 35, ' ', 1);
        Actual := Line.Substring(86, 35);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(UpperCase(TempACHRBDetail."AD1Region Code/Post Code"), 32, ' ', 1);
        Actual := Line.Substring(121, 32);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);
    end;

    local procedure ValidateEFTCADetailAddress2(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTCAOutputFileFormatErr: Label 'Error in EFT CA file output';
        Expected, Actual : Text;
    begin
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."Record Count"), 6, '0', 0);
        Actual := Line.Substring(1, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'C';
        Actual := Line.Substring(7, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'AD2';
        Actual := Line.Substring(8, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Client No"), 10, '0', 1);
        Actual := Line.Substring(11, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Recipient Address"), 35, ' ', 1);
        Actual := Line.Substring(21, 35);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Recipient City/County"), 35, ' ', 1);
        Actual := Line.Substring(56, 35);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Region Code/Post Code"), 35, ' ', 1);
        Actual := Line.Substring(91, 35);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Transaction Type Code"), 3, ' ', 1);
        Actual := Line.Substring(126, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBDetail."AD2Company Entry Description"), 10, ' ', 1);
        Actual := Line.Substring(129, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '              ';
        Actual := Line.Substring(139, 14);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);
    end;

    local procedure ValidateEFTCAFooter(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTCAOutputFileFormatErr: Label 'Error in EFT CA file output';
        Expected, Actual : Text;
    begin
        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBFooter."Record Count"), 6, '0', 0);
        Actual := Line.Substring(1, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := 'Z';
        Actual := Line.Substring(7, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := TempACHRBFooter."Transaction Code";
        Actual := Line.Substring(8, 3);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBFooter."Client Number"), 10, '0', 1);
        Actual := Line.Substring(11, 10);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBFooter."Credit Payment Transactions"), 6, '0', 0);
        Actual := Line.Substring(21, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBFooter."Total File Credit" * 100, 0, 1), 14, '0', 0);
        Actual := Line.Substring(27, 14);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '000000';
        Actual := Line.Substring(41, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '00000000000000';
        Actual := Line.Substring(47, 14);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '00';
        Actual := Line.Substring(61, 2);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHRBFooter."Number of Cust Info Records"), 6, '0', 0);
        Actual := Line.Substring(63, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '            ';
        Actual := Line.Substring(69, 12);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '      ';
        Actual := Line.Substring(81, 6);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '                                                               ';
        Actual := Line.Substring(87, 63);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := '  ';
        Actual := Line.Substring(150, 2);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);

        Expected := ' ';
        Actual := Line.Substring(152, 1);
        Assert.AreEqual(Expected, Actual, EFTCAOutputFileFormatErr);
    end;

    local procedure ValidateEFTUSFooterA(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTUSOutputFileFormatErr: Label 'Error in EFT US file output';
        Expected, Actual : Text;
        Pos: Integer;
    begin
        Pos := 1;
        Expected := '8';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '220';
        Actual := ReadText(Line, Pos, 3);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Entry Addenda Count"), 6, '0', 0);
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Batch Hash Total", 0, 1), 10, '0', 0);
        Actual := ReadText(Line, Pos, 10);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Total Batch Debit Amount" * 100, 0, 1), 12, '0', 0);
        Actual := ReadText(Line, Pos, 12);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Total Batch Credit Amount" * 100, 0, 1), 12, '0', 0);
        Actual := ReadText(Line, Pos, 12);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := '1';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSFooter."Federal ID No.", 1, 9), 9, ' ', 1);
        Actual := ReadText(Line, Pos, 9);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSFooter."Filler/Reserved", 1, 19), 19, ' ', 1);
        Actual := ReadText(Line, Pos, 19);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSFooter."Filler/Reserved", 1, 6), 6, ' ', 1);
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSFooter."Transit Routing Number", 1, 8), 8, ' ', 1);
        Actual := ReadText(Line, Pos, 8);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Batch Number"), 7, '0', 0);
        Actual := ReadText(Line, Pos, 7);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);
    end;

    local procedure ValidateEFTUSFooterB(Line: Text)
    var
        StrConvMangement: Codeunit StringConversionManagement;
        EFTUSOutputFileFormatErr: Label 'Error in EFT US file output';
        Expected, Actual : Text;
        Pos: Integer;
    begin
        Pos := 1;
        Expected := '9';
        Actual := ReadText(Line, Pos, 1);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Batch Count"), 6, '0', 0);
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Block Count"), 6, '0', 0);
        Actual := ReadText(Line, Pos, 6);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Entry Addenda Count"), 8, '0', 0);
        Actual := ReadText(Line, Pos, 8);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."File Hash Total", 0, 1), 10, '0', 0);
        Actual := ReadText(Line, Pos, 10);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Total File Debit Amount" * 100, 0, 1), 12, '0', 0);
        Actual := ReadText(Line, Pos, 12);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(Format(TempACHUSFooter."Total File Credit Amount" * 100, 0, 1), 12, '0', 0);
        Actual := ReadText(Line, Pos, 12);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

        Expected := StrConvMangement.GetPaddedString(CopyStr(TempACHUSFooter."Filler/Reserved", 1, 39), 39, ' ', 1);
        Actual := ReadText(Line, Pos, 39);
        Assert.AreEqual(Expected, Actual, EFTUSOutputFileFormatErr);

    end;

    local procedure ReadEFTFileOutputLines(DataExchDefCode: Code[20]; DetailCode: Code[20]) Lines: List of [Text]
    var
        DataExch: Record "Data Exch.";
        Text: Text;
        InStream: InStream;
    begin
        DataExch.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExch.SetRange("Data Exch. Line Def Code", DetailCode);
        DataExch.FindFirst();
        DataExch.CalcFields("File Content");
        DataExch."File Content".CreateInStream(InStream);

        while not InStream.EOS() do begin
            InStream.ReadText(Text);
            Lines.Add(Text);
        end;
    end;

    local procedure DeleteBankAccount(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.Delete();
    end;

    local procedure CreateDataExchangeColumnDefFieldMappingForDateColumn(var DataExchColumnDef: Record "Data Exch. Column Def"; TableID: Integer; FieldNo: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchColumnDef.Name := StrSubstNo('%1 Date', LibraryUtility.GenerateGUID());
        DataExchColumnDef.Modify();

        DataExchFieldMapping."Data Exch. Def Code" := DataExchColumnDef."Data Exch. Def Code";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchColumnDef."Data Exch. Line Def Code";
        DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";
        DataExchFieldMapping."Table ID" := TableID;
        DataExchFieldMapping."Field ID" := FieldNo;
        if not DataExchFieldMapping.Insert() then;
    end;

    local procedure CreateAndExportPaymentJournal(DocumentType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; TransactionCode: Code[3]; CompanyEntryDescription: Code[10]; ReportDirectRun: Boolean; CustomerBankAccountCode: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        CreatePaymentJournal(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::"Bank Account", CreateAndModifyBankAccount(),
          GenJournalLine."Applies-to Doc. Type"::" ", '', BalAccountType, AccountNo, Amount, CustomerBankAccountCode);
        GenJournalLine.Validate("Transaction Type Code", GenJournalLine."Transaction Type Code"::BUS);
        GenJournalLine.Validate("Transaction Code", TransactionCode);
        GenJournalLine.Validate("Company Entry Description", CompanyEntryDescription);
        GenJournalLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        if ReportDirectRun then
            asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine)
        else
            ExportPaymentJournal(PaymentJournal, GenJournalLine);
    end;

    local procedure CreateAndModifyBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, LibraryUtility.GenerateGUID(), BankAccount."Export Format"::CA);
        CreateBankAccWithBankStatementSetup(BankAccount, 'CA EFT DEFAULT');
        BankAccount.Validate("Client No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Client Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Input Qualifier", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomerBankAccountWithCustomer(UseForElectronicPayments: Boolean; var CustomerBankAccountCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
    begin
        // Need to create Customer Bank Account. Insertion is specific to test and required only once.
        LibrarySales.CreateCustomer(Customer);
        if CustomerBankAccount2.FindFirst() then
            CustomerBankAccount2.Validate("Use for Electronic Payments", true);

        CustomerBankAccount.Init();
        CustomerBankAccount.Validate("Customer No.", Customer."No.");
        CustomerBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Customer Bank Account", CustomerBankAccount.FieldNo(Code))));
        CustomerBankAccount.Insert(true);
        CustomerBankAccount.Validate("Bank Branch No.", CustomerBankAccount2."Bank Branch No.");
        CustomerBankAccount.Validate("Bank Account No.", CustomerBankAccount2."Bank Account No.");
        CustomerBankAccount.Validate(IBAN, CustomerBankAccount2.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", CustomerBankAccount2."SWIFT Code");
        CustomerBankAccount.Validate("Use for Electronic Payments", UseForElectronicPayments);
        CustomerBankAccount.Modify(true);
        CustomerBankAccountCode := CustomerBankAccount.Code;
        exit(CustomerBankAccount."Customer No.");
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; TransitNo: Code[20]; ExportFormat: Option)
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Export Format", ExportFormat);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Remittance Advice No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("E-Pay Export File Path", TemporaryPath);
        BankAccount.Validate("E-Pay Trans. Program Path", TempPathTxt);
        BankAccount.Validate("Last E-Pay Export File Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Transit No.", TransitNo);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountForCountry(var BankAccount: Record "Bank Account"; ExportFormat: Option; BankExportImportSetupCode: Code[20]; ClientNo: Code[10]; ClientName: Code[30])
    begin
        CreateBankAccount(BankAccount, GetTransitNo(ExportFormat), ExportFormat);
        BankAccount.Validate("Payment Export Format", BankExportImportSetupCode);
        BankAccount.Validate("EFT Export Code", BankExportImportSetupCode);
        BankAccount.Validate("Client No.", ClientNo);
        BankAccount.Validate("Client Name", ClientName);
        BankAccount.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        BankAccount.Modify(true);
    end;

    local procedure CreateElectronicPaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreatePaymentJournalAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.", BankAccount."No.");
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify();
        Commit();
    end;

    local procedure CreateTestElectronicPaymentJournalWordLayout(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);
    end;

    local procedure CreateElectronicPaymentJournalNoUseForElecPayment(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        ModifyUseForElectronicPaymentsVendorBankAccount(VendorBankAccount, false);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreatePaymentJournalAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.", BankAccount."No.");
        Commit();
    end;

    local procedure CreateElectronicMultiplePaymentJournals(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreateMultiplePaymentJournalsAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.",
          BankAccount."No.", VendorBankAccount.Code);
        Commit();
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        GenJournalBatch.Modify();
    end;

    local procedure CreatePaymentJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal; CustomerBankAccountCode: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, AccountNo);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Recipient Bank Account", CustomerBankAccountCode);
        GenJournalLine.Modify(true);
    end;

    local procedure ExportPaymentJournalAndVerifyXML(AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; CustomerBankAccountCode: Code[20])
    var
        Amount: Decimal;
    begin
        // Exercise.
        Amount := LibraryRandom.RandDec(10, 2);  // Random value for Amount.
        CreateAndExportPaymentJournal(
          DocumentType, BalAccountType, AccountNo, -Amount, CopyStr(LibraryUtility.GenerateGUID(), 1, 3),
          LibraryUtility.GenerateGUID(), true, CustomerBankAccountCode);

        // Verify: Verify Account No. and Amount Paid on XML file.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(MyBalCaptionTxt, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists('AmountPaid', Amount);
    end;

    local procedure CreatePaymentGLLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                            AccountNo: Code[20];
                                                                                                                                                            AppliesToDocType: Enum "Gen. Journal Document Type";
                                                                                                                                                            AppliesToDocNo: Code[20];
                                                                                                                                                            BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                            BalAccountNo: Code[20];
                                                                                                                                                            Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Payment Reference", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentJournalAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        CreatePurchaseOrder(PurchaseHeader, VendorNo);
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateMultiplePaymentJournalsAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20]; BankAccountCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        CreatePurchaseOrder(PurchaseHeader, VendorNo);
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", BankAccountCode);
        GenJournalLine.Modify();
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", BankAccountCode);
        GenJournalLine.Modify();
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
    end;

    local procedure CreateAndExportVendorPayments(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorBankAccount: array[2] of Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EFTExport: Record "EFT Export";
        PaymentJournal: TestPage "Payment Journal";
        InvoiceNo: Code[20];
        i: Integer;
    begin
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);
        for i := 1 to ArrayLen(VendorBankAccount) do begin
            CreatePurchaseOrder(PurchaseHeader, VendorBankAccount[i]."Vendor No.");
            PurchaseHeader.CalcFields(Amount);
            InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            CreatePaymentGLLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
              GenJournalLine."Account Type"::Vendor, VendorBankAccount[i]."Vendor No.",
              GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo,
              GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
              PurchaseHeader.Amount);
            GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount[i].Code);
            GenJournalLine.Modify(true);
        end;

        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        Assert.RecordCount(EFTExport, ArrayLen(VendorBankAccount));
        EFTExport.FindSet();
        repeat
            EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(TempEFTExportWorkset.Description));
            TempEFTExportWorkset.TransferFields(EFTExport);
            TempEFTExportWorkset.Include := true;
            TempEFTExportWorkset.Insert();
        until EFTExport.Next() = 0;
    end;

    local procedure CreateVendorPaymentLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; VendorBankAccountNo: Code[20]; BankAccountNo: Code[20])
    begin
        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Applies-to Doc. Type"::" ", '',
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandInt(1000));
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndExportVendorPayment(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var GenJournalLine: Record "Gen. Journal Line"; VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        EFTExport: Record "EFT Export";
        PaymentJournal: TestPage "Payment Journal";
        InvoiceNo: Code[20];
    begin
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);

        CreatePurchaseOrder(PurchaseHeader, VendorBankAccount."Vendor No.");
        PurchaseHeader.CalcFields(Amount);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePaymentGLLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorBankAccount."Vendor No.",
          GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();

        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        Assert.RecordCount(EFTExport, 1);
        EFTExport.FindFirst();

        EFTExport.TestField("Sequence No.");
        GenJournalLine.Find();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTExport."Sequence No.");

        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert();
    end;

    local procedure CreateAndExportVendorPaymentWithAllBusinessData(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndExportVendorPayment(TempEFTExportWorkset, GenJournalLine, VendorBankAccount, BankAccountNo);
        TempEFTExportWorkset.TestField("Document No.");
        TempEFTExportWorkset.TestField("External Document No.");
        TempEFTExportWorkset.TestField("Applies-to Doc. No.");
        TempEFTExportWorkset.TestField("Payment Reference");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
        VATPostingSetup.Insert();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-EFT";
        if DataExchDefCode <> '' then
            BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();

        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
    end;

    local procedure CreateVendorWithVendorBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; CountryCode: Code[10])
    var
        DummyBankAccount: Record "Bank Account";
        ExportFormat: Option;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Modify(true);

        case CountryCode of
            'US':
                ExportFormat := DummyBankAccount."Export Format"::US;
            'CA':
                ExportFormat := DummyBankAccount."Export Format"::CA;
            'MX':
                ExportFormat := DummyBankAccount."Export Format"::MX;
        end;

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Transit No.", GetTransitNo(ExportFormat));
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateBankExportImportSetup(DataExchDefCode: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-EFT");
        BankExportImportSetup.Validate("Processing Codeunit ID", Codeunit::"Exp. Launcher EFT");
        BankExportImportSetup.Validate("Data Exch. Def. Code", DataExchDefCode);
        BankExportImportSetup.Insert();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateDataExchDefForCA(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
        ACHRBFooter: Record "ACH RB Footer";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Number"));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Date"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH RB Header", ACHRBHeader.FieldNo("Settlement Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Number"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Detail", Codeunit::"Exp. Pre-Mapping Det EFT CA", Codeunit::"Exp. Mapping Det EFT RB");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Detail", ACHRBDetail.FieldNo("File Creation Number"));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH RB Detail", ACHRBDetail.FieldNo("Payment Reference"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Footer);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH RB Footer", Codeunit::"Exp. Pre-Mapping Foot EFT", Codeunit::"Exp. Mapping Foot EFT CA");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH RB Footer", ACHRBFooter.FieldNo("File Creation Number"));

        exit(DataExchDef.Code);
    end;

    local procedure CreateDataExchDefForUS(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHUSHeader: Record "ACH US Header";
        ACHUSDetail: Record "ACH US Detail";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH US Header", ACHUSHeader.FieldNo("File Creation Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH US Header", ACHUSHeader.FieldNo("File Creation Date"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH US Header", ACHUSHeader.FieldNo("Effective Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH US Detail", Codeunit::"Exp. Pre-Mapping Det EFT US", Codeunit::"Exp. Mapping Det EFT US");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH US Detail", ACHUSDetail.FieldNo("Payment Reference"));

        exit(DataExchDef.Code);
    end;

    local procedure CreateDataExchDefForMX(): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        ACHCecobanHeader: Record "ACH Cecoban Header";
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        LineDefCode: Code[20];
        ColumnNo: Integer;
    begin
        CreateDataExchDef(DataExchDef);

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 6, '0', Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Record Type"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Header);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Header", Codeunit::"Exp. Pre-Mapping Head EFT", Codeunit::"Exp. Mapping Head EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 4, '0', Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Record Type"));
        ColumnNo := CreateDataExchColumnDefForDate(DataExchDef.Code, LineDefCode);
        CreateDataExchFieldMapping(
            DataExchDef.Code, LineDefCode, ColumnNo, Database::"ACH Cecoban Header", ACHCecobanHeader.FieldNo("Settlement Date"));

        LineDefCode := CreateDataExchLineDef(DataExchDef.Code, DataExchLineDef."Line Type"::Detail);
        CreateDataExchMapping(
            DataExchDef.Code, LineDefCode, Database::"ACH Cecoban Detail", Codeunit::"Exp. Pre-Mapping Det EFT MX", Codeunit::"Exp. Mapping Det EFT MX");
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 35, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("External Document No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 20, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Applies-to Doc. No."));
        AddDataExchDefColumnWithMapping(DataExchDef.Code, LineDefCode, 50, '', Database::"ACH Cecoban Detail", ACHCecobanDetail.FieldNo("Payment Reference"));

        exit(DataExchDef.Code);
    end;

    local procedure AddDataExchDefColumnWithMapping(DataExchDefCode: Code[20]; LineDefCode: Code[20]; Length: Integer; PadChar: Text[1]; TableID: Integer; FieldID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        ColumnNo := CreateDataExchColumnDefForText(DataExchDefCode, LineDefCode, Length, PadChar, DataExchColumnDef.Justification::Right);
        CreateDataExchFieldMapping(DataExchDefCode, LineDefCode, ColumnNo, TableID, FieldID);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Validate(Type, DataExchDef.Type::"EFT Payment Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Validate("Validation Codeunit", Codeunit::"Exp. Validation EFT");
        DataExchDef.Validate("Reading/Writing Codeunit", Codeunit::"Exp. Writing EFT");
        DataExchDef.Validate("Reading/Writing XMLport", Xmlport::"Export Generic Fixed Width");
        DataExchDef.Validate("Ext. Data Handling Codeunit", Codeunit::"Exp. External Data EFT");
        DataExchDef.Validate("User Feedback Codeunit", Codeunit::"Exp. User Feedback EFT");
        DataExchDef.Insert(true);
    end;

    local procedure CreateDataExchLineDef(DataExchDefCode: Code[20]; LineType: Option): Code[20]
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchLineDef."Line Type" := LineType;
        DataExchLineDef.Code := LibraryUtility.GenerateGUID();
        DataExchLineDef.Insert(true);
        exit(DataExchLineDef.Code);
    end;

    local procedure CreateDataExchColumnDefForText(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; Length: Integer; PadCharacter: Text[1]; Justification: Option): Integer
    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
    begin
        exit(
            CreateDataExchColumnDef(
                DataExchDefCode, DataExchLineDefCode, DummyDataExchColumnDef."Data Type"::Text, '', '', Length, PadCharacter, Justification));
    end;

    local procedure CreateDataExchColumnDefForDate(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]): Integer
    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
    begin
        exit(
            CreateDataExchColumnDef(
                DataExchDefCode, DataExchLineDefCode, DummyDataExchColumnDef."Data Type"::Date, 'en-us', '<Year,2><Month,2><Day,2>', 6, '', 0));
    end;

    local procedure CreateDataExchColumnDef(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; DataType: Option; DataFormattingCulture: Text[10]; DataFormat: Text[100]; Length: Integer; PadCharacter: Text[1]; Justification: Option): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        if DataExchColumnDef.FindLast() then;

        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchColumnDef."Column No." += 1;
        DataExchColumnDef.Name := LibraryUtility.GenerateGUID();
        DataExchColumnDef.Validate("Data Type", DataType);
        DataExchColumnDef.Validate("Data Formatting Culture", DataFormattingCulture);
        DataExchColumnDef.Validate("Data Format", DataFormat);
        DataExchColumnDef.Validate(Length, Length);
        DataExchColumnDef.Validate("Pad Character", PadCharacter);
        DataExchColumnDef.Validate(Justification, Justification);
        DataExchColumnDef.Insert(true);
        exit(DataExchColumnDef."Column No.")
    end;

    local procedure CreateDataExchMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableID: Integer; PreMappingID: Integer; MappingID: Integer)
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchMapping.Validate("Table ID", TableID);
        DataExchMapping.Validate("Pre-Mapping Codeunit", PreMappingID);
        DataExchMapping.Validate("Mapping Codeunit", MappingID);
        DataExchMapping.Validate("Post-Mapping Codeunit", 0);
        DataExchMapping.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; TableID: Integer; FieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchFieldMapping.Validate("Column No.", ColumnNo);
        DataExchFieldMapping.Validate("Table ID", TableID);
        DataExchFieldMapping.Validate("Field ID", FieldID);
        DataExchFieldMapping.Validate(Optional, true);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure MockExportPayment(var GenJournalLine: Record "Gen. Journal Line"; SequenceNo: Integer)
    var
        EFTExport: Record "EFT Export";
    begin
        GenJournalLine.Find();
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Check Printed" := true;
        GenJournalLine."EFT Export Sequence No." := SequenceNo;
        GenJournalLine.Modify();

        EFTExport.Init();
        EFTExport."Journal Template Name" := GenJournalLine."Journal Template Name";
        EFTExport."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        EFTExport."Line No." := GenJournalLine."Line No.";
        EFTExport."Sequence No." := SequenceNo;
        EFTExport."Bank Payment Type" := GenJournalLine."Bank Payment Type";
        EFTExport."Account Type" := GenJournalLine."Account Type";
        EFTExport."Account No." := GenJournalLine."Account No.";
        EFTExport."Bal. Account Type" := GenJournalLine."Bal. Account Type";
        EFTExport."Bal. Account No." := GenJournalLine."Bal. Account No.";
        EFTExport."Bank Account No." := GenJournalLine."Bal. Account No.";
        EFTExport.Insert();
    end;

    procedure DequeueFromLibraryVariableStorage() Variable: Variant
    begin
        LibraryVariableStorage.Dequeue(Variable);
    end;

    local procedure DuplicateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def"; var BankExportImportSetupTarget: Record "Bank Export/Import Setup"; DataExchDefCodeSource: Code[20])
    var
        DataExchLineDefSource: Record "Data Exch. Line Def";
        DataExchLineDefTarget: Record "Data Exch. Line Def";
        DataExchColumnDefSource: Record "Data Exch. Column Def";
        DataExchColumnDefTarget: Record "Data Exch. Column Def";
        BankExportImportSetupSource: Record "Bank Export/Import Setup";
        DataExchMappingSource: Record "Data Exch. Mapping";
        DataExchMappingTarget: Record "Data Exch. Mapping";
        DataExchFieldMappingSource: Record "Data Exch. Field Mapping";
        DataExchFieldMappingTarget: Record "Data Exch. Field Mapping";
    begin
        DataExchDef.Get(DataExchDefCodeSource);
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Name := LibraryUtility.GenerateGUID();
        DataExchDef.Insert();

        DataExchLineDefSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
        DataExchLineDefSource.FindSet();
        repeat
            DataExchLineDefTarget := DataExchLineDefSource;
            DataExchLineDefTarget."Data Exch. Def Code" := DataExchDef.Code;
            DataExchLineDefTarget.Code := LibraryUtility.GenerateGUID();
            DataExchLineDefTarget.Insert();

            DataExchColumnDefSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
            DataExchColumnDefSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
            DataExchColumnDefSource.FindSet();
            repeat
                DataExchColumnDefTarget := DataExchColumnDefSource;
                DataExchColumnDefTarget."Data Exch. Def Code" := DataExchDef.Code;
                DataExchColumnDefTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                DataExchColumnDefTarget.Insert();
            until DataExchColumnDefSource.Next() = 0;

            DataExchMappingSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
            DataExchMappingSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
            DataExchMappingSource.FindSet();
            repeat
                DataExchMappingTarget := DataExchMappingSource;
                DataExchMappingTarget."Data Exch. Def Code" := DataExchDef.Code;
                DataExchMappingTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                DataExchMappingTarget.Insert();

                DataExchFieldMappingSource.SetRange("Data Exch. Def Code", DataExchDefCodeSource);
                DataExchFieldMappingSource.SetRange("Data Exch. Line Def Code", DataExchLineDefSource.Code);
                DataExchFieldMappingSource.SetRange("Table ID", DataExchMappingSource."Table ID");
                DataExchFieldMappingSource.FindSet();
                repeat
                    DataExchFieldMappingTarget := DataExchFieldMappingSource;
                    DataExchFieldMappingTarget."Data Exch. Def Code" := DataExchDef.Code;
                    DataExchFieldMappingTarget."Data Exch. Line Def Code" := DataExchLineDefTarget.Code;
                    DataExchFieldMappingTarget.Insert();
                until DataExchFieldMappingSource.Next() = 0;
            until DataExchMappingSource.Next() = 0;
        until DataExchLineDefSource.Next() = 0;

        BankExportImportSetupSource.SetRange("Data Exch. Def. Code", DataExchDefCodeSource);
        BankExportImportSetupSource.FindFirst();

        BankExportImportSetupTarget := BankExportImportSetupSource;
        BankExportImportSetupTarget.Validate("Data Exch. Def. Code", DataExchDef.Code);
        BankExportImportSetupTarget.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetupTarget.Insert();
    end;

    local procedure PrepareEFTExportScenario(var GenJournalLine: Record "Gen. Journal Line"; var PaymentJournal: TestPage "Payment Journal")
    var
        EFTExport: Record "EFT Export";
    begin
        CreateExportReportSelection(Layout::Word);
        CreateElectronicPaymentJournal(GenJournalLine);

        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        Commit();

        FindEFTExport(EFTExport, GenJournalLine);
        EFTExport.TestField("Check Exported", true);
        EFTExport.TestField("Check Printed", true);
    end;

    local procedure GetInvoiceAmount(InvoiceNo: Code[20]): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNo);
        PurchInvHeader.CalcFields(Amount);
        exit(PurchInvHeader.Amount)
    end;

    local procedure PrepareEFTSequenceNoScenario(var GenJournalBatch: Record "Gen. Journal Batch"; var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; var LastSequenceNo: Integer)
    var
        EFTExport: Record "EFT Export";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        LastSequenceNo := LibraryRandom.RandInt(1000);
        EFTExport."Sequence No." := LastSequenceNo;
        EFTExport.Insert();
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        BankAccountNo := BankAccount."No.";
    end;

    local procedure PrepareGenJournalLineForPrintReport(var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateBankAccountForCountry(
            BankAccount, BankAccount."Export Format"::US, CreateBankExportImportSetup(CreateDataExchDefForUS()), '', '');
        CreateVendorWithVendorBankAccount(Vendor, VendorBankAccount, 'US');
        CreateGeneralJournalBatch(GenJournalBatch, BankAccount."No.");
        CreateVendorPaymentLine(GenJournalLine, GenJournalBatch, VendorBankAccount."Vendor No.", VendorBankAccount.Code, BankAccount."No.");
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Check Transmitted" := true;
        GenJournalLine.Modify();
    end;

    local procedure PrintElectronicPaymentsRDLC(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElectronicPayments: Report "Export Electronic Payments";
    begin
        GenJournalLine.SetRecFilter();
        ExportElectronicPayments.SetTableView(GenJournalLine);
        ExportElectronicPayments.UseRequestPage(UseRequestPage);
        Commit();
        ExportElectronicPayments.RunModal();
    end;

    local procedure PrintElectronicPaymentsWord(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElecPaymentsWord: Report "ExportElecPayments - Word";
    begin
        GenJournalLine.SetRecFilter();
        ExportElecPaymentsWord.SetTableView(GenJournalLine);
        ExportElecPaymentsWord.UseRequestPage(UseRequestPage);
        Commit();
        ExportElecPaymentsWord.RunModal();
    end;

    local procedure RunReportExportElecPaymentsWord(var GenJournalLine: Record "Gen. Journal Line"; UseRequestPage: Boolean)
    var
        ExportElecPaymentsWord: Report "ExportElecPayments - Word";
    begin
        ExportElecPaymentsWord.SetTableView(GenJournalLine);
        ExportElecPaymentsWord.UseRequestPage(UseRequestPage);
        Commit();
        ExportElecPaymentsWord.RunModal();
    end;

    local procedure ProcessAndGenerateEFTFile(EFTExport: Record "EFT Export"; BankAccountNo: Code[20])
    var
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        GenerateEFT: Codeunit "Generate EFT";
        EFTValues: Codeunit "EFT Values";
    begin
        TempEFTExportWorkset.TransferFields(EFTExport);
        TempEFTExportWorkset.Include := true;
        TempEFTExportWorkset.Insert();
        GenerateEFT.ProcessAndGenerateEFTFile(BankAccountNo, WorkDate(), TempEFTExportWorkset, EFTValues);
    end;

    local procedure ExportPaymentJournal(var PaymentJournal: TestPage "Payment Journal"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        Commit();  // Commit required.
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ExportPaymentsToFile.Invoke();  // Invokes action Export.
    end;

    local procedure ExportPaymentJournalViaAction(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        PaymentJournal.OpenEdit();
        ExportPaymentJournal(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
    end;

    local procedure PerformVoidTransmitElecPayments(var GenJournalLine: Record "Gen. Journal Line")
    var
        VoidTransmitElecPayments: Report "Void/Transmit Elec. Payments";
    begin
        Commit();
        VoidTransmitElecPayments.SetUsageType(1);   // Void
        VoidTransmitElecPayments.SetTableView(GenJournalLine);
        VoidTransmitElecPayments.SetBankAccountNo(GenJournalLine."Bal. Account No.");
        VoidTransmitElecPayments.UseRequestPage(false);
        VoidTransmitElecPayments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentJournalDirect(var PaymentJournal: TestPage "Payment Journal"; GenJournalLine: Record "Gen. Journal Line")
    var
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        GenJnlLineRecRef: RecordRef;
        TempDirectory: Text;
    begin
        Commit();  // Commit required.

        // Functions expect this to be opened and set up
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");

        GenJournalLine.SetFilter("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJnlLineRecRef.GetTable(GenJournalLine);
        GenJnlLineRecRef.SetView(GenJournalLine.GetView());

        TempDirectory := FileManagement.CombinePath(TemporaryPath, TempSubDirectoryTxt);
        if not FileManagement.ServerDirectoryExists(TempDirectory) then
            FileManagement.ServerCreateDirectory(TempDirectory);

        // Handle the layout runs
        CustomLayoutReporting.SetOutputFileBaseName('Test Remittance');
        CustomLayoutReporting.SetSavePath(TempDirectory);
        CustomLayoutReporting.SetOutputOption(CustomLayoutReporting.GetXMLOption());
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"V.Remittance", GenJnlLineRecRef, GenJournalLine.FieldName("Account No."), DATABASE::Vendor,
          Vendor.FieldName("No."), false);
    end;

    local procedure FindAndUpdateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Transit No.", TransitNoTxt);
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);
        Vendor.Validate(Name, Vendor.Name + '_Name');
        Vendor.Validate("Currency Code", '');
        Vendor.Modify(true);
    end;

    local procedure FindEFTExport(var EFTExport: Record "EFT Export"; GenJournalLine: Record "Gen. Journal Line")
    begin
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        EFTExport.SetRange("Line No.", GenJournalLine."Line No.");
        EFTExport.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; BalAccountNo: Code[20])
    begin
        GLEntry.SetCurrentKey("Document Type", "Document No.", "Bal. Account No.");
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetTransitNo(ExportFormat: Option): Code[20]
    var
        DummyBankAccount: Record "Bank Account";
    begin
        case ExportFormat of
            DummyBankAccount."Export Format"::US:
                exit('123456780');
            DummyBankAccount."Export Format"::MX:
                exit('123456780123456780');
            DummyBankAccount."Export Format"::CA:
                exit(TransitNoTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBHeader(var TempACHRBHeaderResult: Record "ACH RB Header" temporary)
    begin
        Clear(TempACHRBHeaderResult);
        TempACHRBHeaderResult.DeleteAll();

        TempACHRBHeaderResult.Copy(TempACHRBHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBDetail(var TempACHRBDetailResult: Record "ACH RB Detail" temporary)
    begin
        Clear(TempACHRBDetailResult);
        TempACHRBDetailResult.DeleteAll();

        TempACHRBDetailResult.Copy(TempACHRBDetail, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHRBFooter(var TempACHRBFooterResult: Record "ACH RB Footer" temporary)
    begin
        Clear(TempACHRBFooterResult);
        TempACHRBFooterResult.DeleteAll();

        TempACHRBFooterResult.Copy(TempACHRBFooter, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHUSHeader(var TempACHUSHeaderResult: Record "ACH US Header" temporary)
    begin
        Clear(TempACHUSHeaderResult);
        TempACHUSHeaderResult.DeleteAll();

        TempACHUSHeaderResult.Copy(TempACHUSHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHUSDetail(var TempACHUSDetailResult: Record "ACH US Detail" temporary)
    begin
        Clear(TempACHUSDetailResult);
        TempACHUSDetailResult.DeleteAll();

        TempACHUSDetailResult.Copy(TempACHUSDetail, true);
    end;

    procedure GetTempACHUSFooter(var TempACHUSFooterResult: Record "ACH US Footer" temporary)
    begin
        Clear(TempACHUSFooterResult);
        TempACHUSFooterResult.DeleteAll();

        TempACHUSFooterResult.Copy(TempACHUSFooter, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHCecobanHeader(var TempACHCecobanHeaderResult: Record "ACH Cecoban Header" temporary)
    begin
        Clear(TempACHCecobanHeaderResult);
        TempACHCecobanHeaderResult.DeleteAll();

        TempACHCecobanHeaderResult.Copy(TempACHCecobanHeader, true);
    end;

    [Scope('OnPrem')]
    procedure GetTempACHCecobanDetail(var TempACHCecobanDetailResult: Record "ACH Cecoban Detail" temporary)
    begin
        Clear(TempACHCecobanDetailResult);
        TempACHCecobanDetailResult.DeleteAll();

        TempACHCecobanDetailResult.Copy(TempACHCecobanDetail, true);
    end;

    local procedure GetFilesListFromZip(var FilesList: List of [Text])
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ZipFile: File;
        ZipInStream: InStream;
        ZipPath: Text;
    begin
        ZipPath := FileManagement.CombinePath(TemporaryPath(), 'AllReports.zip');
        Assert.IsTrue(Exists(ZipPath), 'AllReports.zip is not found');
        ZipFile.Open(ZipPath);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(FilesList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
        CheckClearAllReportsZip();
    end;

    local procedure CheckClearAllReportsZip()
    var
        FileManagement: Codeunit "File Management";
        ZipPath: Text;
    begin
        ZipPath := FileManagement.CombinePath(TemporaryPath(), 'AllReports.zip');
        if Exists(ZipPath) then
            Erase(ZipPath);
    end;

    local procedure GetFilesFromZipArchive(ZipFileName: Text; var FileNames: List of [Text]);
    var
        DataCompression: Codeunit "Data Compression";
        ZipFile: File;
        ExtractedFile: File;
        ZipInStream: InStream;
        FileOutStream: OutStream;
        EntryName: Text;
        EntryList: List of [Text];
        FileName: Text;
    begin
        ZipFile.Open(ZipFileName);
        ZipFile.CreateInStream(ZipInStream);
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(EntryList);
        foreach EntryName in EntryList do begin
            FileName := FileMgt.ServerTempFileName(FileMgt.GetExtension(EntryName));
            FileNames.Add(FileName);
            ExtractedFile.Create(FileName);
            ExtractedFile.CreateOutStream(FileOutStream);
            DataCompression.ExtractEntry(EntryName, FileOutStream);
            ExtractedFile.Close();
        end;
        ZipFile.Close();
    end;

    local procedure ModifyUseForElectronicPaymentsVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; CheckBoxValue: Boolean)
    begin
        VendorBankAccount.SetFilter("Vendor No.", '<>''''');
        VendorBankAccount.FindFirst();
        VendorBankAccount.Validate("Use for Electronic Payments", CheckBoxValue);
        VendorBankAccount.Modify(true);
    end;

    local procedure ModifyFederalIdCompanyInformation(FederalIDNo: Text[30])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Federal ID No.", FederalIDNo);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateForceDocBalanceOnGenJnlTemplate(GenJournalTemplateName: Code[10]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalTemplateName);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure UpdateNameOnVendor(var Vendor: Record Vendor; VendorName: Text[100])
    begin
        Vendor.Validate(Name, VendorName);
        Vendor.Modify(true);
    end;

    local procedure VoidCheckCheckLedgerEntries(BankAccountNo: Code[20])
    var
        CheckLedgerEntries: TestPage "Check Ledger Entries";
    begin
        CheckLedgerEntries.OpenEdit();
        CheckLedgerEntries.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        CheckLedgerEntries."Void Check".Invoke();  // Invokes action VoidCheck.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElectronicPayments.BankAccountNo.SetValue(BankAccountNo);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments.OutputMethod.SetValue('PDF');
        ExportElectronicPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsXMLRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElectronicPayments.BankAccountNo.SetValue(BankAccountNo);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure ExportElectronicPaymentsOutputXMLRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Excel,XML;
    begin
        ExportElectronicPayments.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElectronicPayments.OutputMethod.SetValue(SupportedOutputMethod::XML);
        ExportElectronicPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsWordLayoutRequestPageHandler(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        ExportElecPaymentsWord.BankAccountNo.SetValue(BankAccountNo);
        ExportElecPaymentsWord.OutputMethod.SetValue('PDF');
        ExportElecPaymentsWord.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ExportElectronicPaymentsWordOutputXMLRequestPageHandler(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    var
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Word,XML;
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord.OutputMethod.SetValue(SupportedOutputMethod::XML);
        ExportElecPaymentsWord.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWord_SaveAsXmlRPH(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWordRequestPageHandler(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord.PrintCompanyAddress.SetValue(LibraryVariableStorage.DequeueBoolean());
        ExportElecPaymentsWord.PrintCompanyLogo.SetValue(LibraryVariableStorage.DequeueBoolean());
        ExportElecPaymentsWord.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRH(var ExportElectronicPayments: Report "Export Electronic Payments")
    begin
        ExportElectronicPayments.SaveAsPdf(LibraryUtility.GenerateGUID());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWordRH(var ExportElecPaymentsWord: Report "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.SaveAsPdf(LibraryUtility.GenerateGUID());
    end;

    [Scope('OnPrem')]
    procedure CreateExportReportSelection("Layout": Option RDLC,Word)
    var
        ReportSelections: Record "Report Selections";
    begin
        // Insert or modify to get the expected remittance report selection
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"V.Remittance";
        case Layout of
            Layout::RDLC:
                ReportSelections."Report ID" := REPORT::"Export Electronic Payments";
            Layout::Word:
                ReportSelections."Report ID" := REPORT::"ExportElecPayments - Word";
        end;
        ReportSelections.Sequence := '1';
        ReportSelections.Insert();
        Commit();
    end;

    local procedure UpdateDateFormatsOnCAEFTDataExchDef(DataExchDef: Record "Data Exch. Def"; DateFormat: Text[100]; DateFormatLength: Integer; AddFieldMapping: Boolean)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBDetail: Record "ACH RB Detail";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Header);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Name, ACHRBHeader.FieldName("File Creation Date"));
        DataExchColumnDef.FindFirst();
        DataExchColumnDef."Data Format" := DateFormat;
        DataExchColumnDef.Length := DateFormatLength;
        DataExchColumnDef.Modify(true);

        if AddFieldMapping then
            CreateDataExchangeColumnDefFieldMappingForDateColumn(
                DataExchColumnDef, DATABASE::"ACH RB Header", ACHRBHeader.FieldNo("File Creation Date"));

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.SetRange(Name, ACHRBDetail.FieldName("Payment Date"));
        DataExchColumnDef.FindFirst();
        DataExchColumnDef."Data Format" := DateFormat;
        DataExchColumnDef.Length := DateFormatLength;
        DataExchColumnDef.Modify(true);

        if AddFieldMapping then
            CreateDataExchangeColumnDefFieldMappingForDateColumn(
                DataExchColumnDef, DATABASE::"ACH RB Detail", ACHRBDetail.FieldNo("Payment Date"));
    end;

    local procedure UpdateExtDataHandlingCodOnDataExchDef(DataExchDefCode: Code[20]; ExtDataHandlingCodeunitNo: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(DataExchDefCode);
        DataExchDef.Validate("Ext. Data Handling Codeunit", ExtDataHandlingCodeunitNo);
        DataExchDef.Modify(true);
    end;

    local procedure InsertEntryDetailSequenceNo(DataExchDef: Record "Data Exch. Def")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ACHUSDetail: Record "ACH US Detail";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.FindLast();
        DataExchColumnDef."Column No." += 1;
        DataExchColumnDef.Name := 'Entry Detail Sequence';
        DataExchColumnDef.Insert(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDef.Code;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";
        DataExchFieldMapping.Validate("Table ID", Database::"ACH US Detail");
        DataExchFieldMapping.Validate("Field ID", ACHUSDetail.FieldNo("Entry Detail Sequence No"));
        DataExchFieldMapping.Insert(true);
    end;

    local procedure VoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry")
    var
        CheckManagement: Codeunit CheckManagement;
        VoidType: Option "Unapply and void check","Void check only";
    begin
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
    end;

    local procedure VerifyPaymentFileError(GenJournalLine: Record "Gen. Journal Line"; PaymentFileErrorTxt: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Document No.", GenJournalLine."Document No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJournalLine."Line No.");
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", CopyStr(PaymentFileErrorTxt, 1, MaxStrLen(PaymentJnlExportErrorText."Error Text")));
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(GLEntry.Amount, Round(Amount), LibraryERM.GetAmountRoundingPrecision(), AmountVerificationMsg);
    end;

    local procedure VerifyCheckLedgEntryCount(PostingDate: Date; DocNo: Code[20]; EntryStatus: Option; ExpectedCount: Integer)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Document Type", CheckLedgerEntry."Document Type"::Payment);
        CheckLedgerEntry.SetRange("Posting Date", PostingDate);
        CheckLedgerEntry.SetRange("Document No.", DocNo);
        CheckLedgerEntry.SetRange("Entry Status", EntryStatus);
        Assert.RecordCount(CheckLedgerEntry, ExpectedCount);
    end;

    local procedure VerifyBankAccountFileCreationNumberIncrement(var BankAccount: Record "Bank Account")
    var
        LastFileCreationNo: Integer;
    begin
        LastFileCreationNo := BankAccount."Last E-Pay File Creation No.";
        BankAccount.Find();
        BankAccount.TestField("Last E-Pay File Creation No.", LastFileCreationNo + 1);
    end;

    local procedure VerifyEFTExportCA(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; FileCreationNo: Integer; SettleDate: Date)
    var
        ExportEFTRB: Codeunit "Export EFT (RB)";
    begin
        ERMElectronicFundsTransfer.GetTempACHRBHeader(TempACHRBHeader);
        TempACHRBHeader.TestField("File Creation Number", FileCreationNo);
        TempACHRBHeader.TestField("File Creation Date", ExportEFTRB.JulianDate(Today()));
        TempACHRBHeader.TestField("Settlement Date", SettleDate);
        TempACHRBHeader.TestField("Settlement Julian Date", ExportEFTRB.JulianDate(SettleDate)); // TFS 401126

        ERMElectronicFundsTransfer.GetTempACHRBDetail(TempACHRBDetail);
        TempACHRBDetail.TestField("File Creation Number", FileCreationNo);
        TempACHRBDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHRBDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHRBDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHRBDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");

        ERMElectronicFundsTransfer.GetTempACHRBFooter(TempACHRBFooter);
        TempACHRBFooter.TestField("File Creation Number", FileCreationNo);
    end;

    local procedure VerifyEFTExportUS(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; SettleDate: Date; PayeeName: Text[100])
    begin
        ERMElectronicFundsTransfer.GetTempACHUSHeader(TempACHUSHeader);
        TempACHUSHeader.TestField("Effective Date", SettleDate);

        ERMElectronicFundsTransfer.GetTempACHUSDetail(TempACHUSDetail);
        TempACHUSDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHUSDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHUSDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHUSDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");
        TempACHUSDetail.TestField("Payee Name", PayeeName);
    end;

    local procedure VerifyEFTExportMX(var ERMElectronicFundsTransfer: Codeunit "ERM Electronic Funds Transfer"; EFTExportWorkset: Record "EFT Export Workset"; SettleDate: Date)
    begin
        ERMElectronicFundsTransfer.GetTempACHCecobanHeader(TempACHCecobanHeader);
        TempACHCecobanHeader.TestField("Settlement Date", SettleDate);

        ERMElectronicFundsTransfer.GetTempACHCecobanDetail(TempACHCecobanDetail);
        TempACHCecobanDetail.TestField("Document No.", EFTExportWorkset."Document No.");
        TempACHCecobanDetail.TestField("External Document No.", EFTExportWorkset."External Document No.");
        TempACHCecobanDetail.TestField("Applies-to Doc. No.", EFTExportWorkset."Applies-to Doc. No.");
        TempACHCecobanDetail.TestField("Payment Reference", EFTExportWorkset."Payment Reference");
    end;

    local procedure VerifyLastGenJnlLineFields(var GenJournalLine: Record "Gen. Journal Line"; EFTSequenceNo: Integer; Exported: Boolean; Transmitted: Boolean)
    begin
        GenJournalLine.FindLast();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTSequenceNo);
        GenJournalLine.TestField("Check Printed", Exported);
        GenJournalLine.TestField("Check Exported", Exported);
        GenJournalLine.TestField("Check Transmitted", Transmitted);
    end;

    local procedure VerifyGenJnlLineFields(var GenJournalLine: Record "Gen. Journal Line"; EFTSequenceNo: Integer; Exported: Boolean; Transmitted: Boolean)
    begin
        GenJournalLine.Find();
        GenJournalLine.TestField("EFT Export Sequence No.", EFTSequenceNo);
        GenJournalLine.TestField("Check Printed", Exported);
        GenJournalLine.TestField("Check Exported", Exported);
        GenJournalLine.TestField("Check Transmitted", Transmitted);
    end;

    local procedure VerifyDocumentNoInXmlOutput(FileName: Text; DocumentNos: List of [Code[20]]);
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocumentNo: Code[20];
    begin
        LibraryXPathXMLReader.Initialize(FileName, '');
        foreach DocumentNo in DocumentNos do
            LibraryXPathXMLReader.VerifyNodeCountWithValueByXPath('//DataItems/DataItem/Columns/Column', DocumentNo, 1);
    end;

    local procedure VerifyDocumentNoAbsenceInXmlOutput(FileName: Text; DocumentNos: List of [Code[20]]);
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocumentNo: Code[20];
    begin
        LibraryXPathXMLReader.Initialize(FileName, '');
        foreach DocumentNo in DocumentNos do
            LibraryXPathXMLReader.VerifyNodeCountWithValueByXPath('//DataItems/DataItem/Columns/Column', DocumentNo, 0);
    end;

    local procedure FindEFTExportByGenJournalLine(var EFTExport: Record "EFT Export"; GenJournalLine: Record "Gen. Journal Line")
    begin
        EFTExport.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        EFTExport.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        EFTExport.SetRange("Line No.", GenJournalLine."Line No.");
        EFTExport.SetRange("Sequence No.", GenJournalLine."EFT Export Sequence No.");
        EFTExport.FindFirst();
    end;

    local procedure CreateElectronicPaymentJournalsWithApplication(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindAndUpdateVendorBankAccount(VendorBankAccount);
        CreateBankAccount(BankAccount, VendorBankAccount."Transit No.", BankAccount."Export Format"::US);
        CreateBankAccWithBankStatementSetup(BankAccount, 'US EFT DEFAULT');
        CreateMultiplePaymentJournalsAndApplyAfterPostPurchaseOrder(GenJournalLine, VendorBankAccount."Vendor No.",
          BankAccount."No.", VendorBankAccount.Code);
        Commit();
    end;

    local procedure CreateMultiplePaymentJournalsAndApplyAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20]; BankAccountCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePurchaseOrder(PurchaseHeader, VendorNo);
        PurchaseHeader.CalcFields(Amount);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalBatch(GenJournalBatch, BankAccountNo);

        CreatePaymentGLLine(
            GenJournalLine, GenJournalBatch,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            VendorNo,
            GenJournalLine."Applies-to Doc. Type"::" ",
            '',
            GenJournalLine."Bal. Account Type"::"Bank Account",
            BankAccountNo,
            PurchaseHeader.Amount);
        GenJournalLine.Validate("Recipient Bank Account", BankAccountCode);
        GenJournalLine.Validate("Document No.", LibraryRandom.RandText(MaxStrLen(GenJournalLine."Document No.")));
        GenJournalLine.Modify();

        ApplyVendorEntryFromPaymentJournal(GenJournalLine);

        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue for ExportElectronicPaymentsRequestPageHandler.
    end;

    local procedure ApplyVendorEntryFromPaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.Close();
    end;

    local procedure CreateElectronicExportBankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Federal ID No." = '' then begin
            CompanyInformation."Federal ID No." := LibraryUtility.GenerateGUID();
            CompanyInformation.Modify();
        end;

        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), Database::"Bank Export/Import Setup");
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-EFT");
        BankExportImportSetup.Validate("Data Exch. Def. Code", 'US EFT DEFAULT');
        BankExportImportSetup.Validate("Processing Codeunit ID", Codeunit::"Exp. Launcher EFT");
        BankExportImportSetup.Insert(true);

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Export Format", BankAccount."Export Format"::US);
        BankAccount.Validate("Transit No.", BankAccount."No.");
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Validate("Last E-Pay Export File Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Last Remittance Advice No.", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithBalAccountType(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type"; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, TemplateType);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        NoSeries.FindLast();
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Use for Electronic Payments", true);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateAndPostVendorLedgerEntry(VendorNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJournals: Codeunit "Library - Journals";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(-GenJournalLine.Amount);
    end;

    local procedure SuggestVendorPayment(var PaymentJournal: TestPage "Payment Journal"; JournalBatchName: Code[10]; VendorNo: Text; BankAccountNo: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        PaymentJournal.SuggestVendorPayments.Invoke();  // Opens handler - SuggestVendorPaymentRequestPageHandler.
    end;

    local procedure SetVendorBankAccountInPaymentJournal(var PaymentJournal: TestPage "Payment Journal"; VendorBankAccount: Code[20]; VendorBankAccount2: Code[20])
    begin
        PaymentJournal.First();
        PaymentJournal."Recipient Bank Account".SetValue(VendorBankAccount);
        PaymentJournal.Next();
        PaymentJournal."Recipient Bank Account".SetValue(VendorBankAccount2);
    end;

    local procedure InvokeExportPaymentJournalAction(var PaymentJournal: TestPage "Payment Journal"; GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        Commit();  // Commit required.
        PaymentJournal.ExportPaymentsToFile.Invoke();
    end;

    local procedure FindGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        GenJournalLine.SetRecFilter();
    end;

    local procedure EnqueueMultipleValues(BankAccountNo: Code[20]; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
    end;

    local procedure CreatePaymentGLLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                             AccountNo: Code[20];
                                                                                                                                                             AppliesToDocType: Enum "Gen. Journal Document Type";
                                                                                                                                                             AppliesToDocNo: Code[20];
                                                                                                                                                             BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                             BalAccountNo: Code[20];
                                                                                                                                                             Amount: Decimal;
                                                                                                                                                             VendorBankAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", '');
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Payment Reference", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAccWithBankSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-EFT";
        if DataExchDefCode <> '' then
            BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();

        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountPayment(var BankAccount: Record "Bank Account"; TransitNo: Code[20]; ExportFormat: Option)
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Export Format", ExportFormat);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Remittance Advice No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("E-Pay Export File Path", TemporaryPath);
        BankAccount.Validate("Last E-Pay Export File Name", LibraryUtility.GenerateGUID());
        BankAccount.Validate("Transit No.", TransitNo);
        BankAccount.Modify(true);
    end;



    local procedure CreateGeneralJournalBatchPayment(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        GenJournalBatch.Modify();
    end;


    local procedure CreateAndPostPurchaseInvoiceWithOneLine(VendorNo: Code[20]; ExtDocNo: Code[20]; DueDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItem(Item, 87.90);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", ExtDocNo);
        if DueDate <> 0D then
            PurchaseHeader.Validate("Due Date", DueDate);

        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerEnqueueQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ModalPageHandler]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    begin
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), LibraryVariableStorage.DequeueInteger());
        Response := Action::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithSetAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SuggestVendorPaymentRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());  // Using Random for Months.
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestVendorPayments.BalAccountType.SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        SuggestVendorPayments.BankPaymentType.SetValue(GenJournalLine."Bank Payment Type"::"Electronic Payment");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [RequestPageHandler]
    procedure VoidElectronicPaymentsRequestPageHandler(var VoidElectronicPayments: TestRequestPage "Void/Transmit Elec. Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        VoidElectronicPayments."BankAccount.""No.""".SetValue(BankAccountNo); // Bank Account No.
        VoidElectronicPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElecPaymentsWordRequestPageHandlerWithAmt(var ExportElecPaymentsWord: TestRequestPage "ExportElecPayments - Word")
    begin
        ExportElecPaymentsWord.BankAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord."Gen. Journal Line".SetFilter("Amount (LCY)", LibraryVariableStorage.DequeueText());
        ExportElecPaymentsWord.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnCustomReportLayout(var TestMode: Boolean)
    begin
        TestMode := true
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBHeaderModify', '', false, false)]
    local procedure StoreTempACHRBHeaderOnBeforeACHRBHeaderModify(var ACHRBHeader: Record "ACH RB Header"; BankAccount: Record "Bank Account")
    begin
        TempACHRBHeader := ACHRBHeader;
        if TempACHRBHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBDetailModify', '', false, false)]
    local procedure StoreTempACHRBDetailOnBeforeACHRBDetailModify(var ACHRBDetail: Record "ACH RB Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20]; SettleDate: Date)
    begin
        TempACHRBDetail := ACHRBDetail;
        if TempACHRBDetail.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (RB)", 'OnBeforeACHRBFooterModify', '', false, false)]
    local procedure StoreTempACHRBFooterOnBeforeACHUSDetailModify(var ACHRBFooter: Record "ACH RB Footer"; BankAccNo: Code[20])
    begin
        TempACHRBFooter := ACHRBFooter;
        if TempACHRBFooter.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnStartExportBatchOnBeforeACHUSHeaderModify', '', false, false)]
    local procedure StoreTempACHUSHeaderOnBeforeACHUSHeaderModify(var ACHUSHeader: Record "ACH US Header");
    begin
        TempACHUSHeader := ACHUSHeader;
        if TempACHUSHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnStartExportFileOnBeforeACHUSHeaderModify', '', false, false)]
    local procedure StoreTempACHUSHeaderOnBeforeACHUSHeaderModify2(var ACHUSHeader: Record "ACH US Header");
    begin
        TempACHUSHeader := ACHUSHeader;
        if TempACHUSHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnBeforeACHUSDetailModify', '', false, false)]
    local procedure StoreTempACHUSDetailOnBeforeACHUSDetailModify(var ACHUSDetail: Record "ACH US Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20])
    begin
        TempACHUSDetail := ACHUSDetail;
        if TempACHUSDetail.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnEndExportBatchOnBeforeACHUSFooterModify', '', false, false)]
    local procedure StoreTempACHUSFooterOnBeforeACHUSFooterBatchModify(var ACHUSFooter: Record "ACH US Footer"; BankAccount: Record "Bank Account")
    begin
        TempACHUSFooter := ACHUSFooter;
        if TempACHUSFooter.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnEndExportFileOnBeforeACHUSFooterModify', '', false, false)]
    local procedure StoreTempACHUSFooterOnBeforeACHUSFooterFileModify(var ACHUSFooter: Record "ACH US Footer"; BankAccount: Record "Bank Account")
    begin
        TempACHUSFooter := ACHUSFooter;
        if TempACHUSFooter.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (Cecoban)", 'OnStartExportBatchOnBeforeACHCecobanHeaderModify', '', false, false)]
    local procedure StoreTempACHCecobanHeaderOnBeforeACHCecobanHeaderModify(var ACHCecobanHeader: Record "ACH Cecoban Header")
    begin
        TempACHCecobanHeader := ACHCecobanHeader;
        if TempACHCecobanHeader.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (Cecoban)", 'OnBeforeACHCecobanDetailModify', '', false, false)]
    local procedure StoreTempACHCecobanDetailOnBeforeACHCecobanDetailModify(var ACHCecobanDetail: Record "ACH Cecoban Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20])
    begin
        TempACHCecobanDetail := ACHCecobanDetail;
        if TempACHCecobanDetail.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Read Data Exch. from Stream", 'OnGetDataExchFileContentEvent', '', false, false)]
    local procedure EnqueueBoolOnGetDataExchFileContent(DataExchIdentifier: Record "Data Exch."; var TempBlobResponse: Codeunit "Temp Blob"; var Handled: Boolean)
    var
        IsCodeunitRun: Boolean;
    begin
        IsCodeunitRun := true;
        LibraryVariableStorage.Enqueue(IsCodeunitRun);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export EFT (ACH)", 'OnBeforeDownloadWebclientZip', '', false, false)]
    local procedure VerifyBlobContentOnBeforeDownloadWebclientZip(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; TempEraseFileNameValueBuffer: Record "Name/Value Buffer" temporary; ZipFileName: Text; var DataCompression: Codeunit "Data Compression")
    begin
        if not TempNameValueBuffer.FindSet() then
            exit;
        TempNameValueBuffer.SetAutoCalcFields("Value BLOB");
        repeat
            TempNameValueBuffer.TestField("Value BLOB");
        until TempNameValueBuffer.Next() = 0;
        TempNameValueBuffer.FindSet();
    end;

}
