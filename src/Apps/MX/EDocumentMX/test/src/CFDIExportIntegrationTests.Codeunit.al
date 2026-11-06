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
using Microsoft.Foundation.Reporting;
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
                  tabledata "E-Doc. Service Supported Type" = rimd,
                  tabledata "Document Sending Profile" = rimd,
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
        CFDIServiceCodeTok: Label 'MX-CFDI-TEST', Locked = true;

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
        EDocument := CreateEDocumentThroughExport(SalesInvoiceHeader.RecordId(), "E-Document Type"::"Sales Invoice");
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
        EDocument := CreateEDocumentThroughExport(SalesCrMemoHeader.RecordId(), "E-Document Type"::"Sales Credit Memo");
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
        EDocument := CreateEDocumentThroughExport(SalesInvoiceHeader.RecordId(), "E-Document Type"::"Sales Invoice");
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
        // [SCENARIO] Creating the E-Document for a posted invoice copies the relevant CFDI data from the invoice
        Initialize();

        // [GIVEN] A posted sales invoice with CFDI values
        DocumentNo := CreateAndPostSalesInvoice();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."CFDI Export Code" := '02';
        SalesInvoiceHeader."Exchange Rate USD" := 17.5;
        SalesInvoiceHeader."CFDI Certificate of Origin No." := 'CO-001';
        SalesInvoiceHeader."Foreign Trade" := true;
        SalesInvoiceHeader."SAT International Trade Term" := 'FOB';
        SalesInvoiceHeader.Modify();

        // [WHEN] The E-Document is created for the invoice through the E-Document export
        EDocument := CreateEDocumentThroughExport(SalesInvoiceHeader.RecordId(), "E-Document Type"::"Sales Invoice");

        // [THEN] The E-Document stores the CFDI values of the posted invoice
        Assert.AreEqual('02', EDocument."CFDI Export Code", 'The export code was not copied.');
        Assert.AreEqual(17.5, EDocument."CFDI Exchange Rate USD", 'The USD exchange rate was not copied.');
        Assert.AreEqual('CO-001', EDocument."CFDI Cert. of Origin No.", 'The certificate of origin was not copied.');
        Assert.IsTrue(EDocument."CFDI Foreign Trade", 'The foreign trade flag was not copied.');
        Assert.AreEqual('FOB', EDocument."CFDI Intl. Trade Term", 'The international trade term was not copied.');
    end;

    [Test]
    procedure CartaPorteDataIsCopiedWhenEDocumentIsCreated()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        EDocument: Record "E-Document";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Creating the E-Document for a posted shipment copies the Carta Porte data from the shipment
        Initialize();

        // [GIVEN] A posted sales shipment with Carta Porte values
        DocumentNo := CreateAndPostSalesShipment();
        SalesShipmentHeader.Get(DocumentNo);
        SetMexicanShipmentData(SalesShipmentHeader);
        SalesShipmentHeader."SAT Customs Regime" := 'EXD';
        SalesShipmentHeader.Modify();

        // [WHEN] The E-Document is created for the shipment through the E-Document export
        EDocument := CreateEDocumentThroughExport(SalesShipmentHeader.RecordId(), "E-Document Type"::"Sales Shipment");

        // [THEN] The E-Document stores the Carta Porte values of the posted shipment
        Assert.AreEqual(SalesShipmentHeader."Transit-from Date/Time", EDocument."CFDI Transit-from Date/Time", 'The transit start date/time was not copied.');
        Assert.AreEqual(SalesShipmentHeader."Transit Hours", EDocument."CFDI Transit Hours", 'The transit hours were not copied.');
        Assert.AreEqual(SalesShipmentHeader."Transit Distance", EDocument."CFDI Transit Distance", 'The transit distance was not copied.');
        Assert.AreEqual(SalesShipmentHeader."SAT Transport Type", EDocument."CFDI Transport Type", 'The transport type was not copied.');
        Assert.AreEqual(SalesShipmentHeader."SAT Address ID", EDocument."CFDI SAT Address ID", 'The SAT address was not copied.');
        Assert.AreEqual('EXD', EDocument."CFDI Customs Regime", 'The customs regime was not copied.');
    end;

    [Test]
    procedure SalesShipmentCreatesCFDITrasladoXML()
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
        EDocument := CreateEDocumentThroughExport(SalesShipmentHeader.RecordId(), "E-Document Type"::"Sales Shipment");
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
    procedure CartaPorteDataCorrectedOnEDocumentIsExported()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Carta Porte value corrected on the E-Document is exported, and the posted shipment is not changed
        Initialize();

        // [GIVEN] A posted sales shipment with a transit distance of 100 and its E-Document corrected to 250
        DocumentNo := CreateAndPostSalesShipment();
        SalesShipmentHeader.Get(DocumentNo);
        SetMexicanShipmentData(SalesShipmentHeader);
        SalesShipmentHeader."Transit Distance" := 100;
        SalesShipmentHeader.Modify();
        EDocument := CreateEDocumentThroughExport(SalesShipmentHeader.RecordId(), "E-Document Type"::"Sales Shipment");
        EDocument."CFDI Transit Distance" := 250;
        EDocument.Modify();
        SourceHeader.GetTable(SalesShipmentHeader);
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SourceLines.GetTable(SalesShipmentLine);

        // [WHEN] The shipment is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML uses the E-Document value and the posted shipment keeps its own value
        Assert.AreEqual('250.000000', GetCartaPorteAttribute(TempBlob, 'CartaPorte', 'TotalDistRec'), 'The transit distance from the E-Document was not used.');
        SalesShipmentHeader.Get(DocumentNo);
        Assert.AreEqual(100, SalesShipmentHeader."Transit Distance", 'The posted shipment must not be modified.');
    end;

    [Test]
    procedure SalesOrderCreatesCFDIIngresoXML()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        OrderNo: Code[20];
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A sales order is exported as a CFDI ingreso document
        Initialize();

        // [GIVEN] A sales order with Mexican issuer and customer data
        OrderNo := CreateSalesOrder();
        SalesHeader.Get("Sales Document Type"::Order, OrderNo);
        SetMexicanCustomerDataOnSalesHeader(SalesHeader);
        EDocument := CreateEDocumentThroughExport(SalesHeader.RecordId(), "E-Document Type"::"Sales Order");
        SourceHeader.GetTable(SalesHeader);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SourceLines.GetTable(SalesLine);

        // [WHEN] The order is exported
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        // [THEN] The XML identifies a traslado document and contains the mandatory CFDI nodes
        Assert.AreEqual('T', GetAttribute(TempBlob, 'TipoDeComprobante'), 'The CFDI document type for a sales order export is incorrect.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Emisor'), 'The issuer node is missing for the sales order export.');
        Assert.IsTrue(XmlContains(TempBlob, 'cfdi:Receptor'), 'The receiver node is missing for the sales order export.');
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
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if BindSubscription(this) then;
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
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

    local procedure CreateSalesOrder(): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        SetMexicanCustomerData(Customer);
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Description := 'Sales order item';
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

        exit(SalesHeader."No.");
    end;

    local procedure SetMexicanCustomerDataOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesHeader."Sell-to Customer No.");
        SetMexicanCustomerData(Customer);
        Customer.Modify();
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

    local procedure CreateEDocumentThroughExport(DocumentRecordId: RecordId; DocumentType: Enum "E-Document Type") EDocument: Record "E-Document"
    var
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        SourceHeader: RecordRef;
    begin
        CreateCFDIService(EDocumentService);
        SourceHeader.Open(DocumentRecordId.TableNo());
        SourceHeader.Get(DocumentRecordId);
        Assert.IsTrue(EDocExport.CreateEDocument(EDocument, SourceHeader, EDocumentService, DocumentType), 'The E-Document was not created for the source document.');
        EDocument.Reset();
        EDocument.SetRange("Document Record ID", DocumentRecordId);
        EDocument.FindFirst();
    end;

    local procedure CreateCFDIService(var EDocumentService: Record "E-Document Service")
    var
        DocSendingProfile: Record "Document Sending Profile";
    begin
        if not EDocumentService.Get(CFDIServiceCodeTok) then begin
            if not DocSendingProfile.Get(CFDIServiceCodeTok) then begin
                DocSendingProfile.Init();
                DocSendingProfile.Code := CFDIServiceCodeTok;
                DocSendingProfile.Description := 'CFDI Test Profile';
                DocSendingProfile.Default := true;
                DocSendingProfile.Insert();
            end;
            EDocumentService.Init();
            EDocumentService.Code := CFDIServiceCodeTok;
            EDocumentService.Insert();
            EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
            EDocumentService.Modify();
        end;
        EDocumentService.SetRecFilter();
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

    local procedure GetCartaPorteAttribute(var TempBlob: Codeunit "Temp Blob"; ElementName: Text; AttributeName: Text): Text
    var
        Document: XmlDocument;
        NamespaceManager: XmlNamespaceManager;
        FoundNode: XmlNode;
        Attribute: XmlAttribute;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
        NamespaceManager.NameTable(Document.NameTable());
        NamespaceManager.AddNamespace('cartaporte31', 'http://www.sat.gob.mx/CartaPorte31');
        Assert.IsTrue(Document.SelectSingleNode('//cartaporte31:' + ElementName, NamespaceManager, FoundNode), 'The Carta Porte node ' + ElementName + ' is missing.');
        if FoundNode.AsXmlElement().Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());
        exit('');
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
