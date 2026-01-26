codeunit 144004 "Bank Payments - SEPA V2"
{
    // // [FEATURE] [Bank Payments]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        CountryRegion: Record "Country/Region";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        FullPathErr: Label 'File full path ''%1'' exceeds length (%3) of field ''%2'' ';
        FileCreatedMsg: Label 'Transfer File %1 Created Successfully.';
        ResendConfirmMsg: Label 'Transactions have been transferred to bank file.';
        NothingToSendErr: Label 'There is nothing to send.';
        ReportLinesCountErr: Label 'Only one payment should exist.';
        ZeroReferenceNoErr: Label 'Reference number cannot contain only zeros.';

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentExportUstrd()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CompanyInfo: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        RefPmtExported: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        DocNo := CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        RunExport(BankAccountNo);

        // Verify Header
        RefPmtExported.FindFirst();
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/NbOfTxs[1]', '1');
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/CtrlSum[1]', Format(RefPmtExported.Amount, 0, 9));
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/Grpg[1]', 'MIXD');

        // Verify Sender info
        CompanyInfo.FindFirst();
        RefFileSetup.Get(BankAccountNo);
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/InitgPty/Nm[1]', CompanyInfo.Name);
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/InitgPty/PstlAdr/AdrLine[1]', CompanyInfo.Address + ' ' + CompanyInfo."Address 2");
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/InitgPty/PstlAdr/AdrLine[2]', CompanyInfo."Post Code" + ' ' + CompanyInfo.City);
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/InitgPty/PstlAdr/Ctry[1]', CompanyInfo."Country/Region Code");
        VerifyValue(LibraryXPathXMLReader, 'GrpHdr/InitgPty/Id/OrgId/BkPtyId[1]', RefFileSetup."Bank Party ID");

        // Verify Payment methode
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/PmtMtd[1]', 'TRF');
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/ReqdExctnDt[1]', Format(RefPmtExported."Payment Date", 0, 9));

        // Verify Debitor info
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/Dbtr/Nm[1]', CompanyInfo.Name);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/Dbtr/PstlAdr/AdrLine[1]', CompanyInfo.Address + ' ' + CompanyInfo."Address 2");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/Dbtr/PstlAdr/AdrLine[2]', CompanyInfo."Post Code" + ' ' + CompanyInfo.City);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/Dbtr/PstlAdr/Ctry[1]', CompanyInfo."Country/Region Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/Dbtr/Id/OrgId/BkPtyId[1]', RefFileSetup."Bank Party ID");
        BankAccount.Get(BankAccountNo);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/DbtrAcct/Id/IBAN[1]', BankAccount.IBAN);

        // Verify ChargeBearer
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/ChrgBr[1]', 'SLEV');

        // Verify External Vendor Invoice Numbers
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/PmtId/EndToEndId[1]', DocNo);

        // Verify Amount
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Amt/InstdAmt[1]', Format(RefPmtExported.Amount, 0, 9));
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Amt/InstdAmt/@Ccy', 'EUR');

        // Verify Creditor Bank information
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/BIC[1]', VendorBankAccount."SWIFT Code");

        // Verify Creditor information
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Cdtr/Nm[1]', RefPmtExported."Description 2");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/AdrLine[1]', Vendor.Address + ' ' + Vendor."Address 2");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/AdrLine[2]', Vendor."Post Code" + ' ' + Vendor.City);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/Ctry[1]', Vendor."Country/Region Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/CdtrAcct/Id/IBAN[1]', VendorBankAccount.IBAN);

        // Verify Unstructured information
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/RmtInf/Ustrd[1]', PurchaseHeader."Vendor Invoice No.");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentExportStrd()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::"Reference No.");

        // Excercise
        RunExport(BankAccountNo);

        // Verify Unstructured information
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/CdtrRefInf/CdtrRefTp/Cd[1]', 'SCOR');
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/CdtrRefInf/CdtrRef[1]', '00000000000000268745');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentExportStrdFromOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLinesFromOrder(
          BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::"Reference No.");

        // Excercise
        RunExport(BankAccountNo);

        // Verify Unstructured information
        VerifySEPAValue(BankAccountNo, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/CdtrRefInf/CdtrRef[1]', '00000000000000268745');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentExportStrdFromJournal()
    var
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLinesFromJournal(BankAccountNo, VendorNo);

        // Excercise
        RunExport(BankAccountNo);

        // Verify Unstructured information
        VerifySEPAValue(BankAccountNo, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/CdtrRefInf/CdtrRef[1]', '00000000000000268745');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentExportStrdForign()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor('NO', true);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::"Reference No.");
        RefPmtExported.FindFirst();
        RefPmtExported."Currency Code" := 'NOK';
        RefPmtExported.Modify();

        // Excercise
        RunExport(BankAccountNo);

        // Verify Amount
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Amt/InstdAmt[1]', Format(RefPmtExported.Amount, 0, 9));
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Amt/InstdAmt/@Ccy', 'NOK');

        // Verify Creditor Bank information
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/BIC[1]', VendorBankAccount."SWIFT Code");

        // Verify Creditor information
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/Ctry[1]', Vendor."Country/Region Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/CdtrAcct/Id/IBAN[1]', VendorBankAccount.IBAN);

        // Verify Unstructured information
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/RfrdDocInf/RfrdDocTp/Cd[1]', 'CINV');
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/RmtInf/Strd/RfrdDocInf/RfrdDocNb[1]', PurchaseHeader."Vendor Invoice No.");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,Payments')]
    [Scope('OnPrem')]
    procedure PaymentReportTest()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        LibraryVariableStorage.Enqueue(VendorNo);
        RefPmtExported.FindFirst();
        REPORT.Run(REPORT::Payment, true, false, RefPmtExported);

        // Verify Report
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), ReportLinesCountErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VendNo_RefPmtExported', VendorNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_RefPmtExported', RefPmtExported.Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyNothingToSendRefLineCheck()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);
        RefPmtExported.FindFirst();
        RefPmtExported."SEPA Payment" := false;
        RefPmtExported.Modify();

        // Excercise
        asserterror RunExport(BankAccountNo);

        // Verify error
        Assert.ExpectedError(NothingToSendErr);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyNothingToSendVendorBankCheck()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, false);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        asserterror RunExport(BankAccountNo);

        // Verify error
        Assert.ExpectedError(NothingToSendErr);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyLinesAreRemovedAfterSend()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: array[2] of Code[20];
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        DocNo[1] := CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);
        DocNo[2] := CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);
        RefPmtExported.FindFirst();
        RefPmtExported."SEPA Payment" := false;
        RefPmtExported.Modify();

        // Excercise
        RunExport(BankAccountNo);

        // Verify that only one line exist and it is the right one
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyCount(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf', 1);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/PmtId/EndToEndId[1]', DocNo[2]);

        // Verify Lines in Ref Payment Exported
        RefPmtExported.FindSet();
        Assert.AreEqual(2, RefPmtExported.Count, '2 lines should exist');
        Assert.IsFalse(RefPmtExported.Transferred, 'Export should keep all NON SEPA lines');
        RefPmtExported.Next();
        Assert.IsTrue(RefPmtExported.Transferred, 'Export should remove all SEPA lines out of view');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyOnlyOnePmtInfIsCreatedIfSameDateAndVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: array[2] of Code[20];
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        DocNo[1] := CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);
        DocNo[2] := CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        RunExport(BankAccountNo);

        // Verify that 2 payments are created
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyCount(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf', 2);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf[1]/PmtId/EndToEndId[1]', DocNo[1]);
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf[2]/PmtId/EndToEndId[1]', DocNo[2]);

        // Verify that they exist in the same PmtInf
        VerifyCount(LibraryXPathXMLReader, 'PmtInf', 1);
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler,ConfirmResend')]
    [Scope('OnPrem')]
    procedure VerifyWarningWhenReSending()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise first send
        RunExport(BankAccountNo);
        Commit();

        // Excercise
        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));

        // Verify Header
        // Handled in the ConfirmResend handler
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVendorBankWithoutSwift()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        VendorBankAccount."SWIFT Code" := '';
        VendorBankAccount.Modify();

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        RunExport(BankAccountNo);

        // Verify Creditor Bank information
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyValue(LibraryXPathXMLReader,
          'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/CmbndId/ClrSysMmbId[1]', VendorBankAccount."Clearing Code");
        VerifyValue(LibraryXPathXMLReader, 'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/CmbndId/Nm[1]', VendorBankAccount.Name);
        VerifyValue(
            LibraryXPathXMLReader,
            'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/CmbndId/PstlAdr/AdrLine[1]',
            VendorBankAccount.Address + ' ' + VendorBankAccount."Address 2");
        VerifyValue(
            LibraryXPathXMLReader,
            'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/CmbndId/PstlAdr/AdrLine[2]',
            VendorBankAccount."Post Code" + ' ' + VendorBankAccount.City);
        VerifyValue(LibraryXPathXMLReader,
          'PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/CmbndId/PstlAdr/Ctry[1]', VendorBankAccount."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyVendorBankMustHaveIBAN()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        VendorBankAccount.IBAN := '';
        VendorBankAccount.Modify();

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        asserterror RunExport(BankAccountNo);

        // Verify Creditor Bank information
        Assert.ExpectedError('IBAN must have a value');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    [Scope('OnPrem')]
    procedure VerifyVendorBankMustHaveBankAccountNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor('NO', true);
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        VendorBankAccount.IBAN := '';
        VendorBankAccount."Bank Account No." := '';
        VendorBankAccount.Modify();

        // Setup transaction data
        CreateRefPaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message);

        // Excercise
        asserterror RunExport(BankAccountNo);

        // Verify Creditor Bank information
        Assert.ExpectedError('Bank Account No. must have a value');
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,Payments')]
    [Scope('OnPrem')]
    procedure PaymentReportWithCombinedLines()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPmtExported: Record "Ref. Payment - Exported";
        RefPmtMgt: Codeunit "Ref. Payment Management";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        PaymentType: Option Domestic,Foreign,SEPA;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 378874] Check lines count and totals on REP 32000005 - Payment, when combine payments
        Initialize();

        // [GIVEN] Vendor and Bank Account
        BankAccountNo := CreateBankAccount();
        VendorNo := CreateVendor(CountryRegion.Code, true);

        // [GIVEN] Reference File Setup updated to allow combine payments
        UpdateBankAccountReferenceFileSetup(BankAccountNo, true);

        // [GIVEN] Create documents for suggest Bank Payments
        CreateDocumentForSuggestBankPayments(VendorNo, PurchaseHeader, PurchaseHeader."Message Type"::Message,
          LibraryRandom.RandIntInRange(5, 10));
        Commit();

        // [GIVEN] Run Suggest Bank Payments to create lines on Ref. Payment Export with total amount "A"
        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));
        RefPmtExported.SetRange("Vendor No.", VendorNo);
        RefPmtExported.SetRange("Payment Account", BankAccountNo);
        RefPmtExported.CalcSums(Amount);
        TotalAmount := RefPmtExported.Amount;

        // [GIVEN] Combine payments
        RefPmtMgt.CombineVendPmt(PaymentType::SEPA);
        Commit();

        // [WHEN] Print report 32000005 - Payment
        LibraryVariableStorage.Enqueue(VendorNo);
        RefPmtExported.FindFirst();
        REPORT.Run(REPORT::Payment, true, false, RefPmtExported);

        // [THEN] Report generated one line with amount "A"
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), ReportLinesCountErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_RefPmtExported', TotalAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentPageHandler,SuggestBankPaymentsPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorBankPayments()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: array[2] of Code[20];
    begin
        // [SCENARIO 202940] Suggested posting date is matching the date used by the Bank Payments
        Initialize();

        // Vendor.GET(CreateVendorVATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two posted purchase orders
        InvoiceNo[1] := CreatePostPurchaseDocument(PurchaseHeader."Document Type"::Invoice, Vendor."No.", WorkDate());
        InvoiceNo[2] := CreatePostPurchaseDocument(PurchaseHeader."Document Type"::Invoice, Vendor."No.", WorkDate());

        // [GIVEN] Set up different bank payments dates
        SuggestBankPayments(WorkDate(), Vendor."No.");
        UpdateRefPaymentExportedWithPaymentDate(Vendor."No.", InvoiceNo[1], WorkDate() + 1, true);
        UpdateRefPaymentExportedWithPaymentDate(Vendor."No.", InvoiceNo[2], WorkDate() + 2, true);

        // [WHEN] Run Suggest Vendor Payment Report with "Send to Bank" option
        SuggestVendorPayment(GenJournalLine, WorkDate() + 3, Vendor."No.", true);

        // [THEN] Suggested posting date is the same as the date used by the Bank Payments
        VerifyGeneralJournalPostingDate(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceNo[1], WorkDate() + 1);
        VerifyGeneralJournalPostingDate(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", InvoiceNo[2], WorkDate() + 2);
    end;

    [Test]
    procedure InvoiceMessageZerosOnlyWhenMessageTypeReferenceNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceCard: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 457227] Set only zeros to Invoice Message when Message Type is Reference No.
        Initialize();

        // [GIVEN] Purchase Invoice with Message Type = Reference No.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Message Type", PurchaseHeader."Message Type"::"Reference No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Opened Purchase Invoice card.
        PurchaseInvoiceCard.OpenEdit();
        PurchaseInvoiceCard.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Set Invoice Message = "00000000".
        asserterror PurchaseInvoiceCard."Invoice Message".SetValue('00000000');

        // [THEN] Error "Reference number cannot contain only zeros." is thrown.
        Assert.ExpectedError(ZeroReferenceNoErr);
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    procedure InvoiceMessageNotZerosOnlyWhenMessageTypeReferenceNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceCard: TestPage "Purchase Invoice";
        InvoiceMessage: Text[250];
    begin
        // [SCENARIO 457227] Set value that contains not only zeros to Invoice Message when Message Type is Reference No.
        Initialize();

        // [GIVEN] Purchase Invoice with Message Type = Reference No.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Message Type", PurchaseHeader."Message Type"::"Reference No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Opened Purchase Invoice card.
        PurchaseInvoiceCard.OpenEdit();
        PurchaseInvoiceCard.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Set Invoice Message = "10000003".
        InvoiceMessage := '10000003';
        PurchaseInvoiceCard."Invoice Message".SetValue(InvoiceMessage);
        PurchaseInvoiceCard.Close();

        // [THEN] The Invoice Message was set to "10000003".
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField("Invoice Message", InvoiceMessage);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Payments - SEPA V2");
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Payments - SEPA V2");
        IsInitialized := true;

        CountryRegion.Get('FI');
        InitCompanyInformation(CountryRegion.Code);
        SetupNoSeries(true, false, false, '', '');
        InitGeneralLedgerSetup('EUR');
        InitCountryRegion(CountryRegion.Code, true);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Payments - SEPA V2");
    end;

    local procedure InitCompanyInformation(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryCode;
        CompanyInformation.Modify();
    end;

    local procedure InitGeneralLedgerSetup(LCYCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LCYCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure InitCountryRegion(CountryCode: Code[10]; SepaAllowed: Boolean)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        CountryRegion."SEPA Allowed" := SepaAllowed;
        CountryRegion.Modify();
    end;

    local procedure SetupNoSeries(Default: Boolean; Manual: Boolean; DateOrder: Boolean; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, Default, Manual, DateOrder);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, EndingNo);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Bank Batch Nos." := NoSeries.Code;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Country/Region Code", CountryRegion.Code);
        BankAccount.Validate("Post Code", FindPostCode(CountryRegion.Code));
        BankAccount.Validate("Bank Branch No.", LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."), DATABASE::"Bank Account"));
        BankAccount.Validate("Bank Account No.", '159030-776');
        // Hardcode to match the Bank Account No validation
        BankAccount.Validate("Transit No.", LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Transit No."), DATABASE::"Bank Account"));
        BankAccount.Validate("SWIFT Code", LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account"));
        BankAccount.Validate(IBAN, 'FI9780RBOS16173241116737');
        // Hardcoded to match a valid IBAN
        BankAccount.Validate("Payment Export Format", 'SEPACT V02');
        // Hardcoded to match the test format under test
        BankAccount.Modify();

        CreateBankAccountReferenceFileSetup(BankAccount."No.");

        exit(BankAccount."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; SEPAPayment: Boolean): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate(Name, VendorBankAccount.Code);
        VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount.Validate(Address, LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Address 2", LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate(City, LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Post Code", FindPostCode(CountryCode));
        VendorBankAccount.Validate("Bank Branch No.", LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Branch No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("Bank Account No.", '159030-776');
        VendorBankAccount.Validate("Transit No.", LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Transit No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("SWIFT Code", LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.IBAN := CountryCode + Format(LibraryRandom.RandIntInRange(111111111, 999999999));
        // Use direct assignement to avoid confirm dialog
        VendorBankAccount.Validate("Clearing Code", LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Clearing Code"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("SEPA Payment", SEPAPayment);
        VendorBankAccount.Modify();
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendor(CountryCode: Code[10]; SEPAPayment: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate("Post Code", FindPostCode(CountryCode));
        Vendor.Validate("Business Identity Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Business Identity Code"), DATABASE::Vendor));
        Vendor.Validate("Our Account No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Our Account No."), DATABASE::Vendor));
        Vendor.Validate("Preferred Bank Account Code", CreateVendorBankAccount(Vendor."No.", CountryCode, SEPAPayment));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindPostCode(CountryCode: Code[10]): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange("Country/Region Code", CountryCode);
        LibraryERM.FindPostCode(PostCode);
        exit(PostCode.Code);
    end;

    local procedure CreateBankAccountReferenceFileSetup(BankAccountNo: Code[20])
    var
        ReferenceFileSetup: Record "Reference File Setup";
    begin
        ReferenceFileSetup.Init();
        ReferenceFileSetup.Validate("No.", BankAccountNo);
        ReferenceFileSetup.Validate("Bank Party ID", LibraryUtility.GenerateRandomCode(ReferenceFileSetup.FieldNo("Bank Party ID"), DATABASE::"Reference File Setup"));
        ReferenceFileSetup.Validate("File Name", GenerateFileName(ReferenceFileSetup.FieldNo("File Name"), DATABASE::"Reference File Setup", 'xml'));
        ReferenceFileSetup.Insert();
    end;

    local procedure GenerateFileName(FieldNo: Integer; TableNo: Integer; Extension: Text): Text[250]
    var
        RecRef: RecordRef;
        FullPath: Text;
        FieldLength: Integer;
    begin
        RecRef.Open(TableNo);
        FullPath := TemporaryPath + LibraryUtility.GenerateRandomCode(FieldNo, TableNo) + '.' + Extension;

        FieldLength := RecRef.Field(FieldNo).Length;
        Assert.IsTrue(
          FieldLength >= StrLen(FullPath),
          StrSubstNo(FullPathErr, FullPath, RecRef.Field(FieldNo).Caption, FieldLength));

        exit(CopyStr(FullPath, 1, FieldLength));
    end;

    local procedure CreateRefPaymentExportLines(BankAccountNo: Code[20]; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"; MessageType: Option): Code[20]
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        DocNo: Code[20];
    begin
        DocNo := CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true, MessageType);
        RefPmtExported.DeleteAll();
        Commit();

        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));

        exit(DocNo);
    end;

    local procedure CreateRefPaymentExportLinesFromOrder(BankAccountNo: Code[20]; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"; MessageType: Option): Code[20]
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        DocNo: Code[20];
    begin
        DocNo := CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, true, true, MessageType);
        RefPmtExported.DeleteAll();
        Commit();
        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', PurchaseHeader."Posting Date"));

        exit(DocNo);
    end;

    local procedure CreateRefPaymentExportLinesFromJournal(BankAccountNo: Code[20]; VendorNo: Code[20])
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);

        LibraryJournals.CreateGenJournalLine(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor, VendorNo,
          GenJnlLine."Bal. Account Type"::"Bank Account", BankAccountNo, -LibraryRandom.RandDec(1000, 2));
        GenJnlLine.Validate("External Document No.", Format(LibraryRandom.RandIntInRange(1, 99)));
        GenJnlLine.Validate("Message Type", GenJnlLine."Message Type"::"Reference No");
        GenJnlLine.Validate("Invoice Message", '268745');
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        RefPmtExported.DeleteAll();
        Commit();
        RunSuggestBankPayments(BankAccountNo, VendorNo, CalcDate('<30D>', WorkDate()));
    end;

    local procedure CreateAndPostPurchaseDocumentWithRandomAmounts(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean; MessageType: Option) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Precision: Integer;
        InvoiceMessage: Text[250];
        InvoiceMessage2: Text[250];
    begin
        Precision := LibraryRandom.RandIntInRange(2, 5);
        if MessageType <> PurchaseHeader."Message Type"::"Reference No." then begin
            InvoiceMessage :=
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message"), DATABASE::"Purchase Header");
            InvoiceMessage2 :=
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Invoice Message 2"), DATABASE::"Purchase Header");
        end else
            InvoiceMessage := '268745';
        LibraryInventory.CreateItem(Item);

        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, DocumentType, VendorNo,
            PurchaseLine.Type::Item, Item."No.",
            LibraryRandom.RandDec(1000, Precision), LibraryRandom.RandDec(1000, Precision),
            ToShipReceive, ToInvoice,
            MessageType, InvoiceMessage, InvoiceMessage2);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineType: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; Cost: Decimal; ToShipReceive: Boolean; ToInvoice: Boolean; MessageType: Option; InvoiceMessage: Text[250]; InvoiceMessage2: Text[250]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Message Type", MessageType);
        PurchaseHeader.Validate("Invoice Message", InvoiceMessage);
        PurchaseHeader.Validate("Invoice Message 2", InvoiceMessage2);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Cost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument2(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    local procedure CreateDocumentForSuggestBankPayments(VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"; MessageType: Option; LinesCount: Integer)
    var
        i: Integer;
    begin
        for i := 0 to LinesCount do
            CreateAndPostPurchaseDocumentWithRandomAmounts(
              PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true, MessageType);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        Item.Validate("Last Direct Cost", Item."Unit Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VendorCode: Code[20]; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorCode);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateLongBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Init();
        BankAccount.Validate("No.", LibraryUtility.GenerateRandomCode20(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        BankAccount.Validate(Name, BankAccount."No.");  // Validating No. as Name because value is not important.
        BankAccount.Insert(true);
        exit(BankAccount."No.");
    end;

    local procedure UpdateBankAccountReferenceFileSetup(BankAccountNo: Code[20]; Allow: Boolean)
    var
        ReferenceFileSetup: Record "Reference File Setup";
    begin
        ReferenceFileSetup.Get(BankAccountNo);
        ReferenceFileSetup.Validate("Allow Comb. SEPA Pmts.", Allow);
        ReferenceFileSetup.Validate("Allow Comb. Domestic Pmts.", Allow);
        ReferenceFileSetup.Validate("Allow Comb. Foreign Pmts.", Allow);
        ReferenceFileSetup.Modify(true);
    end;

    local procedure RunSuggestBankPayments(BankAccountNo: Code[20]; VendorNo: Code[20]; PaymentDate: Date)
    var
        SuggestBankPayments: Report "Suggest Bank Payments";
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        SuggestBankPayments.InitializeRequest(PaymentDate, false, 0);
        SuggestBankPayments.Run();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure RunExport(BankAccountNo: Code[20])
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(FileCreatedMsg, GetSEPAFile(BankAccountNo)));
        RefPaymentExported.FindFirst();
        RefPaymentExported.ExportToFile();
    end;

    local procedure SuggestBankPayments(PaymentDate: Date; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        SuggestBankPayments: Report "Suggest Bank Payments";
    begin
        Clear(SuggestBankPayments);
        Vendor.SetRange("No.", VendorNo);
        SuggestBankPayments.SetTableView(Vendor);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(PaymentDate);
        Commit();
        SuggestBankPayments.Run();
    end;

    local procedure SuggestVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; LastPmtDate: Date; VendorNo: Code[20]; SendToBank: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // Create General Journal Template and General Journal Batch.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        // Run Suggest Vendor Payments Report.
        Clear(SuggestVendorPayments);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(LastPmtDate);  // Last Payment Date
        LibraryVariableStorage.Enqueue(LastPmtDate);  // Posting Date
        LibraryVariableStorage.Enqueue(0);            // Available Amount
        LibraryVariableStorage.Enqueue(SendToBank);   // Send to bank
        LibraryVariableStorage.Enqueue(false);        // Skip Exported Payments
        LibraryVariableStorage.Enqueue(false);        // SummarizePerVendor
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID()); // StartingDocumentNo
        Commit();  // Commit required to avoid test failure.
        SuggestVendorPayments.Run();
    end;

    local procedure UpdateRefPaymentExportedWithPaymentDate(VendorNo: Code[20]; DocumentNo: Code[20]; BankPaymentDate: Date; Send: Boolean)
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.SetRange("Vendor No.", VendorNo);
        RefPaymentExported.SetRange("Document No.", DocumentNo);
        RefPaymentExported.FindFirst();
        RefPaymentExported.Validate("Payment Date", BankPaymentDate);
        RefPaymentExported.Validate(Transferred, Send);
        RefPaymentExported.Validate("Payment Account", CreateLongBankAccount());
        RefPaymentExported.Modify(true);
    end;

    local procedure GetSEPAFile(BankAccountNo: Code[20]): Text
    var
        ReferenceFileSetup: Record "Reference File Setup";
    begin
        ReferenceFileSetup.Get(BankAccountNo);
        exit(ReferenceFileSetup."File Name");
    end;

    local procedure VerifyValue(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; XPath: Text; ExpectedValue: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/Document/pain.001.001.02/' + XPath, ExpectedValue);
    end;

    local procedure VerifyCount(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; XPath: Text; NodeCount: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/Document/pain.001.001.02/' + XPath, NodeCount)
    end;

    local procedure VerifySEPAValue(BankAccountNo: Code[20]; XPath: Text; ExpectedValue: Text)
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        LibraryXPathXMLReader.Initialize(GetSEPAFile(BankAccountNo), 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        VerifyValue(LibraryXPathXMLReader, XPath, ExpectedValue);
    end;

    local procedure VerifyGeneralJournalPostingDate(GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.SetRange("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", PostingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSuggestBankPayments(var RequestPage: TestRequestPage "Suggest Bank Payments")
    var
        Vendor: Record Vendor;
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(VendorNo);
        Vendor.Get(VendorNo);

        RequestPage."Payment Account".SetValue(BankAccountNo);
        RequestPage.Vendor.SetFilter("No.", VendorNo);
        RequestPage.Vendor.SetFilter("Payment Method Code", Vendor."Payment Method Code");
        RequestPage.OK().Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Payments(var RequestPage: TestRequestPage Payment)
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        RequestPage."Ref. Payment - Exported".SetFilter("Vendor No.", VendorNo);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(ExpectedMessage, Message, 'Unespected Message');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmResend(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ResendConfirmMsg) <> 0,
          StrSubstNo('Unespected Confirm. Expected to find ''%1'' in ''%2''', ResendConfirmMsg, Question));
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestBankPaymentsPageHandler(var SuggestBankPayments: TestRequestPage "Suggest Bank Payments")
    begin
        SuggestBankPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestBankPayments.LastPaymentDate.SetValue(LibraryVariableStorage.DequeueDate());
        SuggestBankPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.LastPaymentDate.SetValue(LibraryVariableStorage.DequeueDate());
        SuggestVendorPayments.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        SuggestVendorPayments."Available Amount (LCY)".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestVendorPayments.SendToBank.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.SkipExportedPayments.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.SummarizePerVendor.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestVendorPayments.OK().Invoke();
    end;
}
