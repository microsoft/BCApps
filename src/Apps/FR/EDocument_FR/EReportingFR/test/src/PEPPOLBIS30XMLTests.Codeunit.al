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
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 148147 "PEPPOL BIS 3.0 XML Tests"
{
    Subtype = Test;
    Permissions = tabledata "E-Document Service" = rimd,
                  tabledata "Company Information" = rimd,
                  tabledata "FR Regulatory Comment" = rimd,
                  tabledata "Service Participant" = rimd,
                  tabledata "Sales Invoice Line" = rimd,
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
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        PeppolBIS30FRFormat: Codeunit "Peppol BIS 3.0 FR Format";
        IncorrectValueErr: Label 'Incorrect value for %1', Comment = '%1 = XML element path', Locked = true;
        IsInitialized: Boolean;
        CustomerVATNoSequence: Integer;

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
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects buyer endpoint from FR Electronic Address and scheme
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and scheme 0002
        CustomerAddress := '123456789';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0002")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains FR Electronic Address and scheme 0002
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvKeepsBuyerEndpointWhenFRElectronicAddressBlank()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR does not overwrite buyer endpoint when FR Electronic Address is blank
        Initialize();

        // [GIVEN] Posted sales invoice for customer with blank FR electronic address
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID remains populated by base PEPPOL logic
        Assert.AreNotEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerPartyIdentificationWhenScheme0009()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects buyer PartyIdentification with scheme 0009 when customer uses SIRET scheme
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and scheme 0009
        CustomerAddress := '12345678901234';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0009")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer PartyIdentification contains address with scheme 0009
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification schemeID'));
    end;

    [Test]
    procedure ExportSalesInvDoesNotInjectBuyerPartyIdentificationWhenSchemeNot0009()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR does not inject buyer PartyIdentification when scheme is not 0009
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and scheme 0002
        CustomerAddress := '123456789';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0002")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer PartyIdentification is not added by FR logic
        Assert.AreEqual('',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID should be empty'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerEndpointWithEMScheme()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects buyer endpoint with EM scheme when customer uses email scheme
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and EM scheme
        CustomerAddress := 'buyer@example.com';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"EM")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains email with scheme EM
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('EM',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvInjectsBuyerEndpointAndIdentificationWithScheme0009()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CustomerAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export in PEPPOL BIS 3.0 FR injects both buyer endpoint and PartyIdentification when scheme is 0009
        Initialize();

        // [GIVEN] Posted sales invoice for customer with FR electronic address and scheme 0009
        CustomerAddress := '98765432109876';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0009")));

        // [WHEN] Export FR PEPPOL XML
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] Buyer EndpointID contains address with scheme 0009
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
        // [THEN] Buyer PartyIdentification is also injected with scheme 0009
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification ID'));
        Assert.AreEqual('0009',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer PartyIdentification schemeID'));
    end;

    [Test]
    procedure ExportSalesInvIncludesRegulatoryCommentAsNote()
    var
        RegulatoryComment: Record "FR Regulatory Comment";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        CommentText: Text[250];
    begin
        // [SCENARIO] A maintained French regulatory comment is exported as a UBL header note
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));
        CommentText := 'No discount is granted for early payment.';
        RegulatoryComment."Document Type" := RegulatoryComment."Document Type"::"Posted Invoice";
        RegulatoryComment."Document No." := SalesInvoiceHeader."No.";
        RegulatoryComment."Line No." := 10000;
        RegulatoryComment."Comment Type" := RegulatoryComment."Comment Type"::AAB;
        RegulatoryComment."Comment Text" := CommentText;
        RegulatoryComment.Insert();

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual(CommentText, GetNodeByPath(XmlDoc, '/Invoice/cbc:Note'), StrSubstNo(IncorrectValueErr, 'Note'));
    end;

    [Test]
    procedure ExportSalesInvUsesServiceParticipantEndpointWithScheme0225()
    var
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

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual(EndpointId,
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0225',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
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
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemo(CreateCustomer(CustomerAddress, "Electronic Address Scheme"::"0002")));

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
        // [THEN] Buyer EndpointID contains address with scheme 0002
        Assert.AreEqual(CustomerAddress,
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0002',
            GetNodeByPath(XmlDoc, '/CreditNote/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;

    [Test]
    procedure ExportSalesInvSelectsExtendedCTCForMultipleOrders()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] An invoice containing lines from distinct orders uses the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithTwoLines(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));
        SetPostedInvoiceLineReferences(SalesInvoiceHeader."No.", 'SHIPMENT-1', 'ORDER-', false, true);

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('EXTENDED-CTC-FR', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
            StrSubstNo(IncorrectValueErr, 'CustomizationID'));
    end;

    [Test]
    procedure ExportSalesInvSelectsExtendedCTCForMultipleShipments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] An invoice containing lines from distinct shipments uses the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithTwoLines(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));
        SetPostedInvoiceLineReferences(SalesInvoiceHeader."No.", 'SHIPMENT-', 'ORDER-1', true, false);

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreEqual('EXTENDED-CTC-FR', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
            StrSubstNo(IncorrectValueErr, 'CustomizationID'));
    end;

    [Test]
    procedure ExportSalesInvKeepsBasicCTCForRepeatedReferences()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] Repeated references to one shipment and one order do not select the Extended CTC profile
        Initialize();

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithTwoLines(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));
        SetPostedInvoiceLineReferences(SalesInvoiceHeader."No.", 'SHIPMENT-1', 'ORDER-1', false, false);

        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        Assert.AreNotEqual('EXTENDED-CTC-FR', GetNodeByPath(XmlDoc, '/Invoice/cbc:CustomizationID'),
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
    procedure CheckRaisesErrorWhenSIRENIsEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Check raises error when company Registration No. (SIREN) is blank
        Initialize();

        // [GIVEN] Company with blank Registration No.
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify(true);

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] Check is called
        asserterror CheckInvoice(SalesInvoiceHeader);

        // [THEN] Error about Registration No. is raised
        Assert.ExpectedError('Registration No. must be specified in Company Information for French e-invoicing.');

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure ExportSalesInvUsesSellerVATFallbackWhenSIRETIsEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
        OriginalSIRETNo: Code[14];
    begin
        // [SCENARIO] Company VAT registration number is used as the seller endpoint when SIRET is blank
        Initialize();

        // [GIVEN] Company with blank SIRET No. and a VAT registration number
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify(true);

        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('123456789', "Electronic Address Scheme"::"0002")));

        // [WHEN] The invoice is checked and exported
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The supplier endpoint uses the VAT identifier and scheme 0223
        Assert.AreEqual(CompanyInformation.GetVATRegistrationNumber(),
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID'));
        Assert.AreEqual('0223',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Seller EndpointID schemeID'));

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify(true);
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
        Assert.ExpectedError('Country/Region Code must be specified in Company Information for French e-invoicing.');

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := OriginalCountryCode;
        CompanyInformation.Modify(true);
    end;

    [Test]
    procedure ExportSalesInvUsesBuyerVATFallbackWhenElectronicAddressIsEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XmlDoc: XmlDocument;
    begin
        // [SCENARIO] Customer VAT registration number is used when the electronic address is blank
        Initialize();

        // [GIVEN] Posted sales invoice for a customer with blank electronic address and a VAT number
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(CreateCustomer('', "Electronic Address Scheme"::"EM")));

        // [WHEN] The invoice is checked and exported
        CheckInvoice(SalesInvoiceHeader);
        ExportInvoice(SalesInvoiceHeader, XmlDoc);

        // [THEN] The buyer endpoint uses the VAT identifier and scheme 0223
        Assert.AreEqual(GetCustomerVATRegistrationNo(SalesInvoiceHeader."Sell-to Customer No."),
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID'));
        Assert.AreEqual('0223',
            GetNodeByPath(XmlDoc, '/Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID'),
            StrSubstNo(IncorrectValueErr, 'Buyer EndpointID schemeID'));
    end;
    #endregion

    local procedure Initialize()
    var
        ServiceCode: Code[20];
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");

        CompanyInformation.Get();
        EnsureCountryRegionExists('FR');
        CompanyInformation.Name := 'Test Company FR';
        CompanyInformation.Address := '123 Rue de Paris';
        CompanyInformation.City := 'Paris';
        CompanyInformation."Post Code" := '75001';
        CompanyInformation."Country/Region Code" := 'FR';
        CompanyInformation.Validate("Registration No.", '123456789');
        CompanyInformation.Validate("SIRET No.", '12345678901234');
        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation.Validate("VAT Registration No.", 'FR12345678901');
        CompanyInformation.Validate(IBAN, 'FR1420041010050500013M02606');
        CompanyInformation.Validate("SWIFT Code", 'CCBPFRPPVER');
        CompanyInformation.Validate("Bank Branch No.", '20041');
        CompanyInformation.Modify(true);

        SetupGeneralLedger();

        EDocumentService.Reset();
        EDocumentService.DeleteAll();

        ServiceCode := CopyStr('PEPFR-' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService.Init();
        EDocumentService.Code := ServiceCode;
        EDocumentService.Insert(true);
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::"Peppol BIS 3.0 FR");
        EDocumentService.Modify(true);

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL BIS 3.0 XML Tests");
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesInvoiceWithLine(CustomerNo));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithTwoLines(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewSalesLine: Record "Sales Line";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesInvoiceWithLine(CustomerNo));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibrarySales.CreateSalesLine(NewSalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", 1);
        NewSalesLine.Validate("Unit Price", SalesLine."Unit Price");
        NewSalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SetPostedInvoiceLineReferences(DocumentNo: Code[20]; ShipmentNo: Text; OrderNo: Text; AppendShipmentIndex: Boolean; AppendOrderIndex: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        LineIndex: Integer;
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet(true);
        repeat
            LineIndex += 1;
            if AppendShipmentIndex then
                SalesInvoiceLine."Shipment No." := CopyStr(ShipmentNo + Format(LineIndex), 1, MaxStrLen(SalesInvoiceLine."Shipment No."));
            else
                SalesInvoiceLine."Shipment No." := CopyStr(ShipmentNo, 1, MaxStrLen(SalesInvoiceLine."Shipment No."));
            if AppendOrderIndex then
                SalesInvoiceLine."Order No." := CopyStr(OrderNo + Format(LineIndex), 1, MaxStrLen(SalesInvoiceLine."Order No."));
            else
                SalesInvoiceLine."Order No." := CopyStr(OrderNo, 1, MaxStrLen(SalesInvoiceLine."Order No."));
            SalesInvoiceLine.Modify();
        until SalesInvoiceLine.Next() = 0;
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
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
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
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        if Customer."Country/Region Code" = '' then
            Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        if Customer.Address = '' then
            Customer.Address := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Address)), 1, MaxStrLen(Customer.Address));
        if Customer."Post Code" = '' then
            Customer.Validate("Post Code", '75001');
        Customer.Validate("VAT Registration No.", GetNextCustomerVATRegistrationNo());

        Customer.Validate("FR Electronic Address", FRElectronicAddress);
        Customer.Validate("FR Elec. Address Scheme", AddressScheme);
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure GetNextCustomerVATRegistrationNo(): Text[20]
    var
        VATNoBody: Text[11];
        SequenceText: Text;
    begin
        CustomerVATNoSequence += 1;
        SequenceText := Format(CustomerVATNoSequence);
        VATNoBody := CopyStr(PadStr('', 11 - StrLen(SequenceText), '0') + SequenceText, 1, 11);
        exit('FR' + VATNoBody);
    end;

    local procedure GetCustomerVATRegistrationNo(CustomerNo: Code[20]): Text[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(Customer."VAT Registration No.");
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
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
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

    local procedure EnsureCountryRegionExists(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then begin
            CountryRegion.Init();
            CountryRegion.Code := CountryCode;
            CountryRegion.Name := CountryCode;
            CountryRegion."ISO Code" := CountryCode;
            CountryRegion.Insert(true);
        end else
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := CountryCode;
                CountryRegion.Modify(true);
            end;
    end;
}
