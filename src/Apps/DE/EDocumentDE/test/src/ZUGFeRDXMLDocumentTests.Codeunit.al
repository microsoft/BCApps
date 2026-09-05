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
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
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
using System.Utilities;

codeunit 13922 "ZUGFeRD XML Document Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [ZUGFeRD E-document]
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
        ZUGFeRDFormat: Codeunit "ZUGFeRD Format";
        ExportZUGFeRDDocument: Codeunit "Export ZUGFeRD Document";
        IncorrectValueErr: Label 'Incorrect value for %1', Locked = true;
        AttributeNotFoundErr: Label 'Attribute %1 not found for node: %2', Locked = true, Comment = '%1 = XML attribute name, %2 = XML element XPath';
        UnexpectedNodeErr: Label 'Node %1 must not exist.', Locked = true;
        DocumentAllowanceChargeTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        InvoiceLineTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
        InvoiceLineAllowanceChargeTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        MonetarySummationTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation', Locked = true;
        HeaderTradeTaxTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        LineMonetarySummationTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation', Locked = true;
        BilledQuantityTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity', Locked = true;
        TaxCategoryStandardTok: Label 'S', Locked = true;
        ItemChargeReasonTextTok: Label 'Freight surcharge', Locked = true;
        ItemChargeReasonCodeTok: Label 'FC', Locked = true;
        UnitCodeOneTok: Label 'C62', Locked = true;
        UnitCodeHourTok: Label 'HUR', Locked = true;
        DocumentLineTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
        SellerTaxRegistrationTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID', Locked = true;
        BuyerGlobalIdTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:GlobalID', Locked = true;
        ShipToGlobalIdTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty/ram:GlobalID', Locked = true;
        IsInitialized: Boolean;
        OriginalCompanyGLN: Code[13];
        OriginalCompanyUsesGLN: Boolean;
        OriginalCompanyUsesRegistrationNo: Boolean;
        OriginalCompanyVATRegistrationNo: Text[20];
        OriginalCompanyRegistrationNo: Text[20];

    #region SalesInvoice
    [Test]
    procedure CheckSalesInvoiceInZUGFeRDFormatVATRegNoNotMandatoryWithCustomerReference();
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
    procedure CheckSalesInvoiceInZUGFeRDFormatVATRegNoMandatoryWithYourReference();
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
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyHeaderData();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with header data from the document
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created
        VerifyHeaderData(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with customer reference
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with Customer X, E-invoice routing no. = XY
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XY
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post Sales Invoice for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XX
        VerifyBuyerReference(SalesInvoiceHeader."Your Reference", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifySellerOrderReference();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice from sales order creates electronic document in ZUGFeRD format with seller order reference
        Initialize();

        // [GIVEN] Create and Post Sales Invoice from Sales Order
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceFromOrder());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with seller order reference
        VerifySellerOrderReference(SalesInvoiceHeader."Order No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerOrderReference();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO 644035] Export posted sales invoice creates electronic document in ZUGFeRD format with buyer order reference
        Initialize();

        // [GIVEN] Create and post sales invoice with external document no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CreateCustomerWithoutRoutingNo());
        ExternalDocumentNo := CopyStr(LibraryRandom.RandText(MaxStrLen(ExternalDocumentNo)), 1, MaxStrLen(ExternalDocumentNo));
        SalesHeader.Validate("External Document No.", ExternalDocumentNo);
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer order reference from external document no.
        VerifyBuyerOrderReference(ExternalDocumentNo, TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatMandateBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Mandate buyer reference as your reference when releasing sales invoice for ZUGFeRD format
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
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifySellerDataApplicableHeaderTradeAgreement();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with company data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with company data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatWithRespCenterVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice creates electronic document in ZUGFeRD format with responsibility center data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithRespCenter("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, ResponsibilityCenter.Code));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with responsibility data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerDataApplicableHeaderTradeAgreement();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with customer data
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with customer data
        VerifyBuyerData(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifySupplierRegistrationNo()
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

        // [WHEN] Export ZUGFeRD electronic document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Seller tax identifier contains the Registration No. with FC tax scheme
        Assert.AreEqual(RegistrationNo, GetNodeByPathWithError(TempXMLBuffer, SellerTaxRegistrationTok), StrSubstNo(IncorrectValueErr, SellerTaxRegistrationTok));
        Assert.AreEqual('FC', GetAttributeByPathWithError(TempXMLBuffer, SellerTaxRegistrationTok, 'schemeID'), StrSubstNo(IncorrectValueErr, SellerTaxRegistrationTok + '/@schemeID'));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyCustomerGLN();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Customer GLN is exported for buyer and ship-to parties in ZUGFeRD format
        Initialize();

        // [GIVEN] Create and post a sales invoice for a customer that uses GLN in electronic documents
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(CustomerGLN(), ShipToGLN(), true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Buyer and ship-to GlobalID contain the customer GLN with schemeID 0088
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, BuyerGlobalIdTok);
        VerifyGLNIdentifier(ShipToGLN(), TempXMLBuffer, ShipToGlobalIdTok);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatDoesNotExportCustomerGLNWhenDisabled();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Customer GLN is not exported in ZUGFeRD format when GLN use is disabled
        Initialize();

        // [GIVEN] A customer and ship-to address with GLNs, but GLN use in electronic documents disabled
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomerWithGLNAndShipToGLN(CustomerGLN(), ShipToGLN(), false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Buyer and ship-to GLN identifiers are not exported
        VerifyNodeDoesNotExist(TempXMLBuffer, BuyerGlobalIdTok);
        VerifyNodeDoesNotExist(TempXMLBuffer, ShipToGlobalIdTok);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerContactWithAllFields();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice with all buyer contact fields populated
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with contact, phone, and email.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with all buyer contact fields
        VerifyBuyerContactData(SalesInvoiceHeader, TempXMLBuffer, true, true, true);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerContactWithoutPhone();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice without buyer phone number
        Initialize();

        // [GIVEN] Create and Post Sales Invoice without phone number.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithoutPhone("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with contact and email, but no phone
        VerifyBuyerContactData(SalesInvoiceHeader, TempXMLBuffer, true, false, true);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBuyerContactWithoutContactName();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice without buyer contact name
        Initialize();

        // [GIVEN] Create and Post Sales Invoice without contact name.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithoutContact("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with phone and email, but no contact name
        VerifyBuyerContactData(SalesInvoiceHeader, TempXMLBuffer, false, true, true);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyPaymentMeans();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with bank informarion as payment means
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with bank information as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', SalesInvoiceHeader."Currency Code");
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyBankAccountPaymentMeans();
    var
        BankAccount: Record "Bank Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BankAccountIBAN: Code[50];
        BankAccountSWIFT: Code[20];
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document uses Bank Account IBAN and SWIFT Code
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', BankAccountIBAN, BankAccountSWIFT);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyPaymentTerms();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with payment terms
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with payment terms
        VerifyPaymentTerms(SalesInvoiceHeader."Payment Terms Code", SalesInvoiceHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDueDate();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export "Due Date" when no "Payment Terms" are defined for the customer, ensuring a valid ZUGFeRD format.
        Initialize();

        // [GIVEN] Create and Post Sales Invoice without Payment Terms.
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));
        SalesHeader."Payment Terms Code" := '';
        SalesHeader.Modify();
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with due date
        VerifyDueDate(SalesInvoiceHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyTaxTotal();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with different tax totals
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with different tax totals
        VerifyTaxTotals(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyLegalMonetaryTotal();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with document totals
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyLegalMonetaryTotalWithMultipleLines();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice with multiple lines creates ZUGFeRD document where LineTotalAmount equals the sum of all line amounts (BR-CO-10)
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with two lines.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] LineTotalAmount reflects the sum of all invoice lines, not just the last line
        VerifyLegalMonetaryTotal(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyInvoiceLine();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales invoice creates electronic document in ZUGFeRD format with 2 invoice lines
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 invoice lines
        VerifyInvoiceLine(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatIncludesGTIN()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD product identification contains the item's GTIN and GS1 scheme
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] A posted item invoice where the item has a GTIN
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesInvoiceHeader, GTIN);

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Global product identification contains the GTIN with scheme 0160
        Path := '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetNodeByPathWithError(TempXMLBuffer, Path + '/@schemeID'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatIncludesProductIdentifiers()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        ItemReferenceNo: Code[50];
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD invoice keeps standard, seller, and buyer product identifiers separate
        Initialize();
        GTIN := '4006381333931';
        ItemReferenceNo := LibraryUtility.GenerateGUID();

        // [GIVEN] A posted item invoice with a GTIN and buyer item reference
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithItemReference("Sales Document Type"::Invoice, ItemReferenceNo));
        SetItemGTIN(SalesInvoiceHeader, GTIN);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Each product identifier is exported in its corresponding element
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(1, CountNodesByPath(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetNodeByPathWithError(TempXMLBuffer, Path + '/@schemeID'), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesInvoiceLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:BuyerAssignedID';
        Assert.AreEqual(ItemReferenceNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatOmitsGTINForNonItemLine()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD product identification omits GTIN for a non-item line
        Initialize();

        // [GIVEN] A posted invoice with a non-item line
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::"G/L Account", false));

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Global product identification does not exist
        Path := '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyInvoiceLineWithLineDiscount();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in ZUGFeRD format with 2 invoice lines, one line has line discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with line discount
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 invoice lines and one line has line discount
        VerifyInvoiceLineWithDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatWithCustomReportLayout();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales invoice with Custom Report Layout creates electronic document in ZUGFeRD format
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [GIVEN] Custom Report Layout is used
        UpdateReport(Enum::"Report Selection Usage"::"S.Invoice", Report::"ZUGFeRD Custom Sales Invoice");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created
        VerifyHeaderData(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyVATEXCodeAndExemptionReason();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TradeTaxTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        // [SCENARIO] Export posted sales invoice creates electronic document in ZUGFeRD format with VATEX code and exemption reason from VAT Clause
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [GIVEN] VAT Clause with VATEX Code 'VATEX-EU-O' and Description 'Not subject to VAT' linked to the VAT Posting Setup
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        CreateVATClauseWithVATEXCode(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ExemptionReasonCode and ExemptionReason are exported with correct values
        Path := TradeTaxTok + '/ram:ExemptionReasonCode';
        Assert.AreEqual('VATEX-EU-O', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := TradeTaxTok + '/ram:ExemptionReason';
        Assert.AreEqual('Not subject to VAT', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure PrintPostedSalesInvoiceWithCustomReportLayout();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PDFDocument: Codeunit "PDF Document";
        PDFTempBlob: Codeunit "Temp Blob";
        TempBlob: Codeunit "Temp Blob";
        PDFInStream: InStream;
    begin
        // [SCENARIO] Print a posted sales invoice with Custom Report Layout. Ensure that no xml is embedded
        Initialize();

        // [GIVEN] Create and Post Sales Invoice.
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [GIVEN] Custom Report Layout is used
        UpdateReport(Enum::"Report Selection Usage"::"S.Invoice", Report::"ZUGFeRD Custom Sales Invoice");

        // [WHEN] Create PDF Attachment
        ExportZUGFeRDDocument.GenerateSalesInvoicePDFAttachment(SalesInvoiceHeader, PDFTempBlob);

        // [THEN] No XML should be embedded
        PDFTempBlob.CreateInStream(PDFInStream);
        Assert.IsFalse(PDFDocument.GetDocumentAttachmentStream(PDFInStream, TempBlob), 'No Document Attachment should be found.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyGlobalID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622248] Export posted sales invoice verifies GlobalID contains GTIN when set
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] Create and Post Sales Invoice with GTIN
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesInvoiceHeader, GTIN);

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] GlobalID element exists with the GTIN value
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatNoGlobalIDWhenEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622248] Export posted sales invoice does not export GlobalID when GTIN is empty
        Initialize();

        // [GIVEN] Create and Post Sales Invoice without GTIN
        SalesInvoiceHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] GlobalID element does not exist
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    #endregion

    #region SalesCreditMemo
    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyHeaderData();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with header data from the document
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created
        VerifyHeaderData(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatIncludesGTIN()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD credit-memo product identification contains the item's GTIN and GS1 scheme
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] A posted item credit memo where the item has a GTIN
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesCrMemoHeader, GTIN);

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Global product identification contains the GTIN with scheme 0160
        Path := '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetNodeByPathWithError(TempXMLBuffer, Path + '/@schemeID'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatIncludesProductIdentifiers()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        ItemReferenceNo: Code[50];
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD credit memo keeps standard, seller, and buyer product identifiers separate
        Initialize();
        GTIN := '4006381333931';
        ItemReferenceNo := LibraryUtility.GenerateGUID();

        // [GIVEN] A posted item credit memo with a GTIN and buyer item reference
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithItemReference("Sales Document Type"::"Credit Memo", ItemReferenceNo));
        SetItemGTIN(SalesCrMemoHeader, GTIN);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Each product identifier is exported in its corresponding element
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(1, CountNodesByPath(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual('0160', GetNodeByPathWithError(TempXMLBuffer, Path + '/@schemeID'), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesCrMemoLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:BuyerAssignedID';
        Assert.AreEqual(ItemReferenceNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatOmitsGTINForNonItemLine()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [SCENARIO] Exported ZUGFeRD credit-memo product identification omits GTIN for a non-item line
        Initialize();

        // [GIVEN] A posted credit memo with a non-item line
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::"G/L Account", false));

        // [WHEN] Export ZUGFeRD Electronic Document
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Global product identification does not exist
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with customer reference
        Initialize();

        // [GIVEN] Create and Post sales cr. memo with Customer X, E-invoice routing no. = XY
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XY
        Customer.Get(SalesCrMemoHeader."Bill-to Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post sales cr. memo for customer without routing no.
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CreateCustomerWithoutRoutingNo());
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XX
        VerifyBuyerReference(SalesCrMemoHeader."Your Reference", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyCustomerGLN();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 646443] Customer GLN is exported for buyer and ship-to parties in ZUGFeRD credit memo format
        Initialize();

        // [GIVEN] Create and post a sales credit memo for a customer that uses GLN in electronic documents
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoForCustomerWithGLN(CustomerGLN()));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] Buyer and ship-to GlobalID contain the customer GLN with schemeID 0088
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, BuyerGlobalIdTok);
        VerifyGLNIdentifier(CustomerGLN(), TempXMLBuffer, ShipToGlobalIdTok);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifySellerOrderReference();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales cr. memo from return order creates electronic document in ZUGFeRD format with seller order reference
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo from Sales Return Order
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoFromReturnOrder());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with seller order reference
        VerifySellerOrderReference(SalesCrMemoHeader."Return Order No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatMandateBuyerReferenceAsYourReference();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Mandate buyer reference as your reference when releasing sales credit memo for ZUGFeRD format
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
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifySellerDataApplicableHeaderTradeAgreement();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with company data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with company data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatWithRespCenterVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales cr. memo creates electronic document in ZUGFeRD format with responsibility center data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithRespCenter("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, ResponsibilityCenter.Code));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with responsibility data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyBuyerDataApplicableHeaderTradeAgreement();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with customer data
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with customer data
        VerifyBuyerData(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyPaymentMeans();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with bank informarion as payment means
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with bank information as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', SalesCrMemoHeader."Currency Code");
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyBankAccountPaymentMeans();
    var
        BankAccount: Record "Bank Account";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BankAccountIBAN: Code[50];
        BankAccountSWIFT: Code[20];
    begin
        // [SCENARIO 496414] Export posted sales credit memo uses Bank Account IBAN and SWIFT Code when Company Bank Account Code is specified
        Initialize();

        // [GIVEN] Create Bank Account with specific IBAN and SWIFT Code
        BankAccountIBAN := LibraryUtility.GenerateMOD97CompliantCode();
        BankAccountSWIFT := LibraryUtility.GenerateGUID();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.IBAN := BankAccountIBAN;
        BankAccount."SWIFT Code" := BankAccountSWIFT;
        BankAccount.Modify(true);

        // [GIVEN] Create and Post Sales Credit Memo with Bank Account Code
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithBankAccount("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, BankAccount."No."));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document uses Bank Account IBAN and SWIFT Code
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', BankAccountIBAN, BankAccountSWIFT);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyPaymentTerms();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with payment terms
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with payment terms
        VerifyPaymentTerms(SalesCrMemoHeader."Payment Terms Code", SalesCrMemoHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyDueDate();
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export "Due Date" when no "Payment Terms" are defined for the customer, ensuring a valid ZUGFeRD format.
        Initialize();

        // [GIVEN] Create and Post Credit Memo without Payment Terms.
        SalesHeader.Get("Sales Document Type"::"Credit Memo", CreateSalesDocumentWithLine("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));
        SalesHeader."Payment Terms Code" := '';
        SalesHeader.Modify();
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with due date
        VerifyDueDate(SalesCrMemoHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyTaxTotal();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with different tax totals
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with different tax totals
        VerifyTaxTotals(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyLegalMonetaryTotal();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with document totals
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyLegalMonetaryTotalWithMultipleLines();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO] Export posted sales cr. memo with multiple lines creates ZUGFeRD document where LineTotalAmount equals the sum of all line amounts (BR-CO-10)
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo with two lines.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] LineTotalAmount reflects the sum of all cr. memo lines, not just the last line
        VerifyLegalMonetaryTotal(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyCrMemoLine();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 556034] Export posted sales cr. memo creates electronic document in ZUGFeRD format with 2 cr.memo lines
        Initialize();

        // [GIVEN] Create and Post sales cr. memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 cr.memo lines
        VerifyCrMemoLine(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyVATEXCodeAndExemptionReason();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TradeTaxTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        // [SCENARIO] Export posted sales cr. memo creates electronic document in ZUGFeRD format with VATEX code and exemption reason from VAT Clause
        Initialize();

        // [GIVEN] Create and Post Sales Credit Memo.
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [GIVEN] VAT Clause with VATEX Code 'VATEX-EU-O' and Description 'Not subject to VAT' linked to the VAT Posting Setup
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        CreateVATClauseWithVATEXCode(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ExemptionReasonCode and ExemptionReason are exported with correct values
        Path := TradeTaxTok + '/ram:ExemptionReasonCode';
        Assert.AreEqual('VATEX-EU-O', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := TradeTaxTok + '/ram:ExemptionReason';
        Assert.AreEqual('Not subject to VAT', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyGlobalID()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GTIN: Code[14];
        Path: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622248] Export posted sales cr. memo verifies GlobalID contains GTIN when set
        Initialize();
        GTIN := '4006381333931';

        // [GIVEN] Create and Post Sales Cr. Memo with GTIN
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));
        SetItemGTIN(SalesCrMemoHeader, GTIN);

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] GlobalID element exists with the GTIN value
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.AreEqual(GTIN, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatNoGlobalIDWhenEmpty()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Path: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622248] Export posted sales cr. memo does not export GlobalID when GTIN is empty
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo without GTIN
        SalesCrMemoHeader.Get(CreateAndPostSalesDocument("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, false));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] GlobalID element does not exist
        Path := DocumentLineTok + '/ram:SpecifiedTradeProduct/ram:GlobalID';
        Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), StrSubstNo(UnexpectedNodeErr, Path));
    end;

    #endregion

    #region ServiceInvoice
    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyHeaderData();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with header data from the document
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created
        VerifyHeaderData(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with customer reference
        Initialize();

        // [GIVEN] Create and Post Service Invoice with Customer X, E-invoice routing no. = XY
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XY
        Customer.Get(ServiceInvoiceHeader."Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post Service Invoice for customer without routing no.
        CreateServiceHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);
        ServiceInvoiceHeader.Get(PostServiceDocument(ServiceHeader));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XX
        VerifyBuyerReference(ServiceInvoiceHeader."Your Reference", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatMandateBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Mandate buyer reference as your reference when releasing service invoice for ZUGFeRD format
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
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with company data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with company data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatWithRespCenterVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with responsibility center data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocumentWithRespCenter(ResponsibilityCenter.Code));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with responsibility data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyBuyerDataApplicableHeaderTradeAgreement();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with customer data
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with customer data
        VerifyBuyerData(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyPaymentMeans();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with bank information as payment means
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with bank informarion as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', ServiceInvoiceHeader."Currency Code");
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyPaymentTerms();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with payment terms
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with payment terms
        VerifyPaymentTerms(ServiceInvoiceHeader."Payment Terms Code", ServiceInvoiceHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyTaxTotal();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with different tax totals
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with different tax totals
        VerifyTaxTotals(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyLegalMonetaryTotal();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with document totals
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(ServiceInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceInvoiceInZUGFeRDFormatVerifyInvoiceLine();
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service invoice creates electronic document in ZUGFeRD format with 2 invoice lines
        Initialize();

        // [GIVEN] Create and Post Service Invoice.
        ServiceInvoiceHeader.Get(CreateAndPostServiceDocumentWithTwoLines());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceInvoice(ServiceInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 invoice lines
        VerifyServiceInvoiceLine(ServiceInvoiceHeader, TempXMLBuffer);
    end;
    #endregion

    #region ServiceCreditMemo
    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyHeaderData();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with header data from the document
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created
        VerifyHeaderData(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyBuyerReferenceAsCustomerReference();
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with customer reference
        Initialize();

        // [GIVEN] Create and Post service cr. memo with Customer X, E-invoice routing no. = XY
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XY
        Customer.Get(ServiceCrMemoHeader."Customer No.");
        VerifyBuyerReference(Customer."E-Invoice Routing No.", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with your reference from the document
        Initialize();

        // [GIVEN] Create and Post service cr. memo for customer without routing no.
        CreateServiceCrMemoHeader(ServiceHeader, CreateCustomerWithoutRoutingNo());
        CreateServiceLine(ServiceHeader);
        ServiceCrMemoHeader.Get(PostServiceCrMemoDocument(ServiceHeader));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with buyer reference XX
        VerifyBuyerReference(ServiceCrMemoHeader."Your Reference", TempXMLBuffer, '/rsm:CrossIndustryInvoice');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatMandateBuyerReferenceAsYourReference();
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Mandate buyer reference as your reference when releasing service credit memo for ZUGFeRD format
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
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with company data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with company data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatWithRespCenterVerifySellerDataApplicableHeaderTradeAgreement();
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with responsibility center data as seller in applicable header trade agreement
        Initialize();

        // [GIVEN] Responsibility Center
        CreateResponsibilityCenter(ResponsibilityCenter);

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocumentWithRespCenter(ResponsibilityCenter.Code));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with responsibility data as seller in applicable header trade agreement
        VerifySellerData(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty', ResponsibilityCenter);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyBuyerDataApplicableHeaderTradeAgreement();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with customer data
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with customer data
        VerifyBuyerData(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyPaymentMeans();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with bank information as payment means
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with bank informarion as payment means
        VerifyPaymentMeans(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', ServiceCrMemoHeader."Currency Code");
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyPaymentTerms();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with payment terms
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with payment terms
        VerifyPaymentTerms(ServiceCrMemoHeader."Payment Terms Code", ServiceCrMemoHeader."Due Date", TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms');
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyTaxTotal();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with different tax totals
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with different tax totals
        VerifyTaxTotals(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyLegalMonetaryTotal();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with document totals
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocument());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with document totals
        VerifyLegalMonetaryTotal(ServiceCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedServiceCrMemoInZUGFeRDFormatVerifyCrMemoLine();
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 604872] Export posted service cr. memo creates electronic document in ZUGFeRD format with 2 cr.memo lines
        Initialize();

        // [GIVEN] Create and Post service cr. memo.
        ServiceCrMemoHeader.Get(CreateAndPostServiceCrMemoDocumentWithTwoLines());

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportServiceCreditMemo(ServiceCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 cr.memo lines
        VerifyServiceCrMemoLine(ServiceCrMemoHeader, TempXMLBuffer);
    end;
    #endregion
    #region InvoiceDiscount

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyInvoiceWithInvoiceDiscounts();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in ZUGFeRD format with 2 invoice lines and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 invoice lines and invoice discount
        VerifyInvoiceWithInvDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyInvoiceWithInvoiceDiscountsAndLineDiscount();
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales invoice creates electronic document in ZUGFeRD format with 2 invoice lines with discount and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount and line discount on one line
        SalesInvoiceHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::Invoice, Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 invoice lines with line discount and invoice discount
        VerifyInvoiceWithInvDiscount(SalesInvoiceHeader, TempXMLBuffer);
        VerifyInvoiceLineWithDiscount(SalesInvoiceHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyCrMemoWithInvoiceDiscounts();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales cr. memo creates electronic document in ZUGFeRD format with 2 lines and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Invoice with invoice discount
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLines("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 lines and invoice discount
        VerifyCrMemoWithInvDiscount(SalesCrMemoHeader, TempXMLBuffer);
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyCrMemoWithInvoiceDiscountsAndLineDiscount();
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 575895] Export posted sales cr.memo creates electronic document in ZUGFeRD format with 2 cr.memo lines with discount and invoice discount
        Initialize();

        // [GIVEN] Create and Post Sales Cr. Memo with invoice discount and line discount on one line
        SalesCrMemoHeader.Get(CreateAndPostSalesDocumentWithTwoLinesLineDiscount("Sales Document Type"::"Credit Memo", Enum::"Sales Line Type"::Item, true));

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] ZUGFeRD Electronic Document is created with 2 lines with line discount and invoice discount
        VerifyCrMemoWithInvDiscount(SalesCrMemoHeader, TempXMLBuffer);
        VerifyCrMemoLineWithDiscounts(SalesCrMemoHeader, TempXMLBuffer);
    end;
    #endregion
    #region PurchaseInvoice
    [Test]
    procedure ReleasePurchaseInvoiceInZUGFeRDFormat();
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Release purchase invoice regardless if ZUGFeRD format is setup with customer reference
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
    procedure ReleasePurchaseCreditMemoInZUGFeRDFormat();
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Release purchase credit memo regardless if ZUGFeRD format is setup with customer reference
        Initialize();

        // [GIVEN] Set Buyer reference = customer reference
        SetBuyerReferenceMandatory();

        // [WHEN] Create and release Purchase credit Memo
        CreatePurchDocument(PurchaseHeader, "Purchase Document Type"::"Credit Memo");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] No error occurs
    end;
    #endregion

    #region ItemCharge
    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDocumentLevelItemChargeAllowanceCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge classified as a document level allowance/charge is exported as ram:SpecifiedTradeAllowanceCharge in the header trade settlement instead of as an invoice line
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and one item charge assigned to both of them
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] A document level charge is exported with the amount and the VAT category of the item charge
        Path := DocumentAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:CategoryTradeTax/ram:CategoryCode';
        Assert.AreEqual(TaxCategoryStandardTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:CategoryTradeTax/ram:RateApplicablePercent';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatFiveDecimal(ChargeSalesInvoiceLine."VAT %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item charge is no longer exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'Only the item lines must be exported as invoice lines.');
        Assert.IsFalse(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID', ItemChargeNo), 'The item charge must not be exported as an invoice line.');

        // [THEN] The charge is not repeated as a line level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'A document level charge must not be exported inside an invoice line.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDocumentLevelItemChargeReason()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The reason code and the reason text of the item charge are exported
        Path := DocumentAllowanceChargeTok + '/ram:ReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual(ItemChargeReasonTextTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDocumentLevelItemChargeReasonFallsBackToDescription()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The description of the item charge line is exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual(ChargeSalesInvoiceLine.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] No empty reason code is exported
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok + '/ram:ReasonCode'), 'An item charge without a reason code must not export an empty reason code.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDocumentLevelItemChargeReasonFallsBackToItemChargeNo()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The code of the item charge is exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual(ItemChargeNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyDocumentLevelItemChargeWithReasonCodeOnlyKeepsTheReasonCode()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The reason code of the item charge is exported
        Path := DocumentAllowanceChargeTok + '/ram:ReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The code of the item charge is not exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual('', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyLineLevelItemChargeAllowanceCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        ItemSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge classified as a line level allowance/charge is exported inside the line trade settlement of the invoice line it is assigned to
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with one item line and an item charge with the same VAT assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        GetItemInvoiceLine(SalesInvoiceHeader, ItemSalesInvoiceLine);

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the invoice line of the assigned line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Path := InvoiceLineTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ItemSalesInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The line level allowance/charge carries no VAT category, because the VAT category of the invoice line applies
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok + '/ram:CategoryTradeTax/ram:CategoryCode'), 'A line level allowance/charge must not carry its own VAT category.');

        // [THEN] The charge is not repeated as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'A line level charge must not be exported as a document level allowance/charge.');

        // [THEN] The net amount of the invoice line includes the charge
        Path := LineMonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ItemSalesInvoiceLine.Amount + ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyLineLevelItemChargeOnlyAffectsTheAssignedLine()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] Exactly one invoice line carries the allowance/charge
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'The charge must be exported in the assigned invoice line only.');

        // [THEN] Only the assigned invoice line reports the charge in its net amount
        Path := LineMonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(AssignedLineAmount + ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(UnassignedLineAmount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyItemChargeInvoiceLineUsesFallbackQuantityAndUnitCode()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line.');
        Path := InvoiceLineTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ChargeSalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The invoice line of the item charge carries quantity 1 and the unit code C62
        Path := BilledQuantityTok;
        Assert.AreEqual('1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The unit price of the invoice line matches the net amount, so that quantity times price stays the net amount of the line
        Path := InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item line keeps its own quantity and unit code
        Path := BilledQuantityTok;
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ItemSalesInvoiceLine.Quantity), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(ExportZUGFeRDDocument.GetUoMCode(ItemSalesInvoiceLine."Unit of Measure Code"), GetAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyItemChargeInvoiceLineUsesUnitCodeOfItemCharge()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The invoice line of the item charge carries the unit code of the item charge
        Path := BilledQuantityTok;
        Assert.AreEqual(UnitCodeHourTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyNegativeItemChargeInvoiceLineUsesNegativeQuantity()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge exported as a regular invoice line reports a negative quantity and a positive net price, so that the exported document satisfies BR-27
        Initialize();

        // [GIVEN] A service that forces item charges into an invoice line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales invoice with one item line and a negative item charge assigned to that line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(1, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        Assert.IsTrue(ChargeSalesInvoiceLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as an invoice line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line.');
        Path := InvoiceLineTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ChargeSalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The invoice line of the item charge reports the negative fallback quantity with the fallback unit code
        Path := BilledQuantityTok;
        Assert.AreEqual('-1', GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The net price of the invoice line is not negative, because the item net price must never be negative
        Path := InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(-ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The net amount of the invoice line stays negative
        Path := LineMonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The quantity of the invoice line times its net price stays the net amount of the line
        VerifyLastLineAmountMatchesQuantityTimesPrice(
            TempXMLBuffer, BilledQuantityTok,
            InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount',
            LineMonetarySummationTok + '/ram:LineTotalAmount');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyNegativeItemChargeIsExportedAsAllowance()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported as an allowance with a positive amount
        Path := DocumentAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('false', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(-ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The allowance is reported in the allowance total and not in a charge total
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(-ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, MonetarySummationTok + '/ram:ChargeTotalAmount'), 'A negative item charge must not be reported as a charge total.');

        // [THEN] The totals stay consistent
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyForcedLineLevelItemChargeWithoutTargetLineIsDocumentLevel()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported at document level instead of inside an invoice line
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'An unresolved line level charge must not be exported inside an invoice line.');
        Path := DocumentAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The charge is not exported as an invoice line either
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'Only the item lines must be exported as invoice lines.');
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyTotalsWithDocumentLevelItemCharge()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ChargeSalesInvoiceLine: Record "Sales Invoice Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Moving an item charge out of the invoice lines keeps the monetary summation and the tax subtotals consistent
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales invoice with two item lines and one item charge assigned to both of them
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeInvoiceLine(SalesInvoiceHeader, ChargeSalesInvoiceLine);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The sum of the invoice lines no longer contains the charge and the charge is reported as the charge total
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:ChargeTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesInvoiceLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(0), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The exported invoice lines add up to the reported line total amount
        Assert.AreEqual(
            SalesInvoiceHeader.Amount - ChargeSalesInvoiceLine.Amount, SumNodeValuesByPath(TempXMLBuffer, LineMonetarySummationTok + '/ram:LineTotalAmount'),
            'The exported invoice lines must add up to the reported line total amount.');

        // [THEN] The remaining document totals are unchanged
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:TaxTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := HeaderTradeTaxTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := HeaderTradeTaxTok + '/ram:BasisAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyTotalsWithLineLevelItemCharge()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the invoice line it is assigned to
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate invoice line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'The item charge must be exported as a line level allowance/charge.');

        // [THEN] The line total amount still contains the charge and no charge total is reported
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, MonetarySummationTok + '/ram:ChargeTotalAmount'), 'A line level charge must not be reported as a charge total.');
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(0), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The exported invoice lines add up to the reported line total amount
        Assert.AreEqual(
            SalesInvoiceHeader.Amount, SumNodeValuesByPath(TempXMLBuffer, LineMonetarySummationTok + '/ram:LineTotalAmount'),
            'The exported invoice lines must add up to the reported line total amount.');

        // [THEN] The remaining document totals are unchanged
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := HeaderTradeTaxTok + '/ram:BasisAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyDocumentLevelItemChargeAllowanceCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo classified as a document level allowance/charge is exported as ram:SpecifiedTradeAllowanceCharge in the header trade settlement instead of as a credit memo line
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with two item lines and one item charge assigned to both of them
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);

        // [THEN] The item charge line of the credit memo carries a positive amount, so that a charge on a credit note keeps the charge indicator of an invoice
        Assert.IsTrue(ChargeSalesCrMemoLine.Amount > 0, 'The scenario requires a positive item charge amount on the credit memo.');

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] A document level charge is exported with the amount and the VAT category of the item charge
        Path := DocumentAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:CategoryTradeTax/ram:CategoryCode';
        Assert.AreEqual(TaxCategoryStandardTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:CategoryTradeTax/ram:RateApplicablePercent';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatFiveDecimal(ChargeSalesCrMemoLine."VAT %"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The description of the item charge line is exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual(ChargeSalesCrMemoLine.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The item charge is no longer exported as a credit memo line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'Only the item lines must be exported as credit memo lines.');
        Assert.IsFalse(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID', ItemChargeNo), 'The item charge must not be exported as a credit memo line.');

        // [THEN] The charge is not repeated as a line level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'A document level charge must not be exported inside a credit memo line.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyDocumentLevelItemChargeReasonFallsBackToItemChargeNo()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The code of the item charge is exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual(ItemChargeNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyDocumentLevelItemChargeWithReasonCodeOnlyKeepsTheReasonCode()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The reason code of the item charge is exported
        Path := DocumentAllowanceChargeTok + '/ram:ReasonCode';
        Assert.AreEqual(ItemChargeReasonCodeTok, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The code of the item charge is not exported as the reason
        Path := DocumentAllowanceChargeTok + '/ram:Reason';
        Assert.AreEqual('', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyLineLevelItemChargeAllowanceCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo classified as a line level allowance/charge is exported inside the line trade settlement of the credit memo line it is assigned to
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with one item line and an item charge with the same VAT assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        GetItemCrMemoLine(SalesCrMemoHeader, ItemSalesCrMemoLine);

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the credit memo line of the assigned line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate credit memo line.');
        Path := InvoiceLineTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ItemSalesCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('true', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := InvoiceLineAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The line level allowance/charge carries no VAT category, because the VAT category of the credit memo line applies
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok + '/ram:CategoryTradeTax/ram:CategoryCode'), 'A line level allowance/charge must not carry its own VAT category.');

        // [THEN] The charge is not repeated as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'A line level charge must not be exported as a document level allowance/charge.');

        // [THEN] The net amount of the credit memo line includes the charge
        Path := LineMonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ItemSalesCrMemoLine.Amount + ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyItemChargeCrMemoLineUsesFallbackQuantityAndUnitCode()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] An item charge of a posted sales credit memo exported as a regular credit memo line carries quantity 1 and the unit code C62, never an empty unit code
        Initialize();

        // [GIVEN] A service that forces item charges into a document line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales credit memo with one item line and an item charge of quantity 2 assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.AreEqual(2, ChargeSalesCrMemoLine.Quantity, 'The scenario requires an item charge quantity that differs from the fallback quantity.');
        Assert.AreEqual('', ChargeSalesCrMemoLine."Unit of Measure Code", 'The scenario requires an item charge line without a unit of measure.');

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as a credit memo line
        Assert.AreEqual(2, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as a credit memo line.');
        Path := InvoiceLineTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ChargeSalesCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The credit memo line of the item charge carries quantity 1 and the unit code C62
        Assert.AreEqual('1', GetLastNodeByPathWithError(TempXMLBuffer, BilledQuantityTok), StrSubstNo(IncorrectValueErr, BilledQuantityTok));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, BilledQuantityTok, 'unitCode'), StrSubstNo(IncorrectValueErr, BilledQuantityTok));

        // [THEN] The unit price of the credit memo line matches the net amount, so that quantity times price stays the net amount of the line
        Path := InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ChargeSalesCrMemoLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] No allowance/charge is exported for the item charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'An item charge exported as a credit memo line must not be exported as an allowance/charge.');
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'An item charge exported as a credit memo line must not be exported as an allowance/charge.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyNegativeItemChargeCrMemoLineUsesNegativeQuantity()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A negative item charge of a posted sales credit memo exported as a regular credit memo line reports a negative quantity and a positive net price, so that the exported document satisfies BR-27
        Initialize();

        // [GIVEN] A service that forces item charges into a document line with a unit code
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");

        // [GIVEN] A posted sales credit memo with one item line and a negative item charge assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 2, -LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        Assert.IsTrue(ChargeSalesCrMemoLine.Amount < 0, 'The scenario requires a negative item charge amount.');

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The credit memo line of the item charge reports the negative fallback quantity with the fallback unit code
        Assert.AreEqual('-1', GetLastNodeByPathWithError(TempXMLBuffer, BilledQuantityTok), StrSubstNo(IncorrectValueErr, BilledQuantityTok));
        Assert.AreEqual(UnitCodeOneTok, GetLastAttributeByPathWithError(TempXMLBuffer, BilledQuantityTok, 'unitCode'), StrSubstNo(IncorrectValueErr, BilledQuantityTok));

        // [THEN] The net price of the credit memo line is not negative, because the item net price must never be negative
        Path := InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(-ChargeSalesCrMemoLine.Amount), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The quantity of the credit memo line times its net price stays the net amount of the line
        VerifyLastLineAmountMatchesQuantityTimesPrice(
            TempXMLBuffer, BilledQuantityTok,
            InvoiceLineTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount',
            LineMonetarySummationTok + '/ram:LineTotalAmount');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyNegativeItemChargeIsExportedAsAllowance()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported as an allowance with a positive amount
        Path := DocumentAllowanceChargeTok + '/ram:ChargeIndicator/udt:Indicator';
        Assert.AreEqual('false', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentAllowanceChargeTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(-ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The allowance is reported in the allowance total and not in a charge total
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(-ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, MonetarySummationTok + '/ram:ChargeTotalAmount'), 'A negative item charge must not be reported as a charge total.');

        // [THEN] The totals stay consistent
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyTotalsWithDocumentLevelItemCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ChargeSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] Moving an item charge out of the credit memo lines keeps the monetary summation and the tax subtotals consistent
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with two item lines and one item charge assigned to both of them
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(2, 2, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        GetChargeCrMemoLine(SalesCrMemoHeader, ChargeSalesCrMemoLine);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The sum of the credit memo lines no longer contains the charge and the charge is reported as the charge total
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:ChargeTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ChargeSalesCrMemoLine.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(0), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The exported credit memo lines add up to the reported line total amount
        Assert.AreEqual(
            SalesCrMemoHeader.Amount - ChargeSalesCrMemoLine.Amount, SumNodeValuesByPath(TempXMLBuffer, LineMonetarySummationTok + '/ram:LineTotalAmount'),
            'The exported credit memo lines must add up to the reported line total amount.');

        // [THEN] The remaining document totals are unchanged
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := HeaderTradeTaxTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := HeaderTradeTaxTok + '/ram:BasisAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyTotalsWithLineLevelItemCharge()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
        Path: Text;
    begin
        // [SCENARIO] A line level allowance/charge on a posted sales credit memo stays inside the sum of the credit memo lines and leaves the document totals untouched
        Initialize();

        // [GIVEN] A service that maps item charges automatically
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::Automatic);

        // [GIVEN] A posted sales credit memo with one item line and an item charge with the same VAT assigned to that line
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithItemCharge(1, 1, LibraryRandom.RandDecInRange(10, 50, 2), ItemChargeNo));
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The charge is exported inside the credit memo line it is assigned to
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must not be exported as a separate credit memo line.');
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineAllowanceChargeTok), 'The item charge must be exported as a line level allowance/charge.');

        // [THEN] The line total amount still contains the charge and no charge total is reported
        Path := MonetarySummationTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, MonetarySummationTok + '/ram:ChargeTotalAmount'), 'A line level charge must not be reported as a charge total.');
        Path := MonetarySummationTok + '/ram:AllowanceTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(0), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The exported credit memo lines add up to the reported line total amount
        Assert.AreEqual(
            SalesCrMemoHeader.Amount, SumNodeValuesByPath(TempXMLBuffer, LineMonetarySummationTok + '/ram:LineTotalAmount'),
            'The exported credit memo lines must add up to the reported line total amount.');

        // [THEN] The remaining document totals are unchanged
        Path := MonetarySummationTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := MonetarySummationTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader."Amount Including VAT"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The tax subtotal still covers the charge
        Path := HeaderTradeTaxTok + '/ram:BasisAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader.Amount), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    [Test]
    procedure ExportPostedSalesInvoiceInZUGFeRDFormatVerifyChargeKeepsInvoiceLineWhenTheOnlyItemLineIsNotExported()
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

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportInvoice(SalesInvoiceHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as the only invoice line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as an invoice line, so that the document keeps at least one invoice line.');
        Assert.IsTrue(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID', ItemChargeNo), 'The exported invoice line must be the item charge.');

        // [THEN] The invoice line of the item charge carries the fallback quantity and the unit code C62
        Path := BilledQuantityTok;
        Assert.AreEqual('1', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Assert.AreEqual(UnitCodeOneTok, GetAttributeByPathWithError(TempXMLBuffer, Path, 'unitCode'), StrSubstNo(IncorrectValueErr, Path));

        // [THEN] The charge is not exported as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'The item charge must not be exported as a document level allowance/charge.');
    end;

    [Test]
    procedure ExportPostedSalesCrMemoInZUGFeRDFormatVerifyChargeKeepsCrMemoLineWhenTheOnlyItemLineIsNotExported()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ItemSalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        ItemChargeNo: Code[20];
    begin
        // [SCENARIO] A posted sales credit memo whose only item line is skipped by the export keeps the item charge as a credit memo line even when the service forces a document level allowance/charge, so that the exported document satisfies BR-16
        Initialize();

        // [GIVEN] A service that forces item charges into a document level allowance/charge
        SetServiceItemChargeMapping(EDocumentService."Item Charge E-Invoice Mapping"::"Document Allowance/Charge");

        // [GIVEN] A posted sales credit memo with an item charge assigned to an earlier return receipt and one item line without a quantity, which the export skips
        SalesCrMemoHeader.Get(CreateAndPostSalesCrMemoWithChargeAndZeroQuantityLine(ItemChargeNo));
        GetItemCrMemoLine(SalesCrMemoHeader, ItemSalesCrMemoLine);
        Assert.AreEqual(0, ItemSalesCrMemoLine.Quantity, 'The scenario requires an item line without a quantity.');

        // [WHEN] Export ZUGFeRD Electronic Document.
        ExportCreditMemo(SalesCrMemoHeader, TempXMLBuffer);

        // [THEN] The item charge is exported as the only credit memo line
        Assert.AreEqual(1, GetNodeCountByPath(TempXMLBuffer, InvoiceLineTok), 'The item charge must be exported as a credit memo line, so that the document keeps at least one credit memo line.');
        Assert.IsTrue(NodeValueExists(TempXMLBuffer, InvoiceLineTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID', ItemChargeNo), 'The exported credit memo line must be the item charge.');

        // [THEN] The credit memo line of the item charge carries the fallback quantity and the unit code C62
        Assert.AreEqual('1', GetNodeByPathWithError(TempXMLBuffer, BilledQuantityTok), StrSubstNo(IncorrectValueErr, BilledQuantityTok));
        Assert.AreEqual(UnitCodeOneTok, GetAttributeByPathWithError(TempXMLBuffer, BilledQuantityTok, 'unitCode'), StrSubstNo(IncorrectValueErr, BilledQuantityTok));

        // [THEN] The charge is not exported as a document level allowance/charge
        Assert.AreEqual(0, GetNodeCountByPath(TempXMLBuffer, DocumentAllowanceChargeTok), 'The item charge must not be exported as a document level allowance/charge.');
    end;
    #endregion

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

    local procedure GetItemInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
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

    local procedure CreateAndPostSalesDocumentWithItemReference(DocumentType: Enum "Sales Document Type"; ItemReferenceNo: Code[50]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithLine(DocumentType, Enum::"Sales Line Type"::Item, false));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine."Item Reference No." := ItemReferenceNo;
        SalesLine.Modify();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceFromOrder(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Order, CreateSalesDocumentWithLine("Sales Document Type"::Order, Enum::"Sales Line Type"::Item, false));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesCrMemoFromReturnOrder(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::"Return Order", CreateSalesDocumentWithLine("Sales Document Type"::"Return Order", Enum::"Sales Line Type"::Item, false));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithoutPhone(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithoutPhone(DocumentType, LineType));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithoutContact(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, CreateSalesDocumentWithoutContact(DocumentType, LineType));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
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

    local procedure CreateAndPostServiceDocument(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, CreateServiceDocumentWithLine());
        exit(PostServiceDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceDocumentWithTwoLines(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, CreateServiceDocumentWithTwoLines());
        exit(PostServiceDocument(ServiceHeader));
    end;

    local procedure CreateAndPostServiceDocumentWithRespCenter(RespCenterCode: Code[10]): Code[20]
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

    local procedure CreateSalesDocumentWithoutPhone(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        SalesHeader.Validate("Sell-to Phone No.", '');
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, LineType, false);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocumentWithoutContact(DocumentType: Enum "Sales Document Type"; LineType: Enum "Sales Line Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Contact", '');
        SalesHeader.SetHideValidationDialog(false);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, LineType, false);
        exit(SalesHeader."No.");
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
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 2, SalesHeader);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type");
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]);
    var
        PostCode: Record "Post Code";
        PaymentMethod: Record "Payment Method";
        PaymentTermsCode: Code[10];
    begin
        LibraryERM.FindPostCode(PostCode);
        PaymentTermsCode := LibraryERM.FindPaymentTermsCode();
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Sell-to Contact", SalesHeader."No.");
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Bill-to City", PostCode.City);
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Ship-to City", PostCode.City);
        SalesHeader.Validate("Sell-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Sell-to City", PostCode.City);
        SalesHeader.Validate("Sell-to Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateRandomText(20));
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Validate("Due Date", LibraryRandom.RandDate(LibraryRandom.RandIntInRange(5, 10)));
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

    local procedure CreateAndPostSalesCrMemoForCustomerWithGLN(GLN: Code[13]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CreateCustomerWithGLN(GLN, true));
        CreateSalesLine(SalesHeader, Enum::"Sales Line Type"::Item, false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
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
        ZUGFeRDFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);
    end;

    local procedure CheckSalesHeader(SalesHeader: Record "Sales Header")
    var
        SourceDocumentHeader: RecordRef;
    begin
        SourceDocumentHeader.GetTable(SalesHeader);
        ZUGFeRDFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Release);
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
        TempBlob2: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        PDFInStream: InStream;
        PdfAttachmentStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        SourceDocumentLines.GetTable(SalesInvoiceLine);
        ZUGFeRDFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(PdfInStream);
        PDFDocument.GetDocumentAttachmentStream(PdfInStream, TempBlob2);
        TempBlob2.CreateInStream(PdfAttachmentStream);
        TempXMLBuffer.LoadFromStream(PdfAttachmentStream);
    end;

    local procedure ExportCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        PDFInStream: InStream;
        PdfAttachmentStream: InStream;
    begin
        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        SourceDocumentLines.GetTable(SalesCrMemoLine);
        ZUGFeRDFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(PdfInStream);
        PDFDocument.GetDocumentAttachmentStream(PdfInStream, TempBlob2);
        TempBlob2.CreateInStream(PdfAttachmentStream);
        TempXMLBuffer.LoadFromStream(PdfAttachmentStream);
    end;

    local procedure ExportServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        PDFInStream: InStream;
        PdfAttachmentStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceInvoiceHeader);
        SourceDocumentLines.GetTable(ServiceInvoiceLine);
        ZUGFeRDFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(PdfInStream);
        PDFDocument.GetDocumentAttachmentStream(PdfInStream, TempBlob2);
        TempBlob2.CreateInStream(PdfAttachmentStream);
        TempXMLBuffer.LoadFromStream(PdfAttachmentStream);
    end;

    local procedure ExportServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        PDFDocument: Codeunit "PDF Document";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
        PDFInStream: InStream;
        PdfAttachmentStream: InStream;
    begin
        SourceDocumentHeader.GetTable(ServiceCrMemoHeader);
        SourceDocumentLines.GetTable(ServiceCrMemoLine);
        ZUGFeRDFormat.Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);

        TempBlob.CreateInStream(PdfInStream);
        PDFDocument.GetDocumentAttachmentStream(PdfInStream, TempBlob2);
        TempBlob2.CreateInStream(PdfAttachmentStream);
        TempXMLBuffer.LoadFromStream(PdfAttachmentStream);
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
        DocumentTok: Label '/rsm:CrossIndustryInvoice', Locked = true;
        Path: Text;
    begin
        Path := DocumentTok + '/rsm:ExchangedDocument/ram:TypeCode';
        Assert.AreEqual('380', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/rsm:ExchangedDocument/ram:ID';
        Assert.AreEqual(SalesInvoiceHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesInvoiceHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        // Verify Seller Order Reference is not present when invoice is posted directly (without order)
        if SalesInvoiceHeader."Order No." = '' then
            Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerOrderReferencedDocument'), 'Seller Order Reference should not exist');
    end;

    local procedure VerifyHeaderData(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentCreditNoteTok: Label '/rsm:CrossIndustryInvoice', Locked = true;
        Path: Text;
    begin
        Path := DocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:TypeCode';
        Assert.AreEqual('381', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:ID';
        Assert.AreEqual(SalesCrMemoHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesCrMemoHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        // Verify Seller Order Reference is not present when cr. memo is posted directly (without return order)
        if SalesCrMemoHeader."Return Order No." = '' then
            Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerOrderReferencedDocument'), 'Seller Order Reference should not exist');
    end;

    local procedure VerifyHeaderData(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTok: Label '/rsm:CrossIndustryInvoice', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTok + '/rsm:ExchangedDocument/ram:TypeCode';
        Assert.AreEqual('380', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentTok + '/rsm:ExchangedDocument/ram:ID';
        Assert.AreEqual(ServiceInvoiceHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentTok + '/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(ServiceInvoiceHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyHeaderData(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentCreditNoteTok: Label '/rsm:CrossIndustryInvoice', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:TypeCode';
        Assert.AreEqual('381', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:ID';
        Assert.AreEqual(ServiceCrMemoHeader."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentCreditNoteTok + '/rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(ServiceCrMemoHeader."Posting Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerReference(BuyerReference: Text[50]; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerReference';
        Assert.AreEqual(BuyerReference, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySellerOrderReference(OrderNo: Code[20]; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:SellerOrderReferencedDocument/ram:IssuerAssignedID';
        Assert.AreEqual(OrderNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerOrderReference(ExternalDocumentNo: Code[35]; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID';
        Assert.AreEqual(ExternalDocumentNo, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySellerData(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    begin
        VerifySellerData(TempXMLBuffer, DocumentTok, CompanyInformation.Address, CompanyInformation."Post Code", CompanyInformation.City);
    end;

    local procedure VerifySellerData(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; ResponsibilityCenter: Record "Responsibility Center");
    begin
        VerifySellerData(TempXMLBuffer, DocumentTok, ResponsibilityCenter.Address, ResponsibilityCenter."Post Code", ResponsibilityCenter.City);
    end;

    local procedure VerifySellerData(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; Address: Text[100]; PostCode: Code[20]; City: Text[30])
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:Name';
        Assert.AreEqual(CompanyInformation.Name, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentTok + '/ram:PostalTradeAddress/ram:LineOne';
        Assert.AreEqual(Address, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:PostalTradeAddress/ram:PostcodeCode';
        Assert.AreEqual(PostCode, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:PostalTradeAddress/ram:CityName';
        Assert.AreEqual(City, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentTok + '/ram:URIUniversalCommunication/ram:URIID';
        Assert.AreEqual(CompanyInformation."E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentTok + '/ram:SpecifiedTaxRegistration/ram:ID';
        Assert.AreEqual(GetVATRegistrationNo(CompanyInformation."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerData(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentPartyTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty', Locked = true;
        Path: Text;
    begin
        Path := DocumentPartyTok + '/ram:Name';
        Assert.AreEqual(SalesInvoiceHeader."Bill-to Name", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentPartyTok + '/ram:URIUniversalCommunication/ram:URIID';
        Assert.AreEqual(SalesInvoiceHeader."Sell-to E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := DocumentPartyTok + '/ram:SpecifiedTaxRegistration/ram:ID';
        Assert.AreEqual(GetVATRegistrationNo(SalesInvoiceHeader."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerContactData(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary; ExpectContactName: Boolean; ExpectPhone: Boolean; ExpectEmail: Boolean);
    var
        DocumentBuyerContactTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:DefinedTradeContact', Locked = true;
        Path: Text;
        NodeValue: Text;
    begin
        // Check if DefinedTradeContact element exists when any field is populated
        if ExpectContactName or ExpectPhone or ExpectEmail then
            Assert.IsTrue(NodeExistsByPath(TempXMLBuffer, DocumentBuyerContactTok), 'DefinedTradeContact element should exist when contact fields are populated');

        // Verify PersonName
        Path := DocumentBuyerContactTok + '/ram:PersonName';
        if ExpectContactName then begin
            NodeValue := GetNodeByPathWithError(TempXMLBuffer, Path);
            Assert.AreEqual(SalesInvoiceHeader."Sell-to Contact", NodeValue, StrSubstNo(IncorrectValueErr, Path));
        end else
            Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), 'PersonName should not exist when contact name is empty');

        // Verify TelephoneUniversalCommunication/CompleteNumber
        Path := DocumentBuyerContactTok + '/ram:TelephoneUniversalCommunication/ram:CompleteNumber';
        if ExpectPhone then begin
            NodeValue := GetNodeByPathWithError(TempXMLBuffer, Path);
            Assert.AreEqual(SalesInvoiceHeader."Sell-to Phone No.", NodeValue, StrSubstNo(IncorrectValueErr, Path));
        end else
            Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), 'TelephoneUniversalCommunication/CompleteNumber should not exist when phone is empty');

        // Verify EmailURIUniversalCommunication/URIID
        Path := DocumentBuyerContactTok + '/ram:EmailURIUniversalCommunication/ram:URIID';
        if ExpectEmail then begin
            NodeValue := GetNodeByPathWithError(TempXMLBuffer, Path);
            Assert.AreEqual(SalesInvoiceHeader."Sell-to E-Mail", NodeValue, StrSubstNo(IncorrectValueErr, Path));
        end else
            Assert.IsFalse(NodeExistsByPath(TempXMLBuffer, Path), 'EmailURIUniversalCommunication/URIID should not exist when email is empty');
    end;

    local procedure VerifyBuyerData(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentBuyerTradePartyTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty', Locked = true;
        Path: Text;
    begin
        Path := DocumentBuyerTradePartyTok + '/ram:Name';
        Assert.AreEqual(SalesCrMemoHeader."Bill-to Name", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentBuyerTradePartyTok + '/ram:SpecifiedTaxRegistration/ram:ID';
        Assert.AreEqual(GetVATRegistrationNo(SalesCrMemoHeader."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerData(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentPartyTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentPartyTok + '/ram:Name';
        Assert.AreEqual(ServiceInvoiceHeader."Bill-to Name", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := ServiceDocumentPartyTok + '/ram:URIUniversalCommunication/ram:URIID';
        Assert.AreEqual(ServiceInvoiceHeader."E-Mail", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));

        Path := ServiceDocumentPartyTok + '/ram:SpecifiedTaxRegistration/ram:ID';
        Assert.AreEqual(GetVATRegistrationNo(ServiceInvoiceHeader."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyBuyerData(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentBuyerTradePartyTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentBuyerTradePartyTok + '/ram:Name';
        Assert.AreEqual(ServiceCrMemoHeader."Bill-to Name", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentBuyerTradePartyTok + '/ram:SpecifiedTaxRegistration/ram:ID';
        Assert.AreEqual(GetVATRegistrationNo(ServiceCrMemoHeader."VAT Registration No.", CompanyInformation."Country/Region Code"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyPaymentMeans(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; CurrencyCode: Code[10]);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:InvoiceCurrencyCode';
        Assert.AreEqual(GetCurrencyCode(CurrencyCode), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode';
        Assert.AreEqual('58', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:IBANID';
        Assert.AreEqual(GetIBAN(CompanyInformation.IBAN), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyPaymentMeans(var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text; ExpectedIBAN: Code[50]; ExpectedSWIFT: Code[20])
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode';
        Assert.AreEqual('58', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:IBANID';
        Assert.AreEqual(GetIBAN(ExpectedIBAN), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        if ExpectedSWIFT <> '' then begin
            Path := DocumentTok + '/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID';
            Assert.AreEqual(GetIBAN(ExpectedSWIFT), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        end;
    end;

    local procedure VerifyPaymentTerms(PaymentTermsCode: Code[10]; DueDate: Date; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        PaymentTerms: Record "Payment Terms";
        Path: Text;
    begin
        PaymentTerms.Get(PaymentTermsCode);
        Path := DocumentTok + '/ram:Description';
        Assert.AreEqual(PaymentTerms.Description, GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:DueDateDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(DueDate), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyDueDate(DueDate: Date; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:DueDateDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(DueDate), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTaxTotalTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        Path := DocumentTaxTotalTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(GetTotalTaxAmount(SalesInvoiceHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTaxTotalsTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        Path := DocumentTaxTotalsTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(GetTotalTaxAmount(SalesCrMemoHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTaxTotalTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTaxTotalTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(GetTotalTaxAmount(ServiceInvoiceHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyTaxTotals(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceDocumentTaxTotalsTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax', Locked = true;
        Path: Text;
    begin
        Path := ServiceDocumentTaxTotalsTok + '/ram:CalculatedAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(GetTotalTaxAmount(ServiceCrMemoHeader)), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        LineAmounts: Dictionary of [Text, Decimal];
        DocumentLegalMonetaryTotalTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(SalesInvoiceHeader, LineAmounts);
        Path := DocumentLegalMonetaryTotalTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        LineAmounts: Dictionary of [Text, Decimal];
        DocumentLegalMonetaryTotalsTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(SalesCrMemoHeader, LineAmounts);
        Path := DocumentLegalMonetaryTotalsTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentLegalMonetaryTotalsTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(SalesCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        LineAmounts: Dictionary of [Text, Decimal];
        ServiceDocumentLegalMonetaryTotalTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(ServiceInvoiceHeader, LineAmounts);
        Path := ServiceDocumentLegalMonetaryTotalTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceInvoiceHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyLegalMonetaryTotal(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        LineAmounts: Dictionary of [Text, Decimal];
        ServiceDocumentLegalMonetaryTotalsTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation', Locked = true;
        Path: Text;
    begin
        CalculateLineAmounts(ServiceCrMemoHeader, LineAmounts);
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/ram:TaxBasisTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName(Amount))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/ram:GrandTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := ServiceDocumentLegalMonetaryTotalsTok + '/ram:DuePayableAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(LineAmounts.Get(ServiceCrMemoHeader.FieldName("Amount Including VAT"))), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();
        VerifyFirstSalesInvoiceLine(SalesInvoiceLine, TempXMLBuffer, DocumentTok);
        SalesInvoiceLine.Next();
        VerifySecondSalesInvoiceLine(SalesInvoiceLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyFirstSalesInvoiceLine(SalesInvoiceLine: Record "Sales Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(SalesInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesInvoiceLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesInvoiceLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(SalesInvoiceLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesInvoiceLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual(SalesInvoiceLine."Tax Category", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondSalesInvoiceLine(SalesInvoiceLine: Record "Sales Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(SalesInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesInvoiceLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesInvoiceLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(SalesInvoiceLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesInvoiceLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual(SalesInvoiceLine."Tax Category", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesInvoiceLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceLineWithDiscount(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindLast();
        Path := DocumentTok + '/ram:Reason';
        Assert.AreEqual('Line Discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceLine."Line Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyInvoiceWithInvDiscount(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesInvoiceHeader.CalcFields("Invoice Discount Amount");
        Path := DocumentTok + '/ram:Reason';
        Assert.AreEqual('Document discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesInvoiceHeader."Invoice Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindSet();
        VerifyFirstSalesICrMemoLine(SalesCrMemoLine, TempXMLBuffer, DocumentTok);
        SalesCrMemoLine.Next();
        VerifySecondSalesCrMemoLine(SalesCrMemoLine, TempXMLBuffer, DocumentTok);
    end;

    local procedure VerifyFirstSalesICrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(SalesCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesCrMemoLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesCrMemoLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(SalesCrMemoLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesCrMemoLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual(SalesCrMemoLine."Tax Category", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text);
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(SalesCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesCrMemoLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(SalesCrMemoLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(SalesCrMemoLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(SalesCrMemoLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual(SalesCrMemoLine."Tax Category", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString';
        Assert.AreEqual(FormatDate(SalesCrMemoLine."Shipment Date"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoLineWithDiscounts(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindLast();
        Path := DocumentTok + '/ram:Reason';
        Assert.AreEqual('Line Discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoLine."Line Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyCrMemoWithInvDiscount(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary);
    var
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge', Locked = true;
        Path: Text;
    begin
        SalesCrMemoHeader.CalcFields("Invoice Discount Amount");
        Path := DocumentTok + '/ram:Reason';
        Assert.AreEqual('Document discount', GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:ActualAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(SalesCrMemoHeader."Invoice Discount Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyServiceInvoiceLine(ServiceInvoiceHeader: Record "Service Invoice Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
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
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ServiceInvoiceLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ServiceInvoiceLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(ServiceInvoiceLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(ServiceInvoiceLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondServiceInvoiceLine(ServiceInvoiceLine: Record "Service Invoice Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ServiceInvoiceLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ServiceInvoiceLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(ServiceInvoiceLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(ServiceInvoiceLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceInvoiceLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifyServiceCrMemoLine(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        DocumentTok: Label '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', Locked = true;
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
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ServiceCrMemoLine."Line No."), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Quantity"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ServiceCrMemoLine."Amount"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(ServiceCrMemoLine."No.", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(ServiceCrMemoLine."Description", GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Unit Price"), GetNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure VerifySecondServiceCrMemoLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempXMLBuffer: Record "XML Buffer" temporary; DocumentTok: Text)
    var
        Path: Text;
    begin
        Path := DocumentTok + '/ram:AssociatedDocumentLineDocument/ram:LineID';
        Assert.AreEqual(Format(ServiceCrMemoLine."Line No."), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Quantity"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimal(ServiceCrMemoLine."Amount"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID';
        Assert.AreEqual(ServiceCrMemoLine."No.", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedTradeProduct/ram:Name';
        Assert.AreEqual(ServiceCrMemoLine."Description", GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
        Path := DocumentTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount';
        Assert.AreEqual(ExportZUGFeRDDocument.FormatDecimalUnlimited(ServiceCrMemoLine."Unit Price"), GetLastNodeByPathWithError(TempXMLBuffer, Path), StrSubstNo(IncorrectValueErr, Path));
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10];
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure SetBuyerReferenceMandatory()
    begin
        EDocumentService."Buyer Reference Mandatory" := true;
        EDocumentService.Modify();
    end;

    local procedure GetNodeByPathWithError(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Path, XPath);
        if TempXMLBuffer.FindFirst() then
            exit(TempXMLBuffer.GetValue());
        Error('Node not found: %1', XPath);
    end;

    local procedure NodeExistsByPath(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Boolean
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        exit(TempXMLBuffer.FindFirst());
    end;

    local procedure CountNodesByPath(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Integer
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, XPath);
        exit(TempXMLBuffer.Count());
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

    local procedure GetVATRegistrationNo(VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]): Text[30];
    begin
        if CopyStr(VATRegistrationNo, 1, 2) <> CountryRegionCode then
            exit(CountryRegionCode + VATRegistrationNo);
        exit(VATRegistrationNo);
    end;

    local procedure GetIBAN(IBAN: Text[50]) IBANFormatted: Text[50]
    begin
        // Format IBAN to remove spaces and ensure it is in uppercase
        if IBAN = '' then
            exit('');
        IBANFormatted := UpperCase(DelChr(IBAN, '=', ' '));
        exit(CopyStr(IBANFormatted, 1, 50));
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
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums(Amount, "Amount Including VAT");

        if not LineAmounts.ContainsKey(ServiceInvoiceLine.FieldName(Amount)) then
            LineAmounts.Add(ServiceInvoiceLine.FieldName(Amount), ServiceInvoiceLine.Amount);
        if not LineAmounts.ContainsKey(ServiceInvoiceLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(ServiceInvoiceLine.FieldName("Amount Including VAT"), ServiceInvoiceLine."Amount Including VAT");
    end;

    local procedure CalculateLineAmounts(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var LineAmounts: Dictionary of [Text, Decimal])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.CalcSums(Amount, "Amount Including VAT");

        if not LineAmounts.ContainsKey(ServiceCrMemoLine.FieldName(Amount)) then
            LineAmounts.Add(ServiceCrMemoLine.FieldName(Amount), ServiceCrMemoLine.Amount);
        if not LineAmounts.ContainsKey(ServiceCrMemoLine.FieldName("Amount Including VAT")) then
            LineAmounts.Add(ServiceCrMemoLine.FieldName("Amount Including VAT"), ServiceCrMemoLine."Amount Including VAT");
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
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(
          "VAT Calculation Type", '%1|%2|%3',
          ServiceInvoiceLine."VAT Calculation Type"::"Normal VAT",
          ServiceInvoiceLine."VAT Calculation Type"::"Full VAT",
          ServiceInvoiceLine."VAT Calculation Type"::"Reverse Charge VAT");
        ServiceInvoiceLine.CalcSums(Amount, "Amount Including VAT");
        ServiceInvoiceLine.SetRange("VAT Calculation Type");
        exit(ServiceInvoiceLine."Amount Including VAT" - ServiceInvoiceLine.Amount);
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

    local procedure UpdateReport(ReportUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelection: Record "Report Selections";
    begin
        if not ReportSelection.Get(ReportUsage, '1') then begin
            ReportSelection.Init();
            ReportSelection.Validate(Usage, ReportUsage);
            ReportSelection.Validate(Sequence, '1');
            ReportSelection.Validate("Report ID", ReportId);
            ReportSelection.Insert(true);
        end;
        if ReportSelection."Report ID" <> ReportId then begin
            ReportSelection.Validate("Report ID", ReportId);
            ReportSelection.Modify(true);
        end;
        ReportSelection.SetRange(Usage, ReportUsage);
        ReportSelection.SetFilter(Sequence, '<>1');
        if not ReportSelection.IsEmpty() then
            ReportSelection.DeleteAll(true);
    end;

    procedure FormatDate(VarDate: Date): Text[20];
    begin
        if VarDate = 0D then
            exit('17530101');
        exit(Format(VarDate, 0, '<Year4><Month,2><Day,2>'));
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

    local procedure Initialize();
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ZUGFeRD XML Document Tests");
        if IsInitialized then begin
            RestoreCompanyIdentifiers();
            exit;
        end;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ZUGFeRD XML Document Tests");
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
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::ZUGFeRD, "Service Integration"::"No Integration"));
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ZUGFeRD XML Document Tests");
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