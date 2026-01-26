codeunit 144011 "SEPADD08 IntegrationTest - BE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DomiciliationJnlManagement: Codeunit DomiciliationJnlManagement;
        ServerFileName: Text;
        MandateIDErr: Label 'Direct Debit Mandate ID is not transferred to Domiciliation Journal Line.';
        AppliestoErr: Label 'Applies to Entry shoud not be blank.';
        FileExportErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        ErrorCountErr: Label 'There are more file errors than expected.';
        EmptyErr: Label 'File errors are not deleted.';
        PartnerTypeErr: Label 'The customer''s Partner Type, Company, must be equal to the Partner Type, Person, specified in the collection.';
        DomNoTxt: Label '145003454572';
        GLAccTypeErr: Label 'The balance account type in %1 must be G/L Account.';
        GLAccNoErr: Label 'The balance account number in %1 is not a valid G/L Account No.';
        InvalidGLAccNoErr: Label '%1 in Journal Template is not a G/L Account No.';
        InvalidAccTypeErr: Label 'The account type in general ledger account %1 must be Posting.';
        NoSeriesErr: Label 'Validation error for Field: GenJnlBatch,  Message = ''No. Series must have a value in Gen. Journal Batch: Journal Template Name';
        NoRecordsErr: Label 'There are no domiciliation records.';

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestDomJnl()
    var
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccountNo: Code[20];
    begin
        // Setup
        CreatePostCustomerInvoiceWithValidMandate(SalesHeader, BankAccountNo);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccountNo, Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        // Verify
        Assert.AreEqual(DomJnlLine."Direct Debit Mandate ID", SalesHeader."Direct Debit Mandate ID", MandateIDErr);
        Assert.IsTrue(DomJnlLine."Applies-to Entry No." <> 0, AppliestoErr);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestDomJnlExclInvAfterPostingDate()
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccountNo: Code[20];
    begin
        // Setup
        CreatePostCustomerInvoiceWithValidMandate(SalesHeader, BankAccountNo);

        // Exercise
        asserterror CreateDomJnlLineForSalesInvoice(DomiciliationJournalLine, SalesHeader, BankAccountNo,
            Customer."Partner Type"::Company, SalesHeader."Posting Date" - 1);

        // Verify
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,FileDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportDomJnlLegacy()
    var
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccountNo: Code[20];
    begin
        // Setup
        CreatePostCustomerInvoiceWithValidMandate(SalesHeader, BankAccountNo);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccountNo, Customer."Partner Type"::Company,
          SalesHeader."Due Date");
        DomJnlLine.ExportToFile();

        // Verify
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportSEPADomJnlLineErrorsAreDeleted()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Person, SalesHeader."Due Date");
        asserterror DomJnlLine.ExportToFile();
        Assert.ExpectedError(FileExportErr);

        // Verify
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Template Name", DomJnlLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", DomJnlLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", DomJnlLine."Line No.");
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count, ErrorCountErr);
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", PartnerTypeErr);

        // Exercise
        DomJnlLine.Delete(true);

        // Verify
        Assert.IsTrue(PaymentJnlExportErrorText.IsEmpty, EmptyErr);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportSEPADomJnlLine()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] SEPA DD xml export
        // [SCENARIO 362887] Xml <Cdtr> node (2.19) doesn't include <AnyBIC> field
        // Setup
        LibraryBEHelper.InitializeCompanyInformation();
        CompanyInformation.Get();
        CompanyInformation.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        CompanyInformation.Modify(true);

        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");
        DirectDebitCollection.CreateRecord(
          DomJnlLine."Journal Template Name", BankAccount."No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Domiciliation Batch Name" := DomJnlLine."Journal Batch Name";
        DirectDebitCollection.Modify();

        // Exercise
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Verify
        DirectDebitCollectionEntry.TestField("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.TestField("Entry No.", DomJnlLine."Line No.");
        DirectDebitCollectionEntry.TestField("Customer No.", DomJnlLine."Customer No.");
        DirectDebitCollectionEntry.TestField("Applies-to Entry No.", DomJnlLine."Applies-to Entry No.");
        DirectDebitCollectionEntry.TestField("Transfer Date", DomJnlLine."Posting Date");
        DirectDebitCollectionEntry.TestField("Transfer Amount", -DomJnlLine.Amount);
        DirectDebitCollectionEntry.TestField("Mandate ID", DomJnlLine."Direct Debit Mandate ID");

        // Exercise 2
        ExportToServerTempFile(DirectDebitCollectionEntry);

        // Verify 2
        LibraryXMLRead.Initialize(ServerFileName);
        LibraryXMLRead.VerifyNodeValue('Id', CompanyInformation."Enterprise No.");
        LibraryXMLRead.VerifyNodeValue('ChrgBr', 'SLEV');
        // PmtTpInf/InstrPrty removed due to BUG: 267559
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty');
        LibraryXMLRead.VerifyNodeValueInSubtree('MndtRltdInf', 'MndtId', DomJnlLine."Direct Debit Mandate ID");
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', -DomJnlLine.Amount);
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('FinInstnId', 'BICFI', BankAccount."SWIFT Code");

        // TFS 362887: <Cdtr> tag should not contain <AnyBIC>
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Nm', CompanyInformation.Name);
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Cdtr', 'Id');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Cdtr', 'OrgId');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Cdtr', 'AnyBIC');
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportSEPANoDomJnlLineRecords()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Person,
          SalesHeader."Due Date");
        DomJnlLine.Status := DomJnlLine.Status::Posted;
        DomJnlLine.Modify();
        asserterror DomJnlLine.ExportToFile();
        Assert.ExpectedError(NoRecordsErr);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLineIsCreatedAndPosted()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := GLAccount."No.";
        GenJnlBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        CustLedgerEntry.SetRange("Customer No.", DomJnlLine."Customer No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, DomJnlLine.Amount);

        // Verify
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGenJnlErrBalAccType()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::Customer;
        GenJnlBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        asserterror REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(GLAccTypeErr, GenJnlBatch.Name));
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGenJnlErrBalAccNo()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        asserterror REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(GLAccNoErr, GenJnlBatch.Name));
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGenJnlErrBalAccNoNotValid()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := LibraryUtility.GenerateGUID();
        GenJnlBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        asserterror REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(InvalidGLAccNoErr, GenJnlBatch."Bal. Account No."));
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGenJnlErrGLAccIsNotPosting()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::Heading;
        GLAccount.Modify();
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := GLAccount."No.";
        GenJnlBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        asserterror REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(InvalidAccTypeErr, GenJnlBatch."Bal. Account No."));
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,CreateGenJnlLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateGenJnlErrNoSeriesMissing()
    var
        BankAccount: Record "Bank Account";
        DomJnlLine: Record "Domiciliation Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.08",
          CODEUNIT::"SEPA DD-Check Line");
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        CreateDomJnlLineForSalesInvoice(DomJnlLine, SalesHeader, BankAccount."No.", Customer."Partner Type"::Company,
          SalesHeader."Due Date");

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := LibraryUtility.GenerateGUID();
        GenJnlBatch.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(GenJnlTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        asserterror REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, DomJnlLine);

        // Verfify
        Assert.ExpectedError(NoSeriesErr);
        VerifyDDCIsDeleted(DomJnlLine."Journal Template Name", DomJnlLine."Journal Batch Name")
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler')]
    procedure ExportDomJnlLineWithCustomMessageToReceipt()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TempBlob: Codeunit "Temp Blob";
        BankAccountNo: Code[20];
        ExpectedValue: Text;
    begin
        // [SCENARIO] Export domiciliation journal with custom "Message 1" and "Mssage 2" line values

        // [GIVEN] Domiciliation journal line with "Message 1" = "A", "Mssage 2" = "B"
        CreatePostCustomerInvoiceWithValidMandate(SalesHeader, BankAccountNo);
        CreateDomJnlLineForSalesInvoice(
          DomiciliationJournalLine, SalesHeader, BankAccountNo, Customer."Partner Type"::Company, SalesHeader."Due Date");
        DomiciliationJournalLine.Validate("Message 1", LibraryUtility.GenerateGUID());
        DomiciliationJournalLine.Validate("Message 2", LibraryUtility.GenerateGUID());
        DomiciliationJournalLine.Modify(true);

        // [WHEN] Export "File Domiciliation"
        CreateDirectDebitCollectionEntryFromDomJnl(DirectDebitCollectionEntry, DomiciliationJournalLine);
        ExportToTempBlob(TempBlob, DirectDebitCollectionEntry);

        // [THEN] Exported XML contains node "../RmtInf/Ustrd" = "A, B"
        ExpectedValue := DomiciliationJournalLine."Message 1" + ', ' + DomiciliationJournalLine."Message 2";
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.08');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf/RmtInf/Ustrd', ExpectedValue);
    end;

    [Test]
    [HandlerFunctions('SuggestDomiciliationsRequestPageHandler,DomiciliationJournalTemplateHandler')]
    [Scope('OnPrem')]
    procedure ReferenceNoIssueForLengthGreaterThan12WhileSuggestLinesOnDomiciliationJournal()
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestDomiciliations: Report "Suggest domicilations";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 571303] Issue when suggesting domiciliation in the domiciliation journal results in the error message: "It is not possible to display in a field with a length of 12."

        // [GIVEN] Create Customer and Post invoice from Gen. Journal
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateAndPostGeneralJournalLineWithBalancingAccount(
            'FSE' + Format(LibraryRandom.RandIntInRange(2, 2)) + '-' +
            Format(LibraryRandom.RandIntInRange(40, 40)) + '-' + Format(LibraryRandom.RandIntInRange(60009999, 60009999)),
            "Gen. Journal Document Type"::Invoice, "Gen. Journal Account Type"::Customer,
            CustomerNo, LibraryRandom.RandDecInDecimalRange(100, 100, 2));

        // [GIVEN] Enqueue values for suggest domiciliation journal.
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Due Date" + 10);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Posting Date" + 30);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");

        // [WHEN] Run suggest lines on Domiciliations journal
        CreateFilteredSimpleDomicilation(DomiciliationJournalLine);
        SuggestDomiciliations.SetJournal(DomiciliationJournalLine);
        Commit();
        SuggestDomiciliations.Run();

        // [THEN] Domiciliation line created with reference length greater than 12
        DomiciliationJournalLine.SetRange("Journal Template Name", DomiciliationJournalLine."Journal Template Name");
        DomiciliationJournalLine.SetRange("Journal Batch Name", DomiciliationJournalLine."Journal Batch Name");
        DomiciliationJournalLine.FindFirst();
        Assert.IsTrue(DomiciliationJournalLine.Reference <> '', NoRecordsErr);
        Assert.IsTrue(StrLen(DomiciliationJournalLine.Reference) > 12, NoRecordsErr);
    end;

    local procedure CreateAndPostGeneralJournalLineWithBalancingAccount(
        DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", (Today - 20));
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.validate("External Document No.", DocumentNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFilteredSimpleDomicilation(var DomiciliationJournalLine: Record "Domiciliation Journal Line")
    var
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        JnlSelected: Boolean;
        CurrentJnlBatchName: Code[10];
    begin
        DomiciliationJnlManagement.TemplateSelection(DomiciliationJournalLine, JnlSelected);
        DomiciliationJnlManagement.OpenJournal(CurrentJnlBatchName, DomiciliationJournalLine);

        DomiciliationJournalTemplate.FindFirst();
        DomiciliationJournalLine."Journal Template Name" := DomiciliationJournalTemplate.Name;
        DomiciliationJournalLine."Journal Batch Name" := CurrentJnlBatchName;
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; ProcessingCodeunitId: Integer; ProcessingXmlPortId: Integer; CheckExportCodeunitID: Integer)
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Preserve Non-Latin Characters" := true;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitId;
        BankExportImportSetup."Processing XMLport ID" := ProcessingXmlPortId;
        BankExportImportSetup."Check Export Codeunit" := CheckExportCodeunitID;
        BankExportImportSetup.Insert();
    end;

    local procedure CreateBankAccountWithExportImportSetup(var BankAccount: Record "Bank Account"; CodeunitID: Integer; XmlPortID: Integer; CheckExportCodeunitID: Integer)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankExportImportSetup(BankExportImportSetup, CodeunitID, XmlPortID, CheckExportCodeunitID);
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();
        BankAccount.Modify();
    end;

    local procedure CreateDomJnlTemplate(var DomJnlTemplate: Record "Domiciliation Journal Template"; BankAccNo: Code[20])
    begin
        DomJnlTemplate.Init();
        DomJnlTemplate.Name :=
          LibraryUtility.GenerateRandomCode(DomJnlTemplate.FieldNo(Name), DATABASE::"Domiciliation Journal Template");
        DomJnlTemplate."Bank Account No." := BankAccNo;
        DomJnlTemplate.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateDomJnlBatch(var DomJnlBatch: Record "Domiciliation Journal Batch"; DomTemplateName: Code[10]; PartnerType: Enum "Partner Type")
    begin
        DomJnlBatch.Init();
        DomJnlBatch."Journal Template Name" := DomTemplateName;
        DomJnlBatch.Name := LibraryUtility.GenerateRandomCode(DomJnlBatch.FieldNo(Name), DATABASE::"Domiciliation Journal Batch");
        DomJnlBatch."Partner Type" := PartnerType;
        DomJnlBatch.Insert();
    end;

    local procedure CreateCustomerAndCustomerBankAccount(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account"; PartnerType: Enum "Partner Type")
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer."Partner Type" := PartnerType;
        Customer."Domiciliation No." := DomNoTxt;
        Customer.Modify();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID();
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify();
    end;

    local procedure CreateCustomerInvoiceWithValidMandate(var SalesHeader: Record "Sales Header"; CustomerBankAccount: Record "Customer Bank Account")
    var
        SalesLine: Record "Sales Line";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, CustomerBankAccount."Customer No.",
          CustomerBankAccount.Code, WorkDate(), CalcDate('1Y', WorkDate()));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerBankAccount."Customer No.");
        SalesHeader."Direct Debit Mandate ID" := SEPADirectDebitMandate.ID;
        SalesHeader.Modify();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreatePostCustomerInvoiceWithValidMandate(var SalesHeader: Record "Sales Header"; var BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        CreateBankAccountWithExportImportSetup(BankAccount, Codeunit::"File Domiciliations", 0, Codeunit::"SEPA DD-Check Line");
        BankAccountNo := BankAccount."No.";
        CreateCustomerAndCustomerBankAccount(Customer, CustomerBankAccount, Customer."Partner Type"::Company);
        CreateCustomerInvoiceWithValidMandate(SalesHeader, CustomerBankAccount);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateDomJnlLineForSalesInvoice(var DomJnlLine: Record "Domiciliation Journal Line"; SalesHeader: Record "Sales Header"; BankAccountNo: Code[20]; DomBatchPartnerType: Enum "Partner Type"; PostingDate: Date)
    var
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DomJnlBatch: Record "Domiciliation Journal Batch";
        SuggestDomiciliations: Report "Suggest domicilations";
    begin
        CreateDomJnlTemplate(DomJnlTemplate, BankAccountNo);
        CreateDomJnlBatch(DomJnlBatch, DomJnlTemplate.Name, DomBatchPartnerType);
        DomJnlLine."Journal Template Name" := DomJnlTemplate.Name;
        DomJnlLine."Journal Batch Name" := DomJnlBatch.Name;
        LibraryVariableStorage.Enqueue(SalesHeader."Due Date");
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        SuggestDomiciliations.SetJournal(DomJnlLine);
        Commit();
        SuggestDomiciliations.Run();
        DomJnlLine.SetRange("Journal Template Name", DomJnlLine."Journal Template Name");
        DomJnlLine.SetRange("Journal Batch Name", DomJnlLine."Journal Batch Name");
        DomJnlLine.FindFirst();
    end;

    local procedure CreateDirectDebitCollectionEntryFromDomJnl(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; DomiciliationJournalLine: Record "Domiciliation Journal Line")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        DirectDebitCollection.CreateRecord(
          DomiciliationJournalLine."Journal Template Name",
          DomiciliationJournalLine."Bank Account No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Domiciliation Batch Name" := DomiciliationJournalLine."Journal Batch Name";
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        Codeunit.Run(Codeunit::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);
    end;

    local procedure ExportToServerTempFile(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
    begin
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.08", OutStream, DirectDebitCollectionEntry);
        ExportFile.Close();
    end;

    local procedure ExportToTempBlob(TempBlob: Codeunit "Temp Blob"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        DirectDebitCollectionEntry.SetRecFilter();
        Xmlport.Export(Xmlport::"SEPA DD pain.008.001.08", OutStream, DirectDebitCollectionEntry);
    end;

    local procedure VerifyDDCIsDeleted(DomJnlTemplateCode: Code[10]; DomJnlBatchCode: Code[10])
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        DirectDebitCollection.SetRange(Identifier, DomJnlTemplateCode);
        DirectDebitCollection.SetRange("Domiciliation Batch Name", DomJnlBatchCode);
        Assert.IsTrue(DirectDebitCollection.IsEmpty, 'Direct Debit Collection is not deleted.')
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestDomiciliationsRequestPageHandler(var SuggestDomiciliations: TestRequestPage "Suggest domicilations")
    var
        DueDate: Variant;
        CustNo: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(DueDate);
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(CustNo);
        SuggestDomiciliations.DueDate.SetValue(DueDate);
        SuggestDomiciliations.PostingDate.SetValue(PostingDate);
        SuggestDomiciliations.Cust.SetFilter("No.", CustNo);
        SuggestDomiciliations.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileDomiciliationsRequestPageHandler(var FileDomiciliations: TestRequestPage "File Domiciliations")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateGenJnlLineRequestPageHandler(var CreateGenJnlLines: TestRequestPage "Create Gen. Jnl. Lines")
    var
        GenJnlTemplateName: Variant;
        GenJnlBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJnlTemplateName);
        LibraryVariableStorage.Dequeue(GenJnlBatchName);
        CreateGenJnlLines.GenJnlTemplate.SetValue(GenJnlTemplateName);
        CreateGenJnlLines.GenJnlBatch.SetValue(GenJnlBatchName);
        CreateGenJnlLines.PostGenJnlLines.SetValue(true);
        CreateGenJnlLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DomiciliationJournalTemplateHandler(var DomicilJournalTemplates: TestPage "Domicil. Journal Templates")
    begin
        DomicilJournalTemplates.First();
        DomicilJournalTemplates.OK().Invoke();
    end;
}

