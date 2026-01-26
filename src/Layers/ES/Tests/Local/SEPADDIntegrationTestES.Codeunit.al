codeunit 147312 "SEPA DD Integration Test - ES"
{
    // // [FEATURE] [SEPA] [Direct Debit]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        ServerFileName: Text;
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        PartnerTypeMissMatchErr: Label 'The customer''s Partner Type, Person, must be equal to the Partner Type, Company, specified in the collection.';
        SEPADDMandateIDErr: Label 'Wrong  SEPA Direct Debit Mandate ID';
        WrongNodeValueErr: Label 'Wrong node value in exported file, node no %1';
        WrongSumsErr: Label 'Wrong control sum value in exported file.';
        WrongNodeCountErr: Label 'Wrong node count in exported file, node no %1', Comment = '%1 - node name.';

    [Test]
    [HandlerFunctions('BillGroupFactoringRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportBillGroupFactoring()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
    begin
        Initialize();

        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"Bill group - Export factoring", 0);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Partner Type"::" ");

        // Exercise
        BillGroup.ExportToFile();

        // Verify
        // Verification is the requestpage handler

        VerifyDDCIsDeleted(BillGroup."No.");
    end;

    [Test]
    [HandlerFunctions('BillGroupExportN58RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportBillGroupN58()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
    begin
        Initialize();

        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"Bill group - Export N58", 0);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Partner Type"::" ");

        // Exercise
        BillGroup.ExportToFile();

        // Verify
        // Verification is the requestpage handler
        VerifyDDCIsDeleted(BillGroup."No.");
    end;

    [Test]
    [HandlerFunctions('BillGroupExportN19RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportBillGroupN19()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
    begin
        Initialize();

        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"Bill group - Export N19", 0);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Partner Type"::" ");

        // Exercise
        BillGroup.ExportToFile();

        // Verify
        // Verification is the requestpage handler
        VerifyDDCIsDeleted(BillGroup."No.");
    end;

    [Test]
    [HandlerFunctions('BillGroupExportN32RequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportBillGroupN32()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
    begin
        Initialize();

        // Setup
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"Bill group - Export N32", 0);
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Partner Type"::" ");

        // Exercise
        BillGroup.ExportToFile();

        // Verify
        // Verification is the requestpage handler
        VerifyDDCIsDeleted(BillGroup."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPA()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        CompanyInformation: Record "Company Information";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollectionEntry2: Record "Direct Debit Collection Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Company, 1, false);

        DirectDebitCollection.CreateRecord(BillGroup."No.", BankAccount."No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Source Table ID" := DATABASE::"Bill Group";
        DirectDebitCollection.Modify();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry2.CopyFilters(DirectDebitCollectionEntry);
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Exercise
        ExportToServerTempFile(DirectDebitCollectionEntry2);

        // Pre-Verify
        CompanyInformation.Get();

        // Verify
        LibraryXMLRead.Initialize(ServerFileName);
        LibraryXMLRead.VerifyNodeValue('Id', BankAccount."Creditor No.");
        LibraryXMLRead.VerifyNodeValue('ChrgBr', 'SLEV');
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty'); // TFS 379550
        LibraryXMLRead.VerifyNodeValueInSubtree('MndtRltdInf', 'MndtId', CarteraDoc."Direct Debit Mandate ID");
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', DirectDebitCollectionEntry."Transfer Amount");
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('DrctDbtTxInf', 'PmtTpInf'); // TFS 379550
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Cdtr', 'Id'); // TFS 379591
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('FinInstnId', 'BIC', BankAccount."SWIFT Code");
        // One PstlAdr tag only is exported (TFS 379423)
        Assert.AreEqual(
          1, LibraryXMLRead.GetNodesCount('PstlAdr'),
          StrSubstNo(WrongNodeCountErr, 'PstlAdr'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPAN58()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        CompanyInformation: Record "Company Information";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollectionEntry2: Record "Direct Debit Collection Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Company, 1, false);

        DirectDebitCollection.CreateRecord(BillGroup."No.", BankAccount."No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Source Table ID" := DATABASE::"Bill Group";
        DirectDebitCollection."Direct Debit Format" := DirectDebitCollection."Direct Debit Format"::N58;
        DirectDebitCollection.Modify();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry2.CopyFilters(DirectDebitCollectionEntry);
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", DirectDebitCollectionEntry);

        // Exercise
        ExportToServerTempFile(DirectDebitCollectionEntry2);

        // Pre-Verify
        CompanyInformation.Get();

        // Verify
        LibraryXMLRead.Initialize(ServerFileName);
        LibraryXMLRead.VerifyNodeValue('MsgId', 'FSDD' + DirectDebitCollection.Identifier);
        LibraryXMLRead.VerifyNodeValue('Id', BankAccount."Creditor No.");
        LibraryXMLRead.VerifyNodeValue('ChrgBr', 'SLEV');
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty'); // TFS 379550
        LibraryXMLRead.VerifyNodeValueInSubtree('MndtRltdInf', 'MndtId', CarteraDoc."Direct Debit Mandate ID");
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', DirectDebitCollectionEntry."Transfer Amount");
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('DrctDbtTxInf', 'PmtTpInf'); // TFS 379550
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Cdtr', 'Id'); // TFS 379591
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('FinInstnId', 'BIC', BankAccount."SWIFT Code")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPAPartnerTypeMissMatch()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        DirectDebitCollection: Record "Direct Debit Collection";
        CarteraManagement: Codeunit CarteraManagement;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Person, 1, false);

        BillGroup.SelectDirectDebitFormatSilently(DirectDebitCollection."Direct Debit Format"::Standard);

        // Exercise
        asserterror BillGroup.ExportToFile();

        // Verify
        Assert.ExpectedError(HasErrorsErr);

        PaymentJnlExportErrorText.SetRange("Journal Template Name", '');
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", Format(DATABASE::"Bill Group"));
        PaymentJnlExportErrorText.SetRange("Document No.", BillGroup."No.");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", CarteraDoc."Entry No.");
        Assert.AreEqual(1, PaymentJnlExportErrorText.Count, 'There are more errors then expected.');

        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", PartnerTypeMissMatchErr);

        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        CarteraManagement.RemoveReceivableDocs(CarteraDoc);

        Assert.IsTrue(PaymentJnlExportErrorText.IsEmpty, 'There should not be any errors');

        VerifyDDCIsDeleted(BillGroup."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPAWithMultipleBills()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DocumentNo: Code[20];
        BillCount: Integer;
    begin
        Initialize();

        // Setup
        BillCount := LibraryRandom.RandIntInRange(3, 10);
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Company, BillCount, false);

        DirectDebitCollection.CreateRecord(BillGroup."No.", BankAccount."No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Source Table ID" := DATABASE::"Bill Group";
        DirectDebitCollection.Modify();

        Commit();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");

        // Exercise
        ExportToServerTempFile(DirectDebitCollectionEntry);

        // Verify
        VerifyExportedValues(ServerFileName, BillCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSEPAExportErrByDeletion()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        DirectDebitCollection: Record "Direct Debit Collection";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Person, 1, false);

        BillGroup.SelectDirectDebitFormatSilently(DirectDebitCollection."Direct Debit Format"::Standard);
        asserterror BillGroup.ExportToFile();

        // Exercise
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        CarteraDoc.Delete(true);

        // Verify
        Assert.IsTrue(PaymentJnlExportErrorText.IsEmpty, 'There should not be any errors');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RedrawBillsRequestPageHandler,CarteraJnlModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDDMandateIDInRedrawBillProcess()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cartera] [Redraw]
        // [SCENARIO] Redraw Cartera Posted Bill Group with Direct Debit Mandate using Disc/Coll Expenses = False
        Initialize();

        // [GIVEN] Cartera Bill Group for Customer Bank Account with Direct Debit Mandate
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Person, 1, false);

        // [GIVEN] Bill Group is posted and closed
        PostAndCloseBillGroup(BillGroup, DocumentNo);

        // [WHEN] Redraw Closed Bill Group with Disc/Coll Expenses = False
        RunRedrawReceivableBills(DocumentNo, false);

        // [THEN] "SEPA Direct Debit Mandate ID" in transferred to redrawn Receivable Cartera Doc
        VerifyCarteraDocSEPADDMandateID(DocumentNo, GetSEPADDMandateID(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPANoDecimals()
    begin
        ExportBillGroupSEPARecurrent(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBillGroupSEPAWithDecimals()
    begin
        ExportBillGroupSEPARecurrent(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,RedrawBillsRequestPageHandler,CarteraJnlModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDDMandateIDInRedrawBillProcessWithDiscCollExpenses()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cartera] [Redraw]
        // [SCENARIO 217406] Redraw Cartera Posted Bill Group with Direct Debit Mandate using Disc/Coll Expenses = True
        Initialize();

        // [GIVEN] Cartera Bill Group for Customer Bank Account with Direct Debit Mandate
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Person, 1, false);

        // [GIVEN] Bill Group is posted and closed
        PostAndCloseBillGroup(BillGroup, DocumentNo);

        // [WHEN] Redraw Closed Bill Group with Disc/Coll Expenses = True
        RunRedrawReceivableBills(DocumentNo, true);

        // [THEN] "SEPA Direct Debit Mandate ID" in transferred to redrawn Receivable Cartera Doc
        VerifyCarteraDocSEPADDMandateID(DocumentNo, GetSEPADDMandateID(DocumentNo));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure ExportBillGroupSEPARecurrent(NoDecimals: Boolean)
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DocumentNo: Code[20];
        BillCount: Integer;
    begin
        Initialize();

        // Setup
        BillCount := LibraryRandom.RandIntInRange(3, 10);
        CreatePostSalesInvoiceAndCreateBillGroup(
          BillGroup, CarteraDoc, BankAccount, DocumentNo, "Partner Type"::Company, BillCount, NoDecimals);

        DirectDebitCollection.CreateRecord(BillGroup."No.", BankAccount."No.", DirectDebitCollection."Partner Type"::Company);
        DirectDebitCollection."Source Table ID" := DATABASE::"Bill Group";
        DirectDebitCollection.Modify();

        Commit();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");

        // Exercise
        ExportToServerTempFile(DirectDebitCollectionEntry);

        // Verify
        if NoDecimals then
            VerifyExportedZeroDecimals(ServerFileName, BillCount + 1)
        else
            VerifyExportedSums(ServerFileName, BillCount + 1);
    end;

    local procedure CreatePostSalesInvoiceAndCreateBillGroup(var BillGroup: Record "Bill Group"; var CarteraDoc: Record "Cartera Doc."; var BankAccount: Record "Bank Account"; var DocumentNo: Code[20]; BillGroupPartnerType: Enum "Partner Type"; ExpectedNumberOfPayments: Integer; RoundToInt: Boolean)
    begin
        if ExpectedNumberOfPayments > 1 then
            DocumentNo := PostCustomerSalesInvoiceMultiplePayments(BillGroupPartnerType, ExpectedNumberOfPayments, RoundToInt)
        else
            DocumentNo := PostCustomerSalesInvoice(BillGroupPartnerType, RoundToInt);
        CreateBankAccountWithBillGroup(BankAccount, BillGroup);
        ModifyCarteraDoc(CarteraDoc, DocumentNo, BillGroup."No.");
    end;

    local procedure CreateBankAccountWithBillGroup(var BankAccount: Record "Bank Account"; var BillGroup: Record "Bill Group")
    begin
        CreateBankAccountWithExportImportSetup(BankAccount, CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.02");
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Partner Type"::Company);
        ModifyBankAccount(BankAccount);
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; ProcessingCodeunitId: Integer; ProcessingXmlPortId: Integer)
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Preserve Non-Latin Characters" := true;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitId;
        BankExportImportSetup."Processing XMLport ID" := ProcessingXmlPortId;
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA DD-Check Line";
        BankExportImportSetup.Insert();
    end;

    local procedure CreateBankAccountWithExportImportSetup(var BankAccount: Record "Bank Account"; CodeunitID: Integer; XmlPortID: Integer)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateOperationFeesWithRange(BankAccount);
        CreateBankExportImportSetup(BankExportImportSetup, CodeunitID, XmlPortID);
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
    end;

    local procedure CreateBillGroup(var BillGroup: Record "Bill Group"; BankAccNo: Code[20]; PartnerType: Enum "Partner Type")
    begin
        BillGroup."No." := LibraryUtility.GenerateRandomCode(BillGroup.FieldNo("No."), DATABASE::"Bill Group");
        BillGroup."Posting Date" := WorkDate();
        BillGroup."Bank Account No." := BankAccNo;
        BillGroup."Partner Type" := PartnerType;
        BillGroup.Insert();
    end;

    local procedure CreatePaymentTerms(NoOfInstallments: Integer): Code[10]
    var
        Installment: Record Installment;
        PaymentTerms: Record "Payment Terms";
        CurrentPercent: Integer;
        TotalPercent: Integer;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        while NoOfInstallments >= 1 do begin
            LibraryESLocalization.CreateInstallment(Installment, PaymentTerms.Code);
            CurrentPercent := 10;
            if NoOfInstallments = 1 then
                CurrentPercent := 100 - TotalPercent
            else
                TotalPercent += 10;
            Installment.Validate("% of Total", CurrentPercent);
            Installment.Validate("Gap between Installments", '<10D>');
            Installment.Modify();
            NoOfInstallments -= 1;
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure CreateOperationFeesWithRange(BankAccount: Record "Bank Account")
    var
        FeeRange: Record "Fee Range";
    begin
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(
          FeeRange, BankAccount."No.", BankAccount."Currency Code", FeeRange."Type of Fee"::"Collection Expenses");
    end;

    local procedure ModifyCarteraDoc(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20]; NewBillGroupNo: Code[20])
    begin
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindSet();
        repeat
            CarteraDoc."Bill Gr./Pmt. Order No." := NewBillGroupNo;
            CarteraDoc.Modify();
        until CarteraDoc.Next() = 0;
    end;

    local procedure ModifyBankAccount(var BankAccount: Record "Bank Account")
    begin
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAccount."Creditor No." := LibraryUtility.GenerateGUID();
        BankAccount.Modify();
    end;

    local procedure FindCarteraDoc(var CarteraDoc: Record "Cartera Doc."; DocumentNo: Code[20])
    begin
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindLast();
    end;

    local procedure FindPostedCarteraDoc(var PostedCarteraDoc: Record "Posted Cartera Doc."; DocumentNo: Code[20])
    begin
        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Receivable);
        PostedCarteraDoc.SetRange("Document No.", DocumentNo);
        PostedCarteraDoc.FindLast();
    end;

    local procedure FindClosedCarteraDoc(var ClosedCarteraDoc: Record "Closed Cartera Doc."; DocumentNo: Code[20])
    begin
        ClosedCarteraDoc.SetRange(Type, ClosedCarteraDoc.Type::Receivable);
        ClosedCarteraDoc.SetRange("Document No.", DocumentNo);
        ClosedCarteraDoc.FindLast();
    end;

    local procedure FindClearCarteraGenJnlBatch(var CarteraGenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(CarteraGenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.ClearGenJournalLines(CarteraGenJnlBatch);
    end;

    local procedure GetSEPADDMandateID(DocumentNo: Code[20]): Code[35]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        exit(SalesInvoiceHeader."Direct Debit Mandate ID");
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
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02", OutStream, DirectDebitCollectionEntry);
        ExportFile.Close();
    end;

    local procedure RunSettlePostedCarteraDocs(var PostedCarteraDoc: Record "Posted Cartera Doc.")
    var
        SettleDocsInPostBillGr: Report "Settle Docs. in Post. Bill Gr.";
    begin
        SettleDocsInPostBillGr.SetTableView(PostedCarteraDoc);
        SettleDocsInPostBillGr.UseRequestPage(false);
        SettleDocsInPostBillGr.RunModal();
    end;

    local procedure RunRedrawReceivableBills(DocumentNo: Code[20]; DiscCollExpenses: Boolean)
    var
        CarteraGenJnlBatch: Record "Gen. Journal Batch";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        RedrawReceivableBills: Report "Redraw Receivable Bills";
    begin
        FindClosedCarteraDoc(ClosedCarteraDoc, DocumentNo);
        FindClearCarteraGenJnlBatch(CarteraGenJnlBatch);
        LibraryVariableStorage.Enqueue(CarteraGenJnlBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(CarteraGenJnlBatch.Name);
        LibraryVariableStorage.Enqueue(DiscCollExpenses);

        CustLedgEntry.SetRange("Entry No.", ClosedCarteraDoc."Entry No.");
        Commit();

        RedrawReceivableBills.SetTableView(CustLedgEntry);
        RedrawReceivableBills.UseRequestPage(true);
        RedrawReceivableBills.RunModal();
    end;

    local procedure PostCustomerSalesInvoice(CustomerPartnerType: Enum "Partner Type"; RoundToInt: Boolean): Code[20]
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        PrepareCustomer(CustomerPartnerType, 1, Customer, SEPADirectDebitMandate);
        exit(CreatePostSalesInvoice(Customer."No.", SEPADirectDebitMandate.ID, RoundToInt));
    end;

    local procedure PostCustomerSalesInvoiceMultiplePayments(CustomerPartnerType: Enum "Partner Type"; ExpectedNumberOfDebits: Integer; RoundToInt: Boolean): Code[20]
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        PrepareCustomer(CustomerPartnerType, ExpectedNumberOfDebits, Customer, SEPADirectDebitMandate);
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate.Validate("Expected Number of Debits", ExpectedNumberOfDebits);
        SEPADirectDebitMandate.Modify();
        exit(CreatePostSalesInvoice(Customer."No.", SEPADirectDebitMandate.ID, RoundToInt));
    end;

    local procedure PostAndCloseBillGroup(BillGroup: Record "Bill Group"; DocumentNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        FindPostedCarteraDoc(PostedCarteraDoc, DocumentNo);
        RunSettlePostedCarteraDocs(PostedCarteraDoc);
    end;

    local procedure PrepareCustomer(CustomerPartnerType: Enum "Partner Type"; NumberOfPayments: Integer; var Customer: Record Customer; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        PaymentMethod: Record "Payment Method";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Create Bills" := true;
        PaymentMethod."Collection Agent" := PaymentMethod."Collection Agent"::Bank;
        PaymentMethod."Bill Type" := PaymentMethod."Bill Type"::Transfer;
        PaymentMethod.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := LibraryUtility.GenerateGUID();
        if NumberOfPayments > 1 then
            Customer."Payment Terms Code" := CreatePaymentTerms(NumberOfPayments);
        Customer."Payment Method Code" := PaymentMethod.Code;
        Customer."Partner Type" := CustomerPartnerType;
        Customer.Modify();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID();
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify();
        LibrarySales.CreateCustomerMandate(
          SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code, WorkDate(), CalcDate('<1Y>', WorkDate()));
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]; SEPADirectDebitMandateID: Code[35]; RoundToInt: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader."Direct Debit Mandate ID" := SEPADirectDebitMandateID;
        SalesHeader.Modify();
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        if RoundToInt then
            SalesLine.Validate("Unit Price", Round(SalesLine."Unit Price", 100, '>'))
        else
            SalesLine.Validate(
              "Unit Price",
              LibraryRandom.RandIntInRange(10, 1000) +
              (LibraryRandom.RandIntInRange(1, 9) / 10) +
              (LibraryRandom.RandIntInRange(1, 9) / 100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure VerifyDDCIsDeleted(BillGroupNo: Code[20])
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        DirectDebitCollection.SetRange(Identifier, BillGroupNo);
        DirectDebitCollection.SetRange("Source Table ID", DATABASE::"Bill Group");
        Assert.IsTrue(DirectDebitCollection.IsEmpty, 'Direct Debit Collection Entry is not deleted.')
    end;

    local procedure VerifyCarteraDocSEPADDMandateID(DocumentNo: Code[20]; ExpectedDDMandateID: Code[35])
    var
        CarteraDoc: Record "Cartera Doc.";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        FindCarteraDoc(CarteraDoc, DocumentNo);
        CustLedgEntry.Get(CarteraDoc."Entry No.");
        Assert.AreEqual(ExpectedDDMandateID, CarteraDoc."Direct Debit Mandate ID", SEPADDMandateIDErr);
        Assert.AreEqual(ExpectedDDMandateID, CustLedgEntry."Direct Debit Mandate ID", SEPADDMandateIDErr);
    end;

    local procedure VerifyExportedValues(ServerFileName: Text; ExpectedNodeCount: Integer)
    var
        Counter: Integer;
        ExpectedValue: Text;
    begin
        LibraryXMLRead.Initialize(ServerFileName);
        for Counter := 0 to ExpectedNodeCount - 1 do begin
            case Counter of
                0:
                    ExpectedValue := 'FRST';
                ExpectedNodeCount - 1:
                    ExpectedValue := 'FNAL';
                else
                    ExpectedValue := 'RCUR';
            end;
            Assert.AreEqual(
              ExpectedValue, LibraryXMLRead.GetNodeValueAtIndex('SeqTp', Counter),
              StrSubstNo(WrongNodeValueErr, Counter));
        end;
    end;

    local procedure VerifyExportedZeroDecimals(ServerFileName: Text; ExpectedNodeCount: Integer)
    var
        NodeText: Text;
        Counter: Integer;
    begin
        LibraryXMLRead.Initialize(ServerFileName);
        for Counter := 0 to ExpectedNodeCount - 1 do begin
            NodeText := LibraryXMLRead.GetNodeValueAtIndex('CtrlSum', Counter);
            NodeText := ConvertStr(CopyStr(NodeText, StrLen(NodeText) - 2, 3), ',', '.');
            Assert.AreEqual('.00', NodeText, StrSubstNo(WrongNodeValueErr, Counter));
        end;
    end;

    local procedure VerifyExportedSums(ServerFileName: Text; ExpectedNodeCount: Integer)
    var
        CurrentValue: Decimal;
        Residual: Decimal;
        Counter: Integer;
    begin
        LibraryXMLRead.Initialize(ServerFileName);
        for Counter := 0 to ExpectedNodeCount - 1 do begin
            Evaluate(CurrentValue, LibraryXMLRead.GetNodeValueAtIndex('CtrlSum', Counter));
            if Counter = 0 then
                Residual := CurrentValue
            else
                Residual -= CurrentValue;
        end;
        Assert.AreEqual(0, Residual, WrongSumsErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupFactoringRequestPageHandler(var BillGroupExportfactoring: TestRequestPage "Bill group - Export factoring")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN58RequestPageHandler(var BillGroupExportN58: TestRequestPage "Bill group - Export N58")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN19RequestPageHandler(var BillGroupExportN19: TestRequestPage "Bill group - Export N19")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupExportN32RequestPageHandler(var BillGroupExportN32: TestRequestPage "Bill group - Export N32")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawBillsRequestPageHandler(var RedrawBillsPageHandler: TestRequestPage "Redraw Receivable Bills")
    var
        CarteraGenJnlTemplateName: Variant;
        CarteraGenJnlBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CarteraGenJnlTemplateName);
        LibraryVariableStorage.Dequeue(CarteraGenJnlBatchName);
        RedrawBillsPageHandler.NewDueDate.SetValue(WorkDate() + 1);
        RedrawBillsPageHandler.AuxJnlTemplateName.SetValue(CarteraGenJnlTemplateName);
        RedrawBillsPageHandler.AuxJnlBatchName.SetValue(CarteraGenJnlBatchName);
        RedrawBillsPageHandler.DiscCollExpenses.SetValue(LibraryVariableStorage.DequeueBoolean());
        RedrawBillsPageHandler.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJnlModalPageHandler(var CarteraJournalTestPage: TestPage "Cartera Journal")
    begin
        CarteraJournalTestPage.Post.Invoke();
    end;
}

