// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 148148 "Factur-X CII XML Tests"
{
    Subtype = Test;
    Permissions = tabledata "Company Information" = rimd,
                  tabledata Customer = rimd,
                  tabledata "VAT Business Posting Group" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [Factur-X FR E-document]
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        CIIXMLBuilder: Codeunit "CII XML Builder";
        IncorrectValueErr: Label 'Incorrect value for %1', Comment = '%1 = XML element path', Locked = true;
        FacturXProfileIdTok: Label 'urn:cen.eu:en16931:2017', Locked = true;
        CustomerVATNoSequence: Integer;
        IsInitialized: Boolean;

    #region SalesInvoice
    [Test]
    procedure FacturXSalesInvoiceXMLHasTypeCode380()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales invoice has TypeCode 380
        Initialize();

        // [GIVEN] Posted sales invoice
        // [WHEN] Create CII XML via FR CII XML Builder
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] ExchangedDocument/TypeCode = '380'
        Assert.AreEqual('380', GetCIINodeValue(TempBlob, '//rsm:ExchangedDocument/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:TypeCode'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasFacturXProfileId()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales invoice declares the EN16931 Factur-X profile
        Initialize();

        // [GIVEN] Posted sales invoice
        // [WHEN] Create CII XML via FR CII XML Builder
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] GuidelineSpecifiedDocumentContextParameter/ID = FacturX EN16931 profile URI
        Assert.AreEqual(FacturXProfileIdTok,
            GetCIINodeValue(TempBlob, '//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasDocumentNumber()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales invoice contains the document number
        Initialize();

        // [GIVEN] Posted sales invoice with known number
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ExchangedDocument/ID = invoice number
        Assert.AreEqual(SalesInvoiceHeader."No.",
            GetCIINodeValue(TempBlob, '//rsm:ExchangedDocument/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerSIRET()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales invoice contains company SIRET as SellerTradeParty/ID
        Initialize();

        // [GIVEN] Posted sales invoice / Company information with SIRET
        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SellerTradeParty/ID = SIRET No.
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerSIRENWithScheme()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has seller SpecifiedLegalOrganization/ID = SIREN with schemeID 0002
        Initialize();

        // [GIVEN] Posted sales invoice / Company information with Registration No.
        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SpecifiedLegalOrganization/ID = Registration No.
        Assert.AreEqual(CompanyInformation."Registration No.",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID'));

        // [THEN] schemeID attribute = '0002'
        Assert.AreEqual('0002',
            GetCIIAttributeValue(TempBlob, '//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerName()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has seller name from Company Information
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SellerTradeParty/Name = company name
        Assert.AreEqual(CompanyInformation.Name,
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:Name'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerVATRegistration()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has seller VAT registration number with scheme VA
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SellerTradeParty/SpecifiedTaxRegistration/ID = VAT registration no.
        Assert.AreEqual(CompanyInformation."VAT Registration No.",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));
        Assert.AreEqual('VA',
            GetCIIAttributeValue(TempBlob, '//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has buyer name from customer
        Initialize();

        // [GIVEN] Posted sales invoice for a known customer
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/Name = customer name
        Assert.AreEqual(Customer.Name,
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:Name'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLBuyerNameUsesPostedSnapshotNotLiveMaster()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        PostedBuyerName: Text[100];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing the customer master after posting does not change the buyer name on an issued document
        Initialize();

        // [GIVEN] Posted sales invoice with the buyer name captured at posting time
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        PostedBuyerName := SalesInvoiceHeader."Sell-to Customer Name";

        // [GIVEN] The customer master record is renamed after the document was posted
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate(Name, CopyStr(Customer.Name + ' RENAMED', 1, MaxStrLen(Customer.Name)));
        Customer.Modify(true);

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/Name = posted snapshot name, not the edited live master name
        Assert.AreEqual(PostedBuyerName,
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:Name'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerFRElectronicAddressAsURIID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        ElecAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has buyer FR Electronic Address as BuyerTradeParty/URIUniversalCommunication/URIID
        Initialize();

        // [GIVEN] Customer with FR Electronic Address
        ElecAddress := '98765432101234';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithElecAddress(ElecAddress));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID = FR Electronic Address
        Assert.AreEqual(ElecAddress,
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLBuyerFallsBackToVATNoWhenFRElecAddressBlank()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML uses buyer VAT Registration No. with schemeID 9957 as fallback when FR Electronic Address is blank (BR-FR-12)
        Initialize();

        // [GIVEN] Posted sales invoice with customer having no FR Electronic Address but having a VAT Registration No.
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID = customer VAT Registration No. (BR-FR-12 fallback)
        Assert.AreEqual(Customer."VAT Registration No.",
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));

        // [THEN] schemeID = '9957'
        Assert.AreEqual('9957',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSettlementCurrencyCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBlob: Codeunit "Temp Blob";
        ExpectedCurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML settlement currency code matches the document currency or LCY
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        GeneralLedgerSetup.Get();
        if SalesInvoiceHeader."Currency Code" <> '' then
            ExpectedCurrencyCode := SalesInvoiceHeader."Currency Code"
        else
            ExpectedCurrencyCode := GeneralLedgerSetup."LCY Code";

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ApplicableHeaderTradeSettlement/InvoiceCurrencyCode = expected currency
        Assert.AreEqual(ExpectedCurrencyCode,
            GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceCurrencyCode'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasIssueDateTimeFormat102()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        ExpectedDate: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has IssueDateTime/DateTimeString formatted as YYYYMMDD with format attribute 102
        Initialize();

        // [GIVEN] Posted sales invoice with a known posting date
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] IssueDateTime/DateTimeString = posting date as YYYYMMDD
        ExpectedDate := Format(SalesInvoiceHeader."Posting Date", 0, '<Year4><Month,2><Day,2>');
        Assert.AreEqual(ExpectedDate,
            GetCIINodeValue(TempBlob, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString'));

        // [THEN] format attribute = '102'
        Assert.AreEqual('102',
            GetCIIAttributeValue(TempBlob, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString/@format'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString/@format'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerPostalAddress()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has seller postal address from Company Information
        Initialize();

        // [GIVEN] Company Information with address
        CompanyInformation.Get();
        if CompanyInformation.Address = '' then begin
            CompanyInformation.Address := '123 Test Street';
            CompanyInformation.City := 'Paris';
            CompanyInformation."Post Code" := '75001';
            CompanyInformation.Modify(true);
        end;

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SellerTradeParty/PostalTradeAddress contains address fields
        Assert.AreEqual(CompanyInformation."Post Code",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:PostcodeCode'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:PostcodeCode'));
        Assert.AreEqual(CompanyInformation.Address,
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineOne'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineOne'));
        Assert.AreEqual(CompanyInformation.City,
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CityName'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CityName'));
        Assert.AreEqual(CompanyInformation."Country/Region Code",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSellerElectronicAddress()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has seller electronic address (BT-34) as SIRET with schemeID 0009
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SellerTradeParty/URIUniversalCommunication/URIID = SIRET
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID'));

        // [THEN] schemeID = '0009'
        Assert.AreEqual('0009',
            GetCIIAttributeValue(TempBlob, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerPostalAddress()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has buyer postal address from customer
        Initialize();

        // [GIVEN] Posted sales invoice for a customer with address
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/PostalTradeAddress/CountryID = customer country
        Assert.AreEqual(Customer."Country/Region Code",
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerVATRegistration()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has buyer VAT registration with schemeID VA
        Initialize();

        // [GIVEN] Posted sales invoice for a customer with VAT Registration No.
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/SpecifiedTaxRegistration/ID = customer VAT reg. no.
        Assert.AreEqual(Customer."VAT Registration No.",
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));

        // [THEN] schemeID = 'VA'
        Assert.AreEqual('VA',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerElecAddressSchemeID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        ElecAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML buyer electronic address URIID has schemeID from customer setting
        Initialize();

        // [GIVEN] Customer with FR Electronic Address and a SIRET electronic address scheme
        ElecAddress := '98765432101234';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithElecAddress(ElecAddress));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("FR Elec. Address Scheme", Customer."FR Elec. Address Scheme"::"0009");
        Customer.Modify(true);

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID/@schemeID = bare scheme code (not the enum caption)
        Assert.AreEqual('0009',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasPurchaseOrderReference()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        OrderRef: Code[35];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has BuyerOrderReferencedDocument from External Document No. (BT-13)
        Initialize();

        // [GIVEN] Posted sales invoice with External Document No.
        OrderRef := 'PO-2024-999';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithExtDocNo(OrderRef));

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerOrderReferencedDocument/IssuerAssignedID = External Document No.
        Assert.AreEqual(OrderRef,
            GetCIINodeValue(TempBlob, '//ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasDeliveryDate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        ExpectedDate: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has ActualDeliverySupplyChainEvent with delivery date (BT-72)
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ActualDeliverySupplyChainEvent/OccurrenceDateTime/DateTimeString has date
        // Delivery date falls back to document date if shipment date is empty
        if SalesInvoiceHeader."Shipment Date" <> 0D then
            ExpectedDate := Format(SalesInvoiceHeader."Shipment Date", 0, '<Year4><Month,2><Day,2>')
        else
            ExpectedDate := Format(SalesInvoiceHeader."Posting Date", 0, '<Year4><Month,2><Day,2>');

        Assert.AreEqual(ExpectedDate,
            GetCIINodeValue(TempBlob, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'),
            StrSubstNo(IncorrectValueErr, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'));

        // [THEN] format attribute = '102'
        Assert.AreEqual('102',
            GetCIIAttributeValue(TempBlob, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString/@format'),
            StrSubstNo(IncorrectValueErr, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString/@format'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasPaymentMeansTypeCode58()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has SpecifiedTradeSettlementPaymentMeans with TypeCode 58 (SEPA credit transfer)
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] SpecifiedTradeSettlementPaymentMeans/TypeCode = '58'
        Assert.AreEqual('58',
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasTaxBreakdown()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has ApplicableTradeTax with VAT type code and category
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] ApplicableTradeTax/TypeCode = 'VAT'
        Assert.AreEqual('VAT',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'));

        // [THEN] ApplicableTradeTax has BasisAmount
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount'));

        // [THEN] ApplicableTradeTax has CategoryCode
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'));

        // [THEN] ApplicableTradeTax has RateApplicablePercent
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasMonetarySummation()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has SpecifiedTradeSettlementHeaderMonetarySummation with all required amounts
        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] LineTotalAmount = Amount excl. VAT
        Assert.AreEqual(Format(SalesInvoiceHeader.Amount, 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount'));

        // [THEN] TaxBasisTotalAmount = Amount excl. VAT
        Assert.AreEqual(Format(SalesInvoiceHeader.Amount, 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount'));

        // [THEN] GrandTotalAmount = Amount incl. VAT
        Assert.AreEqual(Format(SalesInvoiceHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'));

        // [THEN] DuePayableAmount = Amount incl. VAT
        Assert.AreEqual(Format(SalesInvoiceHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount'));

        // [THEN] TaxTotalAmount is present with currencyID attribute
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount'));
        Assert.AreNotEqual('',
            GetCIIAttributeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount/@currencyID'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount/@currencyID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasLineItem()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has IncludedSupplyChainTradeLineItem with line details
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] Line has LineID
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'));

        // [THEN] Line has product name
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'));

        // [THEN] Line has net price
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'));

        // [THEN] Line has billed quantity
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'));

        // [THEN] Line has tax category code
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'));

        // [THEN] Line has line total amount
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLLineHasUnitCode()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML line BilledQuantity has unitCode attribute (BT-130)
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] BilledQuantity has unitCode attribute
        Assert.AreNotEqual('',
            GetCIIAttributeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLLineTaxHasVATTypeCode()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML line-level ApplicableTradeTax has TypeCode = 'VAT'
        Initialize();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] Line ApplicableTradeTax/TypeCode = 'VAT'
        Assert.AreEqual('VAT',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'));
    end;
    #endregion

    #region SalesCreditMemo
    [Test]
    procedure FacturXSalesCreditMemoXMLHasTypeCode381()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales credit memo has TypeCode 381
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] ExchangedDocument/TypeCode = '381'
        Assert.AreEqual('381', GetCIINodeValue(TempBlob, '//rsm:ExchangedDocument/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:TypeCode'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasDocumentNumber()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a sales credit memo contains the document number
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] ExchangedDocument/ID = credit memo number
        Assert.AreEqual(SalesCrMemoHeader."No.",
            GetCIINodeValue(TempBlob, '//rsm:ExchangedDocument/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//rsm:ExchangedDocument/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasSellerSIRET()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for credit memo contains company SIRET as SellerTradeParty/ID
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] SellerTradeParty/ID = SIRET No.
        Assert.AreEqual(CompanyInformation."SIRET No.",
            GetCIINodeValue(TempBlob, '//ram:SellerTradeParty/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:SellerTradeParty/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasFacturXProfileId()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo declares the EN16931 Factur-X profile
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] GuidelineSpecifiedDocumentContextParameter/ID = FacturX profile URI
        Assert.AreEqual(FacturXProfileIdTok,
            GetCIINodeValue(TempBlob, '//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasBuyerName()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo has buyer name from customer
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] BuyerTradeParty/Name = customer name
        Assert.AreEqual(Customer.Name,
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:Name'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasSettlementCurrencyCode()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBlob: Codeunit "Temp Blob";
        ExpectedCurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo has settlement currency code
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        GeneralLedgerSetup.Get();
        if SalesCrMemoHeader."Currency Code" <> '' then
            ExpectedCurrencyCode := SalesCrMemoHeader."Currency Code"
        else
            ExpectedCurrencyCode := GeneralLedgerSetup."LCY Code";

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] InvoiceCurrencyCode = expected currency
        Assert.AreEqual(ExpectedCurrencyCode,
            GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceCurrencyCode'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasMonetarySummation()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo has SpecifiedTradeSettlementHeaderMonetarySummation
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] GrandTotalAmount = Amount incl. VAT
        Assert.AreEqual(Format(SalesCrMemoHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'));

        // [THEN] DuePayableAmount = Amount incl. VAT
        Assert.AreEqual(Format(SalesCrMemoHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasLineItem()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo has line items
        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] Line has LineID
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'));

        // [THEN] Line has product name
        Assert.AreNotEqual('',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'));
    end;
    #endregion

    #region Reminder
    [Test]
    procedure FacturXIssuedReminderLineHasBilledQuantityOne()
    var
        Customer: Record Customer;
        TempIssuedReminderHeader: Record "Issued Reminder Header" temporary;
        TempIssuedReminderLine: Record "Issued Reminder Line" temporary;
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO] An issued reminder line (which has no Quantity field) emits BilledQuantity = 1
        Initialize();

        // [GIVEN] An issued reminder with a single fee line that carries an amount but no quantity
        Customer.Get(CreateCustomer(''));
        TempIssuedReminderHeader.Init();
        TempIssuedReminderHeader."No." := 'REM-FACTURX-001';
        TempIssuedReminderHeader."Customer No." := Customer."No.";
        TempIssuedReminderHeader.Name := Customer.Name;
        SourceDocumentHeader.GetTable(TempIssuedReminderHeader);

        TempIssuedReminderLine.Init();
        TempIssuedReminderLine."Reminder No." := TempIssuedReminderHeader."No.";
        TempIssuedReminderLine."Line No." := 10000;
        TempIssuedReminderLine.Description := 'Reminder fee';
        TempIssuedReminderLine.Amount := 25;
        TempIssuedReminderLine."VAT %" := 20;
        TempIssuedReminderLine.Insert();
        SourceDocumentLines.GetTable(TempIssuedReminderLine);

        // [WHEN] Create CII XML
        CreateCIIInvoiceXmlFromTempSource(SourceDocumentHeader, SourceDocumentLines, TempIssuedReminderHeader."No.", TempIssuedReminderLine.Amount, TempBlob);

        // [THEN] BilledQuantity = 1 even though the source line has no Quantity field
        Assert.AreEqual('1',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'));
    end;

    [Test]
    procedure FacturXIssuedFinChargeMemoLineHasBilledQuantityOne()
    var
        Customer: Record Customer;
        TempIssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header" temporary;
        TempIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line" temporary;
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO] An issued finance charge memo line (which has no Quantity field) emits BilledQuantity = 1
        Initialize();

        // [GIVEN] An issued finance charge memo with a single interest line that carries an amount but no quantity
        Customer.Get(CreateCustomer(''));
        TempIssuedFinChargeMemoHeader.Init();
        TempIssuedFinChargeMemoHeader."No." := 'FIN-FACTURX-001';
        TempIssuedFinChargeMemoHeader."Customer No." := Customer."No.";
        TempIssuedFinChargeMemoHeader.Name := Customer.Name;
        SourceDocumentHeader.GetTable(TempIssuedFinChargeMemoHeader);

        TempIssuedFinChargeMemoLine.Init();
        TempIssuedFinChargeMemoLine."Finance Charge Memo No." := TempIssuedFinChargeMemoHeader."No.";
        TempIssuedFinChargeMemoLine."Line No." := 10000;
        TempIssuedFinChargeMemoLine.Description := 'Interest charge';
        TempIssuedFinChargeMemoLine.Amount := 25;
        TempIssuedFinChargeMemoLine."VAT %" := 20;
        TempIssuedFinChargeMemoLine.Insert();
        SourceDocumentLines.GetTable(TempIssuedFinChargeMemoLine);

        // [WHEN] Create CII XML
        CreateCIIInvoiceXmlFromTempSource(SourceDocumentHeader, SourceDocumentLines, TempIssuedFinChargeMemoHeader."No.", TempIssuedFinChargeMemoLine.Amount, TempBlob);

        // [THEN] BilledQuantity = 1 even though the source line has no Quantity field
        Assert.AreEqual('1',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'));
    end;
    #endregion

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Factur-X CII XML Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Factur-X CII XML Tests");

        CompanyInformation.Get();
        CompanyInformation.Validate("Registration No.", '123456789');
        CompanyInformation.Validate("SIRET No.", '12345678901234');
        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation.Validate("VAT Registration No.", 'FR12345678901');
        if CompanyInformation.Name = '' then
            CompanyInformation.Name := 'Test Company FR';
        if CompanyInformation."Country/Region Code" = '' then begin
            EnsureCountryRegionExists('FR');
            CompanyInformation.Validate("Country/Region Code", 'FR');
        end;
        CompanyInformation.Modify(true);

        SetupGeneralLedger();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Factur-X CII XML Tests");
    end;

    local procedure CreateAndPostSalesInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, ''));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithElecAddress(FRElecAddress: Text[250]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, FRElecAddress));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithExtDocNo(ExtDocNo: Code[35]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, ''));
        SalesHeader.Validate("External Document No.", ExtDocNo);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesCreditMemo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get("Sales Document Type"::"Credit Memo", CreateSalesDocumentWithLine("Sales Document Type"::"Credit Memo", ''));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocumentWithLine(DocType: Enum "Sales Document Type"; FRElecAddress: Text[250]): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer(FRElecAddress);
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Credit Memo Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Credit Memo Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        EnsureVATBusinessPostingGroupExists(GLAccount."VAT Bus. Posting Group");
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);
        exit(SalesHeader."No.");
    end;

    local procedure CreateCustomer(FRElecAddress: Text[250]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        EnsureVATBusinessPostingGroupExists(Customer."VAT Bus. Posting Group");
        if Customer."Country/Region Code" = '' then
            Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Registration No.", GetNextCustomerVATRegistrationNo());
        Customer.Validate("FR Electronic Address", FRElecAddress);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure EnsureVATBusinessPostingGroupExists(VATBusPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // Shared test libraries can reference VAT posting setup data whose backing VAT business posting group
        // is missing in the test company, so recreate the missing group before validating the customer.
        if (VATBusPostingGroupCode = '') or VATBusinessPostingGroup.Get(VATBusPostingGroupCode) then
            exit;

        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Code := VATBusPostingGroupCode;
        VATBusinessPostingGroup.Insert();
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

    local procedure CreateSalesInvoiceCIIXML(var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);
    end;

    local procedure CreateCIIInvoiceXmlFromTempSource(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; DocumentNo: Code[20]; Amount: Decimal; var TempBlob: Codeunit "Temp Blob")
    var
        EDocument: Record "E-Document";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();

        EDocument.Init();
        EDocument."Document No." := DocumentNo;
        EDocument."Document Date" := WorkDate();
        EDocument."Amount Excl. VAT" := Amount;
        EDocument."Amount Incl. VAT" := Amount;
        EDocument."Currency Code" := GeneralLedgerSetup."LCY Code";

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
    end;

    local procedure CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader: Record "Sales Invoice Header"; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        EDocument: Record "E-Document";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");

        EDocument.Init();
        EDocument."Document No." := SalesInvoiceHeader."No.";
        EDocument."Document Date" := SalesInvoiceHeader."Posting Date";
        EDocument."Amount Excl. VAT" := SalesInvoiceHeader.Amount;
        EDocument."Amount Incl. VAT" := SalesInvoiceHeader."Amount Including VAT";
        if SalesInvoiceHeader."Currency Code" <> '' then
            EDocument."Currency Code" := SalesInvoiceHeader."Currency Code"
        else begin
            GeneralLedgerSetup.Get();
            EDocument."Currency Code" := GeneralLedgerSetup."LCY Code";
        end;

        SourceDocumentHeader.GetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceDocumentLines.GetTable(SalesInvoiceLine);

        CIIXMLBuilder.CreateInvoiceXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
    end;

    local procedure CreateSalesCreditMemoCIIXML(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempBlob: Codeunit "Temp Blob")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        EDocument: Record "E-Document";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SourceDocumentHeader: RecordRef;
        SourceDocumentLines: RecordRef;
    begin
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        EDocument.Init();
        EDocument."Document No." := SalesCrMemoHeader."No.";
        EDocument."Document Date" := SalesCrMemoHeader."Posting Date";
        EDocument."Amount Excl. VAT" := SalesCrMemoHeader.Amount;
        EDocument."Amount Incl. VAT" := SalesCrMemoHeader."Amount Including VAT";
        if SalesCrMemoHeader."Currency Code" <> '' then
            EDocument."Currency Code" := SalesCrMemoHeader."Currency Code"
        else begin
            GeneralLedgerSetup.Get();
            EDocument."Currency Code" := GeneralLedgerSetup."LCY Code";
        end;

        SourceDocumentHeader.GetTable(SalesCrMemoHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SourceDocumentLines.GetTable(SalesCrMemoLine);

        CIIXMLBuilder.CreateCreditMemoXml(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob);
    end;

    local procedure GetCIINodeValue(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Text
    var
        XmlDoc: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        Node: XmlNode;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);
        BuildNamespaceManager(XmlDoc, NamespaceMgr);

        if XmlDoc.SelectSingleNode(XPath, NamespaceMgr, Node) then
            exit(Node.AsXmlElement().InnerText());
        exit('');
    end;

    local procedure GetCIIAttributeValue(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Text
    var
        XmlDoc: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        Node: XmlNode;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);
        BuildNamespaceManager(XmlDoc, NamespaceMgr);

        if XmlDoc.SelectSingleNode(XPath, NamespaceMgr, Node) then
            exit(Node.AsXmlAttribute().Value());
        exit('');
    end;

    local procedure BuildNamespaceManager(XmlDoc: XmlDocument; var NamespaceMgr: XmlNamespaceManager)
    begin
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('rsm', 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100');
        NamespaceMgr.AddNamespace('ram', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');
        NamespaceMgr.AddNamespace('udt', 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100');
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

    local procedure GetUnitOfMeasureCode(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetRange(Code, 'EA');
        if not UnitOfMeasure.FindFirst() then begin
            UnitOfMeasure.Init();
            UnitOfMeasure.Code := 'EA';
            UnitOfMeasure.Description := 'Each';
            UnitOfMeasure.Insert(true);
        end;
        exit(UnitOfMeasure.Code);
    end;

    local procedure EnsureCountryRegionExists(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then begin
            CountryRegion.Init();
            CountryRegion.Code := CountryCode;
            CountryRegion.Name := CountryCode;
            CountryRegion.Insert(true);
        end;
    end;
}
