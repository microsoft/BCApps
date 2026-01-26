codeunit 144104 "Test SEPA PAIN 008.001.08"
{
    // // [FEATURE] [SEPA]
    // Test for SEPA Payment Reports:
    //   1. Verify Payment Amount in report Export SEPA ISO20022 after cancellation of single line in XML file.
    // 
    // TFS_TS_ID = 90332
    // Covers Test cases:
    // ----------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // ----------------------------------------------------------------
    // TestPaymentCancellation
    // 
    // ----------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // ----------------------------------------------------------------
    // TestPaymentLineCancellationExportSEPAISO20022            100414
    // TestPaymentLineRejectionExportSEPAISO20022               100414
    // TestPaymentLineCancellationSEPAISO20022Pain010103        100414
    // TestPaymentLineRejectionSEPAISO20022Pain010103           100414
    // TestPaymentLineCancellationSEPAISO20022Pain00800102      100414
    // TestPaymentLineRejectionSEPAISO20022Pain00800102         100414

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        ExportProtocol: Record "Export Protocol";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ProcessProposalLines: Codeunit "Process Proposal Lines";
        LibraryRandom: Codeunit "Library - Random";
        XMLReadHelper: Codeunit "NL XML Read Helper";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        IsInitialized: Boolean;
        ExportFileName: Text[250];
        DateErr: Label 'The Valid To date must be after the Valid From date.';
        MissingCrIdentifierErr: Label 'The Creditor Identifier must be entered on the Bank Account card.';
        MissingPartnerTypeErr: Label 'The Partner Type must be entered in the Transaction Mode field.';
        MissingMandateErr: Label 'The Mandate ID must be entered on the Customer Bank Account card.';
        PartnerTypeMismatchErr: Label 'All transactions must have the same value for Partner Type.';
        WrongSequenceTypeErr: Label 'Wrong Sequence Type. ';
        NameSpace: Text;
        SequenceTypeIdx: Option ,OOFF,FRST,RCUR,FNAL;
        ExpectedErr: Label 'Unexpected value in xml file for element <//ns:CtrlSum>.';
        UnexpectedErrorMsg: Label 'Unexpected error message in proposal line';
        ForeignCurrencyErrorTok: Label '%1 is filled in, but %2 is 0.';
        IdentificationElementName: Label 'EndToEndId';
        PaymentLineErr: Label '%1 payment line appears in the exported file!';
        CancelTok: Label 'Cancelled';
        RejectTok: Label 'Rejected';
        WrongSymbolFoundErr: Label 'Wrong symbol found';

    [Test]
    [Scope('OnPrem')]
    procedure InitSequenceTypeEmpty()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        InsertPaymentHistoryLineWithMandate(PaymentHistoryLine, DirectDebitMandate."Type of Payment"::Recurrent, 3);

        PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 0);

        Assert.AreEqual(PaymentHistoryLine."Sequence Type"::" ", PaymentHistoryLine."Sequence Type", WrongSequenceTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitSequenceTypeOOFF()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        InsertPaymentHistoryLineWithMandate(PaymentHistoryLine, DirectDebitMandate."Type of Payment"::OneOff, 1);

        PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 1);

        Assert.AreEqual(PaymentHistoryLine."Sequence Type"::OOFF, PaymentHistoryLine."Sequence Type", WrongSequenceTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitSequenceTypeFRST()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        InsertPaymentHistoryLineWithMandate(PaymentHistoryLine, DirectDebitMandate."Type of Payment"::Recurrent, 3);

        PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 1);

        Assert.AreEqual(PaymentHistoryLine."Sequence Type"::FRST, PaymentHistoryLine."Sequence Type", WrongSequenceTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitSequenceTypeRCUR()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        InsertPaymentHistoryLineWithMandate(PaymentHistoryLine, DirectDebitMandate."Type of Payment"::Recurrent, 3);

        PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 2);

        Assert.AreEqual(PaymentHistoryLine."Sequence Type"::RCUR, PaymentHistoryLine."Sequence Type", WrongSequenceTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitSequenceTypeFNAL()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        InsertPaymentHistoryLineWithMandate(PaymentHistoryLine, DirectDebitMandate."Type of Payment"::Recurrent, 3);

        PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 3);

        Assert.AreEqual(PaymentHistoryLine."Sequence Type"::FNAL, PaymentHistoryLine."Sequence Type", WrongSequenceTypeErr);
    end;

    [Test]
    [HandlerFunctions('ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteAssociatedMandateID()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");

        // verify
        DirectDebitMandate.Delete(true); // verification in the Confirmation Handler
    end;

    [Test]
    [HandlerFunctions('ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestMandateIDOnProposalLine()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");

        // verify
        ProposalLine.SetRange("Our Bank No.", BankAccount."No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Direct Debit Mandate ID", DirectDebitMandate.ID)
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestMandateIDOnPaymentHistoryLine()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // verify
        PaymentHistoryLine.SetRange("Our Bank", BankAccount."No.");
        PaymentHistoryLine.FindFirst();
        PaymentHistoryLine.TestField("Direct Debit Mandate ID", DirectDebitMandate.ID)
    end;

    [Test]
    [HandlerFunctions('ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestOnValidateValidFrom()
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        // set up
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        CreateMandate(DirectDebitMandate, Customer."No.", BankAccount."No.", WorkDate(), CalcDate('<+1M>', WorkDate()));

        // exercise
        asserterror DirectDebitMandate.Validate("Valid From", CalcDate('<+2M>', WorkDate()));
        Assert.ExpectedError(DateErr);
    end;

    [Test]
    [HandlerFunctions('ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestOnValidateValidTo()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // set up
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        CreateMandate(DirectDebitMandate, Customer."No.", BankAccount."No.", WorkDate(), CalcDate('<+1M>', WorkDate()));

        // exercise
        asserterror DirectDebitMandate.Validate("Valid To", CalcDate('<-2M>', WorkDate()));
        Assert.ExpectedError(DateErr);
    end;

    [Scope('OnPrem')]
    procedure TestPaymentRejection()
    var
        BankAccountNo: Code[20];
    begin
        Initialize();

        ExportMultilinePayment(BankAccountNo, 2, false, true);

        RejectPayment(BankAccountNo);
        VerifyPaymentIsRejected(BankAccountNo);

        ExportSEPAFile(BankAccountNo);
        VerifyZeroPaymentsInXMLFile(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestGetEntriesWithDifferentCustomerType()
    var
        BankAccount: Record "Bank Account";
        Customer1: Record Customer;
        Customer2: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer1, DirectDebitMandate);
        CreateAndPostSalesInvoice(Customer1."No.", false);

        SetUpTransactionMode(TransactionMode, BankAccount."No.", "Partner Type".FromInteger(3 - Customer1."Partner Type".AsInteger()), TransactionMode."Account Type"::Customer); // Partner Type <> Customer1.Partner Type
        CreateCustomerWithBankAccount(Customer2, BankAccount, TransactionMode.Code, TransactionMode."Partner Type", DirectDebitMandate);
        CreateAndPostSalesInvoice(Customer2."No.", false);

        // exercise
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // verify
        ProposalLine.SetRange("Our Bank No.", BankAccount."No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Error Message", PartnerTypeMismatchErr);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestProposalLineWithBlankMandateID()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        UpdateCustomerBankAccount(Customer."No.", BankAccount."No.", '');

        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // verify
        ProposalLine.SetRange("Our Bank No.", BankAccount."No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Error Message", MissingMandateErr);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestProposalLineWithBlankCreditorIdentifier()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        BankAccount.Validate("Creditor Identifier", '');
        BankAccount.Modify(true);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // verify
        ProposalLine.SetRange("Our Bank No.", BankAccount."No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Error Message", MissingCrIdentifierErr);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestProposalLineWithBlankPartnerType()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        Initialize();

        // setup
        CreateSEPABankAccount(BankAccount);
        SetUpTransactionMode(
          TransactionMode, BankAccount."No.", TransactionMode."Partner Type"::" ", TransactionMode."Account Type"::Customer);
        CreateCustomerWithBankAccount(Customer, BankAccount, TransactionMode.Code, TransactionMode."Partner Type", DirectDebitMandate);
        CreateAndPostSalesInvoice(Customer."No.", false);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);

        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // verify
        ProposalLine.SetRange("Our Bank No.", BankAccount."No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Error Message", MissingPartnerTypeErr);
    end;

    [Test]
    [HandlerFunctions('ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateMandateID()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        CustomerBankAccountCard: TestPage "Customer Bank Account Card";
    begin
        // set up
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        CreateMandate(DirectDebitMandate, Customer."No.", BankAccount."No.", 0D, 0D);

        // exercise
        CustomerBankAccountCard.OpenEdit();
        CustomerBankAccountCard.GotoKey(DirectDebitMandate."Customer No.", DirectDebitMandate."Customer Bank Account Code");
        CustomerBankAccountCard."Direct Debit Mandate ID".SetValue(DirectDebitMandate.ID);

        CustomerBankAccountCard.OK().Invoke();

        // verify
        CustomerBankAccount.Get(DirectDebitMandate."Customer No.", DirectDebitMandate."Customer Bank Account Code");
        CustomerBankAccount.TestField("Direct Debit Mandate ID", DirectDebitMandate.ID);
    end;

    [Scope('OnPrem')]
    procedure TestXMLDiffDatesDiffMandate()
    var
        BankAccountNo: Code[20];
        NumberOfPayments: Integer;
        NumberOfBatches: array[4] of Integer;
    begin
        Initialize();

        NumberOfPayments := 3;
        ExportMultilinePayment(BankAccountNo, NumberOfPayments, true, true);

        // verify
        NumberOfBatches[SequenceTypeIdx::FRST] := 2; // because last line has a diff date
        VerifyBatchesInFile(NumberOfBatches, NumberOfPayments)
    end;

    [Scope('OnPrem')]
    procedure TestXMLDiffDatesOneMandate()
    var
        BankAccountNo: Code[20];
        NumberOfPayments: Integer;
        NumberOfBatches: array[4] of Integer;
    begin
        Initialize();

        NumberOfPayments := 3;
        ExportMultilinePayment(BankAccountNo, NumberOfPayments, false, true);

        // verify
        NumberOfBatches[SequenceTypeIdx::FRST] := 1;
        NumberOfBatches[SequenceTypeIdx::RCUR] := 2; // because last line has a diff date
        VerifyBatchesInFile(NumberOfBatches, NumberOfPayments)
    end;

    [Scope('OnPrem')]
    procedure TestXMLMultipleLinesDiffMandate()
    var
        BankAccountNo: Code[20];
        NumberOfPayments: Integer;
        NumberOfBatches: array[4] of Integer;
    begin
        Initialize();

        NumberOfPayments := 3;
        ExportMultilinePayment(BankAccountNo, NumberOfPayments, true, false);

        // verify
        NumberOfBatches[SequenceTypeIdx::FRST] := 1;
        VerifyBatchesInFile(NumberOfBatches, NumberOfPayments)
    end;

    [Scope('OnPrem')]
    procedure TestXMLMultipleLinesOneMandate()
    var
        BankAccountNo: Code[20];
        NumberOfPayments: Integer;
        NumberOfBatches: array[4] of Integer;
    begin
        Initialize();

        NumberOfPayments := 3;
        ExportMultilinePayment(BankAccountNo, NumberOfPayments, false, false);

        // verify
        NumberOfBatches[SequenceTypeIdx::FRST] := 1;
        NumberOfBatches[SequenceTypeIdx::RCUR] := 1;
        VerifyBatchesInFile(NumberOfBatches, NumberOfPayments)
    end;

    [Scope('OnPrem')]
    procedure TestXMLOneLinePmt()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        NumberOfBatches: array[4] of Integer;
        NumberOfPayments: Integer;
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");
        ExportSEPAFile(BankAccount."No.");

        // verify
        NumberOfBatches[SequenceTypeIdx::FRST] := 1;
        NumberOfPayments := 1;
        VerifySEPADirectDebitFile(BankAccount."No.", NumberOfBatches, NumberOfPayments);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestXMLWithEmptyPstlAdr()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        Initialize();

        // setup
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");
        BlankPostalAdr(BankAccount."No.");
        ExportSEPAFile(BankAccount."No.");

        // verify
        VerifyPostlAdrDoesNotExist();
    end;

    [Scope('OnPrem')]
    procedure TestPaymentCancellation()
    var
        BankAccountNo: Code[20];
    begin
        // Verify Payment Amount in report Export SEPA ISO20022 after cancellation of single line in XML file.

        // Setup: Create and export multiple Payment Lines.
        Initialize();
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.08';
        CreateExportProtocol(REPORT::"SEPA ISO20022 Pain 008.001.08");
        ExportMultilinePayment(BankAccountNo, 2, false, true);

        // Exercise: Cancel single Payment Line and export XML file.
        CancelPayment(BankAccountNo);
        ExportSEPAFile(BankAccountNo);

        // Verify: Verify Amount in XML file.
        VerifyAmountInXMLFile(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineCancellationExportSEPAISO20022()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Cancel, REPORT::"SEPA ISO20022 Pain 008.001.08");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineRejectionExportSEPAISO20022()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Reject, REPORT::"SEPA ISO20022 Pain 008.001.08");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineCancellationSEPAISO20022Pain010103()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Cancel, REPORT::"SEPA ISO20022 Pain 01.01.09");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineRejectionSEPAISO20022Pain010103()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Reject, REPORT::"SEPA ISO20022 Pain 01.01.09");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineCancellationSEPAISO20022Pain00800102()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Cancel, REPORT::"SEPA ISO20022 Pain 008.001.08");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,ChangeStatusReportHandler')]
    [Scope('OnPrem')]
    procedure TestPaymentLineRejectionSEPAISO20022Pain00800102()
    var
        TestOption: Option Cancel,Reject;
    begin
        TestPaymentLine(TestOption::Reject, REPORT::"SEPA ISO20022 Pain 008.001.08");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ForeignVendorForeignBank()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        Initialize();

        // setup
        SetUpSEPAVendor(BankAccount, Vendor, CreateCurrency());

        // exercise
        CreateAndPostPurchaseInvoice(Vendor."No.");
        GetEntriesAtDate(CalcDate('<3D>', WorkDate()));
        ProcessProposals(BankAccount."No.");

        // verify
        VerifyProposalLineNoError(BankAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure VerifySEPAPmtInfInstdAmtRoundedValue()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // Check that Integer value is always exported to InstdAmt with 2 decimal symbols
        Initialize();

        // setup
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08';
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // exercise
        CreateAndPostSalesInvoice(Customer."No.", true);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");
        ExportSEPAFile(BankAccount."No.");

        // verify
        VerifySEPAPmtInfInstdAmt(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure VerifySEPAPmtInfDoesNotContainBOMSymbol()
    var
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 363157] Report 11000013 SEPA ISO20022 Pain 008.001.0 does not contain BOM symbol in the beginning of file
        Initialize();

        // [WHEN] Report 11000013 SEPA ISO20022 Pain 008.001.08 is exported to file
        ExportMultilinePayment(BankAccountNo, 1, false, false);

        // [THEN] Exported file starts with '<?xml' not with BOM symbols
        VerifyBeginningOfXMLFile(ExportFileName, '<?xml');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure VerifySEPAPmtInfGenerateChecksumFalse()
    var
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 363158] Report 11000013 SEPA ISO20022 Pain 008.001.0 does not contain generate Checksum 
        // in Payment History if Generate Checksum is set to false

        Initialize();

        // [WHEN] Report 11000013 SEPA ISO20022 Pain 008.001.08 is exported to file
        ExportMultilinePayment(BankAccountNo, 2, false, true);
        LibraryNLLocalization.SetupExportProtocolChecksum(ExportProtocol, false, false);
        ExportSEPAFile(BankAccountNo);

        // [THEN] Checksum field in the Payment History is left empty 
        LibraryNLLocalization.VerifyPaymentHistoryChecksum(BankAccountNo, false, ExportProtocol.Code);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure VerifySEPAPmtInfGenerateChecksumTrue()
    var
        BankAccountNo: code[20];
    begin
        // [SCENARIO 363159] Report SEPA ISO20022 Pain 008.001.08 generates Checksum
        // in Payment History if Generate Checksum is set to true
        Initialize();
        LibraryNLLocalization.SetupExportProtocolChecksum(ExportProtocol, true, false);
        ExportMultilinePayment(BankAccountNo, 1, false, false);

        // [THEN] Checksum field in the Payment History is populated
        LibraryNLLocalization.VerifyPaymentHistoryChecksum(BankAccountNo, true, ExportProtocol.Code);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure StreetTownAndPostCodeNodesWhenExportSepaIso20022Pain03AndWorldPaymentSet()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 423641] Street, Town, PostCode nodes in XML when export payment history using "SEPA ISO20022 Pain 01.01.09" report. Transaction Mode has WorldPayment set.
        Initialize();

        // [GIVEN] Export Protocol "Generic SEPA" with Export ID = 11000012 which is id for "SEPA ISO20022 Pain 01.01.09" report.
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 01.01.09");

        // [GIVEN] Transaction Mode "ABN" with Export Protocol "Generic SEPA" and WorldPayment = true.
        // [GIVEN] Customer with Transaction Mode "ABN" and with Bank Account "B".
        // [GIVEN] Bank Account "B" has "Account Holder Address" "3 Main Street", "Account Holder Post Code" "127473" and "Account Holder City" "Moscow".
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        UpdateWorldPaymentOnTransactionMode(TransactionMode."Account Type"::Customer, Customer."Transaction Mode Code", true);

        // [GIVEN] Posted Sales Invoice. Payment History with one line created from Posted Sales Invoice.
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // [WHEN] Export Payment History using "SEPA ISO20022 Pain 01.01.09" report.
        ExportSEPAFile(BankAccount."No.");

        // [THEN] There are three nodes StrtNm, PstCd, TwnNm under PstlAdr node.
        // [THEN] StrtNm = "3 Main Street", PstCd = "127473", TwnNm = "Moscow".
        CustomerBankAccount.Get(Customer."No.", Customer."Preferred Bank Account Code");
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:StrtNm', CustomerBankAccount."Account Holder Address");
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:PstCd', CustomerBankAccount."Account Holder Post Code");
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:TwnNm', CustomerBankAccount."Account Holder City");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure StreetTownAndPostCodeNodesWhenExportSepaIso20022Pain03AndWorldPaymentSetAndMaxLengthAddress()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TransactionMode: Record "Transaction Mode";
        Address: Text[100];
        PostCode: Code[20];
        City: Text[30];
    begin
        // [SCENARIO 423641] Street, Town, PostCode nodes in XML when export payment history using "SEPA ISO20022 Pain 01.01.09" report. Transaction Mode has WorldPayment set. Address values has max length.
        Initialize();

        // [GIVEN] Export Protocol "Generic SEPA" with Export ID = 11000012 which is id for "SEPA ISO20022 Pain 01.01.09" report.
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 01.01.09");

        // [GIVEN] Transaction Mode "ABN" with Export Protocol "Generic SEPA" and WorldPayment = true.
        // [GIVEN] Customer with Transaction Mode "ABN" and with Bank Account "B".
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        UpdateWorldPaymentOnTransactionMode(TransactionMode."Account Type"::Customer, Customer."Transaction Mode Code", true);

        // [GIVEN] Bank Account "B" has "Account Holder Address" of lenght 100, "Account Holder Post Code" of lenght 20 and "Account Holder City" of length 30.
        Address := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(Address)), 1, MaxStrLen(Address));
        PostCode := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(PostCode)), 1, MaxStrLen(PostCode));
        City := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(City)), 1, MaxStrLen(City));
        UpdateAddressPostCodeCityOnCustomerBankAccount(Customer."No.", Customer."Preferred Bank Account Code", Address, PostCode, City);

        // [GIVEN] Posted Sales Invoice. Payment History with one line created from Posted Sales Invoice.
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // [WHEN] Export Payment History using "SEPA ISO20022 Pain 01.01.09" report.
        ExportSEPAFile(BankAccount."No.");

        // [THEN] There are three nodes StrtNm, PstCd, TwnNm under PstlAdr node.
        // [THEN] StrtNm = first 70 chars of Address, PstCd = first 16 chars of Post Code, TwnNm = City.
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:StrtNm', CopyStr(Address, 1, 70));
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:PstCd', CopyStr(PostCode, 1, 16));
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:TwnNm', CopyStr(City, 1, 35));
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure StreetTownAndPostCodeNodesWhenExportSepaIso20022Pain03AndWorldPaymentNotSet()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 423641] Street, Town, PostCode nodes in XML when export payment history using "SEPA ISO20022 Pain 01.01.09" report. Transaction Mode has WorldPayment not set.
        Initialize();

        // [GIVEN] Export Protocol "Generic SEPA" with Export ID = 11000012 which is id for "SEPA ISO20022 Pain 01.01.09" report.
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 01.01.09");

        // [GIVEN] Transaction Mode "ABN" with Export Protocol "Generic SEPA" and WorldPayment = false.
        // [GIVEN] Customer with Transaction Mode "ABN" and with Bank Account "B".
        // [GIVEN] Bank Account "B" has "Account Holder Address" "3 Main Street", "Account Holder Post Code" "127473" and "Account Holder City" "Moscow".
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        UpdateWorldPaymentOnTransactionMode(TransactionMode."Account Type"::Customer, Customer."Transaction Mode Code", false);

        // [GIVEN] Posted Sales Invoice. Payment History with one line created from Posted Sales Invoice.
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        // [WHEN] Export Payment History using "SEPA ISO20022 Pain 01.01.09" report.
        ExportSEPAFile(BankAccount."No.");

        // [THEN] There are no such nodes as StrtNm, PstCd, TwnNm under PstlAdr node.
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:StrtNm');
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:PstCd');
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:TwnNm');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure StreetTownAndPostCodeNodesWhenExportSepaIso20022Pain03AndWorldPaymentSetAndBlankAddress()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 423641] Street, Town, PostCode nodes in XML when export payment history using "SEPA ISO20022 Pain 01.01.09" report. Transaction Mode has WorldPayment set. Address values are blank.
        Initialize();

        // [GIVEN] Export Protocol "Generic SEPA" with Export ID = 11000012 which is id for "SEPA ISO20022 Pain 01.01.09" report.
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 01.01.09");

        // [GIVEN] Transaction Mode "ABN" with Export Protocol "Generic SEPA" and WorldPayment = true.
        // [GIVEN] Customer with Transaction Mode "ABN" and with Bank Account "B".
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        UpdateWorldPaymentOnTransactionMode(TransactionMode."Account Type"::Customer, Customer."Transaction Mode Code", true);

        // [GIVEN] Posted Sales Invoice. Payment History with one line created from Posted Sales Invoice.
        // [GIVEN] Payment History Line has blank "Account Holder Address", "Account Holder Post Code", "Account Holder City".
        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");
        BlankPostalAdr(BankAccount."No.");

        // [WHEN] Export Payment History using "SEPA ISO20022 Pain 01.01.09" report.
        ExportSEPAFile(BankAccount."No.");

        // [THEN] There are no such nodes as StrtNm, PstCd, TwnNm under PstlAdr node.
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:StrtNm');
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:PstCd');
        XMLReadHelper.VerifyNodeAbsence('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:TwnNm');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,GetProposalEntriesRequestPageHandler')]
    procedure StreetTownAndPostCodeNodesWhenExportSepaIso20022Pain03AndWorldPaymentNotSetForDbtr()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        TransactionMode: Record "Transaction Mode";
        StreetName: Text[70];
        PostalCode: Text[16];
        TownName: Text[35];
    begin
        // [SCENARIO 527709] Verify StrtNm, PstCd and TwnNm at Dbtor section
        Initialize();

        // [GIVEN] Update address at CompanyInformation
        UpdateCompanyInfoAddress();

        // [GIVEN] Save NameSpace
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';

        // [GIVEN] Create Export Protocol
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 01.01.09", Codeunit::"Check SEPA ISO20022");

        // [GIVEN] Create SEPA Vendor
        SetUpSEPAVendorWithVendorBankAccount(BankAccount, Vendor, '');

        // [GIVEN] Update WorldPayment as false in Transaction Mode
        UpdateWorldPaymentOnTransactionMode(TransactionMode."Account Type"::Vendor, Vendor."Transaction Mode Code", false);

        // [GIVEN] Post Purchase Invoice
        CreateAndPostPurchaseInvoice(Vendor."No.");

        // [GIVEN] Get Posted Entries
        GetEntriesAtDate(CalcDate('<3D>', WorkDate()));

        // [GIVEN] Process the proposal
        ProcessProposals(BankAccount."No.");

        // [WHEN] Export Payment History using "SEPA ISO20022 Pain 01.01.09" report.
        ExportSEPAFile(BankAccount."No.");

        // [GIVEN] Get Company Address from Company Information
        GetCompanyAddress(StreetName, PostalCode, TownName);

        // [THEN] Verify the Address, Postcode and City at CompanyInformation will be shown in xml at Dbtor side
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        if StreetName <> '' then
            XMLReadHelper.VerifyNodeValue('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:Dbtr/ns:PstlAdr/ns:StrtNm', StreetName);
        if PostalCode <> '' then
            XMLReadHelper.VerifyNodeValue('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:Dbtr/ns:PstlAdr/ns:PstCd', PostalCode);
        if TownName <> '' then
            XMLReadHelper.VerifyNodeValue('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:Dbtr/ns:PstlAdr/ns:TwnNm', TownName);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure VerifySEPAISO20022Pain00800108ExportTheCorrectVersion()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistory: Record "Payment History";
    begin
        // [GIVEN 592595] Ensure the SEPA ISO 20022 PAIN.008.001.08 file exports the correct version in the XML File.
        Initialize();

        // [GIVEN] Create Export Protocol for SEPA ISO 20022 PAIN.008.001.08
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 008.001.08");

        // [GIVEN] Set up the SEPA environment
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);

        // [GIVEN] Create and post sales invoice
        CreateAndPostSalesInvoice(Customer."No.", false);

        // [WHEN] Get the proposal entries.
        GetEntries(BankAccount."No.");

        // [WHEN] Process the proposals lines.
        ProcessProposals(BankAccount."No.");

        // [THEN] Export the SEPA file.
        ExportSEPAFile(BankAccount."No.");

        // [GIVEN] Find the Payment History for the Bank Account.
        FindPaymentHistory(BankAccount."No.", PaymentHistory);

        // [THEN] Verify the exported SEPA file and check the default namespace contains SEPA version pain.008.001.08
        XMLReadHelper.Initialize(PaymentHistory."File on Disk", NameSpace);
        XMLReadHelper.VerifyAttributeValue('//ns:Document', 'xmlns', NameSpace);
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test SEPA PAIN 008.001.08");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test SEPA PAIN 008.001.08");
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        Clear(NameSpace);
        ExportFileName := TemporaryPath + CopyStr(Format(CreateGuid()), 2, 10) + '.xml';
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08';
        CreateExportProtocol(Report::"SEPA ISO20022 Pain 008.001.08");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test SEPA PAIN 008.001.08");
    end;

    local procedure BlankPostalAdr(BankAccountNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        FindPaymentHistory(BankAccountNo, PaymentHistory);
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.ModifyAll("Account Holder Address", '', false);
        PaymentHistoryLine.ModifyAll("Account Holder Post Code", '', false);
        PaymentHistoryLine.ModifyAll("Account Holder City", '', false);
        PaymentHistoryLine.ModifyAll("Acc. Hold. Country/Region Code", '', false);
    end;

    local procedure CancelPayment(BankAccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        Commit();
        FindPaymentHistoryLines(BankAccountNo, PaymentHistoryLine);
        PaymentHistoryLine.FindFirst();  // Using Findfirst to find first line in Payment History Line for Cancellation.
        PaymentHistoryLine.SetFilter("Line No.", Format(PaymentHistoryLine."Line No."));
        LibraryVariableStorage.Enqueue(PaymentHistoryLine.Status::Cancelled);
        REPORT.RunModal(REPORT::"Paymt. History - Change Status", true, true, PaymentHistoryLine);
    end;

    local procedure CreateCurrency(): Code[10]
    begin
        exit(
          LibraryERM.CreateCurrencyWithExchangeRate(
            Today(), LibraryRandom.RandDec(30, 2), LibraryRandom.RandDec(30, 2)));
    end;

    local procedure CreateMandate(var DirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustomerNo: Code[20]; BankAccountCode: Code[10]; ValidFromDate: Date; ValidToDate: Date)
    begin
        DirectDebitMandate.Init();
        DirectDebitMandate.ID := LibraryUtility.GenerateRandomCode(DirectDebitMandate.FieldNo(ID), DATABASE::"SEPA Direct Debit Mandate");
        DirectDebitMandate.Validate("Customer No.", CustomerNo);
        DirectDebitMandate.Validate("Customer Bank Account Code", BankAccountCode);
        DirectDebitMandate.Validate("Valid From", ValidFromDate);
        DirectDebitMandate.Validate("Valid To", ValidToDate);
        DirectDebitMandate.Validate("Date of Signature", WorkDate());
        DirectDebitMandate.Validate("Type of Payment", DirectDebitMandate."Type of Payment"::Recurrent);
        DirectDebitMandate.Validate("Expected Number of Debits", LibraryRandom.RandInt(10) + 5);
        DirectDebitMandate.Insert(true);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; RoundedTotal: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoice(SalesHeader, CustomerNo, RoundedTotal);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; RoundedTotal: Boolean)
    var
        SalesLine: Record "Sales Line";
        RandomValue: Decimal;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", Today);
        SalesHeader.Modify(true);
        if RoundedTotal then
            RandomValue := LibraryRandom.RandInt(10) * 100
        else
            RandomValue := LibraryRandom.RandDec(10, 2);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), RandomValue);
        SalesLine.Validate("Unit Price", RandomValue);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateExportProtocol(ExportID: Integer)
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateGUID());
        ExportProtocol.Validate("Check ID", 11000011); // Report ID
        ExportProtocol.Validate("Export ID", ExportID); // Report ID 11000013 SEPA ISO20022 Pain 08.01.02
        ExportProtocol.Validate("Docket ID", 11000004); // Report ID
        ExportProtocol.Validate("Default File Names", ExportFileName);
        ExportProtocol.Insert(true);
    end;

    local procedure CreateFreelyTransferableMax(CountryRegionCode: Code[20])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        if not FreelyTransferableMaximum.Get(CountryRegionCode, '') then begin
            FreelyTransferableMaximum.Init();
            FreelyTransferableMaximum.Validate("Country/Region Code", CountryRegionCode);
            FreelyTransferableMaximum.Validate(Amount, LibraryRandom.RandDecInRange(100000, 1000000, 2));
            FreelyTransferableMaximum.Insert(true);
        end
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer; BankAccount: Record "Bank Account"; TransactionModeCode: Code[20]; PartnerType: Enum "Partner Type"; var DirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        PostCode: Record "Post Code";
    begin
        LibrarySales.CreateCustomer(Customer);
        CustomerBankAccount.Init();
        CustomerBankAccount.Validate(Code, BankAccount.Name);
        CustomerBankAccount.Validate("Customer No.", Customer."No.");
        CustomerBankAccount.Insert(true);

        Customer.Validate("Transaction Mode Code", TransactionModeCode);
        Customer.Validate("Partner Type", PartnerType);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);

        CustomerBankAccount.Validate(Name, BankAccount.Name);
        CustomerBankAccount.Validate("Bank Account No.", BankAccount.Name);
        CustomerBankAccount.Validate("Country/Region Code", BankAccount."Country/Region Code");
        CustomerBankAccount.Validate("Account Holder Address",
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Account Holder Address"), DATABASE::"Customer Bank Account"));

        PostCode.FindFirst();
        CustomerBankAccount."Account Holder Post Code" := PostCode.Code;
        CustomerBankAccount."Account Holder City" := PostCode.City;
        CustomerBankAccount.Validate(IBAN, 'GB 12 CPBK 08929965044991'); // hard coded due to IBAN validation
        CustomerBankAccount.Validate("SWIFT Code",
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("SWIFT Code"), DATABASE::"Customer Bank Account"));
        CustomerBankAccount.Validate("Acc. Hold. Country/Region Code", BankAccount."Country/Region Code");
        CreateMandate(DirectDebitMandate, Customer."No.", BankAccount."No.", 0D, 0D);
        CustomerBankAccount.Validate("Direct Debit Mandate ID", DirectDebitMandate.ID);
        CustomerBankAccount.Modify(true);
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; BankAccount: Record "Bank Account"; TransactionModeCode: Code[20]; PartnerType: Enum "Partner Type"; CurrencyCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PostCode: Record "Post Code";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VendorBankAccount.Init();
        VendorBankAccount.Validate(Code, BankAccount.Name);
        VendorBankAccount.Validate("Vendor No.", Vendor."No.");
        VendorBankAccount.Insert(true);

        BankAccount."Min. Balance" := -LibraryRandom.RandDecInRange(100000, 1000000, 2);
        if CurrencyCode <> '' then begin
            BankAccount.Validate(Balance, 0);
            // we need reset balance before currency is set
            BankAccount.Validate("Currency Code", CurrencyCode);
            Vendor.Validate("Currency Code", CurrencyCode);
        end;
        BankAccount.Modify(true);

        Vendor.Validate("Transaction Mode Code", TransactionModeCode);
        Vendor.Validate("Partner Type", PartnerType);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);

        VendorBankAccount.Validate(Name, BankAccount.Name);
        VendorBankAccount.Validate("Bank Account No.", BankAccount.Name);
        VendorBankAccount.Validate("Country/Region Code", BankAccount."Country/Region Code");
        VendorBankAccount.Validate("Account Holder Address",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Account Holder Address"), DATABASE::"Vendor Bank Account"));

        PostCode.FindFirst();
        VendorBankAccount."Account Holder Post Code" := PostCode.Code;
        VendorBankAccount."Account Holder City" := PostCode.City;
        VendorBankAccount.Validate(IBAN, 'GB 12 CPBK 08929965044991');
        // hard coded due to IBAN validation
        VendorBankAccount.Validate("SWIFT Code",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("Acc. Hold. Country/Region Code", BankAccount."Country/Region Code");
        VendorBankAccount.Modify(true);
    end;

    local procedure ExportMultilinePayment(var BankAccountNo: Code[20]; NumberOfPayments: Integer; NewMandatePerLine: Boolean; NewDateForLastLine: Boolean)
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SetUpSEPA(BankAccount, Customer, DirectDebitMandate);
        BankAccountNo := BankAccount."No.";

        CreateAndPostSalesInvoice(Customer."No.", false);
        GetEntries(BankAccount."No.");
        MultiplyPaymentLines(BankAccount."No.", NumberOfPayments, NewMandatePerLine, NewDateForLastLine);
        ProcessProposals(BankAccount."No.");

        ExportSEPAFile(BankAccount."No.");
    end;

    local procedure ExportSEPAFile(BankAccountNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
    begin
        Commit();
        FindPaymentHistory(BankAccountNo, PaymentHistory);
        REPORT.RunModal(ExportProtocol."Export ID", false, true, PaymentHistory);
    end;

    local procedure FindPaymentHistory(BankAccountNo: Code[20]; var PaymentHistory: Record "Payment History")
    begin
        PaymentHistory.SetRange("Export Protocol", ExportProtocol.Code);
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindLast();
    end;

    local procedure FindPaymentHistoryLines(BankAccountNo: Code[20]; var PaymentHistoryLine: Record "Payment History Line")
    var
        PaymentHistory: Record "Payment History";
    begin
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
    end;

    local procedure FindPostCode(): Code[20]
    var
        PostCode: Record "Post Code";
        Found: Boolean;
    begin
        while not Found do begin
            PostCode.Reset();
            PostCode.Next(LibraryRandom.RandInt(PostCode.Count));
            PostCode.SetRange(Code, PostCode.Code);
            Found := PostCode.Count = 1; // must be one rec to avoid a lookup form.
        end;
        exit(PostCode.Code);
    end;

    local procedure GetEntries(BankAccountNo: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        Commit();
        TransactionMode.SetRange("Our Bank", BankAccountNo);
        REPORT.RunModal(REPORT::"Get Proposal Entries", false, true, TransactionMode);
    end;

    local procedure GetEntriesAtDate(CurrencyDate: Date)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(CurrencyDate);
        REPORT.RunModal(REPORT::"Get Proposal Entries", true, true, TransactionMode);
    end;

    local procedure GetMessageID(PaymentHistory: Record "Payment History"): Text[50]
    var
        MessageId: Text[50];
    begin
        MessageId := PaymentHistory."Our Bank" + PaymentHistory."Run No.";
        if StrLen(MessageId) > 35 then
            MessageId := CopyStr(MessageId, StrLen(MessageId) - 34);
        exit(MessageId)
    end;

    local procedure GetPmtInformationId(PaymentHistoryLine: Record "Payment History Line"): Text[50]
    var
        PaymentInformationId: Text[50];
    begin
        PaymentInformationId := PaymentHistoryLine."Our Bank" + PaymentHistoryLine."Run No." + Format(PaymentHistoryLine."Line No.");
        if StrLen(PaymentInformationId) > 35 then
            PaymentInformationId := CopyStr(PaymentInformationId, StrLen(PaymentInformationId) - 34);
        exit(PaymentInformationId)
    end;

    local procedure GetPmtHistoryLineSumAmount(PaymentHistory: Record "Payment History"): Text[18]
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.Reset();
        PaymentHistoryLine.SetCurrentKey("Our Bank", Status, "Run No.", Order, Date);
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.CalcSums(Amount);
        exit(Format(-PaymentHistoryLine.Amount, 0, 9));
    end;

    local procedure GetSequenceTypeText(SequenceType: Integer): Text[4]
    begin
        SequenceTypeIdx := SequenceType;
        exit(Format(SequenceTypeIdx));
    end;

    local procedure GetUnstructiredRemittanceInfo(PaymentHistoryLine: Record "Payment History Line"): Text[250]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailLine: Record "Detail Line";
    begin
        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
        DetailLine.SetFilter(Status, '%1|%2|%3', DetailLine.Status::"In process", DetailLine.Status::Posted, DetailLine.Status::Correction);
        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
        DetailLine.FindFirst();
        CustLedgEntry.Get(DetailLine."Serial No. (Entry)");
        exit(CustLedgEntry."Document No.");
    end;

    local procedure InsertPaymentHistoryLineWithMandate(var PaymentHistoryLine: Record "Payment History Line"; TypeOfPayment: Option; NoOfDebits: Integer)
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        DirectDebitMandate.Init();
        DirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        DirectDebitMandate."Type of Payment" := TypeOfPayment;
        DirectDebitMandate."Expected Number of Debits" := NoOfDebits;
        DirectDebitMandate.Insert();

        PaymentHistoryLine."Run No." := LibraryUtility.GenerateGUID();
        PaymentHistoryLine."Line No." := 1;
        PaymentHistoryLine."Direct Debit Mandate ID" := DirectDebitMandate.ID;
        PaymentHistoryLine."Sequence Type" := PaymentHistoryLine."Sequence Type"::" ";
        PaymentHistoryLine.Insert();
    end;

    local procedure MultiplyPaymentLines(BankAccountNo: Code[20]; NumberOfPayments: Integer; NewMandatePerPayment: Boolean; NewDateForLastPayment: Boolean)
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        ProposalLine: Record "Proposal Line";
        NoSeries: Codeunit "No. Series";
        LineNo: Integer;
    begin
        ProposalLine.SetRange("Our Bank No.", BankAccountNo);
        ProposalLine.FindFirst();
        for LineNo := 1 to NumberOfPayments - 1 do begin
            ProposalLine."Line No." += 1;
            ProposalLine.Identification := NoSeries.GetNextNo(ProposalLine."Identification No. Series", ProposalLine."Transaction Date");
            if NewMandatePerPayment then begin
                CreateMandate(DirectDebitMandate, ProposalLine."Account No.", ProposalLine.Bank, 0D, 0D);
                ProposalLine."Direct Debit Mandate ID" := DirectDebitMandate.ID;
            end;
            if (LineNo = NumberOfPayments - 1) and NewDateForLastPayment then
                ProposalLine."Transaction Date" += 1;
            ProposalLine.Insert();
        end;
    end;

    local procedure ProcessProposals(BankAccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Our Bank No.", BankAccountNo);
        ProposalLine.FindFirst();
        ProcessProposalLines.Run(ProposalLine);
        ProcessProposalLines.ProcessProposallines();
    end;

    local procedure RejectPayment(BankAccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        Commit();
        FindPaymentHistoryLines(BankAccountNo, PaymentHistoryLine);
        LibraryVariableStorage.Enqueue(PaymentHistoryLine.Status::Rejected);
        REPORT.RunModal(REPORT::"Paymt. History - Change Status", true, true, PaymentHistoryLine);
    end;

    local procedure TestPaymentLine(TestOption: Option Cancel,Reject; ReportNo: Integer)
    var
        BankAccountNo: Code[20];
        PaymentHistoryLine: Record "Payment History Line";
        Identification: Code[80];
        ErrorMessage: Text;
    begin
        // Setup: Create and export multiple Payment Lines.
        Initialize();
        NameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09';

        CreateExportProtocol(ReportNo);

        ExportMultilinePayment(BankAccountNo, 2, false, true);

        FindPaymentHistoryLines(BankAccountNo, PaymentHistoryLine);
        PaymentHistoryLine.FindFirst();
        Identification := PaymentHistoryLine.Identification;

        // Exercise: Cancel single Payment Line and export XML file.
        case TestOption of
            TestOption::Cancel:
                begin
                    CancelPayment(BankAccountNo);
                    ErrorMessage := StrSubstNo(PaymentLineErr, CancelTok);
                end;
            TestOption::Reject:
                begin
                    RejectPayment(BankAccountNo);
                    ErrorMessage := StrSubstNo(PaymentLineErr, RejectTok);
                end;
        end;

        ExportSEPAFile(BankAccountNo);

        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        Assert.IsFalse(XMLReadHelper.VerifyExists(IdentificationElementName, Identification), ErrorMessage);
    end;

    local procedure CreateSEPABankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := SetUpCountrySEPAAllowed();
        CreateFreelyTransferableMax(CountryRegionCode);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Creditor Identifier",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Creditor Identifier"), DATABASE::"Bank Account"));
        BankAccount.Validate("SWIFT Code", Format(LibraryRandom.RandInt(1000000000))); // SWIFTCode
        BankAccount.Validate("Country/Region Code", CountryRegionCode);
        BankAccount.Validate(Balance, 1000000 + LibraryRandom.RandInt(1000000)); // Balance must be positive
        BankAccount.Validate(IBAN, 'GB 12 CPBK 08929965044991'); // hard coded due to IBAN validation
        BankAccount.Validate("Bank Account No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account"));
        BankAccount.Validate("Account Holder Name",
          '&' + LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Account Holder Name"), DATABASE::"Bank Account"));
        BankAccount.Validate("Account Holder Address",
          '@' + LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Account Holder Address"), DATABASE::"Bank Account"));
        BankAccount.Validate("Account Holder Post Code", FindPostCode());

        BankAccPostingGroup.Next(LibraryRandom.RandInt(BankAccPostingGroup.Count));

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.FindFirst();
        BankAccPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccPostingGroup.Modify(true);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccPostingGroup.Code);
        BankAccount.Modify(true);
    end;

    local procedure SetUpCountrySEPAAllowed(): Code[10]
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInfo.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInfo."Country/Region Code");
        CountryRegion.FindFirst();

        CountryRegion.Validate("SEPA Allowed", true);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code)
    end;

    local procedure SetUpSEPA(var BankAccount: Record "Bank Account"; var Customer: Record Customer; var DirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateSEPABankAccount(BankAccount);
        SetUpTransactionMode(
          TransactionMode, BankAccount."No.", "Partner Type".FromInteger(LibraryRandom.RandIntInRange(1, 2)), TransactionMode."Account Type"::Customer);
        CreateCustomerWithBankAccount(Customer, BankAccount, TransactionMode.Code, TransactionMode."Partner Type", DirectDebitMandate);
    end;

    local procedure SetUpSEPAVendor(var BankAccount: Record "Bank Account"; var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateSEPABankAccount(BankAccount);
        SetUpTransactionMode(
          TransactionMode, BankAccount."No.", "Partner Type".FromInteger(LibraryRandom.RandIntInRange(1, 2)), TransactionMode."Account Type"::Vendor);
        CreateVendorWithBankAccount(
          Vendor, BankAccount, TransactionMode.Code, TransactionMode."Partner Type", CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(BankAccount."Country/Region Code", CurrencyCode);
    end;

    local procedure SetUpTransactionMode(var TransactionMode: Record "Transaction Mode"; BankAccountCode: Code[20]; PartnerType: Enum "Partner Type"; AccountType: Option)
    var
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        TransactionMode.Init();
        TransactionMode.Validate(Code, BankAccountCode + Format(LibraryRandom.RandInt(100)));
        TransactionMode.Validate("Account Type", AccountType);
        TransactionMode.Validate("Export Protocol", ExportProtocol.Code);
        TransactionMode.Validate("Our Bank", BankAccountCode);
        TransactionMode.Validate("Run No. Series", LibraryERM.CreateNoSeriesCode());
        // this is necessary as process proposal for two diff. lines requires diff. ifentifiers (No.Series Code)
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, Format(LibraryRandom.RandInt(1000000)), '');
        TransactionMode.Validate("Identification No. Series", NoSeries.Code);

        LibraryERM.FindGLAccount(GLAccount);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        SourceCode.Next(LibraryRandom.RandInt(SourceCode.Count));
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Correction Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Correction Source Code", SourceCode.Code);
        TransactionMode.Validate("Partner Type", PartnerType);
        TransactionMode.Insert(true);
        Commit();
    end;

    local procedure UpdateCustomerBankAccount(CustomerNo: Code[20]; BankAccountNo: Code[10]; MandateId: Text[30])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.SetRange(Code, BankAccountNo);
        CustomerBankAccount.FindFirst();
        CustomerBankAccount.Validate("Direct Debit Mandate ID", MandateId);
        CustomerBankAccount.Modify(true);
    end;

    local procedure UpdateWorldPaymentOnTransactionMode(AccountType: Option; TransactionModeCode: Code[20]; WorldPaymentValue: Boolean)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.Get(AccountType, TransactionModeCode);
        TransactionMode.Validate(WorldPayment, WorldPaymentValue);
        TransactionMode.Modify(true);
    end;

    local procedure UpdateAddressPostCodeCityOnCustomerBankAccount(CustomerNo: Code[20]; CustBankAccountNo: Code[20]; Address: Text[100]; PostCode: Code[20]; City: Text[30])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.Get(CustomerNo, CustBankAccountNo);
        CustomerBankAccount.Validate("Account Holder Address", Address);
        CustomerBankAccount.Validate("Account Holder Post Code", PostCode);
        CustomerBankAccount.Validate("Account Holder City", City);
        CustomerBankAccount.Modify(true);
    end;

    local procedure VerifyBatchCountInFile(NumberOfBatches: array[4] of Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(NumberOfBatches) do
            XMLReadHelper.VerifyNodeCountWithValueByXPath(
              '//ns:Document/ns:CstmrDrctDbtInitn/ns:PmtInf/ns:PmtTpInf/ns:SeqTp', GetSequenceTypeText(i), NumberOfBatches[i]);
    end;

    local procedure VerifyBatchesInFile(NumberOfBatches: array[4] of Integer; NumberOfPayments: Integer)
    begin
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeValue('//ns:NbOfTxs', Format(NumberOfPayments));
        VerifyBatchCountInFile(NumberOfBatches)
    end;

    local procedure VerifyPaymentIsRejected(BankAccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        FindPaymentHistoryLines(BankAccountNo, PaymentHistoryLine);
        PaymentHistoryLine.FindSet();
        repeat
            Assert.AreEqual(PaymentHistoryLine.Status::Rejected, PaymentHistoryLine.Status, PaymentHistoryLine.FieldCaption(Status));
            Assert.AreEqual(
              0, PaymentHistoryLine."Direct Debit Mandate Counter", PaymentHistoryLine.FieldCaption("Direct Debit Mandate Counter"));
            Assert.AreEqual(0, PaymentHistoryLine."Sequence Type", PaymentHistoryLine.FieldCaption("Sequence Type"));
        until PaymentHistoryLine.Next() = 0;
    end;

    local procedure VerifyPostlAdrDoesNotExist()
    begin
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeCountByXPath(
          '//ns:Document/ns:CstmrDrctDbtInitn/ns:PmtInf/ns:DrctDbtTxInf/ns:Dbtr/ns:PstlAdr/ns:AdrLine', 0);
        XMLReadHelper.VerifyNodeCountByXPath('//ns:Document/ns:CstmrDrctDbtInitn/ns:PmtInf/ns:DrctDbtTxInf/ns:Dbtr/ns:PstlAdr', 0);
    end;

    local procedure VerifySEPADirectDebitFile(BankAccountNo: Code[20]; NumberOfBatches: array[4] of Integer; NumberOfPayments: Integer)
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        PaymentHistory: Record "Payment History";
        PaymentHistorySum: Text[18];
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();

        PaymentHistorySum := GetPmtHistoryLineSumAmount(PaymentHistory);

        VerifySEPAGroupHeader(PaymentHistory, PaymentHistorySum, NumberOfBatches, NumberOfPayments);
        VerifySEPAPmtInf(BankAccountNo, PaymentHistorySum);

        // intentionally commented out, since XSD schema must be saved on local hard disk
        // XMLReadHelper.ValidateXMLFileAgainstXSD(ExportFileName,
        // 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08',FORMAT(XSDSchemaPathTxt));
    end;

    local procedure VerifySEPAGroupHeader(PaymentHistory: Record "Payment History"; PaymentHistorySum: Text; NumberOfBatches: array[4] of Integer; NumberOfPayments: Integer)
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyAttributeValue('//ns:Document', 'xmlns', NameSpace);
        VerifyBatchCountInFile(NumberOfBatches);
        XMLReadHelper.VerifyNodeValue('//ns:MsgId', GetMessageID(PaymentHistory));
        XMLReadHelper.VerifyNodeValue('//ns:NbOfTxs', Format(NumberOfPayments));
        XMLReadHelper.VerifyNodeValue('//ns:CtrlSum', PaymentHistorySum);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrDrctDbtInitn/ns:GrpHdr/ns:InitgPty/ns:Nm', CompanyInfo.Name);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrDrctDbtInitn/ns:GrpHdr/ns:InitgPty/ns:Id/ns:OrgId/ns:Othr/ns:Id',
          CompanyInfo."VAT Registration No.");
    end;

    local procedure VerifySEPAPmtInf(BankAccountNo: Code[20]; PaymentHistorySum: Text[18])
    var
        BankAcc: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        GLSetup: Record "General Ledger Setup";
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistoryLine: Record "Payment History Line";
        pmtInfPrefix: Text[50];
    begin
        CompanyInfo.Get();
        GLSetup.Get();

        PaymentHistoryLine.SetRange("Our Bank", BankAccountNo);
        PaymentHistoryLine.FindFirst();

        Customer.Get(PaymentHistoryLine."Account No.");
        pmtInfPrefix := '//ns:Document/ns:CstmrDrctDbtInitn/ns:PmtInf';

        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtInfId',
          GetPmtInformationId(PaymentHistoryLine));
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtMtd', 'DD');
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:BtchBookg', 'false');
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:CtrlSum', PaymentHistorySum);

        // PmtTpInf
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtTpInf/ns:SvcLvl/ns:Cd', 'SEPA');
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtTpInf/ns:SeqTp', 'FRST');
        if Customer."Partner Type" = Customer."Partner Type"::Person then
            XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtTpInf/ns:LclInstrm/ns:Cd', 'CORE')
        else
            XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:PmtTpInf/ns:LclInstrm/ns:Cd', 'B2B');

        // Cdtr
        BankAcc.Get(PaymentHistoryLine."Our Bank");
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:Cdtr/ns:Nm',
          '+' + CopyStr(BankAcc."Account Holder Name", 2)); // starts with '&'
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:Cdtr/ns:PstlAdr',
          '.' + CopyStr(BankAcc."Account Holder Address", 2)); // starts with '@'

        // CdtrAcct
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:CdtrAcct/ns:Id/ns:IBAN',
          DelChr(CopyStr(BankAcc.IBAN, 1, 34)));

        // CdtrAgt
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:CdtrAgt/ns:FinInstnId/ns:BICFI',
          CopyStr(BankAcc."SWIFT Code", 1, 11));

        // UltmtCdtr
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:UltmtCdtr/ns:Nm',
          CompanyInfo.Name);
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:UltmtCdtr/ns:PstlAdr',
          CompanyInfo.Address);
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:ChrgBr[1]', 'SLEV');

        // CdtrSchmeId
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:CdtrSchmeId[1]/ns:Nm',
          CompanyInfo.Name);

        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix +
          '/ns:CdtrSchmeId[1]/ns:Id/ns:PrvtId/ns:Othr/ns:SchmeNm/ns:Prtry', 'SEPA');

        // DrctDbtTxInf
        CustomerBankAccount.Get(Customer."No.", BankAcc."No.");
        DirectDebitMandate.Get(CustomerBankAccount."Direct Debit Mandate ID");
        XMLReadHelper.VerifyNodeValueByXPath('//ns:EndToEndId', PaymentHistoryLine.Identification);
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:InstdAmt',
          DelChr(Format(Abs(PaymentHistoryLine.Amount), 18, '<Precision,2:2><Standard Format,9>'), '=', ' '));

        XMLReadHelper.VerifyAttributeValue('//ns:InstdAmt', 'Ccy', 'EUR');

        XMLReadHelper.VerifyNodeValue(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:DrctDbtTx/ns:MndtRltdInf/ns:MndtId',
          DirectDebitMandate.ID);

        XMLReadHelper.VerifyNodeValue(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:DrctDbtTx/ns:MndtRltdInf/ns:DtOfSgntr',
          Format(DirectDebitMandate."Date of Signature", 0, 9));

        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:DbtrAgt/ns:FinInstnId/ns:BICFI',
          CopyStr(CustomerBankAccount."SWIFT Code", 1, 11));
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:DbtrAcct/ns:Id/ns:IBAN',
          DelChr(CopyStr(PaymentHistoryLine.IBAN, 1, 34)));

        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:UltmtDbtr/ns:Nm', Customer.Name);
        XMLReadHelper.VerifyNodeValueByXPath(pmtInfPrefix + '/ns:DrctDbtTxInf/ns:UltmtDbtr/ns:PstlAdr', Customer.Address);

        XMLReadHelper.VerifyNodeValue('//ns:Ustrd', GetUnstructiredRemittanceInfo(PaymentHistoryLine));
    end;

    local procedure VerifySEPAPmtInfInstdAmt(BankAccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.SetRange("Our Bank", BankAccountNo);
        PaymentHistoryLine.FindFirst();

        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:InstdAmt',
          DelChr(Format(Abs(PaymentHistoryLine.Amount), 18, '<Precision,2:2><Standard Format,9>'), '=', ' '));
    end;

    local procedure VerifyZeroPaymentsInXMLFile(BankAccountNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
        NumberOfBatches: array[4] of Integer;
        i: Integer;
    begin
        for i := 1 to ArrayLen(NumberOfBatches) do
            NumberOfBatches[i] := 0;
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();
        VerifySEPAGroupHeader(PaymentHistory, '0.00', NumberOfBatches, 0);
    end;

    local procedure VerifyAmountInXMLFile(BankAccountNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
    begin
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.FindFirst();
        XMLReadHelper.Initialize(ExportFileName, NameSpace);
        asserterror XMLReadHelper.VerifyNodeValue('//ns:CtrlSum', '           ' + GetPmtHistoryLineSumAmount(PaymentHistory));
        Assert.ExpectedError(ExpectedErr);
    end;

    local procedure VerifyProposalLineNoError(BankAccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        UnexpectedError: Text;
    begin
        ProposalLine.SetRange("Our Bank No.", BankAccountNo);
        if ProposalLine.FindFirst() then begin
            UnexpectedError :=
              StrSubstNo(
                ForeignCurrencyErrorTok, ProposalLine.FieldCaption("Foreign Currency"), ProposalLine.FieldCaption("Foreign Amount"));

            Assert.AreNotEqual(UnexpectedError, ProposalLine."Error Message", UnexpectedErrorMsg);
        end;
    end;

    local procedure VerifyBeginningOfXMLFile(FileName: Text; CheckString: Text[5])
    var
        InStream: InStream;
        File: File;
        ReadText: Text[5];
    begin
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.Read(ReadText, 5);
        File.Close();
        Assert.AreEqual(CheckString, ReadText, WrongSymbolFoundErr);
    end;

    local procedure CreateExportProtocol(ExportID: Integer; CheckID: Integer)
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateGUID());
        ExportProtocol.Validate("Check ID", CheckID);
        ExportProtocol.Validate("Export ID", ExportID);
        ExportProtocol.Validate("Docket ID", 11000004);
        ExportProtocol.Validate("Default File Names", ExportFileName);
        ExportProtocol.Insert(true);
    end;

    local procedure UpdateCompanyInfoAddress();
    var
        CompanyInfo: Record "Company Information";
        Address: Text[100];
        PostCode: Code[20];
        City: Text[30];
    begin
        Address := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(Address)), 1, MaxStrLen(Address));
        PostCode := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(PostCode)), 1, MaxStrLen(PostCode));
        City := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(City)), 1, MaxStrLen(City));

        CompanyInfo.Get();
        CompanyInfo.Validate(Address, CopyStr(Address, 1, 50));
        CompanyInfo.Validate("Address 2", CopyStr(Address, 51, 100));
        CompanyInfo."Post Code" := PostCode;
        CompanyInfo.City := City;
        CompanyInfo.Modify();
    end;

    local procedure GetCompanyAddress(var StreetName: Text[70]; var PostalCode: Text[16]; var TownName: Text[35])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        StreetName := CopyStr(DelChr(CompanyInfo.Address, '<>') + ' ' + DelChr(CompanyInfo."Address 2", '<>'), 1, MaxStrLen(StreetName));
        PostalCode := CopyStr(DelChr(CompanyInfo."Post Code", '<>'), 1, MaxStrLen(PostalCode));
        TownName := CopyStr(DelChr(CompanyInfo.City, '<>'), 1, MaxStrLen(TownName));
    end;

    local procedure SetUpSEPAVendorWithVendorBankAccount(var BankAccount: Record "Bank Account"; var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateSEPABankAccount(BankAccount);
        SetUpTransactionMode(
          TransactionMode, BankAccount."No.", "Partner Type".FromInteger(LibraryRandom.RandIntInRange(1, 2)), TransactionMode."Account Type"::Vendor);
        CreateVendorWithBankAccount(
          Vendor, BankAccount, TransactionMode.Code, TransactionMode."Partner Type", CurrencyCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ProposalLineConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ProposalProcessedMsgHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeStatusReportHandler(var ChangeStatusReport: TestRequestPage "Paymt. History - Change Status")
    var
        NewStatus: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewStatus);
        ChangeStatusReport.NewStatus.SetValue(NewStatus);
        ChangeStatusReport.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        StoredCurrencyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StoredCurrencyDate);
        GetProposalEntries.CurrencyDate.SetValue(StoredCurrencyDate);
        GetProposalEntries.OK().Invoke();
    end;
}

