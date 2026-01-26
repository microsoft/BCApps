codeunit 144002 "MX CFDI 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CFDI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryCFDI: Codeunit "Library - CFDI";
        IsInitialized: Boolean;
        CFDIExportCodeGlobal: Code[10];
        CFDIPurposeGlobal: Code[10];
        CFDIRelationGlobal: Code[10];
        PaymentMethodCodeGlobal: Code[10];
        PaymentTermsCodeGlobal: Code[10];
        ResponseOption: Option Success,Error;
        EInvSendAction: Option "Request Stamp",Send,"Request Stamp and Send",Cancel;
        NamespaceCFD4Txt: Label 'http://www.sat.gob.mx/cfd/4';
        NamespacePagos20: Label 'http://www.sat.gob.mx/Pagos20';
        SchemaLocationCFD4Txt: Label 'http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd';
        NamespaceCCE20Txt: Label 'http://www.sat.gob.mx/ComercioExterior20';
        OptionNotSupportedErr: Label 'Option not supported by test function.';

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure CertificadoOrigenWhenCertificateNumberNotSet()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 564932] CertificadoOrigen and NumCertificadoOrigen when CFDI Certificate of Origin No. is not set.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade and empty CFDI Certificate of Origin No.
        CreateSalesDocForeignTrade(SalesHeader, Enum::"Sales Document Type"::Invoice);
        UpdateCFDICertOfOriginNoOnSalesDoc(SalesHeader, '');
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Request Stamp Sales Invoice
        RequestStamp(DATABASE::"Sales Invoice Header", PostedDocumentNo, ResponseOption::Success, EInvSendAction::"Request Stamp");

        // [THEN] CertificadoOrigen is 0 and NumCertificadoOrigen does not exist in XML document.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.CalcFields("Original Document XML");
        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'CertificadoOrigen', '0');
        LibraryXPathXMLReader.VerifyAttributeAbsence('cfdi:Complemento/cce20:ComercioExterior', 'NumCertificadoOrigen');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure CertificadoOrigenWhenCertificateNumberSet()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
        CertificateOfOriginNo: Text[50];
    begin
        // [SCENARIO 564932] CertificadoOrigen and NumCertificadoOrigen when CFDI Certificate of Origin No. is set.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Foreign Trade and CFDI Certificate of Origin No. "CO001".
        CreateSalesDocForeignTrade(SalesHeader, Enum::"Sales Document Type"::Invoice);
        CertificateOfOriginNo := LibraryUtility.GenerateGUID();
        UpdateCFDICertOfOriginNoOnSalesDoc(SalesHeader, CertificateOfOriginNo);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Request Stamp Sales Invoice
        RequestStamp(DATABASE::"Sales Invoice Header", PostedDocumentNo, ResponseOption::Success, EInvSendAction::"Request Stamp");

        // [THEN] CertificadoOrigen is 1 and NumCertificadoOrigen is "CO001" in XML document.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.CalcFields("Original Document XML");
        InitXMLReaderForSalesDocumentCCE(SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'CertificadoOrigen', '1');
        LibraryXPathXMLReader.VerifyAttributeValue('cfdi:Complemento/cce20:ComercioExterior', 'NumCertificadoOrigen', CertificateOfOriginNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure BaseDRAndImporteDRWhenInvoiceInFCYAndPartialPaymentInLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        PostedInvoiceNo: Code[20];
        PaymentDocNo: Code[20];
        InvoiceDate: Date;
        InvAmountExclVAT: Decimal;
        InvAmountInclVAT: Decimal;
        PaymentExchRateAmt: Decimal;
        PaymentAmount: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentVATBase: Decimal;
        PaymentVATAmount: Decimal;
    begin
        // [SCENARIO 581460] BaseDR and ImporteDR attribute values when invoice is in FCY and partial payment is done in LCY.
        Initialize();

        // [GIVEN] Currency AAA with Exchange Rate 20 at Work Date - 10 days and Exchange Rate 25 at Work Date.
        InvoiceDate := WorkDate() - 10;
        PaymentExchRateAmt := 1 / 25;
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        LibraryERM.CreateExchangeRate(CurrencyCode, InvoiceDate, 1 / 20, 1 / 20);
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), PaymentExchRateAmt, PaymentExchRateAmt);

        // [GIVEN] Posted Sales Invoice with Amount 1000 in AAA currency with Posting Date = Work Date - 10 days. VAT is 20%, Amount Including VAT is 1200.
        CreateSalesHeaderForCustomer(SalesHeader, Enum::"Sales Document Type"::Invoice, CreateCustomer());
        UpdatePostingDateOnSalesHeader(SalesHeader, InvoiceDate);
        UpdateCurrencyCodeOnSalesHeader(SalesHeader, CurrencyCode);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 20);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        InvAmountExclVAT := SalesHeader.Amount;
        InvAmountInclVAT := SalesHeader."Amount Including VAT";
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Posted Customer Payment with Amount LCY = 300 * 25 = 7500 in local currency with Posting Date = Work Date.
        PaymentAmount := 300;
        PaymentAmountLCY := PaymentAmount / PaymentExchRateAmt;
        PaymentDocNo := CreateAndPostPayment(SalesHeader."Sell-to Customer No.", -PaymentAmountLCY, '', PostedInvoiceNo);

        // [WHEN] Request Stamp Customer Payment.
        RequestStamp(Database::"Cust. Ledger Entry", PaymentDocNo, ResponseOption::Success, EInvSendAction::"Request Stamp");

        // [THEN] BaseDR attribute contains VAT Base for payment with value (300 / 1200) * 1000 = 250.00
        // [THEN] ImporteDR attribute contains VAT Amount for payment with value (300 / 1200) * 200 = 50.00
        PaymentVATBase := Round(PaymentAmount / InvAmountInclVAT * InvAmountExclVAT);
        PaymentVATAmount := Round(PaymentAmount / InvAmountInclVAT * (InvAmountInclVAT - InvAmountExclVAT));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentDocNo);
        CustLedgerEntry.CalcFields("Original Document XML");
        InitXMLReaderForPayment(CustLedgerEntry);
        LibraryXPathXMLReader.VerifyAttributeValue(
            'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado/pago20:ImpuestosDR/pago20:TrasladosDR/pago20:TrasladoDR', 'BaseDR', FormatDecimal(PaymentVATBase, 2));
        LibraryXPathXMLReader.VerifyAttributeValue(
            'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado/pago20:ImpuestosDR/pago20:TrasladosDR/pago20:TrasladoDR', 'ImporteDR', FormatDecimal(PaymentVATAmount, 2));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure BaseDRAndImporteDRWhenInvoiceAndPartialPaymentInLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedInvoiceNo: Code[20];
        PaymentDocNo: Code[20];
        InvAmountExclVAT: Decimal;
        InvAmountInclVAT: Decimal;
        PaymentAmount: Decimal;
        PaymentVATBase: Decimal;
        PaymentVATAmount: Decimal;
    begin
        // [SCENARIO 581460] BaseDR and ImporteDR attribute values when invoice and partial payment are in LCY.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount 1000 in local currency. VAT is 20%, Amount Including VAT is 1200.
        CreateSalesHeaderForCustomer(SalesHeader, Enum::"Sales Document Type"::Invoice, CreateCustomer());
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), 1, 20);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        InvAmountExclVAT := SalesHeader.Amount;
        InvAmountInclVAT := SalesHeader."Amount Including VAT";
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Posted Customer Payment with Amount 300 in local currency.
        PaymentAmount := 300;
        PaymentDocNo := CreateAndPostPayment(SalesHeader."Sell-to Customer No.", -PaymentAmount, '', PostedInvoiceNo);

        // [WHEN] Request Stamp Customer Payment.
        RequestStamp(Database::"Cust. Ledger Entry", PaymentDocNo, ResponseOption::Success, EInvSendAction::"Request Stamp");

        // [THEN] BaseDR attribute contains VAT Base for payment with value (300 / 1200) * 1000 = 250.00
        // [THEN] ImporteDR attribute contains VAT Amount for payment with value (300 / 1200) * 200 = 50.00
        PaymentVATBase := Round(PaymentAmount / InvAmountInclVAT * InvAmountExclVAT);
        PaymentVATAmount := Round(PaymentAmount / InvAmountInclVAT * (InvAmountInclVAT - InvAmountExclVAT));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentDocNo);
        CustLedgerEntry.CalcFields("Original Document XML");
        InitXMLReaderForPayment(CustLedgerEntry);
        LibraryXPathXMLReader.VerifyAttributeValue(
            'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado/pago20:ImpuestosDR/pago20:TrasladosDR/pago20:TrasladoDR', 'BaseDR', FormatDecimal(PaymentVATBase, 2));
        LibraryXPathXMLReader.VerifyAttributeValue(
            'cfdi:Complemento/pago20:Pagos/pago20:Pago/pago20:DoctoRelacionado/pago20:ImpuestosDR/pago20:TrasladosDR/pago20:TrasladoDR', 'ImporteDR', FormatDecimal(PaymentVATAmount, 2));
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        CFDIExportCodeGlobal := LibraryCFDI.CreateCFDIExportCode();
        CFDIPurposeGlobal := LibraryCFDI.CreateCFDIPurpose();
        CFDIRelationGlobal := LibraryCFDI.CreateCFDIRelation();
        PaymentMethodCodeGlobal := LibraryCFDI.CreatePaymentMethodForSAT();
        PaymentTermsCodeGlobal := LibraryCFDI.CreatePaymentTermsForSAT();

        SetupCFDI();
        LibraryCFDI.SetupCompanyInformation();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        LibraryCFDI.PopulateSATInformation();

        isInitialized := true;
        Commit();
    end;

    local procedure SetupCFDI()
    var
        PACWebServiceCode: Code[10];
    begin
        PACWebServiceCode := LibraryCFDI.CreatePACService();
        LibraryCFDI.InitGLSetup(PACWebServiceCode);
        LibraryCFDI.SetupReportSelection();
    end;

    local procedure CreateSalesDocForeignTrade(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderForCustomer(SalesHeader, DocumentType, CreateCustomer());
        UpdateForeignTradeOnSalesHeader(SalesHeader);
        CreateSalesLineItem(SalesLine, SalesHeader, CreateItem(), LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(10, 20));
        UpdateForeingTradeOnSalesLine(SalesLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Validate("RFC No.", LibraryCFDI.GetRFCNo());
        Customer.Validate("Country/Region Code", GetCountryRegion());
        Customer."SAT Tax Regime Classification" :=
            LibraryUtility.GenerateRandomCode(Customer.FieldNo("SAT Tax Regime Classification"), DATABASE::Customer);
        Customer.Validate("CFDI Export Code", CFDIExportCodeGlobal);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCodeGlobal);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCodeGlobal);
        SalesHeader.Validate("Bill-to Address", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("Bill-to Post Code", SalesHeader."Sell-to Customer No.");
        SalesHeader.Validate("CFDI Purpose", CFDIPurposeGlobal);
        SalesHeader.Validate("CFDI Relation", CFDIRelationGlobal);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; VATPct: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetup(SalesHeader."VAT Bus. Posting Group", VATPct));
        SalesLine.Validate(Description, SalesLine."No.");
        SalesLine."SAT Customs Document Type" := '02';
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostPayment(CustomerNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; AppliesToDocNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Payment Method Code", PaymentMethodCodeGlobal);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATPct: Decimal): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("CFDI VAT Exemption", false);
        VATPostingSetup.Validate("CFDI Non-Taxable", false);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateItem(): Code[20]
    begin
        exit(CreateItemWithPrice(LibraryRandom.RandDecInRange(1000, 2000, 2) * 2));
    end;

    local procedure CreateItemWithPrice(UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATClassification: Record "SAT Classification";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Gross Weight", LibraryRandom.RandIntInRange(5, 10));
        Item."SAT Item Classification" := LibraryUtility.GenerateRandomCode(Item.FieldNo("SAT Item Classification"), DATABASE::Item);
        Item."SAT Material Type" := '01';
        Item.Modify(true);
        SATClassification."SAT Classification" := Item."SAT Item Classification";
        SATClassification."Hazardous Material Mandatory" := true;
        SATClassification.Insert();
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        SATUnitOfMeasure.Next(LibraryRandom.RandInt(SATUnitOfMeasure.Count()));
        UnitOfMeasure."SAT UofM Classification" := SATUnitOfMeasure."SAT UofM Code";
        UnitOfMeasure."SAT Customs Unit" := SATUnitOfMeasure."SAT UofM Code";
        UnitOfMeasure.Modify();
        exit(Item."No.");
    end;

    local procedure CreateSATAddress(): Integer
    var
        SATAddress: Record "SAT Address";
        SATState: Record "SAT State";
        SATLocality: Record "SAT Locality";
        SATMunicipality: Record "SAT Municipality";
        SATSuburb: Record "SAT Suburb";
    begin
        SATAddress.Init();
        SATState.Next(LibraryRandom.RandInt(SATState.Count()));
        SATMunicipality.Next(LibraryRandom.RandInt(SATMunicipality.Count()));
        SATLocality.Next(LibraryRandom.RandInt(SATLocality.Count()));
        SATSuburb.Next(LibraryRandom.RandInt(SATSuburb.Count()));
        SATAddress."SAT State Code" := SATState.Code;
        SATAddress."SAT Municipality Code" := SATMunicipality.Code;
        SATAddress."SAT Locality Code" := SATLocality.Code;
        SATAddress."SAT Suburb ID" := SATSuburb.ID;
        SATAddress."Country/Region Code" := 'TEST';
        SATAddress.Insert();
        exit(SATAddress.Id);
    end;

    local procedure FormatDecimal(InputValue: Decimal; DecimalPlaces: Integer): Text
    begin
        exit(Format(Abs(InputValue), 0, '<Precision,' + Format(DecimalPlaces) + ':' + Format(DecimalPlaces) + '><Standard Format,1>'));
    end;

    local procedure GetCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.FindFirst();
        CountryRegion."SAT Country Code" := CountryRegion.Code; // Foreign
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure InitXMLReaderForSalesDocumentCCE(RecordVariant: Variant; FieldNo: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(RecordVariant, FieldNo);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', NamespaceCFD4Txt);
        LibraryXPathXMLReader.AddAdditionalNamespace('cce20', NamespaceCCE20Txt);
    end;

    local procedure InitXMLReaderForPayment(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.FromRecord(CustLedgerEntry, CustLedgerEntry.FieldNo("Original Document XML"));
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cfdi', NamespaceCFD4Txt);
        LibraryXPathXMLReader.AddAdditionalNamespace('pago20', NamespacePagos20);
    end;

    local procedure RequestStamp(TableNo: Integer; PostedDocumentNo: Code[20]; Response: Option; DocAction: Option)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
    begin
        MockRequestStamp(Response, TempBlob, NamespaceCFD4Txt, SchemaLocationCFD4Txt);
        if not (TableNo in [DATABASE::"Sales Shipment Header", DATABASE::"Transfer Shipment Header"]) then
            LibraryVariableStorage.Enqueue(DocAction);
        case TableNo of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.Modify(true);
                    SalesInvoiceHeader.RequestStampEDocument();
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.Modify(true);
                    SalesCrMemoHeader.RequestStampEDocument();
                end;
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceInvoiceHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceInvoiceHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.Modify(true);
                    ServiceInvoiceHeader.RequestStampEDocument();
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(ServiceCrMemoHeader);
                    TempBlob.ToRecordRef(RecordRef, ServiceCrMemoHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.Modify(true);
                    ServiceCrMemoHeader.RequestStampEDocument();
                end;
            DATABASE::"Sales Shipment Header":
                begin
                    SalesShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(SalesShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, SalesShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(SalesShipmentHeader);
                    SalesShipmentHeader.Modify(true);
                    SalesShipmentHeader.RequestStampEDocument();
                end;
            DATABASE::"Transfer Shipment Header":
                begin
                    TransferShipmentHeader.Get(PostedDocumentNo);
                    RecordRef.GetTable(TransferShipmentHeader);
                    TempBlob.ToRecordRef(RecordRef, TransferShipmentHeader.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(TransferShipmentHeader);
                    TransferShipmentHeader.Modify(true);
                    TransferShipmentHeader.RequestStampEDocument();
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PostedDocumentNo);
                    RecordRef.GetTable(CustLedgerEntry);
                    TempBlob.ToRecordRef(RecordRef, CustLedgerEntry.FieldNo("Signed Document XML"));
                    RecordRef.SetTable(CustLedgerEntry);
                    CustLedgerEntry.Modify();
                    CustLedgerEntry.RequestStampEDocument();
                end;
        end;
    end;

    local procedure MockRequestStamp(Response: Option; var TempBlob: Codeunit "Temp Blob"; NamespaceCFD: Text; SchemaLocationCFD: Text)
    begin
        if Response = ResponseOption::Success then
            MockSuccessRequestStamp(TempBlob, NamespaceCFD, SchemaLocationCFD)
        else
            MockFailure(TempBlob);
    end;

    local procedure MockFailure(var TempBlob: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="Sello del Emisor No Valido" IdRespuesta="302" />');
    end;

    local procedure MockSuccessRequestStamp(var TempBlob: Codeunit "Temp Blob"; NamespaceCFD: Text; SchemaLocationCFD: Text)
    var
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('<Resultado Descripcion="OK" IdRespuesta="1" >');
        OutStream.WriteText(CopyStr(StrSubstNo('  <cfdi:Comprobante xsi:schemaLocation="%1 %2"', NamespaceCFD, SchemaLocationCFD), 1, 1024));
        OutStream.WriteText(' version="3.0" xmlns="" fecha="2011-11-08T09:02:03" formaDePago="Pago en una sola exhibici');
        OutStream.WriteText('on" noCertificado="30001000000100000800" certificado="MIIE/TCCA+WgAwIBAgIUMzAwMDEwMDAwMDAxMDAwMDA4MDAwDQYJKoZIhvcNAQE');
        OutStream.WriteText('FBQAwggFvMRgwFgYDVQQDDA9BLkMuIGRlIHBydWViYXMxLzAtBgNVBAoMJlNlcnZpY2lvIGRlIEFkbWl');
        OutStream.WriteText('uaXN0cmFjacOzbiBUcmlidXRhcmlhMTgwNgYDVQQLDC9BZG1pbmlzdHJhY2nDs2');
        OutStream.WriteText('4gZGUgU2VndXJpZGFkIGRlIGxhIEluZm9ybWFjacOzbjEpMCcGCSqGSIb3DQEJARYaYXNpc25ldEBwcnVlYmFzLnNhdC5nb2IubXgxJjAkBgNVBAkMHUF2');
        OutStream.WriteText('LiBIaWRhbGdvIDc3LCBDb2wuIEd1ZXJyZXJvMQ4wDAYDVQQRDAUwNjMwMDELMAkGA1UEBhMCTVgxGTA');
        OutStream.WriteText('XBgNVBAgMEERpc3RyaXRvIEZlZGVyYWwxEjAQBgNVBAcMCUNveW9hY8OhbjEVMBMGA1UELRMMU0FUOTcwNzAxTk4zMTIwMAYJKoZIhvcNAQkCDCNSZXNwb2');
        OutStream.WriteText('5zYWJsZTogSMOpY3RvciBPcm5lbGFzIEFyY2lnYTAeFw0xMDA3MzAxNjU4NDBaFw0xMjA3MjkxNjU4');
        OutStream.WriteText('NDBaMIGWMRIwEAYDVQQDDAlNYXRyaXogU0ExEjAQBgNVBCkMCU1hdHJpeiBTQTESMBAGA1UECgwJTWF0cml6IFNBMSUwIwYDVQQtExxBQUEwMTAxMDFBQUE');
        OutStream.WriteText('gLyBBQUFBMDEwMTAxQUFBMR4wHAYDVQQFExUgLyBBQUFBMDEwMTAxSERGUlhYMDExETAPBgNVBAsMC');
        OutStream.WriteText('FVuaWRhZCAxMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDD0ltQNthUNUfzq0t1GpIyapjzOn1W5fGM5G/pQyMluCzP9YlVAgBjGgzwYp9Z0J9gadg3y');
        OutStream.WriteText('2ZrYDwvv8b72goyRnhnv3bkjVRKlus6LDc00K7Jl23UYzNGlXn5+i0HxxuWonc2GYKFGsN4rFWKVy');
        OutStream.WriteText('3Fnpv8Z2D7dNqsVyT5HapEqwIDAQABo4HqMIHnMAwGA1UdEwEB/wQCMAAwCwYDVR0PBAQDAgbAMB0GA1UdDgQWBBSYodSwRczzj5H7mcO3+mAyXz+y0DAuBgN');
        OutStream.WriteText('VHR8EJzAlMCOgIaAfhh1odHRwOi8vcGtpLnNhdC5nb2IubXgvc2F0LmNybDAzBggrBgEFBQcBAQQ');
        OutStream.WriteText('nMCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNhdC5nb2IubXgvMB8GA1UdIwQYMBaAFOtZfQQimlONnnEaoFiWKfU54KDFMBAGA1UdIAQJMAc');
        OutStream.WriteText('wBQYDKgMEMBMGA1UdJQQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBBQUAA4IBAQArHQEorApwqumSn5EqDOAjbezi8fLco1cYES/PD+LQRM1Vb1g7VLE3hR4S');
        OutStream.WriteText('5NNBv0bMwwWAr0WfL9lRRj0PMKLorO8y4TJjRU8MiYXfzSuKYL5Z16kW8zlVHw7CtmjhfjoIMwjQ');
        OutStream.WriteText('o3prifWxFv7VpfIBstKKShU0qB6KzUUNwg2Ola4t4gg2JJcBmyIAIInHSGoeinR2V1tQ10aRqJdXkGin4WZ75yMbQH4L0NfotqY6bp');
        OutStream.WriteText('F2CqIY3aogQyJGhUJji4gYnS2DvHcyoICwgawshjSaX8Y0Xlwnuh6EusqhqlhTgwPNAPrKIXCmOWtqjlDhho/lhkHJMzuTn8AoVapbBUnj" condicionesDe');
        OutStream.WriteText('Pago="30 DIAS" subTotal="250.000000" total="287.500000" metodoDePago="CHEQUE');
        OutStream.WriteText('" tipoDeComprobante="ingreso" sello="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3POT5BqHM7NYILVFs+KaqnO');
        OutStream.WriteText('msM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE');
        OutStream.WriteText(CopyStr(StrSubstNo('4p4TcOf5qsE=" xmlns:cfdi="%1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">', NamespaceCFD), 1, 1024));
        OutStream.WriteText('    <cfdi:Emisor rfc="SWC920404DA3" nombre="CARGILL MEXICO">');
        OutStream.WriteText('      <cfdi:DomicilioFiscal calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" localidad="MONTERREY" municipio="VALLE DEL CAMPE');
        OutStream.WriteText('STRE" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('      <cfdi:ExpedidoEn calle="AVE ROBLE 525" colonia="VALLE DEL CAMPESTRE" municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="MONTERREY" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Emisor>');
        OutStream.WriteText('    <cfdi:Receptor rfc="123456789123" nombre="AVE ROBLE">');
        OutStream.WriteText('      <cfdi:Domicilio calle="AVE ROBLE" colonia="VALLE DEL CAMPESTRE" municipio="VALLE DEL CAMPESTRE" ');
        OutStream.WriteText('localidad="SAN PEDRO" estado="NL" pais="MEXICO" codigoPostal="66230" />');
        OutStream.WriteText('    </cfdi:Receptor>');
        OutStream.WriteText('    <cfdi:Conceptos>');
        OutStream.WriteText('      <cfdi:Concepto cantidad="1.000000" ');
        OutStream.WriteText('descripcion="AP-BL-412 - CALCULADORA" valorUnitario="250.000000" importe="250.000000" />');
        OutStream.WriteText('    </cfdi:Conceptos>');
        OutStream.WriteText('    <cfdi:Impuestos totalImpuestosRetenidos="0.000000" totalImpuestosTrasladados="37.500000">');
        OutStream.WriteText('      <cfdi:Traslados>');
        OutStream.WriteText('        <cfdi:Traslado impuesto="IVA" tasa="15.000000" importe="37.500000" />');
        OutStream.WriteText('      </cfdi:Traslados>');
        OutStream.WriteText('    </cfdi:Impuestos>');
        OutStream.WriteText(CopyStr(StrSubstNo('    <cfdi:Complemento xmlns:cfdi="%1" xmlns="">', NamespaceCFD), 1, 1024));
        OutStream.WriteText('      <tfd:TimbreFiscalDigital version="1.0" UUID="9CDBDABD-9399-4DA1-8409-D1B70C5BA4DD" FechaTimbrado="2011-11-08T07:45:56" ');
        OutStream.WriteText('selloCFD="UjFPBbIfOXXlMsVgqeayMUi4gbp291Nwd0vn1e4DRkzjz3Nw3ZXno1jJNXlTdR3');
        OutStream.WriteText('POT5BqHM7NYILVFs+KaqnOmsM/05UsapfnTtneGIraoU/F2o4rQvg823nr/l61Cadl0nEm73btQiBhtq/4MrGLiUCGdAvcMiE4p4TcOf5qsE=" NoCertificadoSAT');
        OutStream.WriteText('="30001000000100000801" SelloSAT="WDTveFcG+ANYGdjrNrDcpYGdz4p0XsH5C0UTs');
        OutStream.WriteText('qcMM/dSe4MGGnsacrJ75DAT5B5KqZWSefkGeg/sG7i6K3+lZTEuxje+rBDAp/4fMfYeL2TTMLpkU6Oy1zl/N6ywt38Z2+WTwcBIuIkEY54e+mW+zkyJLAxkeDGJHAwEBd');
        OutStream.WriteText('f2nu0=" xsi:schemaLocation="http://www.sat.gob.mx/TimbreFiscalDigital');
        OutStream.WriteText(' http://www.sat.gob.mx/TimbreFiscalDigital/TimbreFiscalDigital.xsd" xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" />');
        OutStream.WriteText('    </cfdi:Complemento>');
        OutStream.WriteText('  </cfdi:Comprobante>');
        OutStream.WriteText('</Resultado>');
    end;

    local procedure UpdateForeignTradeOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        SATInternationalTradeTerm: Record "SAT International Trade Term";
        Location: Record Location;
    begin
        SATInternationalTradeTerm.Next(LibraryRandom.RandInt(SATInternationalTradeTerm.Count()));
        SalesHeader.Validate("Foreign Trade", true);
        SalesHeader.Validate("SAT International Trade Term", SATInternationalTradeTerm.Code);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader."SAT Address ID" := CreateSATAddress();
        SalesHeader.Modify(true);
        UpdateLocationForCartaPorte(SalesHeader."Location Code");
    end;

    local procedure UpdateCurrencyCodeOnSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    begin
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePostingDateOnSalesHeader(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateForeingTradeOnSalesLine(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        SATCustomsUnit: Record "SAT Customs Unit";
    begin
        Item.Get(SalesLine."No.");
        Item."Tariff No." := LibraryUtility.GenerateGUID();
        Item.Modify();
        SATCustomsUnit.Next(LibraryRandom.RandInt(SATCustomsUnit.Count()));
        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        UnitOfMeasure."SAT Customs Unit" := SATCustomsUnit.Code;
        UnitOfMeasure.Modify();
    end;

    local procedure UpdateLocationForCartaPorte(LocationCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location."SAT Address ID" := CreateSATAddress();
        Location.Address := LibraryUtility.GenerateGUID();
        Location."Country/Region Code" := 'TEST';
        Location.Modify();
    end;

    local procedure UpdateCFDICertOfOriginNoOnSalesDoc(var SalesHeader: Record "Sales Header"; CertificateOfOriginNo: Text[50])
    begin
        SalesHeader.Validate("CFDI Certificate of Origin No.", CertificateOfOriginNo);
        SalesHeader.Modify(true);
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        Value: Variant;
        "Action": Option;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Action := Value;
        case Action of
            EInvSendAction::"Request Stamp":
                Choice := 1;
            EInvSendAction::Send:
                Choice := 2;
            EInvSendAction::"Request Stamp and Send":
                Choice := 3;
            else
                Error(OptionNotSupportedErr);
        end;
    end;
}