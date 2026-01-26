codeunit 144200 "FatturaPA Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export]
    end;

    var
        ErrorMessage: Record "Error Message";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        DocumentType: Enum "Gen. Journal Document Type";
        DocNo: Code[20];
        PostingDate: Date;
        ExportFromType: Option Sales,Service;
        PaymentMethodCodeFieldNo: Integer;
        PaymentTermsCodeFieldNo: Integer;
        PostingDateFieldNo: Integer;
        InvoiceDiscountAmountFieldNo: Integer;
        QuantityFieldNo: Integer;
        DocNoFieldNo: Integer;
        VatPercFieldNo: Integer;
        VATBaseAmountFieldNo: Integer;
        LineNoFieldNo: Integer;
        DescriptionFieldNo: Integer;
        UnitOfMeasureFieldNo: Integer;
        UnitPriceFieldNo: Integer;
        LineDiscountAmountFieldNo: Integer;
        LineDiscountPercFieldNo: Integer;
        LineInvDiscAmountFieldNo: Integer;
        AmountFieldNo: Integer;
        LineAmountIncludingVATFieldNo: Integer;
        VATProdPostingGroupCodeFieldNo: Integer;
        VATBusPostingGroupCodeFieldNo: Integer;
        PricesIncludingVATFieldNo: Integer;
        ServiceInvoiceDiscountAmount: Decimal;
        FatturaProjectCodeFieldNo: Integer;
        FatturaTenderCodeFieldNo: Integer;
        CustomerNoFieldNo: Integer;
        UnexpectedElementNameErr: Label 'Unexpected element name. Expected element name: %1. Actual element name: %2.', Comment = '%1=Expetced XML Element Name;%2=Actual XML Element Name;';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        FileNameIncrementErr: Label 'File name is incorrect. It should be incremented by one for the next export.';
        SignatureXSDRelativePathTxt: Label '\GDL\IT\App\Test\XMLSchemas\xmldsig-core-schema.xsd', Locked = true;
        XSDRelativePathTxt: Label '\GDL\IT\App\Test\XMLSchemas\FatturaPA_1_2.xsd', Locked = true;
        InetRootRelativePathTxt: Label '..\', Locked = true;
        DescriptionTxt: Label 'Description Text';

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 270181] Export Sales Invoice with item GTIN
        // [SCENARIO 259342] Export Sales Invoice with customer "PA Code" = "1234567" (private company)
        Initialize();

        // [GIVEN] A posted Sales Invoice (Customer with "PA Code" = "123456") with no currency
        CustomerNo := CreateCustomer();
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [GIVEN] "LCY Code" is "EUR" in "General Ledger Setup"

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported with 'CodiceArticolo' node
        // [THEN] "FormatoTrasmissione" = "FPA12"
        // [THEN] "CodiceDestinatario" = "123456"
        // [THEN] "Divisa" = "EUR" (BUG 308849)
        // TFS ID: 365067
        // [THEN] IdPaese and IdCodice specified for regular customer (non-individual person)
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(ClientFileName));
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceBlankItemGTIN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 270181] Export Sales Invoice with blank item GTIN
        Initialize();

        // [GIVEN] A posted Sales Invoice with blank item GTIN
        CustomerNo := CreateCustomer();
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        UpdateItemGTIN(SalesInvoiceLine."No.", '');

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported without 'CodiceArticolo' node
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(ClientFileName));
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeader(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', false, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesCreditMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] A posted Sales Credit Memo and a certificate
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostSalesCrMemo(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(ClientFileName));
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(
          TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::"Credit Memo", ExportFromType::Sales, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice]
        Initialize();

        // [GIVEN] A posted Service Invoice
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostServiceInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        ServiceInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(ClientFileName));
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::Invoice, ExportFromType::Service, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceCreditMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo]
        Initialize();

        // [GIVEN] A posted Service Credit Memo
        CustomerNo := CreateCustomer();
        DocumentNo := CreateAndPostServiceCrMemo(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(),
            CustomerNo);
        ServiceCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(ClientFileName));
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::"Credit Memo", ExportFromType::Service, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceBatch()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef1: RecordRef;
        DocumentRecRef2: RecordRef;
        ClientFileName: Text[250];
        DocumentNo1: Code[20];
        CustomerNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Batch]
        Initialize();
        // [GIVEN] Two posted Sales Invoices
        CustomerNo := CreateCustomer();
        DocumentNo1 :=
          CreateAndPostSalesInvoice(DocumentRecRef1, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);

        DocumentNo2 :=
          CreateAndPostSalesInvoice(DocumentRecRef2, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesInvoiceHeader.SetFilter("No.", '%1|%2', DocumentNo1, DocumentNo2);

        // [WHEN] The documents are exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] A zip file is exported
        // [THEN] The zip file contains two FatturaPA XML files
        // [THEN] The two FatturaPA files contains values according to the documents
        VerifyZipArchive(DocumentRecRef1, DocumentRecRef2, TempBlob, ExportFromType::Sales, CustLedgerEntry."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceInvoiceBatch()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef1: RecordRef;
        DocumentRecRef2: RecordRef;
        ClientFileName: Text[250];
        DocumentNo1: Code[20];
        CustomerNo1: Code[20];
        DocumentNo2: Code[20];
        CustomerNo2: Code[20];
    begin
        // [FEATURE] [Service] [Invoice] [Batch]
        Initialize();

        // [GIVEN] Two posted Service Invoices
        CustomerNo1 := CreateCustomer();
        DocumentNo1 :=
          CreateAndPostServiceInvoice(DocumentRecRef1, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo1);

        CustomerNo2 := CreateCustomer();
        DocumentNo2 :=
          CreateAndPostServiceInvoice(DocumentRecRef2, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo2);
        ServiceInvoiceHeader.SetFilter("No.", '%1|%2', DocumentNo1, DocumentNo2);

        // [WHEN] The documents are exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] A zip file is exported
        // [THEN] The zip file contains two FatturaPA XML files
        // [THEN] The two FatturaPA files contains values according to the documents
        VerifyZipArchive(DocumentRecRef1, DocumentRecRef2, TempBlob, ExportFromType::Service, CustLedgerEntry."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesCrMemoBatch()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef1: RecordRef;
        DocumentRecRef2: RecordRef;
        ClientFileName: Text[250];
        DocumentNo1: Code[20];
        CustomerNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Batch]
        Initialize();
        // [GIVEN] Two posted Sales Credit Memos
        CustomerNo := CreateCustomer();
        DocumentNo1 :=
          CreateAndPostSalesCrMemo(DocumentRecRef1, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);

        DocumentNo2 :=
          CreateAndPostSalesCrMemo(DocumentRecRef2, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesCrMemoHeader.SetFilter("No.", '%1|%2', DocumentNo1, DocumentNo2);

        // [WHEN] The documents are exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] A zip file is exported
        // [THEN] The zip file contains two FatturaPA XML files
        // [THEN] The two FatturaPA files contains values according to the documents
        VerifyZipArchive(DocumentRecRef1, DocumentRecRef2, TempBlob, ExportFromType::Sales, CustLedgerEntry."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceCrMemoBatch()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef1: RecordRef;
        DocumentRecRef2: RecordRef;
        ClientFileName: Text[250];
        DocumentNo1: Code[20];
        CustomerNo1: Code[20];
        DocumentNo2: Code[20];
        CustomerNo2: Code[20];
    begin
        // [FEATURE] [Service] [Credit Memo] [Batch]
        Initialize();

        // [GIVEN] Two posted Service Credit Memos
        CustomerNo1 := CreateCustomer();
        DocumentNo1 :=
          CreateAndPostServiceCrMemo(DocumentRecRef1, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo1);

        CustomerNo2 := CreateCustomer();
        DocumentNo2 :=
          CreateAndPostServiceCrMemo(DocumentRecRef2, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo2);
        ServiceCrMemoHeader.SetFilter("No.", '%1|%2', DocumentNo1, DocumentNo2);

        // [WHEN] The documents are exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] A zip file is exported
        // [THEN] The zip file contains two FatturaPA XML files
        // [THEN] The two FatturaPA files contains values according to the documents
        VerifyZipArchive(DocumentRecRef1, DocumentRecRef2, TempBlob, ExportFromType::Service, CustLedgerEntry."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithSplitPayment()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 286713] Export Sales Invoice with split payment

        Initialize();

        // [GIVEN] A posted Sales Invoice with Amount = 100 and split payment line with amount = -100
        // [GIVEN VAT Amount  = 18, split payment line VAT Amount = -18
        CreateInvoiceWithSplitPayment(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        DocumentNo := GetDocumentNo(DocumentRecRef);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file has values according to the invoice
        // [THEN] The value of field 2.2.2.7 "EsigibilitaIVA" is "S"
        // [THEN] The value of ImportoTotaleDocumento node is 100
        // BUG 316477: Split payment line does not consider for Imposta XML node calculation
        // [THEN] "Imposta" node has value 18
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, SalesInvoiceHeader."Sell-to Customer No.");
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithUnrealizedVAT()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Unrealized VAT]
        // [SCENARIO 281319] The XML file contains tag <Natura> when VAT Rate = 0
        // [SCENARIO 319833] The XML file does not containt EsigibilitaIVA node when VAT Rate = 0
        // [GIVEN] A posted Sales Invoice with unrealized VAT, "VAT %" = 0
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        DocumentNo := CreateInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        DocumentNo := GetDocumentNo(DocumentRecRef);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The exported XML file is valid according to XSD Schema
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file has values according to the invoice
        // [THEN] The value of field 2.2.2.7 "EsigibilitaIVA" is "D"
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, SalesInvoiceHeader."Sell-to Customer No.");
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, VATPostingSetup."VAT Transaction Nature");
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndSendSalesInvoiceWithMissingFields()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // [FEATURE] [Sales] [Invoice] [Post And Send] [UI]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        // TFS 388373: Fiscal code of length 16 is allowed
        // TFS 393032: VAT Registration no. is optional
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [WHEN] A sales invoice for the given customer has been PostAndSend
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', 5, '', 0D);
        LibraryErrorMessage.TrapErrorMessages();
        PostAndSendSalesInvoice(SalesHeader);

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertSalesHeaderErrorMessages(SalesHeader);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndSendSalesCreditMemoWithMissingFields()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Post And Send] [UI]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        // TFS 388373: Fiscal code of length 16 is allowed
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [WHEN] A sales Credit Memo for the given customer has been PostAndSend
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", Customer."No.", '', 5, '', 0D);
        LibraryErrorMessage.TrapErrorMessages();
        PostAndSendSalesCreditMemo(SalesHeader);

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertSalesHeaderErrorMessages(SalesHeader);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndSendServiceInvoiceWithMissingFields()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // [FEATURE] [Sales] [Invoice] [Post And Send] [UI]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        // TFS 388373: Fiscal code of length 16 is allowed
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [WHEN] A service invoice for the given customer has been PostAndSend
        CreateServiceHeaderWithoutPaymentInformation(ServiceHeader, Customer."No.", ServiceHeader."Document Type"::Invoice);
        LibraryErrorMessage.TrapErrorMessages();
        PostAndSendServiceInvoice(ServiceHeader);

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertServiceHeaderErrorMessages(ServiceHeader);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);
    end;

    [Test]
    [HandlerFunctions('PostAndSendHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndSendServiceCreditMemoWithMissingFields()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        // [FEATURE] [Service] [Credit Memo] [Post And Send] [UI]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        // TFS 388373: Fiscal code of length 16 is allowed
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [WHEN] A service Credit Memo for the given customer has been PostAndSend
        CreateServiceHeaderWithoutPaymentInformation(ServiceHeader, Customer."No.", ServiceHeader."Document Type"::"Credit Memo");
        LibraryErrorMessage.TrapErrorMessages();
        PostAndSendServiceCreditMemo(ServiceHeader);

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertServiceHeaderErrorMessages(ServiceHeader);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPostedSalesInvoiceWithMissingFields()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] Field Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [GIVEN] A posted Sales Invoice for the given customer
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, '', '', Customer."No.");
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        LibraryErrorMessage.TrapErrorMessages();
        asserterror ElectronicDocumentFormat.SendElectronically(TempBlob,
            ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertPostedDocumentHeaderErrorMessages(DocumentRecRef);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPostedSalesCreditMemoWithMissingFields()
    var
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] A posted Sales Credit Memo for the given customer
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        DocumentNo := CreateAndPostSalesCrMemo(
            DocumentRecRef, PaymentMethod.Code, PaymentTerms.Code, Customer."No.");
        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        LibraryErrorMessage.TrapErrorMessages();
        asserterror ElectronicDocumentFormat.SendElectronically(TempBlob,
            ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);

        LibraryErrorMessage.AssertLogIfMessageExists(PaymentTerms,
          PaymentTerms.FieldNo("Fattura Payment Terms Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(PaymentMethod,
          PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPostedServiceInvoiceWithMissingFields()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        TransmissionIntermediaryVendor: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] Field Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] Fattura PA Electronic format has been defined
        LibraryITLocalization.InsertFatturaElectronicFormats(FatturaPA_ElectronicFormatTxt);

        // [GIVEN] A posted Service Invoice for the given customer
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        DocumentNo := CreateAndPostServiceInvoice(DocumentRecRef, PaymentMethod.Code, PaymentTerms.Code, Customer."No.");
        ServiceInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        LibraryErrorMessage.TrapErrorMessages();
        asserterror ElectronicDocumentFormat.SendElectronically(TempBlob,
            ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);

        LibraryErrorMessage.AssertLogIfMessageExists(PaymentTerms,
          PaymentTerms.FieldNo("Fattura Payment Terms Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(PaymentMethod,
          PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPostedServiceCreditMemoWithMissingFields()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo]
        Initialize();

        // [GIVEN] A new customer with no payment method, payment terms nor name
        // [GIVEN] Company information is cleared
        // [GIVEN] No Fattura PA Nos is clear in Sales & Receivables Setup
        // [GIVEN] A clean Tax Representative and transmission intermediary
        CreateCleanCustomer(Customer);
        ClearCompanyInformation();
        ClearFatturaPANoSeries();
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CreateCleanTransmissionIntermediary(TransmissionIntermediaryVendor);

        // [GIVEN] A posted Service Credit Memo for the given customer
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        DocumentNo := CreateAndPostServiceCrMemo(
            DocumentRecRef, PaymentMethod.Code, PaymentTerms.Code, Customer."No.");
        ServiceCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        LibraryErrorMessage.TrapErrorMessages();
        asserterror ElectronicDocumentFormat.SendElectronically(TempBlob,
            ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Errors are logged for all mandatory fields
        LibraryErrorMessage.LoadErrorMessages();
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        AssertCompanyErrorMessages();
        AssertCustomerErrorMessages(Customer);
        AssertTaxRepresentativeErrorMessages(TaxRepresentativeVendor);
        AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor);

        LibraryErrorMessage.AssertLogIfMessageExists(PaymentTerms,
          PaymentTerms.FieldNo("Fattura Payment Terms Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(PaymentMethod,
          PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAFileNameIncrementsByOne()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileNameFirstSend: Text[250];
        ClientFileNameSecondSend: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 269125] File Name increments by one when next FatturaPA is exported.
        Initialize();

        // [GIVEN] A posted Sales Invoice.
        CustomerNo := CreateCustomer();
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [GIVEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileNameFirstSend, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [WHEN] The document is exported second time to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileNameSecondSend, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The name of the second file is equal to the name of the first file incremented by one.
        Assert.AreEqual(IncStr(ClientFileNameFirstSend), ClientFileNameSecondSend, FileNameIncrementErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithMultipleShipmentsDatiOrdineAcquisto()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 269121] DatiGenerali has two DatiOrdineAcquisto with RiferimentoNumeroLinea and IdDocumento each when Sales Invoice is posted for two different Shipments.
        // TFS 284906: IDDocumento reported with Customer Purchase Order No. of Sales Invoice
        Initialize();
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and post two Sales Orders "SO1" and "SO2" as Shipments.
        // [GIVEN] "SO1" has one Sales Line, "SO2" has two Sales Lines.
        CreateAndPostSalesOrderAsShipment(CustomerNo, 1);
        CreateAndPostSalesOrderAsShipment(CustomerNo, 2);

        // [GIVEN] Create and post Sales Invoice for posted Shipments with "Customer Purchase Order No." = "X"
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The DatiGenerali node has two DatiOrdineAcquisto nodes.
        // [THEN] First DatiOrdineAcquisto node has RiferimentoNumeroLinea = 2 and IdDocumento = "X".
        // [THEN] Second DatiOrdineAcquisto node has RiferimentoNumeroLinea = 4, RiferimentoNumeroLinea = 5 and IdDocumento = "SO2" number.
        SalesInvoiceHeader.Get(PostedInvNo);
        VerifyDatiOrdineAcquistoForMultipleShipments(TempBlob, SalesInvoiceHeader."Customer Purchase Order No.");

        // [THEN] No RiferimentoTesto node exports
        // TFS 313364: If you get more than one posted shipments in a Sale Invoice, the E-Invoice xml file is not accepted due to the the shipment description reported
        VerifyNoRiferimentoTestoNodes(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithMultipleShipmentLinesDatiOrdineAcquisto()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 269121] DatiGenerali has one DatiOrdineAcquisto with two RiferimentoNumeroLinea and one IdDocumento when Sales Invoice is posted for Shipment with two lines.
        // TFS 284906: IDDocumento reported with Customer Purchase Order No. of Sales Invoice

        Initialize();
        CustomerNo := CreateCustomer();

        // [GIVEN] Create and post Sales Order "SO" with two lines as Shipments.
        CreateAndPostSalesOrderAsShipment(CustomerNo, 2);

        // [GIVEN] Create and post Sales Invoice for posted Shipments with "Customer Purchase Order No." = "X"
        PostedInvNo := CreateSalesInvFromShipment(CustomerNo);

        // [WHEN] The document is exported to FatturaPA.
        SalesInvoiceHeader.SetRange("No.", PostedInvNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The DatiGenerali node has one DatiOrdineAcquisto node.
        // [THEN] DatiOrdineAcquisto node IdDocumento = "X" and no RiferimentoNumeroLinea nodes.
        SalesInvoiceHeader.Get(PostedInvNo);
        VerifyDatiOrdineAcquistoForShipmentWithMultipleLines(TempBlob, SalesInvoiceHeader."Customer Purchase Order No.");

        // [THEN] No RiferimentoTesto node exports
        // TFS 313364: If you get more than one posted shipments in a Sale Invoice, the E-Invoice xml file is not accepted due to the the shipment description reported
        VerifyNoRiferimentoTestoNodes(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithLineDisc()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice] [Line Discount]
        // [SCENARIO 273569] Importo node has value of Unit Price Discount Amount when send Sales Invoice

        Initialize();

        // [GIVEN] A posted Sales Invoice with "Unit Price" = 150 and "Line Discount %" = 30
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostSalesInvWithLineDisc(
            DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported with 'Importo' node with value 50 ("Unit Price" * "Line Discount %" / 100)
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeader(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceInvoiceWithLineDisc()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice] [Line Discount]
        // [SCENARIO 273569] Importo node has value of Unit Price Discount Amount when send Service Invoice

        Initialize();

        // [GIVEN] A posted Service Invoice with "Unit Price" = 150 and "Line Discount %" = 30
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostServiceInvoiceWithLineDisc(
            DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        ServiceInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported with 'Importo' node with value 50 ("Unit Price" * "Line Discount %" / 100)
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeader(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::Invoice, ExportFromType::Service, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesCrMemoWithLineDisc()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Discount]
        // [SCENARIO 273569] Importo node has value of Unit Price Discount Amount when send Sales Invoice

        Initialize();

        // [GIVEN] A posted Sales Credit Memo with "Unit Price" = 150 and "Line Discount %" = 30
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostSalesCrMemoWithLineDisc(
            DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported with 'Importo' node with value 50 ("Unit Price" * "Line Discount %" / 100)
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeader(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(
          TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::"Credit Memo", ExportFromType::Sales, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServiceCrMemoWithLineDisc()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo] [Line Discount]
        // [SCENARIO 273569] Importo node has value of Unit Price Discount Amount when send Service Invoice

        Initialize();

        // [GIVEN] A posted Service Invoice with "Unit Price" = 150 and "Line Discount %" = 30
        CustomerNo := CreateCustomer();
        DocumentNo :=
          CreateAndPostServiceCrMemoWithLineDisc(
            DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        ServiceCrMemoHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] Line data exported with 'Importo' node with value 50 ("Unit Price" * "Line Discount %" / 100)
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        VerifyFatturaPAFileHeader(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef,
          CustLedgerEntry."Document Type"::"Credit Memo", ExportFromType::Service, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPACodeFieldPublicOrPrivateCompany()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 259342] Customer.IsPublicCompany() returns TRUE only in case of 6-chars length of "PA Code" field value
        Customer.Init();

        // Customer."PA Code" max field length = 7
        Assert.AreEqual(7, MaxStrLen(Customer."PA Code"), '');

        // Customer.IsPublicCompany() returns FALSE in case of "PA Code" = ""
        Assert.IsFalse(Customer.IsPublicCompany(), '');

        // Customer.IsPublicCompany() returns FALSE in case of "PA Code" = "0000000"
        Customer."PA Code" := '0000000';
        Assert.IsFalse(Customer.IsPublicCompany(), '');

        // Customer.IsPublicCompany() returns FALSE in case of "PA Code" = "1234567"
        Customer."PA Code" := '1234567';
        Assert.IsFalse(Customer.IsPublicCompany(), '');

        // Customer.IsPublicCompany() returns TRUE in case of "PA Code" = "123456"
        Customer."PA Code" := '123456';
        Assert.IsTrue(Customer.IsPublicCompany(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoicePrivateCompany()
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 259342] Export Sales Invoice with customer "PA Code" = "1234567" (private company)
        Initialize();

        // [GIVEN] A posted Sales Invoice (Customer with "PA Code" = "1234567")
        CustomerNo := CreatePrivateCompanyCustomer();
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        DummySalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, DummySalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] "FormatoTrasmissione" = "FPR12"
        // [THEN] "CodiceDestinatario" = "1234567"
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPrivateCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoicePrivateCompanyWithZeroPACode()
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 287428] A value of "PEC E-mail Address" of Customer used when export Sales Invoice with customer "PA Code" = "0000000" (private company)
        Initialize();

        // [GIVEN] A posted Sales Invoice (Customer with "PA Code" = "0000000", "PEC E-Mail Address" = "private@customer.com")
        CustomerNo := LibraryITLocalization.CreateFatturaCustomerNo(PadStr('', 7, '0'));
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo);
        DummySalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, DummySalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] "FormatoTrasmissione" = "FPR12"
        // [THEN] "PECDestinatario" = "private@customer.com"
        // [THEN] "CodiceDestinatario" = "0000000"
        TempBlob.CreateInStream(InStr);
        TempXMLBuffer.LoadFromStream(InStr);
        VerifyFatturaPAFileHeaderPrivateCompany(TempXMLBuffer, DocumentRecRef, CustomerNo);
        VerifyCustomerEmail(TempXMLBuffer, CustomerNo);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
        VerifyXSDSchemaForStream(InStr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithNegativeLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPart: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        UnitPrice: Decimal;
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 284454] Exporting a document with negative quantity doesn't produce an invalid negative quantity element
        Initialize();

        // [GIVEN] A posted Sales Invoice with 2 lines, one with positive Quantity, second with negative Quantity, both have Unit Price = X
        CreateAndPostSalesInvoiceWithNegativeLine(UnitPrice, Quantity, DocumentNo, CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer());
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] A Fattura PA document is created for this Sales Invoice
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        // [THEN] There is only one "Quantita" element
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, 'Quantita');
        Assert.RecordCount(TempXMLBufferPart, 1);
        // [THEN] This element corresponds to Quantity on first line
        TempXMLBufferPart.FindFirst();
        TempXMLBufferPart.TestField(Value, FormatAmount(Quantity));

        // [THEN] There are two "PrezzoUnitario" elements, corresponding to both lines.
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, 'PrezzoUnitario');
        Assert.RecordCount(TempXMLBufferPart, 2);
        // [THEN] The second element corresponds to 'negative' line and must have value of -X.
        TempXMLBufferPart.FindLast();
        TempXMLBufferPart.TestField(Value, FormatAmount(-UnitPrice));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceForLocalCustomer()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPart: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        ClientFileName: Text[250];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 334296] Exporting a document with local customer, populates 'CAP' element with its Post Code
        Initialize();

        // [GIVEN] Posted Sales Invoice for a local customer
        CustomerNo := CreateCustomer();
        SalesInvoiceHeader.SetRange("No.", CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo));

        // [WHEN] A Fattura PA document is created for this Sales Invoice
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        // [THEN] 'CAP' element is populated with local Customer's Post Code
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, 'CessionarioCommittente/Sede/CAP');
        TempXMLBufferPart.FindFirst();
        TempXMLBufferPart.TestField(Value, GetCustomerPostCode(CustomerNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceForForeignCustomer()
    var
        CountryRegion: Record "Country/Region";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPart: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        ClientFileName: Text[250];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 334296] Exporting a document with foreign customer, populates 'CAP' element with '00000'
        Initialize();

        // [GIVEN] Posted Sales Invoice for a foreign customer
        LibraryERM.CreateCountryRegion(CountryRegion);
        CustomerNo := CreateForeignCustomer(CountryRegion.Code);
        SalesInvoiceHeader.SetRange("No.", CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo));

        // [WHEN] A Fattura PA document is created for this Sales Invoice
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        // [THEN] 'CAP' element is populated with '00000' for a foreign Customer
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, 'CessionarioCommittente/Sede/CAP');
        TempXMLBufferPart.FindFirst();
        TempXMLBufferPart.TestField(Value, '00000');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrezzoUnitarioExportsUnitPriceWithoutRounding()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 364606] The XML file contains the PrezzoUnitario xml node with unit price without rounding

        Initialize();

        // [GIVEN] Sales invoice with unit price = 0.073
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod());
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(50));
        SalesLine.Validate("Unit Price", 0.073);
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Generate XML file
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file has the PrezzoUnitario xml node with value of 0.073
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoUnitario',
          Format(SalesLine."Unit Price", 0, '<Precision,2:5><Standard Format,9>'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithNoVATRegistrationNoButFiscalCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 393032] Stan can export sales invoice with customer that only has fiscal code but no VAT registratio no.

        Initialize();

        // [GIVEN] A posted Sales Invoice with customer that has "VAT Registration No." = blank, "Fiscal Code" = "Y"
        Customer.Get(CreateCustomer());
        Customer."VAT Registration No." := '';
        Customer.Modify(true);
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), Customer."No.");
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Exported file does not have IdFiscaleIVA xml block related to VAT registration no.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertElementDoesNotExist(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/IdFiscaleIVA');
        // [THEN] Exported file has CodiceFiscale = "Y"
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/CodiceFiscale',
          Customer."Fiscal Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithForeignCustomer()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Customer: Record Customer;
        CurrCustomer: Record Customer;
        CountryRegion: Record "Country/Region";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 391793] CodiceFiscale xml node does not exist in the exported file for the sales invoice with foreign customer

        Initialize();

        // [GIVEN]  "Country/Region Code" code is "IT" in Company Information
        // [GIVEN] A posted Sales Invoice with customer that has "Country/Region Code" = "GB" and "Fiscal Code" = "Y"
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Get(CreateCustomer());
        CurrCustomer := Customer;
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        // Values get blanked after the Country/Region code validation, returning them back
        Customer.Validate("Post Code", CurrCustomer."Post Code");
        Customer.Validate(City, CurrCustomer.City);
        Customer.Validate(County, CurrCustomer.County);
        Customer.Modify(true);
        DocumentNo := CreateAndPostSalesInvoice(DocumentRecRef, CreatePaymentMethod(), CreatePaymentTerms(), Customer."No.");
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Exported file does not have CodiceFiscale
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertElementDoesNotExist(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/CodiceFiscale');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithZeroUnitPrice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 270181] PrezzoUnitario xml node generates for the sales line with zero unit price

        Initialize();

        // [GIVEN] A posted Sales Invoice with two lines, first line has unit price, the second one does not
        SalesInvoiceHeader.SetRange(
          "No.", CreateAndPostSalesInvoiceWithSecondLineZeroUnitPrice(CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer()));

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file has two PrezzoUnitario xml nodes. The second one has value of "0.00"
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoUnitario');
        Assert.RecordCount(TempXMLBuffer, 2);
        FindNextElement(TempXMLBuffer);
        Amount := 0;
        TempXMLBuffer.TestField(Value, Format(Amount, 0, '<Precision,2:5><Standard Format,9>'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithExtendedText()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [SCENARIO 429214] Export sales invoice with extended text
        Initialize();

        // [GIVEN] A posted Sales Invoice with 3 lines and 3 extended texts, one per each line
        SalesInvoiceHeader.SetRange(
          "No.", CreateAndPostSalesInvoiceWithExtText(CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer()));

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file has 3 RiferimentoTesto xml nodes.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/AltriDatiGestionali/RiferimentoTesto');
        Assert.RecordCount(TempXMLBuffer, 3);
    end;

    [Test]
    procedure UnitaMisuraWhenUoMHasLongValue()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        OldUinitOfMeasureDescription: Text[50];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 444574] UnitaMisura tag value when Item has Unit of Measure with Description value of length 50.
        Initialize();

        // [GIVEN] Sales Invoice with Item.
        CreateSalesDocument(
            SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer(), SalesHeader."Document Type"::Invoice);

        // [GIVEN] Item has Unit of Measure with Description value of length 50.
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        UpdateDescriptionOnUoM(
            SalesLine."Unit of Measure Code",
            CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(UnitOfMeasure.Description)), 1, MaxStrLen(UnitOfMeasure.Description)), OldUinitOfMeasureDescription);
        SalesLine.Validate("Unit of Measure Code");
        SalesLine.Modify(true);

        // [GIVEN] Sales Invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
            TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] UnitaMisura tag contains first 10 charachters of Description field of Unit of Measure.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
            TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/UnitaMisura',
            CopyStr(SalesLine."Unit of Measure", 1, 10));

        // TearDown
        UpdateDescriptionOnUoM(SalesLine."Unit of Measure Code", OldUinitOfMeasureDescription, OldUinitOfMeasureDescription);
    end;

    [Test]
    procedure DenominazioneWhenCustomerHasLongName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        CustomerName: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 444468] 1.4.1.3.1 Denominazione tag value when Customer has Name of length 100.
        Initialize();

        // [GIVEN] Sales Invoice for Customer "C".
        Customer.Get(CreateCustomer());
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), Customer."No.", SalesHeader."Document Type"::Invoice);

        // [GIVEN] Customer "C" has Name of length 100.
        CustomerName := LibraryUtility.GenerateRandomXMLText(MaxStrLen(Customer.Name));
        UpdateNameOnCustomer(Customer, CopyStr(CustomerName, 1, MaxStrLen(Customer.Name)));

        // [GIVEN] Sales Invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] 1.4.1.3.1 Denominazione tag contains first 80 charachters of Customer Name field.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer,
          '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente/DatiAnagrafici/Anagrafica/Denominazione',
          CopyStr(CustomerName, 1, 80));
    end;

    [Test]
    procedure DenominazioneWhenVendorHasLongName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        TaxRepresentativeVendor: Record Vendor;
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        VendorName: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 444468] 1.3.1.3.1 Denominazione tag value when Vendor has Name of length 100.
        Initialize();

        // [GIVEN] Company Information with Tax Representative No. "V".
        CreateCleanTaxRepresentative(TaxRepresentativeVendor);
        CompanyInformation.Get();
        TaxRepresentativeVendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        TaxRepresentativeVendor.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());
        TaxRepresentativeVendor.Modify(true);

        // [GIVEN] Sales Invoice with Item.
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer(), SalesHeader."Document Type"::Invoice);

        // [GIVEN] Vendor "V" has Name of length 100.
        VendorName := LibraryUtility.GenerateRandomXMLText(MaxStrLen(TaxRepresentativeVendor.Name));
        UpdateNameOnVendor(TaxRepresentativeVendor, CopyStr(VendorName, 1, MaxStrLen(TaxRepresentativeVendor.Name)));

        // [GIVEN] Sales Invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] 1.3.1.3.1 Denominazione tag contains first 80 charachters of Vendor Name field.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer,
          '/p:FatturaElettronica/FatturaElettronicaHeader/RappresentanteFiscale/DatiAnagrafici/Anagrafica/Denominazione',
          CopyStr(VendorName, 1, 80));
    end;

    [Test]
    procedure DenominazioneWhenCompanyHasLongName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
        CompanyName: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 444468] 1.2.1.3.1 Denominazione tag value when Company has Name of length 100.
        Initialize();

        // [GIVEN] Sales Invoice with Item.
        CreateSalesDocument(
          SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CreateCustomer(), SalesHeader."Document Type"::Invoice);

        // [GIVEN] Company has Name of length 100.
        CompanyName := LibraryUtility.GenerateRandomXMLText(MaxStrLen(CompanyInformation.Name));
        CompanyInformation.Get();
        UpdateNameOnCompany(CompanyInformation, CopyStr(CompanyName, 1, MaxStrLen(CompanyInformation.Name)));

        // [GIVEN] Sales Invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] 1.2.1.3.1 Denominazione tag contains first 80 charachters of Company Name field.
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        AssertCurrentElementValue(
          TempXMLBuffer,
          '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore/DatiAnagrafici/Anagrafica/Denominazione',
          CopyStr(CompanyName, 1, 80));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDocWithNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        UnitPrice: Decimal;
    begin
        // [SCENARIO 460038] The xml file of the document with negative line is correct

        Initialize();

        // [GIVEN] Posted sales invoice with two lines
        // [GIVEN] Quantity = 2, Unit Price = 20, Amount = 40
        // [GIVEN] Quantity = -1, Unit Price = 15, Amount = -15
        CustomerNo := CreateCustomer();
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        UnitPrice := SalesLine."Unit Price";
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", -SalesLine.Quantity / 3);
        SalesLine.Validate("Unit Price", UnitPrice / 3);
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA
        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] ImponibileImporto xml node has 25
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.CalcSums(Amount);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/ImponibileImporto',
          Format(SalesInvoiceLine.Amount, 0, '<Precision,2:5><Standard Format,9>'));
        // [THEN] PrezzoTotale xml node has correct values for both lines
        // [THEN] For the first line it is 40
        // [THEN] For the second line it is -15
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale');
        Assert.RecordCount(TempXMLBuffer, 2);
        SalesInvoiceLine.FindSet();
        repeat
            TempXMLBuffer.TestField(
              Value, Format(Round(SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price"), 0, '<Precision,2:5><Standard Format,9>'));
            TempXMLBuffer.Next();
        until SalesInvoiceLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDocWithZeroLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        ClientFileName: Text[250];
        UnitPrice: Decimal;
    begin
        // [SCENARIO 467883] The xml file of the document with zero line is correct

        Initialize();

        // [GIVEN] Posted sales invoice with two lines
        // [GIVEN] Quantity = 2, Unit Price = 20, Amount = 40
        // [GIVEN] Quantity = 0, Unit Price = 0, Amount = 0
        CustomerNo := CreateCustomer();
        CreateSalesDocument(SalesHeader, CreatePaymentMethod(), CreatePaymentTerms(), CustomerNo, SalesHeader."Document Type"::Invoice);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        UnitPrice := SalesLine."Unit Price";
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", 0);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] The document is exported to FatturaPA
        // [WHEN] The document is exported to FatturaPA.
        ElectronicDocumentFormat.SendElectronically(
          TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] The exported XML file is valid according to XSD Schema
        // [THEN] ImponibileImporto xml node has 25
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.CalcSums(Amount);
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/ImponibileImporto',
          Format(SalesInvoiceLine.Amount, 0, '<Precision,2:5><Standard Format,9>'));
        // [THEN] PrezzoTotale xml node has correct values for both lines
        // [THEN] For the first line it is 40
        // [THEN] For the second line it is 0
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale');
        Assert.RecordCount(TempXMLBuffer, 2);
        SalesInvoiceLine.FindSet();
        repeat
            TempXMLBuffer.TestField(
              Value, Format(Round(SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price"), 0, '<Precision,2:5><Standard Format,9>'));
            TempXMLBuffer.Next();
        until SalesInvoiceLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportedSalesInvoiceEsigibilitaIVATagWhenCoomentLineExist()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 465151] If a line type Comment is added after the Split VAT calculated line, 
        // the exported sale invoice VAT is not correct
        Initialize();

        // [GIVEN] Create a posted Sales Invoice with Amount = 100 and split payment line with amount = -100
        CreateCommentLineInvoiceWithSplitPayment(SalesHeader);

        // [GIVEN] Post the Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Save the Document No.
        DocumentRecRef.GetTable(SalesInvoiceHeader);
        DocumentNo := GetDocumentNo(DocumentRecRef);

        // [WHEN] Find the Sales Invoice Header
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Load the XMLBuffer from TenpBlob
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);

        // [VERIFY] Verify the Document Header have correct node and values
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef, SalesInvoiceHeader."Sell-to Customer No.");

        // [VERIFY] Verify the Document Line have correct values
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef, CustLedgerEntry."Document Type"::Invoice, ExportFromType::Sales, '', true, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceForCustomerWithCurrencyCode()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        TempBlob: Codeunit "Temp Blob";
        DocumentRecRef: RecordRef;
        GenPostingType: Enum "General Posting Type";
        VATCalculationType: Enum "Tax Calculation Type";
        DocumentNo: Code[20];
        ClientFileName: Text[250];
    begin
        // [SCENARIO 557964] Correct Detail Line is populated when exporting a document with different currency.
        Initialize();

        // [GIVEN] Create a VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", LibraryRandom.RandIntInRange(20, 20));

        // [GIVEN] Create a Currency with Exchange Rate.
        CreateCurrencyWithExchangeRate(Currency);

        // [GIVEN] Create a Customer with Currency Code.
        CreateCustomerWithCurrencyCode(Customer, Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create a G/L Account.
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Sale));

        // [GIVEN] Create a Sales Invoice and Post it.
        DocumentNo := CreateAndPostSalesInvWithCurrencyCode(DocumentRecRef, Customer."No.", GLAccount."No.");
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] A Fattura PA document is created for this Sales Invoice.
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] Verify sum of PrezzoTotale(Total Price) xml node for both lines equals to xml node ImponibileImporto(Taxable Amount).
        VerifyNodeImponibileImporto(TempBlob);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        ServiceInvoiceDiscountAmount := 0;

        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        InitializeFieldNo();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, CustomerNo, '', 5, '', 0D);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        UpdateItemGTIN(SalesLine."No.", Format(LibraryRandom.RandIntInRange(1000, 2000)));
    end;

    local procedure CreateAndPostSalesOrderAsShipment(CustomerNo: Code[20]; LinesNo: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        for i := 1 to LinesNo do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        exit(SalesHeader."No.");
    end;

    local procedure CreateAndPostSalesInvoice(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        DocumentRecordRef.GetTable(SalesInvoiceHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostSalesInvoiceWithSecondLineZeroUnitPrice(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::Invoice);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithExtText(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtTextSalesLine: Record "Sales Line";
        i: Integer;
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::Invoice);
        for i := 1 to 3 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
            LibrarySales.CreateSalesLineSimple(ExtTextSalesLine, SalesHeader);
            ExtTextSalesLine.Description := 'extended text' + Format(i);
            ExtTextSalesLine."Attached to Line No." := SalesLine."Line No.";
            ExtTextSalesLine.Modify();
        end;

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithNegativeLine(var UnitPrice: Decimal; var Quantity: Decimal; var DocumentNo: Code[20]; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Quantity := SalesLine.Quantity;
        UnitPrice := SalesLine."Unit Price";
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", -1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesCrMemo(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        DocumentRecordRef.GetTable(SalesCrMemoHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostSalesInvWithLineDisc(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(
          CreateAndPostSalesDocWithLineDisc(
            SalesHeader."Document Type"::Invoice, PaymentMethodCode, PaymentTermsCode, CustomerNo));
        DocumentRecordRef.GetTable(SalesInvoiceHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostSalesCrMemoWithLineDisc(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(
          CreateAndPostSalesDocWithLineDisc(
            SalesHeader."Document Type"::"Credit Memo", PaymentMethodCode, PaymentTermsCode, CustomerNo));
        DocumentRecordRef.GetTable(SalesCrMemoHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostSalesDocWithLineDisc(DocType: Enum "Sales Document Type"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, DocType);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostServiceDocument(var ServiceHeader: Record "Service Header"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; DocumentType: Enum "Service Document Type")
    begin
        CreateServiceHeader(ServiceHeader, CustomerNo, DocumentType);
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Validate("Payment Terms Code", PaymentTermsCode);
        ServiceHeader.Validate("Due Date", Today);
        ServiceHeader.Modify(true);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateAndPostServiceInvoice(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        CreateAndPostServiceDocument(ServiceHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, ServiceHeader."Document Type"::Invoice);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        DocumentRecordRef.GetTable(ServiceInvoiceHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostServiceCrMemo(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        CreateAndPostServiceDocument(
          ServiceHeader, PaymentMethodCode, PaymentTermsCode, CustomerNo, ServiceHeader."Document Type"::"Credit Memo");
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        DocumentRecordRef.GetTable(ServiceCrMemoHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostServiceInvoiceWithLineDisc(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        CreateAndPostServiceDicWithLineDisc(
          ServiceHeader."Document Type"::Invoice, PaymentMethodCode, PaymentTermsCode, CustomerNo);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        DocumentRecordRef.GetTable(ServiceInvoiceHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostServiceCrMemoWithLineDisc(var DocumentRecordRef: RecordRef; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        CreateAndPostServiceDicWithLineDisc(
          ServiceHeader."Document Type"::"Credit Memo", PaymentMethodCode, PaymentTermsCode, CustomerNo);
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        DocumentRecordRef.GetTable(ServiceCrMemoHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure CreateAndPostServiceDicWithLineDisc(DocType: Enum "Service Document Type"; PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, CustomerNo, DocType);
        ServiceHeader.Validate("Payment Method Code", PaymentMethodCode);
        ServiceHeader.Validate("Payment Terms Code", PaymentTermsCode);
        ServiceHeader.Validate("Due Date", Today);
        ServiceHeader.Modify(true);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        // Public Company Customer
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreateForeignCustomer(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Validate(City, LibraryUtility.GenerateGUID());
        Customer.Validate("Post Code", LibraryUtility.GenerateGUID());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePrivateCompanyCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 7)));
    end;

    local procedure CreateCustomerWithVATBussPostGroup(VATBussPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("VAT Bus. Posting Group", VATBussPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateInvoiceWithSplitPayment(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
    begin
        // create VAT Posting Setup
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(
          VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("VAT Transaction Nature", '');
        VATPostingSetup.Modify(true);
        SplitVATPostingSetup.Validate("VAT %", VATPostingSetup."VAT %");
        SplitVATPostingSetup.Validate("VAT Transaction Nature", VATPostingSetup."VAT Transaction Nature");
        SplitVATPostingSetup.Modify(true);
        LibrarySplitVAT.UpdateVATPostingSetupFullVAT(SplitVATPostingSetup);
        CreateInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.AddSplitVATLines();
    end;

    local procedure CreateInvoiceWithVATPostingSetup(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup") DocumentNo: Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithVATBussPostGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod());
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Modify(true);
        CreateSalesLineWithVATPostingGroup(SalesLine, SalesHeader, SalesLine.Type::Item, VATPostingSetup."VAT Prod. Posting Group");
        DocumentNo := NoSeriesBatch.GetNextNo(SalesHeader."Posting No. Series");
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode());
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode());
    end;

    local procedure CreateSalesLineWithVATPostingGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; VATProdPostingGroup: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        UpdateItemGTIN(Item."No.", Format(LibraryRandom.RandIntInRange(1000, 2000)));

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 100 and 200.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvFromShipment(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod());
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Validate("Customer Purchase Order No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateUnrealizedVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code,
          VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT Transaction Nature", LibrarySplitVAT.CreateVATTransactionNatureCode());
        VATPostingSetup.Modify(true);
    end;

    local procedure GetDocumentNo(var DocumentRecordRef: RecordRef): Code[20]
    begin
        exit(Format(DocumentRecordRef.Field(3).Value)); // Document No field = 3
    end;

    local procedure GetLineRecord(var LineRecRef: RecordRef; DocNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExportFromType: Option Sales,Service)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FieldRef: FieldRef;
    begin
        case DocumentType of
            CustLedgerEntry."Document Type"::Invoice:
                if ExportFromType = ExportFromType::Sales then
                    LineRecRef.Open(DATABASE::"Sales Invoice Line")
                else
                    LineRecRef.Open(DATABASE::"Service Invoice Line");
            CustLedgerEntry."Document Type"::"Credit Memo":
                if ExportFromType = ExportFromType::Sales then
                    LineRecRef.Open(DATABASE::"Sales Cr.Memo Line")
                else
                    LineRecRef.Open(DATABASE::"Service Cr.Memo Line");
        end;

        FieldRef := LineRecRef.Field(DocNoFieldNo);
        FieldRef.SetRange(DocNo);
    end;

    local procedure GetVATType(TypeValue: Option; DocTypeValue: Option; DocNoValue: Code[20]; IsSplitPaymentDoc: Boolean): Code[1]
    var
        VATEntry: Record "VAT Entry";
    begin
        if IsSplitPaymentDoc then
            exit('S');
        VATEntry.SetRange(Type, TypeValue);
        VATEntry.SetRange("Document Type", DocTypeValue);
        VATEntry.SetRange("Document No.", DocNoValue);
        if VATEntry.FindFirst() then
            if VATEntry."Unrealized Amount" <> 0 then
                exit('D');
        exit('I');
    end;

    local procedure GetCustomerPostCode(CustomerNo: Code[20]): Code[10]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(Customer."Post Code");
    end;

    local procedure VerifyFatturaPAFileHeaderPublicCompany(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef; CustomerNo: Code[20])
    begin
        VerifyXMLDefinitionPublicCompany(TempXMLBuffer);
        VerifyFatturaPAFileHeader(TempXMLBuffer, HeaderRecRef, CustomerNo);
        VerifyTransmissionDataPublicCompany(TempXMLBuffer, CustomerNo);
    end;

    local procedure VerifyFatturaPAFileHeaderPrivateCompany(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef; CustomerNo: Code[20])
    begin
        VerifyXMLDefinitionPrivateCompany(TempXMLBuffer);
        VerifyFatturaPAFileHeader(TempXMLBuffer, HeaderRecRef, CustomerNo);
        VerifyTransmissionDataPrivateCompany(TempXMLBuffer, CustomerNo);
    end;

    local procedure VerifyFatturaPAFileHeader(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef; CustomerNo: Code[20])
    begin
        VerifyHeaderRecord(HeaderRecRef);
        VerifyCompanyInformation(TempXMLBuffer);
        VerifyTaxRepresentative(TempXMLBuffer);
        VerifyCustomerData(TempXMLBuffer, CustomerNo);
        VerifyDocGeneralData(TempXMLBuffer, HeaderRecRef);
        VerifyDocDiscountData(TempXMLBuffer, HeaderRecRef);
    end;

    local procedure VerifyFatturaPAFileBody(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef; DocumentType: Enum "Gen. Journal Document Type"; ExportFromType: Option; OrderNo: Code[20]; ItemGTIN: Boolean; VATTransactionNature: Code[20])
    var
        LineRecRef: RecordRef;
        IsSplitPayment: Boolean;
        DocumentNo: Code[20];
    begin
        // 2.2 DatiBeniServizi - Goods/Services data
        DocumentNo := GetDocumentNo(HeaderRecRef);
        GetLineRecord(LineRecRef, DocumentNo, DocumentType, ExportFromType);
        LineRecRef.FindSet();
        IsSplitPayment := ContainsSplitPayment(LineRecRef);
        // fill in General, Order Data
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                VerifyOrderData(TempXMLBuffer, HeaderRecRef, OrderNo);
        until LineRecRef.Next() = 0;
        // fill in LineData
        LineRecRef.FindFirst();
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                VerifyLineData(TempXMLBuffer, LineRecRef, ItemGTIN, VATTransactionNature);
        until LineRecRef.Next() = 0;
        // fill in LineVATData
        LineRecRef.FindFirst();
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                VerifyLineVATData(TempXMLBuffer, LineRecRef, IsSplitPayment, VATTransactionNature);
        until LineRecRef.Next() = 0;

        TempXMLBuffer.GetParent();
        VerifyPaymentData(TempXMLBuffer, HeaderRecRef);
    end;

    local procedure ContainsSplitPayment(LineRecRef: RecordRef): Boolean
    begin
        repeat
            if IsSplitPaymentLine(LineRecRef) then begin
                LineRecRef.FindFirst();
                exit(true);
            end;
        until LineRecRef.Next() = 0;
        LineRecRef.FindFirst();
        exit(false)
    end;

    local procedure VerifyXMLDefinitionPublicCompany(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        Assert.AreEqual(TempXMLBuffer.GetElementName(), 'p:FatturaElettronica', '');
        Assert.AreEqual(TempXMLBuffer.GetAttributeValueAsText('versione'), 'FPA12', '');
    end;

    local procedure VerifyXMLDefinitionPrivateCompany(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        Assert.AreEqual(TempXMLBuffer.GetElementName(), 'p:FatturaElettronica', '');
        Assert.AreEqual(TempXMLBuffer.GetAttributeValueAsText('versione'), 'FPR12', '');
    end;

    local procedure VerifyFileName(ActualFileName: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        // - country code + the transmitter's unique identity code + unique progressive number of the file
        Assert.IsTrue(StrPos(ActualFileName, (CompanyInformation."Country/Region Code" +
                                             CompanyInformation."Fiscal Code" + '_')) = 1, '');
    end;

    local procedure VerifyHeaderRecord(HeaderRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        DocNo := HeaderRecRef.Field(DocNoFieldNo).Value();
        case HeaderRecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    HeaderRecRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.CalcFields("Amount Including VAT", "Invoice Discount Amount");
                    DocumentType := CustLedgerEntry."Document Type"::Invoice;
                    PostingDate := SalesInvoiceHeader."Posting Date";
                    ExportFromType := ExportFromType::Sales;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    HeaderRecRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.CalcFields("Amount Including VAT");
                    DocumentType := CustLedgerEntry."Document Type"::Invoice;
                    PostingDate := ServiceInvoiceHeader."Posting Date";
                    ExportFromType := ExportFromType::Service;
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    HeaderRecRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.CalcFields("Amount Including VAT", "Invoice Discount Amount");
                    DocumentType := CustLedgerEntry."Document Type"::"Credit Memo";
                    PostingDate := SalesCrMemoHeader."Posting Date";
                    ExportFromType := ExportFromType::Sales;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    HeaderRecRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.CalcFields("Amount Including VAT");
                    DocumentType := CustLedgerEntry."Document Type"::"Credit Memo";
                    PostingDate := ServiceCrMemoHeader."Posting Date";
                    ExportFromType := ExportFromType::Service;
                end;
        end;
    end;

    local procedure InitializeFieldNo()
    begin
        // field id of the Header tables
        CustomerNoFieldNo := 4;
        PaymentTermsCodeFieldNo := 23;
        PaymentMethodCodeFieldNo := 104;
        PostingDateFieldNo := 20;
        InvoiceDiscountAmountFieldNo := 1305;
        DocNoFieldNo := 3;
        FatturaProjectCodeFieldNo := 12182;
        FatturaTenderCodeFieldNo := 12183;

        // field id of Lines tables
        QuantityFieldNo := 15;
        LineAmountIncludingVATFieldNo := 30;
        VatPercFieldNo := 25;
        VATBaseAmountFieldNo := 99;
        LineNoFieldNo := 4;
        DescriptionFieldNo := 11;
        UnitOfMeasureFieldNo := 13;
        UnitPriceFieldNo := 22;
        LineDiscountAmountFieldNo := 28;
        LineDiscountPercFieldNo := 27;
        LineInvDiscAmountFieldNo := 69;
        AmountFieldNo := 29;
        VATBusPostingGroupCodeFieldNo := 89;
        VATProdPostingGroupCodeFieldNo := 90;
        PricesIncludingVATFieldNo := 35;
    end;

    local procedure IsSplitPaymentLine(LineRecRef: RecordRef): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ReversedVATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(Format(LineRecRef.Field(VATBusPostingGroupCodeFieldNo).Value),
             Format(LineRecRef.Field(VATProdPostingGroupCodeFieldNo).Value))
        then
            if (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT") and
               ReversedVATPostingSetup.Get(VATPostingSetup."Reversed VAT Bus. Post. Group", VATPostingSetup."Reversed VAT Prod. Post. Group")
            then
                exit(true);
        exit(false);
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure FormatAmountFromFieldRef(FieldRef: FieldRef): Text[250]
    begin
        exit(Format(FieldRef.Value, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure VerifyTransmissionDataPublicCompany(var TempXMLBuffer: Record "XML Buffer" temporary; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        VerifyTransmissionData(TempXMLBuffer, 'FPA12');
        Customer.Get(CustomerNo);
        AssertElementValue(TempXMLBuffer, 'CodiceDestinatario', Customer."PA Code");
    end;

    local procedure VerifyTransmissionDataPrivateCompany(var TempXMLBuffer: Record "XML Buffer" temporary; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        VerifyTransmissionData(TempXMLBuffer, 'FPR12');
        Customer.Get(CustomerNo);
        AssertElementValue(TempXMLBuffer, 'CodiceDestinatario', Customer."PA Code");
    end;

    local procedure UpdateItemGTIN(ItemNo: Code[20]; GTIN: Code[14])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate(GTIN, GTIN);
        Item.Modify(true);
    end;

    local procedure UpdateDescriptionOnUoM(UnitOfMeasureCode: Code[10]; NewDescription: Text[50]; var UnitofMeasureDescription: Text[50])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Get(UnitOfMeasureCode);
        UnitofMeasureDescription := UnitOfMeasure.Description;
        UnitOfMeasure.Validate(Description, NewDescription);
        UnitOfMeasure.Modify(true);
    end;

    local procedure UpdateNameOnCustomer(var Customer: Record Customer; CustomerName: Text[100])
    begin
        Customer.Validate(Name, CustomerName);
        Customer.Modify(true);
    end;

    local procedure UpdateNameOnVendor(var Vendor: Record Vendor; VendorName: Text[100])
    begin
        Vendor.Validate(Name, VendorName);
        Vendor.Modify(true);
    end;

    local procedure UpdateNameOnCompany(var CompanyInformation: Record "Company Information"; CompanyName: Text[100])
    begin
        CompanyInformation.Validate(Name, CompanyName);
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyTransmissionData(var TempXMLBuffer: Record "XML Buffer" temporary; FormatoTrasmissione: Text)
    var
        CompanyInformation: Record "Company Information";
        TransmissionIntermediaryVendor: Record Vendor;
    begin
        CompanyInformation.Get();
        // Section 1.1 DatiTrasmissione
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/DatiTrasmissione');
        AssertElementValue(TempXMLBuffer, 'IdTrasmittente', '');

        if not TransmissionIntermediaryVendor.Get(CompanyInformation."Transmission Intermediary No.") then begin
            AssertElementValue(TempXMLBuffer, 'IdPaese', Format(CompanyInformation."Country/Region Code"));
            AssertElementValue(TempXMLBuffer, 'IdCodice', Format(CompanyInformation."Fiscal Code"));
        end else begin
            AssertElementValue(TempXMLBuffer, 'IdPaese', TransmissionIntermediaryVendor."Country/Region Code");
            AssertElementValue(TempXMLBuffer, 'IdCodice', TransmissionIntermediaryVendor."Fiscal Code");
        end;

        FindNextElement(TempXMLBuffer);
        AssertElementValue(TempXMLBuffer, 'FormatoTrasmissione', FormatoTrasmissione);
    end;

    local procedure VerifyCompanyInformation(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CedentePrestatore');
        // 1.2 CedentePrestatore - Seller
        AssertElementValue(TempXMLBuffer, 'DatiAnagrafici', '');
        AssertElementValue(TempXMLBuffer, 'IdFiscaleIVA', '');
        AssertElementValue(TempXMLBuffer, 'IdPaese', CompanyInformation."Country/Region Code");
        AssertElementValue(TempXMLBuffer, 'IdCodice', CompanyInformation."VAT Registration No.");
        AssertElementValue(TempXMLBuffer, 'CodiceFiscale', CompanyInformation."Fiscal Code");

        AssertElementValue(TempXMLBuffer, 'Anagrafica', '');
        AssertElementValue(TempXMLBuffer, 'Denominazione', CompanyInformation.Name);
        AssertElementValue(TempXMLBuffer, 'RegimeFiscale', 'RF' + CompanyInformation."Company Type");
        // 1.2.2 Sede
        AssertElementValue(TempXMLBuffer, 'Sede', '');
        AssertElementValue(TempXMLBuffer, 'Indirizzo', CompanyInformation.Address);
        AssertElementValue(TempXMLBuffer, 'CAP', CompanyInformation."Post Code");
        AssertElementValue(TempXMLBuffer, 'Comune', CompanyInformation.City);
        AssertElementValue(TempXMLBuffer, 'Provincia', CompanyInformation.County);
        AssertElementValue(TempXMLBuffer, 'Nazione', CompanyInformation."Country/Region Code");
        // 1.2.4 IscrizioneREA
        AssertElementValue(TempXMLBuffer, 'IscrizioneREA', '');
        AssertElementValue(TempXMLBuffer, 'Ufficio', CompanyInformation."Registry Office Province");
        AssertElementValue(TempXMLBuffer, 'NumeroREA', CompanyInformation."REA No.");
        AssertElementValue(TempXMLBuffer, 'CapitaleSociale', FormatAmount(CompanyInformation."Paid-In Capital"));
        if CompanyInformation."Shareholder Status" = CompanyInformation."Shareholder Status"::"One Shareholder" then
            AssertElementValue(TempXMLBuffer, 'SocioUnico', 'SU')
        else
            AssertElementValue(TempXMLBuffer, 'SocioUnico', 'SM');

        if CompanyInformation."Liquidation Status" = CompanyInformation."Liquidation Status"::"Not in Liquidation" then
            AssertElementValue(TempXMLBuffer, 'StatoLiquidazione', 'LN')
        else
            AssertElementValue(TempXMLBuffer, 'StatoLiquidazione', 'LS');
        // 1.2.5 Contatti
        AssertElementValue(TempXMLBuffer, 'Contatti', '');
        AssertElementValue(TempXMLBuffer, 'Telefono', DelChr(CompanyInformation."Phone No.", '=', '-'));
        AssertElementValue(TempXMLBuffer, 'Fax', DelChr(CompanyInformation."Fax No.", '=', '-'));
        AssertElementValue(TempXMLBuffer, 'Email', CompanyInformation."E-Mail");
    end;

    local procedure VerifyTaxRepresentative(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        TaxRepresentativeVendor: Record Vendor;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        // 1.3. RappresentanteFiscale - TAX REPRESENTATIVE
        if CompanyInformation."Tax Representative No." <> '' then begin
            TaxRepresentativeVendor.Get(CompanyInformation."Tax Representative No.");
            if CompanyInformation."Tax Representative No." <> '' then begin
                AssertElementValue(TempXMLBuffer, 'RappresentanteFiscale', '');
                AssertElementValue(TempXMLBuffer, 'DatiAnagrafici', '');
                AssertElementValue(TempXMLBuffer, 'IdFiscaleIVA', '');
                AssertElementValue(TempXMLBuffer, 'IdPaese', TaxRepresentativeVendor."Country/Region Code");
                AssertElementValue(TempXMLBuffer, 'IdCodice', TaxRepresentativeVendor."VAT Registration No.");

                AssertElementValue(TempXMLBuffer, 'Anagrafica', '');
                if TaxRepresentativeVendor."Individual Person" then begin
                    AssertElementValue(TempXMLBuffer, 'Nome', TaxRepresentativeVendor."First Name");
                    AssertElementValue(TempXMLBuffer, 'Cognome', TaxRepresentativeVendor."Last Name");
                end else
                    AssertElementValue(TempXMLBuffer, 'Denominazione', TaxRepresentativeVendor.Name);

                TempXMLBuffer.GetParent();
                TempXMLBuffer.GetParent();
            end;
        end;
    end;

    local procedure VerifyCustomerData(var TempXMLBuffer: Record "XML Buffer" temporary; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        // 1.4 CessionarioCommittente
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaHeader/CessionarioCommittente');
        AssertElementValue(TempXMLBuffer, 'DatiAnagrafici', '');
        if not Customer."Individual Person" then begin
            AssertElementValue(TempXMLBuffer, 'IdFiscaleIVA', '');
            AssertElementValue(TempXMLBuffer, 'IdPaese', Customer."Country/Region Code");
            AssertElementValue(TempXMLBuffer, 'IdCodice', Customer."VAT Registration No.");
        end;
        AssertElementValue(TempXMLBuffer, 'CodiceFiscale', Customer."Fiscal Code");
        // 1.4.1.3 Anagrafica
        AssertElementValue(TempXMLBuffer, 'Anagrafica', '');
        if Customer."Individual Person" then begin
            AssertElementValue(TempXMLBuffer, 'Nome', Customer."First Name");
            AssertElementValue(TempXMLBuffer, 'Cognome', Customer."Last Name");
        end else
            AssertElementValue(TempXMLBuffer, 'Denominazione', Customer.Name);
        // 1.4.2. Sede
        AssertElementValue(TempXMLBuffer, 'Sede', '');
        AssertElementValue(TempXMLBuffer, 'Indirizzo', Customer.Address);
        AssertElementValue(TempXMLBuffer, 'CAP', Customer."Post Code");
        AssertElementValue(TempXMLBuffer, 'Comune', Customer.City);
        AssertElementValue(TempXMLBuffer, 'Provincia', Customer.County);
        AssertElementValue(TempXMLBuffer, 'Nazione', Customer."Country/Region Code");
        TempXMLBuffer.GetParent();
        TempXMLBuffer.GetParent();
    end;

    local procedure VerifyDocGeneralData(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GeneralLedgerSetup.Get();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody');
        AssertElementValue(TempXMLBuffer, 'DatiGenerali', '');
        // 2.1.1   DatiGeneraliDocumento - general details
        AssertElementValue(TempXMLBuffer, 'DatiGeneraliDocumento', '');
        case DocumentType of
            CustLedgerEntry."Document Type"::Invoice:
                AssertElementValue(TempXMLBuffer, 'TipoDocumento', 'TD01');
            CustLedgerEntry."Document Type"::"Credit Memo":
                AssertElementValue(TempXMLBuffer, 'TipoDocumento', 'TD04');
            else
                AssertElementValue(TempXMLBuffer, 'TipoDocumento', 'TD02');
        end;
        // 2.1.1.2 Divisa
        AssertElementValue(TempXMLBuffer, 'Divisa', GeneralLedgerSetup."LCY Code");
        // 2.1.1.3  Data
        PostingDateFieldNo := 20;
        AssertElementValue(TempXMLBuffer, 'Data', FormatAmountFromFieldRef(HeaderRecRef.Field(PostingDateFieldNo)));
        // 2.1.1.4   Numero
        DocNoFieldNo := 3;
        AssertElementValue(TempXMLBuffer, 'Numero', Format(HeaderRecRef.Field(DocNoFieldNo).Value));
    end;

    local procedure VerifyDocDiscountData(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef)
    var
        LineRecRef: RecordRef;
        InvoiceDiscountAmount: Decimal;
        AmountInclVAT: Decimal;
        TotalAmount: Decimal;
    begin
        // 2.1.1.8 - ScontoMaggiorazione - Discount - Extra charge
        if ExportFromType = ExportFromType::Sales then begin
            InvoiceDiscountAmountFieldNo := 1305;
            InvoiceDiscountAmount := HeaderRecRef.Field(InvoiceDiscountAmountFieldNo).Value
        end else
            InvoiceDiscountAmount := ServiceInvoiceDiscountAmount;
        if InvoiceDiscountAmount <> 0 then begin
            AssertElementValue(TempXMLBuffer, 'ScontoMaggiorazione', '');
            AssertElementValue(TempXMLBuffer, 'Tipo', 'SC');
            AssertElementValue(TempXMLBuffer, 'Importo', FormatAmount(InvoiceDiscountAmount));
        end;
        // 2.1.1.9   ImportoTotaleDocumento
        GetLineRecord(LineRecRef, DocNo, DocumentType, ExportFromType);
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                if Evaluate(AmountInclVAT, Format(LineRecRef.Field(LineAmountIncludingVATFieldNo).Value)) then
                    TotalAmount += AmountInclVAT;
        until LineRecRef.Next() = 0;

        AssertElementValue(TempXMLBuffer, 'ImportoTotaleDocumento', FormatAmount(TotalAmount));
        TempXMLBuffer.GetParent();
    end;

    local procedure VerifyLineData(var TempXMLBuffer: Record "XML Buffer" temporary; LineRecRef: RecordRef; ItemGTIN: Boolean; VATTransactionNature: Code[20])
    var
        Item: Record Item;
        LineDiscountAmount: Decimal;
        LineAmount: Decimal;
        LineDiscountPct: Decimal;
        UnitPrice: Decimal;
        NoFieldNo: Integer;
    begin
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee');
        Evaluate(LineAmount, Format(LineRecRef.Field(AmountFieldNo)));
        if LineAmount = 0 then
            exit;
        // 2.2.1 DettaglioLinee
        AssertElementValue(TempXMLBuffer, 'NumeroLinea', Format(1));

        if ExportFromType = ExportFromType::Service then
            SumUpServiceDiscountAmount(LineRecRef);

        NoFieldNo := 6;
        Item.Get(LineRecRef.Field(NoFieldNo).Value);
        if ItemGTIN then begin
            AssertElementValue(TempXMLBuffer, 'CodiceArticolo', '');
            AssertElementValue(TempXMLBuffer, 'CodiceTipo', 'GTIN');
            AssertElementValue(TempXMLBuffer, 'CodiceValore', Item.GTIN);
        end;

        DescriptionFieldNo := 11;
        QuantityFieldNo := 15;
        AssertElementValue(TempXMLBuffer, 'Descrizione', Format(LineRecRef.Field(DescriptionFieldNo).Value));
        AssertElementValue(TempXMLBuffer, 'Quantita', FormatAmountFromFieldRef(LineRecRef.Field(QuantityFieldNo)));

        UnitOfMeasureFieldNo := 13;
        UnitPriceFieldNo := 22;
        AssertElementValue(TempXMLBuffer, 'UnitaMisura', Format(LineRecRef.Field(UnitOfMeasureFieldNo).Value));
        AssertElementValue(TempXMLBuffer, 'PrezzoUnitario', FormatAmountFromFieldRef(LineRecRef.Field(UnitPriceFieldNo)));

        LineDiscountPct := LineRecRef.Field(LineDiscountPercFieldNo).Value();
        LineDiscountAmount := LineRecRef.Field(LineDiscountAmountFieldNo).Value();
        UnitPrice := LineRecRef.Field(UnitPriceFieldNo).Value();
        if (LineDiscountAmount <> 0) or (LineDiscountPct <> 0) then begin
            AssertElementValue(TempXMLBuffer, 'ScontoMaggiorazione', '');
            AssertElementValue(TempXMLBuffer, 'Tipo', 'SC');
            AssertElementValue(TempXMLBuffer, 'Percentuale', FormatAmountFromFieldRef(LineRecRef.Field(LineDiscountPercFieldNo)));
            AssertElementValue(TempXMLBuffer, 'Importo', FormatAmountEightDecimalPlaces((UnitPrice * LineDiscountPct) / 100));
        end;

        AssertElementValue(TempXMLBuffer, 'PrezzoTotale', FormatAmountFromFieldRef(LineRecRef.Field(AmountFieldNo)));
        AssertElementValue(TempXMLBuffer, 'AliquotaIVA', FormatAmountFromFieldRef(LineRecRef.Field(VatPercFieldNo)));
        if VATTransactionNature <> '' then
            AssertElementValue(TempXMLBuffer, 'Natura', VATTransactionNature);
    end;

    local procedure VerifyLineVATData(var TempXMLBuffer: Record "XML Buffer" temporary; LineRecRef: RecordRef; IsSplitPaymentDoc: Boolean; VATTransactionNature: Code[20])
    var
        LineAmountIncludingVAT: Decimal;
        Quantity: Decimal;
        VATBaseAmount: Decimal;
        VATRate: Decimal;
    begin
        // 2.2.2 DatiRiepilogo - summary data for every VAT rate
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo');

        Quantity := LineRecRef.Field(QuantityFieldNo).Value();
        LineAmountIncludingVAT := LineRecRef.Field(LineAmountIncludingVATFieldNo).Value();
        VATBaseAmount := LineRecRef.Field(VATBaseAmountFieldNo).Value();

        if (Quantity <> 0) and (LineAmountIncludingVAT <> 0) then begin
            VatPercFieldNo := 25;
            AssertElementValue(TempXMLBuffer, 'AliquotaIVA', FormatAmountFromFieldRef(LineRecRef.Field(VatPercFieldNo)));
            if VATTransactionNature <> '' then
                AssertElementValue(TempXMLBuffer, 'Natura', VATTransactionNature);
            AssertElementValue(TempXMLBuffer,
              'ImponibileImporto', FormatAmountFromFieldRef(LineRecRef.Field(VATBaseAmountFieldNo)));
            AssertElementValue(TempXMLBuffer, 'Imposta', FormatAmount(LineAmountIncludingVAT - VATBaseAmount));
            Evaluate(VATRate, Format(LineRecRef.Field(VatPercFieldNo).Value));
            if VATRate <> 0 then
                AssertElementValue(
                  TempXMLBuffer, 'EsigibilitaIVA', GetVATType(1, 1, Format(LineRecRef.Field(LineNoFieldNo).Value), IsSplitPaymentDoc));
        end;
    end;

    local procedure VerifyOrderData(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef; OrderNo: Code[20])
    begin
        // 2.1.2  DatiOrdineAcquisto
        if OrderNo <> '' then begin
            AssertElementValue(TempXMLBuffer, 'DatiOrdineAcquisto', '');
            AssertElementValue(TempXMLBuffer, 'IdDocumento', OrderNo);
            AssertElementValue(TempXMLBuffer, 'CodiceCUP', Format(HeaderRecRef.Field(FatturaProjectCodeFieldNo).Value));
            AssertElementValue(TempXMLBuffer, 'CodiceCIG', Format(HeaderRecRef.Field(FatturaTenderCodeFieldNo).Value));
        end;
    end;

    local procedure VerifyPaymentData(var TempXMLBuffer: Record "XML Buffer" temporary; HeaderRecRef: RecordRef)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CompanyInformation: Record "Company Information";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CompanyInformation.Get();
        // 2.4. DatiPagamento - Payment Data
        PaymentTerms.Get(HeaderRecRef.Field(PaymentTermsCodeFieldNo).Value);
        PaymentMethod.Get(HeaderRecRef.Field(PaymentMethodCodeFieldNo).Value);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");

        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, 'p:FatturaElettronica/FatturaElettronicaBody/DatiPagamento');
        AssertElementValue(TempXMLBuffer, 'CondizioniPagamento', PaymentTerms."Fattura Payment Terms Code");
        AssertElementValue(TempXMLBuffer, 'DettaglioPagamento', '');
        AssertElementValue(TempXMLBuffer, 'ModalitaPagamento', PaymentMethod."Fattura PA Payment Method");
        AssertElementValue(TempXMLBuffer,
          'DataScadenzaPagamento', Format(CustLedgerEntry."Due Date", 0, '<Standard Format,9>'));
        AssertElementValue(TempXMLBuffer, 'ImportoPagamento', FormatAmount(CustLedgerEntry."Amount (LCY)"));
        AssertElementValue(TempXMLBuffer, 'IBAN', CompanyInformation.IBAN);
    end;

    local procedure VerifyZipArchive(DocumentRecRef1: RecordRef; DocumentRecRef2: RecordRef; TempBlob: Codeunit "Temp Blob"; ExportFromType: Option Sales,Service; DocumentType: Enum "Gen. Journal Document Type")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ZipTempBlob: Codeunit "Temp Blob";
        EntryList: List of [Text];
        FirstFileInStream: InStream;
        SecondFileInStream: InStream;
        FirstFileOutStream: OutStream;
        SecondFileOutStream: OutStream;
        CustomerNo1: Code[20];
        CustomerNo2: Code[20];
    begin
        // verify zip file
        DataCompression.OpenZipArchive(TempBlob, false);
        DataCompression.GetEntryList(EntryList);

        // verify first file
        ZipTempBlob.CreateOutStream(FirstFileOutStream);
        DataCompression.ExtractEntry(EntryList.Get(1), FirstFileOutStream);
        ZipTempBlob.CreateInStream(FirstFileInStream);
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(EntryList.Get(1)));
        TempXMLBuffer.LoadFromStream(FirstFileInStream);
        CustomerNo1 := DocumentRecRef1.Field(CustomerNoFieldNo).Value();
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef1, CustomerNo1);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef1, DocumentType, ExportFromType, '', true, '');
        VerifyXSDSchemaForStream(FirstFileInStream);

        // verify second file
        clear(ZipTempBlob);
        Clear(TempXMLBuffer);
        TempXMLBuffer.DeleteAll();

        ZipTempBlob.CreateOutStream(SecondFileOutStream);
        DataCompression.ExtractEntry(EntryList.Get(2), SecondFileOutStream);
        ZipTempBlob.CreateInStream(SecondFileInStream);
        VerifyFileName(FileManagement.GetFileNameWithoutExtension(EntryList.Get(2)));
        TempXMLBuffer.LoadFromStream(SecondFileInStream);
        CustomerNo2 := DocumentRecRef2.Field(CustomerNoFieldNo).Value();
        VerifyFatturaPAFileHeaderPublicCompany(TempXMLBuffer, DocumentRecRef2, CustomerNo2);
        VerifyFatturaPAFileBody(TempXMLBuffer, DocumentRecRef2, DocumentType, ExportFromType, '', true, '');
        VerifyXSDSchemaForStream(SecondFileInStream);

        DataCompression.CloseZipArchive();
    end;

    local procedure VerifyXSDSchemaForStream(XmlInStream: InStream)
    VAR
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryVerifyXMLSchema: Codeunit "Library - Verify XML Schema";
        Message: Text;
        SignatureXsdPath: Text;
        XsdPath: Text;
        InetRoot: Text;
    BEGIN
        InetRoot := LibraryUtilityOnPrem.GetInetRoot() + InetRootRelativePathTxt;
        SignatureXsdPath := InetRoot + SignatureXSDRelativePathTxt;
        XsdPath := InetRoot + XSDRelativePathTxt;
        LibraryVerifyXMLSchema.SetAdditionalSchemaPath(SignatureXsdPath);
        Assert.IsTrue(LibraryVerifyXMLSchema.VerifyXMLStreamAgainstSchema(XmlInStream, XsdPath, Message), Message);
    END;

    local procedure VerifyDatiOrdineAcquistoForMultipleShipments(TempBlob: Codeunit "Temp Blob"; DocumentNo: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', '2');
        AssertElementValue(TempXMLBuffer, 'IdDocumento', DocumentNo);
        FindNextElement(TempXMLBuffer);
        AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', '4');
        AssertElementValue(TempXMLBuffer, 'RiferimentoNumeroLinea', '5');
        AssertElementValue(TempXMLBuffer, 'IdDocumento', DocumentNo);
    end;

    local procedure VerifyDatiOrdineAcquistoForShipmentWithMultipleLines(TempBlob: Codeunit "Temp Blob"; SalesOrderNo: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiOrdineAcquisto');
        AssertElementValue(TempXMLBuffer, 'IdDocumento', SalesOrderNo);
    end;

    local procedure VerifyCustomerEmail(var XMLBuffer: Record "XML Buffer"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        AssertElementValue(XMLBuffer, 'PECDestinatario', Customer."PEC E-Mail Address");
    end;

    local procedure VerifyNoRiferimentoTestoNodes(TempBlob: Codeunit "Temp Blob")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer,
          '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/AltriDatiGestionali/RiferimentoTesto');
        Assert.RecordCount(TempXMLBuffer, 0);
    end;

    local procedure SumUpServiceDiscountAmount(LineRecRef: RecordRef)
    var
        DiscountPerc: Decimal;
        LineDiscountAmount: Decimal;
        PricesIncludingVAT: Boolean;
    begin
        PricesIncludingVAT := LineRecRef.Field(PricesIncludingVATFieldNo).Value();
        if Evaluate(LineDiscountAmount, Format(LineRecRef.Field(LineDiscountAmountFieldNo).Value)) then;
        if PricesIncludingVAT then begin
            if Evaluate(DiscountPerc, Format(LineRecRef.Field(LineDiscountPercFieldNo).Value)) then;
            ServiceInvoiceDiscountAmount += LineDiscountAmount / (1 + DiscountPerc / 100)
        end else
            ServiceInvoiceDiscountAmount += LineDiscountAmount;
    end;

    local procedure AssertElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; ElementName: Text; ElementValue: Text)
    begin
        FindNextElement(TempXMLBuffer);
        Assert.AreEqual(ElementName, TempXMLBuffer.GetElementName(),
          StrSubstNo(UnexpectedElementNameErr, ElementName, TempXMLBuffer.GetElementName()));
        Assert.AreEqual(ElementValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, ElementName, ElementValue, TempXMLBuffer.Value));
    end;

    local procedure FindNextElement(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        if TempXMLBuffer.HasChildNodes() then
            TempXMLBuffer.FindChildElements(TempXMLBuffer)
        else
            if not (TempXMLBuffer.Next() > 0) then begin
                TempXMLBuffer.GetParent();
                TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                if not (TempXMLBuffer.Next() > 0) then
                    repeat
                        TempXMLBuffer.GetParent();
                        TempXMLBuffer.SetRange("Parent Entry No.", TempXMLBuffer."Parent Entry No.");
                    until (TempXMLBuffer.Next() > 0);
            end;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure PostAndSendSalesInvoice(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.PostAndSend.Invoke();
    end;

    local procedure PostAndSendSalesCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.PostAndSend.Invoke();
    end;

    local procedure PostAndSendServiceInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenView();
        ServiceInvoices.GotoRecord(ServiceHeader);
        ServiceInvoices.PostAndSend.Invoke();
    end;

    local procedure PostAndSendServiceCreditMemo(ServiceHeader: Record "Service Header")
    var
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.GotoRecord(ServiceHeader);
        ServiceCreditMemos.PostAndSend.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendHandlerYes(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes().Invoke();
    end;

    local procedure CreateCleanCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Clear(Customer."Payment Method Code");
        Clear(Customer."Payment Terms Code");
        Clear(Customer.Name);
        Customer.Validate("Country/Region Code", 'IT');
        Customer.Modify();
    end;

    local procedure ClearCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Clear(CompanyInformation);
        CompanyInformation.Modify();
    end;

    local procedure ClearFatturaPANoSeries()
    begin
        SalesReceivablesSetup.Get();
        Clear(SalesReceivablesSetup."Fattura PA Nos.");
        SalesReceivablesSetup.Modify();
    end;

    local procedure AssertSalesHeaderErrorMessages(SalesHeader: Record "Sales Header")
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesHeader, SalesHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          SalesHeader, SalesHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertPostedDocumentHeaderErrorMessages(PostedDocumentHeaderRecordRef: RecordRef)
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(
          PostedDocumentHeaderRecordRef, PaymentMethodCodeFieldNo, ErrorMessage."Message Type"::Warning);
        LibraryErrorMessage.AssertLogIfMessageExists(
          PostedDocumentHeaderRecordRef, PaymentTermsCodeFieldNo, ErrorMessage."Message Type"::Warning);
    end;

    local procedure AssertServiceHeaderErrorMessages(ServiceHeader: Record "Service Header")
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(
          ServiceHeader, ServiceHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          ServiceHeader, ServiceHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertCompanyErrorMessages()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        ErrorMessage.LogIfLengthExceeded(
          CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error, 16);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("Company Type"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo(Address), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo(City), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("REA No."), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          CompanyInformation, CompanyInformation.FieldNo("Registry Office Province"), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertCustomerErrorMessages(Customer: Record Customer)
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(Customer, Customer.FieldNo("PA Code"), ErrorMessage."Message Type"::Error);
        // LibraryErrorMessage.AssertLogIfMessageExists(Customer,Customer.FIELDNO("Country/Region Code"),ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(Customer, Customer.FieldNo(Address), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(Customer, Customer.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(Customer, Customer.FieldNo(City), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(Customer, Customer.FieldNo(Name), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertTaxRepresentativeErrorMessages(var TaxRepresentativeVendor: Record Vendor)
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(
          TaxRepresentativeVendor, TaxRepresentativeVendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(
          TaxRepresentativeVendor, TaxRepresentativeVendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertTransmissionIntermediaryErrorMessages(TransmissionIntermediaryVendor: Record Vendor)
    begin
        LibraryErrorMessage.AssertLogIfMessageExists(TransmissionIntermediaryVendor,
          TransmissionIntermediaryVendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        LibraryErrorMessage.AssertLogIfMessageExists(TransmissionIntermediaryVendor,
          TransmissionIntermediaryVendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error);
    end;

    local procedure AssertCurrentElementValue(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; ExpectedValue: Text)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.AreEqual(ExpectedValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName(), ExpectedValue, TempXMLBuffer.Value));
    end;

    local procedure AssertElementDoesNotExist(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath);
        Assert.RecordCount(TempXMLBuffer, 0);
    end;

    local procedure CreateCleanTaxRepresentative(var TaxRepresentativeVendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryPurchase.CreateVendor(TaxRepresentativeVendor);

        CompanyInformation.Get();
        CompanyInformation."Tax Representative No." := TaxRepresentativeVendor."No.";
        CompanyInformation.Modify();
    end;

    local procedure CreateCleanTransmissionIntermediary(var Vendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        CompanyInformation.Get();
        CompanyInformation.Validate("Transmission Intermediary No.", Vendor."No.");
        CompanyInformation.Modify();
    end;

    local procedure CreateServiceHeaderWithoutPaymentInformation(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; DocumentType: Enum "Service Document Type")
    begin
        CreateServiceHeader(ServiceHeader, CustomerNo, DocumentType);
        Clear(ServiceHeader."Payment Method Code");
        Clear(ServiceHeader."Payment Terms Code");
        ServiceHeader.Modify();
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(1, 1000, 2));
        ServiceLine.Modify(true);
        UpdateItemGTIN(ServiceLine."No.", Format(LibraryRandom.RandIntInRange(1000, 2000)));
    end;

    local procedure CreateCommentLineInvoiceWithSplitPayment(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SplitVATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibrarySplitVAT.CreateVATPostingSetupForSplitVAT(
          VATPostingSetup, SplitVATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("VAT Transaction Nature", '');
        VATPostingSetup.Modify(true);
        SplitVATPostingSetup.Validate("VAT %", VATPostingSetup."VAT %");
        SplitVATPostingSetup.Validate("VAT Transaction Nature", VATPostingSetup."VAT Transaction Nature");
        SplitVATPostingSetup.Modify(true);
        LibrarySplitVAT.UpdateVATPostingSetupFullVAT(SplitVATPostingSetup);
        CreateInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.AddSplitVATLines();

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine.Description := DescriptionTxt;
        SalesLine.Modify();
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandIntInRange(100, 100));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandIntInRange(100, 100));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInDecimalRange(154.8801, 154.8801, 4));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandDecInDecimalRange(154.8801, 154.8801, 4));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomerWithCurrencyCode(var Customer: Record Customer; CurrencyCode: Code[20]; VATBusPostingGroupCode: Code[20])
    begin
        Customer.Get(CreateCustomerWithVATBussPostGroup(VATBusPostingGroupCode));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Validate("Payment Method Code", CreatePaymentMethod());
        Customer.Modify(true);
    end;

    local procedure CreateAndPostSalesInvWithCurrencyCode(var DocumentRecordRef: RecordRef; CustomerNo: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        UnitPrice: array[2] of Decimal;
        Quantity: array[2] of Integer;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        for i := 1 to 2 do begin
            UnitPrice[1] := LibraryRandom.RandDecInDecimalRange(3.64, 3.64, 2);
            UnitPrice[2] := LibraryRandom.RandDecInDecimalRange(3.18, 3.18, 2);
            Quantity[1] := LibraryRandom.RandIntInRange(3000, 3000);
            Quantity[2] := LibraryRandom.RandIntInRange(2000, 2000);

            LibrarySales.CreateSalesLineWithShipmentDate(SalesLine[i], SalesHeader, SalesLine[i].Type::"G/L Account", GLAccountNo, WorkDate(), Quantity[i]);
            SalesLine[i].Validate(SalesLine[i]."Unit Price", UnitPrice[i]);
            SalesLine[i].Modify(true);
        end;

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        DocumentRecordRef.GetTable(SalesInvoiceHeader);
        exit(GetDocumentNo(DocumentRecordRef));
    end;

    local procedure VerifyNodeImponibileImporto(TempBlob: Codeunit "Temp Blob")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPart: Record "XML Buffer" temporary;
        LineTotal: array[2] of Decimal;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale');
        TempXMLBufferPart.FindFirst();
        Evaluate(LineTotal[1], TempXMLBufferPart.Value);
        TempXMLBufferPart.FindLast();
        Evaluate(LineTotal[2], TempXMLBufferPart.Value);
        TempXMLBuffer.FindNodesByXPath(TempXMLBufferPart, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DettaglioLinee/PrezzoTotale');
        AssertCurrentElementValue(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiBeniServizi/DatiRiepilogo/ImponibileImporto',
          FormatAmount((LineTotal[1] + LineTotal[2])));
    end;

    local procedure FormatAmountEightDecimalPlaces(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Sign><Integer><Decimals,8><Comma,.>'))
    end;
}

