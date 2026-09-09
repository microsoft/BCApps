// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Bank.BankAccount;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Test;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 13918 "XRechnung XML Document Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [XRechnung E-document]
    end;

    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        EDocumentService: Record "E-Document Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryEdocument: Codeunit "Library - E-Document";
        LibraryEDocDE: Codeunit "Library - E-Doc DE";
        Assert: Codeunit Assert;
        ExportXRechnungFormat: Codeunit "XRechnung Format";
        ExportXRechnungDocument: Codeunit "Export XRechnung Document";
        IncorrectValueErr: Label 'Incorrect value for %1', Locked = true;
        AttributeNotFoundErr: Label 'Attribute %1 not found for node: %2', Locked = true, Comment = '%1 = XML attribute name, %2 = XML element XPath';
        UnexpectedNodeErr: Label 'Node %1 must not exist.', Locked = true;
        DocumentAllowanceChargeTok: Label '/ubl:Invoice/cac:AllowanceCharge', Locked = true;
        InvoiceLineTok: Label '/ubl:Invoice/cac:InvoiceLine', Locked = true;
        InvoiceLineAllowanceChargeTok: Label '/ubl:Invoice/cac:InvoiceLine/cac:AllowanceCharge', Locked = true;
        LegalMonetaryTotalTok: Label '/ubl:Invoice/cac:LegalMonetaryTotal', Locked = true;
        TaxTotalPathTok: Label '/ubl:Invoice/cac:TaxTotal', Locked = true;
        CrMemoDocumentAllowanceChargeTok: Label '/ns0:CreditNote/cac:AllowanceCharge', Locked = true;
        CrMemoLineTok: Label '/ns0:CreditNote/cac:CreditNoteLine', Locked = true;
        CrMemoLineAllowanceChargeTok: Label '/ns0:CreditNote/cac:CreditNoteLine/cac:AllowanceCharge', Locked = true;
        CrMemoLegalMonetaryTotalTok: Label '/ns0:CreditNote/cac:LegalMonetaryTotal', Locked = true;
        CrMemoTaxTotalPathTok: Label '/ns0:CreditNote/cac:TaxTotal', Locked = true;
        TaxCategoryStandardTok: Label 'S', Locked = true;
        ItemChargeReasonTextTok: Label 'Freight surcharge', Locked = true;
        ItemChargeReasonCodeTok: Label 'FC', Locked = true;
        UnitCodeOneTok: Label 'C62', Locked = true;
        UnitCodeHourTok: Label 'HUR', Locked = true;
        SupplierTaxSchemeTok: Label '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme', Locked = true;
        SupplierPartyIdTok: Label '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID', Locked = true;
        SupplierLegalEntityIdTok: Label '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Locked = true;
        CustomerPartyIdTok: Label '/ubl:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID', Locked = true;
        CustomerLegalEntityIdTok: Label '/ubl:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Locked = true;
        DeliveryLocationIdTok: Label '/ubl:Invoice/cac:Delivery/cac:DeliveryLocation/cbc:ID', Locked = true;
        CreditMemoCustomerPartyIdTok: Label '/ns0:CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID', Locked = true;
        CreditMemoCustomerLegalEntityIdTok: Label '/ns0:CreditNote/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Locked = true;
        CreditMemoDeliveryLocationIdTok: Label '/ns0:CreditNote/cac:Delivery/cac:DeliveryLocation/cbc:ID', Locked = true;
        IsInitialized: Boolean;
        OriginalCompanyGLN: Code[13];
        OriginalCompanyUsesGLN: Boolean;
        OriginalCompanyUsesRegistrationNo: Boolean;
        OriginalCompanyVATRegistrationNo: Text[20];
        OriginalCompanyRegistrationNo: Text[20];

    #region SalesInvoice
    [Test]
    procedure CheckSalesInvoiceInXRechnungFormatVATRegNoNotMandatoryWithCustomerReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] When Buyer Reference is Customer Reference, VAT Registration No. is not required if customer has E-Invoice Routing No.
        Initialize();

        // [GIVEN] Buyer Reference is Customer Reference
        SetBuyerReferenceMandatory();

        // [GIVEN] Sales Invoice for a customer with E-Invoice Routing No. but without VAT Registration No.
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithCustomerWithoutVATRegNo("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item));

        // [WHEN/THEN] Check does not throw an error - VAT Registration No. is not required
        CheckSalesHeader(SalesHeader);
    end;

    [Test]
    procedure CheckSalesInvoiceInXRechnungFormatVATRegNoMandatoryWithYourReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] When Buyer Reference resolves to Your Reference, VAT Registration No. is still required
        Initialize();

        // [GIVEN] Buyer Reference Mandatory is enabled
        SetBuyerReferenceMandatory();

        // [GIVEN] Sales Invoice for a customer without VAT Registration No. and without E-Invoice Routing No.
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithCustomerWithoutVATRegNoAndRoutingNo("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item));

        // [WHEN/THEN] Check throws an error - VAT Registration No. is required
        asserterror CheckSalesHeader(SalesHeader);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyHeaderData();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with header data from the document
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created
        VerifyHeaderData(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with customer reference
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with Customer X, E-invoice routing no. = XY
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XY
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/ubl:Invoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post Sales Invoice for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XX
        VerifyBuyerReference(SalesInvoiceHeader."Your Reference", TempXMLBuffer, '/ubl:Invoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatMandateBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Mandate buyer reference as your reference when releasing sales invoice for XRechnung format
        Initialize();

        // [GIVEN] Set Buyer reference = your reference
        SetBuyerReferenceMandatory();

        // [GIVEN] Create Sales Invoice for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);

        // [WHEN] Remove your reference
        SalesHeader.Validate("Your Reference", '');
        SalesHeader.Modify(false);

        // [THEN] Error message is shown when releasing the sales invoice
        asserterror CheckSalesHeader(SalesHeader);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyAccountingSupplierParty();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with company data as accounting supplier party
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyAccountingCustomerParty();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with customer data as accounting customer party
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with customer data as accounting customer party
        VerifyAccountingCustomerParty(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyPaymentMeans();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with bank informarion as payment means
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with bank informarion as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/ubl:Invoice/cac:PaymentMeans', CompanyInformation.IBAN, CompanyInformation."SWIFT Code");
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyBankAccountPaymentMeans();
    var
        BankAccount: Record "Bank Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BankAccountIBAN: Text[50];
        BankAccountSWIFT: Text[20];
    begin
        // [SCENARIO 496414] Export posted sales invoice uses Bank Account IBAN and SWIFT Code when Company Bank Account Code is specified
        Initialize();

        // [GIVEN] Create Bank Account with specific IBAN and SWIFT Code
        BankAccountIBAN := LibraryUtility.GenerateMOD97CompliantCode();
        BankAccountSWIFT := LibraryUtility.GenerateGUID();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.IBAN := BankAccountIBAN;
        BankAccount."SWIFT Code" := BankAccountSWIFT;
        BankAccount.Modify(true);

        // [GIVEN] Create and Post Sales Invoice with Bank Account Code
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithBankAccount("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, BankAccount."No."));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document uses Bank Account IBAN and SWIFT Code
        VerifyPaymentMeans(TempXMLBuffer, '/ubl:Invoice/cac:PaymentMeans', BankAccountIBAN, BankAccountSWIFT);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyPaymentTerms();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with payment terms
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with payment terms
        VerifyPaymentTerms(SalesInvoiceHeader."Payment Terms Code", TempXMLBuffer, '/ubl:Invoice/cac:PaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyTaxTotal();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with different tax totals
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with different tax totals
        VerifyTaxTotals(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyLegalMonetaryTotal();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with document totals
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyInvoiceLine();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales invoice creates electronic document in XRechnung format with 2 invoice lines
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 invoice lines
        VerifyInvoiceLine(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatIncludesGTIN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung item identification contains the item's GTIN and GS1 scheme
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] A posted item invoice where the item has a GTIN
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesInvoiceHeader, GTIN);

        // [WHEN] Export XRechnung Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Standard item identification contains the GTIN with scheme 0160
        Path := '/ubl:Invoice/cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetAttributeByPathWithError(TempXMLBuffer, Path, 'schemeID'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatOmitsBlankGTIN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung item identification omits a blank GTIN
        Initialize();

        // [GIVEN] A posted item invoice where the item has no GTIN
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Standard item identification does not exist
        Path := '/ubl:Invoice/cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatOmitsGTINForNonItemLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung item identification omits GTIN for a non-item line
        Initialize();

        // [GIVEN] A posted invoice with a non-item line
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::"G/L Account", false));

        // [WHEN] Export XRechnung Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Standard item identification does not exist
        Path := '/ubl:Invoice/cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyInvoiceLineWithLineDiscount();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in XRechnung format with 2 invoice lines, one line has line discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with line discount
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 invoice lines and one line has line discount
        VerifyInvoiceLineWithDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyPDFEmbeddedToXML()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice creates electronic document in XRechnung format with embedded PDF
        Initialize();

        // [GIVEN] Enable Embedding of PDF in export
        SetEdocumentServiceEmbedPDFInExport(true);

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] PDF is embedded in the XML
        VerifyInvoicePDFEmbeddedToXML(TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifySellerAddressFromRespCenter();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice creates electronic document in XRechnung format with seller info from responsibility center
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithRespCenter("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, ResponsibilityCenter.Code));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyVATEXCodeAndExemptionReason();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        InvoiceTaxCategoryTok: Label '/ubl:Invoice/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory', Locked = true;
        Path: Text;
    begin
        // [SCENARIO] Export posted sales invoice creates electronic document in XRechnung format with VATEX code and exemption reason from VAT Clause
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [GIVEN] VAT Clause with VATEX Code 'VATEX-EU-O' and Description 'Not subject to VAT' linked to the VAT Posting Setup
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        CreateVATClauseWithVATEXCode(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] TaxExemptionReasonCode and TaxExemptionReason are exported with correct values
        Path := InvoiceTaxCategoryTok + '/cbc:TaxExemptionReasonCode';
        Assert.AreEqual('VATEX-EU-O', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceTaxCategoryTok + '/cbc:TaxExemptionReason';
        Assert.AreEqual('Not subject to VAT', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;
    #endregion

    #region ServiceInvoice
    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyHeaderData();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with header data from the document
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created
        VerifyHeaderData(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with customer reference
        Initialize();

        // [GIVEN] Create and Post Service Invoice with Customer X, E-invoice routing no. = XY
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XY
        Customer.Get(ServiceInvoiceHeader."Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/ubl:Invoice');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post Service Invoice for customer without routing no.
        CreateServiceHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);
        ServiceInvoiceHeader.Get(PostServiceDocument(ServiceHeader));

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XX
        VerifyBuyerReference(ServiceInvoiceHeader."Your Reference", TempXMLBuffer, '/ubl:Invoice');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatMandateBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Mandate buyer reference as your reference when releasing service invoice for XRechnung format
        Initialize();

        // [GIVEN] Set Buyer reference = your reference
        SetBuyerReferenceMandatory();

        // [GIVEN] Create Service Invoice for customer without routing no.
        CreateServiceHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);

        // [WHEN] Remove your reference
        ServiceHeader.Validate("Your Reference", '');
        ServiceHeader.Modify(false);

        // [THEN] Error message is shown when releasing the service invoice
        asserterror CheckServiceHeader(ServiceHeader);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyAccountingSupplierParty();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with company data as accounting supplier party
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyAccountingCustomerParty();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with customer data as accounting customer party
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with customer data as accounting customer party
        VerifyAccountingCustomerParty(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyPaymentMeans();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with bank information as payment means
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with bank information as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/ubl:Invoice/cac:PaymentMeans');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyPaymentTerms();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with payment terms
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with payment terms
        VerifyPaymentTerms(ServiceInvoiceHeader."Payment Terms Code", TempXMLBuffer, '/ubl:Invoice/cac:PaymentTerms');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyTaxTotal();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with different tax totals
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with different tax totals
        VerifyTaxTotals(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyLegalMonetaryTotal();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with document totals
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyInvoiceLine();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with 2 invoice lines
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocumentWithTwoLines());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 invoice lines
        VerifyServiceInvoiceLine(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyPDFEmbeddedToXML()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with embedded PDF
        Initialize();

        // [GIVEN] Enable Embedding of PDF in export
        SetEdocumentServiceEmbedPDFInExport(true);

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] PDF is embedded in the XML
        VerifyInvoicePDFEmbeddedToXML(TempXMLBuffer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifySellerAddressFromRespCenter();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in XRechnung format with seller info from responsibility center
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocumentWithRespCenter(ResponsibilityCenter.Code));

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInXRechnungFormatVerifyDocumentAttachments();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CSVText1: Text;
        CSVText2: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Export posted service invoice creates electronic document in XRechnung format with document attachments embedded
        Initialize();

        // [GIVEN] Create and Post Service Invoice
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [GIVEN] Create two CSV document attachments
        CSVText1 := CreateCSVDocumentAttachment(ServiceInvoiceHeader, 'attachment.csv');
        CSVText2 := CreateCSVDocumentAttachment(ServiceInvoiceHeader, 'document.csv');

        // [WHEN] Export XRechnung Electronic Document
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document contains 2 AdditionalDocumentReference nodes
        VerifyCSVAttachments(TempXMLBuffer, 'attachment.csv', CSVText1, 'document.csv', CSVText2);
    end;
    #endregion

    #region SalesCreditMemo
    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyHeaderData();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with header data from the document
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created
        VerifyHeaderData(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatIncludesGTIN()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung credit-memo item identification contains the item's GTIN and GS1 scheme
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] A posted item credit memo where the item has a GTIN
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesCrMemoHeader, GTIN);

        // [WHEN] Export XRechnung Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Standard item identification contains the GTIN with scheme 0160
        Path := '/ns0:CreditNote/cac:CreditNoteLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetAttributeByPathWithError(TempXMLBuffer, Path, 'schemeID'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatOmitsBlankGTIN()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung credit-memo item identification omits a blank GTIN
        Initialize();

        // [GIVEN] A posted item credit memo where the item has no GTIN
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Standard item identification does not exist
        Path := '/ns0:CreditNote/cac:CreditNoteLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatOmitsGTINForNonItemLine()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported XRechnung credit-memo item identification omits GTIN for a non-item line
        Initialize();

        // [GIVEN] A posted credit memo with a non-item line
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::"G/L Account", false));

        // [WHEN] Export XRechnung Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Standard item identification does not exist
        Path := '/ns0:CreditNote/cac:CreditNoteLine/cac:Item/cac:StandardItemIdentification/cbc:ID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with customer reference
        Initialize();

        // [GIVEN] Create and Post sales cr. memo with Customer X, E-invoice routing no. = XY
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XY
        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/ns0:CreditNote');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post sales cr. memo for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XX
        VerifyBuyerReference(SalesCrMemoHeader."Your Reference", TempXMLBuffer, '/ns0:CreditNote');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatMandateBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Mandate buyer reference as your reference when releasing sales credit memo for XRechnung format
        Initialize();

        // [GIVEN] Set Buyer reference = your reference
        SetBuyerReferenceMandatory();

        // [GIVEN] Create Sales Credit Memo for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);

        // [WHEN] Remove your reference
        SalesHeader.Validate("Your Reference", '');
        SalesHeader.Modify(false);

        // [THEN] Error message is shown when releasing the sales invoice
        asserterror CheckSalesHeader(SalesHeader);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyAccountingSupplierParty();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with company data as accounting supplier party
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ns0:CreditNote/cac:AccountingSupplierParty/cac:Party');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyAccountingCustomerParty();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with customer data as accounting customer party
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with customer data as accounting customer party
        VerifyAccountingCustomerParty(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyPaymentMeans();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with bank informarion as payment means
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with bank informarion as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/ns0:CreditNote/cac:PaymentMeans');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyBankAccountPaymentMeans();
    var
        BankAccount: Record "Bank Account";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BankAccountIBAN: Text[50];
        BankAccountSWIFT: Text[20];
    begin
        // [SCENARIO 496414] Export posted sales cr. memo uses Bank Account IBAN and SWIFT Code when Company Bank Account Code is specified
        Initialize();

        // [GIVEN] Create Bank Account with specific IBAN and SWIFT Code
        BankAccountIBAN := LibraryUtility.GenerateMOD97CompliantCode();
        BankAccountSWIFT := LibraryUtility.GenerateGUID();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.IBAN := BankAccountIBAN;
        BankAccount."SWIFT Code" := BankAccountSWIFT;
        BankAccount.Modify(true);

        // [GIVEN] Create and Post sales cr. memo with Bank Account Code
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithBankAccount("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, BankAccount."No."));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document has payment means code
        VerifyPaymentMeans(TempXMLBuffer, '/ns0:CreditNote/cac:PaymentMeans');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyPaymentTerms();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with payment terms
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with payment terms
        VerifyPaymentTerms(SalesCrMemoHeader."Payment Terms Code", TempXMLBuffer, '/ns0:CreditNote/cac:PaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyTaxTotal();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with different tax totals
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with different tax totals
        VerifyTaxTotals(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyLegalMonetaryTotal();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with document totals
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyCrMemoLine();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 496414] Export posted sales cr. memo creates electronic document in XRechnung format with 2 cr.memo lines
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 cr.memo lines
        VerifyCrMemoLine(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyPDFEmbeddedToXML()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales cr. memo creates electronic document in XRechnung format with embedded PDF
        Initialize();

        // [GIVEN] Enable Embedding of PDF in export
        SetEdocumentServiceEmbedPDFInExport(true);

        // [GIVEN] Create and Post Sales Cr. Memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] PDF is embedded in the XML
        VerifyCrMemoPDFEmbeddedToXML(TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifySellerAddressFromRespCenter();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales credit memo creates electronic document in XRechnung format with seller info from responsibility center
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Sales Invoice.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithRespCenter("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, ResponsibilityCenter.Code));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ns0:CreditNote/cac:AccountingSupplierParty/cac:Party', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyVATEXCodeAndExemptionReason();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        CrMemoTaxCategoryTok: Label '/ns0:CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory', Locked = true;
        Path: Text;
    begin
        // [SCENARIO] Export posted sales cr. memo creates electronic document in XRechnung format with VATEX code and exemption reason from VAT Clause
        Initialize();

        // [GIVEN] Create and Post Sales Credit Memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [GIVEN] VAT Clause with VATEX Code 'VATEX-EU-O' and Description 'Not subject to VAT' linked to the VAT Posting Setup
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        CreateVATClauseWithVATEXCode(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] TaxExemptionReasonCode and TaxExemptionReason are exported with correct values
        Path := CrMemoTaxCategoryTok + '/cbc:TaxExemptionReasonCode';
        Assert.AreEqual('VATEX-EU-O', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoTaxCategoryTok + '/cbc:TaxExemptionReason';
        Assert.AreEqual('Not subject to VAT', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;
    #endregion

    #region ServiceCreditMemo
    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyHeaderData();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with header data from the document
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created
        VerifyHeaderData(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with customer reference
        Initialize();

        // [GIVEN] Create and Post service cr. memo with Customer X, E-invoice routing no. = XY
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XY
        Customer.Get(ServiceCrMemoHeader."Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/ns0:CreditNote');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post service cr. memo for customer without routing no.
        CreateServiceCrMemoHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);
        ServiceCrMemoHeader.Get(PostServiceCrMemoDocument(ServiceHeader));

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with buyer reference XX
        VerifyBuyerReference(ServiceCrMemoHeader."Your Reference", TempXMLBuffer, '/ns0:CreditNote');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatMandateBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Mandate buyer reference as your reference when releasing service credit memo for XRechnung format
        Initialize();

        // [GIVEN] Set Buyer reference = your reference
        SetBuyerReferenceMandatory();

        // [GIVEN] Create Service Credit Memo for customer without routing no.
        CreateServiceCrMemoHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);

        // [WHEN] Remove your reference
        ServiceHeader.Validate("Your Reference", '');
        ServiceHeader.Modify(false);

        // [THEN] Error message is shown when releasing the service credit memo
        asserterror CheckServiceHeader(ServiceHeader);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyAccountingSupplierParty();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with company data as accounting supplier party
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ns0:CreditNote/cac:AccountingSupplierParty/cac:Party');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyAccountingCustomerParty();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with customer data as accounting customer party
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with customer data as accounting customer party
        VerifyAccountingCustomerParty(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyPaymentMeans();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with bank information as payment means
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with bank information as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/ns0:CreditNote/cac:PaymentMeans');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyPaymentTerms();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with payment terms
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with payment terms
        VerifyPaymentTerms(ServiceCrMemoHeader."Payment Terms Code", TempXMLBuffer, '/ns0:CreditNote/cac:PaymentTerms');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyTaxTotal();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with different tax totals
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with different tax totals
        VerifyTaxTotals(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyLegalMonetaryTotal();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with document totals
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyCrMemoLine();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with 2 cr.memo lines
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocumentWithTwoLines());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 cr.memo lines
        VerifyServiceCrMemoLine(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifyPDFEmbeddedToXML()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in XRechnung format with embedded PDF
        Initialize();

        // [GIVEN] Enable Embedding of PDF in export
        SetEdocumentServiceEmbedPDFInExport(true);

        // [GIVEN] Create and Post Service Cr. Memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] PDF is embedded in the XML
        VerifyCrMemoPDFEmbeddedToXML(TempXMLBuffer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportPostedServiceCrMemoInXRechnungFormatVerifySellerAddressFromRespCenter();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service credit memo creates electronic document in XRechnung format with seller info from responsibility center
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Service Credit Memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocumentWithRespCenter(ResponsibilityCenter.Code));

        // [WHEN] Export XRechnung Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with company data as accounting supplier party
        VerifyAccountingSupplierParty(TempXMLBuffer, '/ns0:CreditNote/cac:AccountingSupplierParty/cac:Party', ResponsibilityCenter);
    end;
    #endregion

    #region InvoiceDiscount
    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyInvoiceWithInvoiceDiscounts();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in XRechnung format with 2 invoice lines and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 invoice lines and invoice discount
        VerifyInvoiceWithInvDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyInvoiceWithInvoiceDiscountsAndLineDiscount();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in XRechnung format with 2 invoice lines with discount and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount and line discount on one line
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 invoice lines with line discount and invoice discount
        VerifyInvoiceWithInvDiscount(SalesInvoiceHeader, TempXMLBuffer);
        VerifyInvoiceLineWithDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyCrMemoWithInvoiceDiscounts();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales cr. memo creates electronic document in XRechnung format with 2 lines and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 lines and invoice discount
        VerifyCrMemoWithInvDiscount(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyCrMemoWithInvoiceDiscountsAndLineDiscount();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales cr.memo creates electronic document in XRechnung format with 2 cr.memo lines with discount and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo with invoice discount and line discount on one line
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] XRechnung Electronic Document is created with 2 lines with line discount and invoice discount
        VerifyCrMemoWithInvDiscount(SalesCrMemoHeader, TempXMLBuffer);
        VerifyCrMemoLineWithDiscounts(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyInvoiceDiscountMultiplierHasFiveDecimals();
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        MultiplierFactorTok: Label '/ubl:Invoice/cac:AllowanceCharge/cbc:MultiplierFactorNumeric', Locked = true;
        ExpectedMultiplierFactor: Text;
    begin
        // [SCENARIO 588110] Document discount MultiplierFactorNumeric is exported with at most 5 decimal places
        Initialize();

        // [GIVEN] Create sales invoice with a deterministic invoice discount that results in a multiplier with > 2 decimals
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice);
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        SalesLine.Next();
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 23.45);
        SalesLine.Modify(true);

        LibrarySales.SetCalcInvDiscount(true);
        SalesHeader.CalcFields(Amount);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(10, SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] MultiplierFactorNumeric matches the exact five-decimal-formatted expected value (detects truncation to 2 decimals)
        SalesInvoiceHeader.CalcFields(Amount, "Invoice Discount Amount");
        ExpectedMultiplierFactor :=
            ExportXRechnungDocument.FormatFiveDecimal(
                100 * SalesInvoiceHeader."Invoice Discount Amount" / (SalesInvoiceHeader."Invoice Discount Amount" + SalesInvoiceHeader.Amount));
        Assert.AreEqual(ExpectedMultiplierFactor, GetNodeByPathWithError(TempXMLBuffer, MultiplierFactorTok), StrSubstNo(IncorrectValueErr, MultiplierFactorTok));
    end;
    #endregion

    #region GLN
    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifySupplierGLNWithSchemeID();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 588110] Supplier GLN is exported with schemeID 0088 in XRechnung format
        Initialize();

        // [GIVEN] Company is set up to use GLN in electronic documents
        SetCompanyGLN(SupplierGLN());

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Supplier PartyIdentification ID is the GLN with schemeID = 0088
        Assert.AreEqual(SupplierGLN(), GetNodeByPathWithError(TempXMLBuffer, SupplierPartyIdTok), StrSubstNo(IncorrectValueErr, SupplierPartyIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, SupplierPartyIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, SupplierPartyIdTok + '/@schemeID'));
        Assert.AreEqual(SupplierGLN(), GetNodeByPathWithError(TempXMLBuffer, SupplierLegalEntityIdTok), StrSubstNo(IncorrectValueErr, SupplierLegalEntityIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, SupplierLegalEntityIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, SupplierLegalEntityIdTok + '/@schemeID'));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyCustomerGLNWithSchemeID();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 588110] Customer GLN is exported with schemeID 0088 in XRechnung format
        Initialize();

        // [GIVEN] Create and Post Sales Invoice for a customer that uses GLN in electronic documents
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(CustomerGLN(), ShipToGLN(), true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Customer PartyIdentification ID is the GLN with schemeID = 0088
        Assert.AreEqual(CustomerGLN(), GetNodeByPathWithError(TempXMLBuffer, CustomerPartyIdTok), StrSubstNo(IncorrectValueErr, CustomerPartyIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, CustomerPartyIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, CustomerPartyIdTok + '/@schemeID'));
        Assert.AreEqual(CustomerGLN(), GetNodeByPathWithError(TempXMLBuffer, CustomerLegalEntityIdTok), StrSubstNo(IncorrectValueErr, CustomerLegalEntityIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, CustomerLegalEntityIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, CustomerLegalEntityIdTok + '/@schemeID'));
        Assert.AreEqual(ShipToGLN(), GetNodeByPathWithError(TempXMLBuffer, DeliveryLocationIdTok), StrSubstNo(IncorrectValueErr, DeliveryLocationIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, DeliveryLocationIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, DeliveryLocationIdTok + '/@schemeID'));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatFallsBackToCustomerGLNWhenShipToGLNIsBlank();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Customer GLN is used when the ship-to address GLN is blank
        Initialize();

        // [GIVEN] A customer with GLN and a ship-to address without GLN
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(CustomerGLN(), '', true));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Delivery location uses the customer GLN with schemeID 0088
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, DeliveryLocationIdTok);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatDoesNotExportCustomerGLNWhenDisabled();
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Customer GLN is not exported in XRechnung format when GLN use is disabled
        Initialize();

        // [GIVEN] A customer and ship-to address with GLNs, but GLN use in electronic documents disabled
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(CustomerGLN(), ShipToGLN(), false));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Customer party uses the VAT registration number and GLN identifiers are not exported
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Assert.AreEqual(
            GetVATRegistrationNo(Customer."VAT Registration No.", SalesInvoiceHeader."Bill-to Country/Region Code"),
            GetNodeByPathWithError(TempXMLBuffer, CustomerPartyIdTok),
            StrSubstNo(IncorrectValueErr, CustomerPartyIdTok));
        VerifyNodeDoesNotExist(TempXMLBuffer, CustomerLegalEntityIdTok);
        VerifyNodeDoesNotExist(TempXMLBuffer, DeliveryLocationIdTok);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportPostedSalesInvoiceInXRechnungFormatUsesSellToGLNForCustomerParty();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Sell-to GLN identifies the customer party and delivery
        Initialize();

        // [GIVEN] A posted sales invoice with different sell-to and bill-to customer GLNs
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithDifferentSellToAndBillToGLNs(CustomerGLN(), SupplierGLN()));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Customer party and delivery use sell-to GLN with schemeID 0088
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, CustomerPartyIdTok);
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, CustomerLegalEntityIdTok);
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, DeliveryLocationIdTok);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifySupplierRegistrationNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        RegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 646793] Supplier Registration No. is exported as the FC tax identifier when GLN and VAT ID are unavailable
        Initialize();

        // [GIVEN] Company "C" has a Registration No. but no GLN or VAT ID
        RegistrationNo := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(RegistrationNo));
        SetCompanyRegistrationNo(RegistrationNo);
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export XRechnung electronic document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Supplier tax identifier contains the Registration No. with FC tax scheme
        Assert.AreEqual(RegistrationNo, GetNodeByPathWithError(TempXMLBuffer, SupplierTaxSchemeTok + '/cbc:CompanyID'), StrSubstNo(IncorrectValueErr, SupplierTaxSchemeTok));
        Assert.AreEqual('FC', GetNodeByPathWithError(TempXMLBuffer, SupplierTaxSchemeTok + '/cac:TaxScheme/cbc:ID'), StrSubstNo(IncorrectValueErr, SupplierTaxSchemeTok));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyCustomerGLNWithSchemeID();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 588110] Customer GLN is exported with schemeID 0088 in XRechnung credit memo format
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo for a customer that uses GLN in electronic documents
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoForCustomerWithGLN(CustomerGLN()));

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Customer and delivery identifiers contain the customer GLN with schemeID 0088
        Assert.AreEqual(CustomerGLN(), GetNodeByPathWithError(TempXMLBuffer, CreditMemoCustomerPartyIdTok), StrSubstNo(IncorrectValueErr, CreditMemoCustomerPartyIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, CreditMemoCustomerPartyIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, CreditMemoCustomerPartyIdTok + '/@schemeID'));
        Assert.AreEqual(CustomerGLN(), GetNodeByPathWithError(TempXMLBuffer, CreditMemoCustomerLegalEntityIdTok), StrSubstNo(IncorrectValueErr, CreditMemoCustomerLegalEntityIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, CreditMemoCustomerLegalEntityIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, CreditMemoCustomerLegalEntityIdTok + '/@schemeID'));
        Assert.AreEqual(CustomerGLN(), GetNodeByPathWithError(TempXMLBuffer, CreditMemoDeliveryLocationIdTok), StrSubstNo(IncorrectValueErr, CreditMemoDeliveryLocationIdTok));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, CreditMemoDeliveryLocationIdTok, 'schemeID'), StrSubstNo(IncorrectValueErr, CreditMemoDeliveryLocationIdTok + '/@schemeID'));
    end;
    #endregion

    #region PurchaseInvoice
    [Test]
    procedure ReleasePurchaseInvoiceInXRechnungFormat();
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Release purchase invoice regardless if XRechnung format is setup with customer reference
        Initialize();

        // [GIVEN] Set Buyer reference = customer reference
        SetBuyerReferenceMandatory();

        // [WHEN] Create and release Purchase Invoice
        CreatePurchDocument(PurchaseHeader, "Purchase Document Type"::Invoice);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] No error occurs
    end;
    #endregion

    #region PurchaseCreditMemo
    [Test]
    procedure ReleasePurchaseCreditMemoInXRechnungFormat();
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Release purchase credit memo regardless if XRechnung format is setup with customer reference
        Initialize();

        // [GIVEN] Set Buyer reference = customer reference
        SetBuyerReferenceMandatory();

        // [WHEN] Create and release Purchase credit Memo
        CreatePurchDocument(PurchaseHeader, "Purchase Document Type"::"Credit Memo");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] No error occurs
    end;
    #endregion

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyUnsupportedAttachmentIsSkipped();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        RecRef: RecordRef;
        CSVText: Text;
    begin
        // [SCENARIO] Attachments with unsupported MIME types are not exported in XRechnung format
        Initialize();

        // [GIVEN] Create and Post Sales Invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, "Sales Line Type"::Item, false));
        RecRef.GetTable(SalesInvoiceHeader);

        // [GIVEN] Create one supported CSV attachment and one unsupported TXT attachment
        CSVText := CreateCSVDocumentAttachment(RecRef, 'data.csv');
        CreateDocumentAttachment(RecRef, 'report.txt', 'Some text content');

        // [WHEN] Export XRechnung Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Only the CSV attachment (supported) is present; TXT is skipped
        VerifyAdditionalDocumentReferenceCount(TempXMLBuffer, 1);
        VerifyCSVAttachmentInXML(TempXMLBuffer, 'data.csv', 'text/csv', CSVText);
    end;

    #region TwoDecimalPlaces
    [Test]
    procedure FormatDecimalWithTwoDecimalPlacesFlagReturnsTrailingZero();
    begin
        // [SCENARIO] FormatDecimal with IncludeDecimalPlaces = true always formats amount with exactly two decimal places
        Initialize();

        // [WHEN/THEN] A value with one significant decimal place gets the trailing zero
        Assert.AreEqual('1.10', ExportXRechnungDocument.FormatDecimal(1.1, true), 'FormatDecimal(1.1, true) should return ''1.10''');
        // [WHEN/THEN] A whole number gets two decimal zeros
        Assert.AreEqual('1.00', ExportXRechnungDocument.FormatDecimal(1, true), 'FormatDecimal(1, true) should return ''1.00''');
        // [WHEN/THEN] A value with two decimal places is unchanged
        Assert.AreEqual('1.23', ExportXRechnungDocument.FormatDecimal(1.23, true), 'FormatDecimal(1.23, true) should return ''1.23''');
    end;

    [Test]
    procedure FormatDecimalWithoutTwoDecimalPlacesFlagNoTrailingZero();
    begin
        // [SCENARIO] FormatDecimal with IncludeDecimalPlaces = false uses the default format without trailing zeros
        Initialize();

        // [WHEN/THEN] A value with one significant decimal place has no trailing zero
        Assert.AreEqual('1.1', ExportXRechnungDocument.FormatDecimal(1.1, false), 'FormatDecimal(1.1, false) should return ''1.1''');
        // [WHEN/THEN] A whole number has no decimal places
        Assert.AreEqual('1', ExportXRechnungDocument.FormatDecimal(1, false), 'FormatDecimal(1, false) should return ''1''');
        // [WHEN/THEN] A value with two decimal places is unchanged
        Assert.AreEqual('1.23', ExportXRechnungDocument.FormatDecimal(1.23, false), 'FormatDecimal(1.23, false) should return ''1.23''');
    end;

    [Test]
    procedure FormatDecimalUnlimitedWithMinTwoDecimalsReturnsTrailingZero();
    begin
        // [SCENARIO] FormatDecimalUnlimited with IncludeMinTwoDecimals = true ensures minimum two decimal places while preserving extended precision
        Initialize();

        // [WHEN/THEN] A value with one significant decimal place gets the trailing zero
        Assert.AreEqual('1.10', ExportXRechnungDocument.FormatDecimalUnlimited(1.1, true), 'FormatDecimalUnlimited(1.1, true) should return ''1.10''');
        // [WHEN/THEN] A whole number gets two decimal zeros
        Assert.AreEqual('1.00', ExportXRechnungDocument.FormatDecimalUnlimited(1, true), 'FormatDecimalUnlimited(1, true) should return ''1.00''');
        // [WHEN/THEN] A value with two decimal places is unchanged
        Assert.AreEqual('1.23', ExportXRechnungDocument.FormatDecimalUnlimited(1.23, true), 'FormatDecimalUnlimited(1.23, true) should return ''1.23''');
        // [WHEN/THEN] A value with extended decimal places preserves full precision
        Assert.AreEqual('5.12345', ExportXRechnungDocument.FormatDecimalUnlimited(5.12345, true), 'FormatDecimalUnlimited(5.12345, true) should return ''5.12345''');
    end;

    [Test]
    procedure FormatDecimalUnlimitedWithoutMinTwoDecimalsUnbounded();
    begin
        // [SCENARIO] FormatDecimalUnlimited with IncludeMinTwoDecimals = false uses unlimited precision without minimum decimal places
        Initialize();

        // [WHEN/THEN] A value with one significant decimal place has no trailing zero
        Assert.AreEqual('1.1', ExportXRechnungDocument.FormatDecimalUnlimited(1.1, false), 'FormatDecimalUnlimited(1.1, false) should return ''1.1''');
        // [WHEN/THEN] A whole number has no decimal places
        Assert.AreEqual('1', ExportXRechnungDocument.FormatDecimalUnlimited(1, false), 'FormatDecimalUnlimited(1, false) should return ''1''');
        // [WHEN/THEN] A value with two decimal places is unchanged
        Assert.AreEqual('1.23', ExportXRechnungDocument.FormatDecimalUnlimited(1.23, false), 'FormatDecimalUnlimited(1.23, false) should return ''1.23''');
        // [WHEN/THEN] A value with extended decimal places preserves full precision
        Assert.AreEqual('5.12345', ExportXRechnungDocument.FormatDecimalUnlimited(5.12345, false), 'FormatDecimalUnlimited(5.12345, false) should return ''5.12345''');
    end;
    #endregion

    #region ItemCharge
    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyDocumentLevelItemChargeAllowanceCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge classified as a document level allowance/charge is exported as cac:AllowanceCharge under the invoice instead of as an invoice line
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and one item charge assigned to both of them
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] A document level charge is exported with the amount and the VAT category of the item charge
        Path := DocumentAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/cac:TaxCategory/cbc:ID';
        Assert.AreEqual(TaxCategoryStandardTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/cac:TaxCategory/cbc:Percent';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(ChargeSalesInvoiceLine."VAT %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item charge is no longer exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'Only the item lines must be exported as invoice lines.');
        Assert.IsFalse(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID', ItemChargeNo), 'The item charge must not be exported as an invoice line.');

        // [THEN] The charge is not repeated as a line level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'A document level charge must not be exported inside an invoice line.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyDocumentLevelItemChargeReason()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] The reason text and reason code of the item charge are exported on the document level allowance/charge
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with an item charge that is a document level charge
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));

        // [GIVEN] The item charge carries a reason text and a reason code
        SetItemChargeReason(ItemChargeNo, ItemChargeReasonTextTok, ItemChargeReasonCodeTok);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The reason code and the reason text of the item charge are exported
        Path := DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual(ItemChargeReasonTextTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyDocumentLevelItemChargeReasonFallsBackToDescription()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Without a reason text on the item charge the description of the item charge line is exported, so that the mandatory allowance/charge reason is never empty
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with an item charge that is a document level charge and has no reason text
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The description of the item charge line is exported as the reason
        Path := DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual(ChargeSalesInvoiceLine.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] No empty reason code is exported
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReasonCode'), 'An item charge without a reason code must not export an empty reason code.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyDocumentLevelItemChargeReasonFallsBackToItemChargeNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Without a reason text, a reason code and a line description the item charge code is exported as the reason, so that the allowance/charge always carries one of the two reason elements EN 16931 requires
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with a document level item charge that has neither a reason text, nor a reason code, nor a line description
        SalesInvoiceHeader.Get(
            CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::Invoice, 2, 2, 2, LibraryRandom.RandDecInRange(10, 50, 2), true, ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        Assert.AreEqual('', ChargeSalesInvoiceLine.Description, 'The scenario requires an item charge line without a description.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The code of the item charge is exported as the reason
        Path := DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual(ItemChargeNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyDocumentLevelItemChargeWithReasonCodeOnlyKeepsTheReasonCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A reason code alone already satisfies the reason requirement of EN 16931, so the item charge code is not substituted as the reason text
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with a document level item charge without a line description
        SalesInvoiceHeader.Get(
            CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::Invoice, 2, 2, 2, LibraryRandom.RandDecInRange(10, 50, 2), true, ItemChargeNo));

        // [GIVEN] The item charge carries a reason code but no reason text
        SetItemChargeReason(ItemChargeNo, '', ItemChargeReasonCodeTok);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The reason code of the item charge is exported
        Path := DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The code of the item charge is not exported as the reason
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason'), 'An item charge with a reason code must not fall back to the item charge code as the reason.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyLineLevelItemChargeAllowanceCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge classified as a line level allowance/charge is exported inside the invoice line it is assigned to
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with one item line and an item charge with the same VAT assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        GetItemInvoiceLine(SalesInvoiceHeader, ItemSalesInvoiceLine);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the invoice line of the assigned line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Path := InvoiceLineTok + '/cbc:ID';
        Assert.AreEqual(Format(ItemSalesInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The line level allowance/charge carries no VAT category, because the VAT category of the invoice line applies
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok + '/cac:TaxCategory/cbc:ID'), 'A line level allowance/charge must not carry its own VAT category.');

        // [THEN] The charge is not repeated as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'A line level charge must not be exported as a document level allowance/charge.');

        // [THEN] The net amount of the invoice line includes the charge
        Path := InvoiceLineTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ItemSalesInvoiceLine.Amount + ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyLineLevelItemChargeOnlyAffectsTheAssignedLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        AssignedLineAmount: Decimal;
        UnassignedLineAmount: Decimal;
        Path: Text;
    begin
        // [SCENARIO] A line level allowance/charge is exported only in the invoice line it is assigned to, and leaves the other invoice lines untouched
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and an item charge assigned to the first line only
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        GetItemInvoiceLine(SalesInvoiceHeader, ItemSalesInvoiceLine);
        AssignedLineAmount := ItemSalesInvoiceLine.Amount;
        ItemSalesInvoiceLine.Next();
        UnassignedLineAmount := ItemSalesInvoiceLine.Amount;

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Exactly one invoice line carries the allowance/charge
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'The charge must be exported in the assigned invoice line only.');

        // [THEN] Only the assigned invoice line reports the charge in its net amount
        Path := InvoiceLineTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(AssignedLineAmount + ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(UnassignedLineAmount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyItemChargeInvoiceLineUsesFallbackQuantityAndUnitCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge exported as a regular invoice line carries quantity 1 and the unit code C62, never an empty unit code
        Initialize();

        // [GIVEN] A service that forces item charges into an invoice line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales invoice with one item line and an item charge of quantity 2 assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        GetItemInvoiceLine(SalesInvoiceHeader, ItemSalesInvoiceLine);
        Assert.AreEqual(2, ChargeSalesInvoiceLine.Quantity, 'The scenario requires an item charge quantity that differs from the fallback quantity.');
        Assert.AreEqual('', ChargeSalesInvoiceLine."Unit of Measure Code", 'The scenario requires an item charge line without a unit of measure.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line.');
        Path := InvoiceLineTok + '/cbc:ID';
        Assert.AreEqual(Format(ChargeSalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The invoice line of the item charge carries quantity 1 and the unit code C62
        Path := InvoiceLineTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual('1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The unit price of the invoice line matches the net amount, so that quantity times price stays the net amount of the line
        Path := InvoiceLineTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item line keeps its own quantity and unit code
        Path := InvoiceLineTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ItemSalesInvoiceLine.Quantity), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(ExportXRechnungDocument.GetUoMCode(ItemSalesInvoiceLine."Unit of Measure Code"), GetAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyItemChargeInvoiceLineUsesUnitCodeOfItemCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A unit code configured on the item charge replaces C62 on the invoice line of the item charge
        Initialize();

        // [GIVEN] A service that forces item charges into an invoice line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales invoice with an item charge that carries the unit code HUR
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        SetItemChargeUnitCode(ItemChargeNo, UnitCodeHourTok);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The invoice line of the item charge carries the unit code of the item charge
        Path := InvoiceLineTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(UnitCodeHourTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyNegativeItemChargeInvoiceLineUsesNegativeQuantity()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge exported as a regular invoice line reports a negative quantity and a positive unit price, so that the exported document satisfies BR-27
        Initialize();

        // [GIVEN] A service that forces item charges into an invoice line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales invoice with one item line and a negative item charge assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        Assert.IsTrue(ChargeSalesInvoiceLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line.');
        Path := InvoiceLineTok + '/cbc:ID';
        Assert.AreEqual(Format(ChargeSalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The invoice line of the item charge reports the negative fallback quantity with the fallback unit code
        Path := InvoiceLineTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual('-1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The unit price of the invoice line is not negative, because the item net price must never be negative
        Path := InvoiceLineTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(-ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The net amount of the invoice line stays negative
        Path := InvoiceLineTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The quantity of the invoice line times its unit price stays the net amount of the line
        VerifyLastLineAmountMatchesQuantityTimesPrice(
            TempXMLBuffer, InvoiceLineTok + '/cbc:InvoicedQuantity', InvoiceLineTok + '/cac:Price/cbc:PriceAmount', InvoiceLineTok + '/cbc:LineExtensionAmount');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyNegativeItemChargeIsExportedAsAllowance()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge is exported as an allowance with a positive amount
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and a negative item charge assigned to both of them
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        Assert.IsTrue(ChargeSalesInvoiceLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported as an allowance with a positive amount
        Path := DocumentAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('false', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(-ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The allowance is reported in the allowance total and not in the charge total
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        Path := LegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(-ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, LegalMonetaryTotalTok + '/cbc:ChargeTotalAmount'), 'A negative item charge must not be reported as a charge total.');

        // [THEN] The totals stay consistent
        Path := LegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := LegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyForcedLineLevelItemChargeWithoutTargetLineIsDocumentLevel()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A forced line level allowance/charge that cannot be resolved to a single invoice line degrades to a document level allowance/charge
        Initialize();

        // [GIVEN] A service that forces item charges into an invoice line allowance/charge
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line Allowance/Charge");

        // [GIVEN] A posted sales invoice with an item charge assigned to two item lines, so that no single target line can be resolved
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported at document level instead of inside an invoice line
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'An unresolved line level charge must not be exported inside an invoice line.');
        Path := DocumentAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The charge is not exported as an invoice line either
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'Only the item lines must be exported as invoice lines.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyChargeOnlyInvoiceKeepsInvoiceLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
    begin
        // [SCENARIO] A posted sales invoice whose only line is an item charge keeps that line as an invoice line even when the service forces a document level allowance/charge, so that the exported document satisfies BR-16
        Initialize();

        // [GIVEN] A service that forces item charges into a document level allowance/charge
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [GIVEN] A posted sales invoice that only contains an item charge assigned to an earlier shipment
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithShipmentChargeOnly(ItemChargeNo));

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported as the only invoice line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line, so that the document keeps at least one invoice line.');
        Assert.IsTrue(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID', ItemChargeNo), 'The exported invoice line must be the item charge.');

        // [THEN] The charge is not exported as an allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'The item charge must not be exported as a document level allowance/charge.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyTotalsWithDocumentLevelItemCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Moving an item charge out of the invoice lines keeps the document totals and the tax subtotals consistent
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and one item charge assigned to both of them
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The sum of the invoice lines no longer contains the charge and the charge is reported as the charge total
        Path := LegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := LegalMonetaryTotalTok + '/cbc:ChargeTotalAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, LegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount'), 'A positive item charge must not be reported as an allowance total.');

        // [THEN] The exported invoice lines add up to the reported line extension amount
        Assert.AreEqual(
            SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount, SumNodeValuesByPath(TempXMLBuffer, InvoiceLineTok + '/cbc:LineExtensionAmount'),
            'The exported invoice lines must add up to the reported line extension amount.');

        // [THEN] The remaining document totals are unchanged
        Path := LegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := LegalMonetaryTotalTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := LegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := TaxTotalPathTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := TaxTotalPathTok + '/cac:TaxSubtotal/cbc:TaxableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyTotalsWithLineLevelItemCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A line level allowance/charge stays inside the sum of the invoice lines and leaves the document totals untouched
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with one item line and an item charge with the same VAT assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the invoice line it is assigned to
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'The item charge must be exported as a line level allowance/charge.');

        // [THEN] The line extension amount still contains the charge and no charge total is reported
        Path := LegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, LegalMonetaryTotalTok + '/cbc:ChargeTotalAmount'), 'A line level charge must not be reported as a charge total.');
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, LegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount'), 'A line level charge must not be reported as an allowance total.');

        // [THEN] The exported invoice lines add up to the reported line extension amount
        Assert.AreEqual(
            SalesInvoiceHeader.Amount, SumNodeValuesByPath(TempXMLBuffer, InvoiceLineTok + '/cbc:LineExtensionAmount'),
            'The exported invoice lines must add up to the reported line extension amount.');

        // [THEN] The remaining document totals are unchanged
        Path := LegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := LegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := TaxTotalPathTok + '/cac:TaxSubtotal/cbc:TaxableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyDocumentLevelItemChargeAllowanceCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo classified as a document level allowance/charge is exported as cac:AllowanceCharge under the credit note instead of as a credit note line
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with two item lines and one item charge assigned to both of them
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);

        // [THEN] The item charge line of the credit memo carries a positive amount, so that a charge on a credit note keeps the charge indicator of an invoice
        Assert.IsTrue(ChargeSalesCrMemoLine.Amount > 0, 'The scenario requires a positive item charge amount on the credit memo.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] A document level charge is exported with the amount and the VAT category of the item charge
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoDocumentAllowanceChargeTok + '/cac:TaxCategory/cbc:ID';
        Assert.AreEqual(TaxCategoryStandardTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoDocumentAllowanceChargeTok + '/cac:TaxCategory/cbc:Percent';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(ChargeSalesCrMemoLine."VAT %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The reason text and the reason code of the item charge line are exported
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual(ChargeSalesCrMemoLine.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item charge is no longer exported as a credit note line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, CrMemoLineTok), 'Only the item lines must be exported as credit note lines.');
        Assert.IsFalse(NodeValueExists(TempXMLBuffer, CrMemoLineTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID', ItemChargeNo), 'The item charge must not be exported as a credit note line.');

        // [THEN] The charge is not repeated as a line level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLineAllowanceChargeTok), 'A document level charge must not be exported inside a credit note line.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyDocumentLevelItemChargeReasonFallsBackToItemChargeNo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Without a reason text, a reason code and a line description the item charge code is exported as the reason, so that the allowance/charge always carries one of the two reason elements EN 16931 requires
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with a document level item charge that has neither a reason text, nor a reason code, nor a line description
        SalesCrMemoHeader.Get(
            CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::"Credit Memo", 2, 2, 2, LibraryRandom.RandDecInRange(10, 50, 2), true, ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.AreEqual('', ChargeSalesCrMemoLine.Description, 'The scenario requires an item charge line without a description.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The code of the item charge is exported as the reason
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual(ItemChargeNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyDocumentLevelItemChargeWithReasonCodeOnlyKeepsTheReasonCode()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A reason code alone already satisfies the reason requirement of EN 16931, so the item charge code is not substituted as the reason text
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with a document level item charge without a line description
        SalesCrMemoHeader.Get(
            CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::"Credit Memo", 2, 2, 2, LibraryRandom.RandDecInRange(10, 50, 2), true, ItemChargeNo));

        // [GIVEN] The item charge carries a reason code but no reason text
        SetItemChargeReason(ItemChargeNo, '', ItemChargeReasonCodeTok);

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The reason code of the item charge is exported
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:AllowanceChargeReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The code of the item charge is not exported as the reason
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoDocumentAllowanceChargeTok + '/cbc:AllowanceChargeReason'), 'An item charge with a reason code must not fall back to the item charge code as the reason.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyLineLevelItemChargeAllowanceCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo classified as a line level allowance/charge is exported inside the credit note line it is assigned to
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with one item line and an item charge with the same VAT assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        GetItemCrMemoLine(SalesCrMemoHeader, ItemSalesCrMemoLine);

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the credit note line of the assigned line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, CrMemoLineTok), 'The item charge must not be exported as a separate credit note line.');
        Path := CrMemoLineTok + '/cbc:ID';
        Assert.AreEqual(Format(ItemSalesCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLineAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLineAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The line level allowance/charge carries no VAT category, because the VAT category of the credit note line applies
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLineAllowanceChargeTok + '/cac:TaxCategory/cbc:ID'), 'A line level allowance/charge must not carry its own VAT category.');

        // [THEN] The charge is not repeated as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoDocumentAllowanceChargeTok), 'A line level charge must not be exported as a document level allowance/charge.');

        // [THEN] The net amount of the credit note line includes the charge
        Path := CrMemoLineTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ItemSalesCrMemoLine.Amount + ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyItemChargeCrMemoLineUsesFallbackQuantityAndUnitCode()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo exported as a regular credit note line carries quantity 1 and the unit code C62, never an empty unit code
        Initialize();

        // [GIVEN] A service that forces item charges into a document line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales credit memo with one item line and an item charge of quantity 2 assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.AreEqual(2, ChargeSalesCrMemoLine.Quantity, 'The scenario requires an item charge quantity that differs from the fallback quantity.');
        Assert.AreEqual('', ChargeSalesCrMemoLine."Unit of Measure Code", 'The scenario requires an item charge line without a unit of measure.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as a credit note line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, CrMemoLineTok), 'The item charge must be exported as a credit note line.');
        Path := CrMemoLineTok + '/cbc:ID';
        Assert.AreEqual(Format(ChargeSalesCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The credit note line of the item charge carries quantity 1 and the unit code C62
        Path := CrMemoLineTok + '/cbc:CreditedQuantity';
        Assert.AreEqual('1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The unit price of the credit note line matches the net amount, so that quantity times price stays the net amount of the line
        Path := CrMemoLineTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ChargeSalesCrMemoLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] No allowance/charge is exported for the item charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoDocumentAllowanceChargeTok), 'An item charge exported as a credit note line must not be exported as an allowance/charge.');
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLineAllowanceChargeTok), 'An item charge exported as a credit note line must not be exported as an allowance/charge.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyNegativeItemChargeCrMemoLineUsesNegativeQuantity()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge of a posted sales credit memo exported as a regular credit note line reports a negative quantity and a positive unit price, so that the exported document satisfies BR-27
        Initialize();

        // [GIVEN] A service that forces item charges into a document line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales credit memo with one item line and a negative item charge assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.IsTrue(ChargeSalesCrMemoLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The credit note line of the item charge reports the negative fallback quantity with the fallback unit code
        Path := CrMemoLineTok + '/cbc:CreditedQuantity';
        Assert.AreEqual('-1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The unit price of the credit note line is not negative, because the item net price must never be negative
        Path := CrMemoLineTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(-ChargeSalesCrMemoLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The quantity of the credit note line times its unit price stays the net amount of the line
        VerifyLastLineAmountMatchesQuantityTimesPrice(
            TempXMLBuffer, CrMemoLineTok + '/cbc:CreditedQuantity', CrMemoLineTok + '/cac:Price/cbc:PriceAmount', CrMemoLineTok + '/cbc:LineExtensionAmount');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyNegativeItemChargeIsExportedAsAllowance()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge of a posted sales credit memo is exported as an allowance with a positive amount
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with two item lines and a negative item charge assigned to both of them
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(2, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.IsTrue(ChargeSalesCrMemoLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported as an allowance with a positive amount
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:ChargeIndicator';
        Assert.AreEqual('false', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoDocumentAllowanceChargeTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(-ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The allowance is reported in the allowance total and not in the charge total
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(-ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLegalMonetaryTotalTok + '/cbc:ChargeTotalAmount'), 'A negative item charge must not be reported as a charge total.');

        // [THEN] The totals stay consistent
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyTotalsWithDocumentLevelItemCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Moving an item charge out of the credit note lines keeps the document totals and the tax subtotals consistent
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with two item lines and one item charge assigned to both of them
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The sum of the credit note lines no longer contains the charge and the charge is reported as the charge total
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:ChargeTotalAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount'), 'A positive item charge must not be reported as an allowance total.');

        // [THEN] The exported credit note lines add up to the reported line extension amount
        Assert.AreEqual(
            SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount, SumNodeValuesByPath(TempXMLBuffer, CrMemoLineTok + '/cbc:LineExtensionAmount'),
            'The exported credit note lines must add up to the reported line extension amount.');

        // [THEN] The remaining document totals are unchanged
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := CrMemoTaxTotalPathTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoTaxTotalPathTok + '/cac:TaxSubtotal/cbc:TaxableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyTotalsWithLineLevelItemCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A line level allowance/charge on a posted sales credit memo stays inside the sum of the credit note lines and leaves the document totals untouched
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with one item line and an item charge with the same VAT assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the credit note line it is assigned to
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, CrMemoLineTok), 'The item charge must not be exported as a separate credit note line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, CrMemoLineAllowanceChargeTok), 'The item charge must be exported as a line level allowance/charge.');

        // [THEN] The line extension amount still contains the charge and no charge total is reported
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLegalMonetaryTotalTok + '/cbc:ChargeTotalAmount'), 'A line level charge must not be reported as a charge total.');
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoLegalMonetaryTotalTok + '/cbc:AllowanceTotalAmount'), 'A line level charge must not be reported as an allowance total.');

        // [THEN] The exported credit note lines add up to the reported line extension amount
        Assert.AreEqual(
            SalesCrMemoHeader.Amount, SumNodeValuesByPath(TempXMLBuffer, CrMemoLineTok + '/cbc:LineExtensionAmount'),
            'The exported credit note lines must add up to the reported line extension amount.');

        // [THEN] The remaining document totals are unchanged
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := CrMemoLegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := CrMemoTaxTotalPathTok + '/cac:TaxSubtotal/cbc:TaxableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInXRechnungFormatVerifyChargeKeepsInvoiceLineWhenTheOnlyItemLineIsNotExported()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A posted sales invoice whose only item line is skipped by the export keeps the item charge as an invoice line even when the service forces a document level allowance/charge, so that the exported document satisfies BR-16
        Initialize();

        // [GIVEN] A service that forces item charges into a document level allowance/charge
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [GIVEN] A posted sales invoice with an item charge assigned to an earlier shipment and one item line without a quantity, which the export skips
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithChargeAndZeroQuantityLine(ItemChargeNo));
        GetItemInvoiceLine(SalesInvoiceHeader, ItemSalesInvoiceLine);
        Assert.AreEqual(0, ItemSalesInvoiceLine.Quantity, 'The scenario requires an item line without a quantity.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as the only invoice line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line, so that the document keeps at least one invoice line.');
        Assert.IsTrue(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID', ItemChargeNo), 'The exported invoice line must be the item charge.');

        // [THEN] The invoice line of the item charge carries the fallback quantity and the unit code C62
        Path := InvoiceLineTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual('1', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The charge is not exported as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'The item charge must not be exported as a document level allowance/charge.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInXRechnungFormatVerifyChargeKeepsCrMemoLineWhenTheOnlyItemLineIsNotExported()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A posted sales credit memo whose only item line is skipped by the export keeps the item charge as a credit note line even when the service forces a document level allowance/charge, so that the exported document satisfies BR-16
        Initialize();

        // [GIVEN] A service that forces item charges into a document level allowance/charge
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [GIVEN] A posted sales credit memo with an item charge assigned to an earlier return receipt and one item line without a quantity, which the export skips
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithChargeAndZeroQuantityLine(ItemChargeNo));
        GetItemCrMemoLine(SalesCrMemoHeader, ItemSalesCrMemoLine);
        Assert.AreEqual(0, ItemSalesCrMemoLine.Quantity, 'The scenario requires an item line without a quantity.');

        // [WHEN] Export XRechnung Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as the only credit note line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, CrMemoLineTok), 'The item charge must be exported as a credit note line, so that the document keeps at least one credit note line.');
        Assert.IsTrue(NodeValueExists(TempXMLBuffer, CrMemoLineTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID', ItemChargeNo), 'The exported credit note line must be the item charge.');

        // [THEN] The credit note line of the item charge carries the fallback quantity and the unit code C62
        Path := CrMemoLineTok + '/cbc:CreditedQuantity';
        Assert.AreEqual('1', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The charge is not exported as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, CrMemoDocumentAllowanceChargeTok), 'The item charge must not be exported as a document level allowance/charge.');
    end;

    #endregion

    local procedure CreateAndPostSalesInvoiceWithItemCharge(NoOfItemLines: Integer; ChargeQuantity: Decimal; ChargeUnitPrice: Decimal; var ItemChargeNo: Code[20]): Code[20]
    begin
        exit(CreateAndPostSalesInvoiceWithItemCharge(NoOfItemLines, NoOfItemLines, ChargeQuantity, ChargeUnitPrice, ItemChargeNo));
    end;

    local procedure CreateAndPostSalesCrMemoWithItemCharge(NoOfItemLines: Integer; ChargeQuantity: Decimal; ChargeUnitPrice: Decimal; var ItemChargeNo: Code[20]): Code[20]
    begin
        exit(CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::"Credit Memo", NoOfItemLines, NoOfItemLines, ChargeQuantity, ChargeUnitPrice, ItemChargeNo));
    end;

    local procedure CreateAndPostSalesInvoiceWithItemCharge(NoOfItemLines: Integer; NoOfAssignedLines: Integer; ChargeQuantity: Decimal; ChargeUnitPrice: Decimal; var ItemChargeNo: Code[20]): Code[20]
    begin
        exit(CreateAndPostSalesDocumentWithItemCharge("Sales Document Type"::Invoice, NoOfItemLines, NoOfAssignedLines, ChargeQuantity, ChargeUnitPrice, ItemChargeNo));
    end;

    local procedure CreateAndPostSalesDocumentWithItemCharge(DocumentType: Enum "Sales Document Type"; NoOfItemLines: Integer; NoOfAssignedLines: Integer; ChargeQuantity: Decimal; ChargeUnitPrice: Decimal; var ItemChargeNo: Code[20]): Code[20]
    begin
        exit(CreateAndPostSalesDocumentWithItemCharge(DocumentType, NoOfItemLines, NoOfAssignedLines, ChargeQuantity, ChargeUnitPrice, false, ItemChargeNo));
    end;

    local procedure CreateAndPostSalesDocumentWithItemCharge(DocumentType: Enum "Sales Document Type"; NoOfItemLines: Integer; NoOfAssignedLines: Integer; ChargeQuantity: Decimal; ChargeUnitPrice: Decimal; BlankChargeDescription: Boolean; var ItemChargeNo: Code[20]): Code[20]
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        ItemSalesLine: Record "Sales Line";
        ItemLineNo: array[2] of Integer;
        Index: Integer;
    begin
        PrepareItemChargePosting();
        LibraryInventory.CreateItem(Item);
        CreateSalesHeader(SalesHeader, DocumentType);
        for Index := 1 to NoOfItemLines do begin
            CreateItemSalesLine(ItemSalesLine, SalesHeader, Item);
            ItemLineNo[Index] := ItemSalesLine."Line No.";
        end;

        ItemChargeNo := CreateItemChargeForItem(Item);
        LibrarySales.CreateSalesLine(ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", ItemChargeNo, ChargeQuantity);
        ChargeSalesLine.Validate("Unit Price", ChargeUnitPrice);
        ChargeSalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        if BlankChargeDescription then
            ChargeSalesLine.Description := '';
        ChargeSalesLine.Modify(true);

        for Index := 1 to NoOfAssignedLines do begin
            LibraryInventory.CreateItemChargeAssignment(
                ItemChargeAssignmentSales, ChargeSalesLine, SalesHeader."Document Type", SalesHeader."No.", ItemLineNo[Index], Item."No.");
            ItemChargeAssignmentSales.Validate("Qty. to Assign", ChargeQuantity / NoOfAssignedLines);
            ItemChargeAssignmentSales.Modify(true);
        end;

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithShipmentChargeOnly(var ItemChargeNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ChargeSalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ShipmentNo: Code[20];
    begin
        PrepareItemChargePosting();
        LibraryInventory.CreateItem(Item);
        CustomerNo := CreateCustomer();
        ShipmentNo := CreateAndPostShipmentOnly(CustomerNo, Item);

        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        ItemChargeNo := CreateItemChargeForItem(Item);
        LibrarySales.CreateSalesLine(ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", ItemChargeNo, 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        ChargeSalesLine.Modify(true);
        AssignItemChargeToShipment(ChargeSalesLine, ShipmentNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithChargeAndZeroQuantityLine(var ItemChargeNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ZeroQuantitySalesLine: Record "Sales Line";
        ChargeSalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ShipmentNo: Code[20];
    begin
        PrepareItemChargePosting();
        LibraryInventory.CreateItem(Item);
        CustomerNo := CreateCustomer();
        ShipmentNo := CreateAndPostShipmentOnly(CustomerNo, Item);

        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(ZeroQuantitySalesLine, SalesHeader, ZeroQuantitySalesLine.Type::Item, Item."No.", 0);
        ZeroQuantitySalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ZeroQuantitySalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        ZeroQuantitySalesLine.Modify(true);

        ItemChargeNo := CreateItemChargeForItem(Item);
        LibrarySales.CreateSalesLine(ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", ItemChargeNo, 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        ChargeSalesLine.Modify(true);
        AssignItemChargeToShipment(ChargeSalesLine, ShipmentNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesCrMemoWithChargeAndZeroQuantityLine(var ItemChargeNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ZeroQuantitySalesLine: Record "Sales Line";
        ChargeSalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ReturnReceiptNo: Code[20];
    begin
        PrepareItemChargePosting();
        LibraryInventory.CreateItem(Item);
        CustomerNo := CreateCustomer();
        ReturnReceiptNo := CreateAndPostReturnReceiptOnly(CustomerNo, Item);

        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(ZeroQuantitySalesLine, SalesHeader, ZeroQuantitySalesLine.Type::Item, Item."No.", 0);
        ZeroQuantitySalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ZeroQuantitySalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        ZeroQuantitySalesLine.Modify(true);

        ItemChargeNo := CreateItemChargeForItem(Item);
        LibrarySales.CreateSalesLine(ChargeSalesLine, SalesHeader, ChargeSalesLine.Type::"Charge (Item)", ItemChargeNo, 1);
        ChargeSalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 50, 2));
        ChargeSalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        ChargeSalesLine.Modify(true);
        AssignItemChargeToReturnReceipt(ChargeSalesLine, ReturnReceiptNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostReturnReceiptOnly(CustomerNo: Code[20]; Item: Record Item): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ItemSalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Return Order", CustomerNo);
        CreateItemSalesLine(ItemSalesLine, SalesHeader, Item);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
        ReturnReceiptHeader.FindFirst();
        exit(ReturnReceiptHeader."No.");
    end;

    local procedure AssignItemChargeToReturnReceipt(ChargeSalesLine: Record "Sales Line"; ReturnReceiptNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ReturnReceiptLine: Record "Return Receipt Line";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        ItemChargeAssignmentSales.Init();
        ItemChargeAssignmentSales.Validate("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.Validate("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.Validate("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.Validate("Item Charge No.", ChargeSalesLine."No.");
        ItemChargeAssignmentSales.Validate("Unit Cost", ChargeSalesLine."Unit Price");
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptNo);
        ReturnReceiptLine.FindFirst();
        ItemChargeAssgntSales.CreateRcptChargeAssgnt(ReturnReceiptLine, ItemChargeAssignmentSales);

        ItemChargeAssignmentSales.SetRange("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", ChargeSalesLine.Quantity);
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure CreateAndPostShipmentOnly(CustomerNo: Code[20]; Item: Record Item): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ItemSalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CustomerNo);
        CreateItemSalesLine(ItemSalesLine, SalesHeader, Item);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure AssignItemChargeToShipment(ChargeSalesLine: Record "Sales Line"; ShipmentNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        ItemChargeAssignmentSales.Init();
        ItemChargeAssignmentSales.Validate("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.Validate("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.Validate("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.Validate("Item Charge No.", ChargeSalesLine."No.");
        ItemChargeAssignmentSales.Validate("Unit Cost", ChargeSalesLine."Unit Price");
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();
        ItemChargeAssgntSales.CreateShptChargeAssgnt(SalesShipmentLine, ItemChargeAssignmentSales);

        ItemChargeAssignmentSales.SetRange("Document Type", ChargeSalesLine."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", ChargeSalesLine."Document No.");
        ItemChargeAssignmentSales.SetRange("Document Line No.", ChargeSalesLine."Line No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", ChargeSalesLine.Quantity);
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure PrepareItemChargePosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetCalcInvDiscount(false);
        InventorySetup.Get();
        InventorySetup.Validate("Prevent Negative Inventory", false);
        InventorySetup.Modify(true);
    end;

    local procedure CreateItemSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Item: Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure."International Standard Code" := LibraryUtility.GenerateGUID();
        UnitOfMeasure.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Unit of Measure", UnitOfMeasure.Code);
        SalesLine.Validate("Tax Category", TaxCategoryStandardTok);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemChargeForItem(Item: Record Item): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(LibraryInventory.CreateItemChargeNo());
        ItemCharge.Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        ItemCharge.Validate("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure SetServiceItemChargeMapping(ItemChargeMapping: Enum "Item Charge E-Invoice Mapping")
    begin
        EDocumentService."Item Charge E-Invoice Mapping" := ItemChargeMapping;
        EDocumentService.Modify();
    end;

    local procedure SetItemChargeReason(ItemChargeNo: Code[20]; ReasonText: Text[100]; ReasonCode: Code[10])
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(ItemChargeNo);
        ItemCharge."E-Invoice Reason Text" := ReasonText;
        ItemCharge."E-Invoice Reason Code" := ReasonCode;
        ItemCharge.Modify(false);
    end;

    local procedure SetItemChargeUnitCode(ItemChargeNo: Code[20]; UnitCode: Code[10])
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(ItemChargeNo);
        ItemCharge."E-Invoice Unit Code" := UnitCode;
        ItemCharge.Modify(false);
    end;

    local procedure GetChargeInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"Charge (Item)");
        SalesInvoiceLine.FindFirst();
    end;

    local procedure GetChargeCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"Charge (Item)");
        SalesCrMemoLine.FindFirst();
    end;

    local procedure GetItemCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.FindFirst();
    end;

    local procedure GetItemInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure GetNodeCountByPath(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Integer
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        exit(TempXMLBuffer.Count());
    end;

    local procedure NodeValueExists(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; NodeValue: Text): Boolean
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        TempXMLBuffer.SetRange(Value, NodeValue);
        exit(not TempXMLBuffer.IsEmpty());
    end;

    local procedure SumNodeValuesByPath(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text) Total: Decimal
    var
        NodeValue: Decimal;
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        if TempXMLBuffer.FindSet() then
            repeat
                Evaluate(NodeValue, TempXMLBuffer.Value, 9);
                Total += NodeValue;
            until TempXMLBuffer.Next() = 0;
    end;

    local procedure GetLastAttributeByPathWithError(var TempXMLBuffer: Record "XML Buffer" temporary; ElementXPath: Text; AttributeName: Text): Text
    var
        TempXMLBufferAttribute: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, ElementXPath);
        if TempXMLBuffer.FindLast() then begin
            TempXMLBufferAttribute.Copy(TempXMLBuffer, true);
            TempXMLBufferAttribute.Reset();
            TempXMLBufferAttribute.SetRange("Parent Entry No.", TempXMLBuffer."Entry No.");
            TempXMLBufferAttribute.SetRange(Type, TempXMLBufferAttribute.Type::Attribute);
            TempXMLBufferAttribute.SetRange(Name, AttributeName);
            if TempXMLBufferAttribute.FindFirst() then
                exit(TempXMLBufferAttribute.Value);
        end;
        Error(AttributeNotFoundErr, AttributeName, ElementXPath);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithLine(DocumentType, LineType, InvoiceDiscount));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostServiceDocument(): Code[20];
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, CreateServiceDocumentWithLine());
        exit(PostServiceDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceDocumentWithTwoLines(): Code[20];
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, CreateServiceDocumentWithTwoLines());
        exit(PostServiceDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceDocumentWithRespCenter(RespCenterCode: Code[10]): Code[20];
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, CreateServiceDocumentWithLine());
        ServiceHeader.Validate("Responsibility Center", RespCenterCode);
        ServiceHeader.Modify(true);
        exit(PostServiceDocument(ServiceHeader));
    end;

    local procedure PostServiceDocument(var ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.FindLast();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreateAndPostServiceCrMemoDocument(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", CreateServiceCrMemoDocumentWithLine());
        exit(PostServiceCrMemoDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceCrMemoDocumentWithTwoLines(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", CreateServiceCrMemoDocumentWithTwoLines());
        exit(PostServiceCrMemoDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceCrMemoDocumentWithRespCenter(RespCenterCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", CreateServiceCrMemoDocumentWithLine());
        ServiceHeader.Validate("Responsibility Center", RespCenterCode);
        ServiceHeader.Modify(true);
        exit(PostServiceCrMemoDocument(ServiceHeader));
    end;

    local procedure PostServiceCrMemoDocument(var ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCrMemoHeader.FindLast();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure CreateAndPostSalesDocumentWithTwoLines(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithTwoLine(DocumentType, LineType, InvoiceDiscount));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithTwoLinesLineDiscount(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithTwoLineLineDiscount(DocumentType, LineType, InvoiceDiscount));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithRespCenter(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; RespCenterCode: Code[10]): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithLine(DocumentType, LineType, false, RespCenterCode));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithBankAccount(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; BankAccountCode: Code[20]): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        SalesHeader.Validate("Company Bank Account Code", BankAccountCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, LineType, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchaseHeader, DocumentType);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithLine(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20]
    begin
        exit(CreateSalesDocumentWithLine(DocumentType, LineType, InvoiceDiscount, ''));
    end;

    local procedure CreateSalesDocumentWithLine(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean; RespCenterCode: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        if RespCenterCode <> '' then begin
            SalesHeader.Validate("Responsibility Center", RespCenterCode);
            SalesHeader.Modify(true);
        end;
        CreateSalesLine(SalesHeader, LineType, false);

        if InvoiceDiscount then
            ApplyInvoiceDiscount(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocumentWithTwoLine(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        CreateSalesLine(SalesHeader, LineType, false);
        CreateSalesLine(SalesHeader, LineType, false);

        if InvoiceDiscount then
            ApplyInvoiceDiscount(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocumentWithTwoLineLineDiscount(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"; InvoiceDiscount: Boolean): Code[20];
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        CreateSalesLine(SalesHeader, LineType, false);
        CreateSalesLine(SalesHeader, LineType, true);

        if InvoiceDiscount then
            ApplyInvoiceDiscount(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure ApplyInvoiceDiscount(SalesHeader: Record "Sales Header");
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        LibrarySales.SetCalcInvDiscount(true);
        SalesHeader.CalcFields(Amount);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount * LibraryRandom.RandDecInRange(40, 60, 5) / 100, SalesHeader);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type");
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]);
    var
        PostCode: Record "Post Code";
        PaymentTermsCode: Code[10];
    begin
        LibraryERM.FindPostCode(PostCode);
        PaymentTermsCode := LibraryERM.FindPaymentTermsCode();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Sell-to Contact", SalesHeader."No.");
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Bill-to City", PostCode.City);
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Ship-to City", PostCode.City);
        SalesHeader.Validate("Sell-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Sell-to City", PostCode.City);
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateRandomText(20));
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20];
    var
        Customer: Record Customer;
    begin
        Customer.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Customer.Validate("E-Invoice Routing No.", LibraryEDocDE.CreateValidRoutingNo());
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateCustomerWithoutRoutingNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer."E-Invoice Routing No." := '';
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithGLN(GLN: Code[13]; UseGLNInElectronicDocument: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.GLN := GLN;
        Customer."Use GLN in Electronic Document" := UseGLNInElectronicDocument;
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(GLN: Code[13]; NewShipToGLN: Code[13]; UseGLNInElectronicDocument: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomerWithGLN(GLN, UseGLNInElectronicDocument);
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.GLN := NewShipToGLN;
        ShipToAddress.Modify(true);
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithDifferentSellToAndBillToGLNs(SellToGLN: Code[13]; BillToGLN: Code[13]): Code[20]
    var
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CreateCustomerWithGLN(SellToGLN, true));
        LibrarySales.CreateCustomer(BillToCustomer);
        BillToCustomer.GLN := BillToGLN;
        BillToCustomer."Use GLN in Electronic Document" := true;
        BillToCustomer.Modify(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesCrMemoForCustomerWithGLN(GLN: Code[13]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CreateCustomerWithGLN(GLN, true));
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SetCompanyGLN(GLN: Code[13])
    begin
        CompanyInformation.Get();
        CompanyInformation.GLN := GLN;
        CompanyInformation."Use GLN in Electronic Document" := true;
        CompanyInformation.Modify();
    end;

    local procedure SetCompanyRegistrationNo(RegistrationNo: Text[20])
    begin
        CompanyInformation.Get();
        CompanyInformation.GLN := '';
        CompanyInformation."Use GLN in Electronic Document" := false;
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation."Registration No." := RegistrationNo;
        CompanyInformation."Use Reg. No. in E-Document" := true;
        CompanyInformation.Modify();
    end;

    local procedure SupplierGLN(): Code[13]
    begin
        exit('5018404000002');
    end;

    local procedure CustomerGLN(): Code[13]
    begin
        exit('4313205158428');
    end;

    local procedure ShipToGLN(): Code[13]
    begin
        exit('1234567890128');
    end;

    local procedure CreateResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center")
    begin
        ResponsibilityCenter.Init();
        ResponsibilityCenter.Validate(Code, LibraryUtility.GenerateRandomCode(ResponsibilityCenter.FieldNo(Code), DATABASE::"Responsibility Center"));
        ResponsibilityCenter.Validate(Name, ResponsibilityCenter.Code);  // Validating Code as Name because value is not important.
        ResponsibilityCenter.Insert(true);
        ResponsibilityCenter.Address := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ResponsibilityCenter.Address));
        ResponsibilityCenter."Address 2" := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ResponsibilityCenter."Address 2"));
        ResponsibilityCenter."Post Code" := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ResponsibilityCenter."Post Code"));
        ResponsibilityCenter.City := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ResponsibilityCenter.City));
        ResponsibilityCenter."Country/Region Code" := CompanyInformation."Country/Region Code";
        ResponsibilityCenter.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; LineDiscount: Boolean);
    var
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        LineNo: Code[20];
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure."International Standard Code" := LibraryUtility.GenerateGUID();
        UnitOfMeasure.Modify(true);
        if LineType = LineType::"G/L Account" then
            LineNo := LibraryERM.CreateGLAccountWithSalesSetup()
        else
            LineNo := LibraryInventory.CreateItemNo();
        LibrarySales.CreateSalesLine(
        SalesLine, SalesHeader, LineType, LineNo, LibraryRandom.RandDecInRange(10, 20, 5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 5));
        SalesLine.Validate("Unit of Measure", UnitOfMeasure.Code);
        SalesLine.Validate("Tax Category", LibraryRandom.RandText(2));
        if LineDiscount then
            SalesLine.Validate("Line Discount %", LibraryRandom.RandDecInRange(10, 20, 5));
        SalesLine.Modify(true);
    end;

    local procedure SetItemGTIN(SalesInvoiceHeader: Record "Sales Invoice Header"; GTIN: Code[14])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        SetItemGTIN(SalesInvoiceLine."No.", GTIN);
    end;

    local procedure SetItemGTIN(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; GTIN: Code[14])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        SetItemGTIN(SalesCrMemoLine."No.", GTIN);
    end;

    local procedure SetItemGTIN(ItemNo: Code[20]; GTIN: Code[14])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate(GTIN, GTIN);
        Item.Modify(true);
    end;

    local procedure CreateServiceDocumentWithLine(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceDocumentWithTwoLines(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        CreateServiceHeader(ServiceHeader, CreateCustomer());
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        PostCode: Record "Post Code";
        PaymentTermsCode: Code[10];
    begin
        LibraryERM.FindPostCode(PostCode);
        PaymentTermsCode := LibraryERM.FindPaymentTermsCode();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Bill-to City", PostCode.City);
        ServiceHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Ship-to City", PostCode.City);
        ServiceHeader.Validate(Address, LibraryUtility.GenerateGUID());
        ServiceHeader.Validate(City, PostCode.City);
        ServiceHeader.Validate("Your Reference", LibraryUtility.GenerateRandomText(20));
        ServiceHeader.Validate("Payment Terms Code", PaymentTermsCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure."International Standard Code" := LibraryUtility.GenerateGUID();
        UnitOfMeasure.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Validate("Unit of Measure", UnitOfMeasure.Code);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceCrMemoDocumentWithLine(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceCrMemoHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceCrMemoDocumentWithTwoLines(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceCrMemoHeader(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        CreateServiceLine(ServiceHeader);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceCrMemoHeader(var ServiceHeader: Record "Service Header")
    begin
        CreateServiceCrMemoHeader(ServiceHeader, CreateCustomer());
    end;

    local procedure CreateServiceCrMemoHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    var
        PostCode: Record "Post Code";
        PaymentTermsCode: Code[10];
    begin
        LibraryERM.FindPostCode(PostCode);
        PaymentTermsCode := LibraryERM.FindPaymentTermsCode();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);
        ServiceHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Bill-to City", PostCode.City);
        ServiceHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Ship-to City", PostCode.City);
        ServiceHeader.Validate(Address, LibraryUtility.GenerateGUID());
        ServiceHeader.Validate(City, PostCode.City);
        ServiceHeader.Validate("Your Reference", LibraryUtility.GenerateRandomText(20));
        ServiceHeader.Validate("Payment Terms Code", PaymentTermsCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CheckServiceHeader(ServiceHeader: Record "Service Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(ServiceHeader);
        ExportXRechnungFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);
    end;

    local procedure CheckSalesHeader(SalesHeader: Record "Sales Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(SalesHeader);
        ExportXRechnungFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);
    end;

    local procedure CreateSalesDocumentWithCustomerWithoutVATRegNo(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20];
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(CreateCustomer());
        Customer."VAT Registration No." := '';
        Customer.Modify(true);
        CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLine(SalesHeader, LineType, false);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocumentWithCustomerWithoutVATRegNoAndRoutingNo(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20];
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(CreateCustomer());
        Customer."VAT Registration No." := '';
        Customer."E-Invoice Routing No." := '';
        Customer.Modify(true);
        CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLine(SalesHeader, LineType, false);
        exit(SalesHeader."No.");
    end;

    local procedure ExportInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        SourceDocumentLines.GetTable(SalesInvoiceLine);
        ExportXRechnungFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        TempBlob.CreateInStream(FileInStream);
        TempXMLBuffer.LoadFromStream(FileInStream);
    end;

    local procedure ExportServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceInvoiceHeader);
        SourceDocumentLines.GetTable(ServiceInvoiceLine);
        ExportXRechnungFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        TempBlob.CreateInStream(FileInStream);
        TempXMLBuffer.LoadFromStream(FileInStream);
    end;

    local procedure ExportCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        SourceDocumentLines.GetTable(SalesCrMemoLine);
        ExportXRechnungFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        TempBlob.CreateInStream(FileInStream);
        TempXMLBuffer.LoadFromStream(FileInStream);
    end;

    local procedure ExportServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        FileInStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceCrMemoHeader);
        SourceDocumentLines.GetTable(ServiceCrMemoLine);
        ExportXRechnungFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
        TempBlob.CreateInStream(FileInStream);
        TempXMLBuffer.LoadFromStream(FileInStream);
    end;

    local procedure VerifyGLNIdentifier(ExpectedGLN: Code[13]; var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    begin
        Assert.AreEqual(ExpectedGLN, GetNodeByPathWithError(TempXMLBuffer, XPath), StrSubstNo(IncorrectValueErr, XPath));
        Assert.AreEqual('0088', GetAttributeByPathWithError(TempXMLBuffer, XPath, 'schemeID'), StrSubstNo(IncorrectValueErr, XPath + '/@schemeID'));
    end;

    local procedure VerifyNodeDoesNotExist(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    begin
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, XPath), StrSubstNo(UnexpectedNodeErr, XPath));
    end;

    local procedure VerifyHeaderData(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTok: Label '/ubl:Invoice', Locked = true;
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:InvoiceTypeCode';
        Assert.AreEqual('380', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(SalesInvoiceHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:IssueDate';
        Assert.AreEqual(FormatDate(SalesInvoiceHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:DocumentCurrencyCode';
        Assert.AreEqual(GetCurrencyCode(SalesInvoiceHeader."Currency Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyHeaderData(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentCreditNoteTok: Label '/ns0:CreditNote', Locked = true;
        Path: Text;
    begin
        Path := DocumentCreditNoteTok + '/cbc:CreditNoteTypeCode';
        Assert.AreEqual('381', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentCreditNoteTok + '/cbc:ID';
        Assert.AreEqual(SalesCrMemoHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentCreditNoteTok + '/cbc:IssueDate';
        Assert.AreEqual(FormatDate(SalesCrMemoHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentCreditNoteTok + '/cbc:DocumentCurrencyCode';
        Assert.AreEqual(GetCurrencyCode(SalesCrMemoHeader."Currency Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyHeaderData(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTok: Label '/ubl:Invoice', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTok + '/cbc:InvoiceTypeCode';
        Assert.AreEqual('380', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentTok + '/cbc:ID';
        Assert.AreEqual(ServiceInvoiceHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentTok + '/cbc:IssueDate';
        Assert.AreEqual(FormatDate(ServiceInvoiceHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentTok + '/cbc:DocumentCurrencyCode';
        Assert.AreEqual(GetCurrencyCode(ServiceInvoiceHeader."Currency Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyHeaderData(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentCreditNoteTok: Label '/ns0:CreditNote', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentCreditNoteTok + '/cbc:CreditNoteTypeCode';
        Assert.AreEqual('381', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentCreditNoteTok + '/cbc:ID';
        Assert.AreEqual(ServiceCrMemoHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentCreditNoteTok + '/cbc:IssueDate';
        Assert.AreEqual(FormatDate(ServiceCrMemoHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentCreditNoteTok + '/cbc:DocumentCurrencyCode';
        Assert.AreEqual(GetCurrencyCode(ServiceCrMemoHeader."Currency Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerReference(BuyerReference: Text[50]; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:BuyerReference';
        Assert.AreEqual(BuyerReference, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyAccountingSupplierParty(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    begin
        VerifyAccountingSupplierParty(TempXMLBuffer, DocumentTok, CompanyInformation.Address, CompanyInformation."Post Code", CompanyInformation.City);
    end;

    local procedure VerifyAccountingSupplierParty(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; ResponsibilityCenter: Record "Responsibility Center")
    begin
        VerifyAccountingSupplierParty(TempXMLBuffer, DocumentTok, ResponsibilityCenter.Address, ResponsibilityCenter."Post Code", ResponsibilityCenter.City);
    end;

    local procedure VerifyAccountingSupplierParty(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; Address: Text; PostCode: Code[20]; City: Text[30])
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cac:PostalAddress/cbc:StreetName';
        Assert.AreEqual(Address, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:PostalAddress/cbc:CityName';
        Assert.AreEqual(City, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:PostalAddress/cbc:PostalZone';
        Assert.AreEqual(PostCode, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentTok + '/cac:PartyTaxScheme/cbc:CompanyID';
        Assert.AreEqual(GetVATRegistrationNo(CompanyInformation."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyAccountingCustomerParty(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesDocumentPartyTok: Label '/ubl:Invoice/cac:AccountingCustomerParty/cac:Party', Locked = true;
        Path: Text;
    begin
        Path := SalesDocumentPartyTok + '/cbc:EndpointID';
        Assert.AreEqual(SalesInvoiceHeader."Sell-to E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := SalesDocumentPartyTok + '/cac:PostalAddress/cbc:StreetName';
        Assert.AreEqual(SalesInvoiceHeader."Bill-to Address", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := SalesDocumentPartyTok + '/cac:PostalAddress/cbc:CityName';
        Assert.AreEqual(SalesInvoiceHeader."Bill-to City", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyAccountingCustomerParty(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentAccountingCustomerPartyTok: Label '/ns0:CreditNote/cac:AccountingCustomerParty/cac:Party', Locked = true;
        Path: Text;
    begin
        Path := DocumentAccountingCustomerPartyTok + '/cbc:EndpointID';
        Assert.AreEqual(SalesCrMemoHeader."Sell-to E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAccountingCustomerPartyTok + '/cac:PostalAddress/cbc:StreetName';
        Assert.AreEqual(SalesCrMemoHeader."Bill-to Address", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAccountingCustomerPartyTok + '/cac:PostalAddress/cbc:CityName';
        Assert.AreEqual(SalesCrMemoHeader."Bill-to City", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyAccountingCustomerParty(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        DocumentServicePartyTok: Label '/ubl:Invoice/cac:AccountingCustomerParty/cac:Party', Locked = true;
        Path: Text;
    begin
        Path := DocumentServicePartyTok + '/cbc:EndpointID';
        Assert.AreEqual(ServiceInvoiceHeader."E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentServicePartyTok + '/cac:PostalAddress/cbc:StreetName';
        Assert.AreEqual(ServiceInvoiceHeader."Bill-to Address", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentServicePartyTok + '/cac:PostalAddress/cbc:CityName';
        Assert.AreEqual(ServiceInvoiceHeader."Bill-to City", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyAccountingCustomerParty(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentAccountingCustomerPartyTok: Label '/ns0:CreditNote/cac:AccountingCustomerParty/cac:Party', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentAccountingCustomerPartyTok + '/cbc:EndpointID';
        Assert.AreEqual(ServiceCrMemoHeader."E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentAccountingCustomerPartyTok + '/cac:PostalAddress/cbc:StreetName';
        Assert.AreEqual(ServiceCrMemoHeader."Bill-to Address", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentAccountingCustomerPartyTok + '/cac:PostalAddress/cbc:CityName';
        Assert.AreEqual(ServiceCrMemoHeader."Bill-to City", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyPaymentMeans(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:PaymentMeansCode';
        Assert.AreEqual('58', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyPaymentMeans(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; ExpectedIBAN: Text; ExpectedSWIFT: Text);
    var
        Path: Text;
    begin
        VerifyPaymentMeans(TempXMLBuffer, DocumentTok);
        Path := DocumentTok + '/cac:PayeeFinancialAccount/cbc:ID';
        Assert.AreEqual(ExpectedIBAN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        if ExpectedSWIFT <> '' then begin
            Path := DocumentTok + '/cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cbc:ID';
            Assert.AreEqual(ExpectedSWIFT, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        end;
    end;

    local procedure VerifyPaymentTerms(PaymentTermsCode: Code[10]; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        PaymentTerms: Record "Payment Terms";
        Path: Text;
    begin
        PaymentTerms.Get(PaymentTermsCode);
        Path := DocumentTok + '/cbc:Note';
        Assert.AreEqual(PaymentTerms.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTaxTotalTok: Label '/ubl:Invoice/cac:TaxTotal', Locked = true;
        Path: Text;
    begin
        Path := DocumentTaxTotalTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(GetTotalTaxAmount(SalesInvoiceHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTaxTotalsTok: Label '/ns0:CreditNote/cac:TaxTotal', Locked = true;
        Path: Text;
    begin
        Path := DocumentTaxTotalsTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(GetTotalTaxAmount(SalesCrMemoHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTaxTotalTok: Label '/ubl:Invoice/cac:TaxTotal', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTaxTotalTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(GetTotalTaxAmount(ServiceInvoiceHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTaxTotalsTok: Label '/ns0:CreditNote/cac:TaxTotal', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTaxTotalsTok + '/cbc:TaxAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(GetTotalTaxAmount(ServiceCrMemoHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        LineAmounts: Dictionary of [Text, Decimal];
        DocumentLegalMonetaryTotalTok: Label '/ubl:Invoice/cac:LegalMonetaryTotal', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(SalesInvoiceHeader, LineAmounts);
        Path := DocumentLegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        LineAmounts: Dictionary of [Text, Decimal];
        DocumentLegalMonetaryTotalsTok: Label '/ns0:CreditNote/cac:LegalMonetaryTotal', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(SalesCrMemoHeader, LineAmounts);
        Path := DocumentLegalMonetaryTotalsTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        LineAmounts: Dictionary of [Text, Decimal];
        ServiceDocumentLegalMonetaryTotalTok: Label '/ubl:Invoice/cac:LegalMonetaryTotal', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(ServiceInvoiceHeader, LineAmounts);
        Path := ServiceDocumentLegalMonetaryTotalTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        LineAmounts: Dictionary of [Text, Decimal];
        ServiceDocumentLegalMonetaryTotalsTok: Label '/ns0:CreditNote/cac:LegalMonetaryTotal', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(ServiceCrMemoHeader, LineAmounts);
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/cbc:TaxExclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/cbc:TaxInclusiveAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/cbc:PayableAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentTok: Label '/ubl:Invoice/cac:InvoiceLine', Locked = true;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();
        VerifyFirstInvoiceLine(SalesInvoiceLine, TempXMLBuffer, DocumentTok);
        SalesInvoiceLine.Next();
        VerifySecondInvoiceLine(SalesInvoiceLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyServiceInvoiceLine(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        DocumentTok: Label '/ubl:Invoice/cac:InvoiceLine', Locked = true;
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        VerifyFirstServiceInvoiceLine(ServiceInvoiceLine, TempXMLBuffer, DocumentTok);
        ServiceInvoiceLine.Next();
        VerifySecondServiceInvoiceLine(ServiceInvoiceLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyFirstServiceInvoiceLine(ServiceInvoiceLine: Record "Service Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(ServiceInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ServiceInvoiceLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ServiceInvoiceLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(ServiceInvoiceLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(ServiceInvoiceLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondServiceInvoiceLine(ServiceInvoiceLine: Record "Service Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(ServiceInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ServiceInvoiceLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(ServiceInvoiceLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(ServiceInvoiceLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyServiceCrMemoLine(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        DocumentTok: Label '/ns0:CreditNote/cac:CreditNoteLine', Locked = true;
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindSet();
        VerifyFirstServiceCrMemoLine(ServiceCrMemoLine, TempXMLBuffer, DocumentTok);
        ServiceCrMemoLine.Next();
        VerifySecondServiceCrMemoLine(ServiceCrMemoLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyFirstServiceCrMemoLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(ServiceCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:CreditedQuantity ';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ServiceCrMemoLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(ServiceCrMemoLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(ServiceCrMemoLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondServiceCrMemoLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(ServiceCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:CreditedQuantity ';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(ServiceCrMemoLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(ServiceCrMemoLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(ServiceCrMemoLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyFirstInvoiceLine(SalesInvoiceLine: Record "Sales Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(SalesInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesInvoiceLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(SalesInvoiceLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(SalesInvoiceLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesInvoiceLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:ClassifiedTaxCategory/cbc:ID';
        Assert.AreEqual(SalesInvoiceLine."Tax Category", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:StartDate';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:EndDate';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondInvoiceLine(SalesInvoiceLine: Record "Sales Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(SalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:InvoicedQuantity';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesInvoiceLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(SalesInvoiceLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(SalesInvoiceLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesInvoiceLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:ClassifiedTaxCategory/cbc:ID';
        Assert.AreEqual(SalesInvoiceLine."Tax Category", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:StartDate';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:EndDate';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceLineWithDiscount(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentTok: Label '/ubl:Invoice/cac:InvoiceLine/cac:AllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindLast();
        Path := DocumentTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual('LineDiscount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:MultiplierFactorNumeric';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(SalesInvoiceLine."Line Discount %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceLine."Line Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:BaseAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceLine."Unit Price" * SalesInvoiceLine.Quantity), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceWithInvDiscount(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTok: Label '/ubl:Invoice/cac:AllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Invoice Discount Amount");
        Path := DocumentTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual('Document discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:MultiplierFactorNumeric';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(100 * SalesInvoiceHeader."Invoice Discount Amount" / (SalesInvoiceHeader."Invoice Discount Amount" + SalesInvoiceHeader.Amount)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Invoice Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:BaseAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesInvoiceHeader."Invoice Discount Amount" + SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentTok: Label '/ns0:CreditNote/cac:CreditNoteLine', Locked = true;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindSet();
        VerifyFirstCrMemoLine(SalesCrMemoLine, TempXMLBuffer, DocumentTok);
        SalesCrMemoLine.Next();
        VerifySecondCrMemoLine(SalesCrMemoLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyFirstCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(SalesCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:CreditedQuantity ';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesCrMemoLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(SalesCrMemoLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(SalesCrMemoLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesCrMemoLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:ClassifiedTaxCategory/cbc:ID';
        Assert.AreEqual(SalesCrMemoLine."Tax Category", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:StartDate';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:EndDate';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/cbc:ID';
        Assert.AreEqual(Format(SalesCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:CreditedQuantity ';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesCrMemoLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:LineExtensionAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cbc:Name';
        Assert.AreEqual(SalesCrMemoLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:SellersItemIdentification/cbc:ID';
        Assert.AreEqual(SalesCrMemoLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Price/cbc:PriceAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimalUnlimited(SalesCrMemoLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:Item/cac:ClassifiedTaxCategory/cbc:ID';
        Assert.AreEqual(SalesCrMemoLine."Tax Category", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:StartDate';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cac:InvoicePeriod/cbc:EndDate';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoLineWithDiscounts(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentTok: Label '/ns0:CreditNote/cac:CreditNoteLine/cac:AllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindLast();
        Path := DocumentTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual('LineDiscount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:MultiplierFactorNumeric';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(SalesCrMemoLine."Line Discount %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoLine."Line Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:BaseAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoLine."Unit Price" * SalesCrMemoLine.Quantity), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoWithInvDiscount(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTok: Label '/ns0:CreditNote/cac:AllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesCrMemoHeader.CalcFields(Amount, "Invoice Discount Amount");
        Path := DocumentTok + '/cbc:AllowanceChargeReason';
        Assert.AreEqual('Document discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:MultiplierFactorNumeric';
        Assert.AreEqual(ExportXRechnungDocument.FormatFiveDecimal(100 * SalesCrMemoHeader."Invoice Discount Amount" / (SalesCrMemoHeader."Invoice Discount Amount" + SalesCrMemoHeader.Amount)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:Amount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Invoice Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/cbc:BaseAmount';
        Assert.AreEqual(ExportXRechnungDocument.FormatDecimal(SalesCrMemoHeader."Invoice Discount Amount" + SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoicePDFEmbeddedToXML(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        TempXMLBuffer.SetRange(Path, '/ubl:Invoice/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject');
        Assert.RecordIsNotEmpty(TempXMLBuffer, '');
    end;

    local procedure VerifyCrMemoPDFEmbeddedToXML(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        TempXMLBuffer.SetRange(Path, '/ns0:CreditNote/cac:AdditionalDocumentReference/cac:Attachment/cbc:EmbeddedDocumentBinaryObject');
        Assert.RecordIsNotEmpty(TempXMLBuffer, '');
    end;

    local procedure VerifyCSVAttachments(var TempXMLBuffer: Record "XML Buffer" temporary; FileName1: Text; CSVText1: Text; FileName2: Text; CSVText2: Text)
    begin
        // [THEN] XRechnung Electronic Document contains 2 AdditionalDocumentReference nodes
        VerifyAdditionalDocumentReferenceCount(TempXMLBuffer, 2);

        // [THEN] First attachment is verified in XML with correct ID, MIME type, and content
        VerifyCSVAttachmentInXML(TempXMLBuffer, FileName1, 'text/csv', CSVText1);

        // [THEN] Second attachment is verified in XML with correct ID, MIME type, and content
        VerifyCSVAttachmentInXML(TempXMLBuffer, FileName2, 'text/csv', CSVText2);
    end;


    local procedure VerifyAdditionalDocumentReferenceCount(var TempXMLBuffer: Record "XML Buffer" temporary; ExpectedCount: Integer)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, '/ubl:Invoice/cac:AdditionalDocumentReference');
        Assert.AreEqual(ExpectedCount, TempXMLBuffer.Count, 'Incorrect number of AdditionalDocumentReference nodes');
    end;

    local procedure VerifyCSVAttachmentInXML(var TempXMLBuffer: Record "XML Buffer" temporary; AttachmentID: Text; ExpectedMIMEType: Text; ExpectedCSVText: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        Base64EncodedContent: Text;
    begin
        Base64EncodedContent := Base64Convert.ToBase64(ExpectedCSVText);
        VerifyAttachmentInXML(TempXMLBuffer, AttachmentID, ExpectedMIMEType, Base64EncodedContent);
    end;

    local procedure VerifyAttachmentInXML(var TempXMLBuffer: Record "XML Buffer" temporary; AttachmentID: Text; ExpectedMIMEType: Text; ExpectedBase64Content: Text)
    var
        TempXMLBufferAttachment: Record "XML Buffer" temporary;
        TempXMLBufferChild: Record "XML Buffer" temporary;
        EncodedContent: Text;
        ExpectedDescription: Text;
        AttachmentEntryNo: Integer;
        EmbeddedDocEntryNo: Integer;
    begin
        // Find the AdditionalDocumentReference node with matching ID
        if not FindAttachmentByID(TempXMLBuffer, AttachmentID, TempXMLBufferAttachment) then
            Error('AdditionalDocumentReference with ID %1 not found', AttachmentID);

        // Extract file name without extension for DocumentDescription verification
        ExpectedDescription := CopyStr(AttachmentID, 1, StrPos(AttachmentID, '.') - 1);

        // Verify DocumentDescription (should match file name without extension)
        TempXMLBufferChild.Copy(TempXMLBuffer, true);
        TempXMLBufferChild.Reset();
        TempXMLBufferChild.SetRange("Parent Entry No.", TempXMLBufferAttachment."Entry No.");
        TempXMLBufferChild.SetRange(Type, TempXMLBufferChild.Type::Element);
        TempXMLBufferChild.SetRange(Name, 'DocumentDescription');
        if TempXMLBufferChild.FindFirst() then
            Assert.AreEqual(ExpectedDescription, TempXMLBufferChild.Value, 'Incorrect DocumentDescription');

        // Find the Attachment child node
        TempXMLBufferChild.Reset();
        TempXMLBufferChild.SetRange("Parent Entry No.", TempXMLBufferAttachment."Entry No.");
        TempXMLBufferChild.SetRange(Type, TempXMLBufferChild.Type::Element);
        TempXMLBufferChild.SetRange(Name, 'Attachment');
        if TempXMLBufferChild.FindFirst() then begin
            AttachmentEntryNo := TempXMLBufferChild."Entry No.";

            // Find EmbeddedDocumentBinaryObject under Attachment
            TempXMLBufferChild.Reset();
            TempXMLBufferChild.SetRange("Parent Entry No.", AttachmentEntryNo);
            TempXMLBufferChild.SetRange(Type, TempXMLBufferChild.Type::Element);
            TempXMLBufferChild.SetRange(Name, 'EmbeddedDocumentBinaryObject');
            if TempXMLBufferChild.FindFirst() then begin
                EncodedContent := TempXMLBufferChild.GetValue();
                EmbeddedDocEntryNo := TempXMLBufferChild."Entry No.";

                // Get mimeCode attribute
                TempXMLBufferChild.Reset();
                TempXMLBufferChild.SetRange("Parent Entry No.", EmbeddedDocEntryNo);
                TempXMLBufferChild.SetRange(Type, TempXMLBufferChild.Type::Attribute);
                TempXMLBufferChild.SetRange(Name, 'mimeCode');
                if TempXMLBufferChild.FindFirst() then
                    Assert.AreEqual(ExpectedMIMEType, TempXMLBufferChild.Value, 'Incorrect MIME type');

                if ExpectedBase64Content <> '' then
                    Assert.AreEqual(ExpectedBase64Content, EncodedContent, 'Attachment content does not match original value');
            end else
                Error('EmbeddedDocumentBinaryObject not found for attachment %1', AttachmentID);
        end else
            Error('Attachment node not found for attachment %1', AttachmentID);
    end;

    local procedure FindAttachmentByID(var TempXMLBuffer: Record "XML Buffer" temporary; AttachmentID: Text; var TempXMLBufferResult: Record "XML Buffer" temporary): Boolean
    var
        TempXMLBufferID: Record "XML Buffer" temporary;
    begin
        // Find all AdditionalDocumentReference nodes
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, '/ubl:Invoice/cac:AdditionalDocumentReference');
        if TempXMLBuffer.FindSet() then
            repeat
                // Check if this node has the matching ID child
                TempXMLBufferID.Copy(TempXMLBuffer, true);
                TempXMLBufferID.Reset();
                TempXMLBufferID.SetRange("Parent Entry No.", TempXMLBuffer."Entry No.");
                TempXMLBufferID.SetRange(Type, TempXMLBufferID.Type::Element);
                TempXMLBufferID.SetRange(Name, 'ID');
                if TempXMLBufferID.FindFirst() then
                    if TempXMLBufferID.Value = AttachmentID then begin
                        TempXMLBufferResult := TempXMLBuffer;
                        exit(true);
                    end;
            until TempXMLBuffer.Next() = 0;
        exit(false);
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10];
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure SetEdocumentServiceEmbedPDFInExport(NewEmbedPDFInExport: Boolean);
    begin
        EDocumentService."Embed PDF in export" := NewEmbedPDFInExport;
        EDocumentService.Modify();
    end;

    local procedure SetBuyerReferenceMandatory()
    begin
        EDocumentService."Buyer Reference Mandatory" := true;
        EDocumentService.Modify();
    end;

    local procedure GetNodeByPathWithError(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        if TempXMLBuffer.FindFirst() then
            exit(TempXMLBuffer.Value);
        Error('Node not found: %1', XPath);
    end;

    local procedure NodeExistsByPath(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Boolean
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        exit(TempXMLBuffer.FindFirst());
    end;

    local procedure GetLastNodeByPathWithError(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        if TempXMLBuffer.FindLast() then
            exit(TempXMLBuffer.Value);
        Error('Node not found: %1', XPath);
    end;

    local procedure VerifyLastLineAmountMatchesQuantityTimesPrice(var TempXMLBuffer: Record "XML Buffer" temporary; QuantityXPath: Text; PriceXPath: Text; LineAmountXPath: Text)
    var
        LineAmount: Decimal;
        Price: Decimal;
        Quantity: Decimal;
    begin
        Evaluate(Quantity, GetLastNodeByPathWithError(TempXMLBuffer, QuantityXPath), 9);
        Evaluate(Price, GetLastNodeByPathWithError(TempXMLBuffer, PriceXPath), 9);
        Evaluate(LineAmount, GetLastNodeByPathWithError(TempXMLBuffer, LineAmountXPath), 9);
        Assert.AreEqual(LineAmount, Round(Quantity * Price, 0.01), 'The quantity times the unit price must stay the net amount of the line.');
    end;

    local procedure GetAttributeByPathWithError(var TempXMLBuffer: Record "XML Buffer" temporary; ElementXPath: Text; AttributeName: Text): Text
    var
        TempXMLBufferAttribute: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, ElementXPath);
        if TempXMLBuffer.FindFirst() then begin
            TempXMLBufferAttribute.Copy(TempXMLBuffer, true);
            TempXMLBufferAttribute.Reset();
            TempXMLBufferAttribute.SetRange("Parent Entry No.", TempXMLBuffer."Entry No.");
            TempXMLBufferAttribute.SetRange(Type, TempXMLBufferAttribute.Type::Attribute);
            TempXMLBufferAttribute.SetRange(Name, AttributeName);
            if TempXMLBufferAttribute.FindFirst() then
                exit(TempXMLBufferAttribute.Value);
        end;
        Error(AttributeNotFoundErr, AttributeName, ElementXPath);
    end;

    local procedure GetVATRegistrationNo(VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]): Text[30];
    begin
        if CopyStr(VATRegistrationNo, 1, 2) <> CountryRegionCode then
            exit(CountryRegionCode + VATRegistrationNo);
        exit(VATRegistrationNo);
    end;

    local procedure CalculateLineAmounts(SalesInvoiceHeader: Record "Sales Invoice Header"; var LineAmounts: Dictionary of [Text, Decimal])
    var
        SalesInvLine: Record "Sales Invoice Line";
        Currency: Record Currency;
    begin
        GetCurrencyCode(SalesInvoiceHeader."Currency Code", Currency);
        SalesInvLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvLine.FindSet();
        if SalesInvoiceHeader."Prices Including VAT" then
            repeat
                SalesInvLine."Line Discount Amount" := Round(SalesInvLine."Line Discount Amount" / (1 + SalesInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesInvLine."Inv. Discount Amount" := Round(SalesInvLine."Inv. Discount Amount" / (1 + SalesInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesInvLine."Unit Price" := Round(SalesInvLine."Unit Price" / (1 + SalesInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesInvLine.Modify(true);
            until SalesInvLine.Next() = 0;

        SalesInvLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");

        if not LineAmounts.ContainsKey(SalesInvLine.FieldName(Amount)) then
            LineAmounts.Add(SalesInvLine.FieldName(Amount), SalesInvLine.Amount);
        if not LineAmounts.ContainsKey(SalesInvLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(SalesInvLine.FieldName("Amount Including VAT"), SalesInvLine."Amount Including VAT");
        if not LineAmounts.ContainsKey(SalesInvLine.FieldName("Inv. Discount Amount")) then
            LineAmounts.Add(SalesInvLine.FieldName("Inv. Discount Amount"), SalesInvLine."Inv. Discount Amount");
    end;

    local procedure CalculateLineAmounts(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var LineAmounts: Dictionary of [Text, Decimal])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Currency: Record Currency;
    begin
        GetCurrencyCode(SalesCrMemoHeader."Currency Code", Currency);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindSet();
        if SalesCrMemoHeader."Prices Including VAT" then
            repeat
                SalesCrMemoLine."Line Discount Amount" := Round(SalesCrMemoLine."Line Discount Amount" / (1 + SalesCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesCrMemoLine."Inv. Discount Amount" := Round(SalesCrMemoLine."Inv. Discount Amount" / (1 + SalesCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesCrMemoLine."Unit Price" := Round(SalesCrMemoLine."Unit Price" / (1 + SalesCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesCrMemoLine.Modify(true);
            until SalesCrMemoLine.Next() = 0;

        SalesCrMemoLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");

        if not LineAmounts.ContainsKey(SalesCrMemoLine.FieldName(Amount)) then
            LineAmounts.Add(SalesCrMemoLine.FieldName(Amount), SalesCrMemoLine.Amount);
        if not LineAmounts.ContainsKey(SalesCrMemoLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(SalesCrMemoLine.FieldName("Amount Including VAT"), SalesCrMemoLine."Amount Including VAT");
        if not LineAmounts.ContainsKey(SalesCrMemoLine.FieldName("Inv. Discount Amount")) then
            LineAmounts.Add(SalesCrMemoLine.FieldName("Inv. Discount Amount"), SalesCrMemoLine."Inv. Discount Amount");
    end;

    local procedure CalculateLineAmounts(ServiceInvoiceHeader: Record "Service Invoice Header"; var LineAmounts: Dictionary of [Text, Decimal])
    var
        ServiceInvLine: Record "Service Invoice Line";
        Currency: Record Currency;
    begin
        GetCurrencyCode(ServiceInvoiceHeader."Currency Code", Currency);
        ServiceInvLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvLine.FindSet();
        if ServiceInvoiceHeader."Prices Including VAT" then
            repeat
                ServiceInvLine."Line Discount Amount" := Round(ServiceInvLine."Line Discount Amount" / (1 + ServiceInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceInvLine."Inv. Discount Amount" := Round(ServiceInvLine."Inv. Discount Amount" / (1 + ServiceInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceInvLine."Unit Price" := Round(ServiceInvLine."Unit Price" / (1 + ServiceInvLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceInvLine.Modify(true);
            until ServiceInvLine.Next() = 0;

        ServiceInvLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");

        if not LineAmounts.ContainsKey(ServiceInvLine.FieldName(Amount)) then
            LineAmounts.Add(ServiceInvLine.FieldName(Amount), ServiceInvLine.Amount);
        if not LineAmounts.ContainsKey(ServiceInvLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(ServiceInvLine.FieldName("Amount Including VAT"), ServiceInvLine."Amount Including VAT");
        if not LineAmounts.ContainsKey(ServiceInvLine.FieldName("Inv. Discount Amount")) then
            LineAmounts.Add(ServiceInvLine.FieldName("Inv. Discount Amount"), ServiceInvLine."Inv. Discount Amount");
    end;

    local procedure CalculateLineAmounts(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var LineAmounts: Dictionary of [Text, Decimal])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        Currency: Record Currency;
    begin
        GetCurrencyCode(ServiceCrMemoHeader."Currency Code", Currency);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindSet();
        if ServiceCrMemoHeader."Prices Including VAT" then
            repeat
                ServiceCrMemoLine."Line Discount Amount" := Round(ServiceCrMemoLine."Line Discount Amount" / (1 + ServiceCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceCrMemoLine."Inv. Discount Amount" := Round(ServiceCrMemoLine."Inv. Discount Amount" / (1 + ServiceCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceCrMemoLine."Unit Price" := Round(ServiceCrMemoLine."Unit Price" / (1 + ServiceCrMemoLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServiceCrMemoLine.Modify(true);
            until ServiceCrMemoLine.Next() = 0;

        ServiceCrMemoLine.CalcSums(Amount, "Amount Including VAT", "Inv. Discount Amount");

        if not LineAmounts.ContainsKey(ServiceCrMemoLine.FieldName(Amount)) then
            LineAmounts.Add(ServiceCrMemoLine.FieldName(Amount), ServiceCrMemoLine.Amount);
        if not LineAmounts.ContainsKey(ServiceCrMemoLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(ServiceCrMemoLine.FieldName("Amount Including VAT"), ServiceCrMemoLine."Amount Including VAT");
        if not LineAmounts.ContainsKey(ServiceCrMemoLine.FieldName("Inv. Discount Amount")) then
            LineAmounts.Add(ServiceCrMemoLine.FieldName("Inv. Discount Amount"), ServiceCrMemoLine."Inv. Discount Amount");
    end;

    local procedure GetTotalTaxAmount(SalesInvoiceHeader: Record "Sales Invoice Header"): Decimal
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvLine.SetFilter(
          "VAT Calculation Type", '%1|%2|%3',
          SalesInvLine."VAT Calculation Type"::"Normal VAT",
          SalesInvLine."VAT Calculation Type"::"Full VAT",
          SalesInvLine."VAT Calculation Type"::"Reverse Charge VAT");
        SalesInvLine.CalcSums(Amount, "Amount Including VAT");
        SalesInvLine.SetRange("VAT Calculation Type");
        exit(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount);
    end;

    local procedure GetTotalTaxAmount(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Decimal
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(
          "VAT Calculation Type", '%1|%2|%3',
          SalesCrMemoLine."VAT Calculation Type"::"Normal VAT",
          SalesCrMemoLine."VAT Calculation Type"::"Full VAT",
          SalesCrMemoLine."VAT Calculation Type"::"Reverse Charge VAT");
        SalesCrMemoLine.CalcSums(Amount, "Amount Including VAT");
        SalesCrMemoLine.SetRange("VAT Calculation Type");
        exit(SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount);
    end;

    local procedure GetTotalTaxAmount(ServiceInvoiceHeader: Record "Service Invoice Header"): Decimal
    var
        ServiceInvLine: Record "Service Invoice Line";
    begin
        ServiceInvLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvLine.SetFilter(
          "VAT Calculation Type", '%1|%2|%3',
          ServiceInvLine."VAT Calculation Type"::"Normal VAT",
          ServiceInvLine."VAT Calculation Type"::"Full VAT",
          ServiceInvLine."VAT Calculation Type"::"Reverse Charge VAT");
        ServiceInvLine.CalcSums(Amount, "Amount Including VAT");
        ServiceInvLine.SetRange("VAT Calculation Type");
        exit(ServiceInvLine."Amount Including VAT" - ServiceInvLine.Amount);
    end;

    local procedure GetTotalTaxAmount(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Decimal
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(
          "VAT Calculation Type", '%1|%2|%3',
          ServiceCrMemoLine."VAT Calculation Type"::"Normal VAT",
          ServiceCrMemoLine."VAT Calculation Type"::"Full VAT",
          ServiceCrMemoLine."VAT Calculation Type"::"Reverse Charge VAT");
        ServiceCrMemoLine.CalcSums(Amount, "Amount Including VAT");
        ServiceCrMemoLine.SetRange("VAT Calculation Type");
        exit(ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount);
    end;



    local procedure CreateCSVDocumentAttachment(ServiceInvoiceHeader: Record "Service Invoice Header"; FileName: Text): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ServiceInvoiceHeader);
        exit(CreateCSVDocumentAttachment(RecRef, FileName));
    end;

    local procedure CreateCSVDocumentAttachment(RecRef: RecordRef; FileName: Text): Text
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        TextBuilder: TextBuilder;
        OutStream: OutStream;
        CSVText: Text;
    begin
        // Build CSV content using TextBuilder
        TextBuilder.AppendLine('Name,Value');
        TextBuilder.Append('Item1,100');
        CSVText := TextBuilder.ToText();

        // Create blob with CSV content
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(CSVText);

        // Save attachment to the document
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);

        exit(CSVText);
    end;

    local procedure CreateDocumentAttachment(RecRef: RecordRef; FileName: Text; ContentText: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ContentText);
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure GetCurrencyCode(DocumentCurrencyCode: Code[10]; var Currency: Record Currency): Code[10]
    begin
        if DocumentCurrencyCode = '' then begin
            Currency.InitRoundingPrecision();
            exit(GeneralLedgerSetup."LCY Code");
        end else begin
            Currency.Get(DocumentCurrencyCode);
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
            exit(DocumentCurrencyCode);
        end;
    end;

    local procedure FormatDate(VarDate: Date): Text[20];
    begin
        if VarDate = 0D then
            exit('1753-01-01');
        exit(Format(VarDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure CreateVATClauseWithVATEXCode(VATBusPostingGroup: Code[20]; VATProductPostingGroup: Code[20])
    var
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClauseCode: Code[10];
    begin
        VATClauseCode := LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Code), Database::"VAT Clause");
        VATClause.Init();
        VATClause.Validate(Code, VATClauseCode);
        VATClause.Validate(Description, 'Not subject to VAT');
        VATClause.Validate("VATEX Code", 'VATEX-EU-O');
        VATClause.Insert(true);
        VATPostingSetup.Get(VATBusPostingGroup, VATProductPostingGroup);
        VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        VATPostingSetup.Modify(true);
    end;

    local procedure Initialize();
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"XRechnung XML Document Tests");
        if IsInitialized then begin
            RestoreCompanyIdentifiers();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"XRechnung XML Document Tests");
        IsInitialized := true;

        CompanyInformation.Get();
        OriginalCompanyGLN := CompanyInformation.GLN;
        OriginalCompanyUsesGLN := CompanyInformation."Use GLN in Electronic Document";
        OriginalCompanyUsesRegistrationNo := CompanyInformation."Use Reg. No. in E-Document";
        OriginalCompanyVATRegistrationNo := CompanyInformation."VAT Registration No.";
        OriginalCompanyRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CompanyInformation."SWIFT Code" := LibraryUtility.GenerateGUID();
        CompanyInformation."E-Mail" := LibraryUtility.GenerateRandomEmail();
        CompanyInformation.Modify();

        GeneralLedgerSetup.Get();

        EDocumentService.DeleteAll();
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::XRechnung, "Service Integration"::"No Integration"));
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"XRechnung XML Document Tests");
    end;

    local procedure RestoreCompanyIdentifiers()
    begin
        CompanyInformation.Get();
        CompanyInformation.GLN := OriginalCompanyGLN;
        CompanyInformation."Use GLN in Electronic Document" := OriginalCompanyUsesGLN;
        CompanyInformation."Use Reg. No. in E-Document" := OriginalCompanyUsesRegistrationNo;
        CompanyInformation."VAT Registration No." := OriginalCompanyVATRegistrationNo;
        CompanyInformation."Registration No." := OriginalCompanyRegistrationNo;
        CompanyInformation.Modify();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}