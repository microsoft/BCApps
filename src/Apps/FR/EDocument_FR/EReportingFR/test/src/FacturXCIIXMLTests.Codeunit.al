// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 148148 "Factur-X CII XML Tests"
{
    Subtype = Test;
    Permissions = tabledata "E-Document Service" = rimd,
                  tabledata "Company Information" = rimd,
                  tabledata "Sales Invoice Header" = m,
                  tabledata Customer = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [Factur-X FR E-document]
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        CIIXMLBuilder: Codeunit "CII XML Builder";
        EDocHelpers: Codeunit "EDoc. Helpers";
        FacturXFormat: Codeunit "Factur-X Format";
        IncorrectValueErr: Label 'Incorrect value for %1', Comment = '%1 = XML element path', Locked = true;
        FacturXProfileIdTok: Label 'urn:cen.eu:en16931:2017', Locked = true;
        DialogErrorCodeTok: Label 'Dialog', Locked = true;
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
    procedure FacturXSalesInvoiceXMLHasFrenchBillingMode()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML declares the French service billing mode
        Initialize();

        // [GIVEN] Posted sales invoice with a G/L account line
        // [WHEN] Create CII XML via FR CII XML Builder
        CreateSalesInvoiceCIIXML(TempBlob);

        // [THEN] BusinessProcessSpecifiedDocumentContextParameter/ID = 'S1'
        Assert.AreEqual('S1',
            GetCIINodeValue(TempBlob, '//ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID'));
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
        // [SCENARIO] Factur-X CII XML has buyer FR Electronic Address as BuyerTradeParty/URIUniversalCommunication/URIID with scheme 0225
        Initialize();

        // [GIVEN] Customer with FR Electronic Address in SIREN_suffix format
        ElecAddress := '987654321_001';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithElecAddress(ElecAddress));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID = FR Electronic Address
        Assert.AreEqual(ElecAddress,
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));

        // [THEN] schemeID = '0225'
        Assert.AreEqual('0225',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLBuyerFallsBackToRegistrationNumber()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML uses buyer Registration Number (first 9 digits) with schemeID 0225 when FR Electronic Address is blank
        Initialize();

        // [GIVEN] Posted sales invoice with customer having no FR Electronic Address but having a Registration Number
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID = first 9 digits of Registration Number
        Assert.AreEqual(CopyStr(Customer."Registration Number", 1, 9),
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));

        // [THEN] schemeID = '0225'
        Assert.AreEqual('0225',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasSettlementCurrencyCode()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML settlement currency code uses LCY when document has no currency
        Initialize();

        // [GIVEN] Posted sales invoice with blank Currency Code (uses LCY)
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        GeneralLedgerSetup.Get();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ApplicableHeaderTradeSettlement/InvoiceCurrencyCode = LCY Code
        Assert.AreEqual(GeneralLedgerSetup."LCY Code",
            GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceCurrencyCode'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasDocumentCurrencyCode()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML settlement currency code uses the document currency
        Initialize();

        // [GIVEN] Sales invoice with a foreign Currency Code
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, '', Currency.Code));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] InvoiceCurrencyCode equals the document currency
        Assert.AreEqual(Currency.Code, GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceCurrencyCode'));
    end;

    [Test]
    procedure FacturXForeignCurrencyRoundingPrecisionIsUsedForInvoiceDiscountAllocation()
    var
        Currency: Record Currency;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        AllowanceAmount: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X allocates an invoice discount using the foreign currency rounding precision
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with mixed VAT rates and a foreign currency whose rounding precision is 1
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 1);
        Currency.Modify(true);
        SalesInvoiceHeader.Get(CreateAndPostMultiVATInvoiceWithDiscount(false));
        SalesInvoiceHeader."Currency Code" := Currency.Code;
        SalesInvoiceHeader."Invoice Discount Amount" := 1.4;
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] The discount allocated to the 20% VAT breakdown is rounded from 0.56 to 1
        AllowanceAmount := GetCIINodeDecimalValue(TempBlob,
            '//ram:SpecifiedTradeAllowanceCharge[ram:CategoryTradeTax/ram:RateApplicablePercent="20"]/ram:ActualAmount');
        Assert.AreEqual(1, AllowanceAmount, StrSubstNo(IncorrectValueErr, 'ActualAmount 20%'));
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
        CompanyInformation.Address := '123 Test Street';
        CompanyInformation.City := 'Paris';
        CompanyInformation."Post Code" := '75001';
        CompanyInformation.Modify(true);

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
    procedure FacturXSalesInvoiceXMLPreservesLowercaseBuyerVATCountryPrefix()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML preserves a buyer VAT registration starting with a lowercase country prefix
        Initialize();

        // [GIVEN] Posted sales invoice with buyer country "FR" and VAT registration "fr12345678901"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader."Sell-to Country/Region Code" := 'FR';
        SalesInvoiceHeader."VAT Registration No." := 'fr12345678901';
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Buyer VAT registration remains "fr12345678901"
        Assert.AreEqual('fr12345678901',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLPrefixesBuyerVATStartingWithLetterAndDigit()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML prefixes a buyer VAT registration whose first two characters are not letters
        Initialize();

        // [GIVEN] Posted sales invoice with buyer country "FR" and VAT registration "F12345678901"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader."Sell-to Country/Region Code" := 'FR';
        SalesInvoiceHeader."VAT Registration No." := 'F12345678901';
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Buyer VAT registration is "FRF12345678901"
        Assert.AreEqual('FRF12345678901',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLPrefixesSingleCharacterBuyerVAT()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML prefixes a single-character buyer VAT registration
        Initialize();

        // [GIVEN] Posted sales invoice with buyer country "FR" and VAT registration "1"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader."Sell-to Country/Region Code" := 'FR';
        SalesInvoiceHeader."VAT Registration No." := '1';
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Buyer VAT registration is "FR1"
        Assert.AreEqual('FR1',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasBuyerElecAddressSchemeID0225()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        ElecAddress: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML buyer electronic address always has schemeID 0225 regardless of customer configured scheme
        Initialize();

        // [GIVEN] Customer with FR Electronic Address (valid SIREN)
        ElecAddress := '987654321';
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithElecAddress(ElecAddress));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID/@schemeID = '0225'
        Assert.AreEqual('0225',
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
        // [SCENARIO] Factur-X CII XML has ActualDeliverySupplyChainEvent with posting date as fallback (BT-72)
        Initialize();

        // [GIVEN] Posted sales invoice with blank Shipment Date
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader."Shipment Date" := 0D;
        SalesInvoiceHeader.Modify();
        ExpectedDate := Format(SalesInvoiceHeader."Posting Date", 0, '<Year4><Month,2><Day,2>');

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ActualDeliverySupplyChainEvent/OccurrenceDateTime/DateTimeString = posting date as YYYYMMDD
        Assert.AreEqual(ExpectedDate,
            GetCIINodeValue(TempBlob, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'),
            StrSubstNo(IncorrectValueErr, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'));

        // [THEN] format attribute = '102'
        Assert.AreEqual('102',
            GetCIIAttributeValue(TempBlob, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString/@format'),
            StrSubstNo(IncorrectValueErr, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString/@format'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLUsesShipmentDateAsDeliveryDate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        ShipmentDate: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML uses Shipment Date as the actual delivery date
        Initialize();

        // [GIVEN] Posted sales invoice with a known Shipment Date
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        ShipmentDate := CalcDate('<-1D>', SalesInvoiceHeader."Posting Date");
        SalesInvoiceHeader."Shipment Date" := ShipmentDate;
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Actual delivery date equals Shipment Date
        Assert.AreEqual(Format(ShipmentDate, 0, '<Year4><Month,2><Day,2>'),
            GetCIINodeValue(TempBlob, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'),
            StrSubstNo(IncorrectValueErr, '//ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString'));
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
    procedure FacturXSalesInvoiceUsesCompanyBankAccountWhenCodeIsBlank()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A blank company bank account code falls back to Company Information payment details
        Initialize();

        // [GIVEN] Company Information with payment details and posted sales invoice "SI" with a blank company bank account code
        CompanyInformation.Get();
        CompanyInformation.IBAN := 'FR7630006000011234567890189';
        CompanyInformation."SWIFT Code" := 'AGRIFRPP';
        CompanyInformation.Modify();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceHeader."Company Bank Account Code" := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Payment account uses Company Information IBAN and BIC
        Assert.AreEqual(DelChr(CompanyInformation.IBAN, '=', ' '),
            GetCIINodeValue(TempBlob, '//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'),
            StrSubstNo(IncorrectValueErr, '//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'));
        Assert.AreEqual(CompanyInformation."SWIFT Code",
            GetCIINodeValue(TempBlob, '//ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID'),
            StrSubstNo(IncorrectValueErr, '//ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID'));
    end;

    [Test]
    procedure FacturXSalesInvoiceXMLHasTaxBreakdown()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has ApplicableTradeTax with VAT type code, basis, and category
        Initialize();

        // [GIVEN] Posted sales invoice with known amounts
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindFirst();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] ApplicableTradeTax/TypeCode = 'VAT'
        Assert.AreEqual('VAT',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode'));

        // [THEN] ApplicableTradeTax/BasisAmount = line amount
        Assert.AreEqual(Format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount'));

        // [THEN] ApplicableTradeTax has CategoryCode 'S' (standard rate)
        Assert.AreEqual('S',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'));

        // [THEN] ApplicableTradeTax/RateApplicablePercent = line VAT %
        Assert.AreEqual(Format(SalesInvoiceLine."VAT %", 0, '<Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'),
            StrSubstNo(IncorrectValueErr, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'));
    end;

    [Test]
    procedure FacturXExemptVATBreakdownHasExemptionReasonWithoutVATEXCode()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        TempBlob: Codeunit "Temp Blob";
        ExemptionReasonXPath: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An exempt VAT breakdown without a configured VATEX code satisfies BR-E-10
        Initialize();

        // [GIVEN] VAT Posting Setup with 0% VAT, category 'E', and no VAT Clause
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        VATPostingSetup."Tax Category" := 'E';
        VATPostingSetup."VAT Clause Code" := '';
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        // [GIVEN] Posted sales invoice with one exempt line
        Customer.Get(CreateCustomer('123456789'));
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] The category 'E' header VAT breakdown contains fallback exemption reason text
        ExemptionReasonXPath := '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode="E"]/ram:ExemptionReason';
        Assert.AreEqual('Exonéré de TVA', GetCIINodeValue(TempBlob, ExemptionReasonXPath),
            StrSubstNo(IncorrectValueErr, ExemptionReasonXPath));
        Assert.AreEqual(1, GetCIINodeCount(TempBlob, ExemptionReasonXPath + '/following-sibling::ram:BasisAmount'),
            StrSubstNo(IncorrectValueErr, 'ExemptionReason must precede BasisAmount'));
    end;

    [Test]
    procedure FacturXSalesInvoiceCommentLineDoesNotCreateEmptyVATCategory()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        EmptyVATCategoryXPath: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A comment line does not create a VAT breakdown with an empty category
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with a financial line and a comment line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithComment());

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] The header VAT breakdown does not contain an empty category code
        EmptyVATCategoryXPath := '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode[not(normalize-space())]';
        Assert.AreEqual(0, GetCIINodeCount(TempBlob, EmptyVATCategoryXPath), StrSubstNo(IncorrectValueErr, EmptyVATCategoryXPath));
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
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has IncludedSupplyChainTradeLineItem with fixture-derived values
        Initialize();

        // [GIVEN] Posted sales invoice with known line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindFirst();

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Line has LineID = '1'
        Assert.AreEqual('1',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:AssociatedDocumentLineDocument/ram:LineID'));

        // [THEN] Line has product name = line description
        Assert.AreEqual(SalesInvoiceLine.Description,
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedTradeProduct/ram:Name'));

        // [THEN] Line has net price = unit price
        Assert.AreEqual(SalesInvoiceLine."Unit Price",
            GetCIINodeDecimalValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'));

        // [THEN] Line has billed quantity
        Assert.AreEqual(Format(SalesInvoiceLine.Quantity, 0, '<Standard Format,9>'),
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'));

        // [THEN] Line has tax category code 'S'
        Assert.AreEqual('S',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'),
            StrSubstNo(IncorrectValueErr, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode'));

        // [THEN] Line has line total amount = line amount
        Assert.AreEqual(Format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,9>'),
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
    procedure FacturXSalesCreditMemoXMLHasReferencedInvoiceNumberAndDate()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for an applied credit memo identifies the referenced invoice and its date
        Initialize();

        // [GIVEN] Posted sales credit memo applied to posted invoice "SI"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice());
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo(SalesInvoiceHeader));

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] InvoiceReferencedDocument contains the invoice number and document date
        Assert.AreEqual(SalesInvoiceHeader."No.",
            GetCIINodeValue(TempBlob, '//ram:InvoiceReferencedDocument/ram:IssuerAssignedID'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceReferencedDocument/ram:IssuerAssignedID'));
        Assert.AreEqual(Format(SalesInvoiceHeader."Document Date", 0, '<Year4><Month,2><Day,2>'),
            GetCIINodeValue(TempBlob, '//ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/qdt:DateTimeString'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/qdt:DateTimeString'));
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
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo uses LCY when document has no currency
        Initialize();

        // [GIVEN] Posted sales credit memo with blank Currency Code (uses LCY)
        SalesCrMemoHeader.Get(CreateAndPostSalesCreditMemo());
        GeneralLedgerSetup.Get();

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] InvoiceCurrencyCode = LCY Code
        Assert.AreEqual(GeneralLedgerSetup."LCY Code",
            GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
            StrSubstNo(IncorrectValueErr, '//ram:InvoiceCurrencyCode'));
    end;

    [Test]
    procedure FacturXSalesCreditMemoXMLHasDocumentCurrencyCode()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML for a credit memo uses the document currency
        Initialize();

        // [GIVEN] Sales credit memo with a foreign Currency Code
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        SalesHeader.Get("Sales Document Type"::"Credit Memo", CreateSalesDocumentWithLine("Sales Document Type"::"Credit Memo", '', Currency.Code));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] InvoiceCurrencyCode equals the document currency
        Assert.AreEqual(Currency.Code, GetCIINodeValue(TempBlob, '//ram:InvoiceCurrencyCode'),
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

    [Test]
    procedure FacturXSalesCrMemoZeroVATCatSPreservedWithGermanBuyer()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        LineTaxCategoryXPath: Text;
        HeaderTaxCategoryXPath: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Credit memo line with VAT%=0 preserves source Tax Category 'S' and serializes the rate; German buyer gets DE-prefixed VAT ID
        Initialize();

        // [GIVEN] German customer "C" with VAT Registration No. '533435789', FR Electronic Address '123456789_FOREIGN'
        EnsureCountryRegionExists('DE');
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", 'DE');
        Customer."VAT Registration No." := '533435789';
        Customer."Registration Number" := '';
        Customer."FR Electronic Address" := '123456789_FOREIGN';
        Customer.Modify(true);
        CustomerNo := Customer."No.";

        // [GIVEN] VAT Posting Setup with Normal VAT, 0%, Tax Category 'S'
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Credit Memo Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Credit Memo Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // [GIVEN] Posted sales credit memo "CM" with a single financial line
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create credit memo CII XML
        CreateSalesCreditMemoCIIXML(SalesCrMemoHeader, TempBlob);

        // [THEN] Line-level ApplicableTradeTax preserves CategoryCode 'S' and RateApplicablePercent '0'
        LineTaxCategoryXPath := '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual('S', GetCIINodeValue(TempBlob, LineTaxCategoryXPath),
            StrSubstNo(IncorrectValueErr, LineTaxCategoryXPath));
        Assert.AreEqual('0',
            GetCIINodeValue(TempBlob, '//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode="S"]/ram:RateApplicablePercent'),
            StrSubstNo(IncorrectValueErr, 'Line RateApplicablePercent'));

        // [THEN] Header ApplicableTradeTax preserves CategoryCode 'S' and RateApplicablePercent '0'
        HeaderTaxCategoryXPath := '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode';
        Assert.AreEqual('S', GetCIINodeValue(TempBlob, HeaderTaxCategoryXPath),
            StrSubstNo(IncorrectValueErr, HeaderTaxCategoryXPath));
        Assert.AreEqual('0',
            GetCIINodeValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:CategoryCode="S"]/ram:RateApplicablePercent'),
            StrSubstNo(IncorrectValueErr, 'Header RateApplicablePercent'));
        Assert.AreEqual(0, GetCIINodeCount(TempBlob, '//ram:ApplicableTradeTax[ram:CategoryCode="O"]'),
            StrSubstNo(IncorrectValueErr, 'CategoryCode O must not be derived from zero-rate category S'));

        // [THEN] Buyer SpecifiedTaxRegistration/ID = 'DE533435789' with schemeID 'VA'
        Assert.AreEqual('DE533435789',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID'));
        Assert.AreEqual('VA',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:SpecifiedTaxRegistration/ram:ID/@schemeID'));

        // [THEN] Buyer URIID = '123456789_FOREIGN' with schemeID '0225'
        Assert.AreEqual('123456789_FOREIGN',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));
        Assert.AreEqual('0225',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
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
        // [FEATURE] [AI test]
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
        // [FEATURE] [AI test]
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

    #region BillingMode
    [Test]
    procedure FacturXBillingModeB1ForItemOnlyInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PeppolBIS30FRFormat: Codeunit "Peppol BIS 3.0 FR Format";
        SourceDocumentLines: RecordRef;
        OriginalView: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] GetFrenchBillingMode returns B1 for an invoice with only Item lines
        Initialize();

        // [GIVEN] Posted sales invoice containing only an Item line
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithBillingModeLines(false));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceDocumentLines.GetTable(SalesInvoiceLine);
        OriginalView := SourceDocumentLines.GetView(false);

        // [WHEN] GetFrenchBillingMode is called
        // [THEN] Result = 'B1' and the source lines view is unchanged
        Assert.AreEqual('B1', PeppolBIS30FRFormat.GetFrenchBillingMode(SourceDocumentLines),
            StrSubstNo(IncorrectValueErr, 'BillingMode B1'));
        Assert.AreEqual(OriginalView, SourceDocumentLines.GetView(false), StrSubstNo(IncorrectValueErr, 'Source Document Lines View'));
    end;

    [Test]
    procedure FacturXBillingModeM1ForMixedItemAndNonItemInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PeppolBIS30FRFormat: Codeunit "Peppol BIS 3.0 FR Format";
        SourceDocumentLines: RecordRef;
        OriginalView: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] GetFrenchBillingMode returns M1 for an invoice with both Item and G/L Account lines
        Initialize();

        // [GIVEN] Posted sales invoice containing Item and G/L Account lines
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceWithBillingModeLines(true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceDocumentLines.GetTable(SalesInvoiceLine);
        OriginalView := SourceDocumentLines.GetView(false);

        // [WHEN] GetFrenchBillingMode is called
        // [THEN] Result = 'M1' and the source lines view is unchanged
        Assert.AreEqual('M1', PeppolBIS30FRFormat.GetFrenchBillingMode(SourceDocumentLines),
            StrSubstNo(IncorrectValueErr, 'BillingMode M1'));
        Assert.AreEqual(OriginalView, SourceDocumentLines.GetView(false), StrSubstNo(IncorrectValueErr, 'Source Document Lines View'));
    end;
    #endregion

    #region Validation
    [Test]
    procedure FacturXCheckRaisesErrorWhenBuyerElectronicAddressIsMissing()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceDocumentHeader: RecordRef;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X Format Check raises error when buyer has no electronic address or VAT
        Initialize();

        // [GIVEN] Posted sales invoice for customer "C" without electronic address or VAT
        CustomerNo := CreateCustomerWithoutIdentifiers();
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomer(CustomerNo));
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] Factur-X Format Check is called
        asserterror CheckFacturX(SourceDocumentHeader);

        // [THEN] Error about buyer electronic address is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressRequiredError(CustomerNo));
    end;

    [Test]
    procedure FacturXCheckRaisesErrorWhenBuyerElectronicAddressIsMalformed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SourceDocumentHeader: RecordRef;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X Format Check raises error when buyer electronic address does not match SIREN format
        Initialize();

        // [GIVEN] Customer "C" with malformed FR Electronic Address (non-digit prefix)
        CustomerNo := CreateCustomer('');
        Customer.Get(CustomerNo);
        Customer."FR Electronic Address" := 'ABCDEFGHI';
        Customer."Registration Number" := '';
        Customer.Modify(true);

        // [GIVEN] Posted sales invoice for "C"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomer(CustomerNo));
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] Factur-X Format Check is called
        asserterror CheckFacturX(SourceDocumentHeader);

        // [THEN] Error about malformed buyer identifier is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressInvalidError(
            Customer.FieldCaption("FR Electronic Address"), CustomerNo));
    end;

    [Test]
    procedure FacturXCheckPassesAndExportsURIIDFromFrenchVAT()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        SourceDocumentHeader: RecordRef;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X uses SIREN extracted from French VAT as BuyerTradeParty URIID when FR Electronic Address and Registration Number are blank
        Initialize();

        // [GIVEN] Customer "C" with French VAT but no FR Electronic Address or Registration Number
        CustomerNo := CreateCustomer('');
        Customer.Get(CustomerNo);
        Customer."FR Electronic Address" := '';
        Customer."Registration Number" := '';
        Customer."VAT Registration No." := 'FR78945627890';
        Customer.Modify(true);

        // [GIVEN] Posted sales invoice for "C"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomer(CustomerNo));
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] Factur-X Format Check is called
        CheckFacturX(SourceDocumentHeader);

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] BuyerTradeParty/URIUniversalCommunication/URIID = '945627890'
        Assert.AreEqual('945627890',
            GetCIINodeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID'));

        // [THEN] schemeID = '0225'
        Assert.AreEqual('0225',
            GetCIIAttributeValue(TempBlob, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'),
            StrSubstNo(IncorrectValueErr, '//ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID/@schemeID'));
    end;

    [Test]
    procedure FacturXCheckRaisesErrorWhenBuyerHasOnlyNonFrenchVAT()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        SourceDocumentHeader: RecordRef;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X Format Check raises error when buyer has only a non-French VAT without FR Electronic Address or Registration Number
        Initialize();

        // [GIVEN] Customer "C" with non-French VAT but no FR Electronic Address or Registration Number
        CustomerNo := CreateCustomer('');
        Customer.Get(CustomerNo);
        Customer."FR Electronic Address" := '';
        Customer."Registration Number" := '';
        Customer."VAT Registration No." := 'DE123456789';
        Customer.Modify(true);

        // [GIVEN] Posted sales invoice for "C"
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoiceForCustomer(CustomerNo));
        SourceDocumentHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] Factur-X Format Check is called
        asserterror CheckFacturX(SourceDocumentHeader);

        // [THEN] Error about buyer electronic address is raised
        AssertExpectedDialogError(EDocHelpers.GetBuyerElectronicAddressRequiredError(CustomerNo));
    end;
    #endregion

    #region MultiVATRate
    [Test]
    procedure FacturXSalesInvoiceXMLHasMultipleVATRateTaxBreakdowns()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        FirstVATPostingSetup: Record "VAT Posting Setup";
        SecondVATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Factur-X CII XML has distinct ApplicableTradeTax groups for each VAT rate
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with two lines at different VAT rates
        CustomerNo := CreateCustomer('');
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        EnsureSalesInvoiceDiscountAccount(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        LibraryERM.CreateVATPostingSetupWithAccounts(FirstVATPostingSetup, FirstVATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        GLAccount.Validate("VAT Prod. Posting Group", FirstVATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", FirstVATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(SecondVATPostingSetup, SecondVATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        SecondVATPostingSetup.Rename(Customer."VAT Bus. Posting Group", SecondVATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("VAT Prod. Posting Group", SecondVATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", 300);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Separate header VAT breakdowns exist for both VAT rates
        Assert.AreEqual(1, GetCIINodeCount(TempBlob,
            '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="20"]'),
            StrSubstNo(IncorrectValueErr, '20 percent ApplicableTradeTax'));
        Assert.AreEqual(1, GetCIINodeCount(TempBlob,
            '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="10"]'),
            StrSubstNo(IncorrectValueErr, '10 percent ApplicableTradeTax'));
        Assert.AreEqual(2, GetCIINodeCount(TempBlob,
            '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax'),
            StrSubstNo(IncorrectValueErr, 'ApplicableTradeTax count'));
    end;

    [Test]
    procedure FacturXMixedVATWithInvDiscountTaxTotalEqualsBreakdownSum()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        TaxTotalAmount: Decimal;
        Calculated20: Decimal;
        Calculated10: Decimal;
        Basis20: Decimal;
        Basis10: Decimal;
        ExpectedBasis20: Decimal;
        ExpectedBasis10: Decimal;
        ExpectedCalculated20: Decimal;
        ExpectedCalculated10: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Mixed VAT rates with invoice discount: TaxTotalAmount = sum of CalculatedAmounts and each breakdown matches posted line amounts
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with two lines at 20% and 10% VAT and invoice discount applied
        SalesInvoiceHeader.Get(CreateAndPostMultiVATInvoiceWithDiscount(true));
        GetPostedInvoiceAmountsByVATRate(SalesInvoiceHeader."No.", 20, ExpectedBasis20, ExpectedCalculated20);
        GetPostedInvoiceAmountsByVATRate(SalesInvoiceHeader."No.", 10, ExpectedBasis10, ExpectedCalculated10);

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Each breakdown BasisAmount equals the posted line Amount grouped by VAT rate
        Basis20 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="20"]/ram:BasisAmount');
        Assert.AreEqual(ExpectedBasis20, Basis20, StrSubstNo(IncorrectValueErr, 'BasisAmount 20%'));
        Basis10 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="10"]/ram:BasisAmount');
        Assert.AreEqual(ExpectedBasis10, Basis10, StrSubstNo(IncorrectValueErr, 'BasisAmount 10%'));

        // [THEN] Each breakdown CalculatedAmount equals AmountIncludingVAT - Amount per rate
        Calculated20 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="20"]/ram:CalculatedAmount');
        Assert.AreEqual(ExpectedCalculated20, Calculated20, StrSubstNo(IncorrectValueErr, 'CalculatedAmount 20%'));
        Calculated10 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="10"]/ram:CalculatedAmount');
        Assert.AreEqual(ExpectedCalculated10, Calculated10, StrSubstNo(IncorrectValueErr, 'CalculatedAmount 10%'));

        // [THEN] Header TaxTotalAmount equals sum of all CalculatedAmounts
        TaxTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount');
        Assert.AreEqual(Calculated20 + Calculated10, TaxTotalAmount, StrSubstNo(IncorrectValueErr, 'TaxTotalAmount'));
    end;

    [Test]
    procedure FacturXSingleVATWithInvDiscountAllowanceAndReconciliation()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempBlob: Codeunit "Temp Blob";
        LineTotalAmount: Decimal;
        AllowanceTotalAmount: Decimal;
        AllowanceAmount: Decimal;
        TaxBasisTotalAmount: Decimal;
        TaxTotalAmount: Decimal;
        BreakdownBasis: Decimal;
        BreakdownCalculated: Decimal;
        ExpectedAllowanceAmount: Decimal;
        ExpectedBasis: Decimal;
        ExpectedCalculated: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Single VAT rate with invoice discount: document allowance, breakdown basis/VAT, and BR-CO-14 reconciliation
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with one line at 20% VAT and invoice discount applied
        SalesInvoiceHeader.Get(CreateAndPostSingleVATInvoiceWithDiscount());
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindFirst();
        ExpectedAllowanceAmount := SalesInvoiceLine."Line Amount" - SalesInvoiceLine.Amount;
        ExpectedBasis := SalesInvoiceLine.Amount;
        ExpectedCalculated := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Document-level allowance equals the discount recorded on the posted line
        AllowanceAmount := GetCIINodeDecimalValue(
            TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge/ram:ActualAmount');
        Assert.AreEqual(ExpectedAllowanceAmount, AllowanceAmount, StrSubstNo(IncorrectValueErr, 'ActualAmount'));

        // [THEN] Breakdown BasisAmount equals posted line Amount
        BreakdownBasis := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:BasisAmount');
        Assert.AreEqual(ExpectedBasis, BreakdownBasis, StrSubstNo(IncorrectValueErr, 'BasisAmount'));

        // [THEN] Breakdown CalculatedAmount equals posted VAT
        BreakdownCalculated := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:CalculatedAmount');
        Assert.AreEqual(ExpectedCalculated, BreakdownCalculated, StrSubstNo(IncorrectValueErr, 'CalculatedAmount'));

        // [THEN] Monetary totals reconcile
        LineTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount');
        AllowanceTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount');
        TaxBasisTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount');
        Assert.AreEqual(LineTotalAmount, TaxBasisTotalAmount + AllowanceTotalAmount,
            StrSubstNo(IncorrectValueErr, 'LineTotalAmount'));

        // [THEN] BR-CO-14: TaxTotalAmount equals the VAT breakdown CalculatedAmount
        TaxTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount');
        Assert.AreEqual(BreakdownCalculated, TaxTotalAmount, StrSubstNo(IncorrectValueErr, 'TaxTotalAmount'));
    end;

    [Test]
    procedure FacturXMixedVATNoDiscountBreakdownAndReconciliation()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        TaxTotalAmount: Decimal;
        TaxBasisTotalAmount: Decimal;
        Calculated20: Decimal;
        Calculated10: Decimal;
        Basis20: Decimal;
        Basis10: Decimal;
        ExpectedBasis20: Decimal;
        ExpectedBasis10: Decimal;
        ExpectedCalculated20: Decimal;
        ExpectedCalculated10: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Mixed VAT rates without invoice discount: breakdown amounts match posted values and reconciliation holds
        Initialize();

        // [GIVEN] Posted sales invoice "SI" with two lines at 20% and 10% VAT without invoice discount
        SalesInvoiceHeader.Get(CreateAndPostMultiVATInvoiceWithDiscount(false));
        GetPostedInvoiceAmountsByVATRate(SalesInvoiceHeader."No.", 20, ExpectedBasis20, ExpectedCalculated20);
        GetPostedInvoiceAmountsByVATRate(SalesInvoiceHeader."No.", 10, ExpectedBasis10, ExpectedCalculated10);

        // [WHEN] Create CII XML
        CreateSalesInvoiceCIIXMLFromHeader(SalesInvoiceHeader, TempBlob);

        // [THEN] Each breakdown BasisAmount and CalculatedAmount match posted line amounts
        Basis20 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="20"]/ram:BasisAmount');
        Assert.AreEqual(ExpectedBasis20, Basis20, StrSubstNo(IncorrectValueErr, 'BasisAmount 20%'));
        Basis10 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="10"]/ram:BasisAmount');
        Assert.AreEqual(ExpectedBasis10, Basis10, StrSubstNo(IncorrectValueErr, 'BasisAmount 10%'));
        Calculated20 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="20"]/ram:CalculatedAmount');
        Assert.AreEqual(ExpectedCalculated20, Calculated20, StrSubstNo(IncorrectValueErr, 'CalculatedAmount 20%'));
        Calculated10 := GetCIINodeDecimalValue(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax[ram:RateApplicablePercent="10"]/ram:CalculatedAmount');
        Assert.AreEqual(ExpectedCalculated10, Calculated10, StrSubstNo(IncorrectValueErr, 'CalculatedAmount 10%'));

        // [THEN] TaxTotalAmount equals sum of all CalculatedAmounts
        TaxTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount');
        Assert.AreEqual(Calculated20 + Calculated10, TaxTotalAmount, StrSubstNo(IncorrectValueErr, 'TaxTotalAmount'));

        // [THEN] TaxBasisTotalAmount equals sum of all BasisAmounts (no discount)
        TaxBasisTotalAmount := GetCIINodeDecimalValue(TempBlob, '//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount');
        Assert.AreEqual(Basis20 + Basis10, TaxBasisTotalAmount, StrSubstNo(IncorrectValueErr, 'TaxBasisTotalAmount'));

        // [THEN] No document-level allowance exists
        Assert.AreEqual(0, GetCIINodeCount(TempBlob, '//ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeAllowanceCharge'),
            StrSubstNo(IncorrectValueErr, 'SpecifiedTradeAllowanceCharge count'));
    end;
    #endregion

    local procedure AssertExpectedDialogError(ExpectedErrorText: Text)
    begin
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    local procedure Initialize()
    var
        EDocumentService: Record "E-Document Service";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Factur-X CII XML Tests");
        EDocumentService.DeleteAll();
        if IsInitialized then begin
            LibrarySetupStorage.Restore();
            exit;
        end;
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
        CreatePostingSetupFixture();

        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

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

    local procedure CreateAndPostSalesInvoiceForCustomer(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithBillingModeLines(IncludeGLAccountLine: Boolean): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerNo: Code[20];
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        if GeneralPostingSetup."COGS Account" = '' then
            GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
            GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        CustomerNo := CreateCustomer('');
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        Item.Get(LibraryInventory.CreateItemNoWithPostingSetup(
            GLAccount."Gen. Prod. Posting Group", GLAccount."VAT Prod. Posting Group"));
        LibraryInventory.UpdateInventoryPostingSetup(Location, Item."Inventory Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        if IncludeGLAccountLine then begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
            SalesLine.Validate("Unit Price", 100);
            SalesLine.Modify(true);
        end;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithComment(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get("Sales Document Type"::Invoice, CreateSalesDocumentWithLine("Sales Document Type"::Invoice, ''));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine.Validate(Description, 'Comment');
        SalesLine.Modify(true);
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

    local procedure CreateAndPostSalesCreditMemo(SalesInvoiceHeader: Record "Sales Invoice Header"): Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocumentWithLine(DocType: Enum "Sales Document Type"; FRElecAddress: Text[250]): Code[20]
    begin
        exit(CreateSalesDocumentWithLine(DocType, FRElecAddress, ''));
    end;

    local procedure CreateSalesDocumentWithLine(DocType: Enum "Sales Document Type"; FRElecAddress: Text[250]; CurrencyCode: Code[10]): Code[20]
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
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        if CurrencyCode <> '' then begin
            SalesHeader.Validate("Currency Code", CurrencyCode);
            SalesHeader.Modify(true);
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);
        exit(SalesHeader."No.");
    end;

    local procedure CreateAndPostMultiVATInvoiceWithDiscount(ApplyInvoiceDiscount: Boolean): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        GLAccount: Record "G/L Account";
        FirstVATPostingSetup: Record "VAT Posting Setup";
        SecondVATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer('');
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATPostingSetupWithAccounts(FirstVATPostingSetup, FirstVATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        GLAccount.Validate("VAT Prod. Posting Group", FirstVATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", FirstVATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        if ApplyInvoiceDiscount then begin
            LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
            CustInvoiceDisc.Validate("Discount %", 10);
            CustInvoiceDisc.Modify(true);
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 200);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);

        LibraryERM.CreateVATPostingSetupWithAccounts(SecondVATPostingSetup, SecondVATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        SecondVATPostingSetup.Rename(Customer."VAT Bus. Posting Group", SecondVATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("VAT Prod. Posting Group", SecondVATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", 300);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);

        if ApplyInvoiceDiscount then
            LibrarySales.CalcSalesDiscount(SalesHeader);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSingleVATInvoiceWithDiscount(): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer('');
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        EnsureSalesInvoiceDiscountAccount(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", 10);
        CustInvoiceDisc.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 500);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit of Measure Code", GetUnitOfMeasureCode());
        SalesLine.Modify(true);

        LibrarySales.CalcSalesDiscount(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure EnsureSalesInvoiceDiscountAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        if GeneralPostingSetup."Sales Inv. Disc. Account" <> '' then
            exit;

        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure GetPostedInvoiceAmountsByVATRate(DocumentNo: Code[20]; VATRate: Decimal; var BasisAmount: Decimal; var CalculatedAmount: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.SetLoadFields("VAT %", Amount, "Amount Including VAT");
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesInvoiceLine."VAT %" = VATRate then begin
                    BasisAmount += SalesInvoiceLine.Amount;
                    CalculatedAmount += SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CreateCustomer(FRElecAddress: Text[250]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo('FR');
        Customer."Registration Number" := '123456789';
        Customer.Validate("FR Electronic Address", FRElecAddress);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithoutIdentifiers(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer."FR Electronic Address" := '';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::" ";
        Customer."VAT Registration No." := '';
        Customer."Registration Number" := '';
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CheckFacturX(var SourceDocumentHeader: RecordRef)
    var
        EDocumentService: Record "E-Document Service";
    begin
        FacturXFormat.Check(SourceDocumentHeader, EDocumentService, "E-Document Processing Phase"::Create);
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

    local procedure GetCIINodeCount(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Integer
    var
        XmlDoc: XmlDocument;
        NamespaceMgr: XmlNamespaceManager;
        Nodes: XmlNodeList;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);
        BuildNamespaceManager(XmlDoc, NamespaceMgr);

        XmlDoc.SelectNodes(XPath, NamespaceMgr, Nodes);
        exit(Nodes.Count());
    end;

    local procedure GetCIINodeDecimalValue(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Decimal
    var
        NodeText: Text;
        Result: Decimal;
    begin
        NodeText := GetCIINodeValue(TempBlob, XPath);
        Evaluate(Result, NodeText, 9);
        exit(Result);
    end;

    local procedure BuildNamespaceManager(XmlDoc: XmlDocument; var NamespaceMgr: XmlNamespaceManager)
    begin
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('rsm', 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100');
        NamespaceMgr.AddNamespace('ram', 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');
        NamespaceMgr.AddNamespace('qdt', 'urn:un:unece:uncefact:data:standard:QualifiedDataType:100');
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
        PostingGroupCode := '0FRFACTURX';

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
