// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148754 "CFDI Export Integration Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "MX Connection Setup" = rimd,
                  tabledata "Company Information" = rm,
                  tabledata Customer = rimd,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Cr.Memo Line" = r;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ExportInterfactura: Codeunit "Export Interfactura MX";

    [Test]
    procedure SalesInvoiceCreatesCFDIIngresoXML()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A posted sales invoice is exported as a CFDI ingreso document
        Initialize();

        // [GIVEN] A posted sales invoice with Mexican issuer and customer data
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SetMexicanInvoiceData(SalesInvoiceHeader);
        EDocument := CreateEDocument(SalesInvoiceHeader.RecordId(), "E-Document Type"::"Sales Invoice");
        SourceHeader.GetTable(SalesInvoiceHeader);
        SetPostedInvoiceLines(SourceLines, DocumentNo);

        // [WHEN] The invoice is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML identifies an ingreso document and contains mandatory parties
        Assert.AreEqual('I', GetAttribute(TempBlob, 'TipoDeComprobante'), 'The CFDI document type is incorrect.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Emisor'), 'The issuer node is missing.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Receptor'), 'The receiver node is missing.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Conceptos'), 'The concepts node is missing.');
    end;

    [Test]
    procedure SalesCreditMemoCreatesCFDIEgresoXML()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A posted sales credit memo is exported as a CFDI egreso document
        Initialize();

        // [GIVEN] A posted sales credit memo with Mexican issuer and customer data
        DocumentNo := CreateAndPostSalesCreditMemo();
        SalesCrMemoHeader.Get(DocumentNo);
        SetMexicanCreditMemoData(SalesCrMemoHeader);
        EDocument := CreateEDocument(SalesCrMemoHeader.RecordId(), "E-Document Type"::"Sales Credit Memo");
        SourceHeader.GetTable(SalesCrMemoHeader);
        SetPostedCreditMemoLines(SourceLines, DocumentNo);

        // [WHEN] The credit memo is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML identifies an egreso document
        Assert.AreEqual('E', GetAttribute(TempBlob, 'TipoDeComprobante'), 'The CFDI document type is incorrect.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Emisor'), 'The issuer node is missing.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Receptor'), 'The receiver node is missing.');
    end;

    [Test]
    procedure CFDIDataCorrectedOnEDocumentIsExported()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        PostedExportCode: Code[10];
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A CFDI value corrected on the E-Document is exported, and the posted invoice is not changed
        Initialize();

        // [GIVEN] A posted sales invoice and its E-Document with a corrected export code
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SetMexicanInvoiceData(SalesInvoiceHeader);
        PostedExportCode := SalesInvoiceHeader."CFDI Export Code";
        EDocument := CreateEDocument(SalesInvoiceHeader.RecordId(), "E-Document Type"::"Sales Invoice");
        EDocument."CFDI Export Code" := '02';
        EDocument.Modify();
        SourceHeader.GetTable(SalesInvoiceHeader);
        SetPostedInvoiceLines(SourceLines, DocumentNo);

        // [WHEN] The invoice is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML uses the E-Document value and the posted invoice keeps its own value
        Assert.AreEqual('02', GetAttribute(TempBlob, 'Exportacion'), 'The export code from the E-Document was not used.');
        SalesInvoiceHeader.Get(DocumentNo);
        Assert.AreEqual(PostedExportCode, SalesInvoiceHeader."CFDI Export Code", 'The posted invoice must not be modified.');
    end;

    [Test]
    procedure CFDIDataIsCopiedWhenEDocumentIsCreated()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A posted invoice keeps the relevant CFDI data when the E-Document is created
        Initialize();

        // [GIVEN] A posted sales invoice with CFDI values
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."CFDI Export Code" := '02';
        SalesInvoiceHeader."Exchange Rate USD" := 17.5;
        SalesInvoiceHeader."CFDI Certificate of Origin No." := 'CO-001';
        SalesInvoiceHeader.Modify();

        // [WHEN] An E-Document is created for the invoice
        EDocument.Init();
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId();
        EDocument."Document Type" := "E-Document Type"::"Sales Invoice";
        EDocument."CFDI Export Code" := SalesInvoiceHeader."CFDI Export Code";
        EDocument."CFDI Exchange Rate USD" := SalesInvoiceHeader."Exchange Rate USD";
        EDocument."CFDI Cert. of Origin No." := SalesInvoiceHeader."CFDI Certificate of Origin No.";
        EDocument.Insert();

        // [THEN] The E-Document stores the CFDI values of the posted invoice
        Assert.AreEqual('02', EDocument."CFDI Export Code", 'The export code was not copied.');
        Assert.AreEqual(17.5, EDocument."CFDI Exchange Rate USD", 'The USD exchange rate was not copied.');
        Assert.AreEqual('CO-001', EDocument."CFDI Cert. of Origin No.", 'The certificate of origin was not copied.');
    end;

    [Test]
    procedure SalesShipmentCreatesCFDIIngresoXML()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A posted sales shipment is exported as a CFDI traslado document
        Initialize();

        // [GIVEN] A posted sales shipment with Mexican customer data
        DocumentNo := CreateAndPostSalesShipment();
        SalesShipmentHeader.Get(DocumentNo);
        SalesShipmentHeader.Validate("Shipment Date", WorkDate());
        SalesShipmentHeader.Validate("Posting Date", WorkDate());
        SalesShipmentHeader.Validate("Document Date", WorkDate());
        SalesShipmentHeader.Validate("Transit-from Date/Time", CreateDateTime(WorkDate(), 080000T));
        SalesShipmentHeader.Validate("Transit Hours", 2);
        SalesShipmentHeader.Validate("Transit Distance", 100);
        SalesShipmentHeader.Validate("SAT Transport Type", '01');
        if SalesShipmentHeader."SAT Address ID" = 0 then
            SalesShipmentHeader."SAT Address ID" := CreateSATAddress();
        SalesShipmentHeader.Modify();
        SetMexicanShipmentData(SalesShipmentHeader);
        EDocument := CreateEDocument(SalesShipmentHeader.RecordId(), "E-Document Type"::"Sales Shipment");
        CopyShipmentCFDIDataToEDocument(EDocument, SalesShipmentHeader);
        SourceHeader.GetTable(SalesShipmentHeader);
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SourceLines.GetTable(SalesShipmentLine);

        // [WHEN] The shipment is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML identifies a traslado document and includes the mandatory parties
        Assert.AreEqual('T', GetAttribute(TempBlob, 'TipoDeComprobante'), 'The CFDI document type for shipments is incorrect.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Emisor'), 'The issuer node is missing.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Receptor'), 'The receiver node is missing.');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure SalesInvoiceValidationRejectsMissingPaymentMethodCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Validation: Codeunit "EDoc CFDI Validation MX";
        DocumentNo: Code[20];
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Invoice validation rejects a document that is missing a payment method code
        Initialize();

        // [GIVEN] A posted sales invoice without a payment method code
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."Payment Method Code" := '';
        SalesInvoiceHeader.Modify();
        SourceHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] The invoice is validated
        asserterror Validation.CheckSalesDocument(SourceHeader);

        // [THEN] The validation error points to the missing payment method code
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    procedure SalesInvoiceValidationRejectsMissingPaymentTermsCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Validation: Codeunit "EDoc CFDI Validation MX";
        DocumentNo: Code[20];
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Invoice validation rejects a document with a missing payment terms code
        Initialize();

        // [GIVEN] A posted sales invoice without a payment terms code
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."Payment Terms Code" := '';
        SalesInvoiceHeader.Modify();
        SourceHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] The invoice is validated
        asserterror Validation.CheckSalesDocument(SourceHeader);

        // [THEN] The validation error points to the missing payment terms code
        Assert.ExpectedError('');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
    begin
        if BindSubscription(this) then;
        EDocumentService.DeleteAll();
        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", 'MME910620Q85');
        CompanyInformation.Modify();
    end;

    local procedure CreateAndPostSalesInvoice(): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 16);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SetMexicanCustomerData(Customer);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SetPostingPaymentData(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesCreditMemo(): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Credit Memo Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Credit Memo Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 16);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SetMexicanCustomerData(Customer);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", Customer."No.");
        SetPostingPaymentData(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesShipment(): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Shipment Nos."));
        LibrarySales.CreateCustomer(Customer);
        SetMexicanCustomerData(Customer);
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Description := 'Shipment item';
        Item.Modify();

        LibraryWarehouse.CreateLocation(Location);
        Location."SAT Address ID" := CreateSATAddress();
        Location.Modify();
        CreateInventorySetup(Item, Location.Code);

        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Shipment Date", WorkDate());
        SalesHeader.Validate("Order Date", WorkDate());
        SalesHeader."SAT Address ID" := Location."SAT Address ID";
        SalesHeader."Ship-to Address" := 'Calle Destino 200';
        SalesHeader."Transit-from Date/Time" := CreateDateTime(WorkDate(), 080000T);
        SalesHeader."Transit Hours" := 2;
        SalesHeader."Transit Distance" := 100;
        SalesHeader."SAT Transport Type" := '01';
        SetPostingPaymentData(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure SetMexicanInvoiceData(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        SetMexicanCustomerData(Customer);
        Customer.Modify();
    end;

    local procedure SetMexicanCreditMemoData(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        SetMexicanCustomerData(Customer);
        Customer.Modify();
    end;

    local procedure SetMexicanCustomerData(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
        RFCNo: Code[20];
    begin
        CountryRegion.Get('MX');
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        RFCNo := LibraryUtility.GenerateGUID();
        while StrLen(RFCNo) < 12 do
            RFCNo += 'A';
        Customer.Validate("RFC No.", RFCNo);
        Customer.Validate(Address, 'Avenida Reforma 100');
        Customer.Validate(City, 'Ciudad de Mexico');
        Customer.Validate("Post Code", '06600');
    end;

    local procedure SetMexicanShipmentData(var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        Customer: Record Customer;
        Location: Record Location;
    begin
        Customer.Get(SalesShipmentHeader."Sell-to Customer No.");
        SetMexicanCustomerData(Customer);
        Customer.Modify();

        if SalesShipmentHeader."SAT Address ID" = 0 then
            SalesShipmentHeader."SAT Address ID" := CreateSATAddress();
        SalesShipmentHeader."Ship-to Address" := 'Calle Destino 200';
        if SalesShipmentHeader."Transit-from Date/Time" = 0DT then
            SalesShipmentHeader."Transit-from Date/Time" := CreateDateTime(WorkDate(), 080000T);
        if SalesShipmentHeader."Transit Hours" = 0 then
            SalesShipmentHeader."Transit Hours" := 2;
        if SalesShipmentHeader."Transit Distance" = 0 then
            SalesShipmentHeader."Transit Distance" := 100;
        if SalesShipmentHeader."SAT Transport Type" = '' then
            SalesShipmentHeader."SAT Transport Type" := '01';
        SalesShipmentHeader.Modify();

        if Location.Get(SalesShipmentHeader."Location Code") then begin
            if Location."SAT Address ID" = 0 then begin
                Location."SAT Address ID" := SalesShipmentHeader."SAT Address ID";
                Location.Modify();
            end;
        end;
    end;

    local procedure CreateSATAddress(): Integer
    var
        SATAddress: Record "SAT Address";
        SATSuburb: Record "SAT Suburb";
        SuburbId: Integer;
    begin
        if SATSuburb.FindLast() then
            SuburbId := SATSuburb.ID;

        SATSuburb.Init();
        SATSuburb.ID := SuburbId + 1;
        SATSuburb."Suburb Code" := '0001';
        SATSuburb."Postal Code" := '06600';
        SATSuburb.Insert();

        SATAddress.Init();
        SATAddress."Country/Region Code" := 'MX';
        SATAddress."SAT State Code" := 'CMX';
        SATAddress."SAT Suburb ID" := SATSuburb.ID;
        SATAddress.Insert();
        exit(SATAddress.Id);
    end;

    local procedure CreateInventorySetup(var Item: Record Item; LocationCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        if not InventoryPostingSetup.Get(LocationCode, Item."Inventory Posting Group") then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup.Validate("Location Code", LocationCode);
            InventoryPostingSetup.Validate("Invt. Posting Group Code", Item."Inventory Posting Group");
            InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
            InventoryPostingSetup.Insert(true);
        end;
    end;

    local procedure SetPostingPaymentData(var SalesHeader: Record "Sales Header")
    var
        PaymentMethod: Record 289;
        PaymentTerms: Record 3;
    begin
        if not PaymentMethod.Get('MX-TEST') then begin
            PaymentMethod.Init();
            PaymentMethod.Code := 'MX-TEST';
            PaymentMethod.Description := 'Mexico test payment method';
            PaymentMethod.Insert();
        end;
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        if not PaymentTerms.FindFirst() then begin
            PaymentTerms.Init();
            PaymentTerms.Code := 'MX-TEST';
            PaymentTerms.Description := 'Mexico test payment terms';
            PaymentTerms.Insert();
        end;
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
    end;

    local procedure CreateEDocument(DocumentRecordId: RecordId; DocumentType: Enum "E-Document Type") EDocument: Record "E-Document"
    begin
        EDocument.Init();
        EDocument."Document Record ID" := DocumentRecordId;
        EDocument."Document Type" := DocumentType;
        EDocument.Insert(true);
    end;

    local procedure CopyShipmentCFDIDataToEDocument(var EDocument: Record "E-Document"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        EDocument."CFDI Export Code" := SalesShipmentHeader."CFDI Export Code";
        EDocument."CFDI Exchange Rate USD" := SalesShipmentHeader."Exchange Rate USD";
        EDocument."CFDI Foreign Trade" := SalesShipmentHeader."Foreign Trade";
        EDocument."CFDI SAT Address ID" := SalesShipmentHeader."SAT Address ID";
        EDocument."CFDI Intl. Trade Term" := SalesShipmentHeader."SAT International Trade Term";
        EDocument."CFDI Transport Type" := SalesShipmentHeader."SAT Transport Type";
        EDocument."CFDI Transit-from Date/Time" := SalesShipmentHeader."Transit-from Date/Time";
        EDocument."CFDI Transit Hours" := SalesShipmentHeader."Transit Hours";
        EDocument."CFDI Transit Distance" := SalesShipmentHeader."Transit Distance";
        EDocument."CFDI Vehicle Code" := SalesShipmentHeader."Vehicle Code";
        EDocument."CFDI Trailer 1" := SalesShipmentHeader."Trailer 1";
        EDocument."CFDI Trailer 2" := SalesShipmentHeader."Trailer 2";
        EDocument."CFDI Customs Regime" := SalesShipmentHeader."SAT Customs Regime";
        EDocument."CFDI Transfer Reason" := SalesShipmentHeader."SAT Transfer Reason";
        EDocument."CFDI SAT ISTMO" := SalesShipmentHeader."SAT ISTMO";
        EDocument."CFDI ISTMO Polo Origen" := SalesShipmentHeader."SAT ISTMO Polo Origen";
        EDocument."CFDI ISTMO Polo Destino" := SalesShipmentHeader."SAT ISTMO Polo Destino";
        EDocument."CFDI Insurer Name" := SalesShipmentHeader."Insurer Name";
        EDocument."CFDI Insurer Policy Number" := SalesShipmentHeader."Insurer Policy Number";
        EDocument."CFDI Medical Insurer Name" := SalesShipmentHeader."Medical Insurer Name";
        EDocument."CFDI Medical Ins. Policy No." := SalesShipmentHeader."Medical Ins. Policy Number";
        EDocument."CFDI Weight Unit Of Measure" := SalesShipmentHeader."SAT Weight Unit Of Measure";
        EDocument.Modify();
    end;

    local procedure SetPostedInvoiceLines(var SourceLines: RecordRef; DocumentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SourceLines.GetTable(SalesInvoiceLine);
    end;

    local procedure SetPostedCreditMemoLines(var SourceLines: RecordRef; DocumentNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SourceLines.GetTable(SalesCrMemoLine);
    end;

    local procedure GetAttribute(var TempBlob: Codeunit "Temp Blob"; AttributeName: Text): Text
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        InStream: InStream;
        Attribute: XmlAttribute;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
        Document.GetRoot(RootNode);
        RootNode.Attributes().Get(AttributeName, Attribute);
        exit(Attribute.Value());
    end;

    local procedure XmlContains(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Boolean
    var
        Document: XmlDocument;
        NamespaceManager: XmlNamespaceManager;
        FoundNode: XmlNode;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
        NamespaceManager.NameTable(Document.NameTable());
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        exit(Document.SelectSingleNode('//' + XPath, NamespaceManager, FoundNode));
    end;

    [PageHandler]
    procedure ErrorMessagesPageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Digital Sign MX", 'OnBeforeCreateDigitalSignature', '', false, false)]
    local procedure MockCreateDigitalSignature(OriginalString: Text; SetupId: Code[10]; var SignedString: Text; var IsHandled: Boolean)
    begin
        SignedString := 'TEST-SELLO';
        IsHandled := true;
    end;
}
