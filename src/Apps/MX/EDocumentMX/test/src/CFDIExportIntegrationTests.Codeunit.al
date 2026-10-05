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
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "MX Connection Setup" = rimd,
                  tabledata "Company Information" = rm,
                  tabledata Customer = rimd,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Cr.Memo Line" = r;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
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

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
    begin
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
}
