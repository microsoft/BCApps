codeunit 139154 "Incoming Doc. To Data Exch.UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Incoming Document]
    end;

    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServPEPPOLManagement: Codeunit "Serv. PEPPOL Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        NamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
        TableErrorMsg: Label '%1 Line:%2', Comment = '%1 - error message, %2 - line number';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AssertMsg: Label '%1 Field:"%2" different from expected.', Comment = '%1 - error message, %2 - field number';
        SalesLineCodeTxt: Label 'SL';
        SalesHeaderCodeTxt: Label 'SH';
        PEPPOLSalesHeaderCodeTxt: Label 'PEPPOLINVHEADER', Locked = true;
        PEPPOLSalesLineCodeTxt: Label 'PEPPOLINVLINES', Locked = true;
        SalesLineDescriptionTxt: Label 'Sales Line';
        SalesHeaderDescriptionTxt: Label 'Sales Header';
        IncorrectNamespaceErr: Label 'The imported file contains unsupported namespace "%1". The supported namespace is ''%2''.', Comment = '%1=File XML Namespace,%2=Supported XML Namespace';
        UTF8Txt: Label 'UTF-8', Locked = true;
        FileManagement: Codeunit "File Management";
        CannotCreateErr: Label 'Cannot create the document. Make sure the data exchange definition is correct.';
        CannotFindColumnErr: Label 'Cannot find Column No. %1 for Line Definition %2.', Comment = '%1 - column number,%2 - line definition code';
        AutomMsg: Label 'selected Incoming Documents.\\Are you sure you want to create documents manually?';
        CannotFindPurchaseHeaderErr: Label 'Cannot find created Purchase Header.';
        CannotFindGenJnlLineErr: Label 'Cannot find created General Journal Line.';
        CannotFindPurchaseLineErr: Label 'No Purchase Lines could be found.';
        CannotFindSalesLineErr: Label 'No Sales Lines could be found.';
        CannotFindServiceLineErr: Label 'No Service Lines could be found.';
        DocNotCreatedMsg: Label 'The document was not created due to errors in the conversion process.';
        DocCreatedMsg: Label 'has been created';
        InvalidCompanyInfoVATRegNoErr: Label 'The customer''s VAT registration number %1 on the incoming document does not match the VAT Registration No. in the Company Information window.', Comment = '%1 VAT Registration Number (format could be AB###### or ###### or AB##-##-###)';
        NoBalanceAccountMappingErr: Label 'Could not fill the Bal. Account No. field for vendor ''''%1''''. Choose the Map Text to Account button to map ''''%1'''' to the relevant G/L account.', Comment = '%1 - vendor name';
        NothingToReleaseErr: Label 'There is nothing to release for the incoming document';
        NoDocCreatedForChoiceErr: Label 'The given key was not present in the dictionary.';
        UnknownChoiceErr: Label 'Unknown choice %1.', Comment = '%1=Choice (number)';
        PEPPOLINVOICELbl: Label 'PEPPOLINVOICE';
        PEPPOLLbl: Label 'PEPPOL';
        StatusErr: Label '%1 must be %2 in %3';

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLNestingWithNoNamespacesPersistedInDataExchField()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNestingAndWithNoNamespaces(OutStream, UTF8Txt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceAndLinesWithNoNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLNestingWithNamespacesPersistedInDataExchField()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNestingAndWithNamespaces(OutStream, UTF8Txt, NamespaceTxt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceAndLinesWithNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExtractOnlyHeadersFromNestedXmlWithNoNamespaces()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNestingAndWithNoNamespaces(OutStream, UTF8Txt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceWithNoNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithoutNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExtractOnlyHeadersFromNestedXmlWithNamespaces()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNestingAndWithNamespaces(OutStream, UTF8Txt, NamespaceTxt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceWithNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithoutNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExtractOnlyHeadersFromUnNestedXmlWithNoNamespaces()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNoNestingAndWithNoNamespaces(OutStream, UTF8Txt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceAndLinesWithNoNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithoutNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExtractOnlyHeadersFromUnNestedXmlWithNamespaces()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteInvoiceFileWithNoNestingAndWithNamespaces(OutStream, UTF8Txt, NamespaceTxt);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceWithNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeWithoutNesting(TempExpectedDataExchField, DataExch);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnsupportedNamespace()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        UnsupportedNamespace: Text;
    begin
        // Setup: create test input file
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        UnsupportedNamespace := NamespaceTxt + '2';
        WriteInvoiceFileWithNoNestingAndWithNamespaces(OutStream, UTF8Txt, UnsupportedNamespace);

        // Setup: create data exchange setup
        CreateDataExchDefSalesInvoiceWithNamespaces(DataExchDef);
        CreateDataExch(DataExch, DataExchDef, TempBlobUTF8);

        // Execute: run data exchange parser
        asserterror CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);
        Assert.ExpectedError(StrSubstNo(IncorrectNamespaceErr, UnsupportedNamespace, NamespaceTxt));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,PageHandler43,PageHandler44,PageHandler51,PageHandler52')]
    [Scope('OnPrem')]
    procedure TestManualCreationOptionsMatchDocumentType()
    var
        IncomingDocument: Record "Incoming Document";
        GeneralJournal: TestPage "General Journal";
        InvalidChoice: Enum "Incoming Related Document Type";
    begin
        Initialize();
        InvalidChoice := "Incoming Related Document Type".FromInteger(10000);

        // Setup: configure data exchange setup and create incoming document
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute and Assert
        AssertDataExchTypeMatchesResponse(IncomingDocument, IncomingDocument."Document Type"::"Sales Invoice");

        // Setup: configure data exchange setup and create incoming document
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute and Assert
        AssertDataExchTypeMatchesResponse(IncomingDocument, IncomingDocument."Document Type"::"Sales Credit Memo");

        // Setup: configure data exchange setup and create incoming document
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute and Assert
        AssertDataExchTypeMatchesResponse(IncomingDocument, IncomingDocument."Document Type"::"Purchase Invoice");

        // Setup: configure data exchange setup and create incoming document
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute and Assert
        AssertDataExchTypeMatchesResponse(IncomingDocument, IncomingDocument."Document Type"::"Purchase Credit Memo");

        // Setup: configure data exchange setup and create incoming document
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute and Assert
        GeneralJournal.Trap();
        AssertDataExchTypeMatchesResponse(IncomingDocument, IncomingDocument."Document Type"::Journal);
        GeneralJournal.Close();

        asserterror AssertDataExchTypeMatchesResponse(IncomingDocument, InvalidChoice);
        Assert.ExpectedError(StrSubstNo(NoDocCreatedForChoiceErr, InvalidChoice));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHeaderFieldsExtractedForDefaultAttachment()
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        CompanyInformation: Record "Company Information";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice,
          CreateSalesDocument(SalesHeader."Document Type"::Invoice, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);
        SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);
        IncomingDocument.Get(IncomingDocument."Entry No.");

        // verify
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation.Name, IncomingDocument."Vendor Name", '');
        Assert.AreEqual(SalesInvoiceHeader."No.", IncomingDocument."Vendor Invoice No.", '');
        Assert.AreEqual(SalesHeader."Document Date", IncomingDocument."Document Date", '');
        Assert.AreEqual(SalesHeader."Due Date", IncomingDocument."Due Date", '');
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(SalesInvoiceHeader.Amount, IncomingDocument."Amount Excl. VAT", '');
        Assert.AreEqual(SalesInvoiceHeader."Amount Including VAT", IncomingDocument."Amount Incl. VAT", '');
        Assert.AreEqual(SalesHeader."Currency Code", IncomingDocument."Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPEPPOLDataExchDef()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibrarySales: Codeunit "Library - Sales";
        File: File;
        InStream: InStream;
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, CreateSalesDocument(SalesHeader."Document Type"::Invoice, true));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);

        // Setup: create data exchange setup
        DataExchDef.Get('PEPPOLINVOICE');

        File.Open(XmlPath);
        File.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDef.Code);

        // Execute: run data exchange parser
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Prepare expected outcome
        CreateExpectedOutcomeForPEPPOLInvoice(TempExpectedDataExchField, DataExch, SalesInvoiceHeader);

        // verify entries in the Data Exch. Field table
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertSpecifiedDataInTable(TempExpectedDataExchField, DataExchField);

        // Close file
        File.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolInvoiceImportLCY()
    begin
        PEPPOLInvoiceImport(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolInvoiceImportNonLCY()
    begin
        PEPPOLInvoiceImport(false);
    end;

    local procedure PEPPOLInvoiceImport(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice,
          CreateSalesDocument(SalesHeader."Document Type"::Invoice, InvoiceCurrencyIsLCY));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);
        SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateDocument.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');
        AssertInvoiceHeaderValues(IncomingDocument, PurchaseHeader, SalesInvoiceHeader, InvoiceCurrencyIsLCY);
        AssertInvoiceLineValues(PurchaseHeader, SalesInvoiceHeader);

        // cleanup
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Delete(true);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolServiceInvoiceImportLCY()
    begin
        PEPPOLServiceInvoiceImport(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolServiceInvoiceImportNonLCY()
    begin
        PEPPOLServiceInvoiceImport(false);
    end;

    local procedure PEPPOLServiceInvoiceImport(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        CreateServiceInvoiceAndPost(ServiceInvoiceHeader, InvoiceCurrencyIsLCY);

        XmlPath := ExportPEPPOLInvoice(ServiceInvoiceHeader);
        SetupCompanyForServiceInvoiceImport(ServiceInvoiceHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateDocument.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');
        AssertServiceInvoiceHeaderValues(IncomingDocument, PurchaseHeader, ServiceInvoiceHeader, InvoiceCurrencyIsLCY);
        AssertServiceInvoiceLineValues(PurchaseHeader, ServiceInvoiceHeader);

        // cleanup
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Delete(true);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolInvoiceToGenJnlLineLCY()
    begin
        TestPEPPOLInvoiceToGenJnlLine(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolInvoiceToGenJnlLineNonLCY()
    begin
        TestPEPPOLInvoiceToGenJnlLine(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPEPPOLInvoiceToGenJnlLineFailsNoMapping()
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CompanyInformation: Record "Company Information";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
        ExpectedErrorMessage: Text;
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice,
          CreateSalesDocument(SalesHeader."Document Type"::Invoice, false));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);
        VendorNo := SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // break the Vendor.GLN link, so that we have to set up a Bal. Account No. mapping
        Vendor.Get(VendorNo);
        Vendor.GLN := '';
        Vendor.Modify();

        // add a balancing account to the general journal batch
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        IncomingDocumentsSetup.Get();
        GenJournalBatch.Get(IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJournalBatch."No. Series" := NoSeries.Code;
        GenJournalBatch.Modify();

        // set up a text-to account mapping, but omit Bal. Account No.
        CompanyInformation.Get();
        PurchasesPayablesSetup.Get();
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := LowerCase(CompanyInformation.Name);
        TextToAccountMapping."Debit Acc. No." := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        TextToAccountMapping."Bal. Source Type" := TextToAccountMapping."Bal. Source Type"::Vendor;
        TextToAccountMapping.Insert();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := '';
        PurchasesPayablesSetup.Modify();

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchanges
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);

        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateGenJnlLine.Invoke();

        // Assert Result
        ExpectedErrorMessage := StrSubstNo(NoBalanceAccountMappingErr, CompanyInformation.Name);
        Assert.IsTrue(IncomingDocumentCard.ErrorMessagesPart.FindFirstField(Description, ExpectedErrorMessage),
          'Expected error message not found');
    end;

    local procedure TestPEPPOLInvoiceToGenJnlLine(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        GenJournalLine: Record "Gen. Journal Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CompanyInformation: Record "Company Information";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IncomingDocuments: TestPage "Incoming Documents";
        GeneralJournal: TestPage "General Journal";
        XmlPath: Text;
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice,
          CreateSalesDocument(SalesHeader."Document Type"::Invoice, InvoiceCurrencyIsLCY));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);
        VendorNo := SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // break the Vendor.GLN link, so that we have to set up a Bal. Account No. mapping
        Vendor.Get(VendorNo);
        Vendor.GLN := '';
        Vendor.Modify();

        // add a balancing account to the general journal batch
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        IncomingDocumentsSetup.Get();
        GenJournalBatch.Get(IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := GLAccount."No.";
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJournalBatch."No. Series" := NoSeries.Code;
        GenJournalBatch.Modify();

        // set up a text-to account mapping
        CompanyInformation.Get();
        PurchasesPayablesSetup.Get();
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := LowerCase(CompanyInformation.Name);
        TextToAccountMapping."Debit Acc. No." := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        TextToAccountMapping."Bal. Source Type" := TextToAccountMapping."Bal. Source Type"::"Bank Account";
        LibraryERM.CreateBankAccount(BankAccount);
        TextToAccountMapping."Bal. Source No." := BankAccount."No.";
        TextToAccountMapping.Insert();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := '';
        PurchasesPayablesSetup.Modify();

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        if InvoiceCurrencyIsLCY then begin
            GeneralLedgerSetup.Get();
            IncomingDocument."Currency Code" := GeneralLedgerSetup."LCY Code";
        end;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchanges
        LibraryVariableStorage.Enqueue(AutomMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(DocCreatedMsg);

        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateGenJnlLine.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocuments.StatusField.Value, '');

        // Assert General Journal Line
        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not GenJournalLine.FindFirst() then
            Error(CannotFindGenJnlLineErr);

        Assert.AreEqual(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type", '');
        Assert.AreEqual(TextToAccountMapping."Bal. Source Type", GenJournalLine."Bal. Account Type", '');
        Assert.AreEqual(TextToAccountMapping."Bal. Source No.", GenJournalLine."Bal. Account No.", '');
        if GenJournalLine."Due Date" <> 0D then
            Assert.AreEqual(SalesHeader."Due Date", GenJournalLine."Due Date", '');
        Assert.AreEqual(SalesHeader."Document Date", GenJournalLine."Document Date", '');
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        Assert.AreEqual(SalesInvoiceHeader."Amount Including VAT", GenJournalLine.Amount, '');
        Assert.AreEqual(SalesInvoiceHeader."No.", GenJournalLine."External Document No.", '');
        Assert.AreEqual(TextToAccountMapping."Debit Acc. No.", GenJournalLine."Account No.", '');
        Assert.AreEqual(CompanyInformation.Name, GenJournalLine.Description, '');

        // Assert opened page
        GeneralJournal.Trap();
        IncomingDocument.Get(IncomingDocument."Entry No.");
        IncomingDocument.ShowRecord();
        Assert.AreEqual(GenJournalLine."Journal Batch Name", GeneralJournal.CurrentJnlBatchName.Value, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolCreditMemoImportLCY()
    begin
        PEPPOLCreditMemoImport(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolCreditMemoImportNonLCY()
    begin
        PEPPOLCreditMemoImport(false);
    end;

    local procedure PEPPOLCreditMemoImport(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo",
          CreateSalesDocument(SalesHeader."Document Type"::"Credit Memo", InvoiceCurrencyIsLCY));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLCreditMemo(SalesCrMemoHeader);

        SetupCompanyForCreditMemoImport(SalesCrMemoHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLCREDITMEMO');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Warning;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateDocument.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');
        AssertCrMemoHeaderValues(IncomingDocument, PurchaseHeader, SalesCrMemoHeader, InvoiceCurrencyIsLCY);
        AssertCrMemoLineValues(PurchaseHeader, SalesCrMemoHeader);

        // cleanup
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Delete(true);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolServiceCreditMemoImportLCY()
    begin
        PEPPOLServiceCreditMemoImport(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolServiceCreditMemoImportNonLCY()
    begin
        PEPPOLServiceCreditMemoImport(false);
    end;

    local procedure PEPPOLServiceCreditMemoImport(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        CreateServiceCreditMemoAndPost(ServiceCrMemoHeader, InvoiceCurrencyIsLCY);

        XmlPath := ExportPEPPOLCreditMemo(ServiceCrMemoHeader);
        SetupCompanyForServiceCreditMemoImport(ServiceCrMemoHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLCREDITMEMO');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Warning;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateDocument.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocumentCard.StatusField.Value, '');

        AssertServiceCrMemoHeaderValues(IncomingDocument, PurchaseHeader, ServiceCrMemoHeader, InvoiceCurrencyIsLCY);
        AssertServiceCrMemoLineValues(PurchaseHeader, ServiceCrMemoHeader);

        // cleanup
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Delete(true);
        Vendor.Delete(true);
        IncomingDocument.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolCreditMemoToGenJnlLineLCY()
    begin
        TestPEPPOLCreditMemoToGenJnlLine(true)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolCreditMemotoGenJnlLineNonLCY()
    begin
        TestPEPPOLCreditMemoToGenJnlLine(false)
    end;

    local procedure TestPEPPOLCreditMemoToGenJnlLine(InvoiceCurrencyIsLCY: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CompanyInformation: Record "Company Information";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        IncomingDocuments: TestPage "Incoming Documents";
        XmlPath: Text;
        VendorNo: Code[20];
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo",
          CreateSalesDocument(SalesHeader."Document Type"::"Credit Memo", InvoiceCurrencyIsLCY));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLCreditMemo(SalesCrMemoHeader);
        CompanyInformation.Get();
        VendorNo := SetupCompanyForCreditMemoImport(SalesCrMemoHeader);

        // break the Vendor.GLN link, so that we have to set up a Bal. Account No. mapping
        Vendor.Get(VendorNo);
        Vendor.GLN := '';
        Vendor.Modify();

        // add a balancing account to the general journal batch
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        IncomingDocumentsSetup.Get();
        GenJournalBatch.Get(IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := GLAccount."No.";
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJournalBatch."No. Series" := NoSeries.Code;
        GenJournalBatch.Modify();

        // set up a text-to account mapping
        CompanyInformation.Get();
        PurchasesPayablesSetup.Get();
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := UpperCase(CompanyInformation.Name);
        TextToAccountMapping."Credit Acc. No." := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines";
        TextToAccountMapping."Bal. Source Type" := TextToAccountMapping."Bal. Source Type"::"G/L Account";
        TextToAccountMapping."Bal. Source No." := PurchasesPayablesSetup."Credit Acc. for Non-Item Lines";
        TextToAccountMapping.Insert();
        PurchasesPayablesSetup."Credit Acc. for Non-Item Lines" := '';
        PurchasesPayablesSetup.Modify();

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLCREDITMEMO');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(AutomMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateGenJnlLine.Invoke();

        // Assert Result
        Assert.AreEqual(Format(IncomingDocument.Status::Created), IncomingDocuments.StatusField.Value, '');

        // Assert Purchase Invoice Header
        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not GenJournalLine.FindFirst() then
            Error(CannotFindGenJnlLineErr);

        Assert.AreEqual(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type", '');
        Assert.AreEqual(TextToAccountMapping."Bal. Source Type", GenJournalLine."Bal. Account Type", '');
        Assert.AreEqual(TextToAccountMapping."Bal. Source No.", GenJournalLine."Bal. Account No.", '');
        if GenJournalLine."Due Date" <> 0D then
            Assert.AreEqual(SalesHeader."Due Date", GenJournalLine."Due Date", '');
        Assert.AreEqual(SalesHeader."Document Date", GenJournalLine."Document Date", '');
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        Assert.AreEqual(SalesCrMemoHeader."Amount Including VAT", GenJournalLine.Amount, '');
        Assert.AreEqual(SalesCrMemoHeader."No.", GenJournalLine."External Document No.", '');
        Assert.AreEqual(TextToAccountMapping."Credit Acc. No.", GenJournalLine."Account No.", '');
        Assert.AreEqual(CompanyInformation.Name, GenJournalLine.Description, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolImportFails()
    var
        CompanyInformation: Record "Company Information";
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        Customer: Record Customer;
        IncomingDocuments: TestPage "Incoming Documents";
        XmlPath: Text;
    begin
        Initialize();

        // Setup: export XML
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, CreateSalesDocument(SalesHeader."Document Type"::Invoice, true));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);

        SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify(true);

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify();

        // Setup: attach XML
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateDocument.Invoke();

        // Verify - there should be the error about missing G/L Account for non-item lines;
        Assert.AreEqual(Format(IncomingDocument.Status::Failed), IncomingDocuments.StatusField.Value, '');
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        AssertExpectedError(IncomingDocuments,
          StrSubstNo(InvalidCompanyInfoVATRegNoErr, Customer."VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestProcessWithDataExchWithNoFileContentFails()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceWithNoNamespaces(DataExchDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document, but don't attach any file
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Execute
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.CreateDocument.Invoke();

        // Verify;
        Assert.ExpectedError(NothingToReleaseErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessWithDataExchWithInvalidNamespaceFails()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
        File: File;
        OutStream: OutStream;
        FileName: Text;
        UnsupportedNamespace: Text;
    begin
        // Init: Create test input file
        FileName := FileManagement.ServerTempFileName('xml');
        File.Create(FileName, TEXTENCODING::UTF8);
        File.CreateOutStream(OutStream);
        UnsupportedNamespace := NamespaceTxt + '2';
        WriteInvoiceFileWithNoNestingAndWithNamespaces(OutStream, UTF8Txt, UnsupportedNamespace);
        File.Close();
        FileName := FileManagement.DownloadTempFile(FileName);

        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceWithNamespaces(DataExchDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document, but don't fill in any Data Exchange Definition Code
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocument, FileName);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Execute
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateDocument.Invoke();

        // Verify;
        Assert.AreEqual(Format(IncomingDocument.Status::Failed), IncomingDocuments.StatusField.Value, '');
        AssertExpectedError(IncomingDocuments, StrSubstNo(IncorrectNamespaceErr, UnsupportedNamespace, NamespaceTxt));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessWithDataExchWithInvalidContentFails()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
        File: File;
        OutStream: OutStream;
        FileName: Text;
    begin
        // Init: Create test input file
        FileName := FileManagement.ServerTempFileName('xml');
        File.Create(FileName, TEXTENCODING::UTF8);
        File.CreateOutStream(OutStream);
        WriteLine(OutStream, 'ABC');
        File.Close();
        FileName := FileManagement.DownloadTempFile(FileName);

        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceWithNamespaces(DataExchDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document, but don't fill in any Data Exchange Definition Code
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocument, FileName);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Execute
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateDocument.Invoke();

        // Verify;
        Assert.AreEqual(Format(IncomingDocument.Status::Failed), IncomingDocuments.StatusField.Value, '');
        AssertExpectedErrorSubstring(IncomingDocuments, 'Data at the root level is invalid');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessWithDataExchWithoutMappingFails()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
        File: File;
        OutStream: OutStream;
        FileName: Text;
    begin
        // Init: Create test input file
        FileName := FileManagement.ServerTempFileName('xml');
        File.Create(FileName, TEXTENCODING::UTF8);
        File.CreateOutStream(OutStream);
        WriteInvoiceFileWithNestingAndWithNoNamespaces(OutStream, UTF8Txt);
        File.Close();
        FileName := FileManagement.DownloadTempFile(FileName);

        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceAndLinesWithNoNamespaces(DataExchDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocument, FileName);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Execute
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateDocument.Invoke();

        // Verify;
        Assert.AreEqual(Format(IncomingDocument.Status::Failed), IncomingDocuments.StatusField.Value, '');
        AssertExpectedErrorSubstring(IncomingDocuments, 'There is no Data Exch. Mapping');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestProcessWithDataExchSucceeds()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
        File: File;
        OutStream: OutStream;
        FileName: Text;
    begin
        // Init: Create test input file
        FileName := FileManagement.ServerTempFileName('xml');
        File.Create(FileName, TEXTENCODING::UTF8);
        File.CreateOutStream(OutStream);
        WriteInvoiceFileWithNoNestingAndWithNoNamespaces(OutStream, UTF8Txt);
        File.Close();
        FileName := FileManagement.DownloadTempFile(FileName);

        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceWithNoNamespaces(DataExchDef);
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindFirst();
        CreateDataExchMapping(DataExchLineDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocument, FileName);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Execute
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        // Verify;
        IncomingDocuments.CreateDocument.Invoke();
        AssertExpectedError(IncomingDocuments, Format(CannotCreateErr));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestProcessAskUserPermission()
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocuments: TestPage "Incoming Documents";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        Initialize();

        // Init: Create test data exchange definition
        CreateDataExchDefSalesInvoiceWithNoNamespaces(DataExchDef);
        DataExchangeType.DeleteAll();
        DataExchangeType.Code := LibraryUtility.GenerateGUID();
        DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
        DataExchangeType.Insert();

        // Init: Create incoming document, but don't attach any file
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Insert();
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");

        // Execute - Create Manually - on list
        LibraryVariableStorage.Enqueue(AutomMsg);
        LibraryVariableStorage.Enqueue(false);
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        IncomingDocuments.CreateManually.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Ensure legacy functionality it hidden
        Assert.IsFalse(IncomingDocuments.PurchaseInvoice.Visible(), '');
        Assert.IsFalse(IncomingDocuments.PurchaseCreditMemo.Visible(), '');
        Assert.IsFalse(IncomingDocuments.SalesInvoice.Visible(), '');
        Assert.IsFalse(IncomingDocuments.SalesCreditMemo.Visible(), '');
        Assert.IsFalse(IncomingDocuments.Journal.Visible(), '');

        IncomingDocumentCard.Trap();
        IncomingDocuments.Edit().Invoke();

        // Execute - Create Manually - on card
        LibraryVariableStorage.Enqueue(AutomMsg);
        LibraryVariableStorage.Enqueue(false);
        IncomingDocumentCard.CreateManually.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Ensure legacy functionality is hidden
        Assert.IsFalse(IncomingDocumentCard.PurchaseInvoice.Visible(), '');
        Assert.IsFalse(IncomingDocumentCard.PurchaseCreditMemo.Visible(), '');
        Assert.IsFalse(IncomingDocumentCard.SalesInvoice.Visible(), '');
        Assert.IsFalse(IncomingDocumentCard.SalesCreditMemo.Visible(), '');
        Assert.IsFalse(IncomingDocumentCard.Journal.Visible(), '');

        // Verify - status not changed
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPeppolImportMultipleFails()
    var
        CompanyInformation: Record "Company Information";
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: array[2] of Record "Sales Invoice Header";
        IncomingDocument: array[2] of Record "Incoming Document";
        IncomingDocumentCreateDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocumentTestPage: TestPage "Incoming Document";
        XmlPath: array[2] of Text;
        Index: Integer;
    begin
        Initialize();

        // Setup: configure data exchange setup and create incoming document
        DataExchDef.Get('PEPPOLINVOICE');

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := 'PEPPOL';
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;

        // Setup: export XML
        for Index := 1 to ArrayLen(SalesInvoiceHeader) do begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, CreateSalesDocument(SalesHeader."Document Type"::Invoice, true));
            SalesInvoiceHeader[Index].Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
            XmlPath[Index] := ExportPEPPOLInvoice(SalesInvoiceHeader[Index]);

            LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument[Index]);
            IncomingDocument[Index]."Data Exchange Type" := DataExchangeType.Code;
            IncomingDocument[Index].Modify();

            // Setup: attach XML
            ImportAttachToIncomingDoc(IncomingDocument[Index], XmlPath[Index]);
        end;

        SetupCompanyForInvoiceImport(SalesInvoiceHeader[1]);

        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify(true);

        // Execute: run data exchange
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);
        LibraryVariableStorage.Enqueue(DocNotCreatedMsg);

        IncomingDocumentCreateDocument.SetFilter(
          "Entry No.", '%1|%2', IncomingDocument[1]."Entry No.", IncomingDocument[2]."Entry No.");

        IncomingDocumentCreateDocument.FindSet();
        repeat
            IncomingDocumentCreateDocument.CreateDocumentWithDataExchange();
        until IncomingDocumentCreateDocument.Next() = 0;

        for Index := 1 to ArrayLen(IncomingDocument) do begin
            // Verify - there should be the error about missing G/L Account for non-item lines;
            IncomingDocument[Index].Find();

            IncomingDocumentTestPage.OpenEdit();
            IncomingDocumentTestPage.FILTER.SetFilter("Entry No.", Format(IncomingDocument[Index]."Entry No."));
            Assert.ExpectedMessage(
              'The customer''s VAT registration number', IncomingDocumentTestPage.ErrorMessagesPart.Description.Value);
            IncomingDocumentTestPage.Close();
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure StatusRemainsCreatedIfHasLinkedDocWhenReopenIncomingDoc()
    var
        DataExchDef: Record "Data Exch. Def";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocumentCard: TestPage "Incoming Document";
        XmlPath: Text;
    begin
        // [SCENARIO 487620] When Stan runs Reopen action on an Incoming Document hvaing Status as Created, then Status remains as Created if a document is linked to it.
        Initialize();

        // [GIVEN] Create a Sales Invoice.
        SalesHeader.Get(
            SalesHeader."Document Type"::Invoice,
            CreateSalesDocument(
                SalesHeader."Document Type"::Invoice,
                false));

        // [GIVEN] Post Sales Invoice.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Generate and save XmlPath of Sales Invoice.
        XmlPath := ExportPEPPOLInvoice(SalesInvoiceHeader);

        // [GIVEN] Setup Company Information for Sales Invoice Import.
        SetupCompanyForInvoiceImport(SalesInvoiceHeader);

        // [GIVEN] Find Data Exchange Def.
        DataExchDef.Get(PEPPOLINVOICELbl);

        // [GIVEN] Create Data Exchange Type.
        CreateDataExchangeType(DataExchangeType, DataExchDef);

        // [GIVEN] Create Incoming Document and Validate Data Exchange Type.
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Data Exchange Type" := DataExchangeType.Code;
        IncomingDocument.Modify(true);

        // [GIVEN] Import Incoming Document.
        ImportAttachToIncomingDoc(IncomingDocument, XmlPath);

        // [GIVEN] Open Incoming Document Card page and run Create Document action.
        LibraryVariableStorage.Enqueue(DocCreatedMsg);
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CreateDocument.Invoke();

        // [WHEN] Run Reopen action.
        IncomingDocumentCard.Reopen.Invoke();

        // [VERIFY] Status of Incoming Document remains as Created.
        Assert.AreEqual(
            Format(IncomingDocument.Status::Created),
            IncomingDocumentCard.StatusField.Value,
            StrSubstNo(
                StatusErr,
                IncomingDocumentCard.StatusField.Caption(),
                Format(IncomingDocument.Status::Created),
                IncomingDocument.TableCaption()));
    end;

    local procedure CreateDataExchDefSalesInvoiceAndLinesWithNamespaces(var DataExchDef: Record "Data Exch. Def")
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        CreateDataExchangeDefinition(DataExchDef);
        CreateDataExchangeLineDef(
          SalesHeaderDataExchLineDef,
          DataExchDef, SalesHeaderCodeTxt,
          SalesHeaderDescriptionTxt, '', '/Document/Invoice', NamespaceTxt);
        CreateDataExchangeLineDef(
          SalesLineDataExchLineDef,
          DataExchDef,
          SalesLineCodeTxt,
          SalesLineDescriptionTxt,
          SalesHeaderCodeTxt, '/Document/Invoice/cac:InvoiceLine', NamespaceTxt);
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesHeaderDataExchLineDef, ColumnNo,
          '/Document/Invoice/cbc:ID', 'InvoiceID');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesHeaderDataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID[@schemeID=''0088'']',
          'VendorGLN');
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:InvoiceLine/cbc:InvoicedQuantity', 'Quantity');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:InvoiceLine/cac:Item/cbc:Name', 'ItemName');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:InvoiceLine/cac:Price/cbc:PriceAmount', 'ItemPrice');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:InvoiceLine/cac:Price/cbc:PriceAmount/@currencyID',
          'CurrencyID');
    end;

    local procedure CreateDataExchDefSalesInvoiceAndLinesWithNoNamespaces(var DataExchDef: Record "Data Exch. Def")
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        CreateDataExchangeDefinition(DataExchDef);
        CreateDataExchangeLineDef(
          SalesHeaderDataExchLineDef,
          DataExchDef, SalesHeaderCodeTxt,
          SalesHeaderDescriptionTxt, '', '/Document/Invoice', '');
        CreateDataExchangeLineDef(
          SalesLineDataExchLineDef,
          DataExchDef,
          SalesLineCodeTxt,
          SalesLineDescriptionTxt,
          SalesHeaderCodeTxt, '/Document/Invoice/InvoiceLine',
          NamespaceTxt);
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesHeaderDataExchLineDef, ColumnNo,
          '/Document/Invoice/ID', 'InvoiceID');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesHeaderDataExchLineDef, ColumnNo,
          '/Document/Invoice/AccountingSupplierParty/Party/EndpointID[@schemeID=''0088'']', 'VendorGLN');
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/InvoiceLine/InvoicedQuantity', 'Quantity');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/InvoiceLine/Item/Name', 'ItemName');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/InvoiceLine/Price/PriceAmount', 'ItemPrice');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, SalesLineDataExchLineDef, ColumnNo,
          '/Document/Invoice/InvoiceLine/Price/PriceAmount/@currencyID', 'CurrencyID');
    end;

    local procedure CreateDataExchDefSalesInvoiceWithNamespaces(var DataExchDef: Record "Data Exch. Def")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        CreateDataExchangeDefinition(DataExchDef);
        CreateDataExchangeLineDef(
          DataExchLineDef,
          DataExchDef,
          SalesHeaderCodeTxt, SalesHeaderDescriptionTxt, '', '/Document/Invoice', NamespaceTxt);
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo,
          '/Document/Invoice/cbc:ID', 'InvoiceID');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo,
          '/Document/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID[@schemeID=''0088'']',
          'VendorGLN');
    end;

    local procedure CreateDataExchDefSalesInvoiceWithNoNamespaces(var DataExchDef: Record "Data Exch. Def")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnNo: Integer;
    begin
        CreateDataExchangeDefinition(DataExchDef);
        CreateDataExchangeLineDef(
          DataExchLineDef,
          DataExchDef,
          SalesHeaderCodeTxt, SalesHeaderDescriptionTxt, '', '/Document/Invoice', '');
        ColumnNo := 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo,
          '/Document/Invoice/ID', 'InvoiceID');
        ColumnNo += 1;
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo,
          '/Document/Invoice/AccountingSupplierParty/Party/EndpointID[@schemeID=''0088'']', 'VendorGLN');
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDef.Code);
    end;

    local procedure CreateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def")
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, 0,
          0, CODEUNIT::"Import XML File to Data Exch.", 0, 0, 0);
    end;

    local procedure CreateDataExchangeColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; Path: Text[250]; Name: Text[250])
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.Validate("Column No.", ColumnNo);
        DataExchColumnDef.Validate(Name, Name);
        DataExchColumnDef.Validate(Path, Path);
        DataExchColumnDef.Insert(true);
    end;

    local procedure CreateDataExchangeLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDef: Record "Data Exch. Def"; "Code": Code[20]; Name: Text[100]; ParentCode: Code[20]; DataLineTag: Text[250]; Namespace: Text[250])
    begin
        DataExchLineDef.InsertRec(DataExchDef.Code, Code, Name, 0);
        DataExchLineDef.Validate("Parent Code", ParentCode);
        DataExchLineDef.Validate("Data Line Tag", DataLineTag);
        DataExchLineDef.Validate(Namespace, Namespace);
        DataExchLineDef.Modify();
    end;

    local procedure CreateDataExchangeColumnValuePair(var TempExpectedDataExchField: Record "Data Exch. Field" temporary; DataExch: Record "Data Exch."; ColumnNo: Integer; NodeValue: Text[250]; LineDef: Text[20])
    begin
        TempExpectedDataExchField.Init();
        TempExpectedDataExchField.Validate("Data Exch. No.", DataExch."Entry No.");
        TempExpectedDataExchField.Validate("Line No.", 1);
        TempExpectedDataExchField.Validate("Column No.", ColumnNo);
        TempExpectedDataExchField.Validate(Value, CopyStr(NodeValue, 1, MaxStrLen(TempExpectedDataExchField.Value)));
        TempExpectedDataExchField.Validate("Data Exch. Line Def Code", LineDef);
        TempExpectedDataExchField.Insert();
    end;

    local procedure CreateDataExchMapping(DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.Validate("Table ID", DATABASE::"Intermediate Data Import");
        DataExchMapping.Insert(true);
    end;

    local procedure CreateExpectedOutcomeWithNesting(var TempExpectedDataExchField: Record "Data Exch. Field" temporary; DataExch: Record "Data Exch.")
    begin
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 1, '0001', '', '', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 1, '00010003', '0001', '', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 2, '00010004', '0001', '', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 2, '0002', '', '', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 3, '00020003', '0002', '', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 1, 1, '00010001', '', 'TOSL108', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 1, 1, '000100030001', '0001', '1', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 1, 2, '00010002', '', '5790989675432', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.",
          1, 2, '000100030002', '0001', 'Paper Subscription', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.",
          1, 3, '000100030003', '0001', '800.00', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.",
          1, 4, '000100030004', '0001', 'DKK', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 1, '000100040001', '0001', '1', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 2, '000100040002', '0001', 'Bicycle', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.",
          2, 3, '000100040003', '0001', '2800.00', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.",
          2, 4, '000100040004', '0001', 'DKK', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 1, '00020001', '', 'TOSL109', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 2, '00020002', '', '5790989675432', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 3, 1, '000200030001', '0002', '1', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 3, 2, '000200030002', '0002', 'Computer', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 3, 3, '000200030003', '0002', '8000.00', SalesLineCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 3, 4, '000200030004', '0002', 'DKK', SalesLineCodeTxt);
    end;

    local procedure CreateExpectedOutcomeWithoutNesting(var TempExpectedDataExchField: Record "Data Exch. Field" temporary; DataExch: Record "Data Exch.")
    begin
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 1, '0001', '', '', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldDefinition(DataExch."Entry No.", 2, '0002', '', '', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 1, 1, '00010001', '', 'TOSL108', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 1, 2, '00010002', '', '5790989675432', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 1, '00020001', '', 'TOSL109', SalesHeaderCodeTxt);
        TempExpectedDataExchField.InsertRecXMLFieldWithParentNodeID(
          DataExch."Entry No.", 2, 2, '00020002', '', '5790989675432', SalesHeaderCodeTxt);
    end;

    local procedure CreateExpectedOutcomeForPEPPOLInvoice(var TempExpectedDataExchField: Record "Data Exch. Field" temporary; DataExch: Record "Data Exch."; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CompanyInfo: Record "Company Information";
        SalesInvoiceLine: Record "Sales Invoice Line";
        Cust: Record Customer;
    begin
        // Currency
        if SalesInvoiceHeader."Currency Code" <> '' then
            CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 3,
              SalesInvoiceHeader."Currency Code", PEPPOLSalesHeaderCodeTxt)
        else
            CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 3,
              LibraryERM.GetLCYCode(), PEPPOLSalesHeaderCodeTxt);

        // Supplier GLN (since we created the invoice, that's us)
        CompanyInfo.Get();
        CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 6,
          CompanyInfo.GLN, PEPPOLSalesHeaderCodeTxt);

        // Bill-to GLN (since we created the invoice, that's the customer)
        Cust.Get(SalesInvoiceHeader."Bill-to Customer No.");
        CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 11,
          Cust.GLN, PEPPOLSalesHeaderCodeTxt);

        // Total Price
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 25,
          Format(Round(SalesInvoiceHeader."Amount Including VAT", 0.01, '>'), 0, 9), PEPPOLSalesHeaderCodeTxt);

        // Item No
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        CreateDataExchangeColumnValuePair(TempExpectedDataExchField, DataExch, 12,
          SalesInvoiceLine."No.", PEPPOLSalesLineCodeTxt);
    end;

    local procedure SetupCompanyForInvoiceImport(SalesInvoiceHeader: Record "Sales Invoice Header"): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        CompanyInformation.Get();

        // Add us as a vendor (our company is the buy-from vendor)
        Vendor.SetRange(GLN, CompanyInformation.GLN);
        if not Vendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor.GLN := CompanyInformation.GLN;
            Vendor.Modify();
        end;

        // We are now the sell-to customer
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CompanyInformation.GLN := Customer.GLN;
        CompanyInformation."VAT Registration No." := Customer."VAT Registration No.";
        CompanyInformation.Modify();

        // Get lines
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.FindSet() then
            exit(Vendor."No.");

        repeat
            if SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item then begin
                // create vendor item reference to the same Item No. as it is the same Item
                Item.Get(SalesInvoiceLine."No.");
                LibraryItemReference.CreateItemReference(
                  ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.");
                ItemReference.Validate("Reference No.", Item."No.");
                ItemReference.Insert(true);
            end;
        until SalesInvoiceLine.Next() = 0;
        exit(Vendor."No.")
    end;

    local procedure SetupCompanyForServiceInvoiceImport(ServiceInvoiceHeader: Record "Service Invoice Header"): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        ServiceInvoiceLine: Record "Service Invoice Line";
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        CompanyInformation.Get();

        // Add us as a vendor (our company is the buy-from vendor)
        Vendor.SetRange(GLN, CompanyInformation.GLN);
        if not Vendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor.GLN := CompanyInformation.GLN;
            Vendor.Modify();
        end;

        // We are now the sell-to customer
        Customer.Get(ServiceInvoiceHeader."Customer No.");
        CompanyInformation.GLN := Customer.GLN;
        CompanyInformation."VAT Registration No." := Customer."VAT Registration No.";
        CompanyInformation.Modify();

        // Get lines
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if not ServiceInvoiceLine.FindSet() then
            exit(Vendor."No.");

        repeat
            if ServiceInvoiceLine.Type = ServiceInvoiceLine.Type::Item then begin
                // create vendor item reference to the same Item No. as it is the same Item
                Item.Get(ServiceInvoiceLine."No.");
                LibraryItemReference.CreateItemReference(
                  ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.");
                ItemReference.Validate("Reference No.", Item."No.");
                ItemReference.Insert(true);
            end;
        until ServiceInvoiceLine.Next() = 0;
        exit(Vendor."No.")
    end;

    local procedure SetupCompanyForCreditMemoImport(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        CompanyInformation.Get();

        // Add us as a vendor (our company is the buy-from vendor)
        Vendor.SetRange(GLN, CompanyInformation.GLN);
        if not Vendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor.GLN := CompanyInformation.GLN;
            Vendor.Modify();
        end;

        // We are now the sell-to customer
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        CompanyInformation.GLN := Customer.GLN;
        CompanyInformation."VAT Registration No." := Customer."VAT Registration No.";
        CompanyInformation.Modify();

        // Get lines
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if not SalesCrMemoLine.FindSet() then
            exit(Vendor."No.");

        repeat
            if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then begin
                // create vendor item reference to the same Item No. as it is the same Item
                Item.Get(SalesCrMemoLine."No.");
                LibraryItemReference.CreateItemReference(
                  ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.");
                ItemReference.Validate("Reference No.", Item."No.");
                ItemReference.Insert(true);
            end;
        until SalesCrMemoLine.Next() = 0;

        exit(Vendor."No.")
    end;

    local procedure SetupCompanyForServiceCreditMemoImport(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        CompanyInformation.Get();

        // Add us as a vendor (our company is the buy-from vendor)
        Vendor.SetRange(GLN, CompanyInformation.GLN);
        if not Vendor.FindFirst() then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor.GLN := CompanyInformation.GLN;
            Vendor.Modify();
        end;

        // We are now the sell-to customer
        Customer.Get(ServiceCrMemoHeader."Customer No.");
        CompanyInformation.GLN := Customer.GLN;
        CompanyInformation."VAT Registration No." := Customer."VAT Registration No.";
        CompanyInformation.Modify();

        // Get lines
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if not ServiceCrMemoLine.FindSet() then
            exit(Vendor."No.");

        repeat
            if ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::Item then begin
                // create vendor item reference to the same Item No. as it is the same Item
                Item.Get(ServiceCrMemoLine."No.");
                LibraryItemReference.CreateItemReference(
                  ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, Vendor."No.");
                ItemReference.Validate("Reference No.", Item."No.");
                ItemReference.Insert(true);
            end;
        until ServiceCrMemoLine.Next() = 0;

        exit(Vendor."No.")
    end;

    local procedure CompanyInfoSetup()
    var
        CompanyInfo: Record "Company Information";
        LibraryERM: Codeunit "Library - ERM";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate(GLN, '1234567890128');
        CompanyInfo.Validate(IBAN, 'GB29NWBK60161331926819');
        CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInfo.Validate("Bank Branch No.", '1234');

        if CompanyInfo."VAT Registration No." = '' then
            CompanyInfo."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInfo."Country/Region Code");

        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        CountryRegion: Record "Country/Region";
        Cust: Record Customer;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        CountryCode: Code[10];
    begin
        CountryCode := ConvertStr(LibraryUtility.GenerateRandomText(2), '', '');
        if not CountryRegion.Get(CountryCode) then begin
            CountryRegion.Validate(Code, CountryCode);
            CountryRegion.Insert(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        Cust.Validate(Address, LibraryUtility.GenerateRandomCode(Cust.FieldNo(Address), DATABASE::Customer));
        Cust.Validate("Country/Region Code", CountryRegion.Code);
        Cust.Validate(City, LibraryUtility.GenerateRandomCode(Cust.FieldNo(City), DATABASE::Customer));
        Cust.Validate("Post Code", LibraryUtility.GenerateRandomCode(Cust.FieldNo("Post Code"), DATABASE::Customer));
        Cust."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Cust.Validate(GLN, '1234567891231');
        Cust."Use GLN in Electronic Document" := true;
        Cust.Modify(true);

        exit(Cust."No.");
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    var
        Currency2: Record Currency;
        CurrencyCode: Code[3];
    begin
        LibraryERM.CreateCurrency(Currency);
        repeat
            CurrencyCode := CopyStr(LibraryUtility.GenerateRandomText(3), 1, 3);
        until not Currency2.Get(CurrencyCode);

        Currency.Rename(CurrencyCode);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 2, 1);
    end;

    local procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; InvoiceCurrencyIsLCY: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Cust: Record Customer;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        UnitOfMeasure: Record "Unit of Measure";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInvt: Codeunit "Library - Inventory";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        LineAmount: Decimal;
    begin
        CompanyInfoSetup();
        ConfigureVATPostingSetup();

        Cust.Get(CreateCustomer());

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Cust."No.");
        SalesHeader.Validate("Your Reference", '123457890');
        if not InvoiceCurrencyIsLCY then begin
            CreateCurrency(Currency);
            SalesHeader.Validate("Currency Code", Currency.Code);
        end;
        SalesHeader.Modify(true);

        LibraryInvt.CreateItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 2));

        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(99, 2));
        SalesLine.Modify(true);

        LineAmount := SalesLine."Line Amount";

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        SalesLine.Modify(true);

        SalesHeader.Find();
        if SalesCalcDiscountByType.InvoiceDiscIsAllowed(SalesHeader."Invoice Disc. Code") then
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandDec(Round(LineAmount, 1, '<'), 2) / 2,
              SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        exit(SalesHeader."No.");
    end;

    local procedure CreateServiceInvoiceAndPost(var ServiceInvoiceHeader: Record "Service Invoice Header"; InvoiceCurrencyIsLCY: Boolean)
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer, InvoiceCurrencyIsLCY);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure CreateServiceCreditMemoAndPost(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; InvoiceCurrencyIsLCY: Boolean)
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer, InvoiceCurrencyIsLCY);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; var Customer: Record Customer; InvoiceCurrencyIsLCY: Boolean)
    var
        GLAccount: Record "G/L Account";
        ServiceLine: Record "Service Line";
        Currency: Record Currency;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CompanyInfoSetup();
        ConfigureVATPostingSetup();

        Customer.Get(CreateCustomer());

        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Your Reference", '123457890');
        if ServiceHeader."Due Date" = 0D then
            ServiceHeader.Validate("Due Date", ServiceHeader."Posting Date");
        if not InvoiceCurrencyIsLCY then begin
            CreateCurrency(Currency);
            ServiceHeader.Validate("Currency Code", Currency.Code);
        end;
        ServiceHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        UnitOfMeasure.Get(Item."Base Unit of Measure");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandDec(99, 2));
        ServiceLine.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        ServiceLine.Modify(true);
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure ExportPEPPOLInvoice(VariantRec: Variant) FileName: Text
    var
        ExpSalesInvPEPPOLBIS30: Codeunit "Exp. Sales Inv. PEPPOL BIS3.0";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        ExpSalesInvPEPPOLBIS30.GenerateXMLFile(VariantRec, OutStr);
        FileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure ExportPEPPOLCreditMemo(VariantRec: Variant) FileName: Text
    var
        ExpSalesCrMPEPPOLBIS30: Codeunit "Exp. Sales CrM. PEPPOL BIS3.0";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        ExpSalesCrMPEPPOLBIS30.GenerateXMLFile(VariantRec, OutStr);
        FileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure WriteInvoiceFileWithNestingAndWithNoNamespaces(OutStream: OutStream; Encoding: Text)
    begin
        // Write a document with two invoices, each with some lines under them
        // Only root namespace is in document
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream, '<Document>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <ID>TOSL108</ID>');
        WriteLine(OutStream, '  <AccountingSupplierParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790989675432</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>SubscriptionSeller.</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingSupplierParty>');
        WriteLine(OutStream, '  <AccountingCustomerParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790000435975</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>Buyercompany ltd</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingCustomerParty>');
        WriteLine(OutStream, '  <InvoiceLine>');
        WriteLine(OutStream, '    <ID>1</ID>');
        WriteLine(OutStream, '    <InvoicedQuantity unitCode="EA">1</InvoicedQuantity>');
        WriteLine(OutStream, '    <LineExtensionAmount currencyID="DKK">800.00</LineExtensionAmount>');
        WriteLine(OutStream, '    <Item>');
        WriteLine(OutStream, '      <Description>Paper Subscription fee 1st quarter</Description>');
        WriteLine(OutStream, '      <Name>Paper Subscription</Name>');
        WriteLine(OutStream, '    </Item>');
        WriteLine(OutStream, '    <Price>');
        WriteLine(OutStream, '      <PriceAmount currencyID="DKK">800.00</PriceAmount>');
        WriteLine(OutStream, '    </Price>');
        WriteLine(OutStream, '  </InvoiceLine>');
        WriteLine(OutStream, '  <InvoiceLine>');
        WriteLine(OutStream, '    <ID>2</ID>');
        WriteLine(OutStream, '    <InvoicedQuantity unitCode="EA">1</InvoicedQuantity>');
        WriteLine(OutStream, '    <LineExtensionAmount currencyID="DKK">2800.00</LineExtensionAmount>');
        WriteLine(OutStream, '    <Item>');
        WriteLine(OutStream, '      <Description>Bicycle</Description>');
        WriteLine(OutStream, '      <Name>Bicycle</Name>');
        WriteLine(OutStream, '    </Item>');
        WriteLine(OutStream, '    <Price>');
        WriteLine(OutStream, '      <PriceAmount currencyID="DKK">2800.00</PriceAmount>');
        WriteLine(OutStream, '    </Price>');
        WriteLine(OutStream, '  </InvoiceLine>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <ID>TOSL109</ID>');
        WriteLine(OutStream, '  <AccountingSupplierParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790989675432</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>SubscriptionSeller.</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingSupplierParty>');
        WriteLine(OutStream, '  <AccountingCustomerParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790000435975</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>Buyercompany ltd</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingCustomerParty>');
        WriteLine(OutStream, '  <InvoiceLine>');
        WriteLine(OutStream, '    <ID>3</ID>');
        WriteLine(OutStream, '    <InvoicedQuantity unitCode="EA">1</InvoicedQuantity>');
        WriteLine(OutStream, '    <LineExtensionAmount currencyID="DKK">8000.00</LineExtensionAmount>');
        WriteLine(OutStream, '    <Item>');
        WriteLine(OutStream, '      <Description>Computer</Description>');
        WriteLine(OutStream, '      <Name>Computer</Name>');
        WriteLine(OutStream, '    </Item>');
        WriteLine(OutStream, '    <Price>');
        WriteLine(OutStream, '      <PriceAmount currencyID="DKK">8000.00</PriceAmount>');
        WriteLine(OutStream, '    </Price>');
        WriteLine(OutStream, '  </InvoiceLine>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteInvoiceFileWithNestingAndWithNamespaces(OutStream: OutStream; Encoding: Text; RootNamespace: Text)
    begin
        // Write a document with two invoices, each with some lines under them
        // No namespaces other than root namespace are in the document
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns="' + RootNamespace + '" ' +
          'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
          'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <cbc:ID>TOSL108</cbc:ID>');
        WriteLine(OutStream, '  <cac:AccountingSupplierParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790989675432</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>SubscriptionSeller.</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingSupplierParty>');
        WriteLine(OutStream, '  <cac:AccountingCustomerParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790000435975</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>Buyercompany ltd</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingCustomerParty>');
        WriteLine(OutStream, '  <cac:InvoiceLine>');
        WriteLine(OutStream, '    <cbc:ID>1</cbc:ID>');
        WriteLine(OutStream, '    <cbc:InvoicedQuantity unitCode="EA">1</cbc:InvoicedQuantity>');
        WriteLine(OutStream, '    <cbc:LineExtensionAmount currencyID="DKK">800.00</cbc:LineExtensionAmount>');
        WriteLine(OutStream, '    <cac:Item>');
        WriteLine(OutStream, '      <cbc:Description>Paper Subscription fee 1st quarter</cbc:Description>');
        WriteLine(OutStream, '      <cbc:Name>Paper Subscription</cbc:Name>');
        WriteLine(OutStream, '    </cac:Item>');
        WriteLine(OutStream, '    <cac:Price>');
        WriteLine(OutStream, '      <cbc:PriceAmount currencyID="DKK">800.00</cbc:PriceAmount>');
        WriteLine(OutStream, '    </cac:Price>');
        WriteLine(OutStream, '  </cac:InvoiceLine>');
        WriteLine(OutStream, '  <cac:InvoiceLine>');
        WriteLine(OutStream, '    <cbc:ID>2</cbc:ID>');
        WriteLine(OutStream, '    <cbc:InvoicedQuantity unitCode="EA">1</cbc:InvoicedQuantity>');
        WriteLine(OutStream, '    <cbc:LineExtensionAmount currencyID="DKK">2800.00</cbc:LineExtensionAmount>');
        WriteLine(OutStream, '    <cac:Item>');
        WriteLine(OutStream, '      <cbc:Description>Bicycle</cbc:Description>');
        WriteLine(OutStream, '      <cbc:Name>Bicycle</cbc:Name>');
        WriteLine(OutStream, '    </cac:Item>');
        WriteLine(OutStream, '    <cac:Price>');
        WriteLine(OutStream, '      <cbc:PriceAmount currencyID="DKK">2800.00</cbc:PriceAmount>');
        WriteLine(OutStream, '    </cac:Price>');
        WriteLine(OutStream, '  </cac:InvoiceLine>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <cbc:ID>TOSL109</cbc:ID>');
        WriteLine(OutStream, '  <cac:AccountingSupplierParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790989675432</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>SubscriptionSeller.</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingSupplierParty>');
        WriteLine(OutStream, '  <cac:AccountingCustomerParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790000435975</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>Buyercompany ltd</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingCustomerParty>');
        WriteLine(OutStream, '  <cac:InvoiceLine>');
        WriteLine(OutStream, '    <cbc:ID>3</cbc:ID>');
        WriteLine(OutStream, '    <cbc:InvoicedQuantity unitCode="EA">1</cbc:InvoicedQuantity>');
        WriteLine(OutStream, '    <cbc:LineExtensionAmount currencyID="DKK">8000.00</cbc:LineExtensionAmount>');
        WriteLine(OutStream, '    <cac:Item>');
        WriteLine(OutStream, '      <cbc:Description>Computer</cbc:Description>');
        WriteLine(OutStream, '      <cbc:Name>Computer</cbc:Name>');
        WriteLine(OutStream, '    </cac:Item>');
        WriteLine(OutStream, '    <cac:Price>');
        WriteLine(OutStream, '      <cbc:PriceAmount currencyID="DKK">8000.00</cbc:PriceAmount>');
        WriteLine(OutStream, '    </cac:Price>');
        WriteLine(OutStream, '  </cac:InvoiceLine>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteInvoiceFileWithNoNestingAndWithNoNamespaces(OutStream: OutStream; Encoding: Text)
    begin
        // Write a document with two invoices, each with no lines under them
        // No namespaces other than root namespace are in the document
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream, '<Document>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <ID>TOSL108</ID>');
        WriteLine(OutStream, '  <AccountingSupplierParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790989675432</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>SubscriptionSeller.</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingSupplierParty>');
        WriteLine(OutStream, '  <AccountingCustomerParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790000435975</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>Buyercompany ltd</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingCustomerParty>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <ID>TOSL109</ID>');
        WriteLine(OutStream, '  <AccountingSupplierParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790989675432</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>SubscriptionSeller.</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingSupplierParty>');
        WriteLine(OutStream, '  <AccountingCustomerParty>');
        WriteLine(OutStream, '    <Party>');
        WriteLine(OutStream, '      <EndpointID schemeID="0088">5790000435975</EndpointID>');
        WriteLine(OutStream, '      <PartyName>');
        WriteLine(OutStream, '        <Name>Buyercompany ltd</Name>');
        WriteLine(OutStream, '      </PartyName>');
        WriteLine(OutStream, '    </Party>');
        WriteLine(OutStream, '  </AccountingCustomerParty>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteInvoiceFileWithNoNestingAndWithNamespaces(OutStream: OutStream; Encoding: Text; Namespace: Text)
    begin
        // Write a document with two invoices, each with no lines under them
        // Multiple namespaces are in the document
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns="' + Namespace + '" ' +
          'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
          'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <cbc:ID>TOSL108</cbc:ID>');
        WriteLine(OutStream, '  <cac:AccountingSupplierParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790989675432</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>SubscriptionSeller.</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingSupplierParty>');
        WriteLine(OutStream, '  <cac:AccountingCustomerParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790000435975</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>Buyercompany ltd</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingCustomerParty>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '<Invoice>');
        WriteLine(OutStream, '  <cbc:ID>TOSL109</cbc:ID>');
        WriteLine(OutStream, '  <cac:AccountingSupplierParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790989675432</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>SubscriptionSeller.</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingSupplierParty>');
        WriteLine(OutStream, '  <cac:AccountingCustomerParty>');
        WriteLine(OutStream, '    <cac:Party>');
        WriteLine(OutStream, '      <cbc:EndpointID schemeID="0088">5790000435975</cbc:EndpointID>');
        WriteLine(OutStream, '      <cac:PartyName>');
        WriteLine(OutStream, '        <cbc:Name>Buyercompany ltd</cbc:Name>');
        WriteLine(OutStream, '      </cac:PartyName>');
        WriteLine(OutStream, '    </cac:Party>');
        WriteLine(OutStream, '  </cac:AccountingCustomerParty>');
        WriteLine(OutStream, '</Invoice>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure ImportAttachToIncomingDoc(IncomingDocument: Record "Incoming Document"; FilePath: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FilePath);
        IncomingDocumentAttachment.Validate(Default, true);
        IncomingDocumentAttachment.Modify(true);
    end;

    local procedure AssertInvoiceHeaderValues(IncomingDocument: Record "Incoming Document"; var PurchaseHeader: Record "Purchase Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; InvoiceCurrencyIsLCY: Boolean)
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not PurchaseHeader.FindFirst() then
            Error(CannotFindPurchaseHeaderErr);

        Assert.AreEqual(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type", '');
        if PurchaseHeader."Due Date" <> 0D then
            Assert.AreEqual(SalesInvoiceHeader."Due Date", PurchaseHeader."Due Date", '');
        SalesInvoiceHeader.CalcFields("Invoice Discount Amount", "Amount Including VAT");
        PurchaseHeader.CalcFields("Invoice Discount Amount", "Amount Including VAT");
        if InvoiceCurrencyIsLCY then
            Assert.AreEqual(SalesInvoiceHeader."Amount Including VAT", PurchaseHeader."Amount Including VAT", '')
        else
            Assert.AreNearlyEqual(SalesInvoiceHeader."Amount Including VAT", PurchaseHeader."Amount Including VAT",
              10 * LibraryERM.GetAmountRoundingPrecision(), '');
        Assert.AreEqual(SalesInvoiceHeader."Invoice Discount Amount", PurchaseHeader."Invoice Discount Amount", '');
        Assert.AreEqual(SalesInvoiceHeader."No.", PurchaseHeader."Vendor Invoice No.", '');
    end;

    local procedure AssertInvoiceLineValues(PurchaseHeader: Record "Purchase Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PurchaseLine: Record "Purchase Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            Error(CannotFindPurchaseLineErr);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.FindSet() then
            Error(CannotFindSalesLineErr);

        repeat
            Assert.AreEqual(SalesInvoiceLine.Type, PurchaseLine.Type, '');
            Assert.AreEqual(SalesInvoiceLine.Quantity, PurchaseLine.Quantity, '');
            Assert.AreEqual(SalesInvoiceLine."Unit Price", PurchaseLine."Direct Unit Cost", '');
            Assert.AreEqual(SalesInvoiceLine."Line Discount Amount", PurchaseLine."Line Discount Amount", '');
            Assert.AreEqual(SalesInvoiceLine.Description, PurchaseLine.Description, '');
            Assert.AreEqual(SalesInvoiceLine."Description 2", PurchaseLine."Description 2", '');
        until (PurchaseLine.Next() = 0) or (SalesInvoiceLine.Next() = 0);
    end;

    local procedure AssertServiceInvoiceHeaderValues(IncomingDocument: Record "Incoming Document"; var PurchaseHeader: Record "Purchase Header"; ServiceInvoiceHeader: Record "Service Invoice Header"; InvoiceCurrencyIsLCY: Boolean)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not PurchaseHeader.FindFirst() then
            Error(CannotFindPurchaseHeaderErr);

        Assert.AreEqual(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type", '');
        if PurchaseHeader."Due Date" <> 0D then
            Assert.AreEqual(ServiceInvoiceHeader."Due Date", PurchaseHeader."Due Date", '');
        ServiceInvoiceLine.SetFilter("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums("Amount Including VAT");
        PurchaseHeader.CalcFields("Amount Including VAT");
        if InvoiceCurrencyIsLCY then
            Assert.AreEqual(ServiceInvoiceLine."Amount Including VAT", PurchaseHeader."Amount Including VAT", '')
        else
            Assert.AreNearlyEqual(ServiceInvoiceLine."Amount Including VAT", PurchaseHeader."Amount Including VAT",
              10 * LibraryERM.GetAmountRoundingPrecision(), '');
        Assert.AreEqual(ServiceInvoiceHeader."No.", PurchaseHeader."Vendor Invoice No.", '');
    end;

    local procedure AssertServiceInvoiceLineValues(PurchaseHeader: Record "Purchase Header"; ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        PurchaseLine: Record "Purchase Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            Error(CannotFindPurchaseLineErr);

        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if not ServiceInvoiceLine.FindSet() then
            Error(CannotFindServiceLineErr);

        repeat
            Assert.AreEqual(ServPEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type), PurchaseLine.Type, '');
            Assert.AreEqual(ServiceInvoiceLine.Quantity, PurchaseLine.Quantity, '');
            Assert.AreEqual(ServiceInvoiceLine."Unit Price", PurchaseLine."Direct Unit Cost", '');
            Assert.AreEqual(ServiceInvoiceLine."Line Discount Amount", PurchaseLine."Line Discount Amount", '');
            Assert.AreEqual(ServiceInvoiceLine.Description, PurchaseLine.Description, '');
            Assert.AreEqual(ServiceInvoiceLine."Description 2", PurchaseLine."Description 2", '');
        until (PurchaseLine.Next() = 0) or (ServiceInvoiceLine.Next() = 0);
    end;

    local procedure AssertCrMemoHeaderValues(IncomingDocument: Record "Incoming Document"; var PurchaseHeader: Record "Purchase Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; InvoiceCurrencyIsLCY: Boolean)
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not PurchaseHeader.FindFirst() then
            Error(CannotFindPurchaseHeaderErr);

        Assert.AreEqual(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type", '');
        if PurchaseHeader."Due Date" <> 0D then
            Assert.AreEqual(SalesCrMemoHeader."Due Date", PurchaseHeader."Due Date", '');
        SalesCrMemoHeader.CalcFields("Invoice Discount Amount", "Amount Including VAT");
        PurchaseHeader.CalcFields("Invoice Discount Amount", "Amount Including VAT");
        if InvoiceCurrencyIsLCY then
            Assert.AreEqual(SalesCrMemoHeader."Amount Including VAT", PurchaseHeader."Amount Including VAT", '')
        else
            Assert.AreNearlyEqual(SalesCrMemoHeader."Amount Including VAT", PurchaseHeader."Amount Including VAT",
              10 * LibraryERM.GetAmountRoundingPrecision(), '');
        Assert.AreEqual(SalesCrMemoHeader."Invoice Discount Amount", PurchaseHeader."Invoice Discount Amount", '');
        Assert.AreEqual(SalesCrMemoHeader."No.", PurchaseHeader."Vendor Cr. Memo No.", '');
    end;

    local procedure AssertServiceCrMemoHeaderValues(IncomingDocument: Record "Incoming Document"; var PurchaseHeader: Record "Purchase Header"; ServiceCrMemoHeader: Record "Service Cr.Memo Header"; InvoiceCurrencyIsLCY: Boolean)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not PurchaseHeader.FindFirst() then
            Error(CannotFindPurchaseHeaderErr);

        Assert.AreEqual(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type", '');
        if PurchaseHeader."Due Date" <> 0D then
            Assert.AreEqual(ServiceCrMemoHeader."Due Date", PurchaseHeader."Due Date", '');
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.CalcSums("Amount Including VAT");
        PurchaseHeader.CalcFields("Amount Including VAT");
        if InvoiceCurrencyIsLCY then
            Assert.AreEqual(ServiceCrMemoLine."Amount Including VAT", PurchaseHeader."Amount Including VAT", '')
        else
            Assert.AreNearlyEqual(ServiceCrMemoLine."Amount Including VAT", PurchaseHeader."Amount Including VAT",
              10 * LibraryERM.GetAmountRoundingPrecision(), '');
        Assert.AreEqual(ServiceCrMemoHeader."No.", PurchaseHeader."Vendor Cr. Memo No.", '');
    end;

    local procedure AssertCrMemoLineValues(PurchaseHeader: Record "Purchase Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PurchaseLine: Record "Purchase Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            Error(CannotFindPurchaseLineErr);

        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if not SalesCrMemoLine.FindSet() then
            Error(CannotFindSalesLineErr);

        repeat
            Assert.AreEqual(SalesCrMemoLine.Type, PurchaseLine.Type, '');
            Assert.AreEqual(SalesCrMemoLine.Quantity, PurchaseLine.Quantity, '');
            Assert.AreEqual(SalesCrMemoLine."Unit Price", PurchaseLine."Direct Unit Cost", '');
            Assert.AreEqual(SalesCrMemoLine."Line Discount Amount", PurchaseLine."Line Discount Amount", '');
            Assert.AreEqual(SalesCrMemoLine.Description, PurchaseLine.Description, '');
            Assert.AreEqual(SalesCrMemoLine."Description 2", PurchaseLine."Description 2", '');
        until (PurchaseLine.Next() = 0) or (SalesCrMemoLine.Next() = 0);
    end;

    local procedure AssertServiceCrMemoLineValues(PurchaseHeader: Record "Purchase Header"; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        PurchaseLine: Record "Purchase Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            Error(CannotFindPurchaseLineErr);

        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if not ServiceCrMemoLine.FindSet() then
            Error(CannotFindSalesLineErr);

        repeat
            Assert.AreEqual(ServPEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type), PurchaseLine.Type, '');
            Assert.AreEqual(ServiceCrMemoLine.Quantity, PurchaseLine.Quantity, '');
            Assert.AreEqual(ServiceCrMemoLine."Unit Price", PurchaseLine."Direct Unit Cost", '');
            Assert.AreEqual(ServiceCrMemoLine."Line Discount Amount", PurchaseLine."Line Discount Amount", '');
            Assert.AreEqual(ServiceCrMemoLine.Description, PurchaseLine.Description, '');
            Assert.AreEqual(ServiceCrMemoLine."Description 2", PurchaseLine."Description 2", '');
        until (PurchaseLine.Next() = 0) or (ServiceCrMemoLine.Next() = 0);
    end;

    local procedure AssertExpectedError(var IncomingDocuments: TestPage "Incoming Documents"; ExpectedErrorMessage: Text)
    var
        ErrorMessages: TestPage "Error Messages";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        ErrorMessages.Trap();
        IncomingDocuments.StatusField.DrillDown();
        Assert.IsTrue(ErrorMessages.FindFirstField(Description, Format(ExpectedErrorMessage)), 'Expected error message not found');
        ErrorMessages.Close();
        IncomingDocumentCard.Trap();
        IncomingDocuments.Edit().Invoke();
        Assert.IsTrue(IncomingDocumentCard.ErrorMessagesPart.FindFirstField(Description, ExpectedErrorMessage),
          'Expected error message not found');
        IncomingDocumentCard.Close();
    end;

    local procedure AssertExpectedErrorSubstring(var IncomingDocuments: TestPage "Incoming Documents"; ExpectedErrorMessage: Text)
    var
        ErrorMessages: TestPage "Error Messages";
        ErrorFound: Boolean;
    begin
        ErrorFound := false;
        ErrorMessages.Trap();
        IncomingDocuments.StatusField.DrillDown();
        ErrorMessages.First();
        repeat
            if StrPos(ErrorMessages.Description.Value, Format(ExpectedErrorMessage)) > 0 then
                ErrorFound := true;
        until ErrorMessages.Next() = false;
        Assert.IsTrue(ErrorFound, 'Expected error message not found');
        ErrorMessages.Close();
    end;

    local procedure AssertDataInTable(var ExpectedDataExchField: Record "Data Exch. Field"; var ActualDataExchField: Record "Data Exch. Field"; Msg: Text)
    var
        LineNo: Integer;
    begin
        ExpectedDataExchField.FindFirst();
        ActualDataExchField.FindFirst();
        repeat
            LineNo += 1;
            AreEqualRecords(ExpectedDataExchField, ActualDataExchField, StrSubstNo(TableErrorMsg, Msg, LineNo));
        until (ExpectedDataExchField.Next() = 0) or (ActualDataExchField.Next() = 0);
        Assert.AreEqual(ExpectedDataExchField.Count, ActualDataExchField.Count, 'Row count does not match');
    end;

    local procedure AssertSpecifiedDataInTable(var ExpectedDataExchField: Record "Data Exch. Field"; var ActualDataExchField: Record "Data Exch. Field")
    begin
        ExpectedDataExchField.FindFirst();
        ActualDataExchField.FindFirst();

        repeat
            ActualDataExchField.SetRange("Column No.", ExpectedDataExchField."Column No.");
            ActualDataExchField.SetRange("Data Exch. Line Def Code", ExpectedDataExchField."Data Exch. Line Def Code");
            if not ActualDataExchField.FindFirst() then
                Error(CannotFindColumnErr, ExpectedDataExchField."Column No.", ExpectedDataExchField."Data Exch. Line Def Code");

            Assert.AreEqual(ExpectedDataExchField.Value, ActualDataExchField.Value, 'Expected values do not match');
        until (ExpectedDataExchField.Next() = 0);
    end;

    local procedure AssertDataExchTypeMatchesResponse(IncomingDocument: Record "Incoming Document"; RelatedDocumentType: Enum "Incoming Related Document Type")
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        RecordVar: Variant;
    begin
        LibraryVariableStorage.Enqueue(RelatedDocumentType.AsInteger());
        IncomingDocument.CreateManually();

        if not IncomingDocument.GetRecord(RecordVar) then
            Error(NoDocCreatedForChoiceErr, RelatedDocumentType);

        // Assert - error will occur is casting fails
        case RelatedDocumentType of
            IncomingDocument."Document Type"::"Sales Invoice":
                begin
                    SalesHeader := RecordVar;
                    Assert.AreEqual(SalesHeader."Document Type", SalesHeader."Document Type"::Invoice, '');
                    SalesHeader.Delete();
                end;
            IncomingDocument."Document Type"::"Sales Credit Memo":
                begin
                    SalesHeader := RecordVar;
                    Assert.AreEqual(SalesHeader."Document Type", SalesHeader."Document Type"::"Credit Memo", '');
                    SalesHeader.Delete();
                end;
            IncomingDocument."Document Type"::"Purchase Invoice":
                begin
                    PurchaseHeader := RecordVar;
                    Assert.AreEqual(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Invoice, '');
                    PurchaseHeader.Delete();
                end;
            IncomingDocument."Document Type"::"Purchase Credit Memo":
                begin
                    PurchaseHeader := RecordVar;
                    Assert.AreEqual(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::"Credit Memo", '');
                    PurchaseHeader.Delete();
                end;
            IncomingDocument."Document Type"::Journal:
                begin
                    GenJournalLine := RecordVar;
                    GenJournalLine.Find();
                    GenJournalLine.Delete();
                end;
            else
                Error(UnknownChoiceErr, RelatedDocumentType);
        end;
    end;

    local procedure AreEqualRecords(ExpectedRecord: Variant; ActualRecord: Variant; Msg: Text)
    var
        ExpectedRecRef: RecordRef;
        ActualRecRef: RecordRef;
        i: Integer;
    begin
        ExpectedRecRef.GetTable(ExpectedRecord);
        ActualRecRef.GetTable(ActualRecord);

        Assert.AreEqual(ExpectedRecRef.Number, ActualRecRef.Number, 'Tables are not the same');

        for i := 1 to ExpectedRecRef.FieldCount do
            if IsSupportedType(ExpectedRecRef.FieldIndex(i).Value) then
                Assert.AreEqual(ExpectedRecRef.FieldIndex(i).Value, ActualRecRef.FieldIndex(i).Value,
                  StrSubstNo(AssertMsg, Msg, ExpectedRecRef.FieldIndex(i).Name));
    end;

    local procedure IsSupportedType(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsTime);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        ActualReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        LibraryVariableStorage.Dequeue(ActualReply);
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := ActualReply;
    end;

    local procedure Initialize()
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        GLAccount: Record "G/L Account";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Incoming Doc. To Data Exch.UT");

        IntermediateDataImport.DeleteAll();
        TextToAccountMapping.DeleteAll();

        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibraryVariableStorage.Clear();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PurchasesPayablesSetup.Get();
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        PurchasesPayablesSetup.Validate("Debit Acc. for Non-Item Lines", GLAccount."No.");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        PurchasesPayablesSetup.Validate("Credit Acc. for Non-Item Lines", GLAccount."No.");
        PurchasesPayablesSetup.Modify(true);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        if IncomingDocumentsSetup.Get() then
            IncomingDocumentsSetup.Delete();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        IncomingDocumentsSetup.Init();
        IncomingDocumentsSetup.Validate("General Journal Template Name", GenJournalTemplate.Name);
        IncomingDocumentsSetup.Validate("General Journal Batch Name", GenJournalBatch.Name);
        IncomingDocumentsSetup.Validate("Require Approval To Create", false);
        IncomingDocumentsSetup.Insert();
    end;

    local procedure CreateDataExchangeType(var DataExchangeType: Record "Data Exchange Type"; DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.SetLoadFields(Code);

        DataExchangeType.SetLoadFields(Code, "Data Exch. Def. Code");
        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchDef.Code);
        if not DataExchangeType.FindFirst() then begin
            DataExchangeType.Code := PEPPOLLbl;
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert();
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        Assert.IsTrue(StrPos(Msg, Message) > 0, Msg);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text; var Choice: Integer; Instructions: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
        Choice += 1;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageHandler43(var "Page": TestPage "Sales Invoice")
    begin
        Page.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageHandler44(var "Page": TestPage "Sales Credit Memo")
    begin
        Page.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageHandler51(var "Page": TestPage "Purchase Invoice")
    begin
        Page.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageHandler52(var "Page": TestPage "Purchase Credit Memo")
    begin
        Page.Close();
    end;
}

