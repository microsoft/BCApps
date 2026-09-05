// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Service.Test;
using System.Utilities;

codeunit 148147 "PEPPOL BIS 3.0 XML Tests"
{
    Subtype = Test;
    Permissions = tabledata "E-Document Service" = rimd,
                  tabledata "Company Information" = rimd,
                  tabledata "Sales Comment Line" = rimd,
                  tabledata "Service Participant" = rimd,
                  tabledata "Sales Invoice Line" = rimd,
                  tabledata "Sales Shipment Header" = rimd,
                  tabledata "Sales Shipment Line" = rimd,
                  tabledata "Sales & Receivables Setup" = rimd,
                  tabledata Customer = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [PEPPOL BIS 3.0 FR E-document]
    end;

    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        EDocHelpers: Codeunit "EDoc. Helpers";
        PeppolBIS30FRFormat: Codeunit "Peppol BIS 3.0 FR Format";
        IncorrectValueErr: Label 'Incorrect value for %1', Comment = '%1 = XML element path', Locked = true;
        DialogErrorCodeTok: Label 'Dialog', Locked = true;
        IsInitialized: Boolean;

    #region SalesInvoice
    [Test]
    procedure ExportSalesInvInjectsSupplierPartyIdentificationSIRET()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects supplier party identification with SIRET and scheme 0009
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Supplier PartyIdentification contains SIRET with scheme 0009
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Supplier PartyIdentification ID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Supplier PartyIdentification schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsSupplierLegalEntitySIREN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects supplier legal entity company id with Registration No. and scheme 0002
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Supplier PartyLegalEntity CompanyID contains Registration No. with scheme 0002
        Assert.AreEqual(CompanyInformation."Registration No.",
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID'),
            StrSubstNo(IncorrectValueErr, 'Supplier CompanyID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Supplier CompanyID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsSupplierEndpointFromSIRET()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects supplier endpoint from SIRET with scheme 0009
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Supplier EndpointID contains SIRET and scheme 0009
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Supplier EndpointID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Supplier EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerEndpointFromFRElectronicAddress()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects buyer endpoint from FR Electronic Address with scheme 0225
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address
        CustomerAddress := '123456789';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0225")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains FR Electronic Address with scheme 0225
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvUsesBuyerRegistrationNumberFallback()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR uses customer Registration Number as buyer endpoint when FR Electronic Address is blank
        Initialize();

        // [GIVEN] Posted sales invoice for customer with blank FR electronic address but valid Registration Number
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains first 9 digits of Registration Number with scheme 0225
        Assert.AreEqual('123456789',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerEndpointWithSIRENSuffix()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects buyer endpoint with SIREN_suffix value and scheme 0225
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address in SIREN_suffix format
        CustomerAddress := '123456789_001';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0225")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains the SIREN_suffix value with scheme 0225
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvUsesConfiguredSchemeForBuyerEndpoint()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR uses the scheme configured for the customer electronic address
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and configured scheme 0002
        CustomerAddress := '123456789';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0002")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID uses the configured scheme 0002
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));

        // [THEN] Buyer PartyIdentification is not synthesized
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID should be empty'));
    end;

    [Test]
    procedure ExportSalesInvUsesBuyerServiceParticipantScheme()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerNo: Code[20];
        EndpointId: Text[200];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR uses the scheme configured for the service participant
        Initialize();

        // [GIVEN] Customer with service participant using configured scheme 0002
        CustomerNo := CreateCustomer('123456789', "Electronic Address Scheme"::"0002");
        EndpointId := '987654321_ABC';
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := CustomerNo;
        ServiceParticipant."Participant Identifier" := EndpointId;
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::"0002";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        // [WHEN] Export FR PEPPOL XML
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID uses the participant's configured scheme 0002
        Assert.AreEqual(EndpointId,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerLegalEntitySIREN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects the buyer SIREN as the legal registration identifier
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('123456789',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID'),
            StrSubstNo(IncorrectValueErr, 'Buyer CompanyID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer CompanyID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvPreservesConfiguredSIRETScheme()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR preserves a configured SIRET endpoint scheme without synthesizing PartyIdentification
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and configured scheme 0009
        CustomerAddress := '987654321_001';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0009")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID uses the configured scheme 0009
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));

        // [THEN] Buyer PartyIdentification is not synthesized from BT-49
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID should be empty'));
    end;

    [Test]
    procedure ExportSalesInvIncludesRegulatoryCommentAsNote()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CommentText: Text[80];
        OrdinaryCommentText: Text[80];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A French regulatory comment is carried through posting and exported with its type in a UBL header note
        Initialize();

        // [GIVEN] Sales invoice "SI" with an ordinary comment and an AAB regulatory comment
        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        InvoiceNo := CreateSalesInvoiceWithLine(CustomerNo);
        CommentText := 'No discount is granted for early payment.';
        OrdinaryCommentText := 'Ordinary comment that must not be exported';
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Invoice;
        SalesCommentLine."No." := InvoiceNo;
        SalesCommentLine."Line No." := 5000;
        SalesCommentLine.Comment := OrdinaryCommentText;
        SalesCommentLine.Insert();
        SalesCommentLine.Init();
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Invoice;
        SalesCommentLine."No." := InvoiceNo;
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine."FR Regulatory Comment Type" := SalesCommentLine."FR Regulatory Comment Type"::AAB;
        SalesCommentLine.Comment := CommentText;
        SalesCommentLine.Insert();
        SalesHeader.Get("Sales Document Type"::Invoice, InvoiceNo);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Posted sales invoice "SI" is exported in PEPPOL BIS 3.0 FR
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The AAB regulatory comment is exported as a UBL header note
        Assert.AreEqual('#AAB#' + CommentText,
            GetNodeByPath(XmlDoc, '/Invoice/cbc:Note[contains(., ''#AAB#'')]'),
            StrSubstNo(IncorrectValueErr, 'AAB regulatory note'));

        // [THEN] The ordinary comment is not exported as a UBL header note
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cbc:Note[contains(., ''' + OrdinaryCommentText + ''')]'),
            StrSubstNo(IncorrectValueErr, 'Ordinary note should be empty'));
    end;

    [Test]
    procedure ExportSalesInvConcatenatesRegulatoryCommentsOfSameType()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        FirstCommentLine: Text[80];
        SecondCommentLine: Text[80];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Multiple PMD comment lines are concatenated into one tagged UBL note
        Initialize();

        // [GIVEN] Sales invoice "SI" with the mandatory PMD text split across two comment lines
        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        InvoiceNo := CreateSalesInvoiceWithLine(CustomerNo);
        FirstCommentLine := 'Tout retard de paiement engendre une pénalité exigible à compter de la date ';
        SecondCommentLine := 'd''échéance, calculée sur la base de trois fois le taux d''intérêt légal.';
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Invoice;
        SalesCommentLine."No." := InvoiceNo;
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine."FR Regulatory Comment Type" := SalesCommentLine."FR Regulatory Comment Type"::PMD;
        SalesCommentLine.Comment := FirstCommentLine;
        SalesCommentLine.Insert();
        SalesCommentLine.Init();
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::Invoice;
        SalesCommentLine."No." := InvoiceNo;
        SalesCommentLine."Line No." := 20000;
        SalesCommentLine."FR Regulatory Comment Type" := SalesCommentLine."FR Regulatory Comment Type"::PMD;
        SalesCommentLine.Comment := SecondCommentLine;
        SalesCommentLine.Insert();
        SalesHeader.Get("Sales Document Type"::Invoice, InvoiceNo);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Posted sales invoice "SI" is exported in PEPPOL BIS 3.0 FR
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Both lines are concatenated into one PMD note without repeating the tag
        Assert.AreEqual('#PMD#' + FirstCommentLine + SecondCommentLine,
            GetNodeByPath(XmlDoc, '/Invoice/cbc:Note[contains(., ''#PMD#'')]'),
            StrSubstNo(IncorrectValueErr, 'PMD regulatory note'));
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cbc:Note[contains(., ''#PMD#'')][2]'),
            StrSubstNo(IncorrectValueErr, 'Second PMD regulatory note should be empty'));
    end;

    [Test]
    procedure ExportSalesInvDoesNotIncludeBillingReference()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Exporting a sales invoice does not add a credit note billing reference
        Initialize();

        // [GIVEN] Posted sales invoice "SI"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Sales invoice "SI" is exported in PEPPOL BIS 3.0 FR
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The XML does not contain a BillingReference
        Assert.AreEqual('', GetNodeByPath(XmlDoc, '/Invoice/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'BillingReference should be empty'));
    end;

    [Test]
    procedure ExportSalesInvSetsS1ForServiceLines()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] An invoice containing only service lines uses billing mode S1
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('S1', GetNodeByPath(XmlDoc, '/Invoice/cbc:ProfileID'), StrSubstNo(IncorrectValueErr, 'ProfileID'));
    end;

    [Test]
    procedure ExportSalesInvUsesServiceParticipantEndpointWithScheme0225()
    var
        Customer: Record Customer;
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerNo: Code[20];
        EndpointId: Text[200];
    begin
        // [SCENARIO] A service-specific routing identifier overrides the endpoint on the customer card
        Initialize();

        CustomerNo := CreateCustomer('12345678901234', "Electronic Address Scheme"::"0009");
        EndpointId := '123456789_001';
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := CustomerNo;
        ServiceParticipant."Participant Identifier" := EndpointId;
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::"0225";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));
        Customer.Get(CustomerNo);
        Customer.GLN := '';
        Customer."VAT Registration No." := '';
        Customer."FR Electronic Address" := '';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::" ";
        Customer.Modify(true);

        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual(EndpointId,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID'));
    end;

    #endregion

    #region ServiceDocuments
    [Test]
    procedure ExportServiceInvoiceRunsFRValidationAndCreatesXML()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A posted service invoice passes French validation and is exported with its transferred line
        Initialize();

        // [GIVEN] Posted service invoice "SI" for a customer with a French electronic address
        ServiceInvoiceHeader.Get(CreateAndPostServiceInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] The service invoice is checked and exported
        CheckServiceInvoice(ServiceInvoiceHeader);
        ExportServiceInvoice(ServiceInvoiceHeader, XmlDoc);

        // [THEN] The PEPPOL invoice contains the transferred service line
        Assert.AreNotEqual('', GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cbc:ID'), StrSubstNo(IncorrectValueErr, 'Invoice Line ID'));
    end;

    [Test]
    procedure ExportServiceCreditMemoRunsFRValidationAndCreatesXML()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A posted service credit memo passes French validation and is exported with its transferred line
        Initialize();

        // [GIVEN] Posted service credit memo "SCM" for a customer with a French electronic address
        ServiceCrMemoHeader.Get(CreateAndPostServiceCreditMemo(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] The service credit memo is checked and exported
        CheckServiceCreditMemo(ServiceCrMemoHeader);
        ExportServiceCreditMemo(ServiceCrMemoHeader, XmlDoc);

        // [THEN] The PEPPOL credit note contains the transferred service line
        Assert.AreNotEqual('', GetNodeByPath(XmlDoc, '/CreditNote/cac:CreditNoteLine/cbc:ID'), StrSubstNo(IncorrectValueErr, 'Credit Note Line ID'));
    end;
    #endregion

    #region SalesCreditMemo
    [Test]
    procedure ExportSalesCrMemoInjectsSupplierAndBuyerElements()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export Sales Credit Memo in PEPPOL BIS 3.0 FR injects supplier and buyer French-specific elements
        Initialize();

        // [GIVEN] Posted sales credit memo for customer with FR electronic address
        CustomerAddress := '123456789';
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0225")));

        // [WHEN] Export FR PEPPOL XML
        ExportCrMemo(SalesCrMemoHeader, XmlDoc);

        // [THEN] Supplier PartyIdentification contains SIRET with scheme 0009
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Supplier PartyIdentification ID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Supplier PartyIdentification schemeID'));
        // [THEN] Supplier EndpointID contains SIRET with scheme 0009
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Supplier EndpointID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Supplier EndpointID schemeID'));
        // [THEN] Buyer EndpointID contains address with scheme 0225
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesCrMemoIncludesRegulatoryCommentAsNote()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XmlDoc: XmlDocument;
        CommentText: Text[80];
    begin
        // [SCENARIO] A French regulatory comment on a posted credit memo is prefixed with its type in a UBL header note
        Initialize();

        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CreateCustomer('', "Electronic Address Scheme"::"EM")));
        CommentText := 'No discount is granted for early payment.';
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::"Posted Credit Memo";
        SalesCommentLine."No." := SalesCrMemoHeader."No.";
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine."FR Regulatory Comment Type" := SalesCommentLine."FR Regulatory Comment Type"::AAB;
        SalesCommentLine.Comment := CommentText;
        SalesCommentLine.Insert();

        ExportCrMemo(SalesCrMemoHeader, XmlDoc);

        Assert.AreEqual('#AAB#' + CommentText, GetNodeByPath(XmlDoc, '/CreditNote/cbc:Note'), StrSubstNo(IncorrectValueErr, 'Note'));
    end;

    [Test]
    procedure ExportSalesCrMemoIncludesBillingReference()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A sales credit memo applied to an invoice exports the invoice number and issue date
        Initialize();

        // [GIVEN] Posted sales invoice "SI" and posted credit memo "SCM" applied to "SI"
        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CustomerNo, SalesInvoiceHeader."No."));

        // [WHEN] Sales credit memo "SCM" is exported in PEPPOL BIS 3.0 FR
        ExportCrMemo(SalesCrMemoHeader, XmlDoc);

        // [THEN] BillingReference contains the number of "SI"
        Assert.AreEqual(SalesInvoiceHeader."No.",
            GetNodeByPath(XmlDoc, '/CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'BillingReference InvoiceDocumentReference ID'));

        // [THEN] BillingReference contains the document date of "SI"
        Assert.AreEqual(Format(SalesInvoiceHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>'),
            GetNodeByPath(XmlDoc, '/CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate'),
            StrSubstNo(IncorrectValueErr, 'BillingReference InvoiceDocumentReference IssueDate'));
    end;

    [Test]
    procedure ExportSalesCrMemoWithoutReferenceDoesNotIncludeBillingReference()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A sales credit memo without an applied invoice does not export an incomplete billing reference
        Initialize();

        // [GIVEN] Posted sales credit memo "SCM" without an applied invoice
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Sales credit memo "SCM" is exported in PEPPOL BIS 3.0 FR
        ExportCrMemo(SalesCrMemoHeader, XmlDoc);

        // [THEN] The XML does not contain a BillingReference
        Assert.AreEqual('', GetNodeByPath(XmlDoc, '/CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'BillingReference should be empty'));
    end;

    [Test]
    procedure ExportSalesCrMemoDoesNotSynthesizeRegulatoryComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XmlDoc: XmlDocument;
        CommentText: Text[80];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Export includes an explicit regulatory note without synthesizing PMT, PMD, or AAB notes
        Initialize();

        // [GIVEN] Posted sales credit memo "SCM" with one explicit PAI regulatory comment
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CreateCustomer('', "Electronic Address Scheme"::"EM")));
        CommentText := 'Payment instructions.';
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::"Posted Credit Memo";
        SalesCommentLine."No." := SalesCrMemoHeader."No.";
        SalesCommentLine."Line No." := 10000;
        SalesCommentLine."FR Regulatory Comment Type" := SalesCommentLine."FR Regulatory Comment Type"::PAI;
        SalesCommentLine.Comment := CommentText;
        SalesCommentLine.Insert();

        // [WHEN] Sales credit memo "SCM" is exported in PEPPOL BIS 3.0 FR
        ExportCrMemo(SalesCrMemoHeader, XmlDoc);

        // [THEN] The explicit PAI comment is exported
        Assert.AreEqual('#PAI#' + CommentText, GetNodeByPath(XmlDoc, '/CreditNote/cbc:Note'),
            StrSubstNo(IncorrectValueErr, 'Explicit regulatory note'));

        // [THEN] Mandatory regulatory comments are not synthesized
        Assert.AreEqual('', GetNodeByPath(XmlDoc, '/CreditNote/cbc:Note[contains(., ''#PMT#'')]'),
            StrSubstNo(IncorrectValueErr, 'PMT note should be empty'));
        Assert.AreEqual('', GetNodeByPath(XmlDoc, '/CreditNote/cbc:Note[contains(., ''#PMD#'')]'),
            StrSubstNo(IncorrectValueErr, 'PMD note should be empty'));
        Assert.AreEqual('', GetNodeByPath(XmlDoc, '/CreditNote/cbc:Note[contains(., ''#AAB#'')]'),
            StrSubstNo(IncorrectValueErr, 'AAB note should be empty'));
    end;

    [Test]
    procedure ExportSalesInvSelectsExtendedCTCForMultipleOrders()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] An invoice containing lines from distinct orders uses the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceFromMultipleOrders(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
            StrSubstNo(IncorrectValueErr, 'CustomizationID'));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual('FR-BUYER-REF', GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cac:OrderLineReference[following-sibling::cac:AllowanceCharge]/cac:OrderReference/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'OrderReference ID'));
        Assert.AreEqual(Format(SalesInvoiceLine."Order Line No.", 0, 9), GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cac:OrderLineReference/cbc:LineID'),
            StrSubstNo(IncorrectValueErr, 'OrderLineReference LineID'));
        Assert.AreEqual(SalesInvoiceLine."Shipment No.", GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cac:Delivery[following-sibling::cac:AllowanceCharge]/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Delivery ID'));
    end;

    [Test]
    procedure ExportSalesInvSelectsExtendedCTCForMultipleShipments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] An invoice containing lines from distinct shipments uses the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceFromMultipleShipments(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
            StrSubstNo(IncorrectValueErr, 'CustomizationID'));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindFirst();
        SalesShipmentHeader.Get(SalesInvoiceLine."Shipment No.");
        Assert.AreEqual(SalesInvoiceLine."Shipment No.", GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cac:Delivery/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Delivery ID'));
        Assert.AreEqual(Format(SalesShipmentHeader."Posting Date", 0, 9), GetNodeByPath(XmlDoc, '/Invoice/cac:InvoiceLine/cac:Delivery/cbc:ActualDeliveryDate'),
            StrSubstNo(IncorrectValueErr, 'ActualDeliveryDate'));
    end;

    [Test]
    procedure ExportSalesInvKeepsBasicCTCForRepeatedReferences()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] Repeated references to one shipment and one order do not select the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceFromSingleShipment(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('urn:cen.eu:en16931:2017', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
            StrSubstNo(IncorrectValueErr, 'CustomizationID'));
    end;
    #endregion

    #region Validation
    [Test]
    procedure CheckPassesWhenAllRequiredFieldsPresent()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check does not raise error when all required French fields are populated
        Initialize();

        // [GIVEN] Posted sales invoice with all required data present
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] Check is called
        CheckInvoice(SalesInvoiceHeader);

        // [THEN] No error is raised (test passes implicitly)
    end;

    [Test]
    procedure CheckPassesWhenSIRENIsEmptyAndSIRETIsPresent()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check accepts a company SIRET when Registration No. (SIREN) is blank
        Initialize();

        // [GIVEN] Company with blank Registration No. and a SIRET No.
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify(true);

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] Check is called
        CheckInvoice(SalesInvoiceHeader);

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure ExportSalesInvUsesSellerVATFallbackWhenSIRETAndSIRENAreEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        OriginalRegistrationNo: Text[20];
        OriginalSIRETNo: Code[14];
    begin
        // [SCENARIO] Company VAT registration number is used as the seller endpoint when SIRET and SIREN are blank
        Initialize();

        // [GIVEN] Company with blank SIRET No. and Registration No., and a VAT registration number
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."SIRET No." := '';
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify(true);

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] The invoice is checked and exported
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The supplier endpoint uses the VAT identifier and scheme 9957
        Assert.AreEqual(CompanyInformation.GetVATRegistrationNumber(),
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID'));
        Assert.AreEqual('9957',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID schemeID'));

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure CheckRaisesErrorWhenSellerVATFallbackIsNonFrench()
    var
        CountryRegion: Record "Country/Region";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] A non-French company VAT registration number cannot be used as a French seller endpoint
        Initialize();

        // [GIVEN] A non-French company with no SIRET, SIREN, or service participant endpoint
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("ISO Code", 'DE');
        CountryRegion.Modify(true);
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '';
        CompanyInformation."Registration No." := '';
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo('DE'));
        CompanyInformation.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] Check is called
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] An error about the missing seller electronic address is raised
        AssertExpectedDialogError(EDocHelpers.GetSellerElectronicAddressRequiredError());
    end;

    [Test]
    procedure ExportSalesInvUsesCompanyServiceParticipantEndpoint()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        EndpointId: Text[200];
    begin
        // [SCENARIO] A service-specific company participant overrides the company endpoint fallbacks
        Initialize();

        EndpointId := CompanyInformation."Registration No.";
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Company;
        ServiceParticipant."Participant Identifier" := EndpointId;
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::"0002";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));
        CompanyInformation.Get();
        CompanyInformation.Address := '123 Rue de Paris';
        CompanyInformation.City := 'Paris';
        CompanyInformation."Post Code" := '75001';
        CompanyInformation.GLN := '';
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation."SIRET No." := '';
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify(true);

        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual(EndpointId,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID schemeID'));
    end;

    [Test]
    procedure CheckRaisesErrorWhenSellerCountryCodeIsEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalCountryCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check raises error when company Country/Region Code is blank
        Initialize();

        // [GIVEN] Company with blank Country/Region Code
        OriginalCountryCode := CompanyInformation."Country/Region Code";
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := '';
        CompanyInformation.Modify(true);

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] Check is called
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] Error about Country/Region Code is raised
        AssertExpectedDialogError(EDocHelpers.GetSellerCountryCodeRequiredError());

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := OriginalCountryCode;
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure ExportSalesInvUsesRegistrationNumberFallbackForBuyerEndpoint()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] Customer Registration Number is used when both FR Electronic Address and Service Participant are absent
        Initialize();

        // [GIVEN] Posted sales invoice for a customer with blank FR electronic address and a Registration Number
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer."FR Electronic Address" := '';
        Customer.Modify(true);

        // [WHEN] The invoice is checked and exported
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The buyer endpoint uses the first 9 digits of Registration Number with scheme 0225
        Assert.AreEqual('123456789',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvUsesFrenchVATFallbackForBuyerEndpoint()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] French VAT Registration No. SIREN extraction is used as buyer endpoint when FR Electronic Address and Registration Number are blank
        Initialize();

        // [GIVEN] Customer "C" with French VAT but no FR Electronic Address or Registration Number
        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        Customer.Get(CustomerNo);
        Customer."FR Electronic Address" := '';
        Customer."Registration Number" := '';
        Customer."VAT Registration No." := 'FR78945627890';
        Customer.Modify(true);

        // [GIVEN] Posted sales invoice for "C"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        // [WHEN] The invoice is checked and exported
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID = '945627890' with scheme 0225
        Assert.AreEqual('945627890',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
        Assert.AreEqual('945627890',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID'),
            StrSubstNo(IncorrectValueErr, 'Buyer CompanyID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer CompanyID schemeID'));
    end;

    [Test]
    procedure CheckRaisesErrorWhenBuyerHasOnlyNonFrenchVAT()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check rejects a buyer with only a non-French VAT when FR Electronic Address and Registration Number are blank
        Initialize();

        // [GIVEN] Customer "C" with non-French VAT but no FR Electronic Address or Registration Number
        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        Customer.Get(CustomerNo);
        Customer."FR Electronic Address" := '';
        Customer."Registration Number" := '';
        Customer."VAT Registration No." := 'DE123456789';
        Customer.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        // [WHEN] Check is called
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] Error about buyer electronic address is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressRequiredError(CustomerNo));
    end;

    [Test]
    procedure CheckSalesInvRejectsMalformedBuyerIdentifier()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] A malformed FR Electronic Address that does not match SIREN format is rejected
        Initialize();

        Customer.Get(CreateCustomer('ABCD56789', "Electronic Address Scheme"::"0002"));
        Customer."Registration Number" := '';
        Customer.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(Customer."No."));

        // [WHEN] Check is called
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] Error about malformed buyer identifier is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressInvalidError(
            Customer.FieldCaption("FR Electronic Address"), Customer."No."));
    end;

    [Test]
    procedure ExportSalesInvUsesSupplierSIRENWhenSIRETIsMissing()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        OriginalSIRETNo: Code[14];
    begin
        // [SCENARIO] Company Registration No. is used as the seller endpoint when SIRET is missing
        Initialize();

        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual(CompanyInformation."Registration No.",
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID schemeID'));

        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure CheckRaisesErrorWhenCompanyParticipantSchemeIsMissing()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] Check rejects a company participant identifier without its scheme even when SIRET is valid
        Initialize();

        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Company;
        ServiceParticipant."Participant Identifier" := CompanyInformation."Registration No.";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetServiceParticipantAddressIncompleteError());
    end;

    [Test]
    procedure CheckRaisesErrorWhenBuyerElectronicAddressIsMissing()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Check rejects a buyer without an electronic address, Registration Number, or a service participant identifier
        Initialize();

        CustomerNo := CreateCustomer('', "Electronic Address Scheme"::"EM");
        ClearCustomerVATRegistrationNo(CustomerNo);
        ClearCustomerRegistrationNumber(CustomerNo);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressRequiredError(CustomerNo));
    end;

    [Test]
    procedure CheckRaisesErrorWhenBuyerElectronicAddressIsMalformed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Check rejects a buyer electronic address that does not match SIREN or SIREN_suffix format
        Initialize();

        CustomerNo := CreateCustomer('SHORT', "Electronic Address Scheme"::"0002");
        Customer.Get(CustomerNo);
        Customer."Registration Number" := '';
        Customer.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressInvalidError(
            Customer.FieldCaption("FR Electronic Address"), CustomerNo));
    end;

    [Test]
    procedure CheckRaisesErrorWhenBuyerElectronicAddressSuffixIsBlank()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Check rejects a buyer electronic address with a blank SIREN suffix
        Initialize();

        CustomerNo := CreateCustomer('123456789_ ', "Electronic Address Scheme"::"0225");
        Customer.Get(CustomerNo);
        Customer."Registration Number" := '';
        Customer.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressInvalidError(
            Customer.FieldCaption("FR Electronic Address"), CustomerNo));
    end;

    [Test]
    procedure CheckRaisesErrorWhenParticipantSchemeIsMissing()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Check rejects a service participant identifier without its French identifier scheme even when the customer endpoint is valid
        Initialize();

        CustomerNo := CreateCustomer('buyer@example.com', "Electronic Address Scheme"::"EM");
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := CustomerNo;
        ServiceParticipant."Participant Identifier" := '123456789_001';
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetServiceParticipantAddressIncompleteError());
    end;

    [Test]
    procedure CheckRaisesErrorWhenParticipantIdentifierIsMissing()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Check rejects a French identifier scheme without its service participant identifier even when the customer endpoint is valid
        Initialize();

        CustomerNo := CreateCustomer('buyer@example.com', "Electronic Address Scheme"::"EM");
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := CustomerNo;
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::"0225";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        asserterror CheckInvoice(SalesInvoiceHeader);

        AssertExpectedDialogError(EDocHelpers.GetServiceParticipantAddressIncompleteError());
    end;

    [Test]
    procedure CheckRaisesErrorWhenParticipantIdentifierIsMalformed()
    var
        ServiceParticipant: Record "Service Participant";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check rejects a service participant identifier that does not match SIREN or SIREN_suffix format
        Initialize();

        // [GIVEN] Customer "C" with a service participant whose identifier is malformed
        CustomerNo := CreateCustomer('buyer@example.com', "Electronic Address Scheme"::"EM");
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := CustomerNo;
        ServiceParticipant."Participant Identifier" := 'INVALID';
        ServiceParticipant."FR Identifier Scheme" := ServiceParticipant."FR Identifier Scheme"::"0225";
        ServiceParticipant.Insert();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CustomerNo));

        // [WHEN] Check the posted sales invoice
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] The malformed participant identifier error is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressInvalidError(
            ServiceParticipant.FieldCaption("Participant Identifier"), CustomerNo));
    end;
    #endregion

    local procedure AssertExpectedDialogError(ExpectedErrorText: Text)
    begin
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    local procedure Initialize()
    var
        ServiceParticipant: Record "Service Participant";
        ServiceCode: Code[20];
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");
        ServiceParticipant.SetRange(Service, EDocumentService.Code);
        ServiceParticipant.DeleteAll();
        if IsInitialized then begin
            LibrarySetupStorage.Restore();
            InitializeCompanyIdentity();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");

        InitializeCompanyIdentity();
        CompanyInformation.Get();
        CompanyInformation.Name := 'Test Company FR';
        CompanyInformation.Address := '123 Rue de Paris';
        CompanyInformation.City := 'Paris';
        CompanyInformation."Post Code" := '75001';
        CompanyInformation."Country/Region Code" := 'FR';
        CompanyInformation.Validate(IBAN, 'FR1420041010050500013M02606');
        CompanyInformation.Validate("SWIFT Code", 'CCBPFRPPVER');
        CompanyInformation.Validate("Bank Branch No.", '20041');
        CompanyInformation.Modify(true);

        SetupGeneralLedger();
        CreatePostingSetupFixture();

        EDocumentService.Reset();
        EDocumentService.DeleteAll();

        ServiceCode := CopyStr('PEPFR-' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService.Init();
        EDocumentService.Code := ServiceCode;
        EDocumentService.Insert(true);
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::"Peppol BIS 3.0 FR");
        EDocumentService.Modify(true);

        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");
    end;

    local procedure InitializeCompanyIdentity()
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get('FR') then begin
            CountryRegion.Code := 'FR';
            CountryRegion.Insert(true);
        end;
        CountryRegion.Validate("ISO Code", 'FR');
        CountryRegion.Modify(true);

        CompanyInformation.Get();
        CompanyInformation.Name := 'Test Company FR';
        CompanyInformation.Address := '123 Rue de Paris';
        CompanyInformation.City := 'Paris';
        CompanyInformation."Post Code" := '75001';
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Validate("Registration No.", '123456789');
        CompanyInformation.Validate("SIRET No.", '12345678901234');
        CompanyInformation.Validate("VAT Registration No.", 'FR12345678901');
        CompanyInformation.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesInvoiceWithLine(CustomerNo));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceFromMultipleOrders(CustomerNo: Code[20]): Code[20]
    var
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
    begin
        FirstShipmentNo := CreateAndPostSalesOrderShipment(CustomerNo, 1, 1, 10);
        SecondShipmentNo := CreateAndPostSalesOrderShipment(CustomerNo, 1, 1, 10);
        exit(CreateAndPostSalesInvoiceFromShipments(CustomerNo, FirstShipmentNo + '|' + SecondShipmentNo));
    end;

    local procedure CreateAndPostSalesInvoiceFromMultipleShipments(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
        OriginalWorkDate: Date;
    begin
        CreateSalesOrderWithLines(SalesHeader, CustomerNo, 1, 2);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);
        OriginalWorkDate := WorkDate();
        WorkDate(CalcDate('<-1D>', OriginalWorkDate));
        FirstShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        WorkDate(OriginalWorkDate);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);
        SecondShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        exit(CreateAndPostSalesInvoiceFromShipments(CustomerNo, FirstShipmentNo + '|' + SecondShipmentNo));
    end;

    local procedure CreateAndPostSalesInvoiceFromSingleShipment(CustomerNo: Code[20]): Code[20]
    var
        ShipmentNo: Code[20];
    begin
        ShipmentNo := CreateAndPostSalesOrderShipment(CustomerNo, 2, 1, 0);
        exit(CreateAndPostSalesInvoiceFromShipments(CustomerNo, ShipmentNo));
    end;

    local procedure CreateAndPostSalesOrderShipment(CustomerNo: Code[20]; NumberOfLines: Integer; Quantity: Decimal; LineDiscountPct: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderWithLines(SalesHeader, CustomerNo, NumberOfLines, Quantity);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet(true);
        repeat
            SalesLine.Validate("Line Discount %", LineDiscountPct);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateSalesOrderWithLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; NumberOfLines: Integer; Quantity: Decimal)
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineIndex: Integer;
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Shipment Nos."));
        CreateDirectPostingGLAccountWithSalesSetup(GLAccount);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        SalesHeader.Modify(true);
        for LineIndex := 1 to NumberOfLines do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", Quantity);
            SalesLine.Validate("Unit Price", 100);
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostSalesInvoiceFromShipments(CustomerNo: Code[20]; ShipmentNoFilter: Text): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        SalesHeader.Modify(true);

        SalesShipmentLine.SetFilter("Document No.", ShipmentNoFilter);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateSalesInvoiceWithLine(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        CreateDirectPostingGLAccountWithSalesSetup(GLAccount);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        if SalesHeader."Bill-to City" = '' then
            SalesHeader.Validate("Bill-to City", 'Paris');
        if SalesHeader."Bill-to Post Code" = '' then
            SalesHeader.Validate("Bill-to Post Code", '75001');
        if SalesHeader."Ship-to City" = '' then
            SalesHeader.Validate("Ship-to City", SalesHeader."Bill-to City");
        if SalesHeader."Ship-to Post Code" = '' then
            SalesHeader.Validate("Ship-to Post Code", '75001');
        if SalesHeader."Ship-to Country/Region Code" = '' then
            SalesHeader.Validate("Ship-to Country/Region Code", CompanyInformation."Country/Region Code");
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    local procedure CreateCustomer(FRElectronicAddress: Text[250]; AddressScheme: Enum "Electronic Address Scheme"): Code[20]
    var
        CurrentCompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CurrentCompanyInformation.Get();
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Country/Region Code", CurrentCompanyInformation."Country/Region Code");
        if Customer.Address = '' then
            Customer.Address := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)), 1, MaxStrLen(Customer.Address));
        if Customer."Post Code" = '' then
            Customer.Validate("Post Code", '75001');
        Customer.Validate(City, 'Paris');
        Customer."VAT Registration No." := 'FR12345678901';
        Customer."Registration Number" := '123456789';

        Customer.Validate("FR Electronic Address", FRElectronicAddress);
        Customer.Validate("FR Elec. Address Scheme", AddressScheme);
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure ClearCustomerVATRegistrationNo(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."VAT Registration No." := '';
        Customer.Modify(true);
    end;

    local procedure ClearCustomerRegistrationNumber(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."Registration Number" := '';
        Customer.Modify(true);
    end;

    local procedure CheckInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        PeppolBIS30FRFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Create);
    end;

    local procedure ExportInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; var XmlDoc: XmlDocument)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceDocumentLines.GetTable(SalesInvoiceLine);

        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        PeppolBIS30FRFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
    end;

    local procedure GetNodeByPath(XmlDoc: XmlDocument; XPath: Text): Text
    var
        NamespaceMgr: XmlNamespaceManager;
        FoundNode: XmlNode;
        XmlElem: XmlElement;
        XmlAttr: XmlAttribute;
        AdjustedXPath: Text;
        AttrName: Text;
        AttrPos: Integer;
    begin
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        NamespaceMgr.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        NamespaceMgr.AddNamespace('inv', 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2');
        NamespaceMgr.AddNamespace('cn', 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2');

        AdjustedXPath := XPath;
        if AdjustedXPath.StartsWith('/Invoice/') then
            AdjustedXPath := '/inv:Invoice/' + CopyStr(AdjustedXPath, 10)
        else
            if AdjustedXPath.StartsWith('/CreditNote/') then
                AdjustedXPath := '/cn:CreditNote/' + CopyStr(AdjustedXPath, 13);

        AttrPos := AdjustedXPath.LastIndexOf('/@');
        if AttrPos > 0 then begin
            AttrName := CopyStr(AdjustedXPath, AttrPos + 2);
            AdjustedXPath := CopyStr(AdjustedXPath, 1, AttrPos - 1);
            if XmlDoc.SelectSingleNode(AdjustedXPath, NamespaceMgr, FoundNode) then begin
                XmlElem := FoundNode.AsXmlElement();
                if XmlElem.Attributes().Get(AttrName, XmlAttr) then
                    exit(XmlAttr.Value());
            end;
        end else
            if XmlDoc.SelectSingleNode(AdjustedXPath, NamespaceMgr, FoundNode) then
                exit(FoundNode.AsXmlElement().InnerText());
        exit('');
    end;

    local procedure CreateAndPostSalesCrMemo(CustomerNo: Code[20]): Code[20]
    begin
        exit(CreateAndPostSalesCrMemo(CustomerNo, ''));
    end;

    local procedure CreateAndPostSalesCrMemo(CustomerNo: Code[20]; AppliesToInvoiceNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Credit Memo Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Credit Memo Nos."));
        CreateDirectPostingGLAccountWithSalesSetup(GLAccount);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CustomerNo);
        if SalesHeader."Bill-to City" = '' then
            SalesHeader.Validate("Bill-to City", 'Paris');
        if SalesHeader."Ship-to City" = '' then
            SalesHeader.Validate("Ship-to City", SalesHeader."Bill-to City");
        if SalesHeader."Ship-to Country/Region Code" = '' then
            SalesHeader.Validate("Ship-to Country/Region Code", CompanyInformation."Country/Region Code");
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        if AppliesToInvoiceNo <> '' then begin
            SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
            SalesHeader.Validate("Applies-to Doc. No.", AppliesToInvoiceNo);
        end;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ExportCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var XmlDoc: XmlDocument)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SourceDocumentLines.GetTable(SalesCrMemoLine);

        EDocument."Document Type" := EDocument."Document Type"::"Sales Credit Memo";
        PeppolBIS30FRFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
    end;

    local procedure CreateAndPostServiceInvoice(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServicePost: Codeunit "Service-Post";
        PostedDocumentVariant: Variant;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        Codeunit.Run(Codeunit::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceInvoiceHeader := PostedDocumentVariant;
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreateAndPostServiceCreditMemo(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        PostedDocumentVariant: Variant;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);
        Codeunit.Run(Codeunit::"Service-Post", ServiceHeader);
        ServicePost.GetPostedDocumentRecord(ServiceHeader, PostedDocumentVariant);
        ServiceCrMemoHeader := PostedDocumentVariant;
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.SetupServiceMgtNoSeries();
        CreateDirectPostingGLAccountWithSalesSetup(GLAccount);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Ship-to Address", Customer.Address);
        ServiceHeader.Validate("Ship-to City", Customer.City);
        ServiceHeader.Validate("Ship-to Post Code", Customer."Post Code");
        ServiceHeader.Validate("Ship-to Country/Region Code", Customer."Country/Region Code");
        ServiceHeader.Validate("Your Reference", 'FR-BUYER-REF');
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", 1);
        ServiceLine.Validate("Unit Price", 100);
        ServiceLine.Modify(true);
    end;

    local procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(ServiceInvoiceHeader);
        PeppolBIS30FRFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Create);
    end;

    local procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(ServiceCrMemoHeader);
        PeppolBIS30FRFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Create);
    end;

    local procedure ExportServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header"; var XmlDoc: XmlDocument)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceInvoiceHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        SourceDocumentLines.GetTable(ServiceInvoiceLine);
        EDocument."Document Type" := EDocument."Document Type"::"Service Invoice";

        PeppolBIS30FRFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
    end;

    local procedure ExportServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var XmlDoc: XmlDocument)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceCrMemoHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        SourceDocumentLines.GetTable(ServiceCrMemoLine);
        EDocument."Document Type" := EDocument."Document Type"::"Service Credit Memo";

        PeppolBIS30FRFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
    end;

    local procedure SetupGeneralLedger()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'EUR';
            GeneralLedgerSetup.Modify(true);
        end;
    end;

    local procedure CreatePostingSetupFixture()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingGroupCode: Code[20];
    begin
        PostingGroupCode := '0FRPEPPOL';

        if VATPostingSetup.Get(PostingGroupCode, PostingGroupCode) then
            exit;

        if not GenBusinessPostingGroup.Get(PostingGroupCode) then begin
            GenBusinessPostingGroup.Code := PostingGroupCode;
            GenBusinessPostingGroup.Insert(true);
        end;
        if not GenProductPostingGroup.Get(PostingGroupCode) then begin
            GenProductPostingGroup.Code := PostingGroupCode;
            GenProductPostingGroup.Insert(true);
        end;

        if not GeneralPostingSetup.Get(PostingGroupCode, PostingGroupCode) then begin
            GeneralPostingSetup."Gen. Bus. Posting Group" := PostingGroupCode;
            GeneralPostingSetup."Gen. Prod. Posting Group" := PostingGroupCode;
            GeneralPostingSetup.Insert(true);
        end;
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Prepayments Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Prepayments Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account (Interim)", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Overhead Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purchase Variance Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);

        if not VATBusinessPostingGroup.Get(PostingGroupCode) then begin
            VATBusinessPostingGroup.Code := PostingGroupCode;
            VATBusinessPostingGroup.Insert(true);
        end;
        if not VATProductPostingGroup.Get(PostingGroupCode) then begin
            VATProductPostingGroup.Code := PostingGroupCode;
            VATProductPostingGroup.Insert(true);
        end;

        VATPostingSetup."VAT Bus. Posting Group" := PostingGroupCode;
        VATPostingSetup."VAT Prod. Posting Group" := PostingGroupCode;
        VATPostingSetup.Insert(true);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 20);
        VATPostingSetup.Validate("Tax Category", 'S');
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateDirectPostingGLAccountWithSalesSetup(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);

        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Sales Line Disc. Account" = '' then begin
            GeneralPostingSetup.Validate("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());
            GeneralPostingSetup.Modify(true);
        end;
    end;

}
